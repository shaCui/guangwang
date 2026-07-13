#import "AcapeShelfBroker.h"
#import "AcapeShelfItem.h"
#import "AcapeVaultStore.h"
#import <StoreKit/StoreKit.h>

static NSString * const kAcapeShelfFulfilledTxKey = @"AcapeShelfFulfilledTxKey";
static NSTimeInterval const kAcapeShelfAdvanceTimeout = 60.0;
static NSTimeInterval const kAcapeShelfKickoffTimeout = 12.0;
static NSTimeInterval const kAcapeShelfCatalogTimeout = 20.0;

@interface AcapeShelfBroker () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic, copy) NSArray<AcapeShelfItem *> *catalog;
@property (nonatomic, copy) NSDictionary<NSString *, SKProduct *> *storeProducts;
@property (nonatomic, copy) NSDictionary<NSString *, AcapeShelfItem *> *catalogByBatchRef;
@property (nonatomic, copy) void (^catalogReadyBlock)(BOOL);
@property (nonatomic, copy) AcapeShelfAdvanceCompletion pendingAdvanceCompletion;
@property (nonatomic, copy) NSString *pendingBatchRef;
@property (nonatomic, strong) SKProductsRequest *productsRequest;
@property (nonatomic, strong) dispatch_block_t pendingAdvanceTimeoutBlock;
@property (nonatomic, strong) dispatch_block_t pendingAdvanceKickoffBlock;
@property (nonatomic, strong) dispatch_block_t catalogRequestTimeoutBlock;
@property (nonatomic, assign) BOOL isObserving;
@property (nonatomic, assign) BOOL pendingAdvanceDidKickoff;
@end

@implementation AcapeShelfBroker

+ (instancetype)shared {
    static AcapeShelfBroker *broker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        broker = [[AcapeShelfBroker alloc] init];
    });
    return broker;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _catalog = [AcapeShelfItem defaultCatalog];
        NSMutableDictionary<NSString *, AcapeShelfItem *> *lookup = [NSMutableDictionary dictionary];
        for (AcapeShelfItem *item in _catalog) {
            lookup[item.batchRef] = item;
        }
        _catalogByBatchRef = lookup.copy;
        _storeProducts = @{};
    }
    return self;
}

- (void)startObserving {
    if (self.isObserving) {
        return;
    }
    self.isObserving = YES;
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [self flushStaleShelfTransactions];
}

- (NSArray<AcapeShelfItem *> *)catalogItems {
    return self.catalog;
}

- (BOOL)canAdvanceShelf {
    return [SKPaymentQueue canMakePayments];
}

- (BOOL)isBatchRefReady:(NSString *)batchRef {
    return batchRef.length > 0 && self.storeProducts[batchRef] != nil;
}

- (void)prepareCatalogWithCompletion:(void (^)(BOOL))completion {
    if (completion) {
        void (^readyBlock)(BOOL) = completion;
        if (self.storeProducts.count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                readyBlock(YES);
            });
            return;
        }
        self.catalogReadyBlock = readyBlock;
    }
    if (self.productsRequest) {
        return;
    }
    NSSet<NSString *> *batchRefs = [NSSet setWithArray:self.catalogByBatchRef.allKeys];
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:batchRefs];
    self.productsRequest.delegate = self;
    [self scheduleCatalogRequestTimeout];
    [self.productsRequest start];
}

- (void)advanceWithBatchRef:(NSString *)batchRef completion:(AcapeShelfAdvanceCompletion)completion {
    if (![self canAdvanceShelf]) {
        [self deliverAdvanceCompletion:completion succeeded:NO issue:AcapeShelfAdvanceIssueUnavailable];
        return;
    }
    if (batchRef.length == 0 || self.catalogByBatchRef[batchRef] == nil) {
        [self deliverAdvanceCompletion:completion succeeded:NO issue:AcapeShelfAdvanceIssueFailed];
        return;
    }
    SKProduct *product = self.storeProducts[batchRef];
    if (!product) {
        [self deliverAdvanceCompletion:completion succeeded:NO issue:AcapeShelfAdvanceIssueUnavailable];
        return;
    }
    if (self.pendingAdvanceCompletion) {
        [self deliverAdvanceCompletion:completion succeeded:NO issue:AcapeShelfAdvanceIssueFailed];
        return;
    }

    [self flushStaleShelfTransactions];

    self.pendingBatchRef = batchRef;
    self.pendingAdvanceCompletion = completion;
    self.pendingAdvanceDidKickoff = NO;
    [self schedulePendingAdvanceTimeout];
    [self schedulePendingAdvanceKickoffWatchdog];

    SKPayment *advance = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:advance];
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSMutableDictionary<NSString *, SKProduct *> *products = [NSMutableDictionary dictionary];
    for (SKProduct *product in response.products) {
        products[product.productIdentifier] = product;
    }
    self.storeProducts = products.copy;
    self.productsRequest = nil;
    [self cancelCatalogRequestTimeout];
    void (^readyBlock)(BOOL) = self.catalogReadyBlock;
    self.catalogReadyBlock = nil;
    if (readyBlock) {
        BOOL ready = self.storeProducts.count > 0;
        dispatch_async(dispatch_get_main_queue(), ^{
            readyBlock(ready);
        });
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    if (request == self.productsRequest) {
        self.productsRequest = nil;
        [self cancelCatalogRequestTimeout];
        void (^readyBlock)(BOOL) = self.catalogReadyBlock;
        self.catalogReadyBlock = nil;
        if (readyBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                readyBlock(NO);
            });
        }
    }
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        NSString *batchRef = transaction.payment.productIdentifier;
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                if (self.pendingBatchRef.length > 0 && [batchRef isEqualToString:self.pendingBatchRef]) {
                    self.pendingAdvanceDidKickoff = YES;
                    [self cancelPendingAdvanceKickoffWatchdog];
                }
                break;
            case SKPaymentTransactionStatePurchased:
                [self fulfillTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self resolveFailedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateDeferred:
                if (self.pendingBatchRef.length > 0 && [batchRef isEqualToString:self.pendingBatchRef]) {
                    self.pendingAdvanceDidKickoff = YES;
                    [self cancelPendingAdvanceKickoffWatchdog];
                }
                break;
        }
    }
}

- (void)fulfillTransaction:(SKPaymentTransaction *)transaction {
    NSString *batchRef = transaction.payment.productIdentifier;
    AcapeShelfItem *item = self.catalogByBatchRef[batchRef];
    BOOL shouldResolvePending = (self.pendingAdvanceCompletion != nil &&
                                 self.pendingBatchRef.length > 0 &&
                                 [batchRef isEqualToString:self.pendingBatchRef]);

    if (!item) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        if (shouldResolvePending) {
            [self resolvePendingAdvanceSucceeded:NO issue:AcapeShelfAdvanceIssueFailed forBatchRef:batchRef];
        }
        return;
    }

    NSString *txId = transaction.transactionIdentifier;
    if (txId.length > 0 && [self hasFulfilledTransactionId:txId]) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        if (shouldResolvePending) {
            [self resolvePendingAdvanceSucceeded:YES issue:AcapeShelfAdvanceIssueNone forBatchRef:batchRef];
        }
        return;
    }

    [[AcapeVaultStore shared] rechargeCredits:item.creditAmount];
    if (txId.length > 0) {
        [self markTransactionIdFulfilled:txId];
    }
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    if (shouldResolvePending) {
        [self resolvePendingAdvanceSucceeded:YES issue:AcapeShelfAdvanceIssueNone forBatchRef:batchRef];
    }
}

- (void)resolveFailedTransaction:(SKPaymentTransaction *)transaction {
    AcapeShelfAdvanceIssue issue = AcapeShelfAdvanceIssueFailed;
    if (transaction.error.code == SKErrorPaymentCancelled) {
        issue = AcapeShelfAdvanceIssueCancelled;
    }
    NSString *batchRef = transaction.payment.productIdentifier;
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    if (self.pendingAdvanceCompletion != nil &&
        self.pendingBatchRef.length > 0 &&
        [batchRef isEqualToString:self.pendingBatchRef]) {
        [self resolvePendingAdvanceSucceeded:NO issue:issue forBatchRef:batchRef];
    }
}

- (void)resolvePendingAdvanceSucceeded:(BOOL)succeeded issue:(AcapeShelfAdvanceIssue)issue forBatchRef:(NSString *)batchRef {
    void (^resolveBlock)(void) = ^{
        if (self.pendingAdvanceCompletion == nil || self.pendingBatchRef.length == 0) {
            return;
        }
        if (![batchRef isEqualToString:self.pendingBatchRef]) {
            return;
        }
        [self cancelPendingAdvanceTimeout];
        [self cancelPendingAdvanceKickoffWatchdog];
        AcapeShelfAdvanceCompletion completion = self.pendingAdvanceCompletion;
        self.pendingAdvanceCompletion = nil;
        self.pendingBatchRef = nil;
        self.pendingAdvanceDidKickoff = NO;
        [self deliverAdvanceCompletion:completion succeeded:succeeded issue:issue];
    };

    if ([NSThread isMainThread]) {
        resolveBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), resolveBlock);
    }
}

- (void)deliverAdvanceCompletion:(AcapeShelfAdvanceCompletion)completion
                      succeeded:(BOOL)succeeded
                          issue:(AcapeShelfAdvanceIssue)issue {
    if (!completion) {
        return;
    }
    if ([NSThread isMainThread]) {
        completion(succeeded, issue);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(succeeded, issue);
        });
    }
}

- (void)schedulePendingAdvanceTimeout {
    [self cancelPendingAdvanceTimeout];
    __weak typeof(self) weakSelf = self;
    dispatch_block_t block = dispatch_block_create(0, ^{
        [weakSelf expirePendingAdvance];
    });
    self.pendingAdvanceTimeoutBlock = block;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kAcapeShelfAdvanceTimeout * NSEC_PER_SEC)),
                   dispatch_get_main_queue(),
                   block);
}

- (void)schedulePendingAdvanceKickoffWatchdog {
    [self cancelPendingAdvanceKickoffWatchdog];
    __weak typeof(self) weakSelf = self;
    NSString *batchRef = self.pendingBatchRef.copy;
    dispatch_block_t block = dispatch_block_create(0, ^{
        [weakSelf expirePendingAdvanceKickoffForBatchRef:batchRef];
    });
    self.pendingAdvanceKickoffBlock = block;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kAcapeShelfKickoffTimeout * NSEC_PER_SEC)),
                   dispatch_get_main_queue(),
                   block);
}

- (void)scheduleCatalogRequestTimeout {
    [self cancelCatalogRequestTimeout];
    __weak typeof(self) weakSelf = self;
    dispatch_block_t block = dispatch_block_create(0, ^{
        [weakSelf expireCatalogRequest];
    });
    self.catalogRequestTimeoutBlock = block;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kAcapeShelfCatalogTimeout * NSEC_PER_SEC)),
                   dispatch_get_main_queue(),
                   block);
}

- (void)cancelPendingAdvanceTimeout {
    if (self.pendingAdvanceTimeoutBlock) {
        dispatch_block_cancel(self.pendingAdvanceTimeoutBlock);
        self.pendingAdvanceTimeoutBlock = nil;
    }
}

- (void)cancelPendingAdvanceKickoffWatchdog {
    if (self.pendingAdvanceKickoffBlock) {
        dispatch_block_cancel(self.pendingAdvanceKickoffBlock);
        self.pendingAdvanceKickoffBlock = nil;
    }
}

- (void)cancelCatalogRequestTimeout {
    if (self.catalogRequestTimeoutBlock) {
        dispatch_block_cancel(self.catalogRequestTimeoutBlock);
        self.catalogRequestTimeoutBlock = nil;
    }
}

- (void)expirePendingAdvance {
    self.pendingAdvanceTimeoutBlock = nil;
    NSString *batchRef = self.pendingBatchRef;
    if (batchRef.length == 0 || self.pendingAdvanceCompletion == nil) {
        return;
    }
    [self resolvePendingAdvanceSucceeded:NO issue:AcapeShelfAdvanceIssueFailed forBatchRef:batchRef];
}

- (void)expirePendingAdvanceKickoffForBatchRef:(NSString *)batchRef {
    self.pendingAdvanceKickoffBlock = nil;
    if (batchRef.length == 0 || self.pendingAdvanceCompletion == nil) {
        return;
    }
    if (![batchRef isEqualToString:self.pendingBatchRef]) {
        return;
    }
    if (self.pendingAdvanceDidKickoff) {
        return;
    }
    [self resolvePendingAdvanceSucceeded:NO issue:AcapeShelfAdvanceIssueUnavailable forBatchRef:batchRef];
}

- (void)expireCatalogRequest {
    self.catalogRequestTimeoutBlock = nil;
    if (!self.productsRequest) {
        return;
    }
    [self.productsRequest cancel];
    self.productsRequest = nil;
    void (^readyBlock)(BOOL) = self.catalogReadyBlock;
    self.catalogReadyBlock = nil;
    if (readyBlock) {
        readyBlock(NO);
    }
}

- (void)flushStaleShelfTransactions {
    for (SKPaymentTransaction *transaction in [SKPaymentQueue defaultQueue].transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self fulfillTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

#pragma mark - Fulfillment ledger

- (BOOL)hasFulfilledTransactionId:(NSString *)transactionId {
    NSSet<NSString *> *fulfilled = [self fulfilledTransactionIds];
    return [fulfilled containsObject:transactionId];
}

- (void)markTransactionIdFulfilled:(NSString *)transactionId {
    if (transactionId.length == 0) {
        return;
    }
    NSMutableSet<NSString *> *fulfilled = [self fulfilledTransactionIds].mutableCopy;
    [fulfilled addObject:transactionId];
    [[NSUserDefaults standardUserDefaults] setObject:fulfilled.allObjects forKey:kAcapeShelfFulfilledTxKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSSet<NSString *> *)fulfilledTransactionIds {
    NSArray *stored = [[NSUserDefaults standardUserDefaults] arrayForKey:kAcapeShelfFulfilledTxKey];
    return stored.count > 0 ? [NSSet setWithArray:stored] : [NSSet set];
}

- (void)dealloc {
    if (self.isObserving) {
        [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    }
}

@end

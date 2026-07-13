#import <Foundation/Foundation.h>

@class AcapeShelfItem;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AcapeShelfAdvanceIssue) {
    AcapeShelfAdvanceIssueNone = 0,
    AcapeShelfAdvanceIssueUnavailable,
    AcapeShelfAdvanceIssueCancelled,
    AcapeShelfAdvanceIssueFailed,
};

typedef void (^AcapeShelfAdvanceCompletion)(BOOL succeeded, AcapeShelfAdvanceIssue issue);

/// 货架通道: StoreKit bridge for coffer catalog advances.
@interface AcapeShelfBroker : NSObject

+ (instancetype)shared;

- (void)startObserving;
- (void)prepareCatalogWithCompletion:(void (^ _Nullable)(BOOL ready))completion;
- (NSArray<AcapeShelfItem *> *)catalogItems;
- (BOOL)canAdvanceShelf;
- (BOOL)isBatchRefReady:(NSString *)batchRef;
- (void)advanceWithBatchRef:(NSString *)batchRef completion:(AcapeShelfAdvanceCompletion)completion;

@end

NS_ASSUME_NONNULL_END

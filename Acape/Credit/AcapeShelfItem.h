#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 货架条目: one recharge tier in the coffer catalog.
@interface AcapeShelfItem : NSObject

@property (nonatomic, copy, readonly) NSString *batchRef;
@property (nonatomic, assign, readonly) NSInteger creditAmount;
@property (nonatomic, copy, readonly) NSString *priceLabel;

+ (instancetype)itemWithBatchRef:(NSString *)batchRef
                    creditAmount:(NSInteger)creditAmount
                      priceLabel:(NSString *)priceLabel;

+ (NSArray<AcapeShelfItem *> *)defaultCatalog;

- (nullable instancetype)initWithBatchRef:(NSString *)batchRef
                             creditAmount:(NSInteger)creditAmount
                               priceLabel:(NSString *)priceLabel NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

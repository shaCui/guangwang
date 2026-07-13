#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 支付: confirm spending a number of credits.
@interface AcapePayConfirmDialog : UIViewController

- (instancetype)initWithCost:(NSInteger)cost;

@property (nonatomic, copy, nullable) void (^onConfirm)(void);

@end

NS_ASSUME_NONNULL_END

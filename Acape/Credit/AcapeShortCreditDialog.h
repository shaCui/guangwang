#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 余额不足: insufficient balance dialog offering a recharge shortcut.
@interface AcapeShortCreditDialog : UIViewController

@property (nonatomic, copy, nullable) void (^onRecharge)(void);

@end

NS_ASSUME_NONNULL_END

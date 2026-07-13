#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AcapeAppNavigator : NSObject

+ (void)presentHarborAsRootInWindow:(UIWindow *)window animated:(BOOL)animated;
+ (void)presentGateAsRootInWindow:(UIWindow *)window animated:(BOOL)animated;
+ (void)presentPortalAsRootInWindow:(UIWindow *)window animated:(BOOL)animated;
+ (void)presentAccessPromptFromPresenter:(UIViewController *)presenter;

@end

NS_ASSUME_NONNULL_END

#import "AcapeAppNavigator.h"
#import "AcapeHarborScreen.h"
#import "AcapeAccessPromptScreen.h"
#import "AcapePortalScreen.h"
#import "AcapeGateScreen.h"

@implementation AcapeAppNavigator

+ (void)presentHarborAsRootInWindow:(UIWindow *)window animated:(BOOL)animated {
    if (!window) {
        return;
    }

    AcapeHarborScreen *harborScreen = [[AcapeHarborScreen alloc] init];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:harborScreen];
    navigation.navigationBarHidden = YES;

    void (^applyRoot)(void) = ^{
        window.rootViewController = navigation;
    };

    if (!animated) {
        applyRoot();
        return;
    }

    [UIView transitionWithView:window
                      duration:0.35
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:applyRoot
                    completion:nil];
}

+ (void)presentAccessPromptFromPresenter:(UIViewController *)presenter {
    if (!presenter) {
        return;
    }
    AcapeAccessPromptScreen *promptScreen = [[AcapeAccessPromptScreen alloc] init];
    promptScreen.modalPresentationStyle = UIModalPresentationOverFullScreen;
    promptScreen.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [presenter presentViewController:promptScreen animated:YES completion:nil];
}

+ (void)presentGateAsRootInWindow:(UIWindow *)window animated:(BOOL)animated {
    if (!window) {
        return;
    }

    AcapeGateScreen *gateScreen = [[AcapeGateScreen alloc] init];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:gateScreen];
    navigation.navigationBarHidden = YES;

    void (^applyRoot)(void) = ^{
        window.rootViewController = navigation;
    };

    if (!animated) {
        applyRoot();
        return;
    }

    [UIView transitionWithView:window
                      duration:0.35
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:applyRoot
                    completion:nil];
}

+ (void)presentPortalAsRootInWindow:(UIWindow *)window animated:(BOOL)animated {
    if (!window) {
        return;
    }

    AcapePortalScreen *portalScreen = [[AcapePortalScreen alloc] init];
    void (^applyRoot)(void) = ^{
        window.rootViewController = portalScreen;
    };

    if (!animated) {
        applyRoot();
        return;
    }

    [UIView transitionWithView:window
                      duration:0.35
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:applyRoot
                    completion:nil];
}

@end

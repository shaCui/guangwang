#import "UIViewController+AcapeDismissKeyboard.h"
#import <objc/runtime.h>

static const void *kAcapeDismissKeyboardGestureKey = &kAcapeDismissKeyboardGestureKey;

@implementation UIViewController (AcapeDismissKeyboard)

- (void)acape_enableDismissKeyboardOnBackgroundTap {
    if (objc_getAssociatedObject(self, kAcapeDismissKeyboardGestureKey)) {
        return;
    }

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(acape_handleBackgroundTapToDismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
    objc_setAssociatedObject(self, kAcapeDismissKeyboardGestureKey, tap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)acape_handleBackgroundTapToDismissKeyboard {
    [self.view endEditing:YES];
}

@end

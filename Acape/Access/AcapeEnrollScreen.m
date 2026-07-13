#import "AcapeEnrollScreen.h"
#import "AcapeRevealText.h"
#import "AcapeLatticeOverlay.h"
#import "AcapeNavKit.h"
#import "AcapeAuthFormKit.h"
#import "AcapeGradientCaptionLabel.h"
#import "AcapePrimaryActionButton.h"
#import "UIViewController+AcapeDismissKeyboard.h"
#import "AcapeAccessScreen.h"
#import "AcapeAppNavigator.h"
#import "AcapeVaultStore.h"
#import "AcapeMemberDetailScreen.h"

@interface AcapeEnrollScreen ()

@property (nonatomic, strong) CAGradientLayer *headerGradientLayer;
@property (nonatomic, strong) AcapeLatticeOverlay *latticeOverlay;
@property (nonatomic, strong) UIButton *backControl;
@property (nonatomic, strong) AcapeGradientCaptionLabel *titleLabel;
@property (nonatomic, strong) UIView *formPanel;
@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UITextField *secretField;
@property (nonatomic, strong) UITextField *secretAgainField;
@property (nonatomic, strong) AcapePrimaryActionButton *submitButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

@end

@implementation AcapeEnrollScreen

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [AcapeAuthFormKit pageBackgroundColor];
    [self acape_enableDismissKeyboardOnBackgroundTap];
    [self buildHeader];
    [self buildFormPanel];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.headerGradientLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height * 0.34);
}

- (void)buildHeader {
    self.headerGradientLayer = [AcapeAuthFormKit headerGradientLayer];
    [self.view.layer addSublayer:self.headerGradientLayer];

    self.latticeOverlay = [[AcapeLatticeOverlay alloc] init];
    self.latticeOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.latticeOverlay];

    self.backControl = [AcapeNavKit backControlWithTarget:self action:@selector(handleBackTap)];
    [self.view addSubview:self.backControl];

    self.titleLabel = [[AcapeGradientCaptionLabel alloc] init];
    self.titleLabel.text = AcapeRevealText(AcapeRevealTextKeyEnrollTitle);
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.titleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.latticeOverlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.latticeOverlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.latticeOverlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.latticeOverlay.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.28],
        [self.backControl.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:16.0],
        [self.backControl.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:4.0],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:35.0],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:88.0],
    ]];
}

- (void)buildFormPanel {
    self.formPanel = [AcapeAuthFormKit formPanelView];
    [self.view addSubview:self.formPanel];

    UILabel *emailCaption = [AcapeAuthFormKit fieldCaptionWithText:AcapeRevealText(AcapeRevealTextKeyEmailLabel)];
    self.emailField = [AcapeAuthFormKit inputFieldWithPlaceholder:AcapeRevealText(AcapeRevealTextKeyEmailPlaceholder) secure:NO];
    self.emailField.keyboardType = UIKeyboardTypeEmailAddress;

    UILabel *secretCaption = [AcapeAuthFormKit fieldCaptionWithText:AcapeRevealText(AcapeRevealTextKeySecretLabel)];
    self.secretField = [AcapeAuthFormKit inputFieldWithPlaceholder:AcapeRevealText(AcapeRevealTextKeySecretPlaceholder) secure:YES];
    self.secretAgainField = [AcapeAuthFormKit inputFieldWithPlaceholder:AcapeRevealText(AcapeRevealTextKeySecretAgainPlaceholder) secure:YES];

    self.submitButton = [[AcapePrimaryActionButton alloc] initWithFrame:CGRectZero];
    [self.submitButton setTitle:AcapeRevealText(AcapeRevealTextKeyEnrollTitle) forState:UIControlStateNormal];
    self.submitButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.submitButton addTarget:self action:@selector(handleSubmitTap) forControlEvents:UIControlEventTouchUpInside];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = UIColor.whiteColor;
    self.loadingIndicator.hidesWhenStopped = YES;
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;

    [self.formPanel addSubview:emailCaption];
    [self.formPanel addSubview:self.emailField];
    [self.formPanel addSubview:secretCaption];
    [self.formPanel addSubview:self.secretField];
    [self.formPanel addSubview:self.secretAgainField];
    [self.formPanel addSubview:self.submitButton];
    [self.view addSubview:self.loadingIndicator];

    [NSLayoutConstraint activateConstraints:@[
        [self.formPanel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.formPanel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.formPanel.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.formPanel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:168.0],

        [emailCaption.topAnchor constraintEqualToAnchor:self.formPanel.topAnchor constant:32.0],
        [emailCaption.leadingAnchor constraintEqualToAnchor:self.formPanel.leadingAnchor constant:24.0],
        [emailCaption.trailingAnchor constraintEqualToAnchor:self.formPanel.trailingAnchor constant:-24.0],

        [self.emailField.topAnchor constraintEqualToAnchor:emailCaption.bottomAnchor constant:10.0],
        [self.emailField.leadingAnchor constraintEqualToAnchor:emailCaption.leadingAnchor],
        [self.emailField.trailingAnchor constraintEqualToAnchor:emailCaption.trailingAnchor],
        [self.emailField.heightAnchor constraintEqualToConstant:52.0],

        [secretCaption.topAnchor constraintEqualToAnchor:self.emailField.bottomAnchor constant:20.0],
        [secretCaption.leadingAnchor constraintEqualToAnchor:emailCaption.leadingAnchor],

        [self.secretField.topAnchor constraintEqualToAnchor:secretCaption.bottomAnchor constant:10.0],
        [self.secretField.leadingAnchor constraintEqualToAnchor:emailCaption.leadingAnchor],
        [self.secretField.trailingAnchor constraintEqualToAnchor:emailCaption.trailingAnchor],
        [self.secretField.heightAnchor constraintEqualToConstant:52.0],

        [self.secretAgainField.topAnchor constraintEqualToAnchor:self.secretField.bottomAnchor constant:14.0],
        [self.secretAgainField.leadingAnchor constraintEqualToAnchor:emailCaption.leadingAnchor],
        [self.secretAgainField.trailingAnchor constraintEqualToAnchor:emailCaption.trailingAnchor],
        [self.secretAgainField.heightAnchor constraintEqualToConstant:52.0],

        [self.submitButton.topAnchor constraintEqualToAnchor:self.secretAgainField.bottomAnchor constant:105.0],
        [self.submitButton.leadingAnchor constraintEqualToAnchor:emailCaption.leadingAnchor],
        [self.submitButton.trailingAnchor constraintEqualToAnchor:emailCaption.trailingAnchor],
        [self.submitButton.heightAnchor constraintEqualToConstant:52.0],

        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];
}

- (void)handleBackTap {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleSubmitTap {
    NSString *email = [self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *secret = self.secretField.text ?: @"";
    NSString *secretAgain = self.secretAgainField.text ?: @"";

    if ([email rangeOfString:@"@"].location == NSNotFound) {
        [self presentNoticeWithCopy:@"Please enter a valid email address."];
        return;
    }
    if (secret.length == 0 || secretAgain.length == 0) {
        [self presentNoticeWithCopy:@"Please enter your password."];
        return;
    }
    if (![secret isEqualToString:secretAgain]) {
        [self presentNoticeWithCopy:@"Passwords do not match."];
        return;
    }
    if ([[AcapeVaultStore shared] isIdentityAccessRevoked:email]) {
        [self presentNoticeWithCopy:AcapeRevealText(AcapeRevealTextKeyHubAccessRevoked)];
        return;
    }
    if ([[AcapeVaultStore shared] hasAccessCredentialForIdentity:email]) {
        [self presentNoticeWithCopy:AcapeRevealText(AcapeRevealTextKeyAccessAlreadyRegistered)];
        return;
    }

    self.submitButton.enabled = NO;
    [self.loadingIndicator startAnimating];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.loadingIndicator stopAnimating];
        BOOL registered = [[AcapeVaultStore shared] registerAccessCredentialWithIdentity:email secret:secret];
        if (!registered) {
            [self presentNoticeWithCopy:AcapeRevealText(AcapeRevealTextKeyAccessAlreadyRegistered)];
            self.submitButton.enabled = YES;
            return;
        }
        [self returnToAccessScreen];
    });
}

- (void)returnToAccessScreen {
    for (UIViewController *screen in self.navigationController.viewControllers) {
        if ([screen isKindOfClass:[AcapeAccessScreen class]]) {
            [self.navigationController popToViewController:screen animated:YES];
            return;
        }
    }
    AcapeAccessScreen *accessScreen = [[AcapeAccessScreen alloc] init];
    NSMutableArray<UIViewController *> *stack = [self.navigationController.viewControllers mutableCopy];
    if (stack.count > 0) {
        [stack removeLastObject];
    }
    [stack addObject:accessScreen];
    [self.navigationController setViewControllers:stack animated:YES];
}

- (void)presentNoticeWithCopy:(NSString *)noticeText {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:noticeText preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

#import "AcapeAccessScreen.h"
#import "AcapeRevealText.h"
#import "AcapeLatticeOverlay.h"
#import "AcapeNavKit.h"
#import "AcapeAuthFormKit.h"
#import "AcapeGradientCaptionLabel.h"
#import "AcapePrimaryActionButton.h"
#import "AcapeEnrollScreen.h"
#import "AcapeRecoverScreen.h"
#import "AcapeMemberDetailScreen.h"
#import "UIViewController+AcapeDismissKeyboard.h"
#import "AcapeAppNavigator.h"
#import "AcapeVaultStore.h"

@interface AcapeAccessScreen () <UITextViewDelegate>

@property (nonatomic, strong) CAGradientLayer *headerGradientLayer;
@property (nonatomic, strong) AcapeLatticeOverlay *latticeOverlay;
@property (nonatomic, strong) UIButton *backControl;
@property (nonatomic, strong) AcapeGradientCaptionLabel *titleLabel;
@property (nonatomic, strong) UIView *formPanel;
@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UITextField *secretField;
@property (nonatomic, strong) AcapePrimaryActionButton *submitButton;
@property (nonatomic, strong) UITextView *registerPromptView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

@end

@implementation AcapeAccessScreen

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [AcapeAuthFormKit pageBackgroundColor];
    [self acape_enableDismissKeyboardOnBackgroundTap];
    [self buildHeader];
    [self buildFormPanel];
    [self buildRegisterPrompt];
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
    self.titleLabel.text = AcapeRevealText(AcapeRevealTextKeyAccessTitle);
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

    UIButton *recoverButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [recoverButton setTitle:AcapeRevealText(AcapeRevealTextKeyRecoverHint) forState:UIControlStateNormal];
    [recoverButton setTitleColor:[AcapeAuthFormKit accentTealColor] forState:UIControlStateNormal];
    recoverButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    recoverButton.translatesAutoresizingMaskIntoConstraints = NO;
    [recoverButton addTarget:self action:@selector(handleRecoverTap) forControlEvents:UIControlEventTouchUpInside];

    self.submitButton = [[AcapePrimaryActionButton alloc] initWithFrame:CGRectZero];
    [self.submitButton setTitle:AcapeRevealText(AcapeRevealTextKeyAccessTitle) forState:UIControlStateNormal];
    self.submitButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.submitButton addTarget:self action:@selector(handleSubmitTap) forControlEvents:UIControlEventTouchUpInside];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = UIColor.whiteColor;
    self.loadingIndicator.hidesWhenStopped = YES;
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;

    [self.formPanel addSubview:emailCaption];
    [self.formPanel addSubview:self.emailField];
    [self.formPanel addSubview:secretCaption];
    [self.formPanel addSubview:recoverButton];
    [self.formPanel addSubview:self.secretField];
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

        [recoverButton.centerYAnchor constraintEqualToAnchor:secretCaption.centerYAnchor],
        [recoverButton.trailingAnchor constraintEqualToAnchor:emailCaption.trailingAnchor],

        [self.secretField.topAnchor constraintEqualToAnchor:secretCaption.bottomAnchor constant:10.0],
        [self.secretField.leadingAnchor constraintEqualToAnchor:emailCaption.leadingAnchor],
        [self.secretField.trailingAnchor constraintEqualToAnchor:emailCaption.trailingAnchor],
        [self.secretField.heightAnchor constraintEqualToConstant:52.0],

        [self.submitButton.topAnchor constraintEqualToAnchor:self.secretField.bottomAnchor constant:100.0],
        [self.submitButton.leadingAnchor constraintEqualToAnchor:emailCaption.leadingAnchor],
        [self.submitButton.trailingAnchor constraintEqualToAnchor:emailCaption.trailingAnchor],
        [self.submitButton.heightAnchor constraintEqualToConstant:52.0],

        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];
}

- (void)buildRegisterPrompt {
    self.registerPromptView = [[UITextView alloc] init];
    self.registerPromptView.backgroundColor = UIColor.clearColor;
    self.registerPromptView.editable = NO;
    self.registerPromptView.scrollEnabled = NO;
    self.registerPromptView.textContainerInset = UIEdgeInsetsZero;
    self.registerPromptView.textContainer.lineFragmentPadding = 0;
    self.registerPromptView.delegate = self;
    self.registerPromptView.textAlignment = NSTextAlignmentCenter;
    self.registerPromptView.linkTextAttributes = @{
        NSForegroundColorAttributeName: [AcapeAuthFormKit accentTealColor],
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
    };
    self.registerPromptView.attributedText = [self registerAttributedText];
    self.registerPromptView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.formPanel addSubview:self.registerPromptView];

    [NSLayoutConstraint activateConstraints:@[
        [self.registerPromptView.centerXAnchor constraintEqualToAnchor:self.formPanel.centerXAnchor],
        [self.registerPromptView.topAnchor constraintEqualToAnchor:self.submitButton.bottomAnchor constant:70.0],
        [self.registerPromptView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.formPanel.leadingAnchor constant:24.0],
        [self.registerPromptView.trailingAnchor constraintLessThanOrEqualToAnchor:self.formPanel.trailingAnchor constant:-24.0],
    ]];
}

- (NSAttributedString *)registerAttributedText {
    NSString *prefix = AcapeRevealText(AcapeRevealTextKeyNoAccountPrefix);
    NSString *action = AcapeRevealText(AcapeRevealTextKeyRegisterAction);
    NSString *fullText = [NSString stringWithFormat:@"%@%@", prefix, action];

    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:fullText attributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:14],
        NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.55],
    }];

    NSRange actionRange = [fullText rangeOfString:action];
    if (actionRange.location != NSNotFound) {
        [text addAttributes:@{
            NSLinkAttributeName: @"acape://register",
            NSForegroundColorAttributeName: [AcapeAuthFormKit accentTealColor],
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
        } range:actionRange];
    }
    return text;
}

- (void)handleBackTap {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleRecoverTap {
    [self.navigationController pushViewController:[[AcapeRecoverScreen alloc] init] animated:YES];
}

- (void)handleSubmitTap {
    NSString *email = [self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *secret = self.secretField.text ?: @"";

    if ([email rangeOfString:@"@"].location == NSNotFound) {
        [self presentNoticeWithCopy:@"Please enter a valid email address."];
        return;
    }
    if (secret.length == 0) {
        [self presentNoticeWithCopy:@"Please enter your password."];
        return;
    }

    self.submitButton.enabled = NO;
    [self.loadingIndicator startAnimating];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.85 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.loadingIndicator stopAnimating];
        if ([[AcapeVaultStore shared] isIdentityAccessRevoked:email]) {
            [self presentNoticeWithCopy:AcapeRevealText(AcapeRevealTextKeyHubAccessRevoked)];
            self.submitButton.enabled = YES;
            return;
        }
        if (![[AcapeVaultStore shared] validateAccessWithIdentity:email secret:secret]) {
            [self presentNoticeWithCopy:AcapeRevealText(AcapeRevealTextKeyAccessInvalidCredential)];
            self.submitButton.enabled = YES;
            return;
        }
        [[AcapeVaultStore shared] markMemberSignedInWithIdentity:email];
        if (![AcapeVaultStore shared].currentMemberProfile.profileCompleted) {
            AcapeMemberDetailScreen *detailScreen = [[AcapeMemberDetailScreen alloc] init];
            detailScreen.completesOnAdvance = YES;
            [self.navigationController pushViewController:detailScreen animated:YES];
            self.submitButton.enabled = YES;
            return;
        }
        [AcapeAppNavigator presentHarborAsRootInWindow:self.view.window animated:YES];
    });
}

- (void)presentNoticeWithCopy:(NSString *)noticeText {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:noticeText
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if ([URL.absoluteString isEqualToString:@"acape://register"]) {
        [self.navigationController pushViewController:[[AcapeEnrollScreen alloc] init] animated:YES];
        return NO;
    }
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

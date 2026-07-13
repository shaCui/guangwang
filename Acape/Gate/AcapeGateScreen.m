#import "AcapeGateScreen.h"
#import "AcapeRevealText.h"
#import "AcapeConsentRingView.h"
#import "AcapeAccessScreen.h"
#import "AcapeEnrollScreen.h"
#import "AcapePolicyScreen.h"
#import "AcapeAppNavigator.h"
#import "AcapeVaultStore.h"
#import "AcapeLinkGateway.h"

static NSString * const kAcapeEULAAcceptedKey = @"AcapeEULAAccepted";

@interface AcapeGradientActionButton : UIButton
@property (nonatomic, strong) CAGradientLayer *fillGradient;
@end

@implementation AcapeGradientActionButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.fillGradient = [CAGradientLayer layer];
        self.fillGradient.colors = @[
            (__bridge id)[UIColor colorWithRed:205.0/255.0 green:255.0/255.0 blue:199.0/255.0 alpha:1.0].CGColor,
            (__bridge id)[UIColor colorWithRed:66.0/255.0 green:252.0/255.0 blue:244.0/255.0 alpha:1.0].CGColor,
        ];
        self.fillGradient.startPoint = CGPointMake(0.5, 0.0);
        self.fillGradient.endPoint = CGPointMake(0.5, 1.0);
        self.fillGradient.cornerRadius = 16.0;
        [self.layer insertSublayer:self.fillGradient atIndex:0];
        self.layer.cornerRadius = 16.0;
        self.clipsToBounds = YES;
        self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        [self setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.fillGradient.frame = self.bounds;
    self.fillGradient.cornerRadius = 16.0;
    self.layer.cornerRadius = 16.0;
}

@end

@interface AcapeGateHaloButton : UIButton
@property (nonatomic, strong) CAGradientLayer *fillGradient;
@end

@implementation AcapeGateHaloButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.fillGradient = [CAGradientLayer layer];
        self.fillGradient.colors = @[
            (__bridge id)[UIColor colorWithRed:205.0/255.0 green:255.0/255.0 blue:199.0/255.0 alpha:0.98].CGColor,
            (__bridge id)[UIColor colorWithRed:66.0/255.0 green:252.0/255.0 blue:244.0/255.0 alpha:0.98].CGColor,
        ];
        self.fillGradient.startPoint = CGPointMake(0.0, 0.5);
        self.fillGradient.endPoint = CGPointMake(1.0, 0.5);
        self.fillGradient.cornerRadius = 18.0;
        [self.layer insertSublayer:self.fillGradient atIndex:0];

        self.layer.cornerRadius = 18.0;
        self.layer.shadowColor = [UIColor colorWithRed:66.0/255.0 green:252.0/255.0 blue:244.0/255.0 alpha:1.0].CGColor;
        self.layer.shadowOpacity = 0.48;
        self.layer.shadowOffset = CGSizeMake(0.0, 6.0);
        self.layer.shadowRadius = 14.0;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.55].CGColor;
        self.clipsToBounds = NO;

        self.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBlack];
        [self setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        [self setTitleColor:[UIColor colorWithWhite:0.0 alpha:0.55] forState:UIControlStateHighlighted];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.fillGradient.frame = self.bounds;
    self.fillGradient.cornerRadius = 18.0;
    self.layer.cornerRadius = 18.0;
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:18.0].CGPath;
}

@end

@interface AcapeGateScreen () <UITextViewDelegate>

@property (nonatomic, strong) UIImageView *backdropImageView;
@property (nonatomic, strong) CAGradientLayer *shadeGradientLayer;
@property (nonatomic, strong) AcapeGateHaloButton *eulaControl;
@property (nonatomic, strong) UIImageView *brandMarkView;
@property (nonatomic, strong) UILabel *brandTitleLabel;
@property (nonatomic, strong) AcapeGradientActionButton *emailAccessButton;
@property (nonatomic, strong) UIButton *freshStartButton;
@property (nonatomic, strong) UIButton *consentToggleButton;
@property (nonatomic, strong) AcapeConsentRingView *consentRingView;
@property (nonatomic, strong) UIImageView *consentSelectedView;
@property (nonatomic, strong) UITextView *consentTextView;
@property (nonatomic, assign) BOOL consentAccepted;
@property (nonatomic, assign) BOOL eulaAccepted;
@property (nonatomic, assign) BOOL didPrimeLinkAccess;

@end

@implementation AcapeGateScreen

- (void)viewDidLoad {
    [super viewDidLoad];
    self.eulaAccepted = [[NSUserDefaults standardUserDefaults] boolForKey:kAcapeEULAAcceptedKey];
    self.consentAccepted = NO;
    [self buildBackdrop];
    [self buildEULAControl];
    [self buildBrandArea];
    [self buildActionButtons];
    [self buildConsentRow];
    [self refreshConsentAppearance];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.didPrimeLinkAccess) {
        return;
    }
    self.didPrimeLinkAccess = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.view.window) {
            return;
        }
        [AcapeLinkGateway requestSystemLinkAccessIfNeeded];
    });
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.shadeGradientLayer.frame = CGRectMake(0,
                                               self.view.bounds.size.height * 0.45,
                                               self.view.bounds.size.width,
                                               self.view.bounds.size.height * 0.55);
}

- (void)buildBackdrop {
    self.backdropImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gate_backdrop"]];
    self.backdropImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.backdropImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.backdropImageView];

    self.shadeGradientLayer = [CAGradientLayer layer];
    self.shadeGradientLayer.colors = @[
        (__bridge id)[UIColor colorWithWhite:0 alpha:0.0].CGColor,
        (__bridge id)[UIColor colorWithWhite:0 alpha:0.35].CGColor,
        (__bridge id)[UIColor colorWithWhite:0 alpha:0.72].CGColor,
    ];
    self.shadeGradientLayer.locations = @[@0.0, @0.35, @1.0];
    [self.view.layer addSublayer:self.shadeGradientLayer];

    [NSLayoutConstraint activateConstraints:@[
        [self.backdropImageView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.backdropImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.backdropImageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.backdropImageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)buildEULAControl {
    self.eulaControl = [[AcapeGateHaloButton alloc] initWithFrame:CGRectZero];
    [self.eulaControl setTitle:AcapeRevealText(AcapeRevealTextKeyEULATitle) forState:UIControlStateNormal];
    self.eulaControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.eulaControl addTarget:self action:@selector(handleEULATap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.eulaControl];

    [NSLayoutConstraint activateConstraints:@[
        [self.eulaControl.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-25.0],
        [self.eulaControl.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8.0],
        [self.eulaControl.widthAnchor constraintEqualToConstant:64.0],
        [self.eulaControl.heightAnchor constraintEqualToConstant:36.0],
    ]];
}

- (void)buildBrandArea {
    self.brandMarkView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"brand_mark"]];
    self.brandMarkView.contentMode = UIViewContentModeScaleAspectFit;
    self.brandMarkView.layer.cornerRadius = 24.0;
    self.brandMarkView.clipsToBounds = YES;
    self.brandMarkView.translatesAutoresizingMaskIntoConstraints = NO;

    self.brandTitleLabel = [[UILabel alloc] init];
    self.brandTitleLabel.text = @"Acape";
    self.brandTitleLabel.textColor = UIColor.whiteColor;
    self.brandTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.brandTitleLabel.font = [UIFont fontWithDescriptor:[[UIFont systemFontOfSize:28 weight:UIFontWeightBold].fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic]
                                                    size:28];
    self.brandTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *brandStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.brandMarkView, self.brandTitleLabel]];
    brandStack.axis = UILayoutConstraintAxisVertical;
    brandStack.alignment = UIStackViewAlignmentCenter;
    brandStack.spacing = 18.0;
    brandStack.translatesAutoresizingMaskIntoConstraints = NO;
    brandStack.tag = 1001;
    [self.view addSubview:brandStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.brandMarkView.widthAnchor constraintEqualToConstant:87.0],
        [self.brandMarkView.heightAnchor constraintEqualToConstant:87.0],
        [brandStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    ]];
}

- (void)buildActionButtons {
    self.emailAccessButton = [[AcapeGradientActionButton alloc] initWithFrame:CGRectZero];
    [self.emailAccessButton setTitle:AcapeRevealText(AcapeRevealTextKeyLoginByEmail) forState:UIControlStateNormal];
    self.emailAccessButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.emailAccessButton addTarget:self action:@selector(handleEmailAccessTap) forControlEvents:UIControlEventTouchUpInside];

    self.freshStartButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.freshStartButton setTitle:AcapeRevealText(AcapeRevealTextKeyImNew) forState:UIControlStateNormal];
    [self.freshStartButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    self.freshStartButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.freshStartButton.backgroundColor = UIColor.whiteColor;
    self.freshStartButton.layer.cornerRadius = 16.0;
    self.freshStartButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.freshStartButton addTarget:self action:@selector(handleFreshStartTap) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *actionStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.emailAccessButton, self.freshStartButton]];
    actionStack.axis = UILayoutConstraintAxisHorizontal;
    actionStack.spacing = 12.0;
    actionStack.distribution = UIStackViewDistributionFill;
    actionStack.translatesAutoresizingMaskIntoConstraints = NO;
    actionStack.tag = 1002;
    [self.view addSubview:actionStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.emailAccessButton.heightAnchor constraintEqualToConstant:52.0],
        [self.freshStartButton.heightAnchor constraintEqualToConstant:52.0],
        [self.emailAccessButton.widthAnchor constraintEqualToAnchor:self.freshStartButton.widthAnchor multiplier:1.75],
        [actionStack.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:24.0],
        [actionStack.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-24.0],
    ]];
}

- (void)buildConsentRow {
    self.consentToggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.consentToggleButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.consentToggleButton addTarget:self action:@selector(handleConsentToggle) forControlEvents:UIControlEventTouchUpInside];

    self.consentRingView = [[AcapeConsentRingView alloc] init];
    self.consentRingView.translatesAutoresizingMaskIntoConstraints = NO;
    self.consentRingView.userInteractionEnabled = NO;

    self.consentSelectedView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gate_consent_selected"]];
    self.consentSelectedView.contentMode = UIViewContentModeScaleAspectFit;
    self.consentSelectedView.translatesAutoresizingMaskIntoConstraints = NO;
    self.consentSelectedView.userInteractionEnabled = NO;

    [self.consentToggleButton addSubview:self.consentRingView];
    [self.consentToggleButton addSubview:self.consentSelectedView];

    self.consentTextView = [[UITextView alloc] init];
    self.consentTextView.backgroundColor = UIColor.clearColor;
    self.consentTextView.editable = NO;
    self.consentTextView.scrollEnabled = NO;
    self.consentTextView.textContainerInset = UIEdgeInsetsZero;
    self.consentTextView.textContainer.lineFragmentPadding = 0;
    self.consentTextView.delegate = self;
    self.consentTextView.linkTextAttributes = @{
        NSForegroundColorAttributeName: UIColor.whiteColor,
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
    };
    self.consentTextView.attributedText = [self consentAttributedText];
    self.consentTextView.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *consentStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.consentToggleButton, self.consentTextView]];
    consentStack.axis = UILayoutConstraintAxisHorizontal;
    consentStack.alignment = UIStackViewAlignmentCenter;
    consentStack.spacing = 10.0;
    consentStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:consentStack];

    UIStackView *actionStack = [self.view viewWithTag:1002];
    UIStackView *brandStack = [self.view viewWithTag:1001];

    [NSLayoutConstraint activateConstraints:@[
        [self.consentToggleButton.widthAnchor constraintEqualToConstant:20.0],
        [self.consentToggleButton.heightAnchor constraintEqualToConstant:20.0],
        [self.consentRingView.topAnchor constraintEqualToAnchor:self.consentToggleButton.topAnchor],
        [self.consentRingView.leadingAnchor constraintEqualToAnchor:self.consentToggleButton.leadingAnchor],
        [self.consentRingView.trailingAnchor constraintEqualToAnchor:self.consentToggleButton.trailingAnchor],
        [self.consentRingView.bottomAnchor constraintEqualToAnchor:self.consentToggleButton.bottomAnchor],
        [self.consentSelectedView.topAnchor constraintEqualToAnchor:self.consentToggleButton.topAnchor],
        [self.consentSelectedView.leadingAnchor constraintEqualToAnchor:self.consentToggleButton.leadingAnchor],
        [self.consentSelectedView.trailingAnchor constraintEqualToAnchor:self.consentToggleButton.trailingAnchor],
        [self.consentSelectedView.bottomAnchor constraintEqualToAnchor:self.consentToggleButton.bottomAnchor],

        [consentStack.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:24.0],
        [consentStack.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-24.0],
        [consentStack.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-16.0],

        [actionStack.bottomAnchor constraintEqualToAnchor:consentStack.topAnchor constant:-20.0],
        [brandStack.bottomAnchor constraintEqualToAnchor:actionStack.topAnchor constant:-32.0],
    ]];
}

- (NSAttributedString *)consentAttributedText {
    NSString *prefix = AcapeRevealText(AcapeRevealTextKeyAgreePrefix);
    NSString *memberTerms = AcapeRevealText(AcapeRevealTextKeyMemberTerms);
    NSString *middle = AcapeRevealText(AcapeRevealTextKeyAgreeMiddle);
    NSString *privacyTerms = AcapeRevealText(AcapeRevealTextKeyPrivacyTerms);
    NSString *fullText = [NSString stringWithFormat:@"%@%@%@%@", prefix, memberTerms, middle, privacyTerms];

    UIColor *plainColor = [UIColor colorWithWhite:1.0 alpha:0.55];
    UIColor *linkColor = UIColor.whiteColor;

    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:fullText attributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:13],
        NSForegroundColorAttributeName: plainColor,
    }];

    NSRange memberRange = [fullText rangeOfString:memberTerms];
    NSRange privacyRange = [fullText rangeOfString:privacyTerms];
    if (memberRange.location != NSNotFound) {
        [text addAttributes:@{
            NSLinkAttributeName: @"acape://member-terms",
            NSForegroundColorAttributeName: linkColor,
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
        } range:memberRange];
    }
    if (privacyRange.location != NSNotFound) {
        [text addAttributes:@{
            NSLinkAttributeName: @"acape://privacy-terms",
            NSForegroundColorAttributeName: linkColor,
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
        } range:privacyRange];
    }
    return text;
}

- (void)refreshConsentAppearance {
    self.consentRingView.hidden = self.consentAccepted;
    self.consentSelectedView.hidden = !self.consentAccepted;
}

- (void)handleConsentToggle {
    self.consentAccepted = !self.consentAccepted;
    [self refreshConsentAppearance];
}

- (BOOL)ensureConsentAccepted {
    if (!self.eulaAccepted) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:@"Please agree to EULA before continuing."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return NO;
    }

    if (self.consentAccepted) {
        return YES;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Please agree to the terms before continuing."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
    return NO;
}

- (void)handleEmailAccessTap {
    if (![self ensureConsentAccepted]) {
        return;
    }
    AcapeAccessScreen *accessScreen = [[AcapeAccessScreen alloc] init];
    [self.navigationController pushViewController:accessScreen animated:YES];
}

- (void)handleFreshStartTap {
    if (![self ensureConsentAccepted]) {
        return;
    }
    [[AcapeVaultStore shared] clearMemberSession];
    [AcapeAppNavigator presentHarborAsRootInWindow:self.view.window animated:YES];
}

- (void)handleEULATap {
    __weak typeof(self) weakSelf = self;
    AcapePolicyScreen *policyScreen = [[AcapePolicyScreen alloc] init];
    policyScreen.initialTab = AcapePolicyTabTerms;
    policyScreen.showsAgreeAction = YES;
    policyScreen.onAgree = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.eulaAccepted = YES;
        strongSelf.consentAccepted = YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAcapeEULAAcceptedKey];
        [strongSelf refreshConsentAppearance];
    };
    [self.navigationController pushViewController:policyScreen animated:YES];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    AcapePolicyScreen *policyScreen = [[AcapePolicyScreen alloc] init];
    if ([URL.absoluteString isEqualToString:@"acape://member-terms"]) {
        policyScreen.initialTab = AcapePolicyTabTerms;
    } else if ([URL.absoluteString isEqualToString:@"acape://privacy-terms"]) {
        policyScreen.initialTab = AcapePolicyTabPrivacy;
    } else {
        return NO;
    }
    policyScreen.showsAgreeAction = NO;
    [self.navigationController pushViewController:policyScreen animated:YES];
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

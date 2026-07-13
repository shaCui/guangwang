#import "AcapePolicyScreen.h"
#import "AcapeRevealText.h"
#import "AcapeNavKit.h"
#import "AcapeAuthFormKit.h"
#import "AcapePrimaryActionButton.h"
#import "AcapeLatticeOverlay.h"

@interface AcapePolicyScreen ()

@property (nonatomic, strong) CAGradientLayer *headerGradientLayer;
@property (nonatomic, strong) AcapeLatticeOverlay *latticeOverlay;
@property (nonatomic, strong) UIButton *backControl;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *contentPanel;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *bodyLabel;
@property (nonatomic, strong) UIButton *termsTabButton;
@property (nonatomic, strong) UIButton *privacyTabButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) AcapePrimaryActionButton *agreeButton;
@property (nonatomic, assign) AcapePolicyTab activeTab;

@end

@implementation AcapePolicyScreen

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [AcapeAuthFormKit pageBackgroundColor];
    self.activeTab = self.initialTab;
    [self buildBackdrop];
    [self buildHeader];
    [self buildContentPanel];
    [self buildScrollArea];
    [self buildTabRow];
    if (self.showsAgreeAction) {
        [self buildActionRow];
    }
    [self refreshTabAppearance];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.headerGradientLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height * 0.34);
}

- (void)buildBackdrop {
    self.headerGradientLayer = [AcapeAuthFormKit headerGradientLayer];
    [self.view.layer addSublayer:self.headerGradientLayer];

    self.latticeOverlay = [[AcapeLatticeOverlay alloc] init];
    self.latticeOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.latticeOverlay];

    [NSLayoutConstraint activateConstraints:@[
        [self.latticeOverlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.latticeOverlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.latticeOverlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.latticeOverlay.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.28],
    ]];
}

- (void)buildHeader {
    self.backControl = [AcapeNavKit backControlWithTarget:self action:@selector(handleBackTap)];
    [self.view addSubview:self.backControl];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = [self currentHeaderText];
    self.titleLabel.textColor = UIColor.whiteColor;
    self.titleLabel.textAlignment = self.showsAgreeAction ? NSTextAlignmentCenter : NSTextAlignmentLeft;
    self.titleLabel.font = [UIFont systemFontOfSize:(self.showsAgreeAction ? 24.0 : 28.0) weight:UIFontWeightBold];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.titleLabel];

    NSMutableArray<NSLayoutConstraint *> *constraints = [@[
        [self.backControl.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:16.0],
        [self.backControl.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:4.0],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:56.0],
    ] mutableCopy];

    if (self.showsAgreeAction) {
        [constraints addObject:[self.titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor]];
    } else {
        [constraints addObject:[self.titleLabel.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:24.0]];
    }

    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)buildContentPanel {
    self.contentPanel = [[UIView alloc] init];
    self.contentPanel.backgroundColor = [UIColor colorWithRed:28.0/255.0 green:48.0/255.0 blue:51.0/255.0 alpha:1.0];
    self.contentPanel.layer.cornerRadius = self.showsAgreeAction ? 32.0 : 0.0;
    self.contentPanel.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.contentPanel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.contentPanel];

    [NSLayoutConstraint activateConstraints:@[
        [self.contentPanel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:(self.showsAgreeAction ? 12.0 : 16.0)],
        [self.contentPanel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.contentPanel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.contentPanel.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)buildScrollArea {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.alwaysBounceVertical = YES;
    [self.contentPanel addSubview:self.scrollView];

    self.bodyLabel = [[UILabel alloc] init];
    self.bodyLabel.textColor = [UIColor colorWithWhite:1.0 alpha:(self.showsAgreeAction ? 0.9 : 0.72)];
    self.bodyLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    self.bodyLabel.numberOfLines = 0;
    self.bodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self applyPolicyBodyText];
    [self.scrollView addSubview:self.bodyLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.contentPanel.topAnchor constant:(self.showsAgreeAction ? 20.0 : 0.0)],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.contentPanel.safeAreaLayoutGuide.leadingAnchor constant:(self.showsAgreeAction ? 24.0 : 24.0)],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.contentPanel.safeAreaLayoutGuide.trailingAnchor constant:-24.0],

        [self.bodyLabel.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor],
        [self.bodyLabel.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor],
        [self.bodyLabel.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor],
        [self.bodyLabel.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor],
        [self.bodyLabel.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor],
    ]];
}

- (void)applyPolicyBodyText {
    NSString *body = AcapeRevealText(AcapeRevealTextKeyEULABody);
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = self.showsAgreeAction ? 8.0 : 4.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

    NSMutableDictionary<NSAttributedStringKey, id> *attributes = [@{
        NSFontAttributeName: self.bodyLabel.font,
        NSForegroundColorAttributeName: self.bodyLabel.textColor,
        NSParagraphStyleAttributeName: paragraphStyle,
    } mutableCopy];

    self.bodyLabel.attributedText = [[NSAttributedString alloc] initWithString:body attributes:attributes];
}

- (NSString *)currentHeaderText {
    if (self.showsAgreeAction) {
        return AcapeRevealText(AcapeRevealTextKeyEULATitle);
    }
    return self.activeTab == AcapePolicyTabPrivacy ? AcapeRevealText(AcapeRevealTextKeyPrivacyPolicy) : AcapeRevealText(AcapeRevealTextKeyTermsOfUse);
}

- (void)buildTabRow {
    self.termsTabButton = [self tabButtonWithTitle:AcapeRevealText(AcapeRevealTextKeyTermsOfUse) action:@selector(handleTermsTabTap)];
    self.privacyTabButton = [self tabButtonWithTitle:AcapeRevealText(AcapeRevealTextKeyPrivacyPolicy) action:@selector(handlePrivacyTabTap)];

    UIStackView *tabStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.termsTabButton, self.privacyTabButton]];
    tabStack.axis = UILayoutConstraintAxisHorizontal;
    tabStack.spacing = 28.0;
    tabStack.distribution = UIStackViewDistributionEqualSpacing;
    tabStack.alignment = UIStackViewAlignmentCenter;
    tabStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentPanel addSubview:tabStack];

    CGFloat tabBottomConstant = self.showsAgreeAction ? -88.0 : -24.0;
    [NSLayoutConstraint activateConstraints:@[
        [tabStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [tabStack.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:tabBottomConstant],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:tabStack.topAnchor constant:-16.0],
    ]];
}

- (UIButton *)tabButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:(self.showsAgreeAction ? 14.0 : 15.0) weight:UIFontWeightSemibold];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)buildActionRow {
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelButton setTitle:AcapeRevealText(AcapeRevealTextKeyHubCancel) forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    self.cancelButton.backgroundColor = UIColor.blackColor;
    self.cancelButton.layer.cornerRadius = 14.0;
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cancelButton addTarget:self action:@selector(handleBackTap) forControlEvents:UIControlEventTouchUpInside];

    self.agreeButton = [[AcapePrimaryActionButton alloc] initWithFrame:CGRectZero];
    [self.agreeButton setTitle:AcapeRevealText(AcapeRevealTextKeyAgreeAction) forState:UIControlStateNormal];
    self.agreeButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    self.agreeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.agreeButton addTarget:self action:@selector(handleAgreeTap) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *actionStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.cancelButton, self.agreeButton]];
    actionStack.axis = UILayoutConstraintAxisHorizontal;
    actionStack.spacing = 20.0;
    actionStack.distribution = UIStackViewDistributionFillEqually;
    actionStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentPanel addSubview:actionStack];

    [NSLayoutConstraint activateConstraints:@[
        [actionStack.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:48.0],
        [actionStack.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-48.0],
        [actionStack.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-24.0],
        [actionStack.heightAnchor constraintEqualToConstant:42.0],
    ]];
}

- (void)refreshTabAppearance {
    UIColor *activeColor = UIColor.whiteColor;
    UIColor *inactiveColor = UIColor.whiteColor;

    [self.termsTabButton setTitleColor:(self.activeTab == AcapePolicyTabTerms ? activeColor : inactiveColor) forState:UIControlStateNormal];
    [self.privacyTabButton setTitleColor:(self.activeTab == AcapePolicyTabPrivacy ? activeColor : inactiveColor) forState:UIControlStateNormal];

    NSDictionary *activeAttrs = @{
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
        NSForegroundColorAttributeName: activeColor,
    };
    NSDictionary *inactiveAttrs = @{
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
        NSForegroundColorAttributeName: inactiveColor,
    };

    [self.termsTabButton setAttributedTitle:[[NSAttributedString alloc] initWithString:AcapeRevealText(AcapeRevealTextKeyTermsOfUse) attributes:(self.activeTab == AcapePolicyTabTerms ? activeAttrs : inactiveAttrs)] forState:UIControlStateNormal];
    [self.privacyTabButton setAttributedTitle:[[NSAttributedString alloc] initWithString:AcapeRevealText(AcapeRevealTextKeyPrivacyPolicy) attributes:(self.activeTab == AcapePolicyTabPrivacy ? activeAttrs : inactiveAttrs)] forState:UIControlStateNormal];
}

- (void)handleTermsTabTap {
    if (self.showsAgreeAction) {
        [self openPolicyDetailWithTab:AcapePolicyTabTerms];
        return;
    }
    self.activeTab = AcapePolicyTabTerms;
    self.titleLabel.text = [self currentHeaderText];
    [self refreshTabAppearance];
}

- (void)handlePrivacyTabTap {
    if (self.showsAgreeAction) {
        [self openPolicyDetailWithTab:AcapePolicyTabPrivacy];
        return;
    }
    self.activeTab = AcapePolicyTabPrivacy;
    self.titleLabel.text = [self currentHeaderText];
    [self refreshTabAppearance];
}

- (void)openPolicyDetailWithTab:(AcapePolicyTab)tab {
    AcapePolicyScreen *policyScreen = [[AcapePolicyScreen alloc] init];
    policyScreen.initialTab = tab;
    policyScreen.showsAgreeAction = NO;
    [self.navigationController pushViewController:policyScreen animated:YES];
}

- (void)handleBackTap {
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleAgreeTap {
    if (self.onAgree) {
        self.onAgree();
    }
    [self handleBackTap];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

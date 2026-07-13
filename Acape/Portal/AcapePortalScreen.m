#import "AcapePortalScreen.h"
#import "AcapeGateScreen.h"
#import "AcapeLatticeOverlay.h"

@interface AcapePortalScreen ()

@property (nonatomic, strong) CAGradientLayer *backdropGradientLayer;
@property (nonatomic, strong) AcapeLatticeOverlay *latticeOverlay;
@property (nonatomic, strong) UIImageView *brandMarkView;
@property (nonatomic, strong) UILabel *brandTitleLabel;

@end

@implementation AcapePortalScreen

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.04 green:0.06 blue:0.06 alpha:1.0];
    [self buildBackdrop];
    [self buildBrandStack];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.backdropGradientLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height * 0.42);
}

- (void)buildBackdrop {
    self.backdropGradientLayer = [CAGradientLayer layer];
    self.backdropGradientLayer.colors = @[
        (__bridge id)[UIColor colorWithRed:0.08 green:0.28 blue:0.26 alpha:0.95].CGColor,
        (__bridge id)[UIColor colorWithRed:0.05 green:0.12 blue:0.11 alpha:0.55].CGColor,
        (__bridge id)[UIColor colorWithRed:0.04 green:0.06 blue:0.06 alpha:0.0].CGColor,
    ];
    self.backdropGradientLayer.locations = @[@0.0, @0.45, @1.0];
    self.backdropGradientLayer.startPoint = CGPointMake(0.5, 0.0);
    self.backdropGradientLayer.endPoint = CGPointMake(0.5, 1.0);
    [self.view.layer addSublayer:self.backdropGradientLayer];

    self.latticeOverlay = [[AcapeLatticeOverlay alloc] init];
    self.latticeOverlay.backgroundColor = UIColor.clearColor;
    self.latticeOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.latticeOverlay];

    [NSLayoutConstraint activateConstraints:@[
        [self.latticeOverlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.latticeOverlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.latticeOverlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.latticeOverlay.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.34],
    ]];
}

- (void)buildBrandStack {
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
    [self.view addSubview:brandStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.brandMarkView.widthAnchor constraintEqualToConstant:87.0],
        [self.brandMarkView.heightAnchor constraintEqualToConstant:87.0],
        [brandStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [brandStack.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-70.0],
    ]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self scheduleGateTransitionIfNeeded];
}

- (void)scheduleGateTransitionIfNeeded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self transitionToGateScreen];
        });
    });
}

- (void)transitionToGateScreen {
    UIWindow *window = self.view.window;
    if (!window) {
        return;
    }
    AcapeGateScreen *gateScreen = [[AcapeGateScreen alloc] init];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:gateScreen];
    navigation.navigationBarHidden = YES;
    [UIView transitionWithView:window
                      duration:0.35
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        window.rootViewController = navigation;
    } completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

#import "AcapeFlagChoiceSheet.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeRevealText.h"

static CGFloat const kSideInset = 25.0;
static CGFloat const kButtonHeight = 52.0;

@interface AcapeFlagChoiceSheet ()
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) UIView *sheetView;
@property (nonatomic, strong) CAGradientLayer *sheetGradient;
@property (nonatomic, strong) CAGradientLayer *sheetMistGradient;
@property (nonatomic, assign) BOOL didRevealSheet;
@end

@implementation AcapeFlagChoiceSheet

- (instancetype)init {
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;

    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
    self.blurView.alpha = 0.0;
    self.blurView.userInteractionEnabled = NO;
    self.blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.blurView];

    self.dimView = [[UIView alloc] init];
    self.dimView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    self.dimView.alpha = 0.0;
    self.dimView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.dimView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismiss)]];
    [self.view addSubview:self.dimView];

    self.sheetView = [[UIView alloc] init];
    self.sheetView.backgroundColor = UIColor.clearColor;
    self.sheetView.layer.cornerRadius = 40.0;
    self.sheetView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.sheetView.clipsToBounds = YES;
    self.sheetView.translatesAutoresizingMaskIntoConstraints = NO;
    self.sheetGradient = [CAGradientLayer layer];
    self.sheetGradient.colors = @[
        (id)[UIColor colorWithRed:205.0 / 255.0 green:1.0 blue:199.0 / 255.0 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:66.0 / 255.0 green:252.0 / 255.0 blue:244.0 / 255.0 alpha:1.0].CGColor,
    ];
    self.sheetGradient.startPoint = CGPointMake(1.0, 0.5);
    self.sheetGradient.endPoint = CGPointMake(0.0, 0.5);
    [self.sheetView.layer insertSublayer:self.sheetGradient atIndex:0];
    self.sheetMistGradient = [CAGradientLayer layer];
    self.sheetMistGradient.colors = @[
        (id)[UIColor colorWithWhite:1.0 alpha:0.68].CGColor,
        (id)[UIColor colorWithWhite:1.0 alpha:1.0].CGColor,
    ];
    self.sheetMistGradient.startPoint = CGPointMake(0.5, 0.0);
    self.sheetMistGradient.endPoint = CGPointMake(0.5, 1.0);
    [self.sheetView.layer insertSublayer:self.sheetMistGradient above:self.sheetGradient];
    [self.view addSubview:self.sheetView];

    UILabel *prompt = [[UILabel alloc] init];
    prompt.text = AcapeRevealText(AcapeRevealTextKeyBondChoicePrompt);
    prompt.numberOfLines = 0;
    prompt.lineBreakMode = NSLineBreakByWordWrapping;
    prompt.textAlignment = NSTextAlignmentCenter;
    prompt.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    prompt.adjustsFontSizeToFitWidth = YES;
    prompt.minimumScaleFactor = 0.9;
    prompt.textColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:0.5];
    prompt.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sheetView addSubview:prompt];

    UIButton *reportButton = [self gradientButtonWithTitle:AcapeRevealText(AcapeRevealTextKeyBondReportAction)];
    [reportButton addTarget:self action:@selector(handleReport) forControlEvents:UIControlEventTouchUpInside];
    UIButton *blockButton = [self solidButtonWithTitle:AcapeRevealText(AcapeRevealTextKeyBondBlockAction2) titleColor:UIColor.whiteColor backgroundColor:[UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0]];
    [blockButton addTarget:self action:@selector(handleBlock) forControlEvents:UIControlEventTouchUpInside];
    UIButton *cancelButton = [self solidButtonWithTitle:AcapeRevealText(AcapeRevealTextKeyHubCancel) titleColor:[UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0] backgroundColor:[UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:0.1]];
    [cancelButton addTarget:self action:@selector(handleDismiss) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[reportButton, blockButton, cancelButton]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sheetView addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [self.blurView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.blurView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.blurView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.blurView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.dimView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.dimView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.dimView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.dimView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.sheetView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.sheetView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.sheetView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.sheetView.heightAnchor constraintEqualToConstant:320.0],

        [prompt.topAnchor constraintEqualToAnchor:self.sheetView.topAnchor constant:28.0],
        [prompt.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor constant:30.0],
        [prompt.trailingAnchor constraintEqualToAnchor:self.sheetView.trailingAnchor constant:-30.0],

        [stack.topAnchor constraintEqualToAnchor:prompt.bottomAnchor constant:24.0],
        [stack.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor constant:kSideInset],
        [stack.trailingAnchor constraintEqualToAnchor:self.sheetView.trailingAnchor constant:-kSideInset],
        [stack.bottomAnchor constraintEqualToAnchor:self.sheetView.safeAreaLayoutGuide.bottomAnchor constant:-16.0],
    ]];
    self.sheetView.transform = CGAffineTransformMakeTranslation(0.0, UIScreen.mainScreen.bounds.size.height);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.didRevealSheet) {
        self.blurView.alpha = 0.0;
        self.dimView.alpha = 0.0;
        [self.view layoutIfNeeded];
        self.sheetView.transform = [self hiddenSheetTransform];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.didRevealSheet) {
        return;
    }
    self.didRevealSheet = YES;
    [UIView animateWithDuration:0.24
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        self.blurView.alpha = 1.0;
        self.dimView.alpha = 1.0;
        self.sheetView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (UIButton *)solidButtonWithTitle:(NSString *)title titleColor:(UIColor *)titleColor backgroundColor:(UIColor *)bg {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:titleColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    button.backgroundColor = bg;
    button.layer.cornerRadius = 16.0;
    button.clipsToBounds = YES;
    [button.heightAnchor constraintEqualToConstant:kButtonHeight].active = YES;
    return button;
}

- (UIButton *)gradientButtonWithTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    button.layer.cornerRadius = 16.0;
    button.clipsToBounds = YES;
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[
        (id)[UIColor colorWithRed:0.804 green:1.0 blue:0.780 alpha:1.0].CGColor,
        (id)[AcapeAuroraBackdrop accentColor].CGColor,
    ];
    gradient.startPoint = CGPointMake(0.5, 0.0);
    gradient.endPoint = CGPointMake(0.5, 1.0);
    gradient.name = @"grad";
    [button.layer insertSublayer:gradient atIndex:0];
    [button.heightAnchor constraintEqualToConstant:kButtonHeight].active = YES;
    return button;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.sheetGradient.frame = self.sheetView.bounds;
    self.sheetMistGradient.frame = self.sheetView.bounds;
    for (UIView *sub in self.sheetView.subviews) {
        if ([sub isKindOfClass:UIStackView.class]) {
            for (UIView *button in [(UIStackView *)sub arrangedSubviews]) {
                for (CALayer *layer in button.layer.sublayers) {
                    if ([layer.name isEqualToString:@"grad"]) {
                        layer.frame = button.bounds;
                    }
                }
            }
        }
    }
}

#pragma mark - Actions

- (void)handleDismiss {
    [self dismissSheetWithCompletion:nil];
}

- (void)handleReport {
    void (^action)(void) = self.onReport;
    [self dismissSheetWithCompletion:^{
        if (action) { action(); }
    }];
}

- (void)handleBlock {
    void (^action)(void) = self.onBlock;
    [self dismissSheetWithCompletion:^{
        if (action) { action(); }
    }];
}

- (void)dismissSheetWithCompletion:(void (^ _Nullable)(void))completion {
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:0.18
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.blurView.alpha = 0.0;
        self.dimView.alpha = 0.0;
        self.sheetView.transform = [self hiddenSheetTransform];
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:completion];
    }];
}

- (CGAffineTransform)hiddenSheetTransform {
    CGFloat distance = CGRectGetHeight(self.sheetView.bounds) + self.view.safeAreaInsets.bottom;
    if (distance <= 0.0) {
        distance = UIScreen.mainScreen.bounds.size.height;
    }
    return CGAffineTransformMakeTranslation(0.0, distance);
}

@end

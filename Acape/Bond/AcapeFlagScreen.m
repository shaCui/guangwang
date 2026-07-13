#import "AcapeFlagScreen.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeNavKit.h"
#import "AcapeRevealText.h"
#import "UIViewController+AcapeDismissKeyboard.h"

static CGFloat const kSideInset = 25.0;
static CGFloat const kReasonHeight = 48.0;

@interface AcapeFlagScreen ()
@property (nonatomic, strong) AcapeAuroraBackdrop *backdrop;
@property (nonatomic, strong) UIButton *backControl;
@property (nonatomic, strong) NSMutableArray<UIButton *> *reasonButtons;
@property (nonatomic, strong) UITextView *explanationView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UIButton *submitButton;
@property (nonatomic, strong) CAGradientLayer *submitGradient;
@property (nonatomic, strong) UIView *progressOverlay;
@property (nonatomic, strong) UIView *successPill;
@property (nonatomic, assign) NSInteger selectedReasonIndex;
@property (nonatomic, assign) BOOL isSubmittingReport;
@end

@implementation AcapeFlagScreen

- (void)viewDidLoad {
    [super viewDidLoad];
    self.selectedReasonIndex = 0;
    self.view.backgroundColor = [AcapeAuroraBackdrop baseColor];
    [self buildBackdrop];
    [self buildHeader];
    [self buildContent];
    [self acape_enableDismissKeyboardOnBackgroundTap];
    [self refreshReasonStyles];
}

- (void)buildBackdrop {
    self.backdrop = [[AcapeAuroraBackdrop alloc] init];
    self.backdrop.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.backdrop];
    [NSLayoutConstraint activateConstraints:@[
        [self.backdrop.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.backdrop.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.backdrop.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.backdrop.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)buildHeader {
    self.backControl = [AcapeNavKit backControlWithTarget:self action:@selector(handleBackTap)];
    self.backControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.backControl];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = AcapeRevealText(AcapeRevealTextKeyBondReportTitle).uppercaseString;
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:titleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.backControl.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:kSideInset],
        [self.backControl.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8.0],
        [titleLabel.centerYAnchor constraintEqualToAnchor:self.backControl.centerYAnchor],
        [titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    ]];
}

- (void)buildContent {
    NSArray<NSString *> *reasons = @[
        AcapeRevealText(AcapeRevealTextKeyBondReasonHarass),
        AcapeRevealText(AcapeRevealTextKeyBondReasonDiscrim),
        AcapeRevealText(AcapeRevealTextKeyBondReasonPrivacy),
        AcapeRevealText(AcapeRevealTextKeyBondReasonVulgar),
        AcapeRevealText(AcapeRevealTextKeyBondReasonOthers),
    ];

    self.reasonButtons = [NSMutableArray array];
    for (NSInteger i = 0; i < reasons.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:reasons[i] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        button.layer.cornerRadius = 12.0;
        button.clipsToBounds = YES;
        button.tag = i;
        [button addTarget:self action:@selector(handleReasonTap:) forControlEvents:UIControlEventTouchUpInside];
        [self.reasonButtons addObject:button];
    }

    UIStackView *reasonStack = [[UIStackView alloc] initWithArrangedSubviews:self.reasonButtons];
    reasonStack.axis = UILayoutConstraintAxisVertical;
    reasonStack.spacing = 12.0;
    reasonStack.distribution = UIStackViewDistributionFillEqually;
    reasonStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:reasonStack];

    UIView *explanationBox = [[UIView alloc] init];
    explanationBox.backgroundColor = [AcapeAuroraBackdrop cardColor];
    explanationBox.layer.cornerRadius = 12.0;
    explanationBox.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:explanationBox];

    self.explanationView = [[UITextView alloc] init];
    self.explanationView.backgroundColor = UIColor.clearColor;
    self.explanationView.textColor = UIColor.whiteColor;
    self.explanationView.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.explanationView.tintColor = [AcapeAuroraBackdrop accentColor];
    self.explanationView.textContainerInset = UIEdgeInsetsMake(12.0, 12.0, 12.0, 12.0);
    self.explanationView.translatesAutoresizingMaskIntoConstraints = NO;
    [explanationBox addSubview:self.explanationView];

    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.text = AcapeRevealText(AcapeRevealTextKeyBondReportHelper);
    self.placeholderLabel.numberOfLines = 0;
    self.placeholderLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.placeholderLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [explanationBox addSubview:self.placeholderLabel];

    self.submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.submitButton setTitle:AcapeRevealText(AcapeRevealTextKeyBondSubmitAction) forState:UIControlStateNormal];
    [self.submitButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    self.submitButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    self.submitButton.layer.cornerRadius = 26.0;
    self.submitButton.clipsToBounds = YES;
    self.submitButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.submitButton addTarget:self action:@selector(handleSubmit) forControlEvents:UIControlEventTouchUpInside];
    self.submitGradient = [CAGradientLayer layer];
    self.submitGradient.colors = @[
        (id)[UIColor colorWithRed:0.804 green:1.0 blue:0.780 alpha:1.0].CGColor,
        (id)[AcapeAuroraBackdrop accentColor].CGColor,
    ];
    self.submitGradient.startPoint = CGPointMake(0.5, 0.0);
    self.submitGradient.endPoint = CGPointMake(0.5, 1.0);
    [self.submitButton.layer insertSublayer:self.submitGradient atIndex:0];
    [self.view addSubview:self.submitButton];

    [NSLayoutConstraint activateConstraints:@[
        [reasonStack.topAnchor constraintEqualToAnchor:self.backControl.bottomAnchor constant:28.0],
        [reasonStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:kSideInset],
        [reasonStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-kSideInset],
        [reasonStack.heightAnchor constraintEqualToConstant:kReasonHeight * 5 + 12.0 * 4],

        [explanationBox.topAnchor constraintEqualToAnchor:reasonStack.bottomAnchor constant:20.0],
        [explanationBox.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:kSideInset],
        [explanationBox.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-kSideInset],
        [explanationBox.heightAnchor constraintEqualToConstant:110.0],

        [self.explanationView.topAnchor constraintEqualToAnchor:explanationBox.topAnchor],
        [self.explanationView.leadingAnchor constraintEqualToAnchor:explanationBox.leadingAnchor],
        [self.explanationView.trailingAnchor constraintEqualToAnchor:explanationBox.trailingAnchor],
        [self.explanationView.bottomAnchor constraintEqualToAnchor:explanationBox.bottomAnchor],

        [self.placeholderLabel.topAnchor constraintEqualToAnchor:explanationBox.topAnchor constant:14.0],
        [self.placeholderLabel.leadingAnchor constraintEqualToAnchor:explanationBox.leadingAnchor constant:16.0],
        [self.placeholderLabel.trailingAnchor constraintEqualToAnchor:explanationBox.trailingAnchor constant:-16.0],

        [self.submitButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:kSideInset],
        [self.submitButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-kSideInset],
        [self.submitButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-24.0],
        [self.submitButton.heightAnchor constraintEqualToConstant:52.0],
    ]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTextChange) name:UITextViewTextDidChangeNotification object:self.explanationView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.submitGradient.frame = self.submitButton.bounds;
}

- (void)refreshReasonStyles {
    UIColor *darkInk = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0];
    for (UIButton *button in self.reasonButtons) {
        BOOL selected = (button.tag == self.selectedReasonIndex);
        button.backgroundColor = selected ? [AcapeAuroraBackdrop accentColor] : [AcapeAuroraBackdrop cardColor];
        [button setTitleColor:(selected ? darkInk : UIColor.whiteColor) forState:UIControlStateNormal];
    }
}

- (void)handleTextChange {
    self.placeholderLabel.hidden = self.explanationView.text.length > 0;
}

#pragma mark - Actions

- (void)handleBackTap {
    [self leaveFlagScreen];
}

- (void)leaveFlagScreen {
    if (self.navigationController.viewControllers.firstObject == self) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)handleReasonTap:(UIButton *)sender {
    self.selectedReasonIndex = sender.tag;
    [self refreshReasonStyles];
}

- (void)handleSubmit {
    if (self.isSubmittingReport) {
        return;
    }
    [self.view endEditing:YES];
    NSString *detailText = [self.explanationView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (self.selectedReasonIndex == 4 && detailText.length == 0) {
        [self showInputPromptPill];
        return;
    }
    self.isSubmittingReport = YES;
    self.submitButton.enabled = NO;
    [self showProgressOverlay];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hideProgressOverlay];
        [self showSuccessPill];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.65 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.isSubmittingReport = NO;
            self.submitButton.enabled = YES;
            [self leaveFlagScreen];
        });
    });
}

- (void)showInputPromptPill {
    [self.successPill removeFromSuperview];
    UIView *pill = [[UIView alloc] init];
    pill.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.58];
    pill.layer.cornerRadius = 16.0;
    pill.alpha = 0.0;
    pill.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:pill];

    UILabel *label = [[UILabel alloc] init];
    label.text = @"Please enter";
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [pill addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [pill.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [pill.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [label.topAnchor constraintEqualToAnchor:pill.topAnchor constant:12.0],
        [label.leadingAnchor constraintEqualToAnchor:pill.leadingAnchor constant:18.0],
        [label.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor constant:-18.0],
        [label.bottomAnchor constraintEqualToAnchor:pill.bottomAnchor constant:-12.0],
    ]];
    self.successPill = pill;
    [UIView animateWithDuration:0.18 animations:^{
        pill.alpha = 1.0;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.85 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.18 animations:^{
                pill.alpha = 0.0;
            } completion:^(BOOL finished2) {
                [pill removeFromSuperview];
            }];
        });
    }];
}

- (void)showProgressOverlay {
    if (self.progressOverlay.superview) {
        return;
    }
    UIView *overlay = [[UIView alloc] init];
    overlay.backgroundColor = UIColor.clearColor;
    overlay.userInteractionEnabled = YES;
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:overlay];

    UIView *plate = [[UIView alloc] init];
    plate.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.34];
    plate.layer.cornerRadius = 18.0;
    plate.translatesAutoresizingMaskIntoConstraints = NO;
    [overlay addSubview:plate];

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.color = UIColor.whiteColor;
    spinner.transform = CGAffineTransformMakeScale(0.82, 0.82);
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [plate addSubview:spinner];
    [spinner startAnimating];

    [NSLayoutConstraint activateConstraints:@[
        [overlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [overlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [overlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [overlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [plate.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [plate.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
        [plate.widthAnchor constraintEqualToConstant:58.0],
        [plate.heightAnchor constraintEqualToConstant:58.0],

        [spinner.centerXAnchor constraintEqualToAnchor:plate.centerXAnchor],
        [spinner.centerYAnchor constraintEqualToAnchor:plate.centerYAnchor],
    ]];
    self.progressOverlay = overlay;
}

- (void)hideProgressOverlay {
    [self.progressOverlay removeFromSuperview];
    self.progressOverlay = nil;
}

- (void)showSuccessPill {
    [self.successPill removeFromSuperview];
    UIView *pill = [[UIView alloc] init];
    pill.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.58];
    pill.layer.cornerRadius = 18.0;
    pill.alpha = 0.0;
    pill.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:pill];

    UILabel *label = [[UILabel alloc] init];
    label.text = AcapeRevealText(AcapeRevealTextKeyBondReportSubmitted);
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 2;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [pill addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [pill.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [pill.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [pill.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:44.0],
        [pill.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-44.0],

        [label.topAnchor constraintEqualToAnchor:pill.topAnchor constant:14.0],
        [label.leadingAnchor constraintEqualToAnchor:pill.leadingAnchor constant:18.0],
        [label.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor constant:-18.0],
        [label.bottomAnchor constraintEqualToAnchor:pill.bottomAnchor constant:-14.0],
    ]];
    self.successPill = pill;
    [UIView animateWithDuration:0.18 animations:^{
        pill.alpha = 1.0;
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

#import "AcapeAccessPromptScreen.h"
#import "AcapeAppNavigator.h"

@interface AcapeAccessPromptScreen ()

@property (nonatomic, strong) UIControl *dimmingControl;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *promptImageView;
@property (nonatomic, strong) UIButton *accessButton;
@property (nonatomic, strong) UIButton *closeButton;

@end

@implementation AcapeAccessPromptScreen

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    [self buildOverlay];
    [self buildCard];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat width = self.cardView.bounds.size.width;
    CGFloat height = self.cardView.bounds.size.height;
    self.closeButton.frame = CGRectMake(width * 0.064,
                                        height * 0.734,
                                        width * 0.411,
                                        height * 0.164);
    self.accessButton.frame = CGRectMake(width * 0.525,
                                         height * 0.734,
                                         width * 0.411,
                                         height * 0.164);
}

- (void)buildOverlay {
    self.dimmingControl = [[UIControl alloc] init];
    self.dimmingControl.backgroundColor = [UIColor colorWithWhite:0 alpha:0.70];
    self.dimmingControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.dimmingControl addTarget:self action:@selector(handleDismissTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.dimmingControl];

    [NSLayoutConstraint activateConstraints:@[
        [self.dimmingControl.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.dimmingControl.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.dimmingControl.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.dimmingControl.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)buildCard {
    self.cardView = [[UIView alloc] init];
    self.cardView.backgroundColor = UIColor.clearColor;
    self.cardView.clipsToBounds = NO;
    self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.cardView];

    self.promptImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"提示游客登录"]];
    self.promptImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.promptImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cardView addSubview:self.promptImageView];

    self.accessButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.accessButton.backgroundColor = UIColor.clearColor;
    [self.accessButton addTarget:self action:@selector(handleAccessTap) forControlEvents:UIControlEventTouchUpInside];
    [self.cardView addSubview:self.accessButton];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.backgroundColor = UIColor.clearColor;
    [self.closeButton addTarget:self action:@selector(handleDismissTap) forControlEvents:UIControlEventTouchUpInside];
    [self.cardView addSubview:self.closeButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.cardView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.cardView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.cardView.widthAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.widthAnchor constant:-48.0],
        [self.cardView.heightAnchor constraintEqualToAnchor:self.cardView.widthAnchor multiplier:879.0 / 915.0],

        [self.promptImageView.topAnchor constraintEqualToAnchor:self.cardView.topAnchor],
        [self.promptImageView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor],
        [self.promptImageView.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor],
        [self.promptImageView.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor],
    ]];

    NSLayoutConstraint *preferredWidth = [self.cardView.widthAnchor constraintEqualToConstant:305.0];
    preferredWidth.priority = UILayoutPriorityDefaultHigh;
    preferredWidth.active = YES;
}

- (void)handleDismissTap {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleAccessTap {
    UIWindow *window = self.view.window ?: self.presentingViewController.view.window;
    [self dismissViewControllerAnimated:YES completion:^{
        [AcapeAppNavigator presentGateAsRootInWindow:window animated:YES];
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

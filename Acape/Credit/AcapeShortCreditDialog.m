#import "AcapeShortCreditDialog.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeRevealText.h"

static CGFloat const kCardWidth = 305.0;
static CGFloat const kCardCornerRadius = 40.0;
static CGFloat const kSideInset = 25.0;
static CGFloat const kCornerMarkSize = 106.0;
static CGFloat const kButtonHeight = 48.0;
static CGFloat const kButtonCornerRadius = 16.0;
static CGFloat const kButtonSpacing = 12.0;

@interface AcapeShortRechargeFillView : UIView
@end

@implementation AcapeShortRechargeFillView

+ (Class)layerClass {
    return CAGradientLayer.class;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
        gradientLayer.colors = @[
            (id)[UIColor colorWithRed:205.0 / 255.0 green:1.0 blue:199.0 / 255.0 alpha:1.0].CGColor,
            (id)[AcapeAuroraBackdrop accentColor].CGColor,
        ];
        gradientLayer.startPoint = CGPointMake(0.0, 0.5);
        gradientLayer.endPoint = CGPointMake(1.0, 0.5);
        self.layer.cornerRadius = kButtonCornerRadius;
        self.clipsToBounds = YES;
    }
    return self;
}

@end

@interface AcapeShortCreditDialog ()
@property (nonatomic, strong) AcapeShortRechargeFillView *rechargeFillView;
@property (nonatomic, strong) UIButton *rechargeButton;
@end

@implementation AcapeShortCreditDialog

- (instancetype)init {
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = UIColor.clearColor;
    card.clipsToBounds = NO;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:card];

    UIView *whiteBase = [[UIView alloc] init];
    whiteBase.backgroundColor = UIColor.whiteColor;
    whiteBase.layer.cornerRadius = kCardCornerRadius;
    whiteBase.clipsToBounds = YES;
    whiteBase.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:whiteBase];

    UIImageView *cornerMark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"不足右上角"]];
    cornerMark.contentMode = UIViewContentModeScaleAspectFit;
    cornerMark.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:cornerMark];

    UIImageView *cardBackdrop = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"不足背景"]];
    cardBackdrop.contentMode = UIViewContentModeScaleToFill;
    cardBackdrop.layer.cornerRadius = kCardCornerRadius;
    cardBackdrop.clipsToBounds = YES;
    cardBackdrop.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:cardBackdrop];

    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.text = AcapeRevealText(AcapeRevealTextKeyCreditShortMessage);
    messageLabel.numberOfLines = 0;
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    messageLabel.textColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:0.85];
    messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:messageLabel];

    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setTitle:AcapeRevealText(AcapeRevealTextKeyHubCancel) forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0] forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    cancelButton.backgroundColor = [UIColor colorWithRed:0.937 green:0.937 blue:0.937 alpha:1.0];
    cancelButton.layer.cornerRadius = kButtonCornerRadius;
    cancelButton.clipsToBounds = YES;
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton addTarget:self action:@selector(handleCancel) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:cancelButton];

    self.rechargeFillView = [[AcapeShortRechargeFillView alloc] init];
    self.rechargeFillView.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:self.rechargeFillView];

    self.rechargeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.rechargeButton.backgroundColor = UIColor.clearColor;
    [self.rechargeButton setTitle:AcapeRevealText(AcapeRevealTextKeyCreditRechargeAction) forState:UIControlStateNormal];
    [self.rechargeButton setTitleColor:[UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0] forState:UIControlStateNormal];
    self.rechargeButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.rechargeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.rechargeButton addTarget:self action:@selector(handleRecharge) forControlEvents:UIControlEventTouchUpInside];
    [self.rechargeFillView addSubview:self.rechargeButton];

    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [card.widthAnchor constraintEqualToConstant:kCardWidth],

        [whiteBase.topAnchor constraintEqualToAnchor:card.topAnchor],
        [whiteBase.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [whiteBase.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [whiteBase.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],

        [cornerMark.topAnchor constraintEqualToAnchor:card.topAnchor constant:-32.0],
        [cornerMark.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:2.0],
        [cornerMark.widthAnchor constraintEqualToConstant:kCornerMarkSize],
        [cornerMark.heightAnchor constraintEqualToConstant:kCornerMarkSize],

        [cardBackdrop.topAnchor constraintEqualToAnchor:card.topAnchor],
        [cardBackdrop.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [cardBackdrop.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [cardBackdrop.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],

        [messageLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:68.0],
        [messageLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:kSideInset],
        [messageLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-kSideInset],

        [cancelButton.topAnchor constraintEqualToAnchor:messageLabel.bottomAnchor constant:40.0],
        [cancelButton.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:kSideInset],
        [cancelButton.widthAnchor constraintEqualToConstant:120.0],
        [cancelButton.heightAnchor constraintEqualToConstant:kButtonHeight],
        [cancelButton.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-30.0],

        [self.rechargeFillView.centerYAnchor constraintEqualToAnchor:cancelButton.centerYAnchor],
        [self.rechargeFillView.leadingAnchor constraintEqualToAnchor:cancelButton.trailingAnchor constant:kButtonSpacing],
        [self.rechargeFillView.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-kSideInset],
        [self.rechargeFillView.heightAnchor constraintEqualToConstant:kButtonHeight],
        [self.rechargeFillView.widthAnchor constraintEqualToAnchor:cancelButton.widthAnchor],

        [self.rechargeButton.topAnchor constraintEqualToAnchor:self.rechargeFillView.topAnchor],
        [self.rechargeButton.leadingAnchor constraintEqualToAnchor:self.rechargeFillView.leadingAnchor],
        [self.rechargeButton.trailingAnchor constraintEqualToAnchor:self.rechargeFillView.trailingAnchor],
        [self.rechargeButton.bottomAnchor constraintEqualToAnchor:self.rechargeFillView.bottomAnchor],
    ]];
}

- (void)handleRecharge {
    void (^action)(void) = self.onRecharge;
    [self dismissViewControllerAnimated:YES completion:^{
        if (action) { action(); }
    }];
}

- (void)handleCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

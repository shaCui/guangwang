#import "AcapePayConfirmDialog.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeRevealText.h"

static CGFloat const kCardWidth = 305.0;
static CGFloat const kCardHeight = 305.0;
static CGFloat const kCardCornerRadius = 40.0;
static CGFloat const kSideInset = 25.0;
static CGFloat const kCornerMarkSize = 106.0;
static CGFloat const kButtonHeight = 48.0;
static CGFloat const kButtonCornerRadius = 16.0;
static CGFloat const kCostRowCornerRadius = 20.0;
static CGFloat const kButtonSpacing = 12.0;

static UIColor *AcapePayAccentBlue(void) {
    return [UIColor colorWithRed:0.318 green:0.345 blue:1.0 alpha:1.0];
}

@interface AcapePaySureFillView : UIView
@end

@implementation AcapePaySureFillView

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

@interface AcapePayConfirmDialog ()
@property (nonatomic, assign) NSInteger cost;
@property (nonatomic, strong) AcapePaySureFillView *sureFillView;
@property (nonatomic, strong) UIButton *sureButton;
@end

@implementation AcapePayConfirmDialog

- (instancetype)initWithCost:(NSInteger)cost {
    self = [super init];
    if (self) {
        _cost = cost;
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

    UIImageView *cornerMark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"credit_coin_mark 1"]];
    cornerMark.contentMode = UIViewContentModeScaleAspectFit;
    cornerMark.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:cornerMark];

    UIImageView *cardBackdrop = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"消费背景"]];
    cardBackdrop.contentMode = UIViewContentModeScaleToFill;
    cardBackdrop.layer.cornerRadius = kCardCornerRadius;
    cardBackdrop.clipsToBounds = YES;
    cardBackdrop.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:cardBackdrop];

    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.attributedText = [self unlockMessageText];
    messageLabel.numberOfLines = 0;
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:messageLabel];

    UIView *costRow = [[UIView alloc] init];
    costRow.backgroundColor = [UIColor colorWithRed:0.937 green:0.937 blue:0.937 alpha:1.0];
    costRow.layer.cornerRadius = kCostRowCornerRadius;
    costRow.clipsToBounds = YES;
    costRow.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:costRow];

    UIImageView *coin = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"credit_coin_mark"]];
    coin.contentMode = UIViewContentModeScaleAspectFit;
    coin.translatesAutoresizingMaskIntoConstraints = NO;
    [costRow addSubview:coin];

    UILabel *amount = [[UILabel alloc] init];
    amount.text = [NSString stringWithFormat:@"-%ld", (long)self.cost];
    amount.textColor = AcapePayAccentBlue();
    amount.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    amount.translatesAutoresizingMaskIntoConstraints = NO;
    [costRow addSubview:amount];

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

    self.sureFillView = [[AcapePaySureFillView alloc] init];
    self.sureFillView.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:self.sureFillView];

    self.sureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sureButton.backgroundColor = UIColor.clearColor;
    [self.sureButton setTitle:AcapeRevealText(AcapeRevealTextKeyBondSureAction) forState:UIControlStateNormal];
    [self.sureButton setTitleColor:[UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0] forState:UIControlStateNormal];
    self.sureButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.sureButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sureButton addTarget:self action:@selector(handleSure) forControlEvents:UIControlEventTouchUpInside];
    [self.sureFillView addSubview:self.sureButton];

    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [card.widthAnchor constraintEqualToConstant:kCardWidth],
        [card.heightAnchor constraintEqualToConstant:kCardHeight],

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

        [costRow.topAnchor constraintEqualToAnchor:messageLabel.bottomAnchor constant:24.0],
        [costRow.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [costRow.heightAnchor constraintEqualToConstant:55.0],

        [coin.leadingAnchor constraintEqualToAnchor:costRow.leadingAnchor constant:14.0],
        [coin.centerYAnchor constraintEqualToAnchor:costRow.centerYAnchor],
        [coin.widthAnchor constraintEqualToConstant:32.0],
        [coin.heightAnchor constraintEqualToConstant:32.0],

        [amount.leadingAnchor constraintEqualToAnchor:coin.trailingAnchor constant:8.0],
        [amount.trailingAnchor constraintEqualToAnchor:costRow.trailingAnchor constant:-18.0],
        [amount.centerYAnchor constraintEqualToAnchor:costRow.centerYAnchor],

        [cancelButton.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:kSideInset],
        [cancelButton.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-30.0],
        [cancelButton.widthAnchor constraintEqualToConstant:120.0],
        [cancelButton.heightAnchor constraintEqualToConstant:kButtonHeight],

        [self.sureFillView.centerYAnchor constraintEqualToAnchor:cancelButton.centerYAnchor],
        [self.sureFillView.leadingAnchor constraintEqualToAnchor:cancelButton.trailingAnchor constant:kButtonSpacing],
        [self.sureFillView.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-kSideInset],
        [self.sureFillView.heightAnchor constraintEqualToConstant:kButtonHeight],
        [self.sureFillView.widthAnchor constraintEqualToAnchor:cancelButton.widthAnchor],

        [self.sureButton.topAnchor constraintEqualToAnchor:self.sureFillView.topAnchor],
        [self.sureButton.leadingAnchor constraintEqualToAnchor:self.sureFillView.leadingAnchor],
        [self.sureButton.trailingAnchor constraintEqualToAnchor:self.sureFillView.trailingAnchor],
        [self.sureButton.bottomAnchor constraintEqualToAnchor:self.sureFillView.bottomAnchor],
    ]];
}

- (NSAttributedString *)unlockMessageText {
    UIFont *bodyFont = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    UIFont *costFont = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    UIColor *bodyColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:0.85];
    NSDictionary *bodyAttributes = @{
        NSFontAttributeName: bodyFont,
        NSForegroundColorAttributeName: bodyColor,
    };
    NSDictionary *costAttributes = @{
        NSFontAttributeName: costFont,
        NSForegroundColorAttributeName: AcapePayAccentBlue(),
    };

    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:AcapeRevealText(AcapeRevealTextKeyMuseUnlockPrefix) attributes:bodyAttributes];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)self.cost] attributes:costAttributes]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:AcapeRevealText(AcapeRevealTextKeyMuseUnlockSuffix) attributes:bodyAttributes]];
    return text;
}

- (void)handleSure {
    void (^action)(void) = self.onConfirm;
    [self dismissViewControllerAnimated:YES completion:^{
        if (action) { action(); }
    }];
}

- (void)handleCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

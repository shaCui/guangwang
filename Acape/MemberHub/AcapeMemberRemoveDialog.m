#import "AcapeMemberRemoveDialog.h"
#import "AcapeRevealText.h"
#import "AcapeAuthFormKit.h"

static CGFloat const kAcapeRemoveCardWidth = 276.0;
static CGFloat const kAcapeRemoveCardCornerRadius = 36.0;
static CGFloat const kAcapeRemoveSideInset = 18.0;
static CGFloat const kAcapeRemoveButtonHeight = 42.0;
static CGFloat const kAcapeRemoveButtonCornerRadius = 16.0;
static CGFloat const kAcapeRemoveButtonSpacing = 12.0;
static CGFloat const kAcapeRemoveCornerMarkSize = 106.0;

@interface AcapeMemberRemoveSureFillView : UIView
@end

@implementation AcapeMemberRemoveSureFillView

+ (Class)layerClass {
    return CAGradientLayer.class;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
        gradientLayer.colors = @[
            (id)[UIColor colorWithRed:205.0 / 255.0 green:1.0 blue:199.0 / 255.0 alpha:1.0].CGColor,
            (id)[AcapeAuthFormKit accentTealColor].CGColor,
        ];
        gradientLayer.startPoint = CGPointMake(0.0, 0.5);
        gradientLayer.endPoint = CGPointMake(1.0, 0.5);
        self.layer.cornerRadius = kAcapeRemoveButtonCornerRadius;
        self.clipsToBounds = YES;
    }
    return self;
}

@end

@interface AcapeMemberRemoveDialog ()
@property (nonatomic, strong) AcapeMemberRemoveSureFillView *sureFillView;
@property (nonatomic, strong) UIButton *sureButton;
@end

@implementation AcapeMemberRemoveDialog

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
    card.layer.shadowColor = UIColor.blackColor.CGColor;
    card.layer.shadowOpacity = 0.14;
    card.layer.shadowRadius = 22.0;
    card.layer.shadowOffset = CGSizeMake(0.0, 10.0);
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:card];

    UIView *whiteBase = [[UIView alloc] init];
    whiteBase.backgroundColor = UIColor.whiteColor;
    whiteBase.layer.cornerRadius = kAcapeRemoveCardCornerRadius;
    whiteBase.clipsToBounds = YES;
    whiteBase.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:whiteBase];

    UIImageView *cornerMark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"删除账号右上角"]];
    cornerMark.contentMode = UIViewContentModeScaleAspectFit;
    cornerMark.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:cornerMark];

    UIImageView *cardBackdrop = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"删除账号背景"]];
    cardBackdrop.contentMode = UIViewContentModeScaleToFill;
    cardBackdrop.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:cardBackdrop];

    UILabel *message = [[UILabel alloc] init];
    message.text = AcapeRevealText(AcapeRevealTextKeyHubRemoveConfirm);
    message.numberOfLines = 0;
    message.textAlignment = NSTextAlignmentCenter;
    message.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    message.textColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0];
    message.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:message];

    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setTitle:AcapeRevealText(AcapeRevealTextKeyHubCancel) forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0] forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    cancelButton.backgroundColor = [UIColor colorWithRed:0.937 green:0.937 blue:0.937 alpha:1.0];
    cancelButton.layer.cornerRadius = kAcapeRemoveButtonCornerRadius;
    cancelButton.clipsToBounds = YES;
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton addTarget:self action:@selector(handleCancel) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:cancelButton];

    self.sureFillView = [[AcapeMemberRemoveSureFillView alloc] init];
    self.sureFillView.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:self.sureFillView];

    self.sureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sureButton.backgroundColor = UIColor.clearColor;
    [self.sureButton setTitle:AcapeRevealText(AcapeRevealTextKeyBondSureAction) forState:UIControlStateNormal];
    [self.sureButton setTitleColor:[UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0] forState:UIControlStateNormal];
    self.sureButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    self.sureButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sureButton addTarget:self action:@selector(handleSure) forControlEvents:UIControlEventTouchUpInside];
    [self.sureFillView addSubview:self.sureButton];

    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [card.widthAnchor constraintEqualToConstant:kAcapeRemoveCardWidth],
        [card.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [card.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24.0],

        [cornerMark.topAnchor constraintEqualToAnchor:card.topAnchor constant:-32.0],
        [cornerMark.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:2.0],
        [cornerMark.widthAnchor constraintEqualToConstant:kAcapeRemoveCornerMarkSize],
        [cornerMark.heightAnchor constraintEqualToConstant:kAcapeRemoveCornerMarkSize],

        [whiteBase.topAnchor constraintEqualToAnchor:card.topAnchor],
        [whiteBase.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [whiteBase.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [whiteBase.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],

        [cardBackdrop.topAnchor constraintEqualToAnchor:card.topAnchor],
        [cardBackdrop.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [cardBackdrop.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [cardBackdrop.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],

        [message.topAnchor constraintEqualToAnchor:card.topAnchor constant:92.0],
        [message.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:24.0],
        [message.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-24.0],

        [cancelButton.topAnchor constraintEqualToAnchor:message.bottomAnchor constant:30.0],
        [cancelButton.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:kAcapeRemoveSideInset],
        [cancelButton.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18.0],
        [cancelButton.heightAnchor constraintEqualToConstant:kAcapeRemoveButtonHeight],

        [self.sureFillView.centerYAnchor constraintEqualToAnchor:cancelButton.centerYAnchor],
        [self.sureFillView.leadingAnchor constraintEqualToAnchor:cancelButton.trailingAnchor constant:kAcapeRemoveButtonSpacing],
        [self.sureFillView.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-kAcapeRemoveSideInset],
        [self.sureFillView.heightAnchor constraintEqualToConstant:kAcapeRemoveButtonHeight],
        [self.sureFillView.widthAnchor constraintEqualToAnchor:cancelButton.widthAnchor],

        [self.sureButton.topAnchor constraintEqualToAnchor:self.sureFillView.topAnchor],
        [self.sureButton.leadingAnchor constraintEqualToAnchor:self.sureFillView.leadingAnchor],
        [self.sureButton.trailingAnchor constraintEqualToAnchor:self.sureFillView.trailingAnchor],
        [self.sureButton.bottomAnchor constraintEqualToAnchor:self.sureFillView.bottomAnchor],
    ]];
}

- (void)handleSure {
    void (^action)(void) = self.onConfirm;
    [self dismissViewControllerAnimated:YES completion:^{
        if (action) {
            action();
        }
    }];
}

- (void)handleCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

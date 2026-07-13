#import "AcapeCurbConfirmDialog.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeRevealText.h"
#import <QuartzCore/QuartzCore.h>

@interface AcapeCurbSureFillView : UIView
@end

@implementation AcapeCurbSureFillView

+ (Class)layerClass {
    return CAGradientLayer.class;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
        gradientLayer.colors = @[
            (id)[UIColor colorWithRed:205.0 / 255.0 green:1.0 blue:199.0 / 255.0 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:66.0 / 255.0 green:252.0 / 255.0 blue:244.0 / 255.0 alpha:1.0].CGColor,
        ];
        gradientLayer.locations = @[@0.0, @1.0];
        gradientLayer.startPoint = CGPointMake(0.5, 0.0);
        gradientLayer.endPoint = CGPointMake(0.5, 1.0);
        self.layer.cornerRadius = 16.0;
        self.clipsToBounds = YES;
    }
    return self;
}

@end

@interface AcapeCurbConfirmDialog ()
@property (nonatomic, strong) UIView *sureFillView;
@property (nonatomic, strong) UIButton *sureButton;
@end

@implementation AcapeCurbConfirmDialog

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
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:card];

    UIView *whiteBase = [[UIView alloc] init];
    whiteBase.backgroundColor = UIColor.whiteColor;
    whiteBase.layer.cornerRadius = 36.0;
    whiteBase.clipsToBounds = YES;
    whiteBase.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:whiteBase];

    UIImageView *cornerMark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"拉黑弹窗右上角"]];
    cornerMark.contentMode = UIViewContentModeScaleAspectFit;
    cornerMark.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:cornerMark];

    UIImageView *cardBackdrop = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"拉黑弹窗背景"]];
    cardBackdrop.contentMode = UIViewContentModeScaleToFill;
    cardBackdrop.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:cardBackdrop];

    UILabel *message = [[UILabel alloc] init];
    message.text = AcapeRevealText(AcapeRevealTextKeyBondBlockDialog);
    message.numberOfLines = 0;
    message.textAlignment = NSTextAlignmentCenter;
    message.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    message.textColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0];
    message.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:message];

    self.sureFillView = [[AcapeCurbSureFillView alloc] init];
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

    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setTitle:AcapeRevealText(AcapeRevealTextKeyHubCancel) forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0] forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    cancelButton.backgroundColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:0.1];
    cancelButton.layer.cornerRadius = 16.0;
    cancelButton.clipsToBounds = YES;
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton addTarget:self action:@selector(handleCancel) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:cancelButton];

    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [card.widthAnchor constraintEqualToConstant:276.0],
        [card.heightAnchor constraintEqualToConstant:276.0],

        [whiteBase.topAnchor constraintEqualToAnchor:card.topAnchor],
        [whiteBase.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [whiteBase.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [whiteBase.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],

        [cornerMark.topAnchor constraintEqualToAnchor:card.topAnchor constant:-28.0],
        [cornerMark.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-1.0],
        [cornerMark.widthAnchor constraintEqualToConstant:94.0],
        [cornerMark.heightAnchor constraintEqualToConstant:94.0],

        [cardBackdrop.topAnchor constraintEqualToAnchor:card.topAnchor],
        [cardBackdrop.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [cardBackdrop.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [cardBackdrop.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],

        [message.topAnchor constraintEqualToAnchor:card.topAnchor constant:96.0],
        [message.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22.0],
        [message.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-22.0],

        [cancelButton.topAnchor constraintEqualToAnchor:message.bottomAnchor constant:34.0],
        [cancelButton.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [cancelButton.widthAnchor constraintEqualToConstant:112.0],
        [cancelButton.heightAnchor constraintEqualToConstant:42.0],

        [self.sureFillView.centerYAnchor constraintEqualToAnchor:cancelButton.centerYAnchor],
        [self.sureFillView.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0],
        [self.sureFillView.widthAnchor constraintEqualToConstant:112.0],
        [self.sureFillView.heightAnchor constraintEqualToConstant:42.0],

        [self.sureButton.topAnchor constraintEqualToAnchor:self.sureFillView.topAnchor],
        [self.sureButton.leadingAnchor constraintEqualToAnchor:self.sureFillView.leadingAnchor],
        [self.sureButton.trailingAnchor constraintEqualToAnchor:self.sureFillView.trailingAnchor],
        [self.sureButton.bottomAnchor constraintEqualToAnchor:self.sureFillView.bottomAnchor],
    ]];
}

- (void)handleSure {
    UIWindow *toastWindow = self.view.window;
    void (^action)(void) = self.onConfirm;
    [self dismissViewControllerAnimated:YES completion:^{
        if (action) { action(); }
        [AcapeCurbConfirmDialog showCurbSuccessToastInWindow:toastWindow];
    }];
}

- (void)handleCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

+ (void)showCurbSuccessToastInWindow:(UIWindow *)window {
    if (!window) {
        return;
    }

    UIView *pill = [[UIView alloc] init];
    pill.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.58];
    pill.layer.cornerRadius = 18.0;
    pill.alpha = 0.0;
    pill.translatesAutoresizingMaskIntoConstraints = NO;
    [window addSubview:pill];

    UILabel *label = [[UILabel alloc] init];
    label.text = @"Blocked successfully";
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [pill addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [pill.centerXAnchor constraintEqualToAnchor:window.centerXAnchor],
        [pill.centerYAnchor constraintEqualToAnchor:window.centerYAnchor],
        [pill.leadingAnchor constraintGreaterThanOrEqualToAnchor:window.leadingAnchor constant:44.0],
        [pill.trailingAnchor constraintLessThanOrEqualToAnchor:window.trailingAnchor constant:-44.0],

        [label.topAnchor constraintEqualToAnchor:pill.topAnchor constant:14.0],
        [label.leadingAnchor constraintEqualToAnchor:pill.leadingAnchor constant:18.0],
        [label.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor constant:-18.0],
        [label.bottomAnchor constraintEqualToAnchor:pill.bottomAnchor constant:-14.0],
    ]];

    [UIView animateWithDuration:0.18 animations:^{
        pill.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.18 delay:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            pill.alpha = 0.0;
        } completion:^(BOOL innerFinished) {
            [pill removeFromSuperview];
        }];
    }];
}

@end

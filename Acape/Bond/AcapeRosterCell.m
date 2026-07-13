#import "AcapeRosterCell.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeRevealText.h"
#import "AcapeVaultStore.h"

@interface AcapeRosterPillBackingView : UIView
@property (nonatomic, assign) BOOL showsGradient;
@end

@interface AcapeRosterPillBackingView ()
@property (nonatomic, strong) CAGradientLayer *toneLayer;
@end

@implementation AcapeRosterPillBackingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _toneLayer = [CAGradientLayer layer];
        _toneLayer.colors = @[
            (id)[UIColor colorWithRed:0.804 green:1.0 blue:0.780 alpha:1.0].CGColor,
            (id)[AcapeAuroraBackdrop accentColor].CGColor,
        ];
        _toneLayer.startPoint = CGPointMake(0.5, 0.0);
        _toneLayer.endPoint = CGPointMake(0.5, 1.0);
        _toneLayer.cornerRadius = 12.0;
        _toneLayer.hidden = YES;
        [self.layer addSublayer:_toneLayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.toneLayer.frame = self.bounds;
}

- (void)setShowsGradient:(BOOL)showsGradient {
    _showsGradient = showsGradient;
    self.toneLayer.hidden = !showsGradient;
}

@end

@interface AcapeRosterCell ()
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) AcapeRosterPillBackingView *pillBackingView;
@property (nonatomic, strong) UIButton *pillButton;
@end

@implementation AcapeRosterCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildLayout];
    }
    return self;
}

- (void)buildLayout {
    self.contentView.backgroundColor = UIColor.clearColor;

    self.cardView = [[UIView alloc] init];
    self.cardView.backgroundColor = [UIColor colorWithRed:31.0 / 255.0 green:51.0 / 255.0 blue:55.0 / 255.0 alpha:1.0];
    self.cardView.layer.cornerRadius = 20.0;
    self.cardView.clipsToBounds = YES;
    self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.cardView];

    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.layer.cornerRadius = 24.0;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cardView addSubview:self.avatarView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.textColor = UIColor.whiteColor;
    self.nameLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cardView addSubview:self.nameLabel];

    self.pillBackingView = [[AcapeRosterPillBackingView alloc] init];
    self.pillBackingView.layer.cornerRadius = 12.0;
    self.pillBackingView.clipsToBounds = YES;
    self.pillBackingView.userInteractionEnabled = NO;
    self.pillBackingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cardView addSubview:self.pillBackingView];

    self.pillButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.pillButton.layer.cornerRadius = 12.0;
    self.pillButton.clipsToBounds = YES;
    self.pillButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    self.pillButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.pillButton addTarget:self action:@selector(handlePillTap) forControlEvents:UIControlEventTouchUpInside];
    [self.cardView addSubview:self.pillButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],

        [self.avatarView.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:22.0],
        [self.avatarView.centerXAnchor constraintEqualToAnchor:self.cardView.centerXAnchor],
        [self.avatarView.widthAnchor constraintEqualToConstant:54.0],
        [self.avatarView.heightAnchor constraintEqualToConstant:54.0],

        [self.nameLabel.topAnchor constraintEqualToAnchor:self.avatarView.bottomAnchor constant:13.0],
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:8.0],
        [self.nameLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-8.0],

        [self.pillBackingView.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor constant:-13.0],
        [self.pillBackingView.centerXAnchor constraintEqualToAnchor:self.cardView.centerXAnchor],
        [self.pillBackingView.widthAnchor constraintEqualToConstant:86.0],
        [self.pillBackingView.heightAnchor constraintEqualToConstant:24.0],

        [self.pillButton.topAnchor constraintEqualToAnchor:self.pillBackingView.topAnchor],
        [self.pillButton.leadingAnchor constraintEqualToAnchor:self.pillBackingView.leadingAnchor],
        [self.pillButton.trailingAnchor constraintEqualToAnchor:self.pillBackingView.trailingAnchor],
        [self.pillButton.bottomAnchor constraintEqualToAnchor:self.pillBackingView.bottomAnchor],
    ]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)configureWithMember:(AcapeSocialMember *)member mode:(AcapeRosterMode)mode {
    self.avatarView.image = [[AcapeVaultStore shared] avatarImageForAssetName:member.avatarAssetName];
    self.nameLabel.text = member.displayName;

    UIColor *darkInk = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0];
    if (mode == AcapeRosterModeCurbed) {
        self.pillBackingView.showsGradient = NO;
        self.pillBackingView.backgroundColor = [AcapeAuroraBackdrop accentColor];
        self.pillButton.backgroundColor = UIColor.clearColor;
        [self.pillButton setTitle:AcapeRevealText(AcapeRevealTextKeyBondRemoveAction) forState:UIControlStateNormal];
        [self.pillButton setTitleColor:darkInk forState:UIControlStateNormal];
        self.pillButton.titleLabel.alpha = 1.0;
        return;
    }

    if (member.bonded) {
        self.pillBackingView.showsGradient = NO;
        self.pillBackingView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        self.pillButton.backgroundColor = UIColor.clearColor;
        [self.pillButton setTitle:AcapeRevealText(AcapeRevealTextKeyBondJoinedAction) forState:UIControlStateNormal];
        [self.pillButton setTitleColor:[darkInk colorWithAlphaComponent:0.5] forState:UIControlStateNormal];
    } else {
        self.pillBackingView.showsGradient = YES;
        self.pillBackingView.backgroundColor = UIColor.clearColor;
        self.pillButton.backgroundColor = UIColor.clearColor;
        [self.pillButton setTitle:AcapeRevealText(AcapeRevealTextKeyBondJoinAction) forState:UIControlStateNormal];
        [self.pillButton setTitleColor:darkInk forState:UIControlStateNormal];
    }
}

- (void)handlePillTap {
    if (self.actionHandler) {
        self.actionHandler();
    }
}

@end

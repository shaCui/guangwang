#import "AcapeSignalBubbleCell.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeVaultStore.h"

static CGFloat const kSideInset = 20.0;
static CGFloat const kAvatarSize = 40.0;
static CGFloat const kAvatarGap = 7.0;
static CGFloat const kBubblePadding = 16.0;
static CGFloat const kBubbleMaxWidth = 272.0;
static CGFloat const kSignalTextMinWidth = 96.0;
static CGFloat const kSignalAudioMinWidth = 126.0;

@interface AcapeSignalBubbleCell ()
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *bodyLabel;
@property (nonatomic, strong) UIStackView *meterBarsView;
@property (nonatomic, copy) NSArray<UIView *> *meterBarViews;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) NSLayoutConstraint *bodyLeadingToIconC;
@property (nonatomic, strong) NSLayoutConstraint *bodyLeadingToBubbleC;
@property (nonatomic, strong) NSLayoutConstraint *avatarLeadingC;
@property (nonatomic, strong) NSLayoutConstraint *avatarTrailingC;
@property (nonatomic, strong) NSLayoutConstraint *bubbleLeadingC;
@property (nonatomic, strong) NSLayoutConstraint *bubbleTrailingC;
@property (nonatomic, strong) NSLayoutConstraint *bubbleMaxWidthC;
@property (nonatomic, strong) NSLayoutConstraint *bubbleTextMinWidthC;
@property (nonatomic, strong) NSLayoutConstraint *bubbleAudioWidthC;
@property (nonatomic, strong) NSLayoutConstraint *timeLeadingC;
@property (nonatomic, strong) NSLayoutConstraint *timeTrailingC;
@end

@implementation AcapeSignalBubbleCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.contentView.backgroundColor = UIColor.clearColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self buildLayout];
    }
    return self;
}

- (void)buildLayout {
    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.layer.cornerRadius = kAvatarSize / 2.0;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.avatarView];

    self.bubbleView = [[UIView alloc] init];
    self.bubbleView.layer.cornerRadius = 20.0;
    self.bubbleView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.bubbleView];

    self.bodyLabel = [[UILabel alloc] init];
    self.bodyLabel.numberOfLines = 0;
    self.bodyLabel.textColor = UIColor.whiteColor;
    self.bodyLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.bodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bubbleView addSubview:self.bodyLabel];

    self.meterBarsView = [[UIStackView alloc] init];
    self.meterBarsView.axis = UILayoutConstraintAxisHorizontal;
    self.meterBarsView.alignment = UIStackViewAlignmentCenter;
    self.meterBarsView.spacing = 3.0;
    self.meterBarsView.hidden = YES;
    self.meterBarsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bubbleView addSubview:self.meterBarsView];

    NSMutableArray<UIView *> *bars = [NSMutableArray array];
    NSArray<NSNumber *> *barHeights = @[@10.0, @17.0, @22.0, @14.0];
    for (NSNumber *height in barHeights) {
        UIView *bar = [[UIView alloc] init];
        bar.backgroundColor = UIColor.whiteColor;
        bar.layer.cornerRadius = 1.5;
        bar.translatesAutoresizingMaskIntoConstraints = NO;
        [self.meterBarsView addArrangedSubview:bar];
        [NSLayoutConstraint activateConstraints:@[
            [bar.widthAnchor constraintEqualToConstant:3.0],
            [bar.heightAnchor constraintEqualToConstant:height.doubleValue],
        ]];
        [bars addObject:bar];
    }
    self.meterBarViews = bars.copy;

    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.4];
    self.timeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bubbleView addSubview:self.timeLabel];

    self.avatarLeadingC = [self.avatarView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kSideInset];
    self.avatarTrailingC = [self.avatarView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kSideInset];
    self.bubbleLeadingC = [self.bubbleView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kSideInset];
    self.bubbleTrailingC = [self.bubbleView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kSideInset];
    self.timeLeadingC = [self.timeLabel.leadingAnchor constraintEqualToAnchor:self.bubbleView.leadingAnchor constant:kBubblePadding];
    self.timeTrailingC = [self.timeLabel.trailingAnchor constraintEqualToAnchor:self.bubbleView.trailingAnchor constant:-kBubblePadding];

    self.bubbleMaxWidthC = [self.bubbleView.widthAnchor constraintLessThanOrEqualToConstant:kBubbleMaxWidth];
    self.bubbleTextMinWidthC = [self.bubbleView.widthAnchor constraintGreaterThanOrEqualToConstant:kSignalTextMinWidth];
    self.bubbleAudioWidthC = [self.bubbleView.widthAnchor constraintEqualToConstant:kSignalAudioMinWidth];
    self.bubbleAudioWidthC.active = NO;

    [NSLayoutConstraint activateConstraints:@[
        [self.avatarView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:6.0],
        [self.avatarView.widthAnchor constraintEqualToConstant:kAvatarSize],
        [self.avatarView.heightAnchor constraintEqualToConstant:kAvatarSize],

        [self.bubbleView.topAnchor constraintEqualToAnchor:self.avatarView.topAnchor constant:kAvatarSize + kAvatarGap],
        self.bubbleMaxWidthC,
        self.bubbleTextMinWidthC,
        [self.bubbleView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-6.0],

        [self.meterBarsView.leadingAnchor constraintEqualToAnchor:self.bubbleView.leadingAnchor constant:kBubblePadding],
        [self.meterBarsView.centerYAnchor constraintEqualToAnchor:self.bodyLabel.centerYAnchor],
        [self.meterBarsView.widthAnchor constraintEqualToConstant:21.0],
        [self.meterBarsView.heightAnchor constraintEqualToConstant:24.0],

        [self.bodyLabel.topAnchor constraintEqualToAnchor:self.bubbleView.topAnchor constant:kBubblePadding],
        [self.bodyLabel.trailingAnchor constraintEqualToAnchor:self.bubbleView.trailingAnchor constant:-kBubblePadding],

        [self.timeLabel.topAnchor constraintEqualToAnchor:self.bodyLabel.bottomAnchor constant:8.0],
        [self.timeLabel.bottomAnchor constraintEqualToAnchor:self.bubbleView.bottomAnchor constant:-12.0],
    ]];

    self.bodyLeadingToBubbleC = [self.bodyLabel.leadingAnchor constraintEqualToAnchor:self.bubbleView.leadingAnchor constant:kBubblePadding];
    self.bodyLeadingToIconC = [self.bodyLabel.leadingAnchor constraintEqualToAnchor:self.meterBarsView.trailingAnchor constant:12.0];
    self.bodyLeadingToBubbleC.active = YES;
}

- (void)configureWithMessage:(AcapeSignalMessage *)message
             partnerAvatar:(NSString *)partnerAvatar
              viewerAvatar:(NSString *)viewerAvatar {
    if (message.kind == AcapeSignalMessageKindVoice) {
        self.meterBarsView.hidden = NO;
        self.bodyLeadingToBubbleC.active = NO;
        self.bodyLeadingToIconC.active = YES;
        self.bubbleTextMinWidthC.constant = kSignalAudioMinWidth;
        NSInteger seconds = MAX(1, message.voiceSeconds);
        self.bubbleMaxWidthC.constant = [UIScreen mainScreen].bounds.size.width * 0.6;
        self.bubbleAudioWidthC.constant = [self audioBubbleWidthForSeconds:seconds];
        self.bubbleAudioWidthC.active = YES;
        self.bodyLabel.text = [NSString stringWithFormat:@"0:%02ld", (long)seconds];
    } else {
        self.meterBarsView.hidden = YES;
        self.bodyLeadingToIconC.active = NO;
        self.bodyLeadingToBubbleC.active = YES;
        self.bubbleTextMinWidthC.constant = kSignalTextMinWidth;
        self.bubbleMaxWidthC.constant = kBubbleMaxWidth;
        self.bubbleAudioWidthC.active = NO;
        self.bodyLabel.text = message.body;
    }
    self.timeLabel.text = message.timeText;

    BOOL viewer = message.fromViewer;
    AcapeVaultStore *store = [AcapeVaultStore shared];
    self.avatarView.image = [store avatarImageForAssetName:viewer ? viewerAvatar : partnerAvatar];

    self.avatarLeadingC.active = !viewer;
    self.avatarTrailingC.active = viewer;
    self.bubbleLeadingC.active = !viewer;
    self.bubbleTrailingC.active = viewer;

    // Time alignment: left for incoming, right for outgoing.
    self.timeLabel.textAlignment = viewer ? NSTextAlignmentRight : NSTextAlignmentLeft;
    self.timeLeadingC.active = !viewer;
    self.timeTrailingC.active = viewer;

    if (viewer) {
        self.bubbleView.backgroundColor = [UIColor colorWithRed:0.235 green:0.0 blue:0.239 alpha:1.0];
    } else {
        self.bubbleView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    }
}

- (CGFloat)audioBubbleWidthForSeconds:(NSInteger)seconds {
    CGFloat maxWidth = [UIScreen mainScreen].bounds.size.width * 0.6;
    CGFloat range = MAX(0.0, maxWidth - kSignalAudioMinWidth);
    CGFloat progress = MIN(1.0, MAX(0.0, (CGFloat)seconds / 59.0));
    return MIN(maxWidth, kSignalAudioMinWidth + range * progress);
}

- (void)setVoicePulseActive:(BOOL)active {
    for (UIView *bar in self.meterBarViews) {
        [bar.layer removeAnimationForKey:@"acape.signal.meterPulse"];
        bar.transform = CGAffineTransformIdentity;
    }
    if (!active || self.meterBarsView.hidden) {
        return;
    }
    NSArray<NSNumber *> *delays = @[@0.0, @0.09, @0.18, @0.04];
    for (NSUInteger index = 0; index < self.meterBarViews.count; index++) {
        UIView *bar = self.meterBarViews[index];
        CAKeyframeAnimation *pulse = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"];
        pulse.values = @[@0.65, @1.35, @0.85, @1.15, @0.65];
        pulse.keyTimes = @[@0.0, @0.25, @0.52, @0.78, @1.0];
        pulse.duration = 0.62;
        pulse.beginTime = CACurrentMediaTime() + delays[index].doubleValue;
        pulse.repeatCount = HUGE_VALF;
        pulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [bar.layer addAnimation:pulse forKey:@"acape.signal.meterPulse"];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self setVoicePulseActive:NO];
    self.avatarLeadingC.active = NO;
    self.avatarTrailingC.active = NO;
    self.bubbleLeadingC.active = NO;
    self.bubbleTrailingC.active = NO;
    self.timeLeadingC.active = NO;
    self.timeTrailingC.active = NO;
    self.bodyLeadingToIconC.active = NO;
    self.bodyLeadingToBubbleC.active = YES;
    self.bubbleAudioWidthC.active = NO;
    self.bubbleTextMinWidthC.constant = kSignalTextMinWidth;
    self.bubbleMaxWidthC.constant = kBubbleMaxWidth;
    self.meterBarsView.hidden = YES;
}

@end

#import "AcapeCuratedFeedCell.h"
#import "AcapeVaultStore.h"

static CGFloat const kAcapeFeedCardWidth = 240.0;
static CGFloat const kAcapeFeedInfoPanelHeight = 85.0;
static CGFloat const kAcapeFeedCaptionTopSpacing = 10.0;
static CGFloat const kAcapeFeedCaptionBottomSpacing = 10.0;
static CGFloat const kAcapeFeedCaptionFontSize = 13.0;
static NSInteger const kAcapeFeedCaptionLineCount = 2;
static CGFloat const kAcapeFeedMemberAvatarTopInset = 12.0;
static CGFloat const kAcapeFeedMemberAvatarSize = 24.0;

@interface AcapeCuratedFeedCell ()

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) CAGradientLayer *coverGradient;
@property (nonatomic, strong) UIView *favorBadge;
@property (nonatomic, strong) UIImageView *favorIconView;
@property (nonatomic, strong) UILabel *favorLabel;
@property (nonatomic, strong) UIButton *favorControl;
@property (nonatomic, strong) UIButton *moreControl;
@property (nonatomic, strong) UIView *moreBadge;
@property (nonatomic, strong) UIButton *playControl;
@property (nonatomic, strong) UIView *infoPanel;
@property (nonatomic, strong) UIImageView *memberAvatarView;
@property (nonatomic, strong) UILabel *memberNameLabel;
@property (nonatomic, strong) UILabel *captionLabel;
@property (nonatomic, strong) NSLayoutConstraint *infoPanelHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *favorBadgeHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *favorIconWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *favorIconHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *playWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *playHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *memberAvatarWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *memberAvatarHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *memberAvatarTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *captionTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *captionHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *moreBadgeWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *moreBadgeHeightConstraint;
@property (nonatomic, assign) CGFloat appliedLayoutScale;

@end

@implementation AcapeCuratedFeedCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = UIColor.clearColor;

        self.cardView = [[UIView alloc] init];
        self.cardView.backgroundColor = [UIColor colorWithRed:0.067 green:0.075 blue:0.090 alpha:1.0];
        self.cardView.layer.cornerRadius = 30.0;
        self.cardView.clipsToBounds = YES;
        self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.cardView];

        self.coverImageView = [[UIImageView alloc] init];
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.coverImageView.clipsToBounds = YES;
        self.coverImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.cardView addSubview:self.coverImageView];

        self.coverGradient = [CAGradientLayer layer];
        [self.coverImageView.layer insertSublayer:self.coverGradient atIndex:0];

        self.infoPanel = [[UIView alloc] init];
        self.infoPanel.backgroundColor = [UIColor colorWithRed:0.122 green:0.200 blue:0.216 alpha:1.0];
        self.infoPanel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.cardView addSubview:self.infoPanel];

        self.favorBadge = [[UIView alloc] init];
        self.favorBadge.backgroundColor = [UIColor colorWithRed:0.608 green:0.596 blue:0.612 alpha:0.25];
        self.favorBadge.layer.cornerRadius = 18.0;
        self.favorBadge.translatesAutoresizingMaskIntoConstraints = NO;
        [self.cardView addSubview:self.favorBadge];

        self.favorIconView = [[UIImageView alloc] init];
        self.favorIconView.contentMode = UIViewContentModeScaleAspectFit;
        self.favorIconView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.favorBadge addSubview:self.favorIconView];

        self.favorLabel = [[UILabel alloc] init];
        self.favorLabel.textColor = UIColor.whiteColor;
        self.favorLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        self.favorLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.favorBadge addSubview:self.favorLabel];

        self.favorControl = [UIButton buttonWithType:UIButtonTypeCustom];
        self.favorControl.backgroundColor = UIColor.clearColor;
        self.favorControl.translatesAutoresizingMaskIntoConstraints = NO;
        [self.favorControl addTarget:self action:@selector(handleFavorTap) forControlEvents:UIControlEventTouchUpInside];
        [self.favorBadge addSubview:self.favorControl];

        self.moreBadge = [[UIView alloc] init];
        self.moreBadge.backgroundColor = [UIColor colorWithRed:0.608 green:0.596 blue:0.612 alpha:0.25];
        self.moreBadge.layer.cornerRadius = 18.0;
        self.moreBadge.translatesAutoresizingMaskIntoConstraints = NO;
        [self.cardView addSubview:self.moreBadge];

        self.moreControl = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.moreControl setImage:[UIImage systemImageNamed:@"ellipsis"] forState:UIControlStateNormal];
        self.moreControl.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.moreControl.tintColor = UIColor.whiteColor;
        self.moreControl.translatesAutoresizingMaskIntoConstraints = NO;
        [self.moreControl addTarget:self action:@selector(handleMoreTap) forControlEvents:UIControlEventTouchUpInside];
        [self.moreBadge addSubview:self.moreControl];

        self.playControl = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.playControl setImage:[UIImage imageNamed:@"harbor_entry_play_mark"] forState:UIControlStateNormal];
        self.playControl.adjustsImageWhenHighlighted = NO;
        self.playControl.translatesAutoresizingMaskIntoConstraints = NO;
        [self.cardView addSubview:self.playControl];

        self.memberAvatarView = [[UIImageView alloc] init];
        self.memberAvatarView.contentMode = UIViewContentModeScaleAspectFill;
        self.memberAvatarView.layer.cornerRadius = 12.0;
        self.memberAvatarView.clipsToBounds = YES;
        self.memberAvatarView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.infoPanel addSubview:self.memberAvatarView];

        self.memberNameLabel = [[UILabel alloc] init];
        self.memberNameLabel.textColor = UIColor.whiteColor;
        self.memberNameLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        self.memberNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.infoPanel addSubview:self.memberNameLabel];

        self.captionLabel = [[UILabel alloc] init];
        self.captionLabel.textColor = [UIColor colorWithWhite:1 alpha:0.5];
        self.captionLabel.font = [UIFont systemFontOfSize:kAcapeFeedCaptionFontSize weight:UIFontWeightRegular];
        self.captionLabel.numberOfLines = kAcapeFeedCaptionLineCount;
        self.captionLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.captionLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        self.captionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.infoPanel addSubview:self.captionLabel];

        [NSLayoutConstraint activateConstraints:@[
            [self.cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [self.cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [self.cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [self.cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],

            [self.coverImageView.topAnchor constraintEqualToAnchor:self.cardView.topAnchor],
            [self.coverImageView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor],
            [self.coverImageView.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor],
            [self.coverImageView.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor],

            [self.infoPanel.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor],
            [self.infoPanel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor],
            [self.infoPanel.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor],
            self.infoPanelHeightConstraint = [self.infoPanel.heightAnchor constraintEqualToConstant:kAcapeFeedInfoPanelHeight],

            [self.favorBadge.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:12.0],
            [self.favorBadge.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:12.0],
            self.favorBadgeHeightConstraint = [self.favorBadge.heightAnchor constraintEqualToConstant:36.0],
            [self.favorBadge.widthAnchor constraintGreaterThanOrEqualToConstant:60.0],

            [self.favorIconView.leadingAnchor constraintEqualToAnchor:self.favorBadge.leadingAnchor constant:10.0],
            [self.favorIconView.centerYAnchor constraintEqualToAnchor:self.favorBadge.centerYAnchor],
            self.favorIconWidthConstraint = [self.favorIconView.widthAnchor constraintEqualToConstant:16.0],
            self.favorIconHeightConstraint = [self.favorIconView.heightAnchor constraintEqualToConstant:16.0],

            [self.favorLabel.leadingAnchor constraintEqualToAnchor:self.favorIconView.trailingAnchor constant:6.0],
            [self.favorLabel.trailingAnchor constraintEqualToAnchor:self.favorBadge.trailingAnchor constant:-10.0],
            [self.favorLabel.centerYAnchor constraintEqualToAnchor:self.favorBadge.centerYAnchor],

            [self.favorControl.topAnchor constraintEqualToAnchor:self.favorBadge.topAnchor],
            [self.favorControl.leadingAnchor constraintEqualToAnchor:self.favorBadge.leadingAnchor],
            [self.favorControl.trailingAnchor constraintEqualToAnchor:self.favorBadge.trailingAnchor],
            [self.favorControl.bottomAnchor constraintEqualToAnchor:self.favorBadge.bottomAnchor],

            [self.moreBadge.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:12.0],
            [self.moreBadge.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-12.0],
            self.moreBadgeWidthConstraint = [self.moreBadge.widthAnchor constraintEqualToConstant:36.0],
            self.moreBadgeHeightConstraint = [self.moreBadge.heightAnchor constraintEqualToConstant:36.0],

            [self.moreControl.topAnchor constraintEqualToAnchor:self.moreBadge.topAnchor],
            [self.moreControl.leadingAnchor constraintEqualToAnchor:self.moreBadge.leadingAnchor],
            [self.moreControl.trailingAnchor constraintEqualToAnchor:self.moreBadge.trailingAnchor],
            [self.moreControl.bottomAnchor constraintEqualToAnchor:self.moreBadge.bottomAnchor],

            [self.playControl.centerYAnchor constraintEqualToAnchor:self.infoPanel.topAnchor],
            [self.playControl.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-12.0],
            self.playWidthConstraint = [self.playControl.widthAnchor constraintEqualToConstant:46.0],
            self.playHeightConstraint = [self.playControl.heightAnchor constraintEqualToConstant:46.0],

            self.memberAvatarTopConstraint = [self.memberAvatarView.topAnchor constraintEqualToAnchor:self.infoPanel.topAnchor constant:kAcapeFeedMemberAvatarTopInset],
            [self.memberAvatarView.leadingAnchor constraintEqualToAnchor:self.infoPanel.leadingAnchor constant:12.0],
            self.memberAvatarWidthConstraint = [self.memberAvatarView.widthAnchor constraintEqualToConstant:24.0],
            self.memberAvatarHeightConstraint = [self.memberAvatarView.heightAnchor constraintEqualToConstant:24.0],

            [self.memberNameLabel.centerYAnchor constraintEqualToAnchor:self.memberAvatarView.centerYAnchor],
            [self.memberNameLabel.leadingAnchor constraintEqualToAnchor:self.memberAvatarView.trailingAnchor constant:8.0],
            [self.memberNameLabel.trailingAnchor constraintEqualToAnchor:self.infoPanel.trailingAnchor constant:-12.0],

            [self.captionLabel.leadingAnchor constraintEqualToAnchor:self.infoPanel.leadingAnchor constant:12.0],
            [self.captionLabel.trailingAnchor constraintEqualToAnchor:self.infoPanel.trailingAnchor constant:-12.0],
            self.captionTopConstraint = [self.captionLabel.topAnchor constraintEqualToAnchor:self.memberAvatarView.bottomAnchor constant:kAcapeFeedCaptionTopSpacing],
            self.captionHeightConstraint = [self.captionLabel.heightAnchor constraintEqualToConstant:32.0],
        ]];
    }
    return self;
}

- (void)applyScaledLayoutForWidth:(CGFloat)width {
    if (width <= 0.0) {
        return;
    }

    CGFloat scale = width / kAcapeFeedCardWidth;
    self.appliedLayoutScale = scale;

    self.cardView.layer.cornerRadius = 30.0 * scale;
    self.favorBadge.layer.cornerRadius = 18.0 * scale;
    self.moreBadge.layer.cornerRadius = 18.0 * scale;
    self.moreBadgeWidthConstraint.constant = 36.0 * scale;
    self.moreBadgeHeightConstraint.constant = 36.0 * scale;
    self.memberAvatarView.layer.cornerRadius = 12.0 * scale;

    CGFloat captionFontSize = MAX(11.0, kAcapeFeedCaptionFontSize * scale);
    UIFont *captionFont = [UIFont systemFontOfSize:captionFontSize weight:UIFontWeightRegular];
    CGFloat captionLineHeight = ceil(captionFont.lineHeight);
    CGFloat captionBlockHeight = captionLineHeight * (CGFloat)kAcapeFeedCaptionLineCount;
    CGFloat avatarTopInset = kAcapeFeedMemberAvatarTopInset * scale;
    CGFloat avatarSize = kAcapeFeedMemberAvatarSize * scale;
    CGFloat captionTopSpacing = kAcapeFeedCaptionTopSpacing * scale;
    CGFloat captionBottomSpacing = kAcapeFeedCaptionBottomSpacing * scale;
    CGFloat panelHeight = avatarTopInset + avatarSize + captionTopSpacing + captionBlockHeight + captionBottomSpacing;

    self.infoPanelHeightConstraint.constant = MAX(kAcapeFeedInfoPanelHeight * scale, panelHeight);
    self.favorBadgeHeightConstraint.constant = 36.0 * scale;
    self.favorIconWidthConstraint.constant = 16.0 * scale;
    self.favorIconHeightConstraint.constant = 16.0 * scale;
    self.playWidthConstraint.constant = 46.0 * scale;
    self.playHeightConstraint.constant = 46.0 * scale;
    self.memberAvatarTopConstraint.constant = avatarTopInset;
    self.memberAvatarWidthConstraint.constant = avatarSize;
    self.memberAvatarHeightConstraint.constant = avatarSize;
    self.captionTopConstraint.constant = captionTopSpacing;
    self.captionHeightConstraint.constant = captionBlockHeight;
    self.favorLabel.font = [UIFont systemFontOfSize:14.0 * scale weight:UIFontWeightSemibold];
    self.memberNameLabel.font = [UIFont systemFontOfSize:14.0 * scale weight:UIFontWeightBold];
    self.captionLabel.font = captionFont;
    self.captionLabel.preferredMaxLayoutWidth = width - (24.0 * scale);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.coverGradient.frame = self.coverImageView.bounds;

    CGFloat width = CGRectGetWidth(self.contentView.bounds);
    if (width <= 0.0) {
        return;
    }

    CGFloat scale = width / kAcapeFeedCardWidth;
    if (fabs(scale - self.appliedLayoutScale) < 0.01) {
        return;
    }

    [self applyScaledLayoutForWidth:width];
}

- (void)configureWithEntry:(AcapeFeedEntry *)entry {
    [self configureWithEntry:entry useSeekCover:NO showsMoreControl:YES];
}

- (void)configureWithEntry:(AcapeFeedEntry *)entry useSeekCover:(BOOL)useSeekCover {
    [self configureWithEntry:entry useSeekCover:useSeekCover showsMoreControl:YES];
}

- (void)configureWithEntry:(AcapeFeedEntry *)entry useSeekCover:(BOOL)useSeekCover showsMoreControl:(BOOL)showsMoreControl {
    NSString *coverAssetName = entry.coverImageAssetName;
    if (useSeekCover && entry.seekCoverImageAssetName.length > 0) {
        coverAssetName = entry.seekCoverImageAssetName;
    }
    UIImage *coverImage = [[AcapeVaultStore shared] clipPreviewImageForEntry:entry];
    if (!coverImage && coverAssetName.length > 0) {
        coverImage = [UIImage imageNamed:coverAssetName];
    }
    self.coverImageView.image = coverImage;
    self.coverImageView.hidden = coverImage == nil;
    self.coverGradient.hidden = coverImage != nil;
    self.coverGradient.colors = @[
        (__bridge id)entry.coverTopColor.CGColor,
        (__bridge id)entry.coverBottomColor.CGColor,
    ];
    self.coverGradient.startPoint = CGPointMake(0.0, 0.0);
    self.coverGradient.endPoint = CGPointMake(1.0, 1.0);
    self.favorLabel.text = [NSString stringWithFormat:@"%ld", (long)entry.favorCount];
    NSString *favorAssetName = entry.isFavoredByViewer ? @"首页已喜欢" : @"首页未喜欢";
    self.favorIconView.image = [UIImage imageNamed:favorAssetName];
    self.favorBadge.backgroundColor = [UIColor colorWithRed:0.608 green:0.596 blue:0.612 alpha:0.25];
    self.favorLabel.textColor = UIColor.whiteColor;
    self.memberNameLabel.text = entry.memberName;
    self.captionLabel.text = entry.captionText;
    self.memberAvatarView.image = [[AcapeVaultStore shared] avatarImageForAssetName:entry.memberAvatarAssetName];
    self.moreBadge.hidden = !showsMoreControl;
    self.moreControl.userInteractionEnabled = showsMoreControl;
    [self applyScaledLayoutForWidth:CGRectGetWidth(self.contentView.bounds)];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.appliedLayoutScale = 0.0;
    self.onFavorTap = nil;
    self.onMoreTap = nil;
}

- (void)handleFavorTap {
    if (self.onFavorTap) {
        self.onFavorTap();
    }
}

- (void)handleMoreTap {
    if (self.onMoreTap) {
        self.onMoreTap();
    }
}

@end

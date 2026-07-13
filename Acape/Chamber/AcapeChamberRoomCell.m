#import "AcapeChamberRoomCell.h"
#import "AcapeChamberJoinButton.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeVaultStore.h"

static CGFloat const kRoomPointerDesignWidth = 20.0;
static CGFloat const kRoomPointerCardGap = 25.0;
static CGFloat const kRoomPointerDesignScreenHeight = 812.0;
static CGFloat const kCardTrailingInset = 25.0;
static CGFloat const kFocusedScale = 1.06;
static CGFloat const kIdleScale = 0.94;

@interface AcapeChamberRoomCell ()
@property (nonatomic, strong) UIImageView *cardBackgroundView;
@property (nonatomic, strong) NSLayoutConstraint *cardLeadingConstraint;
@property (nonatomic, strong) UIImageView *coverView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIView *dotsContainer;
@property (nonatomic, strong) NSLayoutConstraint *dotsContainerWidthConstraint;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *dotViews;
@property (nonatomic, strong) UIView *countPill;
@property (nonatomic, strong) UIImageView *listenerIconView;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) AcapeChamberJoinButton *joinButton;
@property (nonatomic, assign) BOOL roomFocused;
@end

@implementation AcapeChamberRoomCell

+ (CGFloat)cardLeadingInset {
    CGFloat screenHeight = CGRectGetHeight(UIScreen.mainScreen.bounds);
    if (screenHeight <= 0.0) {
        screenHeight = kRoomPointerDesignScreenHeight;
    }
    CGFloat scale = screenHeight / kRoomPointerDesignScreenHeight;
    return kRoomPointerDesignWidth * scale + kRoomPointerCardGap;
}

+ (CGFloat)rowHeight { return 126.0; }

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.contentView.backgroundColor = UIColor.clearColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.roomFocused = NO;
        [self buildLayout];
    }
    return self;
}

- (void)buildLayout {
    self.cardBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"k歌房背景"]];
    self.cardBackgroundView.userInteractionEnabled = YES;
    self.cardBackgroundView.contentMode = UIViewContentModeScaleToFill;
    self.cardBackgroundView.clipsToBounds = YES;
    self.cardBackgroundView.layer.cornerRadius = 18.0;
    self.cardBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.cardBackgroundView];

    self.coverView = [[UIImageView alloc] init];
    self.coverView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverView.layer.cornerRadius = 37.0;
    self.coverView.clipsToBounds = YES;
    self.coverView.layer.borderWidth = 2.0;
    self.coverView.layer.borderColor = [AcapeAuroraBackdrop accentColor].CGColor;
    self.coverView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cardBackgroundView addSubview:self.coverView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.textColor = UIColor.whiteColor;
    self.nameLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cardBackgroundView addSubview:self.nameLabel];

    self.dotsContainer = [[UIView alloc] init];
    self.dotsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cardBackgroundView addSubview:self.dotsContainer];
    self.dotViews = [NSMutableArray array];
    for (NSInteger i = 0; i < 3; i++) {
        UIImageView *dot = [[UIImageView alloc] init];
        dot.contentMode = UIViewContentModeScaleAspectFill;
        dot.layer.cornerRadius = 10.0;
        dot.clipsToBounds = YES;
        dot.layer.borderWidth = 1.0;
        dot.layer.borderColor = UIColor.whiteColor.CGColor;
        dot.translatesAutoresizingMaskIntoConstraints = NO;
        dot.hidden = YES;
        [self.dotsContainer addSubview:dot];
        [self.dotViews addObject:dot];
        [NSLayoutConstraint activateConstraints:@[
            [dot.widthAnchor constraintEqualToConstant:20.0],
            [dot.heightAnchor constraintEqualToConstant:20.0],
            [dot.centerYAnchor constraintEqualToAnchor:self.dotsContainer.centerYAnchor],
            [dot.leadingAnchor constraintEqualToAnchor:self.dotsContainer.leadingAnchor constant:i * 16.0],
        ]];
    }

    self.countPill = [[UIView alloc] init];
    self.countPill.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
    self.countPill.layer.cornerRadius = 10.0;
    self.countPill.clipsToBounds = YES;
    self.countPill.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cardBackgroundView addSubview:self.countPill];

    self.listenerIconView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"人数图标"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    self.listenerIconView.contentMode = UIViewContentModeScaleAspectFit;
    self.listenerIconView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.countPill addSubview:self.listenerIconView];

    self.countLabel = [[UILabel alloc] init];
    self.countLabel.textColor = UIColor.whiteColor;
    self.countLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    self.countLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.countPill addSubview:self.countLabel];

    self.joinButton = [[AcapeChamberJoinButton alloc] initWithFrame:CGRectZero];
    self.joinButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.joinButton addTarget:self action:@selector(handleJoin) forControlEvents:UIControlEventTouchUpInside];
    [self.cardBackgroundView addSubview:self.joinButton];

    self.cardLeadingConstraint = [self.cardBackgroundView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:[AcapeChamberRoomCell cardLeadingInset]];
    [NSLayoutConstraint activateConstraints:@[
        self.cardLeadingConstraint,
        [self.cardBackgroundView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kCardTrailingInset],
        [self.cardBackgroundView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:6.0],
        [self.cardBackgroundView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-6.0],

        [self.coverView.leadingAnchor constraintEqualToAnchor:self.cardBackgroundView.leadingAnchor constant:14.0],
        [self.coverView.centerYAnchor constraintEqualToAnchor:self.cardBackgroundView.centerYAnchor],
        [self.coverView.widthAnchor constraintEqualToConstant:74.0],
        [self.coverView.heightAnchor constraintEqualToConstant:74.0],

        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.coverView.trailingAnchor constant:14.0],
        [self.nameLabel.topAnchor constraintEqualToAnchor:self.coverView.topAnchor constant:6.0],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.joinButton.leadingAnchor constant:-8.0],

        [self.dotsContainer.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.dotsContainer.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:14.0],
        [self.dotsContainer.heightAnchor constraintEqualToConstant:20.0],
    ]];
    self.dotsContainerWidthConstraint = [self.dotsContainer.widthAnchor constraintEqualToConstant:20.0];
    self.dotsContainerWidthConstraint.active = YES;

    [NSLayoutConstraint activateConstraints:@[
        [self.countPill.leadingAnchor constraintEqualToAnchor:self.dotsContainer.trailingAnchor constant:8.0],
        [self.countPill.centerYAnchor constraintEqualToAnchor:self.dotsContainer.centerYAnchor],
        [self.countPill.heightAnchor constraintEqualToConstant:20.0],

        [self.listenerIconView.leadingAnchor constraintEqualToAnchor:self.countPill.leadingAnchor constant:10.0],
        [self.listenerIconView.centerYAnchor constraintEqualToAnchor:self.countPill.centerYAnchor],
        [self.listenerIconView.widthAnchor constraintEqualToConstant:9.0],
        [self.listenerIconView.heightAnchor constraintEqualToConstant:9.0],

        [self.countLabel.leadingAnchor constraintEqualToAnchor:self.listenerIconView.trailingAnchor constant:4.0],
        [self.countLabel.centerYAnchor constraintEqualToAnchor:self.countPill.centerYAnchor],
        [self.countLabel.trailingAnchor constraintEqualToAnchor:self.countPill.trailingAnchor constant:-10.0],

        [self.joinButton.trailingAnchor constraintEqualToAnchor:self.cardBackgroundView.trailingAnchor constant:-14.0],
        [self.joinButton.centerYAnchor constraintEqualToAnchor:self.cardBackgroundView.centerYAnchor],
        [self.joinButton.widthAnchor constraintEqualToConstant:48.0],
        [self.joinButton.heightAnchor constraintEqualToConstant:28.0],
    ]];

}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.cardLeadingConstraint.constant = [AcapeChamberRoomCell cardLeadingInset];
    [self.cardBackgroundView layoutIfNeeded];
    [self.joinButton refreshFillGradient];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.roomFocused = NO;
    [self applyFocusedScaleAnimated:NO];
}

- (void)setFocused:(BOOL)focused animated:(BOOL)animated {
    if (self.roomFocused == focused) {
        return;
    }
    self.roomFocused = focused;
    [self applyFocusedScaleAnimated:animated];
}

- (void)applyFocusedScaleAnimated:(BOOL)animated {
    CGFloat scale = self.roomFocused ? kFocusedScale : kIdleScale;
    CGFloat alpha = self.roomFocused ? 1.0 : 0.88;
    void (^changes)(void) = ^{
        self.cardBackgroundView.transform = CGAffineTransformMakeScale(scale, scale);
        self.cardBackgroundView.alpha = alpha;
    };
    if (animated) {
        [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:changes completion:nil];
    } else {
        changes();
    }
}

- (void)configureWithRoom:(AcapeChamberRoom *)room {
    AcapeVaultStore *store = [AcapeVaultStore shared];
    self.coverView.image = [store chamberCoverImageForRoom:room];
    self.nameLabel.text = room.name;
    self.countLabel.text = [NSString stringWithFormat:@"%ld", (long)room.listenerCount];
    NSInteger dotCount = MIN(room.memberDotAssets.count, 3);
    if (dotCount > 0) {
        self.dotsContainer.hidden = NO;
        self.dotsContainerWidthConstraint.constant = 20.0 + MAX(0, dotCount - 1) * 16.0;
    } else {
        self.dotsContainer.hidden = YES;
        self.dotsContainerWidthConstraint.constant = 0.0;
    }
    for (NSInteger i = 0; i < self.dotViews.count; i++) {
        UIImageView *dot = self.dotViews[i];
        if (i < dotCount) {
            dot.hidden = NO;
            if (i == 0 && [room.memberDotAssets.firstObject isEqualToString:room.coverAssetName ?: @""]) {
                dot.image = [store chamberCoverImageForRoom:room];
            } else {
                dot.image = [UIImage imageNamed:room.memberDotAssets[i]];
                if (!dot.image) {
                    dot.image = [store avatarImageForAssetName:room.memberDotAssets[i]];
                }
            }
        } else {
            dot.hidden = YES;
            dot.image = nil;
        }
    }
    [self setNeedsLayout];
}

- (void)handleJoin {
    if (self.joinHandler) {
        self.joinHandler();
    }
}

@end

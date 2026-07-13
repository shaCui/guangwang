#import "AcapeSignalThreadCell.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeVaultStore.h"

static CGFloat const kCardHeight = 72.0;
static CGFloat const kCardGap = 13.0;
static CGFloat const kSideInset = 25.0;

@interface AcapeSignalThreadCell ()
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *previewLabel;
@property (nonatomic, strong) UIView *badgeView;
@property (nonatomic, strong) CAGradientLayer *badgeGradient;
@property (nonatomic, strong) UILabel *badgeLabel;
@end

@implementation AcapeSignalThreadCell

+ (CGFloat)rowHeight {
    return kCardHeight + kCardGap;
}

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
    self.cardView = [[UIView alloc] init];
    self.cardView.backgroundColor = [AcapeAuroraBackdrop cardColor];
    self.cardView.layer.cornerRadius = 20.0;
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
    self.nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cardView addSubview:self.nameLabel];

    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    self.timeLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
    self.timeLabel.textAlignment = NSTextAlignmentRight;
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cardView addSubview:self.timeLabel];

    self.previewLabel = [[UILabel alloc] init];
    self.previewLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    self.previewLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.previewLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.previewLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cardView addSubview:self.previewLabel];

    self.badgeView = [[UIView alloc] init];
    self.badgeView.translatesAutoresizingMaskIntoConstraints = NO;
    self.badgeGradient = [CAGradientLayer layer];
    self.badgeGradient.colors = @[
        (id)[UIColor colorWithRed:0.804 green:1.0 blue:0.780 alpha:1.0].CGColor,
        (id)[AcapeAuroraBackdrop accentColor].CGColor,
    ];
    self.badgeGradient.startPoint = CGPointMake(0.5, 0.0);
    self.badgeGradient.endPoint = CGPointMake(0.5, 1.0);
    self.badgeGradient.cornerRadius = 8.0;
    [self.badgeView.layer addSublayer:self.badgeGradient];
    [self.cardView addSubview:self.badgeView];

    self.badgeLabel = [[UILabel alloc] init];
    self.badgeLabel.textColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0];
    self.badgeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    self.badgeLabel.textAlignment = NSTextAlignmentCenter;
    self.badgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.badgeView addSubview:self.badgeLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kSideInset],
        [self.cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kSideInset],
        [self.cardView.heightAnchor constraintEqualToConstant:kCardHeight],

        [self.avatarView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:12.0],
        [self.avatarView.centerYAnchor constraintEqualToAnchor:self.cardView.centerYAnchor],
        [self.avatarView.widthAnchor constraintEqualToConstant:48.0],
        [self.avatarView.heightAnchor constraintEqualToConstant:48.0],

        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.avatarView.trailingAnchor constant:8.0],
        [self.nameLabel.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:14.0],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.timeLabel.leadingAnchor constant:-6.0],

        [self.timeLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-12.0],
        [self.timeLabel.centerYAnchor constraintEqualToAnchor:self.nameLabel.centerYAnchor],

        [self.previewLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.previewLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:8.0],
        [self.previewLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.badgeView.leadingAnchor constant:-8.0],

        [self.badgeView.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-12.0],
        [self.badgeView.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor constant:-14.0],
        [self.badgeView.widthAnchor constraintEqualToConstant:16.0],
        [self.badgeView.heightAnchor constraintEqualToConstant:16.0],

        [self.badgeLabel.centerXAnchor constraintEqualToAnchor:self.badgeView.centerXAnchor],
        [self.badgeLabel.centerYAnchor constraintEqualToAnchor:self.badgeView.centerYAnchor],
    ]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.badgeGradient.frame = self.badgeView.bounds;
}

- (void)configureWithThread:(AcapeSignalThread *)thread {
    self.avatarView.image = [[AcapeVaultStore shared] avatarImageForAssetName:thread.avatarAssetName];
    self.nameLabel.text = thread.memberName;
    self.timeLabel.text = thread.timeText;
    self.previewLabel.text = thread.previewText;
    if (thread.unreadCount > 0) {
        self.badgeView.hidden = NO;
        self.badgeLabel.text = [NSString stringWithFormat:@"%ld", (long)thread.unreadCount];
    } else {
        self.badgeView.hidden = YES;
    }
}

@end

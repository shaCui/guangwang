#import "AcapeHarborScreen.h"
#import "AcapeRevealText.h"
#import "AcapeVaultStore.h"
#import "AcapeMemberProfile.h"
#import "AcapeCuratedFeedCell.h"
#import "AcapeSeekScreen.h"
#import "AcapeMemberHubScreen.h"
#import "AcapeSignalListScreen.h"
#import "AcapeChamberListScreen.h"
#import "AcapeReelPlayerScreen.h"
#import "AcapeReelUploadScreen.h"
#import "AcapeMuseScreen.h"
#import "AcapeAppNavigator.h"
#import "AcapePayConfirmDialog.h"
#import "AcapeShortCreditDialog.h"
#import "AcapeCofferScreen.h"
#import "AcapeFlagChoiceSheet.h"
#import "AcapeFlagScreen.h"
#import "AcapeCurbConfirmDialog.h"

static NSString * const kAcapeFeedCellReuseId = @"AcapeCuratedFeedCell";
static CGFloat const kAcapeHarborSideInset = 25.0;
static CGFloat const kAcapeFeatureCardSpacing = 15.0;
static CGFloat const kAcapeFeatureCardAspectRatio = 182.0 / 156.0;
static CGFloat const kAcapeHarborHeaderHeight = 64.0;
static NSInteger const kAcapeMuseUnlockCost = 300;

@interface AcapeHarborScreen () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIImageView *headerGlowView;
@property (nonatomic, strong) UIView *headerBarView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *memberAvatarView;
@property (nonatomic, strong) UILabel *harborTitleLabel;
@property (nonatomic, strong) UIButton *noteBellControl;
@property (nonatomic, strong) UILabel *hiLineLabel;
@property (nonatomic, strong) UILabel *welcomeLineLabel;
@property (nonatomic, strong) UIButton *searchControl;
@property (nonatomic, strong) UIView *aiFeatureCard;
@property (nonatomic, strong) UIView *entertainmentFeatureCard;
@property (nonatomic, strong) UIImageView *curatedMarkView;
@property (nonatomic, strong) UILabel *curatedTitleLabel;
@property (nonatomic, strong) UIButton *publishControl;
@property (nonatomic, strong) UICollectionView *feedCollectionView;
@property (nonatomic, strong) NSLayoutConstraint *feedHeightConstraint;
@property (nonatomic, strong) UIView *feedActionOverlay;
@property (nonatomic, assign) BOOL isFeedActionPending;

@end

@implementation AcapeHarborScreen

- (UIStackView *)featureTitleStackWithRevealKey:(AcapeRevealTextKey)key {
    NSString *text = AcapeRevealText(key);
    NSArray<NSString *> *lines = [text componentsSeparatedByString:@"\n"];
    NSString *firstLineText = lines.firstObject ?: @"";
    NSString *secondLineText = lines.count > 1 ? lines[1] : @"";

    UILabel *firstLineLabel = [[UILabel alloc] init];
    firstLineLabel.text = firstLineText;
    firstLineLabel.textColor = UIColor.whiteColor;
    firstLineLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    firstLineLabel.numberOfLines = 1;
    firstLineLabel.adjustsFontSizeToFitWidth = YES;
    firstLineLabel.minimumScaleFactor = 0.82;
    firstLineLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    UILabel *secondLineLabel = [[UILabel alloc] init];
    secondLineLabel.text = secondLineText;
    secondLineLabel.textColor = UIColor.whiteColor;
    secondLineLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    secondLineLabel.numberOfLines = 1;
    secondLineLabel.adjustsFontSizeToFitWidth = YES;
    secondLineLabel.minimumScaleFactor = 0.82;
    secondLineLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[firstLineLabel, secondLineLabel]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentLeading;
    stack.spacing = 2.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    return stack;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.067 green:0.075 blue:0.090 alpha:1.0];
    [self buildScrollLayout];
    [self buildHeaderGlow];
    [self buildHeaderRow];
    [self buildGreetingRow];
    [self buildFeatureCards];
    [self buildCuratedSection];
    [self buildFeedCollection];
    [self refreshMemberPresentation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshMemberPresentation];
    [self.feedCollectionView reloadData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.feedHeightConstraint.constant != 300.0) {
        self.feedHeightConstraint.constant = 300.0;
    }
}

#pragma mark - Layout

- (void)buildHeaderGlow {
    self.headerGlowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"harbor_header_glow"]];
    self.headerGlowView.contentMode = UIViewContentModeScaleAspectFill;
    self.headerGlowView.clipsToBounds = YES;
    self.headerGlowView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:self.headerGlowView belowSubview:self.scrollView];

    [NSLayoutConstraint activateConstraints:@[
        [self.headerGlowView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:-145.0],
        [self.headerGlowView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:-41.0],
        [self.headerGlowView.widthAnchor constraintEqualToConstant:379.0],
        [self.headerGlowView.heightAnchor constraintEqualToConstant:379.0],
    ]];
}

- (void)buildScrollLayout {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentView];

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:kAcapeHarborHeaderHeight],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],

        [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor],
    ]];
}

- (void)buildHeaderRow {
    self.headerBarView = [[UIView alloc] init];
    self.headerBarView.backgroundColor = UIColor.clearColor;
    self.headerBarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.headerBarView];

    self.memberAvatarView = [[UIImageView alloc] init];
    self.memberAvatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.memberAvatarView.layer.cornerRadius = 16.0;
    self.memberAvatarView.clipsToBounds = YES;
    self.memberAvatarView.userInteractionEnabled = YES;
    self.memberAvatarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.memberAvatarView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMemberHubTap)]];

    self.harborTitleLabel = [[UILabel alloc] init];
    self.harborTitleLabel.text = AcapeRevealText(AcapeRevealTextKeyHarborTitle);
    self.harborTitleLabel.textColor = UIColor.whiteColor;
    self.harborTitleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.harborTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.harborTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.noteBellControl = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.noteBellControl setImage:[UIImage imageNamed:@"harbor_note_bell"] forState:UIControlStateNormal];
    self.noteBellControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.noteBellControl addTarget:self action:@selector(handleNoteBellTap) forControlEvents:UIControlEventTouchUpInside];

    [self.headerBarView addSubview:self.memberAvatarView];
    [self.headerBarView addSubview:self.harborTitleLabel];
    [self.headerBarView addSubview:self.noteBellControl];

    [NSLayoutConstraint activateConstraints:@[
        [self.headerBarView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.headerBarView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.headerBarView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.headerBarView.heightAnchor constraintEqualToConstant:kAcapeHarborHeaderHeight],

        [self.memberAvatarView.topAnchor constraintEqualToAnchor:self.headerBarView.topAnchor constant:8.0],
        [self.memberAvatarView.leadingAnchor constraintEqualToAnchor:self.headerBarView.leadingAnchor constant:kAcapeHarborSideInset],
        [self.memberAvatarView.widthAnchor constraintEqualToConstant:48.0],
        [self.memberAvatarView.heightAnchor constraintEqualToConstant:48.0],

        [self.harborTitleLabel.centerYAnchor constraintEqualToAnchor:self.memberAvatarView.centerYAnchor],
        [self.harborTitleLabel.centerXAnchor constraintEqualToAnchor:self.headerBarView.centerXAnchor],

        [self.noteBellControl.centerYAnchor constraintEqualToAnchor:self.memberAvatarView.centerYAnchor],
        [self.noteBellControl.trailingAnchor constraintEqualToAnchor:self.headerBarView.trailingAnchor constant:-kAcapeHarborSideInset],
        [self.noteBellControl.widthAnchor constraintEqualToConstant:21.0],
        [self.noteBellControl.heightAnchor constraintEqualToConstant:25.0],
    ]];
}

- (void)buildGreetingRow {
    self.hiLineLabel = [[UILabel alloc] init];
    self.hiLineLabel.textColor = UIColor.whiteColor;
    self.hiLineLabel.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBold];
    self.hiLineLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.welcomeLineLabel = [[UILabel alloc] init];
    self.welcomeLineLabel.text = AcapeRevealText(AcapeRevealTextKeyWelcomeBack);
    self.welcomeLineLabel.textColor = UIColor.whiteColor;
    self.welcomeLineLabel.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBold];
    self.welcomeLineLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.searchControl = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.searchControl setImage:[UIImage imageNamed:@"harbor_search_mark"] forState:UIControlStateNormal];
    self.searchControl.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.searchControl.adjustsImageWhenHighlighted = NO;
    self.searchControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.searchControl addTarget:self action:@selector(handleSeekTap) forControlEvents:UIControlEventTouchUpInside];

    [self.contentView addSubview:self.hiLineLabel];
    [self.contentView addSubview:self.welcomeLineLabel];
    [self.contentView addSubview:self.searchControl];

    [NSLayoutConstraint activateConstraints:@[
        [self.hiLineLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:26.0],
        [self.hiLineLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kAcapeHarborSideInset],
        [self.hiLineLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.searchControl.leadingAnchor constant:-12.0],

        [self.welcomeLineLabel.topAnchor constraintEqualToAnchor:self.hiLineLabel.bottomAnchor constant:2.0],
        [self.welcomeLineLabel.leadingAnchor constraintEqualToAnchor:self.hiLineLabel.leadingAnchor],
        [self.welcomeLineLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.searchControl.leadingAnchor constant:-12.0],

        [self.searchControl.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kAcapeHarborSideInset],
        [self.searchControl.widthAnchor constraintEqualToConstant:48.0],
        [self.searchControl.heightAnchor constraintEqualToConstant:64.0],
        [self.searchControl.centerYAnchor constraintEqualToAnchor:self.hiLineLabel.centerYAnchor constant:20.0],
    ]];
}

- (void)buildFeatureCards {
    self.aiFeatureCard = [self buildAIAssistantCard];
    self.entertainmentFeatureCard = [self buildEntertainmentCard];
    self.aiFeatureCard.translatesAutoresizingMaskIntoConstraints = NO;
    self.entertainmentFeatureCard.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:self.aiFeatureCard];
    [self.contentView addSubview:self.entertainmentFeatureCard];

    self.entertainmentFeatureCard.userInteractionEnabled = YES;
    [self.entertainmentFeatureCard addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleEntertainmentTap)]];

    self.aiFeatureCard.userInteractionEnabled = YES;
    [self.aiFeatureCard addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleAIAssistantTap)]];

    [NSLayoutConstraint activateConstraints:@[
        [self.aiFeatureCard.topAnchor constraintEqualToAnchor:self.welcomeLineLabel.bottomAnchor constant:24.0],
        [self.aiFeatureCard.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kAcapeHarborSideInset],
        [self.aiFeatureCard.heightAnchor constraintEqualToAnchor:self.aiFeatureCard.widthAnchor multiplier:kAcapeFeatureCardAspectRatio],

        [self.entertainmentFeatureCard.topAnchor constraintEqualToAnchor:self.aiFeatureCard.topAnchor],
        [self.entertainmentFeatureCard.leadingAnchor constraintEqualToAnchor:self.aiFeatureCard.trailingAnchor constant:kAcapeFeatureCardSpacing],
        [self.entertainmentFeatureCard.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kAcapeHarborSideInset],
        [self.entertainmentFeatureCard.widthAnchor constraintEqualToAnchor:self.aiFeatureCard.widthAnchor],
        [self.entertainmentFeatureCard.heightAnchor constraintEqualToAnchor:self.entertainmentFeatureCard.widthAnchor multiplier:kAcapeFeatureCardAspectRatio],
    ]];
}

- (UIView *)buildAIAssistantCard {
    UIView *card = [[UIView alloc] init];
    card.layer.cornerRadius = 20.0;
    card.clipsToBounds = NO;

    UIView *clipView = [[UIView alloc] init];
    clipView.layer.cornerRadius = 20.0;
    clipView.clipsToBounds = YES;
    clipView.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:clipView];

    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"harbor_ai_card_bg"]];
    backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [clipView addSubview:backgroundView];

    UIImageView *robotView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"harbor_ai_mascot"]];
    robotView.contentMode = UIViewContentModeScaleAspectFit;
    robotView.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:robotView];

    UIImageView *arrowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"harbor_diagonal_arrow"]];
    arrowView.contentMode = UIViewContentModeScaleAspectFit;
    arrowView.translatesAutoresizingMaskIntoConstraints = NO;
    [clipView addSubview:arrowView];

    UIStackView *titleStack = [self featureTitleStackWithRevealKey:AcapeRevealTextKeyAIAssistant];
    [clipView addSubview:titleStack];

    UIView *creditBadge = [[UIView alloc] init];
    creditBadge.backgroundColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0];
    creditBadge.layer.cornerRadius = 10.0;
    creditBadge.translatesAutoresizingMaskIntoConstraints = NO;
    [clipView addSubview:creditBadge];

    UIImageView *creditIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"harbor_credit_badge"]];
    creditIcon.contentMode = UIViewContentModeScaleAspectFit;
    creditIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [creditBadge addSubview:creditIcon];

    UILabel *creditLabel = [[UILabel alloc] init];
    creditLabel.text = @"-300";
    creditLabel.textColor = [UIColor colorWithRed:1.0 green:0.922 blue:0.231 alpha:1.0];
    creditLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
    creditLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [creditBadge addSubview:creditLabel];

    [NSLayoutConstraint activateConstraints:@[
        [clipView.topAnchor constraintEqualToAnchor:card.topAnchor],
        [clipView.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [clipView.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [clipView.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],

        [backgroundView.topAnchor constraintEqualToAnchor:clipView.topAnchor],
        [backgroundView.leadingAnchor constraintEqualToAnchor:clipView.leadingAnchor],
        [backgroundView.trailingAnchor constraintEqualToAnchor:clipView.trailingAnchor],
        [backgroundView.bottomAnchor constraintEqualToAnchor:clipView.bottomAnchor],

        [arrowView.topAnchor constraintEqualToAnchor:clipView.topAnchor constant:12.0],
        [arrowView.leadingAnchor constraintEqualToAnchor:clipView.leadingAnchor constant:12.0],
        [arrowView.widthAnchor constraintEqualToConstant:40.0],
        [arrowView.heightAnchor constraintEqualToConstant:40.0],

        [titleStack.leadingAnchor constraintEqualToAnchor:clipView.leadingAnchor constant:12.0],
        [titleStack.topAnchor constraintEqualToAnchor:clipView.topAnchor constant:87.0],
        [titleStack.trailingAnchor constraintEqualToAnchor:clipView.trailingAnchor constant:-12.0],

        [creditBadge.leadingAnchor constraintEqualToAnchor:clipView.leadingAnchor constant:12.0],
        [creditBadge.bottomAnchor constraintEqualToAnchor:clipView.bottomAnchor constant:-12.0],
        [creditBadge.widthAnchor constraintEqualToConstant:55.0],
        [creditBadge.heightAnchor constraintEqualToConstant:20.0],

        [creditIcon.leadingAnchor constraintEqualToAnchor:creditBadge.leadingAnchor constant:10.0],
        [creditIcon.centerYAnchor constraintEqualToAnchor:creditBadge.centerYAnchor],
        [creditIcon.widthAnchor constraintEqualToConstant:12.0],
        [creditIcon.heightAnchor constraintEqualToConstant:12.0],

        [creditLabel.leadingAnchor constraintEqualToAnchor:creditIcon.trailingAnchor constant:2.0],
        [creditLabel.centerYAnchor constraintEqualToAnchor:creditBadge.centerYAnchor],

        [robotView.widthAnchor constraintEqualToConstant:118.0],
        [robotView.heightAnchor constraintEqualToConstant:118.0],
        [robotView.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:12.0],
        [robotView.topAnchor constraintEqualToAnchor:card.topAnchor constant:-20.0],
    ]];

    return card;
}

- (UIView *)buildEntertainmentCard {
    UIView *card = [[UIView alloc] init];
    card.layer.cornerRadius = 20.0;
    card.clipsToBounds = NO;

    UIView *clipView = [[UIView alloc] init];
    clipView.layer.cornerRadius = 20.0;
    clipView.clipsToBounds = YES;
    clipView.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:clipView];

    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"harbor_play_card_bg"]];
    backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [clipView addSubview:backgroundView];

    UIImageView *mascotView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"harbor_play_mascot"]];
    mascotView.contentMode = UIViewContentModeScaleAspectFit;
    mascotView.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:mascotView];

    UIImageView *arrowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"harbor_diagonal_arrow"]];
    arrowView.contentMode = UIViewContentModeScaleAspectFit;
    arrowView.translatesAutoresizingMaskIntoConstraints = NO;
    [clipView addSubview:arrowView];

    UIStackView *titleStack = [self featureTitleStackWithRevealKey:AcapeRevealTextKeyEntertainmentWorld];
    [clipView addSubview:titleStack];

    UIView *avatarCluster = [self buildEntertainmentAvatarCluster];
    avatarCluster.translatesAutoresizingMaskIntoConstraints = NO;
    [clipView addSubview:avatarCluster];

    [NSLayoutConstraint activateConstraints:@[
        [clipView.topAnchor constraintEqualToAnchor:card.topAnchor],
        [clipView.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [clipView.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [clipView.bottomAnchor constraintEqualToAnchor:card.bottomAnchor],

        [backgroundView.topAnchor constraintEqualToAnchor:clipView.topAnchor],
        [backgroundView.leadingAnchor constraintEqualToAnchor:clipView.leadingAnchor],
        [backgroundView.trailingAnchor constraintEqualToAnchor:clipView.trailingAnchor],
        [backgroundView.bottomAnchor constraintEqualToAnchor:clipView.bottomAnchor],

        [arrowView.topAnchor constraintEqualToAnchor:clipView.topAnchor constant:12.0],
        [arrowView.leadingAnchor constraintEqualToAnchor:clipView.leadingAnchor constant:12.0],
        [arrowView.widthAnchor constraintEqualToConstant:40.0],
        [arrowView.heightAnchor constraintEqualToConstant:40.0],

        [titleStack.leadingAnchor constraintEqualToAnchor:clipView.leadingAnchor constant:12.0],
        [titleStack.topAnchor constraintEqualToAnchor:clipView.topAnchor constant:87.0],
        [titleStack.trailingAnchor constraintEqualToAnchor:clipView.trailingAnchor constant:-12.0],

        [avatarCluster.leadingAnchor constraintEqualToAnchor:clipView.leadingAnchor constant:12.0],
        [avatarCluster.bottomAnchor constraintEqualToAnchor:clipView.bottomAnchor constant:-12.0],
        [avatarCluster.heightAnchor constraintEqualToConstant:20.0],

        [mascotView.widthAnchor constraintEqualToConstant:118.0],
        [mascotView.heightAnchor constraintEqualToConstant:118.0],
        [mascotView.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:12.0],
        [mascotView.topAnchor constraintEqualToAnchor:card.topAnchor constant:-16.0],
    ]];

    return card;
}

- (UIView *)buildEntertainmentAvatarCluster {
    UIView *container = [[UIView alloc] init];
    NSArray<NSString *> *assetNames = @[@"harbor_play_member_1", @"harbor_play_member_2", @"harbor_play_member_3"];
    CGFloat diameter = 20.0;
    CGFloat overlap = 8.0;

    for (NSInteger index = 0; index < assetNames.count; index++) {
        UIImageView *avatarView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:assetNames[index]]];
        avatarView.contentMode = UIViewContentModeScaleAspectFill;
        avatarView.layer.cornerRadius = diameter / 2.0;
        avatarView.clipsToBounds = YES;
        avatarView.layer.borderWidth = 1.5;
        avatarView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.35].CGColor;
        avatarView.translatesAutoresizingMaskIntoConstraints = NO;
        [container addSubview:avatarView];

        [NSLayoutConstraint activateConstraints:@[
            [avatarView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:index * (diameter - overlap)],
            [avatarView.centerYAnchor constraintEqualToAnchor:container.centerYAnchor],
            [avatarView.widthAnchor constraintEqualToConstant:diameter],
            [avatarView.heightAnchor constraintEqualToConstant:diameter],
        ]];
    }

    UILabel *overflowLabel = [[UILabel alloc] init];
    overflowLabel.text = [NSString stringWithFormat:@"+%ld", (long)[AcapeVaultStore shared].entertainmentMemberCount];
    overflowLabel.textColor = [UIColor colorWithWhite:1 alpha:0.75];
    overflowLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
    overflowLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:overflowLabel];

    [NSLayoutConstraint activateConstraints:@[
        [overflowLabel.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:assetNames.count * (diameter - overlap) + 8.0],
        [overflowLabel.centerYAnchor constraintEqualToAnchor:container.centerYAnchor],
        [overflowLabel.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
    ]];

    return container;
}

- (void)buildCuratedSection {
    self.curatedMarkView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"蓝色音乐图标"]];
    self.curatedMarkView.contentMode = UIViewContentModeScaleAspectFit;
    self.curatedMarkView.translatesAutoresizingMaskIntoConstraints = NO;
    self.curatedTitleLabel = [[UILabel alloc] init];
    self.curatedTitleLabel.text = AcapeRevealText(AcapeRevealTextKeyCuratedTitle);
    self.curatedTitleLabel.textColor = UIColor.whiteColor;
    self.curatedTitleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    self.curatedTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.publishControl = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.publishControl setBackgroundImage:[UIImage imageNamed:@"harbor_publish_badge"] forState:UIControlStateNormal];
    self.publishControl.adjustsImageWhenHighlighted = NO;
    self.publishControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.publishControl addTarget:self action:@selector(handlePublishTap) forControlEvents:UIControlEventTouchUpInside];

    [self.contentView addSubview:self.curatedMarkView];
    [self.contentView addSubview:self.curatedTitleLabel];
    [self.contentView addSubview:self.publishControl];

    [NSLayoutConstraint activateConstraints:@[
        [self.curatedMarkView.topAnchor constraintEqualToAnchor:self.aiFeatureCard.bottomAnchor constant:22.0],
        [self.curatedMarkView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kAcapeHarborSideInset],
        [self.curatedMarkView.widthAnchor constraintEqualToConstant:26.0],
        [self.curatedMarkView.heightAnchor constraintEqualToConstant:26.0],

        [self.curatedTitleLabel.centerYAnchor constraintEqualToAnchor:self.curatedMarkView.centerYAnchor],
        [self.curatedTitleLabel.leadingAnchor constraintEqualToAnchor:self.curatedMarkView.trailingAnchor constant:4.0],

        [self.publishControl.centerYAnchor constraintEqualToAnchor:self.curatedMarkView.centerYAnchor],
        [self.publishControl.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kAcapeHarborSideInset],
        [self.publishControl.widthAnchor constraintEqualToConstant:80.0],
        [self.publishControl.heightAnchor constraintEqualToConstant:34.0],
    ]];
}

- (void)buildFeedCollection {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 13.0;
    layout.sectionInset = UIEdgeInsetsMake(0, kAcapeHarborSideInset, 0, kAcapeHarborSideInset);

    self.feedCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.feedCollectionView.backgroundColor = UIColor.clearColor;
    self.feedCollectionView.showsHorizontalScrollIndicator = NO;
    self.feedCollectionView.dataSource = self;
    self.feedCollectionView.delegate = self;
    self.feedCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.feedCollectionView registerClass:AcapeCuratedFeedCell.class forCellWithReuseIdentifier:kAcapeFeedCellReuseId];
    [self.contentView addSubview:self.feedCollectionView];

    self.feedHeightConstraint = [self.feedCollectionView.heightAnchor constraintEqualToConstant:300.0];

    [NSLayoutConstraint activateConstraints:@[
        [self.feedCollectionView.topAnchor constraintEqualToAnchor:self.curatedMarkView.bottomAnchor constant:16.0],
        [self.feedCollectionView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.feedCollectionView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        self.feedHeightConstraint,
        [self.feedCollectionView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-24.0],
    ]];
}

#pragma mark - Presentation

- (void)refreshMemberPresentation {
    AcapeMemberProfile *profile = [AcapeVaultStore shared].currentMemberProfile;
    self.memberAvatarView.image = [[AcapeVaultStore shared] avatarImageForAssetName:profile.avatarAssetName];

    NSString *prefix = AcapeRevealText(AcapeRevealTextKeyGreetingPrefix);
    NSString *exclaim = AcapeRevealText(AcapeRevealTextKeyGreetingExclaim);
    self.hiLineLabel.text = [NSString stringWithFormat:@"%@%@%@", prefix, profile.displayName, exclaim];
}

- (void)handleSeekTap {
    if (![self requireSignedInForFeature]) {
        return;
    }
    AcapeSeekScreen *seekScreen = [[AcapeSeekScreen alloc] init];
    [self.navigationController pushViewController:seekScreen animated:YES];
}

- (void)handleMemberHubTap {
    if (![self requireSignedInForFeature]) {
        return;
    }
    AcapeMemberHubScreen *hubScreen = [[AcapeMemberHubScreen alloc] init];
    [self.navigationController pushViewController:hubScreen animated:YES];
}

- (void)handleNoteBellTap {
    if (![self requireSignedInForFeature]) {
        return;
    }
    AcapeSignalListScreen *signalList = [[AcapeSignalListScreen alloc] init];
    [self.navigationController pushViewController:signalList animated:YES];
}

- (void)handleEntertainmentTap {
    if (![self requireSignedInForFeature]) {
        return;
    }
    AcapeChamberListScreen *chamberList = [[AcapeChamberListScreen alloc] init];
    [self.navigationController pushViewController:chamberList animated:YES];
}

- (void)handlePublishTap {
    if (![self requireSignedInForFeature]) {
        return;
    }
    AcapeReelUploadScreen *uploadScreen = [[AcapeReelUploadScreen alloc] init];
    [self.navigationController pushViewController:uploadScreen animated:YES];
}

- (void)handleAIAssistantTap {
    if (![self requireSignedInForFeature]) {
        return;
    }
    [self presentMuseUnlockConfirmDialog];
}

- (void)presentMuseUnlockConfirmDialog {
    AcapePayConfirmDialog *pay = [[AcapePayConfirmDialog alloc] initWithCost:kAcapeMuseUnlockCost];
    __weak typeof(self) weakSelf = self;
    pay.onConfirm = ^{
        AcapeVaultStore *vault = [AcapeVaultStore shared];
        if (![vault canAffordCredits:kAcapeMuseUnlockCost] || ![vault spendCredits:kAcapeMuseUnlockCost]) {
            [weakSelf presentMuseInsufficientDialog];
            return;
        }
        [vault clearMuseConversation];
        [weakSelf openMuseScreen];
    };
    [self presentViewController:pay animated:YES completion:nil];
}

- (void)presentMuseInsufficientDialog {
    AcapeShortCreditDialog *dialog = [[AcapeShortCreditDialog alloc] init];
    __weak typeof(self) weakSelf = self;
    dialog.onRecharge = ^{
        AcapeCofferScreen *coffer = [[AcapeCofferScreen alloc] init];
        [weakSelf.navigationController pushViewController:coffer animated:YES];
    };
    [self presentViewController:dialog animated:YES completion:nil];
}

- (void)openMuseScreen {
    AcapeMuseScreen *museScreen = [[AcapeMuseScreen alloc] init];
    [self.navigationController pushViewController:museScreen animated:YES];
}

- (BOOL)requireSignedInForFeature {
    if ([AcapeVaultStore shared].isMemberSignedIn) {
        return YES;
    }
    [AcapeAppNavigator presentAccessPromptFromPresenter:self];
    return NO;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [AcapeVaultStore shared].curatedFeedEntries.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AcapeCuratedFeedCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kAcapeFeedCellReuseId forIndexPath:indexPath];
    AcapeFeedEntry *entry = [AcapeVaultStore shared].curatedFeedEntries[indexPath.item];
    [cell configureWithEntry:entry];
    __weak typeof(self) weakSelf = self;
    cell.onFavorTap = ^{
        [weakSelf handleFeedFavorTapForEntry:entry];
    };
    cell.onMoreTap = ^{
        [weakSelf handleFeedMoreTapForEntry:entry];
    };
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(240.0, 300.0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    AcapeFeedEntry *entry = [AcapeVaultStore shared].curatedFeedEntries[indexPath.item];
    AcapeReelPlayerScreen *player = [[AcapeReelPlayerScreen alloc] initWithEntry:entry];
    [self.navigationController pushViewController:player animated:YES];
}

- (void)handleFeedFavorTapForEntry:(AcapeFeedEntry *)entry {
    if (![self requireSignedInForFeature] || self.isFeedActionPending) {
        return;
    }
    self.isFeedActionPending = YES;
    [self showFeedActionOverlay];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[AcapeVaultStore shared] toggleFavorForEntry:entry];
        [self hideFeedActionOverlay];
        self.isFeedActionPending = NO;
        [self reloadFeedEntry:entry];
    });
}

- (void)handleFeedMoreTapForEntry:(AcapeFeedEntry *)entry {
    if (![self requireSignedInForFeature]) {
        return;
    }
    AcapeFlagChoiceSheet *sheet = [[AcapeFlagChoiceSheet alloc] init];
    __weak typeof(self) weakSelf = self;
    sheet.onReport = ^{
        AcapeFlagScreen *flagScreen = [[AcapeFlagScreen alloc] init];
        flagScreen.reportedMemberName = entry.memberName;
        [weakSelf.navigationController pushViewController:flagScreen animated:YES];
    };
    sheet.onBlock = ^{
        AcapeCurbConfirmDialog *dialog = [[AcapeCurbConfirmDialog alloc] init];
        dialog.onConfirm = ^{
            [[AcapeVaultStore shared] addCurbedMemberWithName:entry.memberName avatarAssetName:entry.memberAvatarAssetName];
            [weakSelf.feedCollectionView reloadData];
        };
        [weakSelf presentViewController:dialog animated:YES completion:nil];
    };
    [self presentViewController:sheet animated:NO completion:nil];
}

- (void)reloadFeedEntry:(AcapeFeedEntry *)entry {
    NSArray<AcapeFeedEntry *> *entries = [AcapeVaultStore shared].curatedFeedEntries;
    NSUInteger index = [entries indexOfObjectIdenticalTo:entry];
    if (index == NSNotFound) {
        [self.feedCollectionView reloadData];
        return;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(NSInteger)index inSection:0];
    [self.feedCollectionView reloadItemsAtIndexPaths:@[indexPath]];
}

- (void)showFeedActionOverlay {
    if (self.feedActionOverlay.superview) {
        return;
    }
    UIView *overlay = [[UIView alloc] init];
    overlay.backgroundColor = UIColor.clearColor;
    overlay.userInteractionEnabled = YES;
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:overlay];

    UIView *plate = [[UIView alloc] init];
    plate.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.34];
    plate.layer.cornerRadius = 18.0;
    plate.translatesAutoresizingMaskIntoConstraints = NO;
    [overlay addSubview:plate];

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.color = UIColor.whiteColor;
    spinner.transform = CGAffineTransformMakeScale(0.82, 0.82);
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [plate addSubview:spinner];
    [spinner startAnimating];

    [NSLayoutConstraint activateConstraints:@[
        [overlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [overlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [overlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [overlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [plate.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [plate.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
        [plate.widthAnchor constraintEqualToConstant:58.0],
        [plate.heightAnchor constraintEqualToConstant:58.0],

        [spinner.centerXAnchor constraintEqualToAnchor:plate.centerXAnchor],
        [spinner.centerYAnchor constraintEqualToAnchor:plate.centerYAnchor],
    ]];
    self.feedActionOverlay = overlay;
}

- (void)hideFeedActionOverlay {
    [self.feedActionOverlay removeFromSuperview];
    self.feedActionOverlay = nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

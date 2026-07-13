#import "AcapeMemberHubScreen.h"
#import "AcapeRevealText.h"
#import "AcapeVaultStore.h"
#import "AcapeMemberProfile.h"
#import "AcapeNavKit.h"
#import "AcapeLatticeOverlay.h"
#import "AcapeCuratedFeedCell.h"
#import "AcapeMemberEditScreen.h"
#import "AcapeMemberHubKit.h"
#import "AcapePolicyScreen.h"
#import "AcapeAppNavigator.h"
#import "AcapeRosterScreen.h"
#import "AcapeCofferScreen.h"
#import "AcapePrimaryActionButton.h"
#import "AcapeReelPlayerScreen.h"
#import "AcapeSignalChatScreen.h"
#import "AcapeFlagChoiceSheet.h"
#import "AcapeFlagScreen.h"
#import "AcapeCurbConfirmDialog.h"
#import "AcapeMemberRemoveDialog.h"

static NSString * const kAcapeHubWorksCellReuseId = @"AcapeHubWorksCell";
static CGFloat const kAcapeHubSideInset = 25.0;
static CGFloat const kAcapeHubWorkCardWidth = 240.0;
static CGFloat const kAcapeHubWorkCardHeight = 300.0;
static CGFloat const kAcapeHubWorkLineSpacing = 13.0;
static CGFloat const kAcapeHubFixedNavHeight = 52.0;

@interface AcapeMemberHubScreen () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIImageView *headerGlowView;
@property (nonatomic, strong) AcapeLatticeOverlay *latticeOverlay;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIButton *backControl;
@property (nonatomic, strong) UIButton *moreControl;
@property (nonatomic, strong) UIView *profileBandView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *bondingCountLabel;
@property (nonatomic, strong) UILabel *bonderCountLabel;
@property (nonatomic, strong) UILabel *bondingCaptionLabel;
@property (nonatomic, strong) UILabel *bonderCaptionLabel;
@property (nonatomic, strong) UIStackView *nameRowStack;
@property (nonatomic, strong) UILabel *displayNameLabel;
@property (nonatomic, strong) UIButton *editPillButton;
@property (nonatomic, strong) UIStackView *publicActionStack;
@property (nonatomic, strong) AcapePrimaryActionButton *publicBondButton;
@property (nonatomic, strong) UIButton *publicSignalButton;
@property (nonatomic, strong) UIStackView *worksHeaderStack;
@property (nonatomic, strong) UICollectionView *worksCollectionView;
@property (nonatomic, strong) NSLayoutConstraint *worksHeightConstraint;
@property (nonatomic, strong) UIStackView *settingsHeaderStack;
@property (nonatomic, strong) UIView *primarySettingsPanel;
@property (nonatomic, strong) UIView *accountSettingsPanel;
@property (nonatomic, copy) NSArray<AcapeFeedEntry *> *worksEntries;
@property (nonatomic, copy) NSString *publicMemberName;
@property (nonatomic, copy) NSString *publicAvatarAssetName;
@property (nonatomic, strong) UIView *profileActionOverlay;
@property (nonatomic, assign) BOOL isProfileActionPending;

@end

@implementation AcapeMemberHubScreen

- (instancetype)initWithMemberName:(NSString *)memberName avatarAssetName:(NSString *)avatarAssetName {
    self = [super init];
    if (self) {
        _publicMemberName = [memberName copy];
        _publicAvatarAssetName = [avatarAssetName copy];
    }
    return self;
}

- (BOOL)isPublicProfile {
    return self.publicMemberName.length > 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [AcapeMemberHubKit pageBackgroundColor];
    [self buildBackdrop];
    [self buildScrollLayout];
    [self buildHeaderControls];
    [self buildProfileSection];
    [self buildWorksSection];
    if (self.isPublicProfile) {
        [NSLayoutConstraint activateConstraints:@[
            [self.worksCollectionView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-32.0],
        ]];
    } else {
        [self buildSettingsSection];
    }
    [self.view bringSubviewToFront:self.backControl];
    if (!self.moreControl.hidden) {
        [self.view bringSubviewToFront:self.moreControl];
    }
    [self refreshPresentation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshPresentation];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateWorksHeight];
}

#pragma mark - Layout

- (void)buildBackdrop {
    self.headerGlowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"harbor_header_glow"]];
    self.headerGlowView.contentMode = UIViewContentModeScaleAspectFill;
    self.headerGlowView.clipsToBounds = YES;
    self.headerGlowView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.headerGlowView];

    self.latticeOverlay = [[AcapeLatticeOverlay alloc] init];
    self.latticeOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.latticeOverlay];

    [NSLayoutConstraint activateConstraints:@[
        [self.headerGlowView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:-145.0],
        [self.headerGlowView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:-41.0],
        [self.headerGlowView.widthAnchor constraintEqualToConstant:379.0],
        [self.headerGlowView.heightAnchor constraintEqualToConstant:379.0],
        [self.latticeOverlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.latticeOverlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.latticeOverlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.latticeOverlay.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.34],
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
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
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

- (void)buildHeaderControls {
    self.backControl = [AcapeNavKit backControlWithTarget:self action:@selector(handleBackTap)];
    self.moreControl = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *moreImage = [[UIImage imageNamed:@"播放右上角三个点"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] ?: [AcapeMemberHubKit moreControlImage];
    [self.moreControl setImage:moreImage forState:UIControlStateNormal];
    [self.moreControl addTarget:self action:@selector(handlePublicMoreTap) forControlEvents:UIControlEventTouchUpInside];
    self.moreControl.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.moreControl.hidden = !self.isPublicProfile;
    self.backControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.moreControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.backControl];
    [self.view addSubview:self.moreControl];

    [NSLayoutConstraint activateConstraints:@[
        [self.backControl.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:25.0],
        [self.backControl.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:4.0],
        [self.moreControl.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-25.0],
        [self.moreControl.centerYAnchor constraintEqualToAnchor:self.backControl.centerYAnchor],
        [self.moreControl.widthAnchor constraintEqualToConstant:36.0],
        [self.moreControl.heightAnchor constraintEqualToConstant:36.0],
    ]];
}

- (UIStackView *)verticalStatStackWithCountLabel:(UILabel *)countLabel captionLabel:(UILabel *)captionLabel {
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[countLabel, captionLabel]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 2.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    return stack;
}

- (void)buildProfileSection {
    self.profileBandView = [[UIView alloc] init];
    self.profileBandView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.profileBandView];

    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.layer.cornerRadius = 30.0;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.profileBandView addSubview:self.avatarView];

    self.bondingCountLabel = [self statCountLabel];
    self.bonderCountLabel = [self statCountLabel];
    self.bondingCaptionLabel = [self statCaptionLabelWithText:AcapeRevealText(AcapeRevealTextKeyHubBonding)];
    self.bonderCaptionLabel = [self statCaptionLabelWithText:AcapeRevealText(AcapeRevealTextKeyHubBonders)];

    UIStackView *leftStatStack = [self verticalStatStackWithCountLabel:self.bondingCountLabel captionLabel:self.bondingCaptionLabel];
    UIStackView *rightStatStack = [self verticalStatStackWithCountLabel:self.bonderCountLabel captionLabel:self.bonderCaptionLabel];
    leftStatStack.userInteractionEnabled = !self.isPublicProfile;
    rightStatStack.userInteractionEnabled = !self.isPublicProfile;
    [leftStatStack addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBondingTap)]];
    [rightStatStack addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleAdmirersTap)]];
    [self.profileBandView addSubview:leftStatStack];
    [self.profileBandView addSubview:rightStatStack];

    UILayoutGuide *leftStatGutter = [[UILayoutGuide alloc] init];
    UILayoutGuide *rightStatGutter = [[UILayoutGuide alloc] init];
    [self.profileBandView addLayoutGuide:leftStatGutter];
    [self.profileBandView addLayoutGuide:rightStatGutter];

    self.displayNameLabel = [[UILabel alloc] init];
    self.displayNameLabel.textColor = UIColor.whiteColor;
    self.displayNameLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    self.displayNameLabel.translatesAutoresizingMaskIntoConstraints = NO;

    self.editPillButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.editPillButton setImage:[UIImage imageNamed:@"hub_edit_mark"] forState:UIControlStateNormal];
    self.editPillButton.adjustsImageWhenHighlighted = NO;
    self.editPillButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.editPillButton addTarget:self action:@selector(handleEditTap) forControlEvents:UIControlEventTouchUpInside];
    self.editPillButton.hidden = self.isPublicProfile;

    self.nameRowStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.displayNameLabel, self.editPillButton]];
    self.nameRowStack.axis = UILayoutConstraintAxisHorizontal;
    self.nameRowStack.alignment = UIStackViewAlignmentCenter;
    self.nameRowStack.spacing = 8.0;
    self.nameRowStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.nameRowStack];

    self.publicBondButton = [[AcapePrimaryActionButton alloc] initWithFrame:CGRectZero];
    [self.publicBondButton setTitle:AcapeRevealText(AcapeRevealTextKeyBondJoinAction) forState:UIControlStateNormal];
    self.publicBondButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    self.publicBondButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.publicBondButton addTarget:self action:@selector(handlePublicBondTap) forControlEvents:UIControlEventTouchUpInside];

    self.publicSignalButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.publicSignalButton.backgroundColor = UIColor.whiteColor;
    self.publicSignalButton.layer.cornerRadius = 16.0;
    self.publicSignalButton.clipsToBounds = YES;
    UIImage *signalImage = [[UIImage imageNamed:@"他人页面chat"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] ?: [UIImage imageNamed:@"评论图标"] ?: [UIImage systemImageNamed:@"ellipsis.message.fill"];
    [self.publicSignalButton setImage:signalImage forState:UIControlStateNormal];
    self.publicSignalButton.tintColor = [AcapeMemberHubKit panelBackgroundColor];
    self.publicSignalButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.publicSignalButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.publicSignalButton addTarget:self action:@selector(handlePublicSignalTap) forControlEvents:UIControlEventTouchUpInside];

    self.publicActionStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.publicBondButton, self.publicSignalButton]];
    self.publicActionStack.axis = UILayoutConstraintAxisHorizontal;
    self.publicActionStack.alignment = UIStackViewAlignmentFill;
    self.publicActionStack.spacing = 12.0;
    self.publicActionStack.hidden = !self.isPublicProfile;
    self.publicActionStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.publicActionStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.profileBandView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:kAcapeHubFixedNavHeight],
        [self.profileBandView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.profileBandView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.profileBandView.heightAnchor constraintEqualToConstant:120.0],

        [self.avatarView.centerXAnchor constraintEqualToAnchor:self.profileBandView.centerXAnchor],
        [self.avatarView.centerYAnchor constraintEqualToAnchor:self.profileBandView.centerYAnchor],
        [self.avatarView.widthAnchor constraintEqualToConstant:120.0],
        [self.avatarView.heightAnchor constraintEqualToConstant:120.0],

        [leftStatGutter.leadingAnchor constraintEqualToAnchor:self.profileBandView.leadingAnchor],
        [leftStatGutter.trailingAnchor constraintEqualToAnchor:self.avatarView.leadingAnchor],
        [leftStatGutter.topAnchor constraintEqualToAnchor:self.profileBandView.topAnchor],
        [leftStatGutter.bottomAnchor constraintEqualToAnchor:self.profileBandView.bottomAnchor],

        [rightStatGutter.leadingAnchor constraintEqualToAnchor:self.avatarView.trailingAnchor],
        [rightStatGutter.trailingAnchor constraintEqualToAnchor:self.profileBandView.trailingAnchor],
        [rightStatGutter.topAnchor constraintEqualToAnchor:self.profileBandView.topAnchor],
        [rightStatGutter.bottomAnchor constraintEqualToAnchor:self.profileBandView.bottomAnchor],

        [leftStatStack.centerXAnchor constraintEqualToAnchor:leftStatGutter.centerXAnchor],
        [leftStatStack.centerYAnchor constraintEqualToAnchor:self.avatarView.centerYAnchor constant:8.0],

        [rightStatStack.centerXAnchor constraintEqualToAnchor:rightStatGutter.centerXAnchor],
        [rightStatStack.centerYAnchor constraintEqualToAnchor:self.avatarView.centerYAnchor constant:8.0],

        [self.nameRowStack.topAnchor constraintEqualToAnchor:self.profileBandView.bottomAnchor constant:20.0],
        [self.nameRowStack.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [self.editPillButton.widthAnchor constraintEqualToConstant:40.0],
        [self.editPillButton.heightAnchor constraintEqualToConstant:24.0],

        [self.publicActionStack.topAnchor constraintEqualToAnchor:self.nameRowStack.bottomAnchor constant:22.0],
        [self.publicActionStack.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kAcapeHubSideInset],
        [self.publicActionStack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kAcapeHubSideInset],
        [self.publicActionStack.heightAnchor constraintEqualToConstant:46.0],
        [self.publicSignalButton.widthAnchor constraintEqualToConstant:64.0],
    ]];
}

- (void)buildWorksSection {
    UIImageView *worksIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"蓝色音乐图标"]];
    worksIcon.contentMode = UIViewContentModeScaleAspectFit;
    worksIcon.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *worksTitle = [self sectionTitleLabelWithText:AcapeRevealText(AcapeRevealTextKeyHubWorks)];
    self.worksHeaderStack = [[UIStackView alloc] initWithArrangedSubviews:@[worksIcon, worksTitle]];
    self.worksHeaderStack.axis = UILayoutConstraintAxisHorizontal;
    self.worksHeaderStack.alignment = UIStackViewAlignmentCenter;
    self.worksHeaderStack.spacing = 4.0;
    self.worksHeaderStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.worksHeaderStack];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = kAcapeHubWorkLineSpacing;
    layout.sectionInset = UIEdgeInsetsMake(0.0, kAcapeHubSideInset, 0.0, kAcapeHubSideInset);

    self.worksCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.worksCollectionView.backgroundColor = UIColor.clearColor;
    self.worksCollectionView.showsHorizontalScrollIndicator = NO;
    self.worksCollectionView.alwaysBounceHorizontal = YES;
    self.worksCollectionView.dataSource = self;
    self.worksCollectionView.delegate = self;
    self.worksCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.worksCollectionView registerClass:AcapeCuratedFeedCell.class forCellWithReuseIdentifier:kAcapeHubWorksCellReuseId];
    [self.contentView addSubview:self.worksCollectionView];

    self.worksHeightConstraint = [self.worksCollectionView.heightAnchor constraintEqualToConstant:kAcapeHubWorkCardHeight];

    [NSLayoutConstraint activateConstraints:@[
        [worksIcon.widthAnchor constraintEqualToConstant:26.0],
        [worksIcon.heightAnchor constraintEqualToConstant:26.0],
        [self.worksHeaderStack.topAnchor constraintEqualToAnchor:(self.isPublicProfile ? self.publicActionStack.bottomAnchor : self.nameRowStack.bottomAnchor) constant:(self.isPublicProfile ? 24.0 : 30.0)],
        [self.worksHeaderStack.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kAcapeHubSideInset],
        [self.worksCollectionView.topAnchor constraintEqualToAnchor:self.worksHeaderStack.bottomAnchor constant:12.0],
        [self.worksCollectionView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.worksCollectionView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        self.worksHeightConstraint,
    ]];
}

- (void)buildSettingsSection {
    UIImageView *settingsIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hub_settings_mark"]];
    settingsIcon.contentMode = UIViewContentModeScaleAspectFit;
    settingsIcon.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *settingsTitle = [self sectionTitleLabelWithText:AcapeRevealText(AcapeRevealTextKeyHubSettings)];
    self.settingsHeaderStack = [[UIStackView alloc] initWithArrangedSubviews:@[settingsIcon, settingsTitle]];
    self.settingsHeaderStack.axis = UILayoutConstraintAxisHorizontal;
    self.settingsHeaderStack.alignment = UIStackViewAlignmentCenter;
    self.settingsHeaderStack.spacing = 4.0;
    self.settingsHeaderStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.settingsHeaderStack];

    self.primarySettingsPanel = [AcapeMemberHubKit settingsPanelView];
    self.accountSettingsPanel = [AcapeMemberHubKit settingsPanelView];
    [self.contentView addSubview:self.primarySettingsPanel];
    [self.contentView addSubview:self.accountSettingsPanel];

    NSArray<NSDictionary *> *primaryRows = @[
        @{@"title": AcapeRevealText(AcapeRevealTextKeyHubCredit), @"tag": @0, @"destructive": @NO},
        @{@"title": AcapeRevealText(AcapeRevealTextKeyHubCurbed), @"tag": @1, @"destructive": @NO},
        @{@"title": AcapeRevealText(AcapeRevealTextKeyHubPrivacy), @"tag": @2, @"destructive": @NO},
        @{@"title": AcapeRevealText(AcapeRevealTextKeyHubAgreement), @"tag": @3, @"destructive": @NO},
    ];
    NSArray<NSDictionary *> *accountRows = @[
        @{@"title": AcapeRevealText(AcapeRevealTextKeyHubSignOut), @"tag": @4, @"destructive": @NO},
        @{@"title": AcapeRevealText(AcapeRevealTextKeyHubRemoveAccount), @"tag": @5, @"destructive": @YES},
    ];

    [self fillPanel:self.primarySettingsPanel withRows:primaryRows];
    [self fillPanel:self.accountSettingsPanel withRows:accountRows];

    [NSLayoutConstraint activateConstraints:@[
        [settingsIcon.widthAnchor constraintEqualToConstant:26.0],
        [settingsIcon.heightAnchor constraintEqualToConstant:26.0],
        [self.settingsHeaderStack.topAnchor constraintEqualToAnchor:self.worksCollectionView.bottomAnchor constant:26.0],
        [self.settingsHeaderStack.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kAcapeHubSideInset],

        [self.primarySettingsPanel.topAnchor constraintEqualToAnchor:self.settingsHeaderStack.bottomAnchor constant:12.0],
        [self.primarySettingsPanel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kAcapeHubSideInset],
        [self.primarySettingsPanel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kAcapeHubSideInset],

        [self.accountSettingsPanel.topAnchor constraintEqualToAnchor:self.primarySettingsPanel.bottomAnchor constant:13.0],
        [self.accountSettingsPanel.leadingAnchor constraintEqualToAnchor:self.primarySettingsPanel.leadingAnchor],
        [self.accountSettingsPanel.trailingAnchor constraintEqualToAnchor:self.primarySettingsPanel.trailingAnchor],
        [self.accountSettingsPanel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-32.0],
    ]];
}

- (void)fillPanel:(UIView *)panel withRows:(NSArray<NSDictionary *> *)rows {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 0.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [panel addSubview:stack];

    for (NSDictionary *rowInfo in rows) {
        BOOL destructive = [rowInfo[@"destructive"] boolValue];
        UIButton *row = [AcapeMemberHubKit settingsRowButtonWithTitle:rowInfo[@"title"] destructive:destructive];
        row.tag = [rowInfo[@"tag"] integerValue];
        [row addTarget:self action:@selector(handleSettingsRowTap:) forControlEvents:UIControlEventTouchUpInside];
        [stack addArrangedSubview:row];
    }

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:panel.topAnchor constant:8.0],
        [stack.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-8.0],
    ]];
}

- (UILabel *)statCountLabel {
    UILabel *label = [[UILabel alloc] init];
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    return label;
}

- (UILabel *)statCaptionLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.textColor = [UIColor colorWithWhite:1.0 alpha:0.55];
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    return label;
}

- (UILabel *)sectionTitleLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    return label;
}

#pragma mark - Presentation

- (void)refreshPresentation {
    AcapeVaultStore *store = [AcapeVaultStore shared];
    AcapeMemberProfile *profile = store.currentMemberProfile;

    NSString *displayName = self.isPublicProfile ? self.publicMemberName : profile.displayName;
    NSString *avatarAssetName = self.isPublicProfile ? self.publicAvatarAssetName : profile.avatarAssetName;
    self.avatarView.image = [store avatarImageForAssetName:avatarAssetName];
    self.displayNameLabel.text = displayName;
    if (self.isPublicProfile) {
        self.bondingCountLabel.text = [NSString stringWithFormat:@"%ld", (long)[store bondingRosterForMemberName:self.publicMemberName].count];
        NSInteger bonderCount = [store bonderRosterForMemberName:self.publicMemberName].count;
        if ([store hasBondWithMemberName:self.publicMemberName]) {
            bonderCount += 1;
        }
        self.bonderCountLabel.text = [NSString stringWithFormat:@"%ld", (long)bonderCount];
        [self refreshPublicBondButton];
    } else {
        self.bondingCountLabel.text = [NSString stringWithFormat:@"%ld", (long)store.bondingRoster.count];
        self.bonderCountLabel.text = [NSString stringWithFormat:@"%ld", (long)store.admirerRoster.count];
    }

    self.worksEntries = self.isPublicProfile ? [self worksEntriesForPublicMemberName:self.publicMemberName] : store.memberWorksEntries;
    [self.worksCollectionView reloadData];
    [self updateWorksHeight];
}

- (NSArray<AcapeFeedEntry *> *)worksEntriesForPublicMemberName:(NSString *)memberName {
    if (memberName.length == 0) {
        return @[];
    }
    NSMutableArray<AcapeFeedEntry *> *entries = [NSMutableArray array];
    NSString *target = memberName.lowercaseString;
    for (AcapeFeedEntry *entry in [AcapeVaultStore shared].curatedFeedEntries) {
        if ([entry.memberName.lowercaseString isEqualToString:target]) {
            [entries addObject:entry];
        }
    }
    return entries.copy;
}

- (void)updateWorksHeight {
    self.worksHeightConstraint.constant = self.worksEntries.count > 0 ? kAcapeHubWorkCardHeight : 0.0;
}

#pragma mark - Actions

- (void)handleBackTap {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handlePublicMoreTap {
    if (!self.isPublicProfile || ![self requireSignedInForProfileFeature]) {
        return;
    }
    [self presentMemberActionSheetForName:self.publicMemberName avatarAssetName:self.publicAvatarAssetName];
}

- (void)handlePublicBondTap {
    if (!self.isPublicProfile || ![self requireSignedInForProfileFeature]) {
        return;
    }
    [[AcapeVaultStore shared] toggleBondWithMemberName:self.publicMemberName avatarAssetName:self.publicAvatarAssetName];
    [self refreshPresentation];
    [self showBondNotice];
}

- (void)handlePublicSignalTap {
    if (!self.isPublicProfile || ![self requireSignedInForProfileFeature]) {
        return;
    }
    AcapeSignalThread *thread = [[AcapeVaultStore shared] signalThreadForMemberName:self.publicMemberName avatarAssetName:self.publicAvatarAssetName];
    [[AcapeVaultStore shared] markThreadRead:thread];
    AcapeSignalChatScreen *screen = [[AcapeSignalChatScreen alloc] initWithThread:thread];
    [self.navigationController pushViewController:screen animated:YES];
}

- (void)refreshPublicBondButton {
    if (!self.isPublicProfile) {
        return;
    }
    BOOL bonded = [[AcapeVaultStore shared] hasBondWithMemberName:self.publicMemberName];
    [self.publicBondButton setTitle:AcapeRevealText(bonded ? AcapeRevealTextKeyBondJoinedAction : AcapeRevealTextKeyBondJoinAction) forState:UIControlStateNormal];
    [self.publicBondButton setTitleColor:(bonded ? [UIColor colorWithWhite:1.0 alpha:0.52] : UIColor.blackColor) forState:UIControlStateNormal];
    self.publicBondButton.backgroundColor = bonded ? [AcapeMemberHubKit panelBackgroundColor] : UIColor.clearColor;
    for (CALayer *layer in self.publicBondButton.layer.sublayers) {
        if ([layer isKindOfClass:CAGradientLayer.class]) {
            layer.hidden = bonded;
        }
    }
}

- (void)handleEditTap {
    if (self.isPublicProfile) {
        return;
    }
    AcapeMemberEditScreen *editScreen = [[AcapeMemberEditScreen alloc] init];
    [self.navigationController pushViewController:editScreen animated:YES];
}

- (void)handleBondingTap {
    if (self.isPublicProfile) {
        return;
    }
    AcapeRosterScreen *roster = [[AcapeRosterScreen alloc] initWithMode:AcapeRosterModeBonding];
    [self.navigationController pushViewController:roster animated:YES];
}

- (void)handleAdmirersTap {
    if (self.isPublicProfile) {
        return;
    }
    AcapeRosterScreen *roster = [[AcapeRosterScreen alloc] initWithMode:AcapeRosterModeAdmirers];
    [self.navigationController pushViewController:roster animated:YES];
}

- (BOOL)requireSignedInForProfileFeature {
    if ([AcapeVaultStore shared].isMemberSignedIn) {
        return YES;
    }
    [AcapeAppNavigator presentAccessPromptFromPresenter:self];
    return NO;
}

- (void)handleProfileFavorTapForEntry:(AcapeFeedEntry *)entry {
    if (![self requireSignedInForProfileFeature] || self.isProfileActionPending) {
        return;
    }
    self.isProfileActionPending = YES;
    [self showProfileActionOverlay];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[AcapeVaultStore shared] toggleFavorForEntry:entry];
        [self hideProfileActionOverlay];
        self.isProfileActionPending = NO;
        [self reloadWorksEntry:entry];
    });
}

- (void)handleProfileMoreTapForEntry:(AcapeFeedEntry *)entry {
    if (![self requireSignedInForProfileFeature]) {
        return;
    }
    [self presentMemberActionSheetForName:entry.memberName avatarAssetName:entry.memberAvatarAssetName];
}

- (void)presentMemberActionSheetForName:(NSString *)memberName avatarAssetName:(NSString *)avatarAssetName {
    NSString *targetName = [memberName copy];
    NSString *targetAvatar = [avatarAssetName copy];
    if (targetName.length == 0) {
        return;
    }

    AcapeFlagChoiceSheet *sheet = [[AcapeFlagChoiceSheet alloc] init];
    __weak typeof(self) weakSelf = self;
    sheet.onReport = ^{
        AcapeFlagScreen *flagScreen = [[AcapeFlagScreen alloc] init];
        flagScreen.reportedMemberName = targetName;
        [weakSelf.navigationController pushViewController:flagScreen animated:YES];
    };
    sheet.onBlock = ^{
        AcapeCurbConfirmDialog *dialog = [[AcapeCurbConfirmDialog alloc] init];
        dialog.onConfirm = ^{
            [[AcapeVaultStore shared] addCurbedMemberWithName:targetName avatarAssetName:targetAvatar];
            [weakSelf popToHomeAfterCurbingMember];
        };
        [weakSelf presentViewController:dialog animated:YES completion:nil];
    };
    [self presentViewController:sheet animated:NO completion:nil];
}

- (void)popToHomeAfterCurbingMember {
    [self refreshPresentation];
    if (self.navigationController) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)reloadWorksEntry:(AcapeFeedEntry *)entry {
    NSUInteger index = [self.worksEntries indexOfObjectIdenticalTo:entry];
    if (index == NSNotFound) {
        [self.worksCollectionView reloadData];
        return;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(NSInteger)index inSection:0];
    [self.worksCollectionView reloadItemsAtIndexPaths:@[indexPath]];
}

- (void)showProfileActionOverlay {
    if (self.profileActionOverlay.superview) {
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
    self.profileActionOverlay = overlay;
}

- (void)hideProfileActionOverlay {
    [self.profileActionOverlay removeFromSuperview];
    self.profileActionOverlay = nil;
}

- (void)showBondNotice {
    UIView *pill = [[UIView alloc] init];
    pill.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.58];
    pill.layer.cornerRadius = 18.0;
    pill.alpha = 0.0;
    pill.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:pill];

    UILabel *label = [[UILabel alloc] init];
    label.text = AcapeRevealText(AcapeRevealTextKeyBondActionDone);
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [pill addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [pill.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [pill.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [pill.heightAnchor constraintEqualToConstant:36.0],
        [pill.widthAnchor constraintGreaterThanOrEqualToConstant:170.0],

        [label.leadingAnchor constraintEqualToAnchor:pill.leadingAnchor constant:18.0],
        [label.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor constant:-18.0],
        [label.centerYAnchor constraintEqualToAnchor:pill.centerYAnchor],
    ]];

    [UIView animateWithDuration:0.18 animations:^{
        pill.alpha = 1.0;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.18 animations:^{
                pill.alpha = 0.0;
            } completion:^(BOOL done) {
                [pill removeFromSuperview];
            }];
        });
    }];
}

- (void)handleSettingsRowTap:(UIButton *)sender {
    switch (sender.tag) {
        case 0: {
            AcapeCofferScreen *coffer = [[AcapeCofferScreen alloc] init];
            [self.navigationController pushViewController:coffer animated:YES];
            break;
        }
        case 1: {
            AcapeRosterScreen *curbed = [[AcapeRosterScreen alloc] initWithMode:AcapeRosterModeCurbed];
            [self.navigationController pushViewController:curbed animated:YES];
            break;
        }
        case 2: {
            AcapePolicyScreen *policyScreen = [[AcapePolicyScreen alloc] init];
            policyScreen.initialTab = AcapePolicyTabPrivacy;
            [self.navigationController pushViewController:policyScreen animated:YES];
            break;
        }
        case 3: {
            AcapePolicyScreen *policyScreen = [[AcapePolicyScreen alloc] init];
            policyScreen.initialTab = AcapePolicyTabTerms;
            [self.navigationController pushViewController:policyScreen animated:YES];
            break;
        }
        case 4:
            [self presentSignOutConfirmation];
            break;
        case 5:
            [self presentRemoveAccountConfirmation];
            break;
        default:
            break;
    }
}

- (void)presentSignOutConfirmation {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:AcapeRevealText(AcapeRevealTextKeyHubSignOutConfirm)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:AcapeRevealText(AcapeRevealTextKeyHubCancel) style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:AcapeRevealText(AcapeRevealTextKeyHubConfirm) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[AcapeVaultStore shared] clearMemberSession];
        [AcapeAppNavigator presentGateAsRootInWindow:self.view.window animated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentRemoveAccountConfirmation {
    AcapeMemberRemoveDialog *dialog = [[AcapeMemberRemoveDialog alloc] init];
    __weak typeof(self) weakSelf = self;
    dialog.onConfirm = ^{
        [[AcapeVaultStore shared] removeMemberAccount];
        [AcapeAppNavigator presentGateAsRootInWindow:weakSelf.view.window animated:YES];
    };
    [self presentViewController:dialog animated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.worksEntries.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AcapeCuratedFeedCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kAcapeHubWorksCellReuseId forIndexPath:indexPath];
    AcapeFeedEntry *entry = self.worksEntries[indexPath.item];
    BOOL showsMoreControl = self.isPublicProfile;
    [cell configureWithEntry:entry useSeekCover:NO showsMoreControl:showsMoreControl];
    __weak typeof(self) weakSelf = self;
    cell.onFavorTap = ^{
        [weakSelf handleProfileFavorTapForEntry:entry];
    };
    if (showsMoreControl) {
        cell.onMoreTap = ^{
            [weakSelf handleProfileMoreTapForEntry:entry];
        };
    } else {
        cell.onMoreTap = nil;
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(kAcapeHubWorkCardWidth, kAcapeHubWorkCardHeight);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item >= self.worksEntries.count) {
        return;
    }
    AcapeReelPlayerScreen *player = [[AcapeReelPlayerScreen alloc] initWithEntry:self.worksEntries[indexPath.item]];
    [self.navigationController pushViewController:player animated:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

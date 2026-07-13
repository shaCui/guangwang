#import "AcapeRosterScreen.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeNavKit.h"
#import "AcapeRevealText.h"
#import "AcapeVaultStore.h"
#import "AcapeSocialMember.h"
#import "AcapeMemberHubScreen.h"

static NSString * const kRosterCellReuseId = @"AcapeRosterCell";
static CGFloat const kSideInset = 25.0;

@interface AcapeRosterScreen () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, assign) AcapeRosterMode mode;
@property (nonatomic, strong) AcapeAuroraBackdrop *backdrop;
@property (nonatomic, strong) UIButton *backControl;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIView *emptyStateView;
@property (nonatomic, copy) NSArray<AcapeSocialMember *> *members;
@property (nonatomic, copy) NSArray<AcapeSocialMember *> *presentedMembers;
@property (nonatomic, assign) AcapeRevealTextKey presentedTitleKey;
@property (nonatomic, assign) BOOL usesPresentedMembers;
@end

@implementation AcapeRosterScreen

- (instancetype)initWithMode:(AcapeRosterMode)mode {
    self = [super init];
    if (self) {
        _mode = mode;
    }
    return self;
}

- (instancetype)initWithMembers:(NSArray<AcapeSocialMember *> *)members titleKey:(AcapeRevealTextKey)titleKey {
    self = [super init];
    if (self) {
        _presentedMembers = [members copy];
        _presentedTitleKey = titleKey;
        _usesPresentedMembers = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [AcapeAuroraBackdrop baseColor];
    [self buildBackdrop];
    [self buildHeader];
    [self buildGrid];
    [self buildEmptyState];
    [self reloadMembers];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadMembers];
}

- (void)reloadMembers {
    if (self.usesPresentedMembers) {
        self.members = self.presentedMembers ?: @[];
        [self.collectionView reloadData];
        [self updateEmptyState];
        return;
    }
    AcapeVaultStore *store = [AcapeVaultStore shared];
    switch (self.mode) {
        case AcapeRosterModeBonding: self.members = store.bondingRoster; break;
        case AcapeRosterModeAdmirers: self.members = store.admirerRoster; break;
        case AcapeRosterModeCurbed: self.members = store.curbedRoster; break;
    }
    [self.collectionView reloadData];
    [self updateEmptyState];
}

- (NSString *)titleText {
    if (self.usesPresentedMembers) {
        return AcapeRevealText(self.presentedTitleKey);
    }
    switch (self.mode) {
        case AcapeRosterModeBonding: return AcapeRevealText(AcapeRevealTextKeyBondingTitle);
        case AcapeRosterModeAdmirers: return AcapeRevealText(AcapeRevealTextKeyBondersTitle);
        case AcapeRosterModeCurbed: return AcapeRevealText(AcapeRevealTextKeyBondCurbedTitle);
    }
    return @"";
}

- (void)buildBackdrop {
    self.backdrop = [[AcapeAuroraBackdrop alloc] init];
    self.backdrop.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.backdrop];
    [NSLayoutConstraint activateConstraints:@[
        [self.backdrop.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.backdrop.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.backdrop.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.backdrop.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)buildHeader {
    self.backControl = [AcapeNavKit backControlWithTarget:self action:@selector(handleBackTap)];
    self.backControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.backControl];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = [self titleText].uppercaseString;
    self.titleLabel.textColor = UIColor.whiteColor;
    self.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.titleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.backControl.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:kSideInset],
        [self.backControl.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8.0],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.backControl.centerYAnchor],
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    ]];
}

- (void)buildGrid {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumInteritemSpacing = 15.0;
    layout.minimumLineSpacing = 16.0;
    layout.sectionInset = UIEdgeInsetsMake(0.0, kSideInset, 24.0, kSideInset);

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = UIColor.clearColor;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.contentInset = UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0);
    [self.collectionView registerClass:AcapeRosterCell.class forCellWithReuseIdentifier:kRosterCellReuseId];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.collectionView];

    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.topAnchor constraintEqualToAnchor:self.backControl.bottomAnchor constant:22.0],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];
}

- (void)buildEmptyState {
    self.emptyStateView = [[UIView alloc] init];
    self.emptyStateView.hidden = YES;
    self.emptyStateView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.emptyStateView];

    UIImageView *emptyIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shared_void_mascot"]];
    emptyIcon.contentMode = UIViewContentModeScaleAspectFit;
    emptyIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [self.emptyStateView addSubview:emptyIcon];

    UILabel *emptyLabel = [[UILabel alloc] init];
    emptyLabel.text = @"No data";
    emptyLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.42];
    emptyLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.emptyStateView addSubview:emptyLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.emptyStateView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.emptyStateView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.emptyStateView.topAnchor constraintEqualToAnchor:self.backControl.bottomAnchor],
        [self.emptyStateView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],

        [emptyIcon.centerXAnchor constraintEqualToAnchor:self.emptyStateView.centerXAnchor],
        [emptyIcon.centerYAnchor constraintEqualToAnchor:self.emptyStateView.centerYAnchor constant:-36.0],
        [emptyIcon.widthAnchor constraintEqualToConstant:118.0],
        [emptyIcon.heightAnchor constraintEqualToConstant:92.0],

        [emptyLabel.topAnchor constraintEqualToAnchor:emptyIcon.bottomAnchor constant:10.0],
        [emptyLabel.centerXAnchor constraintEqualToAnchor:self.emptyStateView.centerXAnchor],
    ]];
}

- (void)updateEmptyState {
    BOOL empty = self.members.count == 0;
    self.emptyStateView.hidden = !empty;
    self.collectionView.hidden = empty;
}

#pragma mark - Actions

- (void)handleBackTap {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handlePillTapForMember:(AcapeSocialMember *)member atIndexPath:(NSIndexPath *)indexPath {
    if (self.usesPresentedMembers) {
        return;
    }
    AcapeVaultStore *store = [AcapeVaultStore shared];
    if (self.mode == AcapeRosterModeCurbed) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:AcapeRevealText(AcapeRevealTextKeyBondRemoveConfirm)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:AcapeRevealText(AcapeRevealTextKeyHubCancel) style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:AcapeRevealText(AcapeRevealTextKeyHubConfirm) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [store removeCurbedMember:member];
            [self removeMemberAtIndexPath:indexPath];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    } else if (self.mode == AcapeRosterModeBonding) {
        [store toggleBondForMember:member];
        [self removeMemberAtIndexPath:indexPath];
    } else {
        [store toggleBondForMember:member];
        NSMutableArray<AcapeSocialMember *> *updatedMembers = [self.members mutableCopy];
        if (indexPath.item < updatedMembers.count) {
            updatedMembers[indexPath.item] = member;
            self.members = updatedMembers.copy;
            [UIView performWithoutAnimation:^{
                [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
            }];
        }
    }
}

- (void)removeMemberAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item >= self.members.count) {
        [self reloadMembers];
        return;
    }
    NSMutableArray<AcapeSocialMember *> *updatedMembers = [self.members mutableCopy];
    [updatedMembers removeObjectAtIndex:indexPath.item];
    self.members = updatedMembers.copy;
    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    } completion:^(BOOL finished) {
        [self updateEmptyState];
    }];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.members.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AcapeRosterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kRosterCellReuseId forIndexPath:indexPath];
    AcapeSocialMember *member = self.members[indexPath.item];
    [cell configureWithMember:member mode:self.mode];
    __weak typeof(self) weakSelf = self;
    cell.actionHandler = ^{
        [weakSelf handlePillTapForMember:member atIndexPath:indexPath];
    };
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat available = CGRectGetWidth(collectionView.bounds) - kSideInset * 2.0;
    CGFloat itemWidth = floor((available - 30.0) / 3.0);
    return CGSizeMake(itemWidth, 152.0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.mode == AcapeRosterModeCurbed || indexPath.item >= self.members.count) {
        return;
    }
    AcapeSocialMember *member = self.members[indexPath.item];
    AcapeMemberHubScreen *profile = [[AcapeMemberHubScreen alloc] initWithMemberName:member.displayName
                                                                   avatarAssetName:member.avatarAssetName];
    [self.navigationController pushViewController:profile animated:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

#import "AcapeSeekScreen.h"
#import "AcapeRevealText.h"
#import "AcapeLatticeOverlay.h"
#import "AcapeNavKit.h"
#import "AcapeVaultStore.h"
#import "AcapeCuratedFeedCell.h"
#import "AcapeVoidStateView.h"
#import "AcapeReelPlayerScreen.h"
#import "AcapeAppNavigator.h"
#import "AcapeFlagChoiceSheet.h"
#import "AcapeFlagScreen.h"
#import "AcapeCurbConfirmDialog.h"
#import "UIViewController+AcapeDismissKeyboard.h"

static NSString * const kAcapeSeekCellReuseId = @"AcapeSeekResultCell";
static CGFloat const kAcapeSeekSideInset = 25.0;
static CGFloat const kAcapeSeekColumnSpacing = 13.0;
static CGFloat const kAcapeSeekCardAspectRatio = 208.0 / 156.0;

@interface AcapeSeekScreen () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>

@property (nonatomic, strong) CAGradientLayer *headerGradientLayer;
@property (nonatomic, strong) AcapeLatticeOverlay *latticeOverlay;
@property (nonatomic, strong) UIImageView *headerGlowView;
@property (nonatomic, strong) UIButton *backControl;
@property (nonatomic, strong) UIView *queryPanel;
@property (nonatomic, strong) UITextField *queryField;
@property (nonatomic, strong) UIButton *queryClearControl;
@property (nonatomic, strong) NSLayoutConstraint *queryClearWidthConstraint;
@property (nonatomic, strong) UICollectionView *resultCollectionView;
@property (nonatomic, strong) AcapeVoidStateView *voidStateView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, copy) NSArray<AcapeFeedEntry *> *visibleEntries;
@property (nonatomic, assign) BOOL hasSubmittedQuery;
@property (nonatomic, assign) BOOL isSeekActionPending;
@property (nonatomic, strong) UIView *seekActionOverlay;

@end

@implementation AcapeSeekScreen

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.067 green:0.075 blue:0.090 alpha:1.0];
    self.visibleEntries = @[];
    [self acape_enableDismissKeyboardOnBackgroundTap];
    [self buildHeader];
    [self buildQueryBar];
    [self buildResultCollection];
    [self buildVoidState];
    [self buildLoadingIndicator];
    [self refreshPresentation];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.headerGradientLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height * 0.34);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.queryField becomeFirstResponder];
}

#pragma mark - Layout

- (void)buildHeader {
    self.headerGradientLayer = [CAGradientLayer layer];
    self.headerGradientLayer.colors = @[
        (__bridge id)[UIColor colorWithRed:0.08 green:0.28 blue:0.26 alpha:0.95].CGColor,
        (__bridge id)[UIColor colorWithRed:0.05 green:0.12 blue:0.11 alpha:0.55].CGColor,
        (__bridge id)[UIColor colorWithRed:0.04 green:0.06 blue:0.06 alpha:0.0].CGColor,
    ];
    self.headerGradientLayer.locations = @[@0.0, @0.45, @1.0];
    self.headerGradientLayer.startPoint = CGPointMake(0.5, 0.0);
    self.headerGradientLayer.endPoint = CGPointMake(0.5, 1.0);
    [self.view.layer addSublayer:self.headerGradientLayer];

    self.headerGlowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"harbor_header_glow"]];
    self.headerGlowView.contentMode = UIViewContentModeScaleAspectFill;
    self.headerGlowView.clipsToBounds = YES;
    self.headerGlowView.alpha = 0.55;
    self.headerGlowView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.headerGlowView];

    self.latticeOverlay = [[AcapeLatticeOverlay alloc] init];
    self.latticeOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.latticeOverlay];

    self.backControl = [AcapeNavKit backControlWithTarget:self action:@selector(handleBackTap)];
    [self.view addSubview:self.backControl];

    [NSLayoutConstraint activateConstraints:@[
        [self.headerGlowView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:-120.0],
        [self.headerGlowView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:-41.0],
        [self.headerGlowView.widthAnchor constraintEqualToConstant:379.0],
        [self.headerGlowView.heightAnchor constraintEqualToConstant:379.0],

        [self.latticeOverlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.latticeOverlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.latticeOverlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.latticeOverlay.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.28],

        [self.backControl.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:kAcapeSeekSideInset],
        [self.backControl.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20.0],
    ]];
}

- (void)buildQueryBar {
    self.queryPanel = [[UIView alloc] init];
    self.queryPanel.backgroundColor = [UIColor colorWithRed:0.102 green:0.149 blue:0.196 alpha:1.0];
    self.queryPanel.layer.cornerRadius = 24.0;
    self.queryPanel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.queryPanel];

    self.queryField = [[UITextField alloc] init];
    self.queryField.textColor = UIColor.whiteColor;
    self.queryField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.queryField.returnKeyType = UIReturnKeySearch;
    self.queryField.delegate = self;
    self.queryField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.queryField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.queryField.translatesAutoresizingMaskIntoConstraints = NO;
    self.queryField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:AcapeRevealText(AcapeRevealTextKeySeekPlaceholder) attributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.35],
        NSFontAttributeName: [UIFont systemFontOfSize:16 weight:UIFontWeightRegular],
    }];
    [self.queryField addTarget:self action:@selector(handleQueryEditingChanged) forControlEvents:UIControlEventEditingChanged];

    UIImage *clearImage = [UIImage systemImageNamed:@"xmark.circle.fill"];
    self.queryClearControl = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.queryClearControl setImage:clearImage forState:UIControlStateNormal];
    self.queryClearControl.tintColor = [UIColor colorWithWhite:1 alpha:0.45];
    self.queryClearControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.queryClearControl.hidden = YES;
    self.queryClearControl.alpha = 0.0;
    [self.queryClearControl addTarget:self action:@selector(handleQueryClearTap) forControlEvents:UIControlEventTouchUpInside];

    [self.queryPanel addSubview:self.queryField];
    [self.queryPanel addSubview:self.queryClearControl];

    self.queryClearWidthConstraint = [self.queryClearControl.widthAnchor constraintEqualToConstant:0.0];

    [NSLayoutConstraint activateConstraints:@[
        [self.queryPanel.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:80.0],
        [self.queryPanel.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-kAcapeSeekSideInset],
        [self.queryPanel.centerYAnchor constraintEqualToAnchor:self.backControl.centerYAnchor],
        [self.queryPanel.heightAnchor constraintEqualToConstant:48.0],

        [self.queryField.leadingAnchor constraintEqualToAnchor:self.queryPanel.leadingAnchor constant:16.0],
        [self.queryField.trailingAnchor constraintEqualToAnchor:self.queryClearControl.leadingAnchor constant:-8.0],
        [self.queryField.centerYAnchor constraintEqualToAnchor:self.queryPanel.centerYAnchor],

        [self.queryClearControl.trailingAnchor constraintEqualToAnchor:self.queryPanel.trailingAnchor constant:-12.0],
        [self.queryClearControl.centerYAnchor constraintEqualToAnchor:self.queryPanel.centerYAnchor],
        [self.queryClearControl.heightAnchor constraintEqualToConstant:20.0],
        self.queryClearWidthConstraint,
    ]];
    [self updateQueryClearVisibility];
}

- (void)buildResultCollection {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = kAcapeSeekColumnSpacing;
    layout.minimumLineSpacing = kAcapeSeekColumnSpacing;
    layout.sectionInset = UIEdgeInsetsMake(0, kAcapeSeekSideInset, 24.0, kAcapeSeekSideInset);

    self.resultCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.resultCollectionView.backgroundColor = UIColor.clearColor;
    self.resultCollectionView.alwaysBounceVertical = YES;
    self.resultCollectionView.dataSource = self;
    self.resultCollectionView.delegate = self;
    self.resultCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.resultCollectionView.hidden = YES;
    [self.resultCollectionView registerClass:AcapeCuratedFeedCell.class forCellWithReuseIdentifier:kAcapeSeekCellReuseId];
    [self.view addSubview:self.resultCollectionView];

    [NSLayoutConstraint activateConstraints:@[
        [self.resultCollectionView.topAnchor constraintEqualToAnchor:self.queryPanel.bottomAnchor constant:24.0],
        [self.resultCollectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.resultCollectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.resultCollectionView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];
}

- (void)buildVoidState {
    self.voidStateView = [[AcapeVoidStateView alloc] init];
    self.voidStateView.translatesAutoresizingMaskIntoConstraints = NO;
    self.voidStateView.hidden = YES;
    [self.voidStateView configureWithTitle:AcapeRevealText(AcapeRevealTextKeyVoidTitle)
                                  subtitle:AcapeRevealText(AcapeRevealTextKeyVoidSubtitleSeek)
                           mascotAssetName:@"shared_void_mascot"];
    [self.view addSubview:self.voidStateView];

    [NSLayoutConstraint activateConstraints:@[
        [self.voidStateView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.voidStateView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:24.0],
        [self.voidStateView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [self.voidStateView.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24.0],
    ]];
}

- (void)buildLoadingIndicator {
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = UIColor.whiteColor;
    self.loadingIndicator.hidesWhenStopped = YES;
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.loadingIndicator];

    [NSLayoutConstraint activateConstraints:@[
        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];
}

#pragma mark - Presentation

- (void)refreshPresentation {
    BOOL hasResults = self.visibleEntries.count > 0;
    self.resultCollectionView.hidden = !self.hasSubmittedQuery || !hasResults;
    self.voidStateView.hidden = !self.hasSubmittedQuery || hasResults;
    [self.resultCollectionView reloadData];
}

- (void)performQuery {
    NSString *query = [self.queryField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (query.length == 0) {
        [self presentSeekNotice:AcapeRevealText(AcapeRevealTextKeySeekEmptyPrompt)];
        return;
    }

    [self.queryField resignFirstResponder];
    [self.loadingIndicator startAnimating];
    self.resultCollectionView.hidden = YES;
    self.voidStateView.hidden = YES;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.55 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.loadingIndicator stopAnimating];
        self.hasSubmittedQuery = YES;
        self.visibleEntries = [[AcapeVaultStore shared] curatedEntriesMatchingQuery:query];
        [self refreshPresentation];
    });
}

#pragma mark - Actions

- (void)handleBackTap {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleQueryEditingChanged {
    [self updateQueryClearVisibility];
    if (self.queryField.text.length == 0 && self.hasSubmittedQuery) {
        self.hasSubmittedQuery = NO;
        self.visibleEntries = @[];
        [self refreshPresentation];
    }
}

- (void)handleQueryClearTap {
    self.queryField.text = @"";
    [self updateQueryClearVisibility];
    self.hasSubmittedQuery = NO;
    self.visibleEntries = @[];
    [self refreshPresentation];
    [self.queryField becomeFirstResponder];
}

- (void)updateQueryClearVisibility {
    BOOL showsClearControl = self.queryField.text.length > 0;
    self.queryClearControl.hidden = !showsClearControl;
    self.queryClearControl.alpha = showsClearControl ? 1.0 : 0.0;
    self.queryClearWidthConstraint.constant = showsClearControl ? 20.0 : 0.0;
}

- (void)presentSeekNotice:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                 message:message
                                                          preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)requireSignedInForSeekFeature {
    if ([AcapeVaultStore shared].isMemberSignedIn) {
        return YES;
    }
    [AcapeAppNavigator presentAccessPromptFromPresenter:self];
    return NO;
}

- (void)handleSeekFavorTapForEntry:(AcapeFeedEntry *)entry {
    if (![self requireSignedInForSeekFeature] || self.isSeekActionPending) {
        return;
    }
    self.isSeekActionPending = YES;
    [self showSeekActionOverlay];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[AcapeVaultStore shared] toggleFavorForEntry:entry];
        [self hideSeekActionOverlay];
        self.isSeekActionPending = NO;
        [self reloadSeekEntry:entry];
    });
}

- (void)handleSeekMoreTapForEntry:(AcapeFeedEntry *)entry {
    if (![self requireSignedInForSeekFeature]) {
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
            [weakSelf refreshVisibleEntriesForCurrentQuery];
        };
        [weakSelf presentViewController:dialog animated:YES completion:nil];
    };
    [self presentViewController:sheet animated:NO completion:nil];
}

- (void)refreshVisibleEntriesForCurrentQuery {
    NSString *query = [self.queryField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (query.length == 0) {
        self.visibleEntries = @[];
    } else {
        self.visibleEntries = [[AcapeVaultStore shared] curatedEntriesMatchingQuery:query];
    }
    [self refreshPresentation];
}

- (void)reloadSeekEntry:(AcapeFeedEntry *)entry {
    NSUInteger index = [self.visibleEntries indexOfObjectIdenticalTo:entry];
    if (index == NSNotFound) {
        [self.resultCollectionView reloadData];
        return;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(NSInteger)index inSection:0];
    [self.resultCollectionView reloadItemsAtIndexPaths:@[indexPath]];
}

- (void)showSeekActionOverlay {
    if (self.seekActionOverlay.superview) {
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
    self.seekActionOverlay = overlay;
}

- (void)hideSeekActionOverlay {
    [self.seekActionOverlay removeFromSuperview];
    self.seekActionOverlay = nil;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self performQuery];
    return YES;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.visibleEntries.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AcapeCuratedFeedCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kAcapeSeekCellReuseId forIndexPath:indexPath];
    AcapeFeedEntry *entry = self.visibleEntries[indexPath.item];
    [cell configureWithEntry:entry useSeekCover:YES];
    __weak typeof(self) weakSelf = self;
    cell.onFavorTap = ^{
        [weakSelf handleSeekFavorTapForEntry:entry];
    };
    cell.onMoreTap = ^{
        [weakSelf handleSeekMoreTapForEntry:entry];
    };
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat availableWidth = collectionView.bounds.size.width - (kAcapeSeekSideInset * 2.0) - kAcapeSeekColumnSpacing;
    CGFloat itemWidth = floor(availableWidth / 2.0);
    CGFloat itemHeight = floor(itemWidth * kAcapeSeekCardAspectRatio);
    return CGSizeMake(itemWidth, itemHeight);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item >= self.visibleEntries.count) {
        return;
    }
    [self.queryField resignFirstResponder];
    AcapeReelPlayerScreen *player = [[AcapeReelPlayerScreen alloc] initWithEntry:self.visibleEntries[indexPath.item]];
    [self.navigationController pushViewController:player animated:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

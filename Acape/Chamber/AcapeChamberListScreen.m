#import "AcapeChamberListScreen.h"
#import "AcapeChamberRoomCell.h"
#import "AcapeChamberRoomScreen.h"
#import "AcapeChamberCreateScreen.h"
#import "AcapeChamberCreateCapsuleButton.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeNavKit.h"
#import "AcapeRevealText.h"
#import "AcapeVaultStore.h"

static NSString * const kRoomCellReuseId = @"AcapeChamberRoomCell";
static CGFloat const kRoomPointerLeadingInset = 0.0;
static CGFloat const kRoomPointerDesignWidth = 20.0;
static CGFloat const kRoomPointerDesignHeight = 225.0;
static CGFloat const kRoomPointerDesignScreenHeight = 812.0;

@interface AcapeChamberListScreen () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UIView *headerBar;
@property (nonatomic, strong) UIImageView *roomPointerView;
@property (nonatomic, strong) NSLayoutConstraint *roomPointerWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *roomPointerHeightConstraint;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) AcapeChamberCreateCapsuleButton *createControl;
@property (nonatomic, copy) NSArray<AcapeChamberRoom *> *rooms;
@property (nonatomic, assign) NSInteger focusedRow;
@property (nonatomic, strong) UIView *toastView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingSpinner;
@property (nonatomic, assign) BOOL isEnteringRoom;
@end

@implementation AcapeChamberListScreen

- (void)viewDidLoad {
    [super viewDidLoad];
    self.focusedRow = NSNotFound;
    self.view.backgroundColor = [AcapeAuroraBackdrop baseColor];
    [self buildBackdrop];
    [self buildHeader];
    [self buildTable];
    [self buildRoomPointer];
    [self buildLoadingSpinner];
}

- (void)buildLoadingSpinner {
    self.loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingSpinner.color = UIColor.whiteColor;
    self.loadingSpinner.hidesWhenStopped = YES;
    self.loadingSpinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.loadingSpinner];
    [NSLayoutConstraint activateConstraints:@[
        [self.loadingSpinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingSpinner.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.rooms = [AcapeVaultStore shared].chamberRooms;
    [self.tableView reloadData];
    [self updateFocusedRoomPresentationAnimated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView layoutIfNeeded];
    [self updateFocusedRoomPresentationAnimated:NO];
    for (AcapeChamberRoomCell *cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:AcapeChamberRoomCell.class]) {
            [cell setNeedsLayout];
            [cell layoutIfNeeded];
        }
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateRoomPointerLayout];
    [self.view bringSubviewToFront:self.roomPointerView];
    [self updateFocusedRoomPresentationAnimated:NO];
}

- (CGFloat)roomPointerScreenScale {
    CGFloat screenHeight = CGRectGetHeight(self.view.bounds);
    if (screenHeight <= 0.0) {
        screenHeight = CGRectGetHeight(UIScreen.mainScreen.bounds);
    }
    return screenHeight / kRoomPointerDesignScreenHeight;
}

- (void)updateRoomPointerLayout {
    if (!self.roomPointerWidthConstraint || !self.roomPointerHeightConstraint) {
        return;
    }
    CGFloat scale = [self roomPointerScreenScale];
    self.roomPointerWidthConstraint.constant = kRoomPointerDesignWidth * scale;
    self.roomPointerHeightConstraint.constant = kRoomPointerDesignHeight * scale;
}

- (void)buildBackdrop {
    AcapeAuroraBackdrop *backdrop = [[AcapeAuroraBackdrop alloc] init];
    backdrop.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:backdrop];
    [NSLayoutConstraint activateConstraints:@[
        [backdrop.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [backdrop.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [backdrop.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [backdrop.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)buildHeader {
    self.headerBar = [[UIView alloc] init];
    self.headerBar.backgroundColor = UIColor.clearColor;
    self.headerBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.headerBar];

    UIButton *backControl = [AcapeNavKit backControlWithTarget:self action:@selector(handleBackTap)];
    backControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.headerBar addSubview:backControl];

    self.createControl = [[AcapeChamberCreateCapsuleButton alloc] init];
    self.createControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.createControl addTarget:self action:@selector(handleCreateTap) forControlEvents:UIControlEventTouchUpInside];
    [self.headerBar addSubview:self.createControl];

    [NSLayoutConstraint activateConstraints:@[
        [self.headerBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.headerBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.headerBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.headerBar.heightAnchor constraintEqualToConstant:52.0],

        [backControl.leadingAnchor constraintEqualToAnchor:self.headerBar.leadingAnchor constant:25.0],
        [backControl.centerYAnchor constraintEqualToAnchor:self.headerBar.centerYAnchor],

        [self.createControl.trailingAnchor constraintEqualToAnchor:self.headerBar.trailingAnchor constant:-25.0],
        [self.createControl.centerYAnchor constraintEqualToAnchor:self.headerBar.centerYAnchor],
        [self.createControl.heightAnchor constraintEqualToConstant:34.0],
    ]];
}

- (void)buildTable {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = [AcapeChamberRoomCell rowHeight];
    self.tableView.contentInset = UIEdgeInsetsMake(10.0, 0.0, 24.0, 0.0);
    [self.tableView registerClass:AcapeChamberRoomCell.class forCellReuseIdentifier:kRoomCellReuseId];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.headerBar.bottomAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];
}

- (void)buildRoomPointer {
    self.roomPointerView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"k歌房对准的房间"]];
    self.roomPointerView.contentMode = UIViewContentModeScaleAspectFill;
    self.roomPointerView.clipsToBounds = NO;
    self.roomPointerView.userInteractionEnabled = NO;
    self.roomPointerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.roomPointerView];

    CGFloat scale = [self roomPointerScreenScale];
    self.roomPointerWidthConstraint = [self.roomPointerView.widthAnchor constraintEqualToConstant:kRoomPointerDesignWidth * scale];
    self.roomPointerHeightConstraint = [self.roomPointerView.heightAnchor constraintEqualToConstant:kRoomPointerDesignHeight * scale];

    [NSLayoutConstraint activateConstraints:@[
        [self.roomPointerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:kRoomPointerLeadingInset],
        [self.roomPointerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        self.roomPointerWidthConstraint,
        self.roomPointerHeightConstraint,
    ]];
}

- (CGFloat)pointerAnchorYInTableContent {
    CGPoint anchorInTableBounds = [self.view convertPoint:CGPointMake(0.0, CGRectGetMidY(self.view.bounds)) toView:self.tableView];
    return self.tableView.contentOffset.y + anchorInTableBounds.y;
}

- (NSInteger)focusedRowClosestToPointer {
    if (self.rooms.count == 0) {
        return NSNotFound;
    }

    CGFloat anchorY = [self pointerAnchorYInTableContent];
    NSInteger bestRow = 0;
    CGFloat bestDistance = CGFLOAT_MAX;
    for (NSInteger row = 0; row < (NSInteger)self.rooms.count; row++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        CGRect rowRect = [self.tableView rectForRowAtIndexPath:indexPath];
        if (CGRectIsEmpty(rowRect)) {
            continue;
        }
        CGFloat distance = fabs(CGRectGetMidY(rowRect) - anchorY);
        if (distance < bestDistance) {
            bestDistance = distance;
            bestRow = row;
        }
    }
    return bestRow;
}

- (void)updateFocusedRoomPresentationAnimated:(BOOL)animated {
    NSInteger focusedRow = [self focusedRowClosestToPointer];
    if (focusedRow == NSNotFound) {
        return;
    }
    self.focusedRow = focusedRow;

    for (AcapeChamberRoomCell *cell in self.tableView.visibleCells) {
        if (![cell isKindOfClass:AcapeChamberRoomCell.class]) {
            continue;
        }
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        if (!indexPath) {
            continue;
        }
        [cell setFocused:(indexPath.row == focusedRow) animated:animated];
    }
}

#pragma mark - Actions

- (void)handleBackTap {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleCreateTap {
    AcapeChamberCreateScreen *createScreen = [[AcapeChamberCreateScreen alloc] init];
    __weak typeof(self) weakSelf = self;
    createScreen.roomCreatedHandler = ^(__unused AcapeChamberRoom *room) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.rooms = [AcapeVaultStore shared].chamberRooms;
        strongSelf.focusedRow = strongSelf.rooms.count > 0 ? 0 : NSNotFound;
        [strongSelf.tableView reloadData];
        if (strongSelf.rooms.count > 0) {
            [strongSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                        atScrollPosition:UITableViewScrollPositionTop
                                                animated:YES];
        }
        [strongSelf updateFocusedRoomPresentationAnimated:YES];
        [strongSelf showToastWithText:AcapeRevealText(AcapeRevealTextKeyChamberCreateDone) completion:nil];
    };
    [self presentViewController:createScreen animated:NO completion:nil];
}

- (void)showToastWithText:(NSString *)text completion:(void (^ _Nullable)(void))completion {
    [self.toastView removeFromSuperview];
    self.toastView = nil;

    UIView *pill = [[UIView alloc] init];
    pill.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.58];
    pill.layer.cornerRadius = 18.0;
    pill.alpha = 0.0;
    pill.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:pill];

    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [pill addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [pill.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [pill.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [pill.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:44.0],
        [pill.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-44.0],

        [label.topAnchor constraintEqualToAnchor:pill.topAnchor constant:14.0],
        [label.leadingAnchor constraintEqualToAnchor:pill.leadingAnchor constant:18.0],
        [label.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor constant:-18.0],
        [label.bottomAnchor constraintEqualToAnchor:pill.bottomAnchor constant:-14.0],
    ]];
    self.toastView = pill;

    [UIView animateWithDuration:0.18 animations:^{
        pill.alpha = 1.0;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.18 animations:^{
                pill.alpha = 0.0;
            } completion:^(BOOL done) {
                [pill removeFromSuperview];
                if (self.toastView == pill) {
                    self.toastView = nil;
                }
                if (completion) {
                    completion();
                }
            }];
        });
    }];
}

- (void)beginEnterRoomWithLoading:(AcapeChamberRoom *)room {
    if (self.isEnteringRoom) {
        return;
    }
    self.isEnteringRoom = YES;
    self.view.userInteractionEnabled = NO;
    [self.view bringSubviewToFront:self.loadingSpinner];
    [self.loadingSpinner startAnimating];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.loadingSpinner stopAnimating];
        self.view.userInteractionEnabled = YES;
        self.isEnteringRoom = NO;
        [self enterRoom:room];
    });
}

- (void)enterRoom:(AcapeChamberRoom *)room {
    AcapeChamberRoomScreen *roomScreen = [[AcapeChamberRoomScreen alloc] initWithRoom:room];
    [self.navigationController pushViewController:roomScreen animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rooms.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AcapeChamberRoomCell *cell = [tableView dequeueReusableCellWithIdentifier:kRoomCellReuseId forIndexPath:indexPath];
    AcapeChamberRoom *room = self.rooms[indexPath.row];
    [cell configureWithRoom:room];
    [cell setFocused:(indexPath.row == self.focusedRow) animated:NO];
    __weak typeof(self) weakSelf = self;
    cell.joinHandler = ^{ [weakSelf beginEnterRoomWithLoading:room]; };
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self beginEnterRoomWithLoading:self.rooms[indexPath.row]];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateFocusedRoomPresentationAnimated:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

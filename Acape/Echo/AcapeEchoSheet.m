#import "AcapeEchoSheet.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeRevealText.h"
#import "AcapeVaultStore.h"
#import "AcapeFlagChoiceSheet.h"
#import "AcapeFlagScreen.h"
#import "AcapeCurbConfirmDialog.h"
#import "AcapeReelPlayerScreen.h"
#import "AcapeMemberHubScreen.h"

NSNotificationName const AcapeEchoSheetCountDidChangeNotification = @"AcapeEchoSheetCountDidChangeNotification";
NSString * const AcapeEchoSheetEntryIdKey = @"entryId";
NSString * const AcapeEchoSheetCountKey = @"count";

static CGFloat const kSideInset = 25.0;

@interface AcapeEchoSheet () <UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic, copy) NSString *entryId;
@property (nonatomic, strong) UIView *sheetView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *inputBar;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *submitControl;
@property (nonatomic, strong) UIView *loadingOverlay;
@property (nonatomic, strong) NSLayoutConstraint *sheetHeightC;
@property (nonatomic, strong) NSLayoutConstraint *inputBottomC;
@property (nonatomic, copy) NSArray<AcapeEchoComment *> *comments;
@property (nonatomic, assign) BOOL didRevealSheet;
@property (nonatomic, assign) BOOL isSubmittingNote;
@end

@implementation AcapeEchoSheet

- (instancetype)initWithEntryId:(NSString *)entryId {
    self = [super init];
    if (self) {
        _entryId = entryId;
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    [self buildBackdrop];
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDimTap:)]];
    self.comments = [[AcapeVaultStore shared] commentsForEntryId:self.entryId];
    [self buildSheet];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    if (!self.didRevealSheet) {
        [self.view layoutIfNeeded];
        self.sheetView.transform = [self hiddenSheetTransform];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.didRevealSheet) {
        return;
    }
    self.didRevealSheet = YES;
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:0.24
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        self.sheetView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)buildBackdrop {
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
    blurView.userInteractionEnabled = NO;
    blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:blurView];

    UIView *shadeView = [[UIView alloc] init];
    shadeView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    shadeView.userInteractionEnabled = NO;
    shadeView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:shadeView];

    [NSLayoutConstraint activateConstraints:@[
        [blurView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [blurView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [blurView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [blurView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [shadeView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [shadeView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [shadeView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [shadeView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)buildSheet {
    self.sheetView = [[UIView alloc] init];
    self.sheetView.backgroundColor = UIColor.clearColor;
    self.sheetView.clipsToBounds = NO;
    self.sheetView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.sheetView];

    UIImageView *panelBackdrop = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"评论背景"]];
    panelBackdrop.contentMode = UIViewContentModeScaleToFill;
    panelBackdrop.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sheetView addSubview:panelBackdrop];

    UIImageView *cornerMark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"评论右上角"]];
    cornerMark.contentMode = UIViewContentModeScaleAspectFit;
    cornerMark.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sheetView addSubview:cornerMark];

    self.titleLabel = [[UILabel alloc] init];
    [self updateTitle];
    self.titleLabel.textColor = UIColor.blackColor;
    self.titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sheetView addSubview:self.titleLabel];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60.0;
    self.tableView.allowsSelection = NO;
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"comment"];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sheetView addSubview:self.tableView];

    self.inputBar = [[UIView alloc] init];
    self.inputBar.backgroundColor = UIColor.clearColor;
    self.inputBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sheetView addSubview:self.inputBar];

    UIView *field = [[UIView alloc] init];
    field.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    field.layer.cornerRadius = 16.0;
    field.translatesAutoresizingMaskIntoConstraints = NO;
    [self.inputBar addSubview:field];

    self.textField = [[UITextField alloc] init];
    self.textField.textColor = UIColor.blackColor;
    self.textField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.textField.returnKeyType = UIReturnKeySend;
    self.textField.delegate = self;
    self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:AcapeRevealText(AcapeRevealTextKeySignalInputPlaceholder)
                                                                            attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.0 alpha:0.25]}];
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    [field addSubview:self.textField];

    self.submitControl = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.submitControl setBackgroundImage:[UIImage imageNamed:@"发送按钮"] forState:UIControlStateNormal];
    self.submitControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.submitControl addTarget:self action:@selector(handleSubmitTap) forControlEvents:UIControlEventTouchUpInside];
    [field addSubview:self.submitControl];

    self.sheetHeightC = [self.sheetView.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.65];
    self.inputBottomC = [self.inputBar.bottomAnchor constraintEqualToAnchor:self.sheetView.bottomAnchor];

    [NSLayoutConstraint activateConstraints:@[
        [self.sheetView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.sheetView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.sheetView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        self.sheetHeightC,

        [panelBackdrop.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor],
        [panelBackdrop.trailingAnchor constraintEqualToAnchor:self.sheetView.trailingAnchor],
        [panelBackdrop.topAnchor constraintEqualToAnchor:self.sheetView.topAnchor],
        [panelBackdrop.bottomAnchor constraintEqualToAnchor:self.sheetView.bottomAnchor],

        [cornerMark.topAnchor constraintEqualToAnchor:self.sheetView.topAnchor constant:-44.0],
        [cornerMark.trailingAnchor constraintEqualToAnchor:self.sheetView.trailingAnchor constant:-4.0],
        [cornerMark.widthAnchor constraintEqualToConstant:148.0],
        [cornerMark.heightAnchor constraintEqualToConstant:148.0],

        [self.titleLabel.topAnchor constraintEqualToAnchor:self.sheetView.topAnchor constant:28.0],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor constant:kSideInset],

        [self.tableView.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:12.0],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.sheetView.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.inputBar.topAnchor],

        [self.inputBar.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor],
        [self.inputBar.trailingAnchor constraintEqualToAnchor:self.sheetView.trailingAnchor],
        self.inputBottomC,

        [field.topAnchor constraintEqualToAnchor:self.inputBar.topAnchor constant:8.0],
        [field.leadingAnchor constraintEqualToAnchor:self.inputBar.leadingAnchor constant:kSideInset],
        [field.trailingAnchor constraintEqualToAnchor:self.inputBar.trailingAnchor constant:-kSideInset],
        [field.heightAnchor constraintEqualToConstant:52.0],
        [field.bottomAnchor constraintEqualToAnchor:self.inputBar.safeAreaLayoutGuide.bottomAnchor constant:-8.0],

        [self.textField.leadingAnchor constraintEqualToAnchor:field.leadingAnchor constant:16.0],
        [self.textField.trailingAnchor constraintEqualToAnchor:self.submitControl.leadingAnchor constant:-8.0],
        [self.textField.topAnchor constraintEqualToAnchor:field.topAnchor],
        [self.textField.bottomAnchor constraintEqualToAnchor:field.bottomAnchor],

        [self.submitControl.trailingAnchor constraintEqualToAnchor:field.trailingAnchor constant:-8.0],
        [self.submitControl.centerYAnchor constraintEqualToAnchor:field.centerYAnchor],
        [self.submitControl.widthAnchor constraintEqualToConstant:36.0],
        [self.submitControl.heightAnchor constraintEqualToConstant:36.0],
    ]];
    self.sheetView.transform = CGAffineTransformMakeTranslation(0.0, UIScreen.mainScreen.bounds.size.height);
}

- (void)updateTitle {
    self.titleLabel.text = [NSString stringWithFormat:@"%@ (%ld)", AcapeRevealText(AcapeRevealTextKeyEchoCommentsTitle), (long)self.comments.count];
}

#pragma mark - Keyboard

- (void)handleKeyboardChange:(NSNotification *)note {
    CGRect endFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat overlap = CGRectGetMaxY(self.view.bounds) - CGRectGetMinY([self.view convertRect:endFrame fromView:nil]);
    self.inputBottomC.constant = overlap > 0 ? -overlap : 0.0;
    [UIView animateWithDuration:0.25 animations:^{ [self.view layoutIfNeeded]; }];
}

#pragma mark - Actions

- (void)handleDimTap:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self.view];
    if (!CGRectContainsPoint(self.sheetView.frame, point)) {
        [self dismissSheetAnimated];
    }
}

- (void)dismissSheetAnimated {
    [self.textField resignFirstResponder];
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:0.22
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.sheetView.transform = [self hiddenSheetTransform];
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (CGAffineTransform)hiddenSheetTransform {
    CGFloat distance = CGRectGetHeight(self.sheetView.bounds) + self.view.safeAreaInsets.bottom;
    if (distance <= 0.0) {
        distance = UIScreen.mainScreen.bounds.size.height;
    }
    return CGAffineTransformMakeTranslation(0.0, distance);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self submitTextIfNeeded];
    return NO;
}

- (void)handleSubmitTap {
    [self submitTextIfNeeded];
}

- (void)submitTextIfNeeded {
    NSString *text = self.textField.text;
    if (self.isSubmittingNote || [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length == 0) {
        return;
    }
    self.isSubmittingNote = YES;
    self.textField.enabled = NO;
    self.submitControl.enabled = NO;
    [self showLoadingOverlay];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self finishSubmittingText:text];
    });
}

- (void)finishSubmittingText:(NSString *)text {
    [[AcapeVaultStore shared] addComment:text toEntryId:self.entryId];
    self.comments = [[AcapeVaultStore shared] commentsForEntryId:self.entryId];
    self.textField.text = @"";
    self.textField.enabled = YES;
    self.submitControl.enabled = YES;
    [self hideLoadingOverlay];
    self.isSubmittingNote = NO;
    [self updateTitle];
    [self.tableView reloadData];
    [self notifyEchoCountChanged];
    NSInteger count = self.comments.count;
    if (count > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)showLoadingOverlay {
    if (self.loadingOverlay.superview) {
        return;
    }
    UIWindow *window = self.view.window;
    if (!window) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) {
                continue;
            }
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *candidate in windowScene.windows) {
                window = candidate;
                if (candidate.isKeyWindow) {
                    break;
                }
            }
            if (window) {
                break;
            }
        }
    }
    if (!window) {
        return;
    }
    UIView *overlay = [[UIView alloc] initWithFrame:window.bounds];
    overlay.backgroundColor = UIColor.clearColor;
    overlay.userInteractionEnabled = YES;
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.layer.zPosition = CGFLOAT_MAX;

    UIView *spinnerPlate = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 58.0, 58.0)];
    spinnerPlate.center = CGPointMake(CGRectGetMidX(overlay.bounds), CGRectGetMidY(overlay.bounds));
    spinnerPlate.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.34];
    spinnerPlate.layer.cornerRadius = 18.0;
    spinnerPlate.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    spinnerPlate.layer.shadowColor = UIColor.blackColor.CGColor;
    spinnerPlate.layer.shadowOpacity = 0.18;
    spinnerPlate.layer.shadowRadius = 14.0;
    spinnerPlate.layer.shadowOffset = CGSizeMake(0.0, 8.0);
    [overlay addSubview:spinnerPlate];

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.color = UIColor.whiteColor;
    spinner.center = CGPointMake(CGRectGetMidX(spinnerPlate.bounds), CGRectGetMidY(spinnerPlate.bounds));
    spinner.transform = CGAffineTransformMakeScale(0.82, 0.82);
    spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [spinnerPlate addSubview:spinner];
    [spinner startAnimating];

    [window addSubview:overlay];
    [window bringSubviewToFront:overlay];
    self.loadingOverlay = overlay;
}

- (void)hideLoadingOverlay {
    [self.loadingOverlay removeFromSuperview];
    self.loadingOverlay = nil;
}

#pragma mark - Table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"comment" forIndexPath:indexPath];
    cell.backgroundColor = UIColor.clearColor;
    for (UIView *sub in cell.contentView.subviews) { [sub removeFromSuperview]; }
    AcapeEchoComment *comment = self.comments[indexPath.row];

    UIImageView *avatar = [[UIImageView alloc] init];
    avatar.contentMode = UIViewContentModeScaleAspectFill;
    avatar.layer.cornerRadius = 20.0;
    avatar.clipsToBounds = YES;
    avatar.image = [[AcapeVaultStore shared] avatarImageForAssetName:comment.avatarAssetName];
    avatar.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:avatar];

    UIControl *avatarControl = nil;
    if (![self isOwnEchoComment:comment]) {
        avatarControl = [[UIControl alloc] init];
        avatarControl.tag = indexPath.row;
        avatarControl.translatesAutoresizingMaskIntoConstraints = NO;
        [avatarControl addTarget:self action:@selector(handleEchoAvatarTap:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:avatarControl];
    }

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.text = comment.authorName;
    nameLabel.textColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0];
    nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:nameLabel];

    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.text = comment.text;
    textLabel.textColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:0.5];
    textLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    textLabel.numberOfLines = 0;
    textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:textLabel];

    UIButton *moreControl = nil;
    if (![self isOwnEchoComment:comment]) {
        moreControl = [UIButton buttonWithType:UIButtonTypeCustom];
        [moreControl setBackgroundImage:[UIImage imageNamed:@"播放右上角三个点"] forState:UIControlStateNormal];
        moreControl.tag = indexPath.row;
        moreControl.translatesAutoresizingMaskIntoConstraints = NO;
        [moreControl addTarget:self action:@selector(handleEchoMoreTap:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:moreControl];
    }
    NSLayoutAnchor *textTrailingAnchor = moreControl ? moreControl.leadingAnchor : cell.contentView.trailingAnchor;
    CGFloat textTrailingConstant = moreControl ? -12.0 : -kSideInset;

    [NSLayoutConstraint activateConstraints:@[
        [avatar.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:kSideInset],
        [avatar.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:10.0],
        [avatar.widthAnchor constraintEqualToConstant:40.0],
        [avatar.heightAnchor constraintEqualToConstant:40.0],

        [nameLabel.leadingAnchor constraintEqualToAnchor:avatar.trailingAnchor constant:12.0],
        [nameLabel.topAnchor constraintEqualToAnchor:avatar.topAnchor],
        [nameLabel.trailingAnchor constraintEqualToAnchor:textTrailingAnchor constant:textTrailingConstant],

        [textLabel.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],
        [textLabel.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:6.0],
        [textLabel.trailingAnchor constraintEqualToAnchor:textTrailingAnchor constant:textTrailingConstant],
        [textLabel.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-10.0],
    ]];
    if (moreControl) {
        [NSLayoutConstraint activateConstraints:@[
            [moreControl.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-kSideInset],
            [moreControl.centerYAnchor constraintEqualToAnchor:avatar.centerYAnchor],
            [moreControl.widthAnchor constraintEqualToConstant:36.0],
            [moreControl.heightAnchor constraintEqualToConstant:36.0],
        ]];
    }
    if (avatarControl) {
        [NSLayoutConstraint activateConstraints:@[
            [avatarControl.topAnchor constraintEqualToAnchor:avatar.topAnchor],
            [avatarControl.leadingAnchor constraintEqualToAnchor:avatar.leadingAnchor],
            [avatarControl.trailingAnchor constraintEqualToAnchor:avatar.trailingAnchor],
            [avatarControl.bottomAnchor constraintEqualToAnchor:avatar.bottomAnchor],
        ]];
    }
    return cell;
}

- (void)handleEchoAvatarTap:(UIControl *)sender {
    if (sender.tag < 0 || sender.tag >= self.comments.count) {
        return;
    }
    AcapeEchoComment *item = self.comments[sender.tag];
    if ([self isOwnEchoComment:item]) {
        return;
    }
    UIViewController *host = self.presentingViewController;
    AcapeMemberHubScreen *profile = [[AcapeMemberHubScreen alloc] initWithMemberName:item.authorName avatarAssetName:item.avatarAssetName];
    [self dismissViewControllerAnimated:NO completion:^{
        if (host.navigationController) {
            [host.navigationController pushViewController:profile animated:YES];
        } else {
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:profile];
            nav.navigationBarHidden = YES;
            [host presentViewController:nav animated:YES completion:nil];
        }
    }];
}

- (void)handleEchoMoreTap:(UIButton *)sender {
    if (sender.tag < 0 || sender.tag >= self.comments.count) {
        return;
    }
    AcapeEchoComment *item = self.comments[sender.tag];
    [self presentChoiceForEchoName:item.authorName avatar:item.avatarAssetName];
}

- (void)presentChoiceForEchoName:(NSString *)name avatar:(NSString *)avatar {
    if (name.length == 0) {
        return;
    }
    AcapeFlagChoiceSheet *sheet = [[AcapeFlagChoiceSheet alloc] init];
    __weak typeof(self) weakSelf = self;
    sheet.onReport = ^{
        UIViewController *host = weakSelf.presentingViewController;
        if ([host isKindOfClass:AcapeReelPlayerScreen.class]) {
            [(AcapeReelPlayerScreen *)host pausePlaybackForReportFlow];
        }
        [weakSelf dismissViewControllerAnimated:NO completion:^{
            AcapeFlagScreen *flagScreen = [[AcapeFlagScreen alloc] init];
            flagScreen.reportedMemberName = name;
            if (host.navigationController) {
                [host.navigationController pushViewController:flagScreen animated:YES];
            } else {
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:flagScreen];
                nav.navigationBarHidden = YES;
                [host presentViewController:nav animated:YES completion:nil];
            }
        }];
    };
    sheet.onBlock = ^{
        AcapeCurbConfirmDialog *dialog = [[AcapeCurbConfirmDialog alloc] init];
        dialog.onConfirm = ^{
            [[AcapeVaultStore shared] addCurbedMemberWithName:name avatarAssetName:avatar];
            [weakSelf finishCurbingEchoName:name];
        };
        [weakSelf presentViewController:dialog animated:YES completion:nil];
    };
    [self presentViewController:sheet animated:NO completion:nil];
}

- (void)finishCurbingEchoName:(NSString *)name {
    self.comments = [[AcapeVaultStore shared] commentsForEntryId:self.entryId];
    [self updateTitle];
    [self.tableView reloadData];
    [self notifyEchoCountChanged];

    BOOL curbedEntryMember = self.entryMemberName.length > 0 && [self.entryMemberName.lowercaseString isEqualToString:name.lowercaseString];
    if (curbedEntryMember) {
        UIViewController *host = self.presentingViewController;
        [self dismissViewControllerAnimated:NO completion:^{
            if (host.navigationController) {
                [host.navigationController popViewControllerAnimated:YES];
            } else {
                [host dismissViewControllerAnimated:YES completion:nil];
            }
        }];
        return;
    }
}

- (void)notifyEchoCountChanged {
    NSInteger count = self.comments.count;
    if (self.onCountChanged) {
        self.onCountChanged(count);
    }
    NSDictionary *info = @{
        AcapeEchoSheetEntryIdKey: self.entryId ?: @"",
        AcapeEchoSheetCountKey: @(count),
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:AcapeEchoSheetCountDidChangeNotification object:self userInfo:info];
}

- (BOOL)isOwnEchoComment:(AcapeEchoComment *)comment {
    AcapeMemberProfile *profile = AcapeVaultStore.shared.currentMemberProfile;
    if (profile.displayName.length == 0 || comment.authorName.length == 0) {
        return NO;
    }
    if (![comment.authorName isEqualToString:profile.displayName]) {
        return NO;
    }
    NSString *profileAvatar = [[AcapeVaultStore shared] resolvedAvatarAssetName:profile.avatarAssetName];
    NSString *commentAvatar = [[AcapeVaultStore shared] resolvedAvatarAssetName:comment.avatarAssetName];
    return profileAvatar.length == 0 || commentAvatar.length == 0 || [profileAvatar isEqualToString:commentAvatar];
}

@end

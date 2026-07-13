#import "AcapeReelPlayerScreen.h"
#import "AcapeEchoSheet.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeNavKit.h"
#import "AcapeVaultStore.h"
#import "AcapeFlagChoiceSheet.h"
#import "AcapeFlagScreen.h"
#import "AcapeCurbConfirmDialog.h"
#import "AcapeMemberHubScreen.h"
@import AVFoundation;

static CGFloat const kSideInset = 25.0;
static void *kAcapeReelStatusContext = &kAcapeReelStatusContext;

@interface AcapeReelPlayerScreen () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) AcapeFeedEntry *entry;
@property (nonatomic, strong) UIButton *favorButton;
@property (nonatomic, strong) UILabel *favorCountLabel;
@property (nonatomic, strong) UILabel *commentCountLabel;
@property (nonatomic, strong) UIView *clipHostView;
@property (nonatomic, strong) UIImageView *pauseMarkView;
@property (nonatomic, strong) UIButton *moreControl;
@property (nonatomic, strong) AVPlayer *clipPlayer;
@property (nonatomic, strong) AVPlayerLayer *clipLayer;
@property (nonatomic, strong) CAGradientLayer *scrim;
@property (nonatomic, strong) UIView *scrimHost;
@property (nonatomic, assign) BOOL observingClipStatus;
@end

@implementation AcapeReelPlayerScreen

- (instancetype)initWithEntry:(AcapeFeedEntry *)entry {
    self = [super init];
    if (self) {
        _entry = entry;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    [self buildVideoFrame];
    [self buildPlaybackTapGesture];
    [self buildPauseMark];
    [self buildScrim];
    [self buildCaption];
    [self buildActionRail];
    [self buildBack];
    [self buildMoreControl];
    [self refreshFavor];
    [self refreshCommentCount];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleEchoCountDidChange:)
                                                 name:AcapeEchoSheetCountDidChangeNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshFavor];
    [self refreshCommentCount];
    [self syncPauseMarkVisibility];
}

- (void)buildVideoFrame {
    self.clipHostView = [[UIView alloc] init];
    self.clipHostView.clipsToBounds = YES;
    self.clipHostView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.clipHostView];

    UIImageView *frame = [[UIImageView alloc] init];
    frame.contentMode = UIViewContentModeScaleAspectFill;
    frame.clipsToBounds = YES;
    frame.image = [UIImage imageNamed:self.entry.coverImageAssetName ?: @"harbor_entry_cover_1"];
    frame.translatesAutoresizingMaskIntoConstraints = NO;
    [self.clipHostView addSubview:frame];
    [NSLayoutConstraint activateConstraints:@[
        [self.clipHostView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.clipHostView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.clipHostView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.clipHostView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [frame.topAnchor constraintEqualToAnchor:self.clipHostView.topAnchor],
        [frame.leadingAnchor constraintEqualToAnchor:self.clipHostView.leadingAnchor],
        [frame.trailingAnchor constraintEqualToAnchor:self.clipHostView.trailingAnchor],
        [frame.bottomAnchor constraintEqualToAnchor:self.clipHostView.bottomAnchor],
    ]];

    NSURL *clipURL = [self localClipURL];
    if (!clipURL) {
        return;
    }
    self.clipPlayer = [AVPlayer playerWithURL:clipURL];
    [self.clipPlayer addObserver:self
                       forKeyPath:@"timeControlStatus"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:kAcapeReelStatusContext];
    [self.clipPlayer addObserver:self
                       forKeyPath:@"rate"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:kAcapeReelStatusContext];
    self.observingClipStatus = YES;
    self.clipLayer = [AVPlayerLayer playerLayerWithPlayer:self.clipPlayer];
    self.clipLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.clipHostView.layer addSublayer:self.clipLayer];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleClipEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.clipPlayer.currentItem];
    [self.clipPlayer play];
}

- (void)buildPauseMark {
    self.pauseMarkView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"播放暂停按钮"]];
    self.pauseMarkView.contentMode = UIViewContentModeScaleAspectFit;
    self.pauseMarkView.hidden = YES;
    self.pauseMarkView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.pauseMarkView];

    [NSLayoutConstraint activateConstraints:@[
        [self.pauseMarkView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.pauseMarkView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.pauseMarkView.widthAnchor constraintEqualToConstant:78.0],
        [self.pauseMarkView.heightAnchor constraintEqualToConstant:78.0],
    ]];
}

- (void)buildPlaybackTapGesture {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePlaybackTap:)];
    tap.cancelsTouchesInView = NO;
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
}

- (void)buildScrim {
    self.scrimHost = [[UIView alloc] init];
    self.scrimHost.userInteractionEnabled = NO;
    self.scrimHost.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrimHost];
    self.scrim = [CAGradientLayer layer];
    self.scrim.colors = @[
        (id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor,
        (id)[UIColor colorWithWhite:0.0 alpha:0.85].CGColor,
    ];
    self.scrim.startPoint = CGPointMake(0.5, 0.0);
    self.scrim.endPoint = CGPointMake(0.5, 1.0);
    [self.scrimHost.layer addSublayer:self.scrim];
    [NSLayoutConstraint activateConstraints:@[
        [self.scrimHost.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrimHost.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrimHost.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.scrimHost.heightAnchor constraintEqualToConstant:310.0],
    ]];
}

- (void)buildCaption {
    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.text = [NSString stringWithFormat:@"@%@", self.entry.memberName];
    nameLabel.textColor = UIColor.whiteColor;
    nameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:nameLabel];

    UILabel *captionLabel = [[UILabel alloc] init];
    captionLabel.text = self.entry.captionText;
    captionLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    captionLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    captionLabel.numberOfLines = 0;
    captionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:captionLabel];

    [NSLayoutConstraint activateConstraints:@[
        [captionLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:kSideInset],
        [captionLabel.widthAnchor constraintEqualToConstant:280.0],
        [captionLabel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-24.0],

        [nameLabel.leadingAnchor constraintEqualToAnchor:captionLabel.leadingAnchor],
        [nameLabel.bottomAnchor constraintEqualToAnchor:captionLabel.topAnchor constant:-8.0],
    ]];
}

- (void)buildActionRail {
    UIImageView *avatar = [[UIImageView alloc] init];
    avatar.contentMode = UIViewContentModeScaleAspectFill;
    avatar.layer.cornerRadius = 24.0;
    avatar.clipsToBounds = YES;
    avatar.layer.borderWidth = 2.0;
    avatar.layer.borderColor = UIColor.whiteColor.CGColor;
    avatar.image = [[AcapeVaultStore shared] avatarImageForAssetName:self.entry.memberAvatarAssetName];
    avatar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:avatar];

    UIControl *avatarControl = [[UIControl alloc] init];
    avatarControl.translatesAutoresizingMaskIntoConstraints = NO;
    [avatarControl addTarget:self action:@selector(handleMemberAvatarTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:avatarControl];

    self.favorButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.favorButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.favorButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.favorButton addTarget:self action:@selector(handleFavorTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.favorButton];

    self.favorCountLabel = [self railCountLabel];
    [self.view addSubview:self.favorCountLabel];

    UIButton *commentButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [commentButton setBackgroundImage:[UIImage imageNamed:@"评论图标"] forState:UIControlStateNormal];
    commentButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    commentButton.translatesAutoresizingMaskIntoConstraints = NO;
    [commentButton addTarget:self action:@selector(handleCommentTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:commentButton];

    self.commentCountLabel = [self railCountLabel];
    [self.view addSubview:self.commentCountLabel];

    [NSLayoutConstraint activateConstraints:@[
        [avatar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-kSideInset],
        [avatar.widthAnchor constraintEqualToConstant:48.0],
        [avatar.heightAnchor constraintEqualToConstant:48.0],
        [avatar.bottomAnchor constraintEqualToAnchor:self.favorButton.topAnchor constant:-28.0],

        [avatarControl.topAnchor constraintEqualToAnchor:avatar.topAnchor],
        [avatarControl.leadingAnchor constraintEqualToAnchor:avatar.leadingAnchor],
        [avatarControl.trailingAnchor constraintEqualToAnchor:avatar.trailingAnchor],
        [avatarControl.bottomAnchor constraintEqualToAnchor:avatar.bottomAnchor],

        [self.favorButton.centerXAnchor constraintEqualToAnchor:avatar.centerXAnchor],
        [self.favorButton.widthAnchor constraintEqualToConstant:30.0],
        [self.favorButton.heightAnchor constraintEqualToConstant:30.0],
        [self.favorButton.bottomAnchor constraintEqualToAnchor:self.favorCountLabel.topAnchor constant:-4.0],

        [self.favorCountLabel.centerXAnchor constraintEqualToAnchor:avatar.centerXAnchor],
        [self.favorCountLabel.bottomAnchor constraintEqualToAnchor:commentButton.topAnchor constant:-24.0],

        [commentButton.centerXAnchor constraintEqualToAnchor:avatar.centerXAnchor],
        [commentButton.widthAnchor constraintEqualToConstant:30.0],
        [commentButton.heightAnchor constraintEqualToConstant:30.0],
        [commentButton.bottomAnchor constraintEqualToAnchor:self.commentCountLabel.topAnchor constant:-4.0],

        [self.commentCountLabel.centerXAnchor constraintEqualToAnchor:avatar.centerXAnchor],
        [self.commentCountLabel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-44.0],
    ]];
}

- (UILabel *)railCountLabel {
    UILabel *label = [[UILabel alloc] init];
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    return label;
}

- (void)buildBack {
    UIButton *backControl = [AcapeNavKit backControlWithTarget:self action:@selector(handleBackTap)];
    backControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:backControl];
    [NSLayoutConstraint activateConstraints:@[
        [backControl.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:kSideInset],
        [backControl.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8.0],
    ]];
}

- (BOOL)isViewerOwnEntry {
    AcapeVaultStore *store = [AcapeVaultStore shared];
    if (!store.isMemberSignedIn) {
        return NO;
    }
    NSString *viewerName = store.currentMemberProfile.displayName.lowercaseString ?: @"";
    NSString *authorName = self.entry.memberName.lowercaseString ?: @"";
    return viewerName.length > 0 && [viewerName isEqualToString:authorName];
}

- (void)buildMoreControl {
    if ([self isViewerOwnEntry]) {
        return;
    }

    self.moreControl = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.moreControl setBackgroundImage:[UIImage imageNamed:@"播放右上角三个点"] forState:UIControlStateNormal];
    self.moreControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.moreControl addTarget:self action:@selector(handleMoreTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.moreControl];

    [NSLayoutConstraint activateConstraints:@[
        [self.moreControl.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-25.0],
        [self.moreControl.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8.0],
        [self.moreControl.widthAnchor constraintEqualToConstant:36.0],
        [self.moreControl.heightAnchor constraintEqualToConstant:36.0],
    ]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.clipLayer.frame = self.clipHostView.bounds;
    self.scrim.frame = self.scrimHost.bounds;
}

- (NSURL *)localClipURL {
    return [[AcapeVaultStore shared] localClipURLForFileName:self.entry.localClipFileName];
}

- (void)handleClipEnd:(NSNotification *)notification {
    [self.clipPlayer seekToTime:kCMTimeZero];
    [self.clipPlayer play];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.clipPlayer pause];
    [self syncPauseMarkVisibility];
}

- (void)dealloc {
    if (self.observingClipStatus) {
        [self.clipPlayer removeObserver:self forKeyPath:@"timeControlStatus" context:kAcapeReelStatusContext];
        [self.clipPlayer removeObserver:self forKeyPath:@"rate" context:kAcapeReelStatusContext];
        self.observingClipStatus = NO;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refreshFavor {
    NSString *asset = self.entry.isFavoredByViewer ? @"首页已喜欢" : @"首页未喜欢";
    [self.favorButton setBackgroundImage:[UIImage imageNamed:asset] forState:UIControlStateNormal];
    self.favorCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.entry.favorCount];
}

- (void)refreshCommentCount {
    NSInteger count = [[AcapeVaultStore shared] commentsForEntryId:self.entry.entryId].count;
    self.commentCountLabel.text = [NSString stringWithFormat:@"%ld", (long)count];
}

- (void)handleEchoCountDidChange:(NSNotification *)note {
    NSString *entryId = note.userInfo[AcapeEchoSheetEntryIdKey];
    if (entryId.length > 0 && ![entryId isEqualToString:self.entry.entryId]) {
        return;
    }
    [self refreshCommentCount];
}

#pragma mark - Actions

- (void)handleBackTap {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleMemberAvatarTap {
    [self.clipPlayer pause];
    [self syncPauseMarkVisibility];
    AcapeMemberHubScreen *profile = [[AcapeMemberHubScreen alloc] initWithMemberName:self.entry.memberName avatarAssetName:self.entry.memberAvatarAssetName];
    [self.navigationController pushViewController:profile animated:YES];
}

- (void)handleMoreTap {
    AcapeFlagChoiceSheet *sheet = [[AcapeFlagChoiceSheet alloc] init];
    __weak typeof(self) weakSelf = self;
    sheet.onReport = ^{
        [weakSelf pausePlaybackForReportFlow];
        AcapeFlagScreen *flagScreen = [[AcapeFlagScreen alloc] init];
        flagScreen.reportedMemberName = weakSelf.entry.memberName;
        if (weakSelf.navigationController) {
            [weakSelf.navigationController pushViewController:flagScreen animated:YES];
        } else {
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:flagScreen];
            nav.navigationBarHidden = YES;
            [weakSelf presentViewController:nav animated:YES completion:nil];
        }
    };
    sheet.onBlock = ^{
        AcapeCurbConfirmDialog *dialog = [[AcapeCurbConfirmDialog alloc] init];
        dialog.onConfirm = ^{
            [[AcapeVaultStore shared] addCurbedMemberWithName:weakSelf.entry.memberName avatarAssetName:weakSelf.entry.memberAvatarAssetName];
            if (weakSelf.navigationController) {
                [weakSelf.navigationController popToRootViewControllerAnimated:YES];
            } else {
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            }
        };
        [weakSelf presentViewController:dialog animated:YES completion:nil];
    };
    [self presentViewController:sheet animated:NO completion:nil];
}

- (void)pausePlaybackForReportFlow {
    [self.clipPlayer pause];
    [self syncPauseMarkVisibility];
}

- (void)syncPauseMarkVisibility {
    if (!self.clipPlayer || !self.pauseMarkView) {
        self.pauseMarkView.hidden = YES;
        return;
    }
    self.pauseMarkView.hidden = [self clipIsAdvancing];
}

- (BOOL)clipIsAdvancing {
    return self.clipPlayer.rate > 0.01 || self.clipPlayer.timeControlStatus == AVPlayerTimeControlStatusPlaying;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                        context:(void *)context {
    if (context == kAcapeReelStatusContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self syncPauseMarkVisibility];
        });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)handlePlaybackTap:(UITapGestureRecognizer *)tap {
    if (!self.clipPlayer) {
        return;
    }
    if ([self clipIsAdvancing]) {
        [self.clipPlayer pause];
        self.pauseMarkView.hidden = NO;
    } else {
        [self.clipPlayer play];
        self.pauseMarkView.hidden = YES;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *view = touch.view;
    while (view) {
        if ([view isKindOfClass:UIControl.class]) {
            return NO;
        }
        view = view.superview;
    }
    return YES;
}

- (void)handleFavorTap {
    [[AcapeVaultStore shared] toggleFavorForEntry:self.entry];
    [self refreshFavor];
}

- (void)handleCommentTap {
    AcapeEchoSheet *sheet = [[AcapeEchoSheet alloc] initWithEntryId:self.entry.entryId];
    sheet.entryMemberName = self.entry.memberName;
    sheet.entryMemberAvatarAssetName = self.entry.memberAvatarAssetName;
    __weak typeof(self) weakSelf = self;
    sheet.onCountChanged = ^(NSInteger newCount) {
        weakSelf.commentCountLabel.text = [NSString stringWithFormat:@"%ld", (long)newCount];
    };
    [self presentViewController:sheet animated:NO completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

#import "AcapeSignalVoiceScreen.h"
#import "AcapeSignalBubbleCell.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeNavKit.h"
#import "AcapeRevealText.h"
#import "AcapeVaultStore.h"
#import "AcapeMemberProfile.h"
@import AVFoundation;

static NSString * const kBubbleCellReuseId = @"AcapeSignalVoiceBubbleCell";

@interface AcapeSignalVoiceScreen () <UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate>
@property (nonatomic, strong) AcapeSignalThread *thread;
@property (nonatomic, strong) AcapeAuroraBackdrop *backdrop;
@property (nonatomic, strong) UIButton *backControl;
@property (nonatomic, strong) UIImageView *headerAvatarView;
@property (nonatomic, strong) UILabel *headerNameLabel;
@property (nonatomic, strong) UIButton *moreControl;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *glowPanel;
@property (nonatomic, strong) CAGradientLayer *glowGradient;
@property (nonatomic, strong) UIView *micButton;
@property (nonatomic, strong) UIView *micOuterRing;
@property (nonatomic, strong) CAGradientLayer *micInnerGradient;
@property (nonatomic, strong) CAGradientLayer *micOuterGradient;
@property (nonatomic, strong) UIView *micInnerCircle;
@property (nonatomic, strong) UIButton *textEntryControl;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) AVAudioRecorder *voiceRecorder;
@property (nonatomic, strong) AVAudioPlayer *voicePlayer;
@property (nonatomic, copy) NSString *activeVoiceFileName;
@property (nonatomic, strong) NSIndexPath *activeVoiceIndexPath;
@property (nonatomic, assign) NSTimeInterval recordStart;
@property (nonatomic, assign) BOOL recording;
@property (nonatomic, assign) BOOL voicePressActive;
@end

@implementation AcapeSignalVoiceScreen

- (instancetype)initWithThread:(AcapeSignalThread *)thread {
    self = [super init];
    if (self) {
        _thread = thread;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [AcapeAuroraBackdrop baseColor];
    [self buildBackdrop];
    [self buildHeader];
    [self buildVoiceControl];
    [self buildTable];
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

    self.headerAvatarView = [[UIImageView alloc] init];
    self.headerAvatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.headerAvatarView.layer.cornerRadius = 16.0;
    self.headerAvatarView.clipsToBounds = YES;
    self.headerAvatarView.image = [[AcapeVaultStore shared] avatarImageForAssetName:self.thread.avatarAssetName];
    self.headerAvatarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.headerAvatarView];

    self.headerNameLabel = [[UILabel alloc] init];
    self.headerNameLabel.text = self.thread.memberName;
    self.headerNameLabel.textColor = UIColor.whiteColor;
    self.headerNameLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.headerNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.headerNameLabel];

    self.moreControl = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *dots = [[UIImage imageNamed:@"播放右上角三个点"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.moreControl setImage:dots forState:UIControlStateNormal];
    self.moreControl.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.moreControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.moreControl addTarget:self action:@selector(handleBackTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.moreControl];

    [NSLayoutConstraint activateConstraints:@[
        [self.backControl.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:25.0],
        [self.backControl.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8.0],

        [self.headerAvatarView.leadingAnchor constraintEqualToAnchor:self.backControl.trailingAnchor constant:25.0],
        [self.headerAvatarView.centerYAnchor constraintEqualToAnchor:self.backControl.centerYAnchor],
        [self.headerAvatarView.widthAnchor constraintEqualToConstant:32.0],
        [self.headerAvatarView.heightAnchor constraintEqualToConstant:32.0],

        [self.headerNameLabel.leadingAnchor constraintEqualToAnchor:self.headerAvatarView.trailingAnchor constant:10.0],
        [self.headerNameLabel.centerYAnchor constraintEqualToAnchor:self.headerAvatarView.centerYAnchor],

        [self.moreControl.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-25.0],
        [self.moreControl.centerYAnchor constraintEqualToAnchor:self.backControl.centerYAnchor],
        [self.moreControl.widthAnchor constraintEqualToConstant:36.0],
        [self.moreControl.heightAnchor constraintEqualToConstant:36.0],
    ]];
}

- (void)buildVoiceControl {
    self.glowPanel = [[UIView alloc] init];
    self.glowPanel.userInteractionEnabled = NO;
    self.glowPanel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.glowPanel];

    self.glowGradient = [CAGradientLayer layer];
    self.glowGradient.colors = @[
        (id)[[AcapeAuroraBackdrop accentColor] colorWithAlphaComponent:0.0].CGColor,
        (id)[[AcapeAuroraBackdrop accentColor] colorWithAlphaComponent:0.22].CGColor,
    ];
    self.glowGradient.startPoint = CGPointMake(0.5, 0.0);
    self.glowGradient.endPoint = CGPointMake(0.5, 1.0);
    [self.glowPanel.layer addSublayer:self.glowGradient];

    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.text = AcapeRevealText(AcapeRevealTextKeySignalVoiceCallHint);
    self.hintLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    self.hintLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    self.hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.hintLabel];

    self.micButton = [[UIView alloc] init];
    self.micButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.micButton];

    self.micOuterRing = [[UIView alloc] init];
    self.micOuterRing.translatesAutoresizingMaskIntoConstraints = NO;
    [self.micButton addSubview:self.micOuterRing];
    self.micOuterGradient = [CAGradientLayer layer];
    self.micOuterGradient.colors = @[
        (id)[UIColor colorWithRed:0.804 green:1.0 blue:0.780 alpha:1.0].CGColor,
        (id)[AcapeAuroraBackdrop accentColor].CGColor,
    ];
    self.micOuterGradient.startPoint = CGPointMake(0.5, 0.0);
    self.micOuterGradient.endPoint = CGPointMake(0.5, 1.0);
    self.micOuterGradient.opacity = 0.25;
    [self.micOuterRing.layer addSublayer:self.micOuterGradient];

    UIView *innerCircle = [[UIView alloc] init];
    innerCircle.translatesAutoresizingMaskIntoConstraints = NO;
    [self.micButton addSubview:innerCircle];
    self.micInnerCircle = innerCircle;
    self.micInnerGradient = [CAGradientLayer layer];
    self.micInnerGradient.colors = self.micOuterGradient.colors;
    self.micInnerGradient.startPoint = CGPointMake(0.5, 0.0);
    self.micInnerGradient.endPoint = CGPointMake(0.5, 1.0);
    [innerCircle.layer addSublayer:self.micInnerGradient];

    UIImageView *micIcon = [[UIImageView alloc] init];
    UIImageConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:26 weight:UIImageSymbolWeightRegular];
    micIcon.image = [UIImage systemImageNamed:@"mic.fill" withConfiguration:cfg];
    micIcon.tintColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0];
    micIcon.contentMode = UIViewContentModeScaleAspectFit;
    micIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [innerCircle addSubview:micIcon];

    self.textEntryControl = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImageConfiguration *textEntryConfig = [UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightMedium];
    UIImage *textEntryImage = [UIImage systemImageNamed:@"keyboard" withConfiguration:textEntryConfig];
    [self.textEntryControl setImage:textEntryImage forState:UIControlStateNormal];
    self.textEntryControl.tintColor = [AcapeAuroraBackdrop accentColor];
    self.textEntryControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.textEntryControl addTarget:self action:@selector(handleTextEntryTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.textEntryControl];

    UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleMicPress:)];
    press.minimumPressDuration = 0.0;
    [self.micButton addGestureRecognizer:press];

    [NSLayoutConstraint activateConstraints:@[
        [self.glowPanel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.glowPanel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.glowPanel.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.glowPanel.heightAnchor constraintEqualToConstant:176.0],

        [self.micButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.micButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-24.0],
        [self.micButton.widthAnchor constraintEqualToConstant:87.0],
        [self.micButton.heightAnchor constraintEqualToConstant:87.0],

        [self.micOuterRing.topAnchor constraintEqualToAnchor:self.micButton.topAnchor],
        [self.micOuterRing.leadingAnchor constraintEqualToAnchor:self.micButton.leadingAnchor],
        [self.micOuterRing.trailingAnchor constraintEqualToAnchor:self.micButton.trailingAnchor],
        [self.micOuterRing.bottomAnchor constraintEqualToAnchor:self.micButton.bottomAnchor],

        [innerCircle.centerXAnchor constraintEqualToAnchor:self.micButton.centerXAnchor],
        [innerCircle.centerYAnchor constraintEqualToAnchor:self.micButton.centerYAnchor],
        [innerCircle.widthAnchor constraintEqualToConstant:75.0],
        [innerCircle.heightAnchor constraintEqualToConstant:75.0],

        [micIcon.centerXAnchor constraintEqualToAnchor:innerCircle.centerXAnchor],
        [micIcon.centerYAnchor constraintEqualToAnchor:innerCircle.centerYAnchor],
        [micIcon.widthAnchor constraintEqualToConstant:30.0],
        [micIcon.heightAnchor constraintEqualToConstant:30.0],

        [self.hintLabel.bottomAnchor constraintEqualToAnchor:self.micButton.topAnchor constant:-14.0],
        [self.hintLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        [self.textEntryControl.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:25.0],
        [self.textEntryControl.centerYAnchor constraintEqualToAnchor:self.micButton.centerYAnchor],
        [self.textEntryControl.widthAnchor constraintEqualToConstant:44.0],
        [self.textEntryControl.heightAnchor constraintEqualToConstant:44.0],
    ]];
}

- (void)buildTable {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 140.0;
    self.tableView.userInteractionEnabled = YES;
    self.tableView.contentInset = UIEdgeInsetsMake(12.0, 0.0, 12.0, 0.0);
    [self.tableView registerClass:AcapeSignalBubbleCell.class forCellReuseIdentifier:kBubbleCellReuseId];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:self.tableView belowSubview:self.glowPanel];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.backControl.bottomAnchor constant:14.0],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.hintLabel.topAnchor constant:-8.0],
    ]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.glowGradient.frame = self.glowPanel.bounds;
    self.micOuterGradient.frame = self.micOuterRing.bounds;
    self.micOuterRing.layer.cornerRadius = self.micOuterRing.bounds.size.width / 2.0;
    self.micOuterGradient.cornerRadius = self.micOuterRing.bounds.size.width / 2.0;
    self.micOuterRing.clipsToBounds = YES;
    self.micInnerGradient.frame = self.micInnerCircle.bounds;
    self.micInnerGradient.cornerRadius = self.micInnerCircle.bounds.size.width / 2.0;
    self.micInnerCircle.layer.cornerRadius = self.micInnerCircle.bounds.size.width / 2.0;
    self.micInnerCircle.clipsToBounds = YES;
    [self scrollToBottom];
}

- (void)scrollToBottom {
    NSInteger count = self.thread.messages.count;
    if (count == 0) {
        return;
    }
    NSIndexPath *last = [NSIndexPath indexPathForRow:count - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:last atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

#pragma mark - Actions

- (void)handleBackTap {
    [self stopVoicePulse];
    [self.voicePlayer stop];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleTextEntryTap {
    [self stopVoicePulse];
    [self.voicePlayer stop];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleMicPress:(UILongPressGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.voicePressActive = YES;
            [self beginVoiceCaptureIfAllowed];
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            self.voicePressActive = NO;
            [self finishRecording];
            break;
        default:
            break;
    }
}

- (void)beginVoiceCaptureIfAllowed {
    AVAudioSession *session = AVAudioSession.sharedInstance;
    AVAudioSessionRecordPermission permission = session.recordPermission;
    if (permission == AVAudioSessionRecordPermissionGranted) {
        [self beginRecording];
        return;
    }
    if (permission == AVAudioSessionRecordPermissionDenied) {
        [self presentVoiceAccessNotice];
        return;
    }

    [session requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!granted) {
                [self presentVoiceAccessNotice];
                return;
            }
            if (self.voicePressActive) {
                [self beginRecording];
            }
        });
    }];
}

- (void)presentVoiceAccessNotice {
    if (self.presentedViewController) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:AcapeRevealText(AcapeRevealTextKeySignalVoiceAccessHint)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:AcapeRevealText(AcapeRevealTextKeyHubConfirm) style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)beginRecording {
    if (self.recording) {
        return;
    }
    NSError *sessionError = nil;
    AVAudioSession *session = AVAudioSession.sharedInstance;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
                    mode:AVAudioSessionModeDefault
                 options:AVAudioSessionCategoryOptionDefaultToSpeaker
                   error:&sessionError];
    [session setActive:YES error:nil];

    NSString *fileName = [NSString stringWithFormat:@"voice_%lld.m4a", (long long)(NSDate.date.timeIntervalSince1970 * 1000.0)];
    NSURL *fileURL = [[AcapeVaultStore shared] localVoiceURLForFileName:fileName];
    if (!fileURL || sessionError) {
        return;
    }
    NSDictionary *settings = @{
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVSampleRateKey: @44100,
        AVNumberOfChannelsKey: @1,
        AVEncoderAudioQualityKey: @(AVAudioQualityMedium),
    };
    NSError *recordError = nil;
    self.voiceRecorder = [[AVAudioRecorder alloc] initWithURL:fileURL settings:settings error:&recordError];
    if (recordError || ![self.voiceRecorder prepareToRecord] || ![self.voiceRecorder record]) {
        self.voiceRecorder = nil;
        return;
    }
    self.activeVoiceFileName = fileName;
    self.recording = YES;
    self.recordStart = [NSDate date].timeIntervalSince1970;
    self.hintLabel.text = AcapeRevealText(AcapeRevealTextKeySignalVoiceCalling);
    [UIView animateWithDuration:0.6 delay:0.0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionCurveEaseInOut animations:^{
        self.micButton.transform = CGAffineTransformMakeScale(1.12, 1.12);
    } completion:nil];
}

- (void)finishRecording {
    if (!self.recording) {
        return;
    }
    self.recording = NO;
    [self.voiceRecorder stop];
    self.voiceRecorder = nil;
    [self.micButton.layer removeAllAnimations];
    [UIView animateWithDuration:0.2 animations:^{
        self.micButton.transform = CGAffineTransformIdentity;
    }];
    self.hintLabel.text = AcapeRevealText(AcapeRevealTextKeySignalVoiceCallHint);

    NSTimeInterval elapsed = [NSDate date].timeIntervalSince1970 - self.recordStart;
    NSInteger seconds = (NSInteger)round(elapsed);
    seconds = MAX(1, MIN(seconds, 59));
    [[AcapeVaultStore shared] appendViewerVoiceSeconds:seconds fileName:self.activeVoiceFileName toThread:self.thread];
    self.activeVoiceFileName = nil;
    [self.tableView reloadData];
    [self.tableView layoutIfNeeded];
    [self scrollToBottom];
}

- (void)playVoiceFromNote:(AcapeSignalMessage *)note atIndexPath:(NSIndexPath *)indexPath {
    if (note.voiceFileName.length == 0) {
        return;
    }
    NSURL *fileURL = [[AcapeVaultStore shared] localVoiceURLForFileName:note.voiceFileName];
    if (!fileURL) {
        return;
    }
    [self.voicePlayer stop];
    self.voicePlayer.delegate = nil;
    [self stopVoicePulse];
    NSError *error = nil;
    self.voicePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    if (!error && [self.voicePlayer prepareToPlay]) {
        self.voicePlayer.delegate = self;
        [self startVoicePulseAtIndexPath:indexPath];
        [self.voicePlayer play];
    }
}

- (void)startVoicePulseAtIndexPath:(NSIndexPath *)indexPath {
    [self stopVoicePulse];
    self.activeVoiceIndexPath = indexPath;
    AcapeSignalBubbleCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [cell setVoicePulseActive:YES];
}

- (void)stopVoicePulse {
    if (self.activeVoiceIndexPath) {
        AcapeSignalBubbleCell *cell = [self.tableView cellForRowAtIndexPath:self.activeVoiceIndexPath];
        [cell setVoicePulseActive:NO];
    }
    self.activeVoiceIndexPath = nil;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self stopVoicePulse];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self stopVoicePulse];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.thread.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AcapeSignalBubbleCell *cell = [tableView dequeueReusableCellWithIdentifier:kBubbleCellReuseId forIndexPath:indexPath];
    AcapeSignalMessage *message = self.thread.messages[indexPath.row];
    [cell configureWithMessage:message
                 partnerAvatar:self.thread.avatarAssetName
                  viewerAvatar:[AcapeVaultStore shared].currentMemberProfile.avatarAssetName];
    [cell setVoicePulseActive:[self.activeVoiceIndexPath isEqual:indexPath]];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AcapeSignalMessage *note = self.thread.messages[indexPath.row];
    if (note.kind == AcapeSignalMessageKindVoice && note.fromViewer) {
        [self playVoiceFromNote:note atIndexPath:indexPath];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

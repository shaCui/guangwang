#import "AcapeSignalChatScreen.h"
#import "AcapeSignalBubbleCell.h"
#import "AcapeSignalVoiceScreen.h"
#import "AcapeFlagChoiceSheet.h"
#import "AcapeFlagScreen.h"
#import "AcapeCurbConfirmDialog.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeNavKit.h"
#import "AcapeRevealText.h"
#import "AcapeVaultStore.h"
#import "AcapeMemberProfile.h"
#import "UIViewController+AcapeDismissKeyboard.h"
@import AVFoundation;

static NSString * const kBubbleCellReuseId = @"AcapeSignalBubbleCell";

@interface AcapeSignalChatScreen () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, AVAudioPlayerDelegate>
@property (nonatomic, strong) AcapeSignalThread *thread;
@property (nonatomic, strong) AcapeAuroraBackdrop *backdrop;
@property (nonatomic, strong) UIButton *backControl;
@property (nonatomic, strong) UIImageView *headerAvatarView;
@property (nonatomic, strong) UILabel *headerNameLabel;
@property (nonatomic, strong) UIButton *moreControl;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *inputBar;
@property (nonatomic, strong) UIButton *micControl;
@property (nonatomic, strong) UIView *inputField;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *sendControl;
@property (nonatomic, strong) NSLayoutConstraint *inputBarBottomC;
@property (nonatomic, strong) AVAudioPlayer *voicePlayer;
@property (nonatomic, strong) NSIndexPath *activeVoiceIndexPath;
@end

@implementation AcapeSignalChatScreen

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
    [self buildInputBar];
    [self buildTable];
    [self acape_enableDismissKeyboardOnBackgroundTap];
    [self scrollToBottomAnimated:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSignalThreadDidUpdate:)
                                                 name:AcapeSignalThreadDidUpdateNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [self.tableView reloadData];
    [self.tableView layoutIfNeeded];
    [self scrollToBottomAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Layout

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
    [self.moreControl addTarget:self action:@selector(handleMoreTap) forControlEvents:UIControlEventTouchUpInside];
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

- (void)buildInputBar {
    self.inputBar = [[UIView alloc] init];
    self.inputBar.backgroundColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0];
    self.inputBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.inputBar];

    self.micControl = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.micControl setImage:[[UIImage imageNamed:@"话筒"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    self.micControl.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.micControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.micControl addTarget:self action:@selector(handleMicTap) forControlEvents:UIControlEventTouchUpInside];
    [self.inputBar addSubview:self.micControl];

    self.inputField = [[UIView alloc] init];
    self.inputField.backgroundColor = [AcapeAuroraBackdrop cardColor];
    self.inputField.layer.cornerRadius = 16.0;
    self.inputField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.inputBar addSubview:self.inputField];

    self.textField = [[UITextField alloc] init];
    self.textField.textColor = UIColor.whiteColor;
    self.textField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.textField.tintColor = [AcapeAuroraBackdrop accentColor];
    self.textField.returnKeyType = UIReturnKeySend;
    self.textField.delegate = self;
    self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:AcapeRevealText(AcapeRevealTextKeySignalInputPlaceholder)
                                                                            attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.4]}];
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.inputField addSubview:self.textField];

    self.sendControl = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.sendControl setImage:[[UIImage imageNamed:@"发送按钮"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    self.sendControl.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.sendControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sendControl addTarget:self action:@selector(handleSendTap) forControlEvents:UIControlEventTouchUpInside];
    [self.inputField addSubview:self.sendControl];

    self.inputBarBottomC = [self.inputBar.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor];

    [NSLayoutConstraint activateConstraints:@[
        [self.inputBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.inputBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        self.inputBarBottomC,

        [self.inputField.topAnchor constraintEqualToAnchor:self.inputBar.topAnchor constant:12.0],
        [self.inputField.trailingAnchor constraintEqualToAnchor:self.inputBar.trailingAnchor constant:-25.0],
        [self.inputField.leadingAnchor constraintEqualToAnchor:self.inputBar.leadingAnchor constant:71.0],
        [self.inputField.heightAnchor constraintEqualToConstant:52.0],
        [self.inputField.bottomAnchor constraintEqualToAnchor:self.inputBar.safeAreaLayoutGuide.bottomAnchor constant:-12.0],

        [self.micControl.leadingAnchor constraintEqualToAnchor:self.inputBar.leadingAnchor constant:22.0],
        [self.micControl.centerYAnchor constraintEqualToAnchor:self.inputField.centerYAnchor],
        [self.micControl.widthAnchor constraintEqualToConstant:32.0],
        [self.micControl.heightAnchor constraintEqualToConstant:32.0],

        [self.sendControl.trailingAnchor constraintEqualToAnchor:self.inputField.trailingAnchor constant:-8.0],
        [self.sendControl.centerYAnchor constraintEqualToAnchor:self.inputField.centerYAnchor],
        [self.sendControl.widthAnchor constraintEqualToConstant:36.0],
        [self.sendControl.heightAnchor constraintEqualToConstant:36.0],

        [self.textField.leadingAnchor constraintEqualToAnchor:self.inputField.leadingAnchor constant:16.0],
        [self.textField.trailingAnchor constraintEqualToAnchor:self.sendControl.leadingAnchor constant:-6.0],
        [self.textField.topAnchor constraintEqualToAnchor:self.inputField.topAnchor],
        [self.textField.bottomAnchor constraintEqualToAnchor:self.inputField.bottomAnchor],
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
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.contentInset = UIEdgeInsetsMake(12.0, 0.0, 96.0, 0.0);
    [self.tableView registerClass:AcapeSignalBubbleCell.class forCellReuseIdentifier:kBubbleCellReuseId];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:self.tableView belowSubview:self.inputBar];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.backControl.bottomAnchor constant:14.0],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

#pragma mark - Keyboard

- (void)handleKeyboardChange:(NSNotification *)note {
    CGRect endFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat overlap = CGRectGetMaxY(self.view.bounds) - CGRectGetMinY([self.view convertRect:endFrame fromView:nil]);
    self.inputBarBottomC.constant = overlap > 0 ? -overlap : 0.0;
    [UIView animateWithDuration:MAX(duration, 0.2) animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    NSInteger count = self.thread.messages.count;
    if (count == 0) {
        return;
    }
    [self.tableView layoutIfNeeded];
    NSIndexPath *last = [NSIndexPath indexPathForRow:count - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:last atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}

#pragma mark - Actions

- (void)handleBackTap {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleMicTap {
    [self.textField resignFirstResponder];
    AcapeSignalVoiceScreen *voiceScreen = [[AcapeSignalVoiceScreen alloc] initWithThread:self.thread];
    voiceScreen.modalPresentationStyle = UIModalPresentationOverFullScreen;
    voiceScreen.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:voiceScreen animated:YES completion:nil];
}

- (void)handleMoreTap {
    [self.textField resignFirstResponder];
    AcapeFlagChoiceSheet *sheet = [[AcapeFlagChoiceSheet alloc] init];
    __weak typeof(self) weakSelf = self;
    sheet.onReport = ^{
        AcapeFlagScreen *flagScreen = [[AcapeFlagScreen alloc] init];
        flagScreen.reportedMemberName = weakSelf.thread.memberName;
        [weakSelf.navigationController pushViewController:flagScreen animated:YES];
    };
    sheet.onBlock = ^{
        AcapeCurbConfirmDialog *dialog = [[AcapeCurbConfirmDialog alloc] init];
        dialog.onConfirm = ^{
            [[AcapeVaultStore shared] addCurbedMemberWithName:weakSelf.thread.memberName avatarAssetName:weakSelf.thread.avatarAssetName];
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
        [weakSelf presentViewController:dialog animated:YES completion:nil];
    };
    [self presentViewController:sheet animated:NO completion:nil];
}

- (void)handleSendTap {
    NSString *text = self.textField.text;
    if ([text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length == 0) {
        return;
    }
    [[AcapeVaultStore shared] appendViewerText:text toThread:self.thread];
    self.textField.text = @"";
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];
}

- (void)handleSignalThreadDidUpdate:(NSNotification *)note {
    AcapeSignalThread *updatedThread = [note.object isKindOfClass:AcapeSignalThread.class] ? note.object : nil;
    if (updatedThread && updatedThread != self.thread && ![updatedThread.threadId isEqualToString:self.thread.threadId]) {
        return;
    }
    [self.tableView reloadData];
    [self.tableView layoutIfNeeded];
    [self scrollToBottomAnimated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self handleSendTap];
    return NO;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AcapeSignalMessage *note = self.thread.messages[indexPath.row];
    if (note.kind != AcapeSignalMessageKindVoice || !note.fromViewer || note.voiceFileName.length == 0) {
        return;
    }
    [self playVoiceFromNote:note atIndexPath:indexPath];
}

- (void)playVoiceFromNote:(AcapeSignalMessage *)note atIndexPath:(NSIndexPath *)indexPath {
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

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

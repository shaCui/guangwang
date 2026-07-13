#import "AcapeChamberRoomScreen.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeCurbConfirmDialog.h"
#import "AcapeFlagChoiceSheet.h"
#import "AcapeFlagScreen.h"
#import "AcapeMemberHubScreen.h"
#import "AcapeMicRippleHost.h"
#import "AcapeRevealText.h"
#import "AcapeVaultStore.h"
#import "AcapeVoiceLevelMonitor.h"
#import "UIViewController+AcapeDismissKeyboard.h"

static CGFloat const kSideInset = 25.0;
static CGFloat const kSeatSize = 60.0;
static CGFloat const kRowPitch = 105.0;
static NSInteger const kSeatTagBase = 1000;
static NSInteger const kMicTagBase = 2000;

static CGFloat const kInputBarVerticalPad = 12.0;
static CGFloat const kInputFieldHeight = 52.0;
static CGFloat const kInputBarHeight = kInputBarVerticalPad + kInputFieldHeight + kInputBarVerticalPad;

@interface AcapeChamberRoomScreen () <UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic, strong) AcapeChamberRoom *room;
@property (nonatomic, strong) UILabel *roomNameLabel;
@property (nonatomic, strong) UIButton *menuControl;
@property (nonatomic, strong) UIView *seatGridView;
@property (nonatomic, strong) UITableView *chatTable;
@property (nonatomic, strong) UIView *inputBar;
@property (nonatomic, strong) UIView *editorPanel;
@property (nonatomic, strong) UITextField *anchorField;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *sendControl;
@property (nonatomic, strong) UIButton *promptControl;
@property (nonatomic, strong) NSLayoutConstraint *seatGridHeightC;
@property (nonatomic, assign) NSInteger mySeatIndex;
@property (nonatomic, strong) AcapeVoiceLevelMonitor *voiceLevelMonitor;
@end

@implementation AcapeChamberRoomScreen

- (instancetype)initWithRoom:(AcapeChamberRoom *)room {
    self = [super init];
    if (self) {
        _room = room;
        _mySeatIndex = NSNotFound;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [AcapeAuroraBackdrop baseColor];
    [self buildBackground];
    [self buildHeader];
    [self updateMenuControlVisibility];
    [self buildSeatGridShell];
    [self buildInputBar];
    [self buildChatFeed];
    [self initializeMicStates];
    [self reloadSeatGrid];
    [self acape_enableDismissKeyboardOnBackgroundTap];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.view bringSubviewToFront:self.inputBar];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self dismissComposerKeyboard];
    [self.voiceLevelMonitor stopMonitoring];
    [[self myMicHostView] setRippleLive:NO];
}

#pragma mark - Layout

- (void)buildBackground {
    UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chamber_room_bg"]];
    bg.contentMode = UIViewContentModeScaleAspectFill;
    bg.clipsToBounds = YES;
    bg.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:bg];
    [NSLayoutConstraint activateConstraints:@[
        [bg.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [bg.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [bg.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [bg.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)buildHeader {
    self.roomNameLabel = [[UILabel alloc] init];
    self.roomNameLabel.text = self.room.name;
    self.roomNameLabel.textColor = UIColor.whiteColor;
    self.roomNameLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    self.roomNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.roomNameLabel];

    UIView *countPill = [[UIView alloc] init];
    countPill.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
    countPill.layer.cornerRadius = 10.0;
    countPill.clipsToBounds = YES;
    countPill.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:countPill];

    UIImageView *countIcon = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"人数图标"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    countIcon.contentMode = UIViewContentModeScaleAspectFit;
    countIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [countPill addSubview:countIcon];

    UILabel *countLabel = [[UILabel alloc] init];
    countLabel.text = [NSString stringWithFormat:@"%ld", (long)self.room.listenerCount];
    countLabel.textColor = UIColor.whiteColor;
    countLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    countLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [countPill addSubview:countLabel];

    self.menuControl = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.menuControl setImage:[[UIImage imageNamed:@"播放右上角三个点"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    self.menuControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.menuControl addTarget:self action:@selector(handleMenuTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.menuControl];

    UIButton *exitControl = [UIButton buttonWithType:UIButtonTypeCustom];
    [exitControl setImage:[[UIImage imageNamed:@"退出k歌房"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    exitControl.translatesAutoresizingMaskIntoConstraints = NO;
    [exitControl addTarget:self action:@selector(handleExitTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:exitControl];

    [NSLayoutConstraint activateConstraints:@[
        [self.roomNameLabel.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:kSideInset],
        [self.roomNameLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8.0],
        [self.roomNameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.menuControl.leadingAnchor constant:-12.0],

        [countPill.leadingAnchor constraintEqualToAnchor:self.roomNameLabel.leadingAnchor],
        [countPill.topAnchor constraintEqualToAnchor:self.roomNameLabel.bottomAnchor constant:8.0],
        [countPill.heightAnchor constraintEqualToConstant:20.0],
        [countIcon.leadingAnchor constraintEqualToAnchor:countPill.leadingAnchor constant:10.0],
        [countIcon.centerYAnchor constraintEqualToAnchor:countPill.centerYAnchor],
        [countIcon.widthAnchor constraintEqualToConstant:9.0],
        [countIcon.heightAnchor constraintEqualToConstant:9.0],
        [countLabel.leadingAnchor constraintEqualToAnchor:countIcon.trailingAnchor constant:4.0],
        [countLabel.centerYAnchor constraintEqualToAnchor:countPill.centerYAnchor],
        [countLabel.trailingAnchor constraintEqualToAnchor:countPill.trailingAnchor constant:-10.0],

        [exitControl.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-kSideInset],
        [exitControl.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8.0],
        [exitControl.widthAnchor constraintEqualToConstant:36.0],
        [exitControl.heightAnchor constraintEqualToConstant:36.0],

        [self.menuControl.trailingAnchor constraintEqualToAnchor:exitControl.leadingAnchor constant:-12.0],
        [self.menuControl.centerYAnchor constraintEqualToAnchor:exitControl.centerYAnchor],
        [self.menuControl.widthAnchor constraintEqualToConstant:36.0],
        [self.menuControl.heightAnchor constraintEqualToConstant:36.0],
    ]];
}

- (void)updateMenuControlVisibility {
    BOOL ownRoom = [[AcapeVaultStore shared] isMemberOwnedChamberRoom:self.room];
    self.menuControl.hidden = ownRoom;
    self.menuControl.userInteractionEnabled = !ownRoom;
}

- (void)buildSeatGridShell {
    self.seatGridView = [[UIView alloc] init];
    self.seatGridView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.seatGridView];

    NSInteger rows = (NSInteger)ceil(self.room.seats.count / 2.0);
    self.seatGridHeightC = [self.seatGridView.heightAnchor constraintEqualToConstant:rows * kRowPitch];

    [NSLayoutConstraint activateConstraints:@[
        [self.seatGridView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:88.0],
        [self.seatGridView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.seatGridView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        self.seatGridHeightC,
    ]];
}

- (void)reloadSeatGrid {
    for (UIView *subview in self.seatGridView.subviews) {
        [subview removeFromSuperview];
    }

    NSInteger columns = 2;
    NSInteger rows = (NSInteger)ceil(self.room.seats.count / (CGFloat)columns);
    self.seatGridHeightC.constant = rows * kRowPitch;

    for (NSInteger i = 0; i < (NSInteger)self.room.seats.count; i++) {
        AcapeChamberSeat *seat = self.room.seats[i];
        NSInteger col = i % columns;
        NSInteger row = i / columns;

        UIView *seatContainer = [[UIView alloc] init];
        seatContainer.tag = kSeatTagBase + i;
        seatContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [self.seatGridView addSubview:seatContainer];

        UIButton *seatTapControl = [UIButton buttonWithType:UIButtonTypeCustom];
        seatTapControl.tag = kSeatTagBase + i;
        seatTapControl.translatesAutoresizingMaskIntoConstraints = NO;
        [seatTapControl addTarget:self action:@selector(handleSeatTap:) forControlEvents:UIControlEventTouchUpInside];
        [seatContainer addSubview:seatTapControl];

        UIImageView *avatarView = [[UIImageView alloc] init];
        avatarView.contentMode = UIViewContentModeScaleAspectFill;
        avatarView.layer.cornerRadius = kSeatSize / 2.0;
        avatarView.clipsToBounds = YES;
        avatarView.layer.borderWidth = 1.0;
        avatarView.layer.borderColor = [UIColor colorWithRed:0.267 green:0.988 blue:0.953 alpha:1.0].CGColor;
        avatarView.translatesAutoresizingMaskIntoConstraints = NO;
        avatarView.userInteractionEnabled = NO;
        [seatContainer addSubview:avatarView];

        UILabel *nameLabel = [[UILabel alloc] init];
        nameLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        nameLabel.textColor = UIColor.whiteColor;
        nameLabel.textAlignment = NSTextAlignmentCenter;
        nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        nameLabel.userInteractionEnabled = NO;
        [seatContainer addSubview:nameLabel];

        if (seat.occupantName.length > 0) {
            if ([seat.avatarAssetName isEqualToString:self.room.coverAssetName]) {
                avatarView.image = [[AcapeVaultStore shared] chamberCoverImageForRoom:self.room];
            } else {
                avatarView.image = [[AcapeVaultStore shared] avatarImageForAssetName:seat.avatarAssetName];
            }
            nameLabel.text = seat.occupantName;
        } else {
            avatarView.image = [UIImage imageNamed:@"空座位"];
            avatarView.contentMode = UIViewContentModeScaleAspectFit;
            avatarView.backgroundColor = UIColor.clearColor;
            nameLabel.text = @"";
        }

        AcapeMicRippleHost *micHost = [[AcapeMicRippleHost alloc] initWithFrame:CGRectZero];
        micHost.tag = kMicTagBase + i;
        micHost.translatesAutoresizingMaskIntoConstraints = NO;
        [micHost.micControl addTarget:self action:@selector(handleMicTap:) forControlEvents:UIControlEventTouchUpInside];
        micHost.micControl.tag = kMicTagBase + i;
        [self.seatGridView addSubview:micHost];
        [self updateMicHost:micHost forSeat:seat atIndex:i];

        NSMutableArray<NSLayoutConstraint *> *seatConstraints = [NSMutableArray array];
        [seatConstraints addObjectsFromArray:@[
            [seatContainer.topAnchor constraintEqualToAnchor:self.seatGridView.topAnchor constant:row * kRowPitch],
            [seatContainer.widthAnchor constraintEqualToConstant:kSeatSize],
            [avatarView.topAnchor constraintEqualToAnchor:seatContainer.topAnchor],
            [avatarView.centerXAnchor constraintEqualToAnchor:seatContainer.centerXAnchor],
            [avatarView.widthAnchor constraintEqualToConstant:kSeatSize],
            [avatarView.heightAnchor constraintEqualToConstant:kSeatSize],
            [nameLabel.topAnchor constraintEqualToAnchor:avatarView.bottomAnchor constant:6.0],
            [nameLabel.centerXAnchor constraintEqualToAnchor:seatContainer.centerXAnchor],
            [nameLabel.widthAnchor constraintEqualToConstant:kSeatSize + 20.0],
            [seatContainer.bottomAnchor constraintEqualToAnchor:nameLabel.bottomAnchor],
            [seatTapControl.topAnchor constraintEqualToAnchor:seatContainer.topAnchor],
            [seatTapControl.leadingAnchor constraintEqualToAnchor:seatContainer.leadingAnchor],
            [seatTapControl.trailingAnchor constraintEqualToAnchor:seatContainer.trailingAnchor],
            [seatTapControl.bottomAnchor constraintEqualToAnchor:seatContainer.bottomAnchor],
            [micHost.centerYAnchor constraintEqualToAnchor:avatarView.centerYAnchor],
            [micHost.widthAnchor constraintEqualToConstant:56.0],
            [micHost.heightAnchor constraintEqualToConstant:56.0],
        ]];
        if (col == 0) {
            [seatConstraints addObject:[seatContainer.leadingAnchor constraintEqualToAnchor:self.seatGridView.leadingAnchor constant:kSideInset]];
            [seatConstraints addObject:[micHost.leadingAnchor constraintEqualToAnchor:seatContainer.trailingAnchor constant:0.0]];
        } else {
            [seatConstraints addObject:[seatContainer.trailingAnchor constraintEqualToAnchor:self.seatGridView.trailingAnchor constant:-kSideInset]];
            [seatConstraints addObject:[micHost.trailingAnchor constraintEqualToAnchor:seatContainer.leadingAnchor constant:0.0]];
        }
        [NSLayoutConstraint activateConstraints:seatConstraints];
    }
    [self syncVoiceLevelMonitor];
}

- (void)updateMicHost:(AcapeMicRippleHost *)micHost forSeat:(AcapeChamberSeat *)seat atIndex:(NSInteger)index {
    UIButton *micControl = micHost.micControl;
    BOOL occupied = seat.occupantName.length > 0;
    micHost.hidden = !occupied;
    micControl.userInteractionEnabled = occupied && index == self.mySeatIndex;
    if (!occupied) {
        [micHost setRippleLive:NO];
        return;
    }
    NSString *assetName = seat.micLive ? @"开麦图标" : @"静音图标";
    [micControl setImage:[[UIImage imageNamed:assetName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    micControl.alpha = (index == self.mySeatIndex) ? 1.0 : 0.95;
    if (index == self.mySeatIndex) {
        [micHost setRippleLive:NO];
    }
}

- (AcapeVoiceLevelMonitor *)voiceLevelMonitor {
    if (!_voiceLevelMonitor) {
        _voiceLevelMonitor = [[AcapeVoiceLevelMonitor alloc] init];
    }
    return _voiceLevelMonitor;
}

- (AcapeMicRippleHost *)myMicHostView {
    if (self.mySeatIndex == NSNotFound) {
        return nil;
    }
    UIView *micView = [self.seatGridView viewWithTag:kMicTagBase + self.mySeatIndex];
    return [micView isKindOfClass:AcapeMicRippleHost.class] ? (AcapeMicRippleHost *)micView : nil;
}

- (void)syncVoiceLevelMonitor {
    BOOL shouldMonitor = self.mySeatIndex != NSNotFound
        && self.mySeatIndex < (NSInteger)self.room.seats.count
        && self.room.seats[self.mySeatIndex].micLive;
    if (!shouldMonitor) {
        [self.voiceLevelMonitor stopMonitoring];
        [[self myMicHostView] setRippleLive:NO];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.voiceLevelMonitor startMonitoringWithHandler:^(BOOL speaking) {
        [[weakSelf myMicHostView] setRippleLive:speaking];
    }];
}

#pragma mark - Session State

- (BOOL)isTemplateChamberRoom {
    return [self.room.roomId isEqualToString:@"room_1"]
        || [self.room.roomId isEqualToString:@"room_2"]
        || [self.room.roomId isEqualToString:@"room_3"]
        || [self.room.roomId isEqualToString:@"room_4"];
}

- (BOOL)currentMemberIsRoomHost {
    AcapeChamberSeat *hostSeat = self.room.seats.firstObject;
    if (hostSeat.occupantName.length == 0) {
        return NO;
    }
    NSString *displayName = [AcapeVaultStore shared].currentMemberProfile.displayName;
    return [hostSeat.occupantName isEqualToString:displayName];
}

- (void)initializeMicStates {
    AcapeMemberProfile *profile = [AcapeVaultStore shared].currentMemberProfile;
    self.mySeatIndex = NSNotFound;

    for (NSInteger i = 0; i < (NSInteger)self.room.seats.count; i++) {
        AcapeChamberSeat *seat = self.room.seats[i];
        if (seat.occupantName.length > 0 && [seat.occupantName isEqualToString:profile.displayName]) {
            self.mySeatIndex = i;
        }
    }

    for (AcapeChamberSeat *seat in self.room.seats) {
        seat.micLive = NO;
    }

    if ([self currentMemberIsRoomHost] && self.mySeatIndex == 0) {
        self.room.seats.firstObject.micLive = YES;
    }
}

- (void)persistRoomStateIfNeeded {
    if ([self isTemplateChamberRoom]) {
        return;
    }
    [[AcapeVaultStore shared] persistMemberChamberRooms];
}

- (void)vacateSeatAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.room.seats.count) {
        return;
    }
    AcapeChamberSeat *seat = self.room.seats[index];
    seat.occupantName = nil;
    seat.avatarAssetName = nil;
    seat.micLive = NO;
}

#pragma mark - Input / Chat

- (NSAttributedString *)inputPlaceholderText {
    return [[NSAttributedString alloc] initWithString:AcapeRevealText(AcapeRevealTextKeySignalInputPlaceholder)
                                           attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.4]}];
}

- (void)configureComposerField:(UITextField *)textField {
    textField.textColor = UIColor.whiteColor;
    textField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    textField.tintColor = [AcapeAuroraBackdrop accentColor];
    textField.returnKeyType = UIReturnKeySend;
    textField.delegate = self;
    textField.attributedPlaceholder = [self inputPlaceholderText];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)installComposerInContainer:(UIView *)container
                             field:(UIView *)field
                         textField:(UITextField *)textField
                       sendControl:(UIButton *)sendControl {
    [container addSubview:field];
    [field addSubview:textField];
    [field addSubview:sendControl];
    [NSLayoutConstraint activateConstraints:@[
        [field.topAnchor constraintEqualToAnchor:container.topAnchor constant:kInputBarVerticalPad],
        [field.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:kSideInset],
        [field.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-kSideInset],
        [field.heightAnchor constraintEqualToConstant:kInputFieldHeight],
        [field.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-kInputBarVerticalPad],
        [sendControl.trailingAnchor constraintEqualToAnchor:field.trailingAnchor constant:-8.0],
        [sendControl.centerYAnchor constraintEqualToAnchor:field.centerYAnchor],
        [sendControl.widthAnchor constraintEqualToConstant:36.0],
        [sendControl.heightAnchor constraintEqualToConstant:36.0],
        [textField.leadingAnchor constraintEqualToAnchor:field.leadingAnchor constant:16.0],
        [textField.trailingAnchor constraintEqualToAnchor:sendControl.leadingAnchor constant:-6.0],
        [textField.topAnchor constraintEqualToAnchor:field.topAnchor],
        [textField.bottomAnchor constraintEqualToAnchor:field.bottomAnchor],
    ]];
}

- (void)buildInputBar {
    CGFloat panelWidth = CGRectGetWidth(UIScreen.mainScreen.bounds);
    if (panelWidth <= 0.0) {
        panelWidth = 375.0;
    }

    self.editorPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, panelWidth, kInputBarHeight)];
    self.editorPanel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.editorPanel.backgroundColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0];

    UIView *editorField = [[UIView alloc] init];
    editorField.backgroundColor = [AcapeAuroraBackdrop cardColor];
    editorField.layer.cornerRadius = 16.0;
    editorField.translatesAutoresizingMaskIntoConstraints = NO;

    self.textField = [[UITextField alloc] init];
    [self configureComposerField:self.textField];

    self.sendControl = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.sendControl setImage:[[UIImage imageNamed:@"发送按钮"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    self.sendControl.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.sendControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sendControl addTarget:self action:@selector(handleSendTap) forControlEvents:UIControlEventTouchUpInside];
    [self installComposerInContainer:self.editorPanel
                               field:editorField
                           textField:self.textField
                         sendControl:self.sendControl];

    self.anchorField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.anchorField.hidden = YES;
    self.anchorField.inputAccessoryView = self.editorPanel;
    [self.view addSubview:self.anchorField];

    self.inputBar = [[UIView alloc] init];
    self.inputBar.backgroundColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0];
    self.inputBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.inputBar];

    UIView *promptField = [[UIView alloc] init];
    promptField.backgroundColor = [AcapeAuroraBackdrop cardColor];
    promptField.layer.cornerRadius = 16.0;
    promptField.userInteractionEnabled = NO;
    promptField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.inputBar addSubview:promptField];

    UILabel *promptLabel = [[UILabel alloc] init];
    promptLabel.attributedText = [self inputPlaceholderText];
    promptLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [promptField addSubview:promptLabel];

    UIImageView *promptSendMark = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"发送按钮"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    promptSendMark.contentMode = UIViewContentModeScaleAspectFit;
    promptSendMark.translatesAutoresizingMaskIntoConstraints = NO;
    [promptField addSubview:promptSendMark];

    self.promptControl = [UIButton buttonWithType:UIButtonTypeCustom];
    self.promptControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.promptControl addTarget:self action:@selector(handlePromptTap) forControlEvents:UIControlEventTouchUpInside];
    [self.inputBar addSubview:self.promptControl];

    [NSLayoutConstraint activateConstraints:@[
        [self.inputBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.inputBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.inputBar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [promptField.topAnchor constraintEqualToAnchor:self.inputBar.topAnchor constant:kInputBarVerticalPad],
        [promptField.leadingAnchor constraintEqualToAnchor:self.inputBar.leadingAnchor constant:kSideInset],
        [promptField.trailingAnchor constraintEqualToAnchor:self.inputBar.trailingAnchor constant:-kSideInset],
        [promptField.heightAnchor constraintEqualToConstant:kInputFieldHeight],
        [promptField.bottomAnchor constraintEqualToAnchor:self.inputBar.bottomAnchor constant:-kInputBarVerticalPad],
        [promptLabel.leadingAnchor constraintEqualToAnchor:promptField.leadingAnchor constant:16.0],
        [promptLabel.centerYAnchor constraintEqualToAnchor:promptField.centerYAnchor],
        [promptSendMark.trailingAnchor constraintEqualToAnchor:promptField.trailingAnchor constant:-8.0],
        [promptSendMark.centerYAnchor constraintEqualToAnchor:promptField.centerYAnchor],
        [promptSendMark.widthAnchor constraintEqualToConstant:36.0],
        [promptSendMark.heightAnchor constraintEqualToConstant:36.0],
        [self.promptControl.topAnchor constraintEqualToAnchor:self.inputBar.topAnchor],
        [self.promptControl.leadingAnchor constraintEqualToAnchor:self.inputBar.leadingAnchor],
        [self.promptControl.trailingAnchor constraintEqualToAnchor:self.inputBar.trailingAnchor],
        [self.promptControl.bottomAnchor constraintEqualToAnchor:self.inputBar.bottomAnchor],
    ]];
}

- (void)handlePromptTap {
    if (self.textField.isFirstResponder) {
        return;
    }
    [self.anchorField becomeFirstResponder];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.textField becomeFirstResponder];
    });
}

- (void)buildChatFeed {
    self.chatTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.chatTable.backgroundColor = UIColor.clearColor;
    self.chatTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.chatTable.showsVerticalScrollIndicator = NO;
    self.chatTable.dataSource = self;
    self.chatTable.rowHeight = UITableViewAutomaticDimension;
    self.chatTable.estimatedRowHeight = 44.0;
    self.chatTable.allowsSelection = NO;
    self.chatTable.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.chatTable.translatesAutoresizingMaskIntoConstraints = NO;
    [self.chatTable registerClass:UITableViewCell.class forCellReuseIdentifier:@"chatLine"];
    [self.view insertSubview:self.chatTable belowSubview:self.inputBar];

    [NSLayoutConstraint activateConstraints:@[
        [self.chatTable.topAnchor constraintEqualToAnchor:self.seatGridView.bottomAnchor constant:12.0],
        [self.chatTable.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.chatTable.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.chatTable.bottomAnchor constraintEqualToAnchor:self.inputBar.topAnchor],
    ]];
}

#pragma mark - Actions

- (void)handleMenuTap {
    AcapeVaultStore *store = [AcapeVaultStore shared];
    if ([store isMemberOwnedChamberRoom:self.room]) {
        return;
    }

    [self dismissComposerKeyboard];
    NSString *hostName = [store chamberHostNameForRoom:self.room];
    NSString *hostAvatar = [store chamberHostAvatarAssetNameForRoom:self.room];
    if (hostName.length == 0) {
        return;
    }

    AcapeFlagChoiceSheet *sheet = [[AcapeFlagChoiceSheet alloc] init];
    __weak typeof(self) weakSelf = self;
    sheet.onReport = ^{
        AcapeFlagScreen *flagScreen = [[AcapeFlagScreen alloc] init];
        flagScreen.reportedMemberName = hostName;
        [weakSelf.navigationController pushViewController:flagScreen animated:YES];
    };
    sheet.onBlock = ^{
        AcapeCurbConfirmDialog *dialog = [[AcapeCurbConfirmDialog alloc] init];
        dialog.onConfirm = ^{
            [weakSelf.voiceLevelMonitor stopMonitoring];
            [[weakSelf myMicHostView] setRippleLive:NO];
            [store addCurbedMemberWithName:hostName avatarAssetName:hostAvatar];
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
        [weakSelf presentViewController:dialog animated:YES completion:nil];
    };
    [self presentViewController:sheet animated:NO completion:nil];
}

- (void)handleExitTap {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:AcapeRevealText(AcapeRevealTextKeyChamberLeaveConfirm)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:AcapeRevealText(AcapeRevealTextKeyHubCancel) style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:AcapeRevealText(AcapeRevealTextKeyBondSureAction) style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentProfileForSeat:(AcapeChamberSeat *)seat {
    if (seat.occupantName.length == 0) {
        return;
    }
    NSString *memberName = [AcapeVaultStore shared].currentMemberProfile.displayName;
    if ([seat.occupantName isEqualToString:memberName]) {
        return;
    }
    AcapeMemberHubScreen *profile = [[AcapeMemberHubScreen alloc] initWithMemberName:seat.occupantName
                                                                     avatarAssetName:seat.avatarAssetName];
    [self.navigationController pushViewController:profile animated:YES];
}

- (void)handleSeatTap:(UIButton *)sender {
    NSInteger seatIndex = sender.tag - kSeatTagBase;
    if (seatIndex < 0 || seatIndex >= (NSInteger)self.room.seats.count) {
        return;
    }
    AcapeChamberSeat *seat = self.room.seats[seatIndex];
    if (seat.occupantName.length > 0) {
        [self presentProfileForSeat:seat];
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:AcapeRevealText(AcapeRevealTextKeyChamberJoinConfirm)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:AcapeRevealText(AcapeRevealTextKeyHubCancel) style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:AcapeRevealText(AcapeRevealTextKeyBondSureAction) style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        [self performSeatJoinAtIndex:seatIndex];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performSeatJoinAtIndex:(NSInteger)seatIndex {
    if (seatIndex < 0 || seatIndex >= (NSInteger)self.room.seats.count) {
        return;
    }
    AcapeChamberSeat *seat = self.room.seats[seatIndex];
    if (seat.occupantName.length > 0) {
        return;
    }

    AcapeMemberProfile *profile = [AcapeVaultStore shared].currentMemberProfile;
    if (self.mySeatIndex != NSNotFound && self.mySeatIndex != seatIndex) {
        [self vacateSeatAtIndex:self.mySeatIndex];
    }

    seat.occupantName = profile.displayName;
    seat.avatarAssetName = [[AcapeVaultStore shared] resolvedAvatarAssetName:profile.avatarAssetName];
    seat.micLive = YES;
    self.mySeatIndex = seatIndex;
    [self reloadSeatGrid];
    [self persistRoomStateIfNeeded];
}

- (void)handleMicTap:(UIButton *)sender {
    NSInteger seatIndex = sender.tag - kMicTagBase;
    if (seatIndex != self.mySeatIndex) {
        return;
    }
    AcapeChamberSeat *seat = self.room.seats[seatIndex];
    if (seat.occupantName.length == 0) {
        return;
    }
    seat.micLive = !seat.micLive;
    AcapeMicRippleHost *micHost = [sender.superview isKindOfClass:AcapeMicRippleHost.class] ? (AcapeMicRippleHost *)sender.superview : nil;
    if (micHost) {
        [self updateMicHost:micHost forSeat:seat atIndex:seatIndex];
    }
    [self syncVoiceLevelMonitor];
    [self persistRoomStateIfNeeded];
}

- (void)dismissComposerKeyboard {
    [self.textField resignFirstResponder];
    [self.anchorField resignFirstResponder];
    [self.view endEditing:YES];
    self.inputBar.hidden = NO;
}

- (void)handleSendTap {
    NSString *text = self.textField.text;
    if ([text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length == 0) {
        return;
    }
    [[AcapeVaultStore shared] appendChatLine:text toRoom:self.room];
    self.textField.text = @"";
    [self dismissComposerKeyboard];
    [self.chatTable reloadData];
    NSInteger count = self.room.chatLines.count;
    if (count > 0) {
        [self.chatTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.textField) {
        self.inputBar.hidden = YES;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.textField) {
        self.inputBar.hidden = NO;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self handleSendTap];
    return NO;
}

#pragma mark - Chat feed

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.room.chatLines.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"chatLine" forIndexPath:indexPath];
    cell.backgroundColor = UIColor.clearColor;
    cell.contentView.backgroundColor = UIColor.clearColor;
    for (UIView *sub in cell.contentView.subviews) {
        [sub removeFromSuperview];
    }
    AcapeChamberChatLine *line = self.room.chatLines[indexPath.row];

    UIImageView *avatar = [[UIImageView alloc] init];
    avatar.contentMode = UIViewContentModeScaleAspectFill;
    avatar.layer.cornerRadius = 15.0;
    avatar.clipsToBounds = YES;
    avatar.image = [[AcapeVaultStore shared] avatarImageForAssetName:line.avatarAssetName];
    avatar.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:avatar];

    UIView *bubble = [[UIView alloc] init];
    bubble.backgroundColor = [UIColor colorWithRed:0.608 green:0.596 blue:0.612 alpha:0.25];
    bubble.layer.cornerRadius = 16.0;
    bubble.layer.maskedCorners = kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    bubble.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:bubble];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.text = line.speakerName;
    nameLabel.textColor = [UIColor colorWithRed:1.0 green:0.922 blue:0.231 alpha:1.0];
    nameLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [bubble addSubview:nameLabel];

    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.text = line.text;
    textLabel.textColor = UIColor.whiteColor;
    textLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    textLabel.numberOfLines = 0;
    textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [bubble addSubview:textLabel];

    [NSLayoutConstraint activateConstraints:@[
        [avatar.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:kSideInset],
        [avatar.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:6.0],
        [avatar.widthAnchor constraintEqualToConstant:30.0],
        [avatar.heightAnchor constraintEqualToConstant:30.0],

        [bubble.leadingAnchor constraintEqualToAnchor:avatar.trailingAnchor constant:8.0],
        [bubble.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:6.0],
        [bubble.trailingAnchor constraintLessThanOrEqualToAnchor:cell.contentView.trailingAnchor constant:-kSideInset],
        [bubble.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-6.0],

        [nameLabel.topAnchor constraintEqualToAnchor:bubble.topAnchor constant:8.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:bubble.leadingAnchor constant:10.0],
        [nameLabel.trailingAnchor constraintEqualToAnchor:bubble.trailingAnchor constant:-10.0],

        [textLabel.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:2.0],
        [textLabel.leadingAnchor constraintEqualToAnchor:bubble.leadingAnchor constant:10.0],
        [textLabel.trailingAnchor constraintEqualToAnchor:bubble.trailingAnchor constant:-10.0],
        [textLabel.bottomAnchor constraintEqualToAnchor:bubble.bottomAnchor constant:-8.0],
    ]];
    return cell;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

#import "AcapeMuseScreen.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeNavKit.h"
#import "AcapeRevealText.h"
#import "AcapeVaultStore.h"
#import "AcapeMemberProfile.h"
#import "AcapeSignalMessage.h"
#import "AcapeLatticeOverlay.h"
#import "UIViewController+AcapeDismissKeyboard.h"

static CGFloat const kSideInset = 25.0;
static CGFloat const kHeaderBarHeight = 44.0;
static CGFloat const kBannerTopSpacing = 20.0;
static CGFloat const kMascotTopSpacing = -5.0;
static CGFloat const kBubblePadding = 16.0;
static CGFloat const kBubbleMaxWidth = 272.0;
static CGFloat const kBubbleMinWidth = 96.0;

@interface AcapeMuseScreen () <UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *inputBar;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) NSLayoutConstraint *inputBottomC;
@property (nonatomic, strong) NSMutableArray<AcapeSignalMessage *> *messages;
@property (nonatomic, assign) NSInteger replyCursor;
@property (nonatomic, weak) UIView *headerBar;
@property (nonatomic, weak) UIView *bannerHost;
@end

@implementation AcapeMuseScreen

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [AcapeAuroraBackdrop baseColor];
    [self loadConversation];
    [self buildBackdrop];
    [self buildHeader];
    [self buildBanner];
    [self buildInputBar];
    [self buildTable];
    [self acape_enableDismissKeyboardOnBackgroundTap];
    [self.tableView reloadData];
    [self scrollToBottom];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)loadConversation {
    self.messages = [@[
        [AcapeSignalMessage textMessageWithId:@"muse_intro"
                                         body:AcapeRevealText(AcapeRevealTextKeyMuseIntro)
                                   fromViewer:NO
                                     timeText:[self formattedTimeText]],
    ] mutableCopy];
    self.replyCursor = 0;
}

- (void)buildBackdrop {
    AcapeLatticeOverlay *lattice = [[AcapeLatticeOverlay alloc] init];
    lattice.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:lattice];

    [NSLayoutConstraint activateConstraints:@[
        [lattice.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [lattice.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [lattice.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [lattice.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.28],
    ]];
}

- (NSString *)formattedTimeText {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"h:mm a";
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    return [formatter stringFromDate:[NSDate date]];
}

- (NSString *)displayTimeForMessage:(AcapeSignalMessage *)message {
    return message.timeText.length > 0 ? message.timeText : [self formattedTimeText];
}

- (void)buildHeader {
    UIView *headerBar = [[UIView alloc] init];
    headerBar.backgroundColor = UIColor.clearColor;
    headerBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:headerBar];

    UIButton *backControl = [AcapeNavKit backControlWithTarget:self action:@selector(handleBackTap)];
    backControl.translatesAutoresizingMaskIntoConstraints = NO;
    [headerBar addSubview:backControl];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = AcapeRevealText(AcapeRevealTextKeyMuseTitle);
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [headerBar addSubview:titleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [headerBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [headerBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [headerBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [headerBar.heightAnchor constraintEqualToConstant:kHeaderBarHeight],

        [backControl.leadingAnchor constraintEqualToAnchor:headerBar.leadingAnchor constant:kSideInset],
        [backControl.centerYAnchor constraintEqualToAnchor:headerBar.centerYAnchor],
        [titleLabel.centerYAnchor constraintEqualToAnchor:headerBar.centerYAnchor],
        [titleLabel.centerXAnchor constraintEqualToAnchor:headerBar.centerXAnchor],
    ]];
    self.headerBar = headerBar;
}

- (void)buildBanner {
    UIView *banner = [[UIView alloc] init];
    banner.layer.cornerRadius = 20.0;
    banner.clipsToBounds = YES;
    banner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:banner];

    UIImageView *bannerBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"机器背景"]];
    bannerBackground.contentMode = UIViewContentModeScaleAspectFill;
    bannerBackground.translatesAutoresizingMaskIntoConstraints = NO;
    [banner addSubview:bannerBackground];

    UIImageView *mascot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"首页蓝色娃娃"]];
    mascot.contentMode = UIViewContentModeScaleAspectFit;
    mascot.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:mascot];

    UILabel *greetingTitle = [[UILabel alloc] init];
    greetingTitle.text = AcapeRevealText(AcapeRevealTextKeyMuseGreetingTitle);
    greetingTitle.textColor = UIColor.whiteColor;
    greetingTitle.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    greetingTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [banner addSubview:greetingTitle];

    UILabel *greetingBody = [[UILabel alloc] init];
    greetingBody.text = AcapeRevealText(AcapeRevealTextKeyMuseGreetingBody);
    greetingBody.textColor = [UIColor colorWithWhite:1.0 alpha:0.85];
    greetingBody.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    greetingBody.numberOfLines = 0;
    greetingBody.translatesAutoresizingMaskIntoConstraints = NO;
    [banner addSubview:greetingBody];

    [NSLayoutConstraint activateConstraints:@[
        [banner.topAnchor constraintEqualToAnchor:self.headerBar.bottomAnchor constant:kBannerTopSpacing],
        [banner.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:kSideInset],
        [banner.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-kSideInset],
        [banner.heightAnchor constraintEqualToConstant:108.0],

        [bannerBackground.topAnchor constraintEqualToAnchor:banner.topAnchor],
        [bannerBackground.leadingAnchor constraintEqualToAnchor:banner.leadingAnchor],
        [bannerBackground.trailingAnchor constraintEqualToAnchor:banner.trailingAnchor],
        [bannerBackground.bottomAnchor constraintEqualToAnchor:banner.bottomAnchor],

        [mascot.topAnchor constraintEqualToAnchor:self.headerBar.bottomAnchor constant:kMascotTopSpacing],
        [mascot.trailingAnchor constraintEqualToAnchor:banner.trailingAnchor constant:6.0],
        [mascot.widthAnchor constraintEqualToConstant:120.0],
        [mascot.heightAnchor constraintEqualToConstant:120.0],

        [greetingTitle.topAnchor constraintEqualToAnchor:banner.topAnchor constant:22.0],
        [greetingTitle.leadingAnchor constraintEqualToAnchor:banner.leadingAnchor constant:18.0],

        [greetingBody.topAnchor constraintEqualToAnchor:greetingTitle.bottomAnchor constant:8.0],
        [greetingBody.leadingAnchor constraintEqualToAnchor:banner.leadingAnchor constant:18.0],
        [greetingBody.widthAnchor constraintEqualToConstant:180.0],
    ]];
    self.bannerHost = banner;
}

- (void)buildInputBar {
    self.inputBar = [[UIView alloc] init];
    self.inputBar.backgroundColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0];
    self.inputBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.inputBar];

    UIView *field = [[UIView alloc] init];
    field.backgroundColor = [AcapeAuroraBackdrop cardColor];
    field.layer.cornerRadius = 16.0;
    field.translatesAutoresizingMaskIntoConstraints = NO;
    [self.inputBar addSubview:field];

    self.textField = [[UITextField alloc] init];
    self.textField.textColor = UIColor.whiteColor;
    self.textField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.textField.tintColor = [AcapeAuroraBackdrop accentColor];
    self.textField.returnKeyType = UIReturnKeySend;
    self.textField.delegate = self;
    self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:AcapeRevealText(AcapeRevealTextKeySignalInputPlaceholder)
                                                                            attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.4]}];
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    [field addSubview:self.textField];

    UIButton *sendControl = [UIButton buttonWithType:UIButtonTypeCustom];
    [sendControl setImage:[[UIImage imageNamed:@"发送按钮"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    sendControl.imageView.contentMode = UIViewContentModeScaleAspectFit;
    sendControl.translatesAutoresizingMaskIntoConstraints = NO;
    [sendControl addTarget:self action:@selector(handleSendTap) forControlEvents:UIControlEventTouchUpInside];
    [field addSubview:sendControl];

    self.inputBottomC = [self.inputBar.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor];
    [NSLayoutConstraint activateConstraints:@[
        [self.inputBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.inputBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        self.inputBottomC,
        [field.topAnchor constraintEqualToAnchor:self.inputBar.topAnchor constant:12.0],
        [field.leadingAnchor constraintEqualToAnchor:self.inputBar.leadingAnchor constant:kSideInset],
        [field.trailingAnchor constraintEqualToAnchor:self.inputBar.trailingAnchor constant:-kSideInset],
        [field.heightAnchor constraintEqualToConstant:52.0],
        [field.bottomAnchor constraintEqualToAnchor:self.inputBar.safeAreaLayoutGuide.bottomAnchor constant:-12.0],
        [sendControl.trailingAnchor constraintEqualToAnchor:field.trailingAnchor constant:-8.0],
        [sendControl.centerYAnchor constraintEqualToAnchor:field.centerYAnchor],
        [sendControl.widthAnchor constraintEqualToConstant:36.0],
        [sendControl.heightAnchor constraintEqualToConstant:36.0],
        [self.textField.leadingAnchor constraintEqualToAnchor:field.leadingAnchor constant:16.0],
        [self.textField.trailingAnchor constraintEqualToAnchor:sendControl.leadingAnchor constant:-6.0],
        [self.textField.topAnchor constraintEqualToAnchor:field.topAnchor],
        [self.textField.bottomAnchor constraintEqualToAnchor:field.bottomAnchor],
    ]];
}

- (void)buildTable {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 80.0;
    self.tableView.allowsSelection = NO;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.contentInset = UIEdgeInsetsMake(12.0, 0.0, 12.0, 0.0);
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"museBubble"];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:self.tableView belowSubview:self.inputBar];
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.bannerHost.bottomAnchor constant:12.0],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.inputBar.topAnchor],
    ]];
}

#pragma mark - Keyboard

- (void)handleKeyboardChange:(NSNotification *)note {
    CGRect endFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat overlap = CGRectGetMaxY(self.view.bounds) - CGRectGetMinY([self.view convertRect:endFrame fromView:nil]);
    self.inputBottomC.constant = overlap > 0 ? -overlap : 0.0;
    [UIView animateWithDuration:0.25 animations:^{ [self.view layoutIfNeeded]; }];
}

#pragma mark - Actions

- (void)handleBackTap {
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self handleSendTap];
    return NO;
}

- (void)handleSendTap {
    NSString *text = self.textField.text;
    if ([text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length == 0) {
        return;
    }
    [self commitSend:text];
}

- (void)commitSend:(NSString *)text {
    NSString *stamp = [self formattedTimeText];

    [self.messages addObject:[AcapeSignalMessage textMessageWithId:[NSString stringWithFormat:@"u_%@", @(self.messages.count)] body:text fromViewer:YES timeText:stamp]];
    self.textField.text = @"";
    [self.tableView reloadData];
    [self scrollToBottom];

    NSArray<NSString *> *replies = @[
        AcapeRevealText(AcapeRevealTextKeyMuseReply1),
        AcapeRevealText(AcapeRevealTextKeyMuseReply2),
        AcapeRevealText(AcapeRevealTextKeyMuseReply3),
    ];
    NSString *reply = replies[self.replyCursor % replies.count];
    self.replyCursor += 1;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.messages addObject:[AcapeSignalMessage textMessageWithId:[NSString stringWithFormat:@"a_%@", @(self.messages.count)] body:reply fromViewer:NO timeText:stamp]];
        [self.tableView reloadData];
        [self scrollToBottom];
    });
}

- (void)scrollToBottom {
    if (self.messages.count == 0) { return; }
    [self.tableView layoutIfNeeded];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

#pragma mark - Table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"museBubble" forIndexPath:indexPath];
    cell.backgroundColor = UIColor.clearColor;
    for (UIView *sub in cell.contentView.subviews) { [sub removeFromSuperview]; }
    AcapeSignalMessage *message = self.messages[indexPath.row];
    BOOL viewer = message.fromViewer;

    UIImageView *avatar = [[UIImageView alloc] init];
    avatar.contentMode = UIViewContentModeScaleAspectFill;
    avatar.layer.cornerRadius = 20.0;
    avatar.clipsToBounds = YES;
    avatar.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:avatar];

    UIView *bubble = [[UIView alloc] init];
    bubble.layer.cornerRadius = 20.0;
    bubble.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:bubble];

    UILabel *body = [[UILabel alloc] init];
    body.text = message.body;
    body.numberOfLines = 0;
    body.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    body.translatesAutoresizingMaskIntoConstraints = NO;
    [bubble addSubview:body];

    UILabel *timeLabel = [[UILabel alloc] init];
    timeLabel.text = [self displayTimeForMessage:message];
    timeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    timeLabel.numberOfLines = 1;
    timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [bubble addSubview:timeLabel];

    if (viewer) {
        avatar.image = [[AcapeVaultStore shared] avatarImageForAssetName:[AcapeVaultStore shared].currentMemberProfile.avatarAssetName];
        bubble.backgroundColor = [AcapeAuroraBackdrop accentColor];
        body.textColor = UIColor.blackColor;
        timeLabel.textColor = [UIColor colorWithWhite:0.0 alpha:0.45];
        timeLabel.textAlignment = NSTextAlignmentRight;
    } else {
        avatar.image = [UIImage imageNamed:@"机器头像"];
        bubble.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        body.textColor = UIColor.whiteColor;
        timeLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.4];
        timeLabel.textAlignment = NSTextAlignmentLeft;
    }

    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray arrayWithArray:@[
        [avatar.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:6.0],
        [avatar.widthAnchor constraintEqualToConstant:40.0],
        [avatar.heightAnchor constraintEqualToConstant:40.0],
        [bubble.topAnchor constraintEqualToAnchor:avatar.topAnchor constant:47.0],
        [bubble.widthAnchor constraintLessThanOrEqualToConstant:kBubbleMaxWidth],
        [bubble.widthAnchor constraintGreaterThanOrEqualToConstant:kBubbleMinWidth],
        [bubble.widthAnchor constraintGreaterThanOrEqualToAnchor:timeLabel.widthAnchor constant:kBubblePadding * 2.0],
        [bubble.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-6.0],
        [body.topAnchor constraintEqualToAnchor:bubble.topAnchor constant:kBubblePadding],
        [body.leadingAnchor constraintEqualToAnchor:bubble.leadingAnchor constant:kBubblePadding],
        [body.trailingAnchor constraintEqualToAnchor:bubble.trailingAnchor constant:-kBubblePadding],
        [timeLabel.topAnchor constraintEqualToAnchor:body.bottomAnchor constant:8.0],
        [timeLabel.bottomAnchor constraintEqualToAnchor:bubble.bottomAnchor constant:-12.0],
    ]];

    if (viewer) {
        [constraints addObject:[timeLabel.trailingAnchor constraintEqualToAnchor:bubble.trailingAnchor constant:-16.0]];
        [constraints addObjectsFromArray:@[
            [avatar.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-kSideInset],
            [bubble.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-kSideInset],
        ]];
    } else {
        [constraints addObject:[timeLabel.leadingAnchor constraintEqualToAnchor:bubble.leadingAnchor constant:16.0]];
        [constraints addObjectsFromArray:@[
            [avatar.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:kSideInset],
            [bubble.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:kSideInset],
        ]];
    }

    [NSLayoutConstraint activateConstraints:constraints];
    return cell;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

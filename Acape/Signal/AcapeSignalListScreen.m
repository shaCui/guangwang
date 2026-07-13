#import "AcapeSignalListScreen.h"
#import "AcapeSignalThreadCell.h"
#import "AcapeSignalChatScreen.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeNavKit.h"
#import "AcapeRevealText.h"
#import "AcapeVaultStore.h"

static NSString * const kThreadCellReuseId = @"AcapeSignalThreadCell";

@interface AcapeSignalListScreen () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) AcapeAuroraBackdrop *backdrop;
@property (nonatomic, strong) UIButton *backControl;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<AcapeSignalThread *> *threads;
@end

@implementation AcapeSignalListScreen

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [AcapeAuroraBackdrop baseColor];
    [self buildBackdrop];
    [self buildHeader];
    [self buildTable];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.threads = [AcapeVaultStore shared].signalThreads;
    [self.tableView reloadData];
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
    self.titleLabel.text = AcapeRevealText(AcapeRevealTextKeySignalTitle);
    self.titleLabel.textColor = UIColor.whiteColor;
    self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.titleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.backControl.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:25.0],
        [self.backControl.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8.0],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.backControl.centerYAnchor],
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    ]];
}

- (void)buildTable {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = [AcapeSignalThreadCell rowHeight];
    self.tableView.contentInset = UIEdgeInsetsMake(14.0, 0.0, 24.0, 0.0);
    [self.tableView registerClass:AcapeSignalThreadCell.class forCellReuseIdentifier:kThreadCellReuseId];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.backControl.bottomAnchor constant:22.0],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];
}

#pragma mark - Actions

- (void)handleBackTap {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.threads.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AcapeSignalThreadCell *cell = [tableView dequeueReusableCellWithIdentifier:kThreadCellReuseId forIndexPath:indexPath];
    [cell configureWithThread:self.threads[indexPath.row]];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AcapeSignalThread *thread = self.threads[indexPath.row];
    [[AcapeVaultStore shared] markThreadRead:thread];
    AcapeSignalChatScreen *chatScreen = [[AcapeSignalChatScreen alloc] initWithThread:thread];
    [self.navigationController pushViewController:chatScreen animated:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

#import "AcapeCofferScreen.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeNavKit.h"
#import "AcapeRevealText.h"
#import "AcapeVaultStore.h"
#import "AcapeShelfBroker.h"
#import "AcapeShelfItem.h"

static CGFloat const kSideInset = 25.0;
static CGFloat const kCardGap = 13.0;
static CGFloat const kHeaderBarHeight = 44.0;
static CGFloat const kContentTopSpacing = 20.0;
static NSTimeInterval const kShelfVerifyDelay = 1.0;

@interface AcapeCofferScreen ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *balanceAmountLabel;
@property (nonatomic, strong) UIView *balanceCard;
@property (nonatomic, strong) UIView *headerBar;
@property (nonatomic, strong) UIView *advanceBlockingOverlay;
@property (nonatomic, strong) UIActivityIndicatorView *advanceSpinner;
@property (nonatomic, strong) UIView *toastView;
@property (nonatomic, assign) BOOL catalogReady;
@end

@implementation AcapeCofferScreen

- (NSArray<AcapeShelfItem *> *)catalogItems {
    return [AcapeShelfBroker shared].catalogItems;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [AcapeAuroraBackdrop baseColor];
    [[AcapeShelfBroker shared] startObserving];
    [self buildBackdrop];
    [self buildHeader];
    [self buildScroll];
    [self buildBalanceCard];
    [self buildPackageGrid];
    [self refreshBalance];
    [self.view bringSubviewToFront:self.headerBar];
    [self prepareShelfCatalog];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshBalance];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self hideAdvanceBlockingOverlay];
}

- (void)prepareShelfCatalog {
    [[AcapeShelfBroker shared] prepareCatalogWithCompletion:^(BOOL ready) {
        self.catalogReady = ready;
    }];
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
    UIView *headerBar = [[UIView alloc] init];
    headerBar.backgroundColor = UIColor.clearColor;
    headerBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:headerBar];

    UIButton *backControl = [AcapeNavKit backControlWithTarget:self action:@selector(handleBackTap)];
    backControl.translatesAutoresizingMaskIntoConstraints = NO;
    [headerBar addSubview:backControl];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = AcapeRevealText(AcapeRevealTextKeyCreditWalletTitle);
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

- (void)buildScroll {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentView];

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.headerBar.bottomAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],

        [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor],
    ]];
}

- (void)buildBalanceCard {
    self.balanceCard = [[UIView alloc] init];
    self.balanceCard.backgroundColor = UIColor.clearColor;
    self.balanceCard.clipsToBounds = NO;
    self.balanceCard.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.balanceCard];

    UIImageView *balanceBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"value背景"]];
    balanceBackground.contentMode = UIViewContentModeScaleAspectFill;
    balanceBackground.layer.cornerRadius = 20.0;
    balanceBackground.clipsToBounds = YES;
    balanceBackground.translatesAutoresizingMaskIntoConstraints = NO;
    [self.balanceCard addSubview:balanceBackground];

    UIImageView *valueMark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"value小图标"]];
    valueMark.contentMode = UIViewContentModeScaleAspectFit;
    valueMark.translatesAutoresizingMaskIntoConstraints = NO;
    [self.balanceCard addSubview:valueMark];

    UILabel *caption = [[UILabel alloc] init];
    caption.text = AcapeRevealText(AcapeRevealTextKeyCreditBalanceCaption);
    caption.textColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0];
    caption.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    caption.translatesAutoresizingMaskIntoConstraints = NO;
    [self.balanceCard addSubview:caption];

    self.balanceAmountLabel = [[UILabel alloc] init];
    self.balanceAmountLabel.textColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0];
    self.balanceAmountLabel.font = [UIFont systemFontOfSize:40 weight:UIFontWeightBold];
    self.balanceAmountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.balanceCard addSubview:self.balanceAmountLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.balanceCard.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:kContentTopSpacing],
        [self.balanceCard.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kSideInset],
        [self.balanceCard.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kSideInset],
        [self.balanceCard.heightAnchor constraintEqualToConstant:108.0],

        [balanceBackground.topAnchor constraintEqualToAnchor:self.balanceCard.topAnchor],
        [balanceBackground.leadingAnchor constraintEqualToAnchor:self.balanceCard.leadingAnchor],
        [balanceBackground.trailingAnchor constraintEqualToAnchor:self.balanceCard.trailingAnchor],
        [balanceBackground.bottomAnchor constraintEqualToAnchor:self.balanceCard.bottomAnchor],

        [valueMark.trailingAnchor constraintEqualToAnchor:self.balanceCard.trailingAnchor constant:-12.0],
        [valueMark.centerYAnchor constraintEqualToAnchor:self.balanceCard.centerYAnchor constant:-15.0],
        [valueMark.widthAnchor constraintEqualToConstant:110.0],
        [valueMark.heightAnchor constraintEqualToConstant:110.0],

        [caption.topAnchor constraintEqualToAnchor:self.balanceCard.topAnchor constant:20.0],
        [caption.leadingAnchor constraintEqualToAnchor:self.balanceCard.leadingAnchor constant:20.0],

        [self.balanceAmountLabel.topAnchor constraintEqualToAnchor:caption.bottomAnchor constant:2.0],
        [self.balanceAmountLabel.leadingAnchor constraintEqualToAnchor:self.balanceCard.leadingAnchor constant:20.0],
    ]];
}

- (void)buildPackageGrid {
    NSArray<AcapeShelfItem *> *catalogItems = self.catalogItems;
    UIStackView *columnStack = [[UIStackView alloc] init];
    columnStack.axis = UILayoutConstraintAxisVertical;
    columnStack.spacing = kCardGap;
    columnStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:columnStack];

    for (NSInteger row = 0; row < (NSInteger)ceil(catalogItems.count / 2.0); row++) {
        UIStackView *rowStack = [[UIStackView alloc] init];
        rowStack.axis = UILayoutConstraintAxisHorizontal;
        rowStack.spacing = kCardGap;
        rowStack.distribution = UIStackViewDistributionFillEqually;
        for (NSInteger col = 0; col < 2; col++) {
            NSInteger index = row * 2 + col;
            if (index < (NSInteger)catalogItems.count) {
                [rowStack addArrangedSubview:[self packageCardForItem:catalogItems[index]]];
            } else {
                UIView *spacer = [[UIView alloc] init];
                [rowStack addArrangedSubview:spacer];
            }
        }
        [columnStack addArrangedSubview:rowStack];
    }

    [NSLayoutConstraint activateConstraints:@[
        [columnStack.topAnchor constraintEqualToAnchor:self.balanceCard.bottomAnchor constant:20.0],
        [columnStack.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kSideInset],
        [columnStack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kSideInset],
        [columnStack.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-24.0],
    ]];
}

- (UIView *)packageCardForItem:(AcapeShelfItem *)item {
    UIButton *card = [UIButton buttonWithType:UIButtonTypeCustom];
    card.backgroundColor = [AcapeAuroraBackdrop cardColor];
    card.layer.cornerRadius = 16.0;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [card.heightAnchor constraintEqualToConstant:80.0].active = YES;

    UIImageView *coin = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"credit_coin_mark"]];
    coin.contentMode = UIViewContentModeScaleAspectFit;
    coin.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:coin];

    UILabel *creditsLabel = [[UILabel alloc] init];
    creditsLabel.text = [NSString stringWithFormat:@"%ld", (long)item.creditAmount];
    creditsLabel.textColor = UIColor.whiteColor;
    creditsLabel.numberOfLines = 1;
    creditsLabel.adjustsFontSizeToFitWidth = YES;
    creditsLabel.minimumScaleFactor = 0.75;
    creditsLabel.lineBreakMode = NSLineBreakByClipping;
    creditsLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    creditsLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    creditsLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *priceLabel = [[UILabel alloc] init];
    priceLabel.text = item.priceLabel;
    priceLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    priceLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    priceLabel.numberOfLines = 1;
    priceLabel.adjustsFontSizeToFitWidth = YES;
    priceLabel.minimumScaleFactor = 0.85;
    priceLabel.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *textStack = [[UIStackView alloc] initWithArrangedSubviews:@[creditsLabel, priceLabel]];
    textStack.axis = UILayoutConstraintAxisVertical;
    textStack.alignment = UIStackViewAlignmentFill;
    textStack.spacing = 4.0;
    textStack.userInteractionEnabled = NO;
    textStack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:textStack];

    __weak typeof(self) weakSelf = self;
    NSString *batchRef = item.batchRef;
    NSInteger credits = item.creditAmount;
    [card addAction:[UIAction actionWithHandler:^(UIAction *action) {
        [weakSelf handleAdvancePackageWithBatchRef:batchRef credits:credits];
    }] forControlEvents:UIControlEventTouchUpInside];

    [NSLayoutConstraint activateConstraints:@[
        [coin.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:12.0],
        [coin.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
        [coin.widthAnchor constraintEqualToConstant:52.0],
        [coin.heightAnchor constraintEqualToConstant:52.0],

        [textStack.leadingAnchor constraintEqualToAnchor:coin.trailingAnchor constant:8.0],
        [textStack.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
        [textStack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-10.0],
    ]];
    return card;
}

- (void)refreshBalance {
    self.balanceAmountLabel.text = [NSString stringWithFormat:@"%ld", (long)[AcapeVaultStore shared].creditBalance];
}

#pragma mark - Actions

- (void)handleBackTap {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleAdvancePackageWithBatchRef:(NSString *)batchRef credits:(NSInteger)credits {
    if (![[AcapeShelfBroker shared] canAdvanceShelf]) {
        [self presentShelfNotice:AcapeRevealText(AcapeRevealTextKeyCreditShelfUnavailable)];
        return;
    }
    [self presentAdvanceConfirmForBatchRef:batchRef credits:credits];
}

- (void)presentAdvanceConfirmForBatchRef:(NSString *)batchRef credits:(NSInteger)credits {
    NSString *message = [NSString stringWithFormat:@"%@ (+%ld)", AcapeRevealText(AcapeRevealTextKeyCreditRechargeConfirm), (long)credits];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:AcapeRevealText(AcapeRevealTextKeyHubCancel) style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:AcapeRevealText(AcapeRevealTextKeyBondSureAction) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf beginShelfAdvanceWithBatchRef:batchRef];
        });
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)beginShelfAdvanceWithBatchRef:(NSString *)batchRef {
    [self showAdvanceBlockingOverlay];
    __weak typeof(self) weakSelf = self;
    void (^startShelfAdvance)(void) = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (![[AcapeShelfBroker shared] isBatchRefReady:batchRef]) {
            [strongSelf hideAdvanceBlockingOverlay];
            [strongSelf presentShelfNotice:AcapeRevealText(AcapeRevealTextKeyCreditShelfUnavailable)];
            return;
        }
        [[AcapeShelfBroker shared] advanceWithBatchRef:batchRef completion:^(BOOL succeeded, AcapeShelfAdvanceIssue issue) {
            __strong typeof(weakSelf) innerSelf = weakSelf;
            if (!innerSelf) {
                return;
            }
            if (succeeded) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kShelfVerifyDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) doneSelf = weakSelf;
                    if (!doneSelf) {
                        return;
                    }
                    [doneSelf hideAdvanceBlockingOverlay];
                    [doneSelf refreshBalance];
                    [doneSelf showToastWithText:AcapeRevealText(AcapeRevealTextKeyCreditRechargeDone) completion:nil];
                });
                return;
            }
            [innerSelf hideAdvanceBlockingOverlay];
            if (issue == AcapeShelfAdvanceIssueCancelled) {
                return;
            }
            NSString *notice = AcapeRevealText(AcapeRevealTextKeyCreditShelfFailed);
            if (issue == AcapeShelfAdvanceIssueUnavailable) {
                notice = AcapeRevealText(AcapeRevealTextKeyCreditShelfUnavailable);
            } else if (issue == AcapeShelfAdvanceIssueCancelled) {
                notice = AcapeRevealText(AcapeRevealTextKeyCreditShelfCancelled);
            }
            [innerSelf presentShelfNotice:notice];
        }];
    };

    if ([[AcapeShelfBroker shared] isBatchRefReady:batchRef]) {
        startShelfAdvance();
        return;
    }
    [[AcapeShelfBroker shared] prepareCatalogWithCompletion:^(BOOL ready) {
        startShelfAdvance();
    }];
}

- (void)showAdvanceBlockingOverlay {
    [self hideAdvanceBlockingOverlay];

    UIView *overlay = [[UIView alloc] init];
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.35];
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:overlay];

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.color = UIColor.whiteColor;
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [overlay addSubview:spinner];

    [NSLayoutConstraint activateConstraints:@[
        [overlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [overlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [overlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [overlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [spinner.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [spinner.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
    ]];

    [spinner startAnimating];
    self.advanceBlockingOverlay = overlay;
    self.advanceSpinner = spinner;
}

- (void)hideAdvanceBlockingOverlay {
    [self.advanceSpinner stopAnimating];
    self.advanceSpinner = nil;
    [self.advanceBlockingOverlay removeFromSuperview];
    self.advanceBlockingOverlay = nil;
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
    [self.view bringSubviewToFront:pill];

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

- (void)presentShelfNotice:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:AcapeRevealText(AcapeRevealTextKeyHubConfirm) style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

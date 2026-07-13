#import "AcapeReelUploadScreen.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeNavKit.h"
#import "AcapeRevealText.h"
#import "AcapeVaultStore.h"
#import "UIViewController+AcapeDismissKeyboard.h"

static CGFloat const kSideInset = 25.0;
static NSInteger const kMaxChars = 200;

@interface AcapeReelUploadScreen () <UITextViewDelegate>
@property (nonatomic, strong) UITextView *descriptionView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UILabel *counterLabel;
@property (nonatomic, strong) UIButton *thumbButton;
@property (nonatomic, strong) UIImageView *thumbImageView;
@property (nonatomic, strong) UIImageView *thumbBadge;
@property (nonatomic, assign) BOOL clipSelected;
@property (nonatomic, strong) UIButton *uploadButton;
@property (nonatomic, strong) CAGradientLayer *uploadGradient;
@property (nonatomic, weak) UIButton *headerRef;
@end

@implementation AcapeReelUploadScreen

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [AcapeAuroraBackdrop baseColor];
    [self buildBackdrop];
    [self buildHeader];
    [self buildForm];
    [self acape_enableDismissKeyboardOnBackgroundTap];
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
    UIButton *backControl = [AcapeNavKit backControlWithTarget:self action:@selector(handleBackTap)];
    backControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:backControl];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = AcapeRevealText(AcapeRevealTextKeyReelPublishTitle);
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:titleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [backControl.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:kSideInset],
        [backControl.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8.0],
        [titleLabel.centerYAnchor constraintEqualToAnchor:backControl.centerYAnchor],
        [titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    ]];
    self.headerRef = backControl;
}

- (void)buildForm {
    UIView *descBox = [[UIView alloc] init];
    descBox.backgroundColor = [AcapeAuroraBackdrop cardColor];
    descBox.layer.cornerRadius = 16.0;
    descBox.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:descBox];

    self.descriptionView = [[UITextView alloc] init];
    self.descriptionView.backgroundColor = UIColor.clearColor;
    self.descriptionView.textColor = UIColor.whiteColor;
    self.descriptionView.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.descriptionView.tintColor = [AcapeAuroraBackdrop accentColor];
    self.descriptionView.textContainerInset = UIEdgeInsetsMake(14.0, 12.0, 30.0, 12.0);
    self.descriptionView.delegate = self;
    self.descriptionView.translatesAutoresizingMaskIntoConstraints = NO;
    [descBox addSubview:self.descriptionView];

    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.text = AcapeRevealText(AcapeRevealTextKeyReelUploadPlaceholder);
    self.placeholderLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    self.placeholderLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [descBox addSubview:self.placeholderLabel];

    self.counterLabel = [[UILabel alloc] init];
    self.counterLabel.text = [NSString stringWithFormat:@"0/%ld", (long)kMaxChars];
    self.counterLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    self.counterLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightRegular];
    self.counterLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [descBox addSubview:self.counterLabel];

    self.thumbButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.thumbButton.backgroundColor = [AcapeAuroraBackdrop cardColor];
    self.thumbButton.layer.cornerRadius = 12.0;
    self.thumbButton.clipsToBounds = YES;
    self.thumbButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.thumbButton addTarget:self action:@selector(handleThumbTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.thumbButton];

    self.thumbImageView = [[UIImageView alloc] init];
    self.thumbImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.thumbImageView.clipsToBounds = YES;
    self.thumbImageView.hidden = YES;
    self.thumbImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.thumbButton addSubview:self.thumbImageView];

    UIImageView *plusIcon = [[UIImageView alloc] init];
    UIImageConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:26 weight:UIImageSymbolWeightRegular];
    plusIcon.image = [UIImage systemImageNamed:@"plus" withConfiguration:cfg];
    plusIcon.tintColor = [UIColor colorWithWhite:1.0 alpha:0.4];
    plusIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [self.thumbButton addSubview:plusIcon];

    self.uploadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.uploadButton setTitle:AcapeRevealText(AcapeRevealTextKeyReelUploadAction) forState:UIControlStateNormal];
    [self.uploadButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    self.uploadButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    self.uploadButton.layer.cornerRadius = 26.0;
    self.uploadButton.clipsToBounds = YES;
    self.uploadButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.uploadButton addTarget:self action:@selector(handleUpload) forControlEvents:UIControlEventTouchUpInside];
    self.uploadGradient = [CAGradientLayer layer];
    self.uploadGradient.colors = @[
        (id)[UIColor colorWithRed:0.804 green:1.0 blue:0.780 alpha:1.0].CGColor,
        (id)[AcapeAuroraBackdrop accentColor].CGColor,
    ];
    self.uploadGradient.startPoint = CGPointMake(0.5, 0.0);
    self.uploadGradient.endPoint = CGPointMake(0.5, 1.0);
    [self.uploadButton.layer insertSublayer:self.uploadGradient atIndex:0];
    [self.view addSubview:self.uploadButton];

    [NSLayoutConstraint activateConstraints:@[
        [descBox.topAnchor constraintEqualToAnchor:self.headerRef.bottomAnchor constant:28.0],
        [descBox.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:kSideInset],
        [descBox.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-kSideInset],
        [descBox.heightAnchor constraintEqualToConstant:150.0],

        [self.descriptionView.topAnchor constraintEqualToAnchor:descBox.topAnchor],
        [self.descriptionView.leadingAnchor constraintEqualToAnchor:descBox.leadingAnchor],
        [self.descriptionView.trailingAnchor constraintEqualToAnchor:descBox.trailingAnchor],
        [self.descriptionView.bottomAnchor constraintEqualToAnchor:descBox.bottomAnchor],

        [self.placeholderLabel.topAnchor constraintEqualToAnchor:descBox.topAnchor constant:14.0],
        [self.placeholderLabel.leadingAnchor constraintEqualToAnchor:descBox.leadingAnchor constant:16.0],

        [self.counterLabel.bottomAnchor constraintEqualToAnchor:descBox.bottomAnchor constant:-10.0],
        [self.counterLabel.leadingAnchor constraintEqualToAnchor:descBox.leadingAnchor constant:16.0],

        [self.thumbButton.topAnchor constraintEqualToAnchor:descBox.bottomAnchor constant:20.0],
        [self.thumbButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:kSideInset],
        [self.thumbButton.widthAnchor constraintEqualToConstant:106.0],
        [self.thumbButton.heightAnchor constraintEqualToConstant:159.0],

        [self.thumbImageView.topAnchor constraintEqualToAnchor:self.thumbButton.topAnchor],
        [self.thumbImageView.leadingAnchor constraintEqualToAnchor:self.thumbButton.leadingAnchor],
        [self.thumbImageView.trailingAnchor constraintEqualToAnchor:self.thumbButton.trailingAnchor],
        [self.thumbImageView.bottomAnchor constraintEqualToAnchor:self.thumbButton.bottomAnchor],

        [plusIcon.centerXAnchor constraintEqualToAnchor:self.thumbButton.centerXAnchor],
        [plusIcon.centerYAnchor constraintEqualToAnchor:self.thumbButton.centerYAnchor],

        [self.uploadButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:kSideInset],
        [self.uploadButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-kSideInset],
        [self.uploadButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-24.0],
        [self.uploadButton.heightAnchor constraintEqualToConstant:52.0],
    ]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.uploadGradient.frame = self.uploadButton.bounds;
}

#pragma mark - TextView

- (void)textViewDidChange:(UITextView *)textView {
    if (textView.text.length > kMaxChars) {
        textView.text = [textView.text substringToIndex:kMaxChars];
    }
    self.placeholderLabel.hidden = textView.text.length > 0;
    self.counterLabel.text = [NSString stringWithFormat:@"%ld/%ld", (long)textView.text.length, (long)kMaxChars];
}

#pragma mark - Actions

- (void)handleBackTap {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleThumbTap {
    self.clipSelected = !self.clipSelected;
    if (self.clipSelected) {
        self.thumbImageView.hidden = NO;
        self.thumbImageView.image = [UIImage imageNamed:@"harbor_entry_cover_1"];
    } else {
        self.thumbImageView.hidden = YES;
    }
}

- (void)handleUpload {
    [self.view endEditing:YES];
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.color = UIColor.whiteColor;
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:spinner];
    [NSLayoutConstraint activateConstraints:@[
        [spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [spinner.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];
    [spinner startAnimating];
    self.view.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [spinner stopAnimating];
        [spinner removeFromSuperview];
        self.view.userInteractionEnabled = YES;
        UIAlertController *done = [UIAlertController alertControllerWithTitle:nil
                                                                     message:AcapeRevealText(AcapeRevealTextKeyReelUploadDone)
                                                              preferredStyle:UIAlertControllerStyleAlert];
        [done addAction:[UIAlertAction actionWithTitle:AcapeRevealText(AcapeRevealTextKeyHubConfirm) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[AcapeVaultStore shared] appendPublishedEntryWithCaption:self.descriptionView.text
                                                  coverImageAssetName:(self.clipSelected ? @"harbor_entry_cover_1" : nil)
                                                     localClipFileName:nil];
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:done animated:YES completion:nil];
    });
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

#import "AcapeChamberCreateScreen.h"
#import "AcapeRevealText.h"
#import "AcapeVaultStore.h"
#import "AcapeAuroraBackdrop.h"
#import "UIViewController+AcapeDismissKeyboard.h"
@import AVFoundation;
@import Photos;

static CGFloat const kSideInset = 25.0;
static CGFloat const kSheetCornerRadius = 40.0;
static CGFloat const kCoverSlotSize = 100.0;
static NSString * const kAcapeLocalChamberCoverAssetName = @"chamber_local_cover";

@interface AcapeChamberCreateFillView : UIView
@end

@implementation AcapeChamberCreateFillView

+ (Class)layerClass {
    return CAGradientLayer.class;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
        gradientLayer.colors = @[
            (id)[UIColor colorWithRed:205.0 / 255.0 green:1.0 blue:199.0 / 255.0 alpha:1.0].CGColor,
            (id)[AcapeAuroraBackdrop accentColor].CGColor,
        ];
        gradientLayer.startPoint = CGPointMake(0.0, 0.5);
        gradientLayer.endPoint = CGPointMake(1.0, 0.5);
        self.layer.cornerRadius = 16.0;
        self.clipsToBounds = YES;
    }
    return self;
}

@end

@interface AcapeChamberCreateScreen () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate>
@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) UIButton *backdropControl;
@property (nonatomic, strong) UIView *sheetView;
@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) UIView *selectedCoverSlot;
@property (nonatomic, strong) UIImageView *selectedCoverView;
@property (nonatomic, strong) UIButton *removeCoverControl;
@property (nonatomic, strong) UIButton *addCoverControl;
@property (nonatomic, strong) AcapeChamberCreateFillView *createFillView;
@property (nonatomic, strong) UIButton *createButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadingSpinner;
@property (nonatomic, strong) NSLayoutConstraint *sheetHeightC;
@property (nonatomic, strong) UIImage *pendingCoverImage;
@property (nonatomic, assign) BOOL didRevealSheet;
@property (nonatomic, assign) BOOL isCreating;
@end

@implementation AcapeChamberCreateScreen

- (instancetype)init {
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    [self buildDimBackdrop];
    [self buildSheet];
    [self acape_enableDismissKeyboardOnBackgroundTap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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

#pragma mark - Layout

- (void)buildDimBackdrop {
    self.dimView = [[UIView alloc] init];
    self.dimView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    self.dimView.userInteractionEnabled = NO;
    self.dimView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.dimView];

    self.backdropControl = [UIButton buttonWithType:UIButtonTypeCustom];
    self.backdropControl.backgroundColor = UIColor.clearColor;
    self.backdropControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backdropControl addTarget:self action:@selector(handleBackdropTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backdropControl];

    [NSLayoutConstraint activateConstraints:@[
        [self.dimView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.dimView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.dimView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.dimView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.backdropControl.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.backdropControl.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.backdropControl.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.backdropControl.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)buildSheet {
    self.sheetView = [[UIView alloc] init];
    self.sheetView.backgroundColor = UIColor.clearColor;
    self.sheetView.clipsToBounds = NO;
    self.sheetView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.sheetView];

    UIView *cardSurface = [[UIView alloc] init];
    cardSurface.backgroundColor = UIColor.clearColor;
    cardSurface.layer.cornerRadius = kSheetCornerRadius;
    cardSurface.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    cardSurface.clipsToBounds = YES;
    cardSurface.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sheetView addSubview:cardSurface];

    UIView *whiteBase = [[UIView alloc] init];
    whiteBase.backgroundColor = UIColor.whiteColor;
    whiteBase.translatesAutoresizingMaskIntoConstraints = NO;
    [cardSurface addSubview:whiteBase];

    UIImageView *panelBackdrop = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"创建k歌房背景"]];
    panelBackdrop.contentMode = UIViewContentModeScaleToFill;
    panelBackdrop.translatesAutoresizingMaskIntoConstraints = NO;
    [cardSurface addSubview:panelBackdrop];

    UIImageView *cornerMark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"创建k歌房右上角"]];
    cornerMark.contentMode = UIViewContentModeScaleAspectFit;
    cornerMark.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sheetView addSubview:cornerMark];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = AcapeRevealText(AcapeRevealTextKeyChamberCreateTitle);
    titleLabel.textColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0];
    titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sheetView addSubview:titleLabel];

    UIView *nameSection = [self sectionLabelWithText:AcapeRevealText(AcapeRevealTextKeyChamberNameField)];
    nameSection.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sheetView addSubview:nameSection];

    UIView *nameFieldBox = [[UIView alloc] init];
    nameFieldBox.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    nameFieldBox.layer.cornerRadius = 16.0;
    nameFieldBox.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sheetView addSubview:nameFieldBox];

    self.nameField = [[UITextField alloc] init];
    self.nameField.delegate = self;
    self.nameField.textColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0];
    self.nameField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.nameField.tintColor = [AcapeAuroraBackdrop accentColor];
    self.nameField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:AcapeRevealText(AcapeRevealTextKeyChamberNamePlaceholder)
                                                                            attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.0 alpha:0.35]}];
    self.nameField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nameField addTarget:self action:@selector(handleNameFieldChange) forControlEvents:UIControlEventEditingChanged];
    [nameFieldBox addSubview:self.nameField];

    UIView *coverSection = [self sectionLabelWithText:AcapeRevealText(AcapeRevealTextKeyChamberCoverField)];
    coverSection.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sheetView addSubview:coverSection];

    self.selectedCoverSlot = [[UIView alloc] init];
    self.selectedCoverSlot.hidden = YES;
    self.selectedCoverSlot.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sheetView addSubview:self.selectedCoverSlot];

    self.selectedCoverView = [[UIImageView alloc] init];
    self.selectedCoverView.contentMode = UIViewContentModeScaleAspectFill;
    self.selectedCoverView.layer.cornerRadius = 16.0;
    self.selectedCoverView.clipsToBounds = YES;
    self.selectedCoverView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.selectedCoverSlot addSubview:self.selectedCoverView];

    self.removeCoverControl = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.removeCoverControl setImage:[UIImage imageNamed:@"创建k歌房删除封面"] forState:UIControlStateNormal];
    self.removeCoverControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.removeCoverControl addTarget:self action:@selector(handleRemoveCoverTap) forControlEvents:UIControlEventTouchUpInside];
    [self.selectedCoverSlot addSubview:self.removeCoverControl];

    self.addCoverControl = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addCoverControl.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    self.addCoverControl.layer.cornerRadius = 16.0;
    self.addCoverControl.clipsToBounds = YES;
    self.addCoverControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.addCoverControl addTarget:self action:@selector(handleAddCoverTap) forControlEvents:UIControlEventTouchUpInside];
    [self.sheetView addSubview:self.addCoverControl];

    UIImageView *addMark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"创建k歌房加号"]];
    addMark.contentMode = UIViewContentModeScaleAspectFit;
    addMark.userInteractionEnabled = NO;
    addMark.translatesAutoresizingMaskIntoConstraints = NO;
    [self.addCoverControl addSubview:addMark];

    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setTitle:AcapeRevealText(AcapeRevealTextKeyHubCancel) forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0] forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    cancelButton.backgroundColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:0.1];
    cancelButton.layer.cornerRadius = 16.0;
    cancelButton.clipsToBounds = YES;
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton addTarget:self action:@selector(handleCancelTap) forControlEvents:UIControlEventTouchUpInside];
    [self.sheetView addSubview:cancelButton];

    self.createFillView = [[AcapeChamberCreateFillView alloc] init];
    self.createFillView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sheetView addSubview:self.createFillView];

    self.createButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.createButton setTitle:AcapeRevealText(AcapeRevealTextKeyChamberCreateAction) forState:UIControlStateNormal];
    [self.createButton setTitleColor:[UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0] forState:UIControlStateNormal];
    self.createButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    self.createButton.backgroundColor = UIColor.clearColor;
    self.createButton.enabled = NO;
    self.createButton.alpha = 0.45;
    self.createButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.createButton addTarget:self action:@selector(handleCreateTap) forControlEvents:UIControlEventTouchUpInside];
    [self.createFillView addSubview:self.createButton];

    self.loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingSpinner.color = UIColor.whiteColor;
    self.loadingSpinner.hidesWhenStopped = YES;
    self.loadingSpinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.loadingSpinner];

    CGFloat sheetHeight = MIN(UIScreen.mainScreen.bounds.size.height * 0.68, 560.0);
    self.sheetHeightC = [self.sheetView.heightAnchor constraintEqualToConstant:sheetHeight];

    static CGFloat const kCornerMarkSize = 148.0;

    [NSLayoutConstraint activateConstraints:@[
        [self.sheetView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.sheetView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.sheetView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        self.sheetHeightC,

        [cardSurface.topAnchor constraintEqualToAnchor:self.sheetView.topAnchor],
        [cardSurface.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor],
        [cardSurface.trailingAnchor constraintEqualToAnchor:self.sheetView.trailingAnchor],
        [cardSurface.bottomAnchor constraintEqualToAnchor:self.sheetView.bottomAnchor],

        [whiteBase.topAnchor constraintEqualToAnchor:cardSurface.topAnchor],
        [whiteBase.leadingAnchor constraintEqualToAnchor:cardSurface.leadingAnchor],
        [whiteBase.trailingAnchor constraintEqualToAnchor:cardSurface.trailingAnchor],
        [whiteBase.bottomAnchor constraintEqualToAnchor:cardSurface.bottomAnchor],

        [panelBackdrop.topAnchor constraintEqualToAnchor:cardSurface.topAnchor],
        [panelBackdrop.leadingAnchor constraintEqualToAnchor:cardSurface.leadingAnchor],
        [panelBackdrop.trailingAnchor constraintEqualToAnchor:cardSurface.trailingAnchor],
        [panelBackdrop.bottomAnchor constraintEqualToAnchor:cardSurface.bottomAnchor],

        [cornerMark.topAnchor constraintEqualToAnchor:self.sheetView.topAnchor constant:-44.0],
        [cornerMark.trailingAnchor constraintEqualToAnchor:self.sheetView.trailingAnchor constant:-4.0],
        [cornerMark.widthAnchor constraintEqualToConstant:kCornerMarkSize],
        [cornerMark.heightAnchor constraintEqualToConstant:kCornerMarkSize],

        [titleLabel.topAnchor constraintEqualToAnchor:self.sheetView.topAnchor constant:32.0],
        [titleLabel.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor constant:kSideInset],
        [titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:cornerMark.leadingAnchor constant:-8.0],

        [nameSection.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:28.0],
        [nameSection.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor constant:kSideInset],

        [nameFieldBox.topAnchor constraintEqualToAnchor:nameSection.bottomAnchor constant:10.0],
        [nameFieldBox.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor constant:kSideInset],
        [nameFieldBox.trailingAnchor constraintEqualToAnchor:self.sheetView.trailingAnchor constant:-kSideInset],
        [nameFieldBox.heightAnchor constraintEqualToConstant:52.0],

        [self.nameField.leadingAnchor constraintEqualToAnchor:nameFieldBox.leadingAnchor constant:16.0],
        [self.nameField.trailingAnchor constraintEqualToAnchor:nameFieldBox.trailingAnchor constant:-16.0],
        [self.nameField.topAnchor constraintEqualToAnchor:nameFieldBox.topAnchor],
        [self.nameField.bottomAnchor constraintEqualToAnchor:nameFieldBox.bottomAnchor],

        [coverSection.topAnchor constraintEqualToAnchor:nameFieldBox.bottomAnchor constant:24.0],
        [coverSection.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor constant:kSideInset],

        [self.selectedCoverSlot.topAnchor constraintEqualToAnchor:coverSection.bottomAnchor constant:12.0],
        [self.selectedCoverSlot.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor constant:kSideInset],
        [self.selectedCoverSlot.widthAnchor constraintEqualToConstant:kCoverSlotSize],
        [self.selectedCoverSlot.heightAnchor constraintEqualToConstant:kCoverSlotSize],

        [self.selectedCoverView.topAnchor constraintEqualToAnchor:self.selectedCoverSlot.topAnchor],
        [self.selectedCoverView.leadingAnchor constraintEqualToAnchor:self.selectedCoverSlot.leadingAnchor],
        [self.selectedCoverView.trailingAnchor constraintEqualToAnchor:self.selectedCoverSlot.trailingAnchor],
        [self.selectedCoverView.bottomAnchor constraintEqualToAnchor:self.selectedCoverSlot.bottomAnchor],

        [self.removeCoverControl.topAnchor constraintEqualToAnchor:self.selectedCoverSlot.topAnchor constant:-6.0],
        [self.removeCoverControl.trailingAnchor constraintEqualToAnchor:self.selectedCoverSlot.trailingAnchor constant:6.0],
        [self.removeCoverControl.widthAnchor constraintEqualToConstant:24.0],
        [self.removeCoverControl.heightAnchor constraintEqualToConstant:24.0],

        [self.addCoverControl.topAnchor constraintEqualToAnchor:coverSection.bottomAnchor constant:12.0],
        [self.addCoverControl.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor constant:kSideInset],
        [self.addCoverControl.widthAnchor constraintEqualToConstant:kCoverSlotSize],
        [self.addCoverControl.heightAnchor constraintEqualToConstant:kCoverSlotSize],

        [addMark.centerXAnchor constraintEqualToAnchor:self.addCoverControl.centerXAnchor],
        [addMark.centerYAnchor constraintEqualToAnchor:self.addCoverControl.centerYAnchor],
        [addMark.widthAnchor constraintEqualToConstant:36.0],
        [addMark.heightAnchor constraintEqualToConstant:36.0],

        [cancelButton.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor constant:kSideInset],
        [cancelButton.bottomAnchor constraintEqualToAnchor:self.sheetView.safeAreaLayoutGuide.bottomAnchor constant:-20.0],
        [cancelButton.heightAnchor constraintEqualToConstant:52.0],

        [self.createFillView.trailingAnchor constraintEqualToAnchor:self.sheetView.trailingAnchor constant:-kSideInset],
        [self.createFillView.centerYAnchor constraintEqualToAnchor:cancelButton.centerYAnchor],
        [self.createFillView.heightAnchor constraintEqualToAnchor:cancelButton.heightAnchor],
        [self.createFillView.leadingAnchor constraintEqualToAnchor:cancelButton.trailingAnchor constant:12.0],
        [self.createFillView.widthAnchor constraintEqualToAnchor:cancelButton.widthAnchor],

        [self.createButton.topAnchor constraintEqualToAnchor:self.createFillView.topAnchor],
        [self.createButton.leadingAnchor constraintEqualToAnchor:self.createFillView.leadingAnchor],
        [self.createButton.trailingAnchor constraintEqualToAnchor:self.createFillView.trailingAnchor],
        [self.createButton.bottomAnchor constraintEqualToAnchor:self.createFillView.bottomAnchor],

        [self.loadingSpinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingSpinner.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];
}

- (UIView *)sectionLabelWithText:(NSString *)text {
    UIView *container = [[UIView alloc] init];

    UIView *accentBar = [[UIView alloc] init];
    accentBar.backgroundColor = [AcapeAuroraBackdrop accentColor];
    accentBar.layer.cornerRadius = 2.0;
    accentBar.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:accentBar];

    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.textColor = [UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0];
    label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [accentBar.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [accentBar.centerYAnchor constraintEqualToAnchor:container.centerYAnchor],
        [accentBar.widthAnchor constraintEqualToConstant:4.0],
        [accentBar.heightAnchor constraintEqualToConstant:14.0],

        [label.leadingAnchor constraintEqualToAnchor:accentBar.trailingAnchor constant:8.0],
        [label.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [label.topAnchor constraintEqualToAnchor:container.topAnchor],
        [label.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
    ]];
    return container;
}

#pragma mark - Cover State

- (void)refreshCoverLayout {
    BOOL hasCover = self.pendingCoverImage != nil;
    self.selectedCoverSlot.hidden = !hasCover;
    self.addCoverControl.hidden = hasCover;
    self.selectedCoverView.image = self.pendingCoverImage;
}

#pragma mark - Actions

- (void)handleBackdropTap {
    [self dismissSheetAnimated];
}

- (void)handleCancelTap {
    [self dismissSheetAnimated];
}

- (void)handleNameFieldChange {
    NSString *trimmed = [self.nameField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    BOOL enabled = trimmed.length > 0;
    self.createButton.enabled = enabled;
    self.createButton.alpha = enabled ? 1.0 : 0.45;
}

- (void)handleAddCoverTap {
    [self.view endEditing:YES];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Photo Library" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self requestPhotoAccessThenPresentCoverPicker];
        }]];
    }
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self requestCameraAccessThenPresentCoverPicker];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:AcapeRevealText(AcapeRevealTextKeyHubCancel) style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = self.addCoverControl;
    sheet.popoverPresentationController.sourceRect = self.addCoverControl.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)requestCameraAccessThenPresentCoverPicker {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        [self presentCoverPickerWithSource:UIImagePickerControllerSourceTypeCamera];
        return;
    }
    if (status == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    [self presentCoverPickerWithSource:UIImagePickerControllerSourceTypeCamera];
                } else {
                    [self showCoverAccessAlertWithMessage:@"Camera permission is required."];
                }
            });
        }];
        return;
    }
    [self showCoverAccessAlertWithMessage:@"Camera permission is required."];
}

- (void)requestPhotoAccessThenPresentCoverPicker {
    if (@available(iOS 14.0, *)) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
        if (status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited) {
            [self presentCoverPickerWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
            return;
        }
        if (status == PHAuthorizationStatusNotDetermined) {
            [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus requestStatus) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (requestStatus == PHAuthorizationStatusAuthorized || requestStatus == PHAuthorizationStatusLimited) {
                        [self presentCoverPickerWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
                    } else {
                        [self showCoverAccessAlertWithMessage:@"Photo library permission is required."];
                    }
                });
            }];
            return;
        }
    } else {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusAuthorized) {
            [self presentCoverPickerWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
            return;
        }
        if (status == PHAuthorizationStatusNotDetermined) {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus requestStatus) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (requestStatus == PHAuthorizationStatusAuthorized) {
                        [self presentCoverPickerWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
                    } else {
                        [self showCoverAccessAlertWithMessage:@"Photo library permission is required."];
                    }
                });
            }];
            return;
        }
    }
    [self showCoverAccessAlertWithMessage:@"Photo library permission is required."];
}

- (void)presentCoverPickerWithSource:(UIImagePickerControllerSourceType)sourceType {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.allowsEditing = YES;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)showCoverAccessAlertWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:AcapeRevealText(AcapeRevealTextKeyHubCancel) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)handleRemoveCoverTap {
    self.pendingCoverImage = nil;
    [self refreshCoverLayout];
}

- (void)handleCreateTap {
    if (self.isCreating) {
        return;
    }
    [self.view endEditing:YES];
    NSString *roomName = [self.nameField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (roomName.length == 0) {
        return;
    }

    self.isCreating = YES;
    [self.view bringSubviewToFront:self.loadingSpinner];
    [self.loadingSpinner startAnimating];
    self.sheetView.userInteractionEnabled = NO;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        AcapeVaultStore *store = [AcapeVaultStore shared];
        NSString *coverAssetName = self.pendingCoverImage ? kAcapeLocalChamberCoverAssetName : nil;
        AcapeChamberRoom *room = [store createChamberRoomWithName:roomName coverAssetName:coverAssetName];
        if (self.pendingCoverImage) {
            [store persistChamberCoverImage:self.pendingCoverImage forRoomId:room.roomId];
        }

        [self.loadingSpinner stopAnimating];
        self.sheetView.userInteractionEnabled = YES;
        self.isCreating = NO;

        void (^handler)(AcapeChamberRoom *) = self.roomCreatedHandler;
        [self dismissSheetAnimatedWithCompletion:^{
            if (handler) {
                handler(room);
            }
        }];
    });
}

- (void)dismissSheetAnimated {
    [self dismissSheetAnimatedWithCompletion:nil];
}

- (void)dismissSheetAnimatedWithCompletion:(void (^ _Nullable)(void))completion {
    [self.view endEditing:YES];
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:0.22
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.sheetView.transform = [self hiddenSheetTransform];
        self.dimView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:completion];
    }];
}

- (CGAffineTransform)hiddenSheetTransform {
    CGFloat distance = CGRectGetHeight(self.sheetView.bounds) + self.view.safeAreaInsets.bottom;
    if (distance <= 0.0) {
        distance = UIScreen.mainScreen.bounds.size.height;
    }
    return CGAffineTransformMakeTranslation(0.0, distance);
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    if (image) {
        self.pendingCoverImage = image;
        [self refreshCoverLayout];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDarkContent;
}

@end

#import "AcapeMemberDetailScreen.h"
#import "AcapeRevealText.h"
#import "AcapeVaultStore.h"
#import "AcapeMemberProfile.h"
#import "AcapeNavKit.h"
#import "AcapeAuthFormKit.h"
#import "AcapePrimaryActionButton.h"
#import "AcapeAppNavigator.h"
#import "UIViewController+AcapeDismissKeyboard.h"
@import AVFoundation;
@import Photos;

static NSString * const kAcapeLocalPortraitAssetName = @"member_local_portrait";

@interface AcapeGenderChoiceButton : UIButton
@property (nonatomic, strong) CAGradientLayer *fillGradient;
- (void)applyChosen:(BOOL)chosen;
@end

@implementation AcapeGenderChoiceButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _fillGradient = [CAGradientLayer layer];
        _fillGradient.colors = @[
            (__bridge id)[UIColor colorWithRed:0.75 green:1.00 blue:0.77 alpha:1.0].CGColor,
            (__bridge id)[UIColor colorWithRed:0.25 green:0.91 blue:0.88 alpha:1.0].CGColor,
        ];
        _fillGradient.startPoint = CGPointMake(0.0, 0.5);
        _fillGradient.endPoint = CGPointMake(1.0, 0.5);
        _fillGradient.hidden = YES;
        [self.layer insertSublayer:_fillGradient atIndex:0];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.fillGradient.frame = self.bounds;
    self.fillGradient.cornerRadius = self.layer.cornerRadius;
}

- (void)applyChosen:(BOOL)chosen {
    self.fillGradient.hidden = !chosen;
    self.backgroundColor = chosen ? UIColor.clearColor : UIColor.blackColor;
    self.layer.borderWidth = 0.0;
    [self setTitleColor:(chosen ? UIColor.blackColor : [UIColor colorWithWhite:1.0 alpha:0.58]) forState:UIControlStateNormal];
}

@end

@interface AcapeMemberDetailScreen () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UIImageView *headerGlowView;
@property (nonatomic, strong) UIView *navBarView;
@property (nonatomic, strong) UIButton *backControl;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UITextField *nicknameField;
@property (nonatomic, strong) UITextField *birthdayField;
@property (nonatomic, strong) UITextField *locationField;
@property (nonatomic, strong) UIButton *maleButton;
@property (nonatomic, strong) UIButton *femaleButton;
@property (nonatomic, strong) AcapePrimaryActionButton *advanceButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UIView *birthdayShadeView;
@property (nonatomic, strong) UIView *birthdaySheetView;
@property (nonatomic, strong) UIDatePicker *birthdayPicker;

@end

@implementation AcapeMemberDetailScreen

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [AcapeAuthFormKit pageBackgroundColor];
    [self acape_enableDismissKeyboardOnBackgroundTap];
    [self buildLayout];
    [self populateFields];
}

- (void)buildLayout {
    self.headerGlowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"harbor_header_glow"]];
    self.headerGlowView.contentMode = UIViewContentModeScaleAspectFill;
    self.headerGlowView.clipsToBounds = YES;
    self.headerGlowView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.headerGlowView];

    self.navBarView = [[UIView alloc] init];
    self.navBarView.backgroundColor = UIColor.clearColor;
    self.navBarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.navBarView];

    self.backControl = [AcapeNavKit backControlWithTarget:self action:@selector(handleBackTap)];
    [self.navBarView addSubview:self.backControl];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentView];

    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.contentMode = UIViewContentModeScaleAspectFit;
    self.avatarView.clipsToBounds = NO;
    self.avatarView.userInteractionEnabled = YES;
    self.avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.avatarView];
    [self.avatarView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleAvatarTap)]];

    UIView *formPanel = [[UIView alloc] init];
    formPanel.backgroundColor = [AcapeAuthFormKit panelBackgroundColor];
    formPanel.layer.cornerRadius = 24.0;
    formPanel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:formPanel];

    UILabel *nicknameCaption = [AcapeAuthFormKit fieldCaptionWithText:AcapeRevealText(AcapeRevealTextKeyHubNickname)];
    self.nicknameField = [AcapeAuthFormKit inputFieldWithPlaceholder:AcapeRevealText(AcapeRevealTextKeyHubFieldPlaceholder) secure:NO];

    UILabel *birthdayCaption = [AcapeAuthFormKit fieldCaptionWithText:AcapeRevealText(AcapeRevealTextKeyHubBirthday)];
    self.birthdayField = [AcapeAuthFormKit inputFieldWithPlaceholder:@"Please select" secure:NO];
    self.birthdayField.delegate = self;

    UILabel *locationCaption = [AcapeAuthFormKit fieldCaptionWithText:AcapeRevealText(AcapeRevealTextKeyHubLocation)];
    self.locationField = [AcapeAuthFormKit inputFieldWithPlaceholder:AcapeRevealText(AcapeRevealTextKeyHubFieldPlaceholder) secure:NO];

    UILabel *genderCaption = [AcapeAuthFormKit fieldCaptionWithText:AcapeRevealText(AcapeRevealTextKeyHubGender)];
    self.maleButton = [self genderButtonWithTitle:AcapeRevealText(AcapeRevealTextKeyHubMale)];
    self.femaleButton = [self genderButtonWithTitle:AcapeRevealText(AcapeRevealTextKeyHubFemale)];
    [self.maleButton addTarget:self action:@selector(handleMaleTap) forControlEvents:UIControlEventTouchUpInside];
    [self.femaleButton addTarget:self action:@selector(handleFemaleTap) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *genderStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.maleButton, self.femaleButton]];
    genderStack.axis = UILayoutConstraintAxisHorizontal;
    genderStack.spacing = 12.0;
    genderStack.distribution = UIStackViewDistributionFillEqually;
    genderStack.translatesAutoresizingMaskIntoConstraints = NO;

    for (UIView *view in @[nicknameCaption, self.nicknameField, birthdayCaption, self.birthdayField, locationCaption, self.locationField, genderCaption, genderStack]) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [formPanel addSubview:view];
    }

    self.advanceButton = [[AcapePrimaryActionButton alloc] initWithFrame:CGRectZero];
    [self.advanceButton setTitle:AcapeRevealText(AcapeRevealTextKeyHubAdvance) forState:UIControlStateNormal];
    self.advanceButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.advanceButton addTarget:self action:@selector(handleAdvanceTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.advanceButton];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.color = UIColor.whiteColor;
    self.loadingIndicator.hidesWhenStopped = YES;
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.loadingIndicator];

    [NSLayoutConstraint activateConstraints:@[
        [self.headerGlowView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:-145.0],
        [self.headerGlowView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:-41.0],
        [self.headerGlowView.widthAnchor constraintEqualToConstant:379.0],
        [self.headerGlowView.heightAnchor constraintEqualToConstant:379.0],

        [self.navBarView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.navBarView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.navBarView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.navBarView.heightAnchor constraintEqualToConstant:44.0],

        [self.backControl.leadingAnchor constraintEqualToAnchor:self.navBarView.leadingAnchor constant:16.0],
        [self.backControl.centerYAnchor constraintEqualToAnchor:self.navBarView.centerYAnchor],

        [self.scrollView.topAnchor constraintEqualToAnchor:self.navBarView.bottomAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.advanceButton.topAnchor constant:-16.0],

        [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor],

        [self.avatarView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:16.0],
        [self.avatarView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [self.avatarView.widthAnchor constraintEqualToConstant:98.0],
        [self.avatarView.heightAnchor constraintEqualToConstant:98.0],

        [formPanel.topAnchor constraintEqualToAnchor:self.avatarView.bottomAnchor constant:28.0],
        [formPanel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20.0],
        [formPanel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20.0],
        [formPanel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-16.0],

        [nicknameCaption.topAnchor constraintEqualToAnchor:formPanel.topAnchor constant:24.0],
        [nicknameCaption.leadingAnchor constraintEqualToAnchor:formPanel.leadingAnchor constant:20.0],
        [self.nicknameField.topAnchor constraintEqualToAnchor:nicknameCaption.bottomAnchor constant:8.0],
        [self.nicknameField.leadingAnchor constraintEqualToAnchor:nicknameCaption.leadingAnchor],
        [self.nicknameField.trailingAnchor constraintEqualToAnchor:formPanel.trailingAnchor constant:-20.0],
        [self.nicknameField.heightAnchor constraintEqualToConstant:47.0],

        [birthdayCaption.topAnchor constraintEqualToAnchor:self.nicknameField.bottomAnchor constant:20.0],
        [birthdayCaption.leadingAnchor constraintEqualToAnchor:nicknameCaption.leadingAnchor],
        [self.birthdayField.topAnchor constraintEqualToAnchor:birthdayCaption.bottomAnchor constant:8.0],
        [self.birthdayField.leadingAnchor constraintEqualToAnchor:self.nicknameField.leadingAnchor],
        [self.birthdayField.trailingAnchor constraintEqualToAnchor:self.nicknameField.trailingAnchor],
        [self.birthdayField.heightAnchor constraintEqualToConstant:47.0],

        [locationCaption.topAnchor constraintEqualToAnchor:self.birthdayField.bottomAnchor constant:20.0],
        [locationCaption.leadingAnchor constraintEqualToAnchor:nicknameCaption.leadingAnchor],
        [self.locationField.topAnchor constraintEqualToAnchor:locationCaption.bottomAnchor constant:8.0],
        [self.locationField.leadingAnchor constraintEqualToAnchor:self.nicknameField.leadingAnchor],
        [self.locationField.trailingAnchor constraintEqualToAnchor:self.nicknameField.trailingAnchor],
        [self.locationField.heightAnchor constraintEqualToConstant:47.0],

        [genderCaption.topAnchor constraintEqualToAnchor:self.locationField.bottomAnchor constant:20.0],
        [genderCaption.leadingAnchor constraintEqualToAnchor:nicknameCaption.leadingAnchor],
        [genderStack.topAnchor constraintEqualToAnchor:genderCaption.bottomAnchor constant:8.0],
        [genderStack.leadingAnchor constraintEqualToAnchor:self.nicknameField.leadingAnchor],
        [genderStack.trailingAnchor constraintEqualToAnchor:self.nicknameField.trailingAnchor],
        [genderStack.heightAnchor constraintEqualToConstant:46.0],
        [genderStack.bottomAnchor constraintEqualToAnchor:formPanel.bottomAnchor constant:-24.0],

        [self.advanceButton.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:25.0],
        [self.advanceButton.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-25.0],
        [self.advanceButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-16.0],
        [self.advanceButton.heightAnchor constraintEqualToConstant:52.0],

        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];
}

- (UIButton *)genderButtonWithTitle:(NSString *)title {
    AcapeGenderChoiceButton *button = [[AcapeGenderChoiceButton alloc] initWithFrame:CGRectZero];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    button.backgroundColor = UIColor.blackColor;
    button.layer.cornerRadius = 12.0;
    [button applyChosen:NO];
    return button;
}

- (void)populateFields {
    AcapeMemberProfile *profile = [AcapeVaultStore shared].currentMemberProfile;
    BOOL usesLocalPortrait = [profile.avatarAssetName isEqualToString:kAcapeLocalPortraitAssetName];
    UIImage *storedPortrait = usesLocalPortrait ? [[AcapeVaultStore shared] avatarImageForAssetName:profile.avatarAssetName] : nil;
    [self applyAvatarImage:(storedPortrait ?: [UIImage imageNamed:@"设置默认头像"]) clipsToCircle:usesLocalPortrait];
    BOOL hasCompletedInfo = profile.profileCompleted;
    self.nicknameField.text = hasCompletedInfo ? profile.nickname : @"";
    self.birthdayField.text = hasCompletedInfo ? profile.birthday : @"";
    self.locationField.text = hasCompletedInfo ? profile.location : @"";
    [self refreshGenderSelection];
}

- (void)refreshGenderSelection {
    AcapeMemberProfile *profile = [AcapeVaultStore shared].currentMemberProfile;
    BOOL isMale = ![profile.gender isEqualToString:@"female"];
    [(AcapeGenderChoiceButton *)self.maleButton applyChosen:isMale];
    [(AcapeGenderChoiceButton *)self.femaleButton applyChosen:!isMale];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField == self.birthdayField) {
        [self.view endEditing:YES];
        [self presentBirthdayPicker];
        return NO;
    }
    return YES;
}

- (void)handleAvatarTap {
    [self.view endEditing:YES];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Photo Library" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self requestPhotoAccessThenPresentPicker];
        }]];
    }
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self requestCameraAccessThenPresentPicker];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:AcapeRevealText(AcapeRevealTextKeyHubCancel) style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = self.avatarView;
    sheet.popoverPresentationController.sourceRect = self.avatarView.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)requestCameraAccessThenPresentPicker {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        [self presentPortraitPickerWithSource:UIImagePickerControllerSourceTypeCamera];
        return;
    }
    if (status == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    [self presentPortraitPickerWithSource:UIImagePickerControllerSourceTypeCamera];
                } else {
                    [self presentNoticeWithCopy:@"Camera permission is required."];
                }
            });
        }];
        return;
    }
    [self presentNoticeWithCopy:@"Camera permission is required."];
}

- (void)requestPhotoAccessThenPresentPicker {
    if (@available(iOS 14.0, *)) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
        if (status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited) {
            [self presentPortraitPickerWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
            return;
        }
        if (status == PHAuthorizationStatusNotDetermined) {
            [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus requestStatus) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (requestStatus == PHAuthorizationStatusAuthorized || requestStatus == PHAuthorizationStatusLimited) {
                        [self presentPortraitPickerWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
                    } else {
                        [self presentNoticeWithCopy:@"Photo library permission is required."];
                    }
                });
            }];
            return;
        }
    } else {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusAuthorized) {
            [self presentPortraitPickerWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
            return;
        }
        if (status == PHAuthorizationStatusNotDetermined) {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus requestStatus) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (requestStatus == PHAuthorizationStatusAuthorized) {
                        [self presentPortraitPickerWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
                    } else {
                        [self presentNoticeWithCopy:@"Photo library permission is required."];
                    }
                });
            }];
            return;
        }
    }
    [self presentNoticeWithCopy:@"Photo library permission is required."];
}

- (void)presentPortraitPickerWithSource:(UIImagePickerControllerSourceType)sourceType {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.allowsEditing = YES;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    if (image) {
        [self applyAvatarImage:image clipsToCircle:YES];
        [self persistPortraitImage:image];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)persistPortraitImage:(UIImage *)image {
    NSData *data = UIImagePNGRepresentation(image);
    if (!data) {
        data = UIImageJPEGRepresentation(image, 0.88);
    }
    if (!data) {
        return;
    }
    [data writeToURL:[self localPortraitURL] atomically:YES];
    AcapeMemberProfile *profile = [AcapeVaultStore shared].currentMemberProfile;
    profile.avatarAssetName = kAcapeLocalPortraitAssetName;
    [[AcapeVaultStore shared] updateCurrentMemberProfile:profile];
}

- (void)applyAvatarImage:(UIImage *)image clipsToCircle:(BOOL)clipsToCircle {
    self.avatarView.image = image;
    self.avatarView.contentMode = clipsToCircle ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleAspectFit;
    self.avatarView.layer.cornerRadius = clipsToCircle ? 49.0 : 0.0;
    self.avatarView.clipsToBounds = clipsToCircle;
}

- (NSURL *)localPortraitURL {
    return [[AcapeVaultStore shared] localPortraitURL];
}

- (void)presentBirthdayPicker {
    if (self.birthdaySheetView) {
        return;
    }

    self.birthdayShadeView = [[UIView alloc] init];
    self.birthdayShadeView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.45];
    self.birthdayShadeView.alpha = 0.0;
    self.birthdayShadeView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.birthdayShadeView];
    [self.birthdayShadeView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissBirthdayPicker)]];

    self.birthdaySheetView = [[UIView alloc] init];
    self.birthdaySheetView.backgroundColor = [UIColor colorWithRed:0.08 green:0.13 blue:0.14 alpha:1.0];
    self.birthdaySheetView.layer.cornerRadius = 24.0;
    self.birthdaySheetView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.birthdaySheetView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.birthdaySheetView];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = AcapeRevealText(AcapeRevealTextKeyHubBirthday);
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.birthdaySheetView addSubview:titleLabel];

    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancelButton setTitle:AcapeRevealText(AcapeRevealTextKeyHubCancel) forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.7] forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton addTarget:self action:@selector(dismissBirthdayPicker) forControlEvents:UIControlEventTouchUpInside];
    [self.birthdaySheetView addSubview:cancelButton];

    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [doneButton setTitleColor:[AcapeAuthFormKit accentTealColor] forState:UIControlStateNormal];
    doneButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    doneButton.translatesAutoresizingMaskIntoConstraints = NO;
    [doneButton addTarget:self action:@selector(confirmBirthdayPicker) forControlEvents:UIControlEventTouchUpInside];
    [self.birthdaySheetView addSubview:doneButton];

    self.birthdayPicker = [[UIDatePicker alloc] init];
    self.birthdayPicker.datePickerMode = UIDatePickerModeDate;
    self.birthdayPicker.maximumDate = [NSDate date];
    self.birthdayPicker.tintColor = [AcapeAuthFormKit accentTealColor];
    if (@available(iOS 13.0, *)) {
        self.birthdayPicker.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
    @try {
        [self.birthdayPicker setValue:UIColor.whiteColor forKey:@"textColor"];
    } @catch (__unused NSException *exception) {
    }
    if (@available(iOS 13.4, *)) {
        self.birthdayPicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
    NSDate *date = [self birthdayDateFromText:self.birthdayField.text] ?: [self birthdayDateFromText:@"2003-01-01"] ?: [NSDate date];
    self.birthdayPicker.date = date;
    self.birthdayPicker.translatesAutoresizingMaskIntoConstraints = NO;
    [self.birthdaySheetView addSubview:self.birthdayPicker];

    [NSLayoutConstraint activateConstraints:@[
        [self.birthdayShadeView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.birthdayShadeView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.birthdayShadeView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.birthdayShadeView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.birthdaySheetView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.birthdaySheetView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.birthdaySheetView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [titleLabel.topAnchor constraintEqualToAnchor:self.birthdaySheetView.topAnchor constant:20.0],
        [titleLabel.centerXAnchor constraintEqualToAnchor:self.birthdaySheetView.centerXAnchor],
        [cancelButton.centerYAnchor constraintEqualToAnchor:titleLabel.centerYAnchor],
        [cancelButton.leadingAnchor constraintEqualToAnchor:self.birthdaySheetView.leadingAnchor constant:24.0],
        [doneButton.centerYAnchor constraintEqualToAnchor:titleLabel.centerYAnchor],
        [doneButton.trailingAnchor constraintEqualToAnchor:self.birthdaySheetView.trailingAnchor constant:-24.0],

        [self.birthdayPicker.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:12.0],
        [self.birthdayPicker.leadingAnchor constraintEqualToAnchor:self.birthdaySheetView.leadingAnchor],
        [self.birthdayPicker.trailingAnchor constraintEqualToAnchor:self.birthdaySheetView.trailingAnchor],
        [self.birthdayPicker.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-16.0],
    ]];

    self.birthdaySheetView.transform = CGAffineTransformMakeTranslation(0.0, 360.0);
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.birthdayShadeView.alpha = 1.0;
        self.birthdaySheetView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)confirmBirthdayPicker {
    self.birthdayField.text = [self birthdayTextFromDate:self.birthdayPicker.date];
    [self dismissBirthdayPicker];
}

- (void)dismissBirthdayPicker {
    if (!self.birthdaySheetView) {
        return;
    }
    UIView *shadeView = self.birthdayShadeView;
    UIView *sheetView = self.birthdaySheetView;
    self.birthdayShadeView = nil;
    self.birthdaySheetView = nil;
    self.birthdayPicker = nil;
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        shadeView.alpha = 0.0;
        sheetView.transform = CGAffineTransformMakeTranslation(0.0, 360.0);
    } completion:^(__unused BOOL finished) {
        [shadeView removeFromSuperview];
        [sheetView removeFromSuperview];
    }];
}

- (NSDate *)birthdayDateFromText:(NSString *)text {
    if (text.length == 0) {
        return nil;
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    return [formatter dateFromString:text];
}

- (NSString *)birthdayTextFromDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    return [formatter stringFromDate:date];
}

- (void)handleMaleTap {
    AcapeMemberProfile *profile = [AcapeVaultStore shared].currentMemberProfile;
    profile.gender = @"male";
    [[AcapeVaultStore shared] updateCurrentMemberProfile:profile];
    [self refreshGenderSelection];
}

- (void)handleFemaleTap {
    AcapeMemberProfile *profile = [AcapeVaultStore shared].currentMemberProfile;
    profile.gender = @"female";
    [[AcapeVaultStore shared] updateCurrentMemberProfile:profile];
    [self refreshGenderSelection];
}

- (void)handleBackTap {
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleAdvanceTap {
    NSString *nickname = [self.nicknameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *birthday = [self.birthdayField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *location = [self.locationField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (nickname.length == 0 || birthday.length == 0 || location.length == 0) {
        [self presentNoticeWithCopy:@"Please complete all information."];
        return;
    }

    AcapeMemberProfile *profile = [AcapeVaultStore shared].currentMemberProfile;
    profile.nickname = nickname;
    profile.displayName = nickname;
    profile.birthday = birthday;
    profile.location = location;
    if (profile.avatarAssetName.length == 0 || ![profile.avatarAssetName isEqualToString:kAcapeLocalPortraitAssetName]) {
        profile.avatarAssetName = @"member_default_mark";
    }
    profile.profileCompleted = YES;
    [[AcapeVaultStore shared] updateCurrentMemberProfile:profile];

    self.advanceButton.enabled = NO;
    [self.loadingIndicator startAnimating];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.loadingIndicator stopAnimating];
        self.advanceButton.enabled = YES;
        [AcapeAppNavigator presentHarborAsRootInWindow:self.view.window animated:YES];
    });
}

- (void)presentNoticeWithCopy:(NSString *)noticeText {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:noticeText
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

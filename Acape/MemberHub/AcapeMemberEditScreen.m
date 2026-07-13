#import "AcapeMemberEditScreen.h"
#import "AcapeRevealText.h"
#import "AcapeVaultStore.h"
#import "AcapeMemberProfile.h"
#import "AcapeNavKit.h"
#import "AcapeAuthFormKit.h"
#import "AcapePrimaryActionButton.h"
#import "UIViewController+AcapeDismissKeyboard.h"
@import AVFoundation;
@import Photos;

static NSString * const kAcapeLocalPortraitAssetName = @"member_local_portrait";

@interface AcapeMemberEditScreen () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UIImageView *headerGlowView;
@property (nonatomic, strong) UIButton *backControl;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UIButton *cameraBadgeButton;
@property (nonatomic, strong) UILabel *usernameCaption;
@property (nonatomic, strong) UITextField *usernameField;
@property (nonatomic, strong) AcapePrimaryActionButton *saveButton;
@property (nonatomic, strong) UIView *loadingOverlay;
@property (nonatomic, strong) UIView *toastView;
@property (nonatomic, assign) BOOL isSaving;

@end

@implementation AcapeMemberEditScreen

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

    self.backControl = [AcapeNavKit backControlWithTarget:self action:@selector(handleBackTap)];
    [self.view addSubview:self.backControl];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = AcapeRevealText(AcapeRevealTextKeyHubEditTitle);
    self.titleLabel.textColor = UIColor.whiteColor;
    self.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.titleLabel];

    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.layer.cornerRadius = 30.0;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.avatarView];

    self.cameraBadgeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cameraBadgeButton.backgroundColor = [AcapeAuthFormKit accentTealColor];
    self.cameraBadgeButton.layer.cornerRadius = 18.0;
    self.cameraBadgeButton.clipsToBounds = YES;
    UIImage *cameraMark = [UIImage imageNamed:@"头像相机"];
    [self.cameraBadgeButton setImage:cameraMark forState:UIControlStateNormal];
    self.cameraBadgeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.cameraBadgeButton.contentEdgeInsets = UIEdgeInsetsMake(8.0, 8.0, 8.0, 8.0);
    self.cameraBadgeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cameraBadgeButton addTarget:self action:@selector(handleCameraTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.cameraBadgeButton];

    self.usernameCaption = [AcapeAuthFormKit fieldCaptionWithText:AcapeRevealText(AcapeRevealTextKeyHubUsername)];
    [self.view addSubview:self.usernameCaption];

    self.usernameField = [AcapeAuthFormKit inputFieldWithPlaceholder:AcapeRevealText(AcapeRevealTextKeyHubUsernamePlaceholder) secure:NO];
    self.usernameField.backgroundColor = [UIColor colorWithRed:31.0/255.0 green:51.0/255.0 blue:55.0/255.0 alpha:1.0];
    self.usernameField.layer.cornerRadius = 16.0;
    [self.view addSubview:self.usernameField];

    self.saveButton = [[AcapePrimaryActionButton alloc] initWithFrame:CGRectZero];
    [self.saveButton setTitle:AcapeRevealText(AcapeRevealTextKeyHubSave) forState:UIControlStateNormal];
    self.saveButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.saveButton addTarget:self action:@selector(handleSaveTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.saveButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.headerGlowView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:-145.0],
        [self.headerGlowView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:-41.0],
        [self.headerGlowView.widthAnchor constraintEqualToConstant:379.0],
        [self.headerGlowView.heightAnchor constraintEqualToConstant:379.0],

        [self.backControl.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:16.0],
        [self.backControl.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:4.0],

        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.backControl.centerYAnchor],

        [self.avatarView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:136.0],
        [self.avatarView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.avatarView.widthAnchor constraintEqualToConstant:120.0],
        [self.avatarView.heightAnchor constraintEqualToConstant:120.0],

        [self.cameraBadgeButton.trailingAnchor constraintEqualToAnchor:self.avatarView.trailingAnchor constant:2.0],
        [self.cameraBadgeButton.bottomAnchor constraintEqualToAnchor:self.avatarView.bottomAnchor constant:2.0],
        [self.cameraBadgeButton.widthAnchor constraintEqualToConstant:36.0],
        [self.cameraBadgeButton.heightAnchor constraintEqualToConstant:36.0],

        [self.usernameCaption.topAnchor constraintEqualToAnchor:self.avatarView.bottomAnchor constant:73.0],
        [self.usernameCaption.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:25.0],

        [self.usernameField.topAnchor constraintEqualToAnchor:self.usernameCaption.bottomAnchor constant:12.0],
        [self.usernameField.leadingAnchor constraintEqualToAnchor:self.usernameCaption.leadingAnchor],
        [self.usernameField.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-25.0],
        [self.usernameField.heightAnchor constraintEqualToConstant:52.0],

        [self.saveButton.leadingAnchor constraintEqualToAnchor:self.usernameField.leadingAnchor],
        [self.saveButton.trailingAnchor constraintEqualToAnchor:self.usernameField.trailingAnchor],
        [self.saveButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-32.0],
        [self.saveButton.heightAnchor constraintEqualToConstant:52.0],
    ]];
}

- (void)populateFields {
    AcapeMemberProfile *profile = [AcapeVaultStore shared].currentMemberProfile;
    self.avatarView.image = [[AcapeVaultStore shared] avatarImageForAssetName:profile.avatarAssetName];
    self.usernameField.text = profile.displayName;
}

- (void)handleBackTap {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleCameraTap {
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
    sheet.popoverPresentationController.sourceView = self.cameraBadgeButton;
    sheet.popoverPresentationController.sourceRect = self.cameraBadgeButton.bounds;
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
                    [self showToastWithText:@"Camera permission is required." completion:nil];
                }
            });
        }];
        return;
    }
    [self showToastWithText:@"Camera permission is required." completion:nil];
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
                        [self showToastWithText:@"Photo library permission is required." completion:nil];
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
                        [self showToastWithText:@"Photo library permission is required." completion:nil];
                    }
                });
            }];
            return;
        }
    }
    [self showToastWithText:@"Photo library permission is required." completion:nil];
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
        self.avatarView.image = image;
        self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
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
    [data writeToURL:[[AcapeVaultStore shared] localPortraitURL] atomically:YES];
    AcapeMemberProfile *profile = [AcapeVaultStore shared].currentMemberProfile;
    profile.avatarAssetName = kAcapeLocalPortraitAssetName;
    [[AcapeVaultStore shared] updateCurrentMemberProfile:profile];
}

- (void)handleSaveTap {
    if (self.isSaving) {
        return;
    }

    NSString *username = [self.usernameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (username.length == 0) {
        [self showToastWithText:AcapeRevealText(AcapeRevealTextKeyHubUsernameRequired) completion:nil];
        return;
    }

    self.isSaving = YES;
    [self.view endEditing:YES];
    [self showLoadingOverlay];
    self.view.userInteractionEnabled = NO;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        AcapeMemberProfile *profile = [AcapeVaultStore shared].currentMemberProfile;
        profile.displayName = username;
        [[AcapeVaultStore shared] updateCurrentMemberProfile:profile];
        [self hideLoadingOverlay];
        [self showToastWithText:AcapeRevealText(AcapeRevealTextKeyHubSaveDone) completion:^{
            self.view.userInteractionEnabled = YES;
            self.isSaving = NO;
            [self.navigationController popViewControllerAnimated:YES];
        }];
    });
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

- (void)showLoadingOverlay {
    if (self.loadingOverlay.superview) {
        return;
    }

    UIView *overlay = [[UIView alloc] init];
    overlay.backgroundColor = UIColor.clearColor;
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:overlay];

    UIView *plate = [[UIView alloc] init];
    plate.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.34];
    plate.layer.cornerRadius = 18.0;
    plate.translatesAutoresizingMaskIntoConstraints = NO;
    [overlay addSubview:plate];

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.color = UIColor.whiteColor;
    spinner.transform = CGAffineTransformMakeScale(0.82, 0.82);
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [plate addSubview:spinner];
    [spinner startAnimating];

    [NSLayoutConstraint activateConstraints:@[
        [overlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [overlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [overlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [overlay.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [plate.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [plate.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
        [plate.widthAnchor constraintEqualToConstant:58.0],
        [plate.heightAnchor constraintEqualToConstant:58.0],

        [spinner.centerXAnchor constraintEqualToAnchor:plate.centerXAnchor],
        [spinner.centerYAnchor constraintEqualToAnchor:plate.centerYAnchor],
    ]];
    self.loadingOverlay = overlay;
}

- (void)hideLoadingOverlay {
    [self.loadingOverlay removeFromSuperview];
    self.loadingOverlay = nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

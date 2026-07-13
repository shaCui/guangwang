#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AcapeMemberHubKit : NSObject

+ (UIColor *)pageBackgroundColor;
+ (UIColor *)panelBackgroundColor;
+ (UIColor *)accentTealColor;
+ (UIColor *)destructiveTextColor;

+ (UIImage *)rowArrowImage;
+ (UIImage *)moreControlImage;

+ (UIView *)settingsPanelView;
+ (UIButton *)settingsRowButtonWithTitle:(NSString *)title destructive:(BOOL)destructive;

@end

NS_ASSUME_NONNULL_END

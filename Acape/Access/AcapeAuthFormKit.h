#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AcapeAuthFormKit : NSObject

+ (UIColor *)pageBackgroundColor;
+ (UIColor *)accentTealColor;
+ (UIColor *)panelBackgroundColor;
+ (UIColor *)fieldBackgroundColor;
+ (UIColor *)placeholderColor;

+ (CAGradientLayer *)headerGradientLayer;
+ (UIView *)formPanelView;
+ (UILabel *)fieldCaptionWithText:(NSString *)text;
+ (UITextField *)inputFieldWithPlaceholder:(NSString *)placeholder secure:(BOOL)secure;

@end

NS_ASSUME_NONNULL_END

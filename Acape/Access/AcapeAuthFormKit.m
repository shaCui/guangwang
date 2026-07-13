#import "AcapeAuthFormKit.h"

@implementation AcapeAuthFormKit

+ (UIColor *)pageBackgroundColor {
    return [UIColor colorWithRed:0.04 green:0.06 blue:0.06 alpha:1.0];
}

+ (UIColor *)accentTealColor {
    return [UIColor colorWithRed:66.0/255.0 green:252.0/255.0 blue:244.0/255.0 alpha:1.0];
}

+ (UIColor *)panelBackgroundColor {
    return [UIColor colorWithRed:26.0/255.0 green:38.0/255.0 blue:50.0/255.0 alpha:1.0];
}

+ (UIColor *)fieldBackgroundColor {
    return UIColor.blackColor;
}

+ (UIColor *)placeholderColor {
    return [UIColor colorWithWhite:1.0 alpha:0.35];
}

+ (CAGradientLayer *)headerGradientLayer {
    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.colors = @[
        (__bridge id)[UIColor colorWithRed:0.08 green:0.28 blue:0.26 alpha:0.95].CGColor,
        (__bridge id)[UIColor colorWithRed:0.05 green:0.12 blue:0.11 alpha:0.55].CGColor,
        (__bridge id)[UIColor colorWithRed:0.04 green:0.06 blue:0.06 alpha:0.0].CGColor,
    ];
    layer.locations = @[@0.0, @0.45, @1.0];
    layer.startPoint = CGPointMake(0.5, 0.0);
    layer.endPoint = CGPointMake(0.5, 1.0);
    return layer;
}

+ (UIView *)formPanelView {
    UIView *panel = [[UIView alloc] init];
    panel.backgroundColor = [self panelBackgroundColor];
    panel.layer.cornerRadius = 40.0;
    panel.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    return panel;
}

+ (UILabel *)fieldCaptionWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    return label;
}

+ (UITextField *)inputFieldWithPlaceholder:(NSString *)placeholder secure:(BOOL)secure {
    UITextField *field = [[UITextField alloc] init];
    field.backgroundColor = [self fieldBackgroundColor];
    field.textColor = UIColor.whiteColor;
    field.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    field.layer.cornerRadius = 20.0;
    field.clipsToBounds = YES;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.secureTextEntry = secure;
    field.translatesAutoresizingMaskIntoConstraints = NO;
    field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{
        NSForegroundColorAttributeName: [self placeholderColor],
        NSFontAttributeName: [UIFont systemFontOfSize:16 weight:UIFontWeightRegular],
    }];
    UIView *leftPadding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 52)];
    field.leftView = leftPadding;
    field.leftViewMode = UITextFieldViewModeAlways;
    return field;
}

@end

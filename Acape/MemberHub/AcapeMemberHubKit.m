#import "AcapeMemberHubKit.h"

@implementation AcapeMemberHubKit

+ (UIColor *)pageBackgroundColor {
    return [UIColor colorWithRed:0.04 green:0.06 blue:0.06 alpha:1.0];
}

+ (UIColor *)panelBackgroundColor {
    return [UIColor colorWithRed:31.0/255.0 green:51.0/255.0 blue:55.0/255.0 alpha:1.0];
}

+ (UIColor *)accentTealColor {
    return [UIColor colorWithRed:66.0/255.0 green:252.0/255.0 blue:244.0/255.0 alpha:1.0];
}

+ (UIColor *)destructiveTextColor {
    return [UIColor colorWithRed:1.0 green:87.0/255.0 blue:51.0/255.0 alpha:1.0];
}

+ (UIImage *)rowArrowImage {
    return [UIImage imageNamed:@"hub_row_arrow_mark"];
}

+ (UIImage *)moreControlImage {
    CGSize size = CGSizeMake(36.0, 36.0);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGRect circle = CGRectMake(0, 0, size.width, size.height);
    [[UIColor colorWithWhite:1.0 alpha:0.08] setFill];
    [[UIBezierPath bezierPathWithOvalInRect:circle] fill];

    UIColor *dotColor = [UIColor colorWithWhite:1.0 alpha:0.85];
    [dotColor setFill];
    CGFloat dot = 3.0;
    CGFloat y = (size.height - dot) / 2.0;
    for (NSInteger index = 0; index < 3; index++) {
        CGFloat x = 9.0 + index * 7.0;
        [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(x, y, dot, dot)] fill];
    }

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIView *)settingsPanelView {
    UIView *panel = [[UIView alloc] init];
    panel.backgroundColor = [self panelBackgroundColor];
    panel.layer.cornerRadius = 16.0;
    panel.clipsToBounds = YES;
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    return panel;
}

+ (UIButton *)settingsRowButtonWithTitle:(NSString *)title destructive:(BOOL)destructive {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.titleEdgeInsets = UIEdgeInsetsMake(0, 20.0, 0, 0);
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:(destructive ? [self destructiveTextColor] : UIColor.whiteColor) forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];

    UIImage *arrowImage = [self rowArrowImage];
    UIImageView *arrowView = [[UIImageView alloc] initWithImage:arrowImage];
    arrowView.contentMode = UIViewContentModeScaleAspectFit;
    arrowView.translatesAutoresizingMaskIntoConstraints = NO;
    arrowView.userInteractionEnabled = NO;
    [button addSubview:arrowView];

    CGFloat arrowWidth = arrowImage.size.width > 0 ? arrowImage.size.width : 18.0;
    CGFloat arrowHeight = arrowImage.size.height > 0 ? arrowImage.size.height : 18.0;

    [NSLayoutConstraint activateConstraints:@[
        [button.heightAnchor constraintEqualToConstant:43.0],
        [arrowView.trailingAnchor constraintEqualToAnchor:button.trailingAnchor constant:-20.0],
        [arrowView.centerYAnchor constraintEqualToAnchor:button.centerYAnchor],
        [arrowView.widthAnchor constraintEqualToConstant:arrowWidth],
        [arrowView.heightAnchor constraintEqualToConstant:arrowHeight],
    ]];
    return button;
}

@end

#import "AcapeNavKit.h"

@implementation AcapeNavKit

+ (UIButton *)backControlWithTarget:(id)target action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *image = [UIImage imageNamed:@"nav_back_mark"];
    [button setImage:image forState:UIControlStateNormal];
    button.adjustsImageWhenHighlighted = NO;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    if (target && action) {
        [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    }
    if (image.size.width > 0 && image.size.height > 0) {
        [button.widthAnchor constraintEqualToConstant:image.size.width].active = YES;
        [button.heightAnchor constraintEqualToConstant:image.size.height].active = YES;
    } else {
        [button.widthAnchor constraintEqualToConstant:44.0].active = YES;
        [button.heightAnchor constraintEqualToConstant:44.0].active = YES;
    }
    return button;
}

@end

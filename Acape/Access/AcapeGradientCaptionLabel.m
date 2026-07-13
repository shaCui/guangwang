#import "AcapeGradientCaptionLabel.h"
#import "AcapeAuthFormKit.h"

@implementation AcapeGradientCaptionLabel {
    CAGradientLayer *_gradientLayer;
}

- (instancetype)init {
    return [self initWithFontSize:48.0];
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFontSize:48.0];
}

- (instancetype)initWithFontSize:(CGFloat)fontSize {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.textColor = UIColor.whiteColor;
        self.textAlignment = NSTextAlignmentLeft;
        self.font = [UIFont fontWithDescriptor:[[UIFont systemFontOfSize:fontSize weight:UIFontWeightBold].fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic]
                                        size:fontSize];
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[
            (__bridge id)[UIColor colorWithRed:205.0/255.0 green:255.0/255.0 blue:199.0/255.0 alpha:1.0].CGColor,
            (__bridge id)[AcapeAuthFormKit accentTealColor].CGColor,
        ];
        _gradientLayer.startPoint = CGPointMake(0.5, 0.0);
        _gradientLayer.endPoint = CGPointMake(0.5, 1.0);
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.bounds.size.width <= 0 || self.bounds.size.height <= 0) {
        return;
    }
    _gradientLayer.frame = self.bounds;
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [_gradientLayer renderInContext:context];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.textColor = [UIColor colorWithPatternImage:gradientImage];
}

@end

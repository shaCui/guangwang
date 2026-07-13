#import "AcapePrimaryActionButton.h"
#import "AcapeAuthFormKit.h"

@implementation AcapePrimaryActionButton {
    CAGradientLayer *_fillGradient;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _fillGradient = [CAGradientLayer layer];
        _fillGradient.colors = @[
            (__bridge id)[UIColor colorWithRed:205.0/255.0 green:255.0/255.0 blue:199.0/255.0 alpha:1.0].CGColor,
            (__bridge id)[AcapeAuthFormKit accentTealColor].CGColor,
        ];
        _fillGradient.startPoint = CGPointMake(0.0, 0.5);
        _fillGradient.endPoint = CGPointMake(1.0, 0.5);
        _fillGradient.cornerRadius = 16.0;
        [self.layer insertSublayer:_fillGradient atIndex:0];
        self.layer.cornerRadius = 16.0;
        self.clipsToBounds = YES;
        self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        [self setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _fillGradient.frame = self.bounds;
    _fillGradient.cornerRadius = 16.0;
    self.layer.cornerRadius = 16.0;
}

@end

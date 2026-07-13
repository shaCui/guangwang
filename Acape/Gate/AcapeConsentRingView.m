#import "AcapeConsentRingView.h"

@implementation AcapeConsentRingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return;
    }

    CGFloat inset = 1.0;
    CGRect boxRect = CGRectInset(rect, inset, inset);
    CGFloat cornerRadius = 4.0;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:boxRect cornerRadius:cornerRadius];
    CGContextSetStrokeColorWithColor(context, UIColor.whiteColor.CGColor);
    CGContextSetLineWidth(context, 1.5);
    CGContextAddPath(context, path.CGPath);
    CGContextStrokePath(context);
}

@end

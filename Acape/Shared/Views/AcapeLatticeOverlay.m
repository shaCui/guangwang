#import "AcapeLatticeOverlay.h"

@implementation AcapeLatticeOverlay

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

    CGFloat spacing = 14.0;
    CGFloat dotSize = 3.0;
    UIColor *dotColor = [UIColor colorWithRed:0.18 green:0.62 blue:0.58 alpha:0.22];
    NSInteger columns = (NSInteger)ceil(rect.size.width / spacing);
    NSInteger rows = (NSInteger)ceil(rect.size.height / spacing);

    for (NSInteger row = 0; row < rows; row++) {
        CGFloat rowProgress = (CGFloat)row / MAX(rows - 1, 1);
        CGFloat alphaScale = 1.0 - rowProgress * 0.85;
        UIColor *rowColor = [dotColor colorWithAlphaComponent:0.22 * alphaScale];

        for (NSInteger column = 0; column < columns; column++) {
            CGFloat x = column * spacing + spacing * 0.5;
            CGFloat y = row * spacing + spacing * 0.5;
            CGRect dotRect = CGRectMake(x - dotSize * 0.5, y - dotSize * 0.5, dotSize, dotSize);
            CGContextSetFillColorWithColor(context, rowColor.CGColor);
            CGContextFillEllipseInRect(context, dotRect);
        }
    }
}

@end

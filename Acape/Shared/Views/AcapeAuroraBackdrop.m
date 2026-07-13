#import "AcapeAuroraBackdrop.h"

@interface AcapeAuroraBackdrop ()
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIImageView *glowView;
@end

@implementation AcapeAuroraBackdrop

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _showsGlow = YES;
        self.backgroundColor = [AcapeAuroraBackdrop baseColor];
        self.userInteractionEnabled = NO;
        self.clipsToBounds = YES;

        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[
            (id)[AcapeAuroraBackdrop auroraTopColor].CGColor,
            (id)[AcapeAuroraBackdrop baseColor].CGColor,
        ];
        _gradientLayer.locations = @[@0.0, @0.19467];
        _gradientLayer.startPoint = CGPointMake(0.5, 0.0);
        _gradientLayer.endPoint = CGPointMake(0.5, 1.0);
        [self.layer addSublayer:_gradientLayer];

        _glowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"harbor_header_glow"]];
        _glowView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_glowView];
    }
    return self;
}

- (void)setShowsGlow:(BOOL)showsGlow {
    _showsGlow = showsGlow;
    self.glowView.hidden = !showsGlow;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.bounds;
    // Match the Sketch glow: 379x379 anchored at (-41, -189) relative to the screen top.
    self.glowView.frame = CGRectMake(-41.0, -189.0, 379.0, 379.0);
}

+ (UIColor *)baseColor {
    return [UIColor colorWithRed:0.067 green:0.075 blue:0.090 alpha:1.0];
}

+ (UIColor *)auroraTopColor {
    return [UIColor colorWithRed:0.020 green:0.267 blue:0.290 alpha:1.0];
}

+ (UIColor *)cardColor {
    return [UIColor colorWithRed:0.122 green:0.200 blue:0.216 alpha:1.0];
}

+ (UIColor *)accentColor {
    return [UIColor colorWithRed:0.259 green:0.988 blue:0.957 alpha:1.0];
}

@end

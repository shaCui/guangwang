#import "AcapeChamberJoinButton.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeRevealText.h"

@interface AcapeChamberJoinButton ()
@property (nonatomic, strong) CAGradientLayer *fillGradient;
@end

@implementation AcapeChamberJoinButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.fillGradient = [CAGradientLayer layer];
        self.fillGradient.colors = @[
            (__bridge id)[UIColor colorWithRed:0.804 green:1.0 blue:0.780 alpha:1.0].CGColor,
            (__bridge id)[AcapeAuroraBackdrop accentColor].CGColor,
        ];
        self.fillGradient.startPoint = CGPointMake(0.5, 0.0);
        self.fillGradient.endPoint = CGPointMake(0.5, 1.0);
        [self.layer insertSublayer:self.fillGradient atIndex:0];

        self.layer.cornerRadius = 12.0;
        self.clipsToBounds = YES;
        self.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
        [self setTitle:AcapeRevealText(AcapeRevealTextKeyChamberJoinAction) forState:UIControlStateNormal];
        [self setTitleColor:[UIColor colorWithRed:0.008 green:0.008 blue:0.020 alpha:1.0] forState:UIControlStateNormal];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self refreshFillGradient];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window) {
        [self setNeedsLayout];
    }
}

- (void)refreshFillGradient {
    if (CGRectIsEmpty(self.bounds)) {
        return;
    }
    self.fillGradient.frame = self.bounds;
    self.fillGradient.cornerRadius = 12.0;
    self.layer.cornerRadius = 12.0;
}

@end

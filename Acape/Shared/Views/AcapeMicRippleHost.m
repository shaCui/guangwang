#import "AcapeMicRippleHost.h"

static CGFloat const kAcapeMicRippleCoreSize = 28.0;
static CGFloat const kAcapeMicRippleHostSize = 56.0;
static NSString * const kAcapeMicRippleAnimationKey = @"acape.mic.ripple";

@interface AcapeMicRippleHost ()
@property (nonatomic, strong, readwrite) UIButton *micControl;
@property (nonatomic, copy) NSArray<CALayer *> *rippleLayers;
@property (nonatomic, assign, getter=isRippleLive) BOOL rippleLive;
@end

@implementation AcapeMicRippleHost

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = NO;
        self.userInteractionEnabled = YES;
        [self buildRippleLayers];
        [self buildMicControl];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(kAcapeMicRippleHostSize, kAcapeMicRippleHostSize);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat coreSide = kAcapeMicRippleCoreSize;
    CGFloat originX = (CGRectGetWidth(self.bounds) - coreSide) / 2.0;
    CGFloat originY = (CGRectGetHeight(self.bounds) - coreSide) / 2.0;
    CGRect coreFrame = CGRectMake(originX, originY, coreSide, coreSide);
    self.micControl.frame = coreFrame;
    for (CALayer *layer in self.rippleLayers) {
        layer.frame = coreFrame;
        layer.cornerRadius = coreSide / 2.0;
    }
}

- (void)buildRippleLayers {
    UIColor *ringColor = [UIColor colorWithRed:0.267 green:0.988 blue:0.953 alpha:1.0];
    NSMutableArray<CALayer *> *layers = [NSMutableArray arrayWithCapacity:3];
    for (NSInteger i = 0; i < 3; i++) {
        CALayer *ring = [CALayer layer];
        ring.backgroundColor = UIColor.clearColor.CGColor;
        ring.borderWidth = 1.2;
        ring.borderColor = [ringColor colorWithAlphaComponent:0.62].CGColor;
        ring.opacity = 0.0;
        [self.layer addSublayer:ring];
        [layers addObject:ring];
    }
    self.rippleLayers = layers.copy;
}

- (void)buildMicControl {
    self.micControl = [UIButton buttonWithType:UIButtonTypeCustom];
    self.micControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.micControl];
}

- (void)setRippleLive:(BOOL)live {
    if (_rippleLive == live) {
        return;
    }
    _rippleLive = live;
    if (live) {
        [self startRippleAnimation];
    } else {
        [self stopRippleAnimation];
    }
}

- (void)startRippleAnimation {
    [self stopRippleAnimation];
    NSArray<NSNumber *> *delays = @[@0.0, @0.75, @1.5];
    for (NSInteger index = 0; index < (NSInteger)self.rippleLayers.count; index++) {
        CALayer *ring = self.rippleLayers[index];
        ring.opacity = 0.0;
        ring.transform = CATransform3DIdentity;

        CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scale.fromValue = @1.0;
        scale.toValue = @2.0;

        CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacity.fromValue = @0.42;
        opacity.toValue = @0.0;

        CAAnimationGroup *group = [CAAnimationGroup animation];
        group.animations = @[scale, opacity];
        group.duration = 2.2;
        group.beginTime = CACurrentMediaTime() + delays[index].doubleValue;
        group.repeatCount = HUGE_VALF;
        group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        group.removedOnCompletion = NO;
        group.fillMode = kCAFillModeForwards;

        [ring addAnimation:group forKey:kAcapeMicRippleAnimationKey];
    }
}

- (void)stopRippleAnimation {
    for (CALayer *ring in self.rippleLayers) {
        [ring removeAnimationForKey:kAcapeMicRippleAnimationKey];
        ring.opacity = 0.0;
        ring.transform = CATransform3DIdentity;
    }
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window && self.isRippleLive) {
        [self startRippleAnimation];
    }
}

@end

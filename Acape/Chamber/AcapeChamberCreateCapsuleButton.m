#import "AcapeChamberCreateCapsuleButton.h"
#import "AcapeAuroraBackdrop.h"
#import "AcapeRevealText.h"

@interface AcapeChamberCreateCapsuleButton ()
@property (nonatomic, strong) CAGradientLayer *fillGradient;
@property (nonatomic, strong) UIImageView *markView;
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation AcapeChamberCreateCapsuleButton

+ (UIImage *)createMarkImage {
    UIImage *assetImage = [UIImage imageNamed:@"创建房间"];
    if (assetImage) {
        return assetImage;
    }

    static UIImage *markImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGSize size = CGSizeMake(20.0, 22.0);
        UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
        format.opaque = NO;
        format.scale = 0.0;
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
        markImage = [renderer imageWithActions:^(__unused UIGraphicsImageRendererContext *rendererContext) {
            [[UIColor whiteColor] setFill];
            [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(7.5, 2.0, 5.0, 18.0) cornerRadius:2.5] fill];
            [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(2.0, 8.5, 16.0, 5.0) cornerRadius:2.5] fill];
        }];
    });
    return markImage;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.fillGradient = [CAGradientLayer layer];
        self.fillGradient.colors = @[
            (__bridge id)[UIColor colorWithRed:205.0/255.0 green:255.0/255.0 blue:199.0/255.0 alpha:1.0].CGColor,
            (__bridge id)[UIColor colorWithRed:66.0/255.0 green:252.0/255.0 blue:244.0/255.0 alpha:1.0].CGColor,
        ];
        self.fillGradient.startPoint = CGPointMake(0.0, 0.5);
        self.fillGradient.endPoint = CGPointMake(1.0, 0.5);
        [self.layer insertSublayer:self.fillGradient atIndex:0];

        self.layer.cornerRadius = 12.0;
        self.clipsToBounds = YES;

        self.markView = [[UIImageView alloc] initWithImage:[AcapeChamberCreateCapsuleButton createMarkImage]];
        self.markView.contentMode = UIViewContentModeScaleAspectFit;
        self.markView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.markView];

        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.text = AcapeRevealText(AcapeRevealTextKeyChamberCreateAction);
        self.titleLabel.textColor = UIColor.blackColor;
        self.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.titleLabel];

        [NSLayoutConstraint activateConstraints:@[
            [self.markView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12.0],
            [self.markView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [self.markView.widthAnchor constraintEqualToConstant:20.0],
            [self.markView.heightAnchor constraintEqualToConstant:22.0],

            [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.markView.trailingAnchor constant:6.0],
            [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-14.0],
            [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        ]];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, 34.0);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.fillGradient.frame = self.bounds;
    self.fillGradient.cornerRadius = 12.0;
    self.layer.cornerRadius = 12.0;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.alpha = highlighted ? 0.82 : 1.0;
}

@end

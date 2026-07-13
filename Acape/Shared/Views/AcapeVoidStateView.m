#import "AcapeVoidStateView.h"

@interface AcapeVoidStateView ()

@property (nonatomic, strong) UIImageView *mascotView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIStackView *textStack;

@end

@implementation AcapeVoidStateView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.mascotView = [[UIImageView alloc] init];
        self.mascotView.contentMode = UIViewContentModeScaleAspectFit;
        self.mascotView.translatesAutoresizingMaskIntoConstraints = NO;

        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.textColor = UIColor.whiteColor;
        self.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.numberOfLines = 1;

        self.subtitleLabel = [[UILabel alloc] init];
        self.subtitleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.45];
        self.subtitleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
        self.subtitleLabel.numberOfLines = 0;

        self.textStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.titleLabel, self.subtitleLabel]];
        self.textStack.axis = UILayoutConstraintAxisVertical;
        self.textStack.alignment = UIStackViewAlignmentCenter;
        self.textStack.spacing = 8.0;
        self.textStack.translatesAutoresizingMaskIntoConstraints = NO;

        [self addSubview:self.mascotView];
        [self addSubview:self.textStack];

        [NSLayoutConstraint activateConstraints:@[
            [self.mascotView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [self.mascotView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [self.mascotView.widthAnchor constraintEqualToConstant:110.0],
            [self.mascotView.heightAnchor constraintEqualToConstant:105.0],

            [self.textStack.topAnchor constraintEqualToAnchor:self.mascotView.bottomAnchor constant:24.0],
            [self.textStack.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor constant:24.0],
            [self.textStack.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-24.0],
            [self.textStack.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [self.textStack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        ]];
    }
    return self;
}

- (void)configureWithTitle:(NSString *)title
                  subtitle:(NSString *)subtitle
           mascotAssetName:(NSString *)assetName {
    self.titleLabel.text = title;
    self.subtitleLabel.text = subtitle;
    NSString *resolvedAssetName = assetName.length > 0 ? assetName : @"shared_void_mascot";
    self.mascotView.image = [UIImage imageNamed:resolvedAssetName];
    self.mascotView.hidden = self.mascotView.image == nil;
}

@end

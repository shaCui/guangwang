#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AcapeMicRippleHost : UIView

@property (nonatomic, strong, readonly) UIButton *micControl;

- (void)setRippleLive:(BOOL)live;

@end

NS_ASSUME_NONNULL_END

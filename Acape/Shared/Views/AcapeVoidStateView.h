#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AcapeVoidStateView : UIView

- (void)configureWithTitle:(NSString *)title
                  subtitle:(NSString *)subtitle
           mascotAssetName:(nullable NSString *)assetName;

@end

NS_ASSUME_NONNULL_END

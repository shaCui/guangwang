#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 举报: full report screen with selectable reasons and an explanation field.
@interface AcapeFlagScreen : UIViewController

@property (nonatomic, copy, nullable) NSString *reportedMemberName;

@end

NS_ASSUME_NONNULL_END

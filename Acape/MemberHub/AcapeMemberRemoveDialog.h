#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AcapeMemberRemoveDialog : UIViewController

@property (nonatomic, copy, nullable) void (^onConfirm)(void);

@end

NS_ASSUME_NONNULL_END

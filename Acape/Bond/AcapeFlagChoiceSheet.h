#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 举报/拉黑: bottom choice sheet asking to report or block a member.
@interface AcapeFlagChoiceSheet : UIViewController

@property (nonatomic, copy, nullable) void (^onReport)(void);
@property (nonatomic, copy, nullable) void (^onBlock)(void);

@end

NS_ASSUME_NONNULL_END

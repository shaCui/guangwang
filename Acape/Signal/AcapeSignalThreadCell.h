#import <UIKit/UIKit.h>
#import "AcapeSignalThread.h"

NS_ASSUME_NONNULL_BEGIN

@interface AcapeSignalThreadCell : UITableViewCell

+ (CGFloat)rowHeight;
- (void)configureWithThread:(AcapeSignalThread *)thread;

@end

NS_ASSUME_NONNULL_END

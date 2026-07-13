#import <UIKit/UIKit.h>
#import "AcapeChamberRoom.h"

NS_ASSUME_NONNULL_BEGIN

@interface AcapeChamberRoomCell : UITableViewCell

@property (nonatomic, copy, nullable) void (^joinHandler)(void);

+ (CGFloat)rowHeight;
- (void)configureWithRoom:(AcapeChamberRoom *)room;
- (void)setFocused:(BOOL)focused animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END

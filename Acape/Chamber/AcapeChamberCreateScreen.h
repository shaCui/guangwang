#import <UIKit/UIKit.h>

@class AcapeChamberRoom;

NS_ASSUME_NONNULL_BEGIN

@interface AcapeChamberCreateScreen : UIViewController

@property (nonatomic, copy, nullable) void (^roomCreatedHandler)(AcapeChamberRoom *room);

@end

NS_ASSUME_NONNULL_END

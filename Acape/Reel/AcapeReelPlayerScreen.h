#import <UIKit/UIKit.h>
#import "AcapeFeedEntry.h"

NS_ASSUME_NONNULL_BEGIN

/// 视频: full-screen video player with a right-side action rail.
@interface AcapeReelPlayerScreen : UIViewController

- (instancetype)initWithEntry:(AcapeFeedEntry *)entry;
- (void)pausePlaybackForReportFlow;

@end

NS_ASSUME_NONNULL_END

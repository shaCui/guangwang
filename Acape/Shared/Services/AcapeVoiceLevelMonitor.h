#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^AcapeVoiceSpeakingHandler)(BOOL speaking);

@interface AcapeVoiceLevelMonitor : NSObject

- (void)startMonitoringWithHandler:(AcapeVoiceSpeakingHandler)handler;
- (void)stopMonitoring;

@end

NS_ASSUME_NONNULL_END

#import "AcapeVoiceLevelMonitor.h"
#import <AVFoundation/AVFoundation.h>

static float const kAcapeVoiceSpeakThreshold = 0.018f;
static float const kAcapeVoiceSilentThreshold = 0.010f;
static NSInteger const kAcapeVoiceSilentFrameLimit = 8;

@interface AcapeVoiceLevelMonitor ()
@property (nonatomic, copy, nullable) AcapeVoiceSpeakingHandler speakingHandler;
@property (nonatomic, strong, nullable) AVAudioEngine *audioEngine;
@property (nonatomic, assign, getter=isMonitoring) BOOL monitoring;
@property (nonatomic, assign, getter=isSpeaking) BOOL speaking;
@property (nonatomic, assign) NSInteger silentFrameCount;
@end

@implementation AcapeVoiceLevelMonitor

- (void)dealloc {
    [self stopMonitoring];
}

- (void)startMonitoringWithHandler:(AcapeVoiceSpeakingHandler)handler {
    self.speakingHandler = handler;
    if (self.isMonitoring) {
        return;
    }

    AVAudioSession *session = AVAudioSession.sharedInstance;
    switch (session.recordPermission) {
        case AVAudioSessionRecordPermissionGranted:
            [self beginEngineIfNeeded];
            break;
        case AVAudioSessionRecordPermissionDenied:
            break;
        case AVAudioSessionRecordPermissionUndetermined:
            [session requestRecordPermission:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
                        [self beginEngineIfNeeded];
                    }
                });
            }];
            break;
    }
}

- (void)stopMonitoring {
    self.speakingHandler = nil;
    self.silentFrameCount = 0;
    [self setSpeaking:NO forceNotify:YES];

    if (self.audioEngine.isRunning) {
        [self.audioEngine.inputNode removeTapOnBus:0];
        [self.audioEngine stop];
    }
    self.audioEngine = nil;
    self.monitoring = NO;
}

- (void)beginEngineIfNeeded {
    if (self.isMonitoring) {
        return;
    }

    NSError *sessionError = nil;
    AVAudioSession *session = AVAudioSession.sharedInstance;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
                    mode:AVAudioSessionModeVoiceChat
                 options:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth
                   error:&sessionError];
    [session setActive:YES error:nil];
    if (sessionError) {
        return;
    }

    AVAudioEngine *engine = [[AVAudioEngine alloc] init];
    AVAudioInputNode *inputNode = engine.inputNode;
    AVAudioFormat *format = [inputNode outputFormatForBus:0];
    if (!format) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    [inputNode installTapOnBus:0
                    bufferSize:1024
                        format:format
                         block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        float level = [strongSelf levelForBuffer:buffer];
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf processLevel:level];
        });
    }];

    NSError *startError = nil;
    [engine prepare];
    if (![engine startAndReturnError:&startError]) {
        [inputNode removeTapOnBus:0];
        return;
    }

    self.audioEngine = engine;
    self.monitoring = YES;
    self.silentFrameCount = 0;
}

- (float)levelForBuffer:(AVAudioPCMBuffer *)buffer {
    if (!buffer.floatChannelData || buffer.frameLength == 0) {
        return 0.0f;
    }
    float *samples = buffer.floatChannelData[0];
    UInt32 length = buffer.frameLength;
    float sum = 0.0f;
    for (UInt32 index = 0; index < length; index++) {
        float sample = samples[index];
        sum += sample * sample;
    }
    return sqrtf(sum / MAX(length, 1));
}

- (void)processLevel:(float)level {
    if (level >= kAcapeVoiceSpeakThreshold) {
        self.silentFrameCount = 0;
        [self setSpeaking:YES forceNotify:NO];
        return;
    }
    if (level <= kAcapeVoiceSilentThreshold) {
        self.silentFrameCount += 1;
        if (self.silentFrameCount >= kAcapeVoiceSilentFrameLimit) {
            [self setSpeaking:NO forceNotify:NO];
        }
    }
}

- (void)setSpeaking:(BOOL)speaking forceNotify:(BOOL)forceNotify {
    if (!forceNotify && _speaking == speaking) {
        return;
    }
    _speaking = speaking;
    if (self.speakingHandler) {
        self.speakingHandler(speaking);
    }
}

@end

#import "AcapeSignalMessage.h"

@implementation AcapeSignalMessage

+ (instancetype)textMessageWithId:(NSString *)messageId
                             body:(NSString *)body
                       fromViewer:(BOOL)fromViewer
                         timeText:(NSString *)timeText {
    AcapeSignalMessage *message = [[AcapeSignalMessage alloc] init];
    message.messageId = messageId;
    message.kind = AcapeSignalMessageKindText;
    message.body = body;
    message.fromViewer = fromViewer;
    message.timeText = timeText;
    message.voiceSeconds = 0;
    return message;
}

+ (instancetype)voiceMessageWithId:(NSString *)messageId
                           seconds:(NSInteger)seconds
                        fromViewer:(BOOL)fromViewer
                          timeText:(NSString *)timeText {
    AcapeSignalMessage *message = [[AcapeSignalMessage alloc] init];
    message.messageId = messageId;
    message.kind = AcapeSignalMessageKindVoice;
    message.body = @"";
    message.fromViewer = fromViewer;
    message.timeText = timeText;
    message.voiceSeconds = seconds;
    return message;
}

@end

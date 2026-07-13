#import "AcapeSignalThread.h"

@implementation AcapeSignalThread

+ (instancetype)threadWithId:(NSString *)threadId
                  memberName:(NSString *)memberName
             avatarAssetName:(nullable NSString *)avatarAssetName
                 previewText:(NSString *)previewText
                    timeText:(NSString *)timeText
                 unreadCount:(NSInteger)unreadCount
                    messages:(NSArray<AcapeSignalMessage *> *)messages {
    AcapeSignalThread *thread = [[AcapeSignalThread alloc] init];
    thread.threadId = threadId;
    thread.memberName = memberName;
    thread.avatarAssetName = avatarAssetName;
    thread.previewText = previewText;
    thread.timeText = timeText;
    thread.unreadCount = unreadCount;
    thread.messages = [messages mutableCopy] ?: [NSMutableArray array];
    return thread;
}

@end

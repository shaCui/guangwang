#import <Foundation/Foundation.h>
#import "AcapeSignalMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface AcapeSignalThread : NSObject

@property (nonatomic, copy) NSString *threadId;
@property (nonatomic, copy) NSString *memberName;
@property (nonatomic, copy, nullable) NSString *avatarAssetName;
@property (nonatomic, copy) NSString *previewText;
@property (nonatomic, copy) NSString *timeText;
@property (nonatomic, assign) NSInteger unreadCount;
@property (nonatomic, strong) NSMutableArray<AcapeSignalMessage *> *messages;

+ (instancetype)threadWithId:(NSString *)threadId
                  memberName:(NSString *)memberName
             avatarAssetName:(nullable NSString *)avatarAssetName
                 previewText:(NSString *)previewText
                    timeText:(NSString *)timeText
                 unreadCount:(NSInteger)unreadCount
                    messages:(NSArray<AcapeSignalMessage *> *)messages;

@end

NS_ASSUME_NONNULL_END

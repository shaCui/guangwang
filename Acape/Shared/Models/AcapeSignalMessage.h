#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AcapeSignalMessageKind) {
    AcapeSignalMessageKindText,
    AcapeSignalMessageKindVoice,
};

@interface AcapeSignalMessage : NSObject

@property (nonatomic, copy) NSString *messageId;
@property (nonatomic, assign) AcapeSignalMessageKind kind;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, assign) BOOL fromViewer;
@property (nonatomic, copy) NSString *timeText;
@property (nonatomic, assign) NSInteger voiceSeconds;
@property (nonatomic, copy, nullable) NSString *voiceFileName;

+ (instancetype)textMessageWithId:(NSString *)messageId
                             body:(NSString *)body
                       fromViewer:(BOOL)fromViewer
                         timeText:(NSString *)timeText;

+ (instancetype)voiceMessageWithId:(NSString *)messageId
                           seconds:(NSInteger)seconds
                        fromViewer:(BOOL)fromViewer
                          timeText:(NSString *)timeText;

@end

NS_ASSUME_NONNULL_END

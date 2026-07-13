#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AcapeChamberSeat : NSObject
@property (nonatomic, copy, nullable) NSString *occupantName;   // nil = empty seat
@property (nonatomic, copy, nullable) NSString *avatarAssetName;
@property (nonatomic, assign) BOOL micLive;
+ (instancetype)seatWithName:(nullable NSString *)name avatar:(nullable NSString *)avatar;
@end

@interface AcapeChamberChatLine : NSObject
@property (nonatomic, copy) NSString *speakerName;
@property (nonatomic, copy, nullable) NSString *avatarAssetName;
@property (nonatomic, copy) NSString *text;
+ (instancetype)lineWithSpeaker:(NSString *)speaker avatar:(nullable NSString *)avatar text:(NSString *)text;
@end

@interface AcapeChamberRoom : NSObject
@property (nonatomic, copy) NSString *roomId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy, nullable) NSString *coverAssetName;
@property (nonatomic, assign) NSInteger listenerCount;
@property (nonatomic, copy) NSArray<NSString *> *memberDotAssets;
@property (nonatomic, strong) NSMutableArray<AcapeChamberSeat *> *seats;
@property (nonatomic, strong) NSMutableArray<AcapeChamberChatLine *> *chatLines;

+ (instancetype)roomWithId:(NSString *)roomId
                      name:(NSString *)name
            coverAssetName:(nullable NSString *)coverAssetName
             listenerCount:(NSInteger)listenerCount
           memberDotAssets:(NSArray<NSString *> *)memberDotAssets
                     seats:(NSArray<AcapeChamberSeat *> *)seats
                 chatLines:(NSArray<AcapeChamberChatLine *> *)chatLines;
@end

NS_ASSUME_NONNULL_END

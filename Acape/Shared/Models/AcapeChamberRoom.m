#import "AcapeChamberRoom.h"

@implementation AcapeChamberSeat
+ (instancetype)seatWithName:(NSString *)name avatar:(NSString *)avatar {
    AcapeChamberSeat *seat = [[AcapeChamberSeat alloc] init];
    seat.occupantName = name;
    seat.avatarAssetName = avatar;
    return seat;
}
@end

@implementation AcapeChamberChatLine
+ (instancetype)lineWithSpeaker:(NSString *)speaker avatar:(NSString *)avatar text:(NSString *)text {
    AcapeChamberChatLine *line = [[AcapeChamberChatLine alloc] init];
    line.speakerName = speaker;
    line.avatarAssetName = avatar;
    line.text = text;
    return line;
}
@end

@implementation AcapeChamberRoom
+ (instancetype)roomWithId:(NSString *)roomId
                      name:(NSString *)name
            coverAssetName:(NSString *)coverAssetName
             listenerCount:(NSInteger)listenerCount
           memberDotAssets:(NSArray<NSString *> *)memberDotAssets
                     seats:(NSArray<AcapeChamberSeat *> *)seats
                 chatLines:(NSArray<AcapeChamberChatLine *> *)chatLines {
    AcapeChamberRoom *room = [[AcapeChamberRoom alloc] init];
    room.roomId = roomId;
    room.name = name;
    room.coverAssetName = coverAssetName;
    room.listenerCount = listenerCount;
    room.memberDotAssets = memberDotAssets;
    room.seats = [seats mutableCopy];
    room.chatLines = [chatLines mutableCopy];
    return room;
}
@end

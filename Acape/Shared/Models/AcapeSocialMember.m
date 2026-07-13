#import "AcapeSocialMember.h"

@implementation AcapeSocialMember

+ (instancetype)memberWithId:(NSString *)memberId
                 displayName:(NSString *)displayName
             avatarAssetName:(nullable NSString *)avatarAssetName
                      bonded:(BOOL)bonded {
    AcapeSocialMember *member = [[AcapeSocialMember alloc] init];
    member.memberId = memberId;
    member.displayName = displayName;
    member.avatarAssetName = avatarAssetName;
    member.bonded = bonded;
    return member;
}

@end

#import "AcapeMemberProfile.h"

@implementation AcapeMemberProfile

+ (BOOL)supportsSecureCoding {
    return YES;
}

+ (instancetype)profileWithMemberId:(NSString *)memberId
                        displayName:(NSString *)displayName
                    avatarAssetName:(NSString *)avatarAssetName {
    AcapeMemberProfile *profile = [[AcapeMemberProfile alloc] init];
    profile.memberId = memberId;
    profile.displayName = displayName;
    profile.avatarAssetName = avatarAssetName;
    profile.nickname = @"";
    profile.birthday = @"2003-01-01";
    profile.location = @"";
    profile.gender = @"male";
    profile.profileCompleted = NO;
    return profile;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.memberId forKey:@"memberId"];
    [coder encodeObject:self.displayName forKey:@"displayName"];
    [coder encodeObject:self.avatarAssetName forKey:@"avatarAssetName"];
    [coder encodeObject:self.nickname forKey:@"nickname"];
    [coder encodeObject:self.birthday forKey:@"birthday"];
    [coder encodeObject:self.location forKey:@"location"];
    [coder encodeObject:self.gender forKey:@"gender"];
    [coder encodeBool:self.profileCompleted forKey:@"profileCompleted"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _memberId = [coder decodeObjectOfClass:NSString.class forKey:@"memberId"] ?: @"";
        _displayName = [coder decodeObjectOfClass:NSString.class forKey:@"displayName"] ?: @"";
        _avatarAssetName = [coder decodeObjectOfClass:NSString.class forKey:@"avatarAssetName"];
        _nickname = [coder decodeObjectOfClass:NSString.class forKey:@"nickname"] ?: @"";
        _birthday = [coder decodeObjectOfClass:NSString.class forKey:@"birthday"] ?: @"2003-01-01";
        _location = [coder decodeObjectOfClass:NSString.class forKey:@"location"] ?: @"";
        _gender = [coder decodeObjectOfClass:NSString.class forKey:@"gender"] ?: @"male";
        _profileCompleted = [coder decodeBoolForKey:@"profileCompleted"];
    }
    return self;
}

@end

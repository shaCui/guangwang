#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AcapeMemberProfile : NSObject <NSSecureCoding>

@property (nonatomic, copy) NSString *memberId;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy, nullable) NSString *avatarAssetName;
@property (nonatomic, copy, nullable) NSString *nickname;
@property (nonatomic, copy, nullable) NSString *birthday;
@property (nonatomic, copy, nullable) NSString *location;
@property (nonatomic, copy, nullable) NSString *gender;
@property (nonatomic, assign) BOOL profileCompleted;

+ (instancetype)profileWithMemberId:(NSString *)memberId
                        displayName:(NSString *)displayName
                    avatarAssetName:(nullable NSString *)avatarAssetName;

@end

NS_ASSUME_NONNULL_END

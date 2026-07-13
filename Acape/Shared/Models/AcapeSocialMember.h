#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AcapeSocialMember : NSObject

@property (nonatomic, copy) NSString *memberId;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy, nullable) NSString *avatarAssetName;
@property (nonatomic, assign) BOOL bonded;

+ (instancetype)memberWithId:(NSString *)memberId
                 displayName:(NSString *)displayName
             avatarAssetName:(nullable NSString *)avatarAssetName
                      bonded:(BOOL)bonded;

@end

NS_ASSUME_NONNULL_END

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AcapeEchoComment : NSObject

@property (nonatomic, copy) NSString *authorName;
@property (nonatomic, copy, nullable) NSString *avatarAssetName;
@property (nonatomic, copy) NSString *text;

+ (instancetype)commentWithAuthor:(NSString *)author
                           avatar:(nullable NSString *)avatar
                             text:(NSString *)text;

@end

NS_ASSUME_NONNULL_END

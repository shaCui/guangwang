#import "AcapeEchoComment.h"

@implementation AcapeEchoComment

+ (instancetype)commentWithAuthor:(NSString *)author
                           avatar:(nullable NSString *)avatar
                             text:(NSString *)text {
    AcapeEchoComment *comment = [[AcapeEchoComment alloc] init];
    comment.authorName = author;
    comment.avatarAssetName = avatar;
    comment.text = text;
    return comment;
}

@end

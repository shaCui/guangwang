#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const AcapeEchoSheetCountDidChangeNotification;
FOUNDATION_EXPORT NSString * const AcapeEchoSheetEntryIdKey;
FOUNDATION_EXPORT NSString * const AcapeEchoSheetCountKey;

/// 评论区: comment sheet presented over a video.
@interface AcapeEchoSheet : UIViewController

- (instancetype)initWithEntryId:(NSString *)entryId;

@property (nonatomic, copy, nullable) void (^onCountChanged)(NSInteger newCount);
@property (nonatomic, copy, nullable) NSString *entryMemberName;
@property (nonatomic, copy, nullable) NSString *entryMemberAvatarAssetName;

@end

NS_ASSUME_NONNULL_END

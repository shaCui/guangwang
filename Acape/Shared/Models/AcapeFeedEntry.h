#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AcapeFeedEntry : NSObject

@property (nonatomic, copy) NSString *entryId;
@property (nonatomic, copy) NSString *memberName;
@property (nonatomic, copy, nullable) NSString *memberAvatarAssetName;
@property (nonatomic, assign) NSInteger favorCount;
@property (nonatomic, assign) BOOL isFavoredByViewer;
@property (nonatomic, copy) NSString *captionText;
@property (nonatomic, copy, nullable) NSString *coverImageAssetName;
@property (nonatomic, copy, nullable) NSString *seekCoverImageAssetName;
@property (nonatomic, copy, nullable) NSString *localClipFileName;
@property (nonatomic, strong) UIColor *coverTopColor;
@property (nonatomic, strong) UIColor *coverBottomColor;

+ (instancetype)entryWithId:(NSString *)entryId
                 memberName:(NSString *)memberName
        memberAvatarAssetName:(nullable NSString *)memberAvatarAssetName
                 favorCount:(NSInteger)favorCount
           isFavoredByViewer:(BOOL)isFavoredByViewer
                captionText:(NSString *)captionText
          coverImageAssetName:(nullable NSString *)coverImageAssetName
       seekCoverImageAssetName:(nullable NSString *)seekCoverImageAssetName
             localClipFileName:(nullable NSString *)localClipFileName
              coverTopColor:(UIColor *)coverTopColor
           coverBottomColor:(UIColor *)coverBottomColor;

@end

NS_ASSUME_NONNULL_END

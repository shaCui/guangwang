#import "AcapeFeedEntry.h"

@implementation AcapeFeedEntry

+ (instancetype)entryWithId:(NSString *)entryId
                 memberName:(NSString *)memberName
        memberAvatarAssetName:(NSString *)memberAvatarAssetName
                 favorCount:(NSInteger)favorCount
           isFavoredByViewer:(BOOL)isFavoredByViewer
                captionText:(NSString *)captionText
          coverImageAssetName:(NSString *)coverImageAssetName
       seekCoverImageAssetName:(NSString *)seekCoverImageAssetName
             localClipFileName:(NSString *)localClipFileName
              coverTopColor:(UIColor *)coverTopColor
           coverBottomColor:(UIColor *)coverBottomColor {
    AcapeFeedEntry *entry = [[AcapeFeedEntry alloc] init];
    entry.entryId = entryId;
    entry.memberName = memberName;
    entry.memberAvatarAssetName = memberAvatarAssetName;
    entry.favorCount = favorCount;
    entry.isFavoredByViewer = isFavoredByViewer;
    entry.captionText = captionText;
    entry.coverImageAssetName = coverImageAssetName;
    entry.seekCoverImageAssetName = seekCoverImageAssetName;
    entry.localClipFileName = localClipFileName;
    entry.coverTopColor = coverTopColor;
    entry.coverBottomColor = coverBottomColor;
    return entry;
}

@end

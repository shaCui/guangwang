#import <UIKit/UIKit.h>
#import "AcapeFeedEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface AcapeCuratedFeedCell : UICollectionViewCell

@property (nonatomic, copy, nullable) void (^onFavorTap)(void);
@property (nonatomic, copy, nullable) void (^onMoreTap)(void);

- (void)configureWithEntry:(AcapeFeedEntry *)entry;
- (void)configureWithEntry:(AcapeFeedEntry *)entry useSeekCover:(BOOL)useSeekCover;
- (void)configureWithEntry:(AcapeFeedEntry *)entry useSeekCover:(BOOL)useSeekCover showsMoreControl:(BOOL)showsMoreControl;

@end

NS_ASSUME_NONNULL_END

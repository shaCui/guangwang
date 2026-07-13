#import <UIKit/UIKit.h>
#import "AcapeSignalMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface AcapeSignalBubbleCell : UITableViewCell

- (void)configureWithMessage:(AcapeSignalMessage *)message
             partnerAvatar:(nullable NSString *)partnerAvatar
              viewerAvatar:(nullable NSString *)viewerAvatar;
- (void)setVoicePulseActive:(BOOL)active;

@end

NS_ASSUME_NONNULL_END

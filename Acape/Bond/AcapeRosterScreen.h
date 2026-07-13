#import <UIKit/UIKit.h>
#import "AcapeRosterCell.h"
#import "AcapeRevealText.h"

NS_ASSUME_NONNULL_BEGIN

@interface AcapeRosterScreen : UIViewController

- (instancetype)initWithMode:(AcapeRosterMode)mode;
- (instancetype)initWithMembers:(NSArray<AcapeSocialMember *> *)members titleKey:(AcapeRevealTextKey)titleKey;

@end

NS_ASSUME_NONNULL_END

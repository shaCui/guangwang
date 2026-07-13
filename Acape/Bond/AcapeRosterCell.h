#import <UIKit/UIKit.h>
#import "AcapeSocialMember.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AcapeRosterMode) {
    AcapeRosterModeBonding,
    AcapeRosterModeAdmirers,
    AcapeRosterModeCurbed,
};

@interface AcapeRosterCell : UICollectionViewCell

@property (nonatomic, copy, nullable) void (^actionHandler)(void);

- (void)configureWithMember:(AcapeSocialMember *)member mode:(AcapeRosterMode)mode;

@end

NS_ASSUME_NONNULL_END

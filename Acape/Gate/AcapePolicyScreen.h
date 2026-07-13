#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AcapePolicyTab) {
    AcapePolicyTabTerms,
    AcapePolicyTabPrivacy,
};

@interface AcapePolicyScreen : UIViewController

@property (nonatomic, assign) AcapePolicyTab initialTab;
@property (nonatomic, assign) BOOL showsAgreeAction;
@property (nonatomic, copy, nullable) void (^onAgree)(void);

@end

NS_ASSUME_NONNULL_END

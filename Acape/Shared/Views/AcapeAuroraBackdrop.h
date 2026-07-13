#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Shared page backdrop: dark base with a teal aurora gradient across the top
/// plus the corner glow bloom. Matches the Sketch background used across the
/// Signal / Bond / Credit / Chamber / Reel screens (gradient #05444A -> #111317).
@interface AcapeAuroraBackdrop : UIView

@property (nonatomic, assign) BOOL showsGlow;

+ (UIColor *)baseColor;      // #111317
+ (UIColor *)auroraTopColor; // #05444A
+ (UIColor *)cardColor;      // #1F3337
+ (UIColor *)accentColor;    // #42FCF4

@end

NS_ASSUME_NONNULL_END

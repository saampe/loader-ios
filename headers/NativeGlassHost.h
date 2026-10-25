#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
// Main-thread, opt-in native UIKit material. The caller must supply a verified
// transparent host view; no class-name guessing or screen-coordinate placement.
@interface NativeGlassHost : NSObject
+ (BOOL)attachToTransparentHost:(UIView *)host clearStyle:(BOOL)clearStyle;
+ (BOOL)attachToHost:(UIView *)host clearStyle:(BOOL)clearStyle
 allowBackgroundOverride:(BOOL)allowBackgroundOverride;
+ (void)detachFromHost:(UIView *)host;
+ (BOOL)isAttachedToHost:(UIView *)host;
@end
NS_ASSUME_NONNULL_END

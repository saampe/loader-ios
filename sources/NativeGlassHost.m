#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Native Liquid Glass background for a *known* native host view. This class does
// not search Discord's hierarchy or modify unrelated React Native surfaces.
// Attaching to an opaque host is intentionally rejected: it would conceal the
// material behind its own background and falsely suggest that glass was enabled.
@interface NativeGlassHost : NSObject
+ (BOOL)attachToTransparentHost:(UIView *)host clearStyle:(BOOL)clearStyle;
+ (void)detachFromHost:(UIView *)host;
+ (BOOL)isAttachedToHost:(UIView *)host;
@end

@interface UnboundGlassMaterialView : UIVisualEffectView
@property (nonatomic, strong) UIVisualEffect *deferredEffect;
@end

@implementation UnboundGlassMaterialView
- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.window && self.deferredEffect && self.effect != self.deferredEffect)
        self.effect = self.deferredEffect;
}
@end

@implementation NativeGlassHost

static char kNativeGlassHostAssociation;

+ (BOOL)isAttachedToHost:(UIView *)host
{
    if (!host) return NO;
    return objc_getAssociatedObject(host, &kNativeGlassHostAssociation) != nil;
}

+ (void)detachFromHost:(UIView *)host
{
    NSAssert(NSThread.isMainThread, @"NativeGlassHost requires main thread");
    if (!host) return;
    UIVisualEffectView *glass = objc_getAssociatedObject(host, &kNativeGlassHostAssociation);
    [glass removeFromSuperview];
    objc_setAssociatedObject(host, &kNativeGlassHostAssociation, nil, OBJC_ASSOCIATION_ASSIGN);
}

+ (BOOL)attachToTransparentHost:(UIView *)host clearStyle:(BOOL)clearStyle
{
    NSAssert(NSThread.isMainThread, @"NativeGlassHost requires main thread");
    if (!host || !host.window || host.bounds.size.width < 1 || host.bounds.size.height < 1)
        return NO;
    if (![NSThread isMainThread]) return NO;
    if ([self isAttachedToHost:host]) return YES;
    if (@available(iOS 26.0, *))
    {
        UIColor *background = host.backgroundColor;
        if (background)
        {
            CGFloat alpha = CGColorGetAlpha(background.CGColor);
            if (alpha > 0.01) return NO;
        }

        Class glassClass = NSClassFromString(@"UIGlassEffect");
        SEL factory = NSSelectorFromString(@"effectWithStyle:");
        if (![glassClass respondsToSelector:factory]) return NO;
        id (*makeEffect)(id, SEL, NSInteger) =
            (id (*)(id, SEL, NSInteger))[glassClass methodForSelector:factory];
        id effect = makeEffect(glassClass, factory, clearStyle ? 1 : 0);
        if (![effect isKindOfClass:UIVisualEffect.class]) return NO;

        UnboundGlassMaterialView *glass = [[UnboundGlassMaterialView alloc] initWithEffect:nil];
        glass.deferredEffect = (UIVisualEffect *)effect;
        glass.translatesAutoresizingMaskIntoConstraints = YES;
        glass.frame = host.bounds;
        glass.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        glass.cornerConfiguration = [UICornerConfiguration capsuleConfiguration];
        glass.userInteractionEnabled = NO;
        glass.backgroundColor = UIColor.clearColor;
        [host insertSubview:glass atIndex:0];

        objc_setAssociatedObject(host, &kNativeGlassHostAssociation, glass, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return YES;
    }
    return NO;
}

@end

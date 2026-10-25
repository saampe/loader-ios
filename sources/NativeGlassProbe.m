#import <UIKit/UIKit.h>

// Isolated, opt-in visual material probe. It never modifies Discord's React Native
// controls, theme tokens or view hierarchy below the window root.
@interface NativeGlassProbe : NSObject
+ (BOOL)isVisible;
+ (BOOL)toggleForWindow:(UIWindow *)window;
@end

@implementation NativeGlassProbe

static __weak UIView *glassProbeHost = nil;
static UIView *glassProbeContainer = nil;

+ (BOOL)isVisible
{
    return glassProbeContainer != nil && glassProbeContainer.superview != nil;
}

+ (void)removeProbe
{
    [glassProbeContainer removeFromSuperview];
    glassProbeContainer = nil;
    glassProbeHost = nil;
}

+ (BOOL)toggleForWindow:(UIWindow *)window
{
    NSAssert(NSThread.isMainThread, @"Native glass probe must run on main thread");
    if ([self isVisible])
    {
        [self removeProbe];
        return NO;
    }

    if (@available(iOS 26.0, *))
    {
        Class glassClass = NSClassFromString(@"UIGlassEffect");
        if (!glassClass || !window.rootViewController.view)
        {
            NSLog(@"[NativeGlassProbe] UIGlassEffect or host unavailable");
            return NO;
        }

        // Apple's designated Objective-C factory provides an explicit clear glass style.
        // Clear is intentionally used for the proof: regular glass adapts very dark
        // against Discord's titanium/Onyx surfaces, making it look opaque.
        SEL makeGlass = NSSelectorFromString(@"effectWithStyle:");
        if (![glassClass respondsToSelector:makeGlass])
        {
            NSLog(@"[NativeGlassProbe] UIGlassEffect factory unavailable");
            return NO;
        }
        id (*effectFactory)(id, SEL, NSInteger) = (id (*)(id, SEL, NSInteger))[glassClass methodForSelector:makeGlass];
        id effect = effectFactory(glassClass, makeGlass, 1); // UIGlassEffectStyleClear
        if (![effect isKindOfClass:[UIVisualEffect class]])
        {
            NSLog(@"[NativeGlassProbe] Could not construct UIGlassEffect");
            return NO;
        }

        UIView *host = window.rootViewController.view;
        UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 196, 64)];
        container.userInteractionEnabled = NO;
        container.backgroundColor = UIColor.clearColor;
        container.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                    UIViewAutoresizingFlexibleRightMargin |
                                    UIViewAutoresizingFlexibleTopMargin;
        CGFloat bottom = MAX(host.safeAreaInsets.bottom, 16.0);
        container.center = CGPointMake(CGRectGetMidX(host.bounds),
                                       CGRectGetMaxY(host.bounds) - bottom - 180.0);

        UIVisualEffectView *glass = [[UIVisualEffectView alloc] initWithEffect:(UIVisualEffect *)effect];
        glass.frame = container.bounds;
        glass.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                 UIViewAutoresizingFlexibleHeight;
        glass.userInteractionEnabled = NO;
        // Use iOS 26 glass-aware corner geometry, not a CoreAnimation mask.
        glass.cornerConfiguration = [UICornerConfiguration capsuleConfiguration];
        // Avoid clipping the effect renderer, as UIKit manages its own glass mask.
        glass.clipsToBounds = NO;
        [container addSubview:glass];

        UILabel *label = [[UILabel alloc] initWithFrame:container.bounds];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                 UIViewAutoresizingFlexibleHeight;
        label.text = @"Native Liquid Glass";
        label.textColor = UIColor.labelColor;
        label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        label.textAlignment = NSTextAlignmentCenter;
        label.userInteractionEnabled = NO;
        [glass.contentView addSubview:label];

        [host addSubview:container];
        glassProbeHost = host;
        glassProbeContainer = container;
        NSLog(@"[NativeGlassProbe] Displayed native UIGlassEffect in test chip");
        return YES;
    }

    NSLog(@"[NativeGlassProbe] Requires iOS 26 or later");
    return NO;
}

@end

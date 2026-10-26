#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "NativeGlassHost.h"

// Native Liquid Glass background for a *known* native host view. This class does
// not search Discord's hierarchy or modify unrelated React Native surfaces.
// Attaching to an opaque host is intentionally rejected: it would conceal the
// material behind its own background and falsely suggest that glass was enabled.
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
static char kNativeGlassOriginalBackground;
static char kNativeGlassOriginalOpaque;

// A React Native testID is bridged to UIView.accessibilityIdentifier on iOS.
// It provides a stable semantic anchor even if Fabric class names or the
// navigation layout change. Only our namespaced identifiers are permitted.
+ (UIView *)uniqueMarkedHost:(NSString *)identifier
{
    if (![NSThread isMainThread] || ![identifier isKindOfClass:[NSString class]] ||
        ![identifier hasPrefix:@"unbound.glass."] || identifier.length > 96)
        return nil;

    UIView *matched = nil;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes)
    {
        if (![scene isKindOfClass:[UIWindowScene class]] ||
            (scene.activationState != UISceneActivationStateForegroundActive &&
             scene.activationState != UISceneActivationStateForegroundInactive))
            continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows)
        {
            if (window.hidden || window.alpha < 0.01 ||
                window.windowLevel != UIWindowLevelNormal || !window.rootViewController.view)
                continue;

            NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:window.rootViewController.view];
            // Discord screens can have thousands of Fabric nodes. A global
            // 4096-node budget across all windows can omit a valid YouBar
            // marker purely because an unrelated view appeared earlier.
            // Bound each visible app window independently, and refuse if
            // the entire hierarchy cannot be inspected for duplicate IDs.
            NSUInteger windowScanned = 0;
            for (NSUInteger index = 0; index < queue.count && windowScanned < 16384; index++, windowScanned++)
            {
                UIView *view = queue[index];
                if ([view.accessibilityIdentifier isEqualToString:identifier])
                {
                    if (matched) return nil; // ambiguous anchor: fail closed
                    matched = view;
                }
                for (UIView *child in view.subviews)
                {
                    if (queue.count >= 16384) break;
                    [queue addObject:child];
                }
            }
            if (windowScanned >= 16384 || queue.count >= 16384) return nil;
        }
    }
    if (!matched) NSLog(@"[NativeGlassHost] No marked host for %@", identifier);
    return matched;
}

// Diagnostics for the installed Discord hierarchy. Only view geometry,
// component-class names and material state are returned; never view contents.
+ (NSDictionary<NSString *, id> *)diagnosticsForMarkedHost:(NSString *)identifier
{
    if (![NSThread isMainThread])
        return @{ @"reason": @"NOT_MAIN_THREAD" };
    if (![identifier hasPrefix:@"unbound.glass."] || identifier.length > 96)
        return @{ @"reason": @"INVALID_IDENTIFIER" };

    UIView *matched = nil;
    NSUInteger matches = 0;
    NSUInteger inspected = 0;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes)
    {
        if (![scene isKindOfClass:UIWindowScene.class] ||
            (scene.activationState != UISceneActivationStateForegroundActive &&
             scene.activationState != UISceneActivationStateForegroundInactive))
            continue;

        for (UIWindow *window in ((UIWindowScene *)scene).windows)
        {
            if (window.hidden || window.alpha < 0.01 ||
                window.windowLevel != UIWindowLevelNormal || !window.rootViewController.view)
                continue;

            NSMutableArray<UIView *> *queue =
                [NSMutableArray arrayWithObject:window.rootViewController.view];
            for (NSUInteger index = 0; index < queue.count && index < 16384; index++)
            {
                UIView *view = queue[index];
                inspected++;
                if ([view.accessibilityIdentifier isEqualToString:identifier])
                {
                    matches++;
                    matched = view;
                }
                for (UIView *child in view.subviews)
                {
                    if (queue.count >= 16384) break;
                    [queue addObject:child];
                }
            }
            // Never report a unique marker from a partial scan.
            if (queue.count >= 16384)
                return @{ @"reason": @"SCAN_LIMIT",
                          @"inspectedViews": @(inspected),
                          @"matches": @(matches) };
        }
    }

    if (matches != 1 || !matched)
        return @{ @"reason": matches == 0 ? @"ANCHOR_NOT_FOUND" : @"AMBIGUOUS_ANCHOR",
                  @"matches": @(matches), @"inspectedViews": @(inspected) };

    UIVisualEffectView *glass =
        objc_getAssociatedObject(matched, &kNativeGlassHostAssociation);
    CGFloat width = CGRectGetWidth(matched.bounds);
    CGFloat height = CGRectGetHeight(matched.bounds);
    UIColor *background = matched.backgroundColor;
    BOOL opaque = matched.opaque ||
        (background && CGColorGetAlpha(background.CGColor) > 0.01);

    // Flag directly covering opaque RN layers; this is an indication, not a
    // guarantee, that the compositor obscures the underlying glass.
    NSUInteger coveringOpaqueChildren = 0;
    for (UIView *child in matched.subviews)
    {
        if (child == glass || child.hidden || child.alpha < 0.01)
            continue;
        CGRect overlap = CGRectIntersection(child.frame, matched.bounds);
        CGFloat overlapArea = CGRectIsNull(overlap) ? 0 :
            CGRectGetWidth(overlap) * CGRectGetHeight(overlap);
        UIColor *childBackground = child.backgroundColor;
        BOOL childOpaque = child.opaque ||
            (childBackground && CGColorGetAlpha(childBackground.CGColor) > 0.98);
        if (childOpaque && width * height > 0 &&
            overlapArea >= 0.75 * width * height)
            coveringOpaqueChildren++;
    }

    return @{ @"reason": @"ANCHOR_FOUND",
              @"matches": @(matches),
              @"inspectedViews": @(inspected),
              @"viewClass": NSStringFromClass(matched.class) ?: @"unknown",
              @"width": @(width),
              @"height": @(height),
              @"inWindow": @(matched.window != nil),
              @"hostOpaque": @(opaque),
              @"materialAttached": @(glass != nil && glass.superview == matched),
              @"effectActive": @(glass.effect != nil),
              @"coveringOpaqueChildren": @(coveringOpaqueChildren) };
}

+ (BOOL)attachToMarkedHost:(NSString *)identifier clearStyle:(BOOL)clearStyle
 allowBackgroundOverride:(BOOL)allowBackgroundOverride
{
    NSAssert(NSThread.isMainThread, @"Native glass marker search requires main thread");
    UIView *host = [self uniqueMarkedHost:identifier];
    return host && [self attachToHost:host clearStyle:clearStyle
                    allowBackgroundOverride:allowBackgroundOverride];
}

+ (void)detachFromMarkedHost:(NSString *)identifier
{
    NSAssert(NSThread.isMainThread, @"Native glass marker search requires main thread");
    UIView *host = [self uniqueMarkedHost:identifier];
    if (host) [self detachFromHost:host];
}

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
    NSNumber *originalOpaque = objc_getAssociatedObject(host, &kNativeGlassOriginalOpaque);
    if (originalOpaque)
    {
        id originalBackground = objc_getAssociatedObject(host, &kNativeGlassOriginalBackground);
        host.backgroundColor = originalBackground == [NSNull null] ? nil : originalBackground;
        host.opaque = originalOpaque.boolValue;
        objc_setAssociatedObject(host, &kNativeGlassOriginalOpaque, nil, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(host, &kNativeGlassOriginalBackground, nil, OBJC_ASSOCIATION_ASSIGN);
    }
}

+ (BOOL)attachToTransparentHost:(UIView *)host clearStyle:(BOOL)clearStyle
{
    return [self attachToHost:host clearStyle:clearStyle allowBackgroundOverride:NO];
}

+ (BOOL)attachToHost:(UIView *)host clearStyle:(BOOL)clearStyle
 allowBackgroundOverride:(BOOL)allowBackgroundOverride
{
    NSAssert(NSThread.isMainThread, @"NativeGlassHost requires main thread");
    if (!host || !host.window || host.bounds.size.width < 1 || host.bounds.size.height < 1)
        return NO;
    if (![NSThread isMainThread]) return NO;
    // A host can be reused while a React Native screen changes. Never claim
    // success for a stale or detached material layer.
    UIVisualEffectView *existing = objc_getAssociatedObject(host, &kNativeGlassHostAssociation);
    if (existing)
    {
        if (existing.superview == host) return YES;
        objc_setAssociatedObject(host, &kNativeGlassHostAssociation, nil, OBJC_ASSOCIATION_ASSIGN);
    }
    if (@available(iOS 26.0, *))
    {
        UIColor *background = host.backgroundColor;
        BOOL isOpaque = host.opaque || (background && CGColorGetAlpha(background.CGColor) > 0.01);
        if (isOpaque && !allowBackgroundOverride) return NO;
        // Never modify an entire UIWindow or screen-sized React root when a
        // plugin requests a transparent navigation *surface*.
        if (isOpaque && allowBackgroundOverride)
        {
            CGRect area = [host convertRect:host.bounds toView:host.window];
            if ([host isKindOfClass:[UIWindow class]] ||
                area.size.height > MIN(240.0, host.window.bounds.size.height * 0.36) ||
                area.size.width < 72.0 ||
                CGRectIsNull(area) || CGRectIsInfinite(area))
                return NO;
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
        if (isOpaque && allowBackgroundOverride)
        {
            objc_setAssociatedObject(host, &kNativeGlassOriginalBackground,
                                     background ?: (id)[NSNull null], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(host, &kNativeGlassOriginalOpaque,
                                     @(host.opaque), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            host.opaque = NO;
            host.backgroundColor = UIColor.clearColor;
        }
        [host insertSubview:glass atIndex:0];
        // The deferred UIGlassEffect must be committed while its UIKit
        // view is attached to a window. A layout pass is not guaranteed to
        // happen after an already-laid-out RN host receives this child.
        [glass setNeedsLayout];
        [glass layoutIfNeeded];
        if (!glass.effect)
        {
            [glass removeFromSuperview];
            if (isOpaque && allowBackgroundOverride)
            {
                id originalColor = objc_getAssociatedObject(host, &kNativeGlassOriginalBackground);
                host.backgroundColor = originalColor == [NSNull null] ? nil : originalColor;
                NSNumber *oldOpaque = objc_getAssociatedObject(host, &kNativeGlassOriginalOpaque);
                host.opaque = oldOpaque.boolValue;
                objc_setAssociatedObject(host, &kNativeGlassOriginalBackground, nil, OBJC_ASSOCIATION_ASSIGN);
                objc_setAssociatedObject(host, &kNativeGlassOriginalOpaque, nil, OBJC_ASSOCIATION_ASSIGN);
            }
            return NO;
        }

        objc_setAssociatedObject(host, &kNativeGlassHostAssociation, glass, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return YES;
    }
    return NO;
}

@end

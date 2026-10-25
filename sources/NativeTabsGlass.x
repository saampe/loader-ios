#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Only adjusts actual React Native Screens UITabBarController instances.
// UIKit owns the iOS 26+ native Liquid Glass appearance. The tweak cannot
// assign UIGlassEffect to UITabBarAppearance.backgroundEffect (UIBlurEffect only).
// This deliberately never paints an imitation blur over a React Native tab.
@interface RNSTabBarController : UITabBarController
@end

static char kUnboundTabsPreviousStandard;
static char kUnboundTabsPreviousScroll;

static BOOL UnboundTabsGlassEnabled(void)
{
    // Experimental until the actual target and renderer are verified.
    // Fail closed by default; the developer menu can enable it.
    id saved = [[NSUserDefaults standardUserDefaults] objectForKey:@"UnboundNativeTabsGlassEnabled"];
    return saved ? [saved boolValue] : NO;
}

static void UnboundRestoreTabAppearance(UITabBar *bar)
{
    UITabBarAppearance *oldStandard =
        objc_getAssociatedObject(bar, &kUnboundTabsPreviousStandard);
    UITabBarAppearance *oldScroll =
        objc_getAssociatedObject(bar, &kUnboundTabsPreviousScroll);
    if (oldStandard)
    {
        bar.standardAppearance = oldStandard;
        if (@available(iOS 15.0, *)) bar.scrollEdgeAppearance = oldScroll;
    }
    objc_setAssociatedObject(bar, &kUnboundTabsPreviousStandard, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(bar, &kUnboundTabsPreviousScroll, nil, OBJC_ASSOCIATION_ASSIGN);
}

static void UnboundApplyNativeTabAppearance(RNSTabBarController *controller)
{
    if (![NSThread isMainThread] || !controller.view.window) return;
    if (@available(iOS 26.0, *))
    {
        UITabBar *bar = controller.tabBar;
        if (!bar || bar.items.count < 2) return;
        if (!UnboundTabsGlassEnabled())
        {
            UnboundRestoreTabAppearance(bar);
            return;
        }

        UITabBarAppearance *previous =
            objc_getAssociatedObject(bar, &kUnboundTabsPreviousStandard);
        if (!previous)
        {
            objc_setAssociatedObject(bar, &kUnboundTabsPreviousStandard,
                                     [bar.standardAppearance copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            if (@available(iOS 15.0, *))
                objc_setAssociatedObject(bar, &kUnboundTabsPreviousScroll,
                                         [bar.scrollEdgeAppearance copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }

        // Let UIKit's real iOS 26+ system tab bar material be rendered.
        // Explicit backgroundColor/opaque visual settings from Discord can
        // otherwise suppress the system glass renderer.
        UITabBarAppearance *native = [[UITabBarAppearance alloc] init];
        [native configureWithDefaultBackground];
        // Retain the app's item typography/colors (Titanium Blue), only reset
        // the bar background to Apple's supported system material.
        UITabBarAppearance *current = bar.standardAppearance;
        if (current)
        {
            native.stackedLayoutAppearance = [current.stackedLayoutAppearance copy];
            native.inlineLayoutAppearance = [current.inlineLayoutAppearance copy];
            native.compactInlineLayoutAppearance = [current.compactInlineLayoutAppearance copy];
        }
        bar.standardAppearance = native;
        if (@available(iOS 15.0, *)) bar.scrollEdgeAppearance = native;
        bar.translucent = YES;
        NSLog(@"[NativeTabsGlass] Applied system tab glass to active RNSTabBarController");
    }
}

// Native class confirmed in Discord 350.0 Mach-O metadata. This hook is a
// no-op if Discord uses a custom JS tab navigator instead of RNSTabs.
%hook RNSTabBarController

- (void)viewDidAppear:(BOOL)animated
{
    %orig;
    UnboundApplyNativeTabAppearance(self);
}

- (void)updateTabBarAppearance
{
    %orig;
    UnboundApplyNativeTabAppearance(self);
}

%end

// Refresh active controller after the user toggles the native-glass preference.
@interface NativeTabsGlassControl : NSObject
+ (BOOL)isEnabled;
+ (BOOL)toggleAndRefresh;
@end

@implementation NativeTabsGlassControl

+ (BOOL)isEnabled { return UnboundTabsGlassEnabled(); }

+ (BOOL)toggleAndRefresh
{
    NSAssert(NSThread.isMainThread, @"NativeTabsGlassControl requires main thread");
    BOOL enabled = !UnboundTabsGlassEnabled();
    [[NSUserDefaults standardUserDefaults] setBool:enabled
                                          forKey:@"UnboundNativeTabsGlassEnabled"];
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes)
    {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows)
        {
            NSMutableArray<UIViewController *> *queue = [NSMutableArray array];
            if (window.rootViewController) [queue addObject:window.rootViewController];
            for (NSUInteger index = 0; index < queue.count && index < 128; index++)
            {
                UIViewController *candidate = queue[index];
                if ([candidate isKindOfClass:[RNSTabBarController class]])
                    UnboundApplyNativeTabAppearance((RNSTabBarController *)candidate);
                [queue addObjectsFromArray:candidate.childViewControllers];
                if (candidate.presentedViewController)
                    [queue addObject:candidate.presentedViewController];
            }
        }
    }
    return enabled;
}

@end

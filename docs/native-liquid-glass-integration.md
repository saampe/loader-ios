# Native Liquid Glass integration decision (Discord 350 / Unbound)

## Verified in repository (2026-10-25)

- `sources/NativeGlassProbe.m` inserts a real `UIGlassEffect` in a
  `UIVisualEffectView`, attached to Discord's root view, **above** its React
  Native content. It is an isolated overlay, *not* a replacement for Discord's
  navigation or profile panel.
- `sources/DevOverlay.m` owns a separate passthrough `UIWindow`; its developer
  action toggles the glass probe on the underlying Discord root view.
- `sources/NativePluginBridge.mm` already exposes native Objective-C/UIView
  operations and Fabric surface mounting to plugin code. Any proposed native
  bridge extension must retain main-thread UIKit work, ownership/lifetime checks,
  and the existing bridge's security and argument constraints.
- `saampe/discord-themes/titanium-blue-glass-refined/index.js` changes semantic
  colors via `Theme.internal.resolveSemanticColor`; this alone cannot create a
  genuine UIKit glass renderer or guarantee transparency of an RN navigation
  component.
- Native source compiled successfully in GitHub Actions run 40224572428.
  Isolated UIKit simulator run 40225122331 succeeded, including screenshot
  production. **Neither verifies Discord-specific z-order or transparency.**

## Remaining integration blocker

A real glass *background* for an RN control requires a dependable correspondence
between the active RN control and its backing native `UIView`. Root-window
overlays are visually above the controls and may obstruct or distort their
content; placing a view behind an opaque RN background hides the glass instead.
Hard-coded pixel positions and class-name-only searches are unsafe across Discord
navigation changes and iPhone geometry.

Before changing the production navigation, identify a reliable view anchor or
JS-to-native bridge handle, and confirm the panel background can be made
transparent **only for that specific surface** (not global background tokens).
Do not assume the generic Fabric surface API identifies Discord's existing tabs.

## Implementation acceptance gates (no user IPA for these)

1. Show native glass and an opaque RN-like sibling in the standalone simulator;
   verify the stacking model, rounded material corners, light/dark behavior and
   event passthrough from an actual screenshot.
2. Build a main-thread native glass surface whose lifecycle follows an explicit
   anchor view (attach/update/detach), with no permanent UIWindow-level overlay.
3. Restrict background transparency to the identified host surface. Retain
   Titanium Blue for all other Discord screens and semantics.
4. Build and static-check the tweak using the compile-only workflow. Keep an
   opt-out that works when the target view cannot be found.
5. Only propose the user's **single final IPA test** after these checks, while
   explicitly disclosing what the simulator cannot verify.

No Discord IPA was built as part of this analysis.


## Offline Discord 350.0 source inspection (2026-10-25)

The *existing* private Discord 350.0 source IPA was analyzed in the
`saampe/Unbound-iOS` Actions workflow `Inspect Discord Navigation Offline`,
run 40234346725. **No IPA was built or modified, and no phone install was needed.**

Confirmed fixture:
- `Discord.app/main.jsbundle` (68,560,176 bytes)
- `Discord.app/Discord` executable (56,638,176 bytes)
- Both contain navigation-related indicators, including `TabBar`,
  `NavigationContainer`, and React Native markers.
- Crucially, native executable strings include `RNSTabBarController`,
  `RNSTabBarAppearanceCoordinator`, `findTabBarController`, and
  `getTabNavigator:`. This demonstrates that native RNScreens tabs are
  present in the binary, **not** that the active Discord bottom navigation
  actually uses them.

Next: distinguish a live `UITabBarController`/`RNSTabBarController`
from a custom JS/React Native tab implementation. A static string match alone
cannot justify automatically attaching glass. The `NativePlugin.objc.snapshot`
and `findViews` APIs already exist and provide a bounded way to inspect live
native views, if a suitable existing diagnostic channel is available. Do not
force an additional IPA just to capture this.

Offline inspection artifact: private workflow run 40234346725, artifact
`offline-navigation-inspection`. Contains names and counts, not the IPA.

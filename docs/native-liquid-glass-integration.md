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


## Target identification: Discord 350 Hermes bundle (further offline proof)

The existing source IPA contains a Hermes bytecode bundle with identifiable module
names:
- `modules/main_tabs_v2/native/MainNavigator.tsx`
- `modules/main_tabs_v2/native/MainTabsConstants.tsx`
- `modules/main_tabs_v2/native/panels/MainTabsNavigatorPanel.tsx`
- `modules/main_tabs_v2/native/tabs/{guilds,messages,notifications,you}/...`
- `modules/main_tabs_v2/native/you_bar/YouBarStackNavigator.tsx`

It also contains strings `RNSTabsHostIOS`, `RNSTabsScreenIOS`, and
`RNSTabsBottomAccessoryContent`, plus a native `RNSTabBarController` class
in the executable. These are strong leads to investigate with a *runtime*
class-specific check, not evidence that the visible Discord tab bar uses this
class.

The user-facing profile bottom area may instead be owned by a React Native
module under `you_bar` or a custom main-tabs panel. Automatic glass injection
must not assume any one interpretation without an actual mounted-view anchor.

### Critical UIKit distinction

The iOS SDK declares `UITabBarAppearance.backgroundEffect` as
`UIBlurEffect`, **not** `UIVisualEffect`. Assigning `UIGlassEffect`
directly fails Swift compilation. UIKit's default tab-bar appearance may already
use native Liquid Glass. In a uniform-background simulator, an opaque tab-bar
appearance and the default appearance rendered *pixel-identical* in the bottom
navigation area. Therefore merely calling
`configureWithDefaultBackground` is **not** an adequate proof that our code
added Liquid Glass.

A more discriminating simulator test uses an explicit `UIGlassEffect` behind a
transparent native tab bar, with colored patterns in the content and a
same-transparency control. The attempted native-tab appearance override did not produce a material difference
in side-by-side screenshots and was removed from the production loader. No additional Discord IPA should be built for discovery.


### Native tab-bar stacking regression discovered in simulator

Run 40235805881 explicitly inserted a `UIGlassEffect` view as a sibling
*behind* a transparent native `UITabBar`. The native tab-bar icons became
visibly blurred, even though the material's view was geometrically below the
bar. A same-transparency, no-extra-glass screenshot kept icons legible.
This is a compositor/layer interaction and **rules out blindly placing a
second Liquid Glass renderer behind an existing UIKit glass tab bar**.

The ineffective native-tab appearance experiment has been removed.
Safer route: target an actual custom React Native navigation surface using a
view-specific anchor, avoiding native UITabBar's internally managed glass
hierarchy. Confirm actual material by executing `NativeGlassHost.m` in the
isolated simulator; perform no IPA integration until its exact renderer passes.

Source screenshots: `saampe/loader-ios` workflow run 40235805881,
artifact `native-glass-simulator-proof`.


## Direct production-code simulator verification

Run 40236344191 compiled **the same** `sources/NativeGlassHost.m` file used
by the production loader together with a small C ABI shim in an isolated iOS
26 simulator app. The test created a deliberately opaque 320×72 navigation
host, then invoked `attachToHost:clearStyle:allowBackgroundOverride:` with the
override enabled.

The attachment and association-state assertions passed. The captured image
`actual-objc-host-glass.png` shows **visible refraction through an actual
`UIGlassEffect`** and crisp text over a multicolored backdrop; the
`actual-objc-host-baseline.png` control displays a flat opaque surface.
The images' bottom fifth has substantial pixel differences (~47/56/65 mean
RGB channel levels). This establishes that the actual ObjC class works in a
normal UIKit view tree, not merely the Swift approximation.

Still unverified: ownership and stacking of Discord's *actual* navigation
host. A UIKit `UITabBar` must not receive a redundant sibling glass layer,
as shown by the earlier icon-blurring regression. Do not request a new Discord
IPA until a reliable React Native host anchor is obtained.


## Exact Discord floating YouBar component identified (Hermes decompilation)

The full Discord 350 Hermes bytecode was disassembled offline, then its
per-component functions were extracted; no Discord IPA was built or installed.

**Definitive source module:** `modules/main_tabs_v2/native/you_bar/YouBarBackground.tsx`.

Exported default: `React.memo(YouBarBackground)`. Its runtime bytecode,
functions 74806 and 74807, directly calls `Theme.useToken` for two colors:
- `MOBILE_FLOATINGBAR_BACKGROUND`
- `MOBILE_FLOATINGBAR_BACKGROUND_NAMEPLATE` (conditionally used when
  `hasNameplate` is true)

It constructs **`YouBarAnimatedBackground`** (large avatar) or
**`YouBarMaskedBackground`** (regular avatar), passing
`{ barWidth, backgroundColor, avatarSize? }`.

Confirmed related source modules:
- `.../you_bar/YouBar.tsx`, default `React.memo(YouBarThemed)`;
- `.../you_bar/YouBarButton.tsx`, default
  `React.memo(YouBarButton)`;
- `.../you_bar/YouBarFloatingShade.tsx`, default
  `React.memo(YouBarFloatingShade)`.

These are far more precise targets than an RNSTabBarController. The
floating background is a special masked/animated React Native composition,
so replacing an arbitrary parent with a glass view may cover the buttons or
break its shape. Safest plan is to use a **single-semantic-view anchor** and
target only these two floating bar colors, leaving Titanium Blue untouched.
`NativeGlassHost.attachToMarkedHost` is implemented for explicit React Native
`testID` -> `accessibilityIdentifier` targeting and rejects duplicate
markers and unrelated classes.

Hermes evidence: `saampe/Unbound-iOS` Actions run 40237892981,
artifact `discord-navigation-hermes-references`, and the matching
`YouBarBackground_Compiled.hasm` / `YouBarBackground_Fallback.hasm`.

**Remaining risk:** locating the actual final native `UIView` that owns the
masked floating bar background and proving it can be made transparent without
harming its animation. A successful bytecode static analysis is not a runtime
viewport assertion.

## 2026-10-26: YouBar native bridge and lifecycle fixes (next IPA candidate)

The user's installed Discord diagnostic reported `loader.unbound=true`,
`loader.bridge=false`, and no `glassAttachById`, even though the bundled
YouBar plugin and Hermes module were present. This establishes a missing
`NativePlugin` global *in that earlier IPA*, not a failed UIKit shader.

Current integrated loader:
- After successful Unbound JS bundle evaluation, `sources/Unbound.xm` verifies
  the native glass API and re-registers it in the same Hermes runtime if absent.
  It records `__unboundGlassNativeStartup` in the shared diagnostic.
- The bundled `embedded/native-liquid-glass-youbar.js` captures the native
  ObjC host functions at startup and can keep using them if Unbound resets the
  global `NativePlugin` while Metro dependencies load asynchronously.
- Out-of-order native attachment results after unmount now trigger guarded
  cleanup. Stale mounts cannot detach material belonging to a newer marker.
- The external `saampe/discord-themes/native-liquid-glass-youbar/index.js`
  matches the bundled plugin byte-for-byte, with tests covering both late
  attachment and bridge-global disappearance.
- JS verification passed in `saampe/discord-themes` Actions runs
  `40355715084` and `40356097953`. The former confirms late-attach cleanup;
  the latter confirms bridge retention.
- Integrated loader code revision: `6f466692e8217ccccf1803972c4f36f7d21459b3`.
- The private build workflow in `saampe/Unbound-iOS` is pinned to this exact
  integrated revision, but **no new Discord IPA was created** while preparing
  these changes. The normal `main` workflow-file change does not trigger a
  Discord IPA build.

Release gates: require `Verify Native Theme Code` to compile the integrated
loader and stage the byte-identical plugin; the last check was queued at the
time of this note. After that, the next meaningful verification requires a
single test IPA on the user's real device. Use the in-app
`Share Native Glass Diagnostics` report; check `nativeStartup` and
`pluginStatus` separately from `bridgePresent`. An effective material
requires the correct small YouBar anchor, actual UIKit attachment, and a
non-opaque content layer. A simulator or green JS test cannot prove that
Discord's animated/masked YouBar geometry renders correctly on device.

## External plugin override policy (2026-10-26)

Native Unbound loads validated external plugin manifests before starting its
built-in glass JS. If a valid installed plugin has manifest ID
`native-liquid-glass-youbar`, the built-in copy does **not** start.
The external plugin is therefore the single owner of YouBar patching. If it
fails, the original opaque Discord YouBar is preserved instead of having an
uncontrolled second glass plugin attempt to take over.

This selection is made at loader startup. After adding, removing or replacing
the external plugin, **restart Discord** so Unbound re-scans installed plugins.
An installed-but-disabled external plugin can still suppress the bundled
version; removing that plugin folder restores bundled behavior after restart
when `ui.nativeGlassYoubar` remains enabled. A user can disable the built-in
path using the existing `ui.nativeGlassYoubar` setting. No future IPA
rebuild is needed for compatible JavaScript-only plugin changes. Changes to
compiled UIKit/JSI exports still require recompilation.

Plugin source: `saampe/discord-themes/native-liquid-glass-youbar/`.
Integrated loader: `saampe/loader-ios` at
`b2d56da17b07d68a2f36e0596ef5e61d2c9718e8`.
The private IPA workflow is pinned to this same source. This source update
does not build an IPA, and the new native integration has not yet been
device-validated.

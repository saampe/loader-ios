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

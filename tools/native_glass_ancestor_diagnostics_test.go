package main

import (
  "os"
  "strings"
  "testing"
)

// Read-only, content-free native diagnostics are required before any further
// modification to UIKit compositing or another user-facing IPA build.
func TestNativeGlassCompositingDiagnosticContract(t *testing.T) {
  data, err := os.ReadFile("../sources/NativeGlassHost.m")
  if err != nil { t.Fatal(err) }
  src := string(data)
  checks := []string{
    `@"ancestorCompositing": ancestors`,
    `@"effectiveAncestorAlpha": @(effectiveAncestorAlpha)`,
    `@"nativeGlassIsFrontmost": @(nativeGlassIsFrontmost)`,
    `@"nativeGlassIsBackmost": @(nativeGlassIsBackmost)`,
    `@"layerMaskPresent": @(node.layer.mask != nil)`,
    `@"layerOpacity": @(node.layer.opacity)`,
    `@"nativeGlassHasMask": @(glass.layer.mask != nil)`,
  }
  checks = append(checks,
    "if (!self.window || self.effect) return;",
    "effectiveAlpha <= 0.02",
    "self.glassClearStyle ? 1 : 0",
    "self.effect = (UIVisualEffect *)effect;",
    "glass.glassClearStyle = clearStyle",
  )
  for _, value := range checks {
    if !strings.Contains(src, value) { t.Errorf("missing glass safety or diagnostic contract: %s", value) }
  }
  // The pre-layout attach path must not construct the effect. This prevents
  // recurrence of the attached-but-black on-device state.
  if strings.Contains(src, "deferredEffect") {
    t.Error("Do not preconstruct a UIGlassEffect before in-window layout")
  }
  if strings.Contains(src, `@"accessibilityLabel"`) || strings.Contains(src, `@"textContent"`) {
    t.Fatal("view diagnostics must not export user-generated UI content")
  }
}

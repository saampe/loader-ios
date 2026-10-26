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
  for _, value := range checks {
    if !strings.Contains(src, value) { t.Errorf("missing diagnostic: %s", value) }
  }
  if strings.Contains(src, `@"accessibilityLabel"`) || strings.Contains(src, `@"textContent"`) {
    t.Fatal("view diagnostics must not export user-generated UI content")
  }
}

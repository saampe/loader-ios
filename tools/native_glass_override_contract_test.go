package main

import (
    "os"
    "strings"
    "testing"
)

// Prevent future IPA revisions from unintentionally running the bundled and
// separately installed YouBar glass plugins together.
func TestNativeGlassExternalPluginOverrideContract(t *testing.T) {
    header, err := os.ReadFile("../headers/Plugins.h")
    if err != nil { t.Fatal(err) }
    scanner, err := os.ReadFile("../sources/Plugins.m")
    if err != nil { t.Fatal(err) }
    startup, err := os.ReadFile("../sources/Unbound.xm")
    if err != nil { t.Fatal(err) }

    mustContain := func(name, body, needle string) {
        t.Helper()
        if !strings.Contains(body, needle) { t.Errorf("%s lacks expected override contract %q", name, needle) }
    }
    mustContain("header",string(header),"hasInstalledPluginWithId:")
    mustContain("scanner",string(scanner),`[manifest[@"id"] isEqualToString:identifier]`)
    mustContain("scanner",string(scanner),`manifest[@"id"] isKindOfClass:[NSString class]`)
    mustContain("scanner",string(scanner),`[plugins addObject:@{`)
    mustContain("startup",string(startup),`![Plugins hasInstalledPluginWithId:@"native-liquid-glass-youbar"]`)
    mustContain("startup",string(startup),`ui.nativeGlassYoubar`)
}

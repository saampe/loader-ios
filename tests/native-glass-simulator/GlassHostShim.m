#import <UIKit/UIKit.h>
#import "NativeGlassHost.h"

// C ABI for Swift standalone simulator to execute the actual Objective-C
// component shipped in the injected loader. No Discord binary involved.
BOOL UnboundSimulatorAttachGlass(void *hostPointer, BOOL clearStyle, BOOL overrideBackground)
{
    UIView *host = (__bridge UIView *)hostPointer;
    return [NativeGlassHost attachToHost:host clearStyle:clearStyle
                allowBackgroundOverride:overrideBackground];
}

void UnboundSimulatorDetachGlass(void *hostPointer)
{
    [NativeGlassHost detachFromHost:(__bridge UIView *)hostPointer];
}

BOOL UnboundSimulatorIsGlassAttached(void *hostPointer)
{
    return [NativeGlassHost isAttachedToHost:(__bridge UIView *)hostPointer];
}

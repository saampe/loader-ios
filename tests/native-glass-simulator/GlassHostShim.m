#import <UIKit/UIKit.h>
#import "NativeGlassHost.h"

// C ABI for Swift standalone simulator to execute the actual Objective-C
// component shipped in the injected loader. No Discord binary involved.
int UnboundSimulatorAttachGlass(void *hostPointer, int clearStyle, int overrideBackground)
{
    UIView *host = (__bridge UIView *)hostPointer;
    return [NativeGlassHost attachToHost:host clearStyle:(clearStyle != 0)
                allowBackgroundOverride:(overrideBackground != 0)];
}

void UnboundSimulatorDetachGlass(void *hostPointer)
{
    [NativeGlassHost detachFromHost:(__bridge UIView *)hostPointer];
}

int UnboundSimulatorIsGlassAttached(void *hostPointer)
{
    return [NativeGlassHost isAttachedToHost:(__bridge UIView *)hostPointer];
}

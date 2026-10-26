#import "Unbound.h"
#import "LoaderShared.h"

@interface Plugins : NSObject
{
    NSMutableArray *plugins;
}

+ (NSString *)makeJSON;
+ (BOOL)hasInstalledPluginWithId:(NSString *)identifier;
+ (void)init;

@end

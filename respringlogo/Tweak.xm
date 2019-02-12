/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.
*/

#import "../core/ANEMSettingsManager.h"
#import <dlfcn.h>

%ctor {
	if (kCFCoreFoundationVersionNumber > MaxSupportedCFVersion)
        return;
    
    if (objc_getClass("ANEMSettingsManager") == nil){
        dlopen("/usr/lib/TweakInject/AnemoneCore.dylib",RTLD_LAZY);
    }

    [[%c(ANEMSettingsManager) sharedManager] setCGImageHookEnabled:YES];
}
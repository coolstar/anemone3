#import <libhooker.h>
#import <objc/runtime.h>
#import <dlfcn.h>

@interface UIImage(bundle)
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
@end

#import "../core/ANEMSettingsManager.h"
#import "../core/Bundle.h"

/*#define log_data(fmt, ...) \
            do {FILE *f = fopen("/var/mobile/pref-log.txt", "a"); fprintf(f, fmt, __VA_ARGS__);fclose(f);} while(0)*/

static CFArrayRef (*anem_CPBitmapCreateImagesFromPath)(NSString *, NSObject**, void*, void*);
static CFArrayRef (*oldCPBitmapCreateImagesFromPath)(NSString *, NSObject**, void*, void*);

static CFArrayRef CPBitmapCreateImagesFromPath_new(NSString *path, NSObject **icons, void *arg2, void *arg3) {
	CFArrayRef originalImages = oldCPBitmapCreateImagesFromPath(path, icons, arg2, arg3);
	if (originalImages != nil && *icons != nil && [*icons isKindOfClass:[NSArray class]]){
		NSBundle *bundle = [NSBundle anemoneBundleWithFile:path];
		if (bundle){
			CFMutableArrayRef mutableImages = CFArrayCreateMutableCopy(kCFAllocatorDefault, 0, originalImages);

			NSArray *keys = (NSArray *)*icons;
			for (NSString *icon in keys){

				NSString *themedPath = [bundle themedPathForImage:icon];
				if (!themedPath)
					continue;

				UIImage *image = [UIImage imageWithContentsOfFile:themedPath];

				CGImageRef cgImage = [image CGImage];
				if (cgImage == nil)
					continue;
				NSUInteger index = [keys indexOfObject:icon];
				CFArraySetValueAtIndex(mutableImages, index, cgImage);
			}
			return mutableImages;
		}
	}
	return originalImages;
}

%ctor {
	if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Preferences"]){
		if (objc_getClass("ANEMSettingsManager") == nil){
        	dlopen("/usr/lib/TweakInject/AnemoneCore.dylib",RTLD_LAZY);
    	}

		void *appsupport = dlopen("/System/Library/PrivateFrameworks/AppSupport.framework/AppSupport", RTLD_NOW);
		*(void **)(&anem_CPBitmapCreateImagesFromPath) = dlsym(appsupport, "CPBitmapCreateImagesFromPath");
		const struct LHFunctionHook hook = {(void *)anem_CPBitmapCreateImagesFromPath, (void **)&CPBitmapCreateImagesFromPath_new, (void **)&oldCPBitmapCreateImagesFromPath};
		LHHookFunctions(&hook, 1);
	}
}

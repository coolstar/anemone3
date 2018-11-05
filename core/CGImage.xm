#import "ANEMSettingsManager.h"
#import "Bundle.h"
#ifdef NO_SUBSTRATE
	#ifdef USE_SUBSTITUTE
		#import <substitute.h>
		#import <dlfcn.h>
	#else
		#import "../common/fishhook.h"
		#import <dlfcn.h>
	#endif
#else
#import <substrate.h>
#endif

extern "C" {
	void MSHookFunction(void *symbol, void *hook, void **old);
	CGImageRef *CGImageSourceCreateWithFile(NSString *path, NSDictionary *options);
}

CGImageRef *(*oldCGImageSourceCreateWithFile)(NSString *, NSDictionary*);
CGImageRef *(*oldCGImageSourceCreateWithURL)(NSURL *, NSDictionary*);

CGImageRef *newCGImageSourceCreateWithFile(NSString *path, NSDictionary *options){
	if ([[ANEMSettingsManager sharedManager] isCGImageHookEnabled]){
		NSString *themedPath = [path anemoneThemedPath];
		if ([[ANEMSettingsManager sharedManager] onlyLoadThemedCGImages]){
			if (![themedPath hasPrefix:@"/Library/Themes"] && ![themedPath hasPrefix:@"/var/stash/anemonecache"] && ![themedPath hasPrefix:@"/System/Library/PreferenceBundles/VPNPreferences.bundle/"])
				return nil;
		}
		path = themedPath;
	}
	return oldCGImageSourceCreateWithFile(path, options);
}

CGImageRef *newCGImageSourceCreateWithURL(NSURL *url, NSDictionary *options){
	if ([[ANEMSettingsManager sharedManager] isCGImageHookEnabled]){
		if ([url isFileURL])
			url = [NSURL fileURLWithPath:[[url path] anemoneThemedPath]];
		if ([[ANEMSettingsManager sharedManager] onlyLoadThemedCGImages]){
			if (![[url absoluteString] hasPrefix:@"file:///Library/Themes"] && ![[url absoluteString] hasPrefix:@"file:///var/stash/anemonecache"] && ![[url absoluteString] hasPrefix:@"file:///System/Library/PreferenceBundles/VPNPreferences.bundle/"])
				return nil;
		}
	}
	return oldCGImageSourceCreateWithURL(url, options);
}

%ctor {
	if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"org.coolstar.anemone"]){
#ifdef NO_SUBSTRATE
		#ifdef USE_SUBSTITUTE
			struct substitute_function_hook hook[2] = {
				{(void *)&CGImageSourceCreateWithFile, (void **)&newCGImageSourceCreateWithFile, (void **)&oldCGImageSourceCreateWithFile},
				{(void *)&CGImageSourceCreateWithURL, (void **)&newCGImageSourceCreateWithURL, (void **)&oldCGImageSourceCreateWithURL}
			};
			substitute_hook_functions(hook, 2, NULL, SUBSTITUTE_NO_THREAD_SAFETY);
		#else
			rebind_symbols((struct rebinding[2]){
				{"CGImageSourceCreateWithFile", (void *)newCGImageSourceCreateWithFile, (void **)&oldCGImageSourceCreateWithFile},
				{"CGImageSourceCreateWithURL", (void *)newCGImageSourceCreateWithURL, (void **)&oldCGImageSourceCreateWithURL}
			},2);
		#endif
#else
		MSHookFunction((void *)&CGImageSourceCreateWithFile, (void **)&newCGImageSourceCreateWithFile, (void **)&oldCGImageSourceCreateWithFile);
		MSHookFunction((void *)&CGImageSourceCreateWithURL, (void **)&newCGImageSourceCreateWithURL, (void **)&oldCGImageSourceCreateWithURL);
#endif
	}
}
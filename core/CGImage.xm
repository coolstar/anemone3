#import "ANEMSettingsManager.h"
#import "Bundle.h"
#import <libhooker.h>

extern "C" {
	CGImageRef *CGImageSourceCreateWithFile(NSString *path, NSDictionary *options);
}

static CGImageRef *(*oldCGImageSourceCreateWithFile)(NSString *, NSDictionary*);
static CGImageRef *(*oldCGImageSourceCreateWithURL)(NSURL *, NSDictionary*);

static CGImageRef *newCGImageSourceCreateWithFile(NSString *path, NSDictionary *options){
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

static CGImageRef *newCGImageSourceCreateWithURL(NSURL *url, NSDictionary *options){
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
		struct LHFunctionHook hook[2] = {
			{(void *)&CGImageSourceCreateWithFile, (void **)&newCGImageSourceCreateWithFile, (void **)&oldCGImageSourceCreateWithFile},
			{(void *)&CGImageSourceCreateWithURL, (void **)&newCGImageSourceCreateWithURL, (void **)&oldCGImageSourceCreateWithURL}
		};
		LHHookFunctions(hook, 2);
	}
}
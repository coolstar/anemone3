#import "ANEMSettingsManager.h"
#import "Bundle.h"

static NSMutableDictionary *cachedBundles = nil;

@implementation NSBundle (Anemone)
+ (NSBundle *) anemoneBundleWithFile:(NSString *)path {
	path = [path stringByDeletingLastPathComponent];
	if (path == nil || [path length] == 0 || [path isEqualToString:@"/"])
		return nil;
	NSBundle *bundle = nil;
	if (!cachedBundles)
		cachedBundles = [[NSMutableDictionary alloc] initWithCapacity:5];

	bundle = [cachedBundles objectForKey:path];
	if ((NSNull *)bundle == [NSNull null])
		return nil;
	else if (bundle == nil){
		if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:@"Info.plist"]])
			bundle = [NSBundle bundleWithPath:path];
		if (bundle == nil)
			bundle = [NSBundle anemoneBundleWithFile:path];
		[cachedBundles setObject:(bundle == nil ? [NSNull null] : bundle) forKey:path];
	}
	return bundle;
}

- (NSString *)themedPathForImage:(NSString *)image {
	if (kCFCoreFoundationVersionNumber > MaxSupportedCFVersion)
		return nil;

	NSString *themesDir = [[ANEMSettingsManager sharedManager] themesDir];
	NSString *bundleIdentifier = [self bundleIdentifier];

	NSArray *themes = [[ANEMSettingsManager sharedManager] themeSettings];
	NSArray *searchExtensions = @[@"@3x.png", @"@3x~iphone.png", @"@2x.png", @"@2x~iphone.png", @".png", @"~iphone.png"];
	if ([[ANEMSettingsManager sharedManager] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
		searchExtensions = @[@"@3x.png", @"@2x~ipad.png", @"@2x.png", @"~ipad.png", @".png"];
	}

	for (NSString *theme in themes){
		NSString *path = [NSString stringWithFormat:@"%@/%@/Bundles/%@/%@.png",themesDir,theme,bundleIdentifier,image];

		for (NSString *searchExtension in searchExtensions){
			NSString *fileEnding = [image stringByAppendingString:searchExtension];

			NSString *searchPath = [NSString stringWithFormat:@"%@/%@/Bundles/%@/%@",themesDir,theme,bundleIdentifier,fileEnding];

			if ([[NSFileManager defaultManager] fileExistsAtPath:searchPath])
				return path;
		}
	}
	return nil;
}
@end

@implementation NSString (Anemone)
- (NSString *) anemoneThemedPath {
	if (kCFCoreFoundationVersionNumber > MaxSupportedCFVersion)
		return self;

	NSString *themesDir = [[ANEMSettingsManager sharedManager] themesDir];

	if ([self hasPrefix:themesDir])
		return self;
	if ([self hasSuffix:@".artwork"])
		return self;
	if ([self hasSuffix:@".car"])
		return self;

	NSString *fullPath = [self stringByResolvingSymlinksInPath];
	NSString *fileName = [fullPath lastPathComponent];
	
	NSBundle *bundle = [NSBundle anemoneBundleWithFile:fullPath];
	if ([[ANEMSettingsManager sharedManager] masksOnly]){
		if (![[bundle bundleIdentifier] isEqualToString:@"com.apple.mobileicons.framework"]){
			return self;
		}
	}

	NSString *fileEnding = fileName;
	if (bundle){
		NSString *prefix = [[bundle bundlePath] stringByResolvingSymlinksInPath];
		if ([fullPath hasPrefix:prefix])
			fileEnding = [fullPath substringFromIndex:[prefix length]+1];
	}

	NSArray *themes = [[ANEMSettingsManager sharedManager] themeSettings];

	NSString *folderName = [[fullPath stringByDeletingLastPathComponent] lastPathComponent];
	
	for (NSString *theme in themes)
		{
		if (bundle){
			NSString *path = [NSString stringWithFormat:@"%@/%@/Bundles/%@/%@",themesDir,theme,bundle.bundleIdentifier,fileEnding];
			if ([[NSFileManager defaultManager] fileExistsAtPath:path])
				return path;
		}
		NSString *pathFolders = [NSString stringWithFormat:@"%@/%@/Folders/%@/%@",themesDir,theme,folderName,fileName];
		if ([[NSFileManager defaultManager] fileExistsAtPath:pathFolders])
			return pathFolders;
		NSString *pathFallback = [NSString stringWithFormat:@"%@/%@/Fallback/%@",themesDir,theme,fileName];
		if ([[NSFileManager defaultManager] fileExistsAtPath:pathFallback])
			return pathFallback;
	}
	return self;
}
@end
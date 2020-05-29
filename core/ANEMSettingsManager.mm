#import "ANEMSettingsManager.h"
#import <objc/runtime.h>

#pragma clang diagnostic push 
#pragma clang diagnostic ignored "-Wambiguous-macro"
#if TARGET_IPHONE_SIMULATOR
#define HOMEDIR NSHomeDirectory()
#else
#define HOMEDIR @"/var/mobile"
#endif
#pragma clang diagnostic pop

#define preferenceFilePath [HOMEDIR stringByAppendingPathComponent:@"Library/Preferences/com.anemoneteam.anemone.plist"]

@implementation ANEMSettingsManager
- (instancetype)init {
	self = [super init];
	if (self){
		_CGImageHookEnabled = NO;

		if (!_userDefaults){
			if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.anemoneteam.anemone"])
				_userDefaults = [[NSUserDefaults alloc] init];
			else
				_userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.anemoneteam.anemone"];
		}
	}
	return self;
}

+ (instancetype)sharedManager {
	static ANEMSettingsManager *sharedInstance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});

	return sharedInstance;
}

- (NSString *)themesDir {
#pragma clang diagnostic push 
#pragma clang diagnostic ignored "-Wambiguous-macro"
#if TARGET_IPHONE_SIMULATOR
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
		return @"/Library/Themes/iPad";
	else
		return @"/Library/Themes/iPhone";
#endif
#pragma clang diagnostic pop
	return @"/Library/Themes";
}

- (BOOL)isCGImageHookEnabled {
	return _CGImageHookEnabled;
}

- (void)setCGImageHookEnabled:(BOOL)enabled {
	_CGImageHookEnabled = enabled;
}

- (BOOL)onlyLoadThemedCGImages {
	return _loadOnlyThemedCGImages;
}

- (void)setOnlyLoadThemedCGImages:(BOOL)load {
	_loadOnlyThemedCGImages = load;
}

- (BOOL)masksOnly {
	return NO;
}

- (NSArray *)themeSettings {
	if (kCFCoreFoundationVersionNumber > MaxSupportedCFVersion)
		return nil;

	if (!_themeSettings){
		if (_userDefaults){
			NSArray *themes = [_userDefaults arrayForKey:@"settingsPacked"];
			if (themes){
				_themeSettings = themes;
				return themes;
			}
		}

		NSMutableArray *themes = [[NSMutableArray alloc] init];

		NSDictionary *rawSettings = [NSDictionary dictionaryWithContentsOfFile:preferenceFilePath];

		NSArray *packages = [rawSettings objectForKey:@"packages"];

		for (NSDictionary *package in packages){
			NSArray *packageThemes = [package objectForKey:@"themes"];
			for (NSDictionary *theme in packageThemes){
				if ([theme objectForKey:@"name"] && [[theme objectForKey:@"enabled"] boolValue])
					[themes addObject:[theme objectForKey:@"name"]];
			}
		}
		_themeSettings = themes;
	}
	return _themeSettings;
}

- (void)forceReloadNow {
    _themeSettings = nil;
    [self themeSettings];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"AnemoneReloadNotification" object:nil];
}

- (NSInteger)userInterfaceIdiom {
	if (![_userDefaults objectForKey:@"userInterfaceIdiom"]){
		NSDictionary *rawSettings = [NSDictionary dictionaryWithContentsOfFile:preferenceFilePath];
		return [[rawSettings objectForKey:@"userInterfaceIdiom"] integerValue];
	}
	return [_userDefaults integerForKey:@"userInterfaceIdiom"];
}

- (NSInteger)displayScale {
	if (![_userDefaults objectForKey:@"displayScale"]){
		NSDictionary *rawSettings = [NSDictionary dictionaryWithContentsOfFile:preferenceFilePath];
		return [[rawSettings objectForKey:@"displayScale"] integerValue];
	}
	return [_userDefaults integerForKey:@"displayScale"];
}
@end

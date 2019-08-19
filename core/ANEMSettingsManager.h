#define SupportsNoExtensionDir YES
#define MaxSupportedCFVersion 1575.17 // Only support up to iOS 12.2

@interface ANEMSettingsManager : NSObject {
	NSArray *_themeSettings;
	BOOL _CGImageHookEnabled;
	BOOL _loadOnlyThemedCGImages;
	BOOL _optithemeEnabled;

	NSMutableArray *_eventHandlers;

	NSUserDefaults *_userDefaults;
}
+ (instancetype)sharedManager;
- (NSArray *)themeSettings;
- (NSString *)themesDir;
- (void)forceReloadNow;

- (BOOL)onlyLoadThemedCGImages;
- (void)setOnlyLoadThemedCGImages:(BOOL)load;

- (BOOL)isCGImageHookEnabled;
- (void)setCGImageHookEnabled:(BOOL)enabled;

- (BOOL)masksOnly;

- (NSInteger)userInterfaceIdiom;
- (NSInteger)displayScale;
@end

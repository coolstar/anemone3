#define SupportsNoExtensionDir YES
#if __arm64e__
#define MaxSupportedCFVersion 1676.104 // Only support up to iOS 13.5
#else
#define MaxSupportedCFVersion 1699.999 //1677.104 //Only support up to iOS 13.6.1
#endif

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

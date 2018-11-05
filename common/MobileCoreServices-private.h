@interface LSResourceProxy : NSObject
- (NSDictionary *)iconsDictionary;
@end

@interface LSApplicationProxy : LSResourceProxy
+ (LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)arg1;
- (NSURL *)bundleURL;
- (id)_plistValueForKey:(NSString *)key;
- (NSString *)applicationIdentifier;
- (NSString *)localizedName;
- (BOOL)iconIsPrerendered;

- (NSString *)_boundApplicationIdentifier;
- (NSDictionary *)iconsDictionary;
- (void)setAlternateIconName:(NSString *)name withResult:(void (^)(bool success))result;
@end

@interface _LSIconCacheClient : NSObject
+ (instancetype)sharedInstance;
- (void)invalidateCacheEntriesForBundleIdentifier:(NSString *)bundleIdentifier clearAlternateName:(bool)clearAlternateName validationDictionary:(id)arg3;
@end

@interface LSApplicationWorkspace : NSObject
+ (LSApplicationWorkspace *) defaultWorkspace;
- (NSArray *)allInstalledApplications; //7.0 and higher
@end

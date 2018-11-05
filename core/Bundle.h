@interface NSBundle (Anemone)
+ (NSBundle *) anemoneBundleWithFile:(NSString *)path;
- (NSString *)themedPathForImage:(NSString *)image;
@end

@interface NSString (Anemone)
- (NSString *) anemoneThemedPath;
@end
#import "../core/ANEMSettingsManager.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#include <dlfcn.h>
#include <libhooker.h>

static BOOL IBThemesLoaded = NO;
static NSMutableArray *IBActiveThemes = nil;
static NSDictionary *IBActiveOverrides = nil;

#pragma clang diagnostic push 
#pragma clang diagnostic ignored "-Wambiguous-macro"
#if TARGET_IPHONE_SIMULATOR
#define HOMEDIR NSHomeDirectory()
#else
#define HOMEDIR @"/var/mobile"
#endif
#pragma clang diagnostic pop
#define preferenceFilePath [HOMEDIR stringByAppendingPathComponent:@"Library/Preferences/com.anemoneteam.anemone.plist"]

static BOOL OverlayLoaded = NO;
static CGImageRef OverlayImage = nil;
static CGImageRef UnderlayImage = nil;
static CGImageRef UnderlayImageSpringBoard = nil;

@interface IBTheme : NSObject

@property (nonatomic, strong, readonly) NSString *path;
@property (nonatomic, assign) BOOL iconsArePrecomposed;

- (instancetype)initWithPath:(NSString *)path;
+ (void)resetThemes;
@end

@implementation IBTheme

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _path = path;
    }
    return self;
}

+ (void)resetThemes {
    IBActiveThemes = nil;

    IBActiveOverrides = nil;

    OverlayLoaded = NO;
    OverlayImage = nil;
    UnderlayImage = nil;
    UnderlayImageSpringBoard = nil;

    ANEMSettingsManager *settingsManager = [%c(ANEMSettingsManager) sharedManager];
    NSArray *themes = [settingsManager themeSettings];
    NSString *themesDir = [settingsManager themesDir];

    NSMutableArray *IBThemes = [NSMutableArray array];

    IBActiveThemes = [[NSMutableArray alloc] init];

    for (NSString *theme in themes) {

        NSString *path = [NSString stringWithFormat:@"%@/%@", themesDir, theme];
        NSString *iconBundlesPath = [path stringByAppendingPathComponent:@"IconBundles"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:iconBundlesPath]) {
            IBTheme *ibtheme = [[IBTheme alloc] initWithPath:iconBundlesPath];

            NSString *plistPath = [path stringByAppendingPathComponent:@"Info.plist"];
            NSDictionary *themeOptions = [NSDictionary dictionaryWithContentsOfFile:plistPath];
            ibtheme.iconsArePrecomposed = ![themeOptions[@"IB-MaskIcons"] boolValue];

            [IBActiveThemes addObject:ibtheme];
            [IBThemes addObject:iconBundlesPath];
        }
    }

    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.anemoneteam.anemone"]){
        IBActiveOverrides = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"iconOverrides"];
    } else {
        NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:preferenceFilePath];
        IBActiveOverrides = [preferences objectForKey:@"iconOverrides"];
    }
    NSMutableDictionary *_newIBOverrides = [[NSMutableDictionary alloc] init];
    for (NSDictionary *bundleIdentifier in IBActiveOverrides){
        NSString *theme = [[IBActiveOverrides objectForKey:bundleIdentifier] objectForKey:@"theme"];
        if (!theme){
            [_newIBOverrides setObject:[IBActiveOverrides objectForKey:bundleIdentifier] forKey:bundleIdentifier];
            continue;
        }
        if ([themes containsObject:theme]){
            [_newIBOverrides setObject:[IBActiveOverrides objectForKey:bundleIdentifier] forKey:bundleIdentifier];
        }
    }
    IBActiveOverrides = _newIBOverrides;
}

@end

%hook LSBundleRecordBuilder
- (NSDictionary *)iconsDictionaryFromDict:(NSDictionary *)dict {
    NSDictionary *iconDict = %orig;

    if (iconDict){
        NSMutableDictionary *iconDictMutable = [iconDict mutableCopy];
        NSMutableDictionary *altIcons = [[iconDictMutable objectForKey:@"CFBundleAlternateIcons"] mutableCopy];
        if (!altIcons){
            altIcons = [NSMutableDictionary dictionary];
        }
        [altIcons setObject:@{
            @"CFBundleIconFiles":@[
                @"__ANEM_THEMEDICON.png",
                @"__ANEM_THEMEDICON~ipad.png",
                @"__ANEM_THEMEDICON@2x.png",
                @"__ANEM_THEMEDICON@2x~ipad.png"
                ],
            @"UIPrerenderedIcon":@0
        } forKey:@"__ANEM__AltIcon"];
        [iconDictMutable setObject:altIcons forKey:@"CFBundleAlternateIcons"];
        iconDict = iconDictMutable;
    }

    return iconDict;
}

- (NSDictionary *)getIconsDictionaryFromDict:(NSDictionary *)dict {
	NSDictionary *iconDict = %orig;

	if (iconDict){
		NSMutableDictionary *iconDictMutable = [iconDict mutableCopy];
		NSMutableDictionary *altIcons = [[iconDictMutable objectForKey:@"CFBundleAlternateIcons"] mutableCopy];
		if (!altIcons){
			altIcons = [NSMutableDictionary dictionary];
		}
		[altIcons setObject:@{
			@"CFBundleIconFiles":@[
				@"__ANEM_THEMEDICON.png",
				@"__ANEM_THEMEDICON~ipad.png",
				@"__ANEM_THEMEDICON@2x.png",
				@"__ANEM_THEMEDICON@2x~ipad.png"
				],
			@"UIPrerenderedIcon":@0
		} forKey:@"__ANEM__AltIcon"];
		[iconDictMutable setObject:altIcons forKey:@"CFBundleAlternateIcons"];
		iconDict = iconDictMutable;
	}

	return iconDict;
}
%end

static NSString *IBGetThemedIconWithPrefix(NSString *displayIdentifier, NSString *suffix){
	if (!IBThemesLoaded){
        [IBTheme resetThemes];
        IBThemesLoaded = YES;
    }

	if ([IBActiveThemes count] == 0)
        return nil;

    NSDictionary *themeOverride = [IBActiveOverrides objectForKey:displayIdentifier];

    ANEMSettingsManager *settingsManager = [%c(ANEMSettingsManager) sharedManager];

    bool isiPad = ([settingsManager userInterfaceIdiom] == 1);
    int scale = (int)[settingsManager displayScale];

    if ([themeOverride objectForKey:@"name"])
        displayIdentifier = [themeOverride objectForKey:@"name"];

    NSMutableArray *potentialFilenames = [@[
    	[displayIdentifier stringByAppendingString:@"-large.png"], 
    	[displayIdentifier stringByAppendingString:suffix], 
    	[displayIdentifier stringByAppendingString:[suffix stringByAppendingString:@".png"]],
    	] mutableCopy];

    if (scale == 3)
        [potentialFilenames addObject:[displayIdentifier stringByAppendingString:@"@3x.png"]];
    if (isiPad)
        [potentialFilenames addObject:[displayIdentifier stringByAppendingString:@"@2x~ipad.png"]];
    [potentialFilenames addObject:[displayIdentifier stringByAppendingString:@"@2x.png"]];

    for (IBTheme *theme in IBActiveThemes) {
        if ([themeOverride objectForKey:@"theme"]){
            NSString *themeName = [[theme.path stringByDeletingLastPathComponent] lastPathComponent];
            if (![themeName isEqualToString:[themeOverride objectForKey:@"theme"]])
                continue;
        }

        for (NSString *filename in potentialFilenames) {
            NSString *path = [theme.path stringByAppendingPathComponent:filename];

            if ([[NSFileManager defaultManager] fileExistsAtPath:path])
            	return path;
        }
    }
    return nil;
}

static void LoadOverlayImage(){
    if (OverlayLoaded)
        return;

    ANEMSettingsManager *settingsManager = [%c(ANEMSettingsManager) sharedManager];

    bool isiPad = ([settingsManager userInterfaceIdiom] == 1);
    int scale = (int)[settingsManager displayScale];

    CGImageSourceRef overlayImage = nil;
    CGImageSourceRef underlayImage = nil;
    CGImageSourceRef underlayImageSpringBoard = nil;

    NSArray *themes = [settingsManager themeSettings];
    NSString *themesDir = [settingsManager themesDir];
    for (NSString *theme in themes)
    {
        NSArray *deviceNames = @[@"iPhone"];
        if (isiPad){
            deviceNames = @[@"iPad"];
            /*if (MAX([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height) == 1366){ //iPad Pro
                deviceNames = @[@"iPadPro", @"iPad"];
            }*/
        }

        for (NSString *deviceName in deviceNames){
            for (int scaleToLoad = scale; scaleToLoad >= 2; scaleToLoad--){
                if (!overlayImage){
                    NSString *overlayPath = [NSString stringWithFormat:@"%@/%@/AnemoneEffects/%@Overlay@%dx.png",themesDir,theme,deviceName, scaleToLoad];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:overlayPath])
                        overlayImage = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:overlayPath], nil);
                }

                if (!underlayImageSpringBoard){
                    NSString *underlayPath = [NSString stringWithFormat:@"%@/%@/AnemoneEffects/%@UnderlaySpringBoard@%dx.png",themesDir,theme,deviceName, scaleToLoad];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:underlayPath])
                        underlayImageSpringBoard = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:underlayPath], nil);
                }

                if (!underlayImage){
                    NSString *underlayPath = [NSString stringWithFormat:@"%@/%@/AnemoneEffects/%@Underlay@%dx.png",themesDir,theme,deviceName, scaleToLoad];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:underlayPath])
                        underlayImage = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:underlayPath], nil);
                }
            }                

            if (!overlayImage){
                NSString *overlayPath = [NSString stringWithFormat:@"%@/%@/AnemoneEffects/%@Overlay.png",themesDir,theme,deviceName];
                if ([[NSFileManager defaultManager] fileExistsAtPath:overlayPath])
                    overlayImage = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:overlayPath], nil);
            }
                

            if (!underlayImageSpringBoard){
                NSString *underlayPath = [NSString stringWithFormat:@"%@/%@/AnemoneEffects/%@UnderlaySpringBoard.png",themesDir,theme,deviceName];
                if ([[NSFileManager defaultManager] fileExistsAtPath:underlayPath])
                    underlayImageSpringBoard = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:underlayPath], nil);
            }

            if (!underlayImage){
                NSString *underlayPath = [NSString stringWithFormat:@"%@/%@/AnemoneEffects/%@Underlay.png",themesDir,theme,deviceName];
                if ([[NSFileManager defaultManager] fileExistsAtPath:underlayPath])
                    underlayImage = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:underlayPath], nil);
                }
            if (overlayImage && underlayImage)
                break;
        }
        if (overlayImage && underlayImage)
            break;
    }

    if (overlayImage) {
        OverlayImage = CGImageSourceCreateImageAtIndex(overlayImage, 0, nil);
        CFRelease(overlayImage);
    }

    if (underlayImageSpringBoard) {
        UnderlayImageSpringBoard = CGImageSourceCreateImageAtIndex(underlayImageSpringBoard, 0, nil);
        CFRelease(underlayImageSpringBoard);
    }

    if (underlayImage) {
        UnderlayImage = CGImageSourceCreateImageAtIndex(underlayImage, 0, nil);
        if (!UnderlayImageSpringBoard)
            UnderlayImageSpringBoard = CGImageSourceCreateImageAtIndex(underlayImage, 0, nil);
        CFRelease(underlayImage);
    }

    OverlayLoaded = YES;
}

static CGImageRef *(*oldCGImageSourceCreateWithURL)(NSURL *, NSDictionary*);

static CGImageRef *newCGImageSourceCreateWithURL(NSURL *url, NSDictionary *options){
	return oldCGImageSourceCreateWithURL(url, options);
}

static CFURLRef (*oldCFBundleCopyResourceURL)(CFBundleRef, NSString *, NSString *, NSString *);

static CFURLRef newCFBundleCopyResourceURL(CFBundleRef cfbundle, NSString *resourceName, NSString *resourceType, NSString *subDirName){
    //NSBundle *bundle = (NSBundle *)cfbundle;
    NSString *anemPrefix = @"__ANEM_THEMEDICON";

    if ([resourceName hasPrefix:anemPrefix]){
        NSString *bundleIdentifier = (NSString *)CFBundleGetIdentifier(cfbundle);
        if ([bundleIdentifier isEqualToString:@"com.anemoneteam.anemone"])
            bundleIdentifier = @"com.anemonetheming.anemone";

        if ([bundleIdentifier isEqualToString:@"org.coolstar.electra1141"])
            bundleIdentifier = @"org.coolstar.electra1131";

        NSString *filename = IBGetThemedIconWithPrefix(bundleIdentifier, [resourceName substringFromIndex:anemPrefix.length]);
        if (filename)
            return CFURLCopyAbsoluteURL((CFURLRef)[NSURL fileURLWithPath:filename]);
    }
    return oldCFBundleCopyResourceURL(cfbundle, resourceName, resourceType, subDirName);
}

static CFURLRef (*oldCFBundleCopyResourceURLForLocalization)(CFBundleRef, NSString *, NSString *, NSString *, NSString *);

static CFURLRef newCFBundleCopyResourceURLForLocalization(CFBundleRef cfbundle, NSString *resourceName, NSString *resourceType, NSString *subDirName, NSString *localizationName){
    //NSBundle *bundle = (NSBundle *)cfbundle;
    NSString *anemPrefix = @"__ANEM_THEMEDICON";

    if ([resourceName hasPrefix:anemPrefix]){
        NSString *bundleIdentifier = (NSString *)CFBundleGetIdentifier(cfbundle);
        if ([bundleIdentifier isEqualToString:@"com.anemoneteam.anemone"])
            bundleIdentifier = @"com.anemonetheming.anemone";

        if ([bundleIdentifier isEqualToString:@"org.coolstar.electra1141"])
            bundleIdentifier = @"org.coolstar.electra1131";

        NSString *filename = IBGetThemedIconWithPrefix(bundleIdentifier, [resourceName substringFromIndex:anemPrefix.length]);
        if (filename)
            return CFURLCopyAbsoluteURL((CFURLRef)[NSURL fileURLWithPath:filename]);
    }
    return oldCFBundleCopyResourceURLForLocalization(cfbundle, resourceName, resourceType, subDirName, localizationName);
}

static bool isRenderingIcon = false;

static void (*oldCGContextSetFillColor)(CGContextRef, CGFloat *);

static void newCGContextSetFillColor(CGContextRef c, CGFloat *components){
    if (isRenderingIcon) {
        CGFloat newComponents[4] = {0, 0, 0, 0};
        oldCGContextSetFillColor(c, newComponents);
    } else {
        oldCGContextSetFillColor(c, components);
    }
}

CGImageRef LICreateIconForImages(CFArrayRef, int, int);

static CGImageRef (*oldLICreateIconForImages)(CFArrayRef, int, int);

static int displayScale = 0;

static CGImageRef newLICreateIconForImages(CFArrayRef images, int variant, int precomposed){
    isRenderingIcon = true;

    /* Variant List (Home Screen)
    iPhone @2x: 15 [120x120]
    iPhone @2x (XR): 79 [128x128]
    iPad @2x: 24
    iPhone @3x: 32 [180x180]
    iPhone @3x (XS Max): 80 [192x192]
    iPad @3x: 24
    iPad @2x (small): 32775

    XR and 11 shows up as 80 on iOS 13+ ???
    */

    if (variant == 80){
        int scale = displayScale;
        if (scale == 0){
            ANEMSettingsManager *settingsManager = [%c(ANEMSettingsManager) sharedManager];
            displayScale = (int)[settingsManager displayScale];
            scale = displayScale;
        }
        variant = 32;

        if (scale == 2)
            variant = 15;
    }

    if (variant == 79)
        variant = 15;

    if (variant == 33)
        variant = 15;

    if (variant == 32775)
        variant = 24;

    CGImageRef rawIcon = oldLICreateIconForImages(images, variant, precomposed);

    size_t width = CGImageGetWidth(rawIcon);
    size_t height = CGImageGetHeight(rawIcon);

    LoadOverlayImage();

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace, kCGImageByteOrder32Little | kCGImageAlphaPremultipliedFirst);

    if ((variant == 15 || variant == 24 || variant == 32) && UnderlayImageSpringBoard){
        CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), UnderlayImageSpringBoard);
    } else if (UnderlayImage){
        CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), UnderlayImage);
    }

    CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), rawIcon);

    if (OverlayImage){
        CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), OverlayImage);
    }

    CGImageRef newIcon = CGBitmapContextCreateImage(ctx);
    CGImageRelease(rawIcon);

    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);

    isRenderingIcon = false;
    return newIcon;
}

%hook ANEMSettingsManager
- (BOOL)masksOnly {
    return YES;
}
%end

static int (*oldLSCheckEntitlementForAuditToken)(void *, NSString *);

static int newLSCheckEntitlementForAuditToken(void *arg0, NSString *entitlement){
    if ([entitlement isEqualToString:@"com.apple.lsapplicationworkspace.rebuildappdatabases"]){
        return 1;
    }

    return oldLSCheckEntitlementForAuditToken(arg0, entitlement);
}

static bool (*oldLIIsURLContainedInDirectory)(NSURL *url, NSURL *url2);
static bool newLIIsURLContainedInDirectory(NSURL *url, NSURL *url2){
    if ([[url absoluteString] hasPrefix:@"file:///Library/Themes/"]){
        return true;
    }
    return oldLIIsURLContainedInDirectory(url, url2);
}

//CGContextFillRect (underlays)

%ctor {
	if (kCFCoreFoundationVersionNumber > MaxSupportedCFVersion)
        return;
    
    if (objc_getClass("ANEMSettingsManager") == nil){
        dlopen("/usr/lib/TweakInject/AnemoneCore.dylib",RTLD_LAZY);
    }

    [[%c(ANEMSettingsManager) sharedManager] setCGImageHookEnabled:YES];

    IBActiveThemes = nil;
    IBActiveOverrides = nil;
    IBThemesLoaded = NO;
	%init();

    const struct LHFunctionHook hook[5] = {
        {(void *)&CGImageSourceCreateWithURL, (void **)&newCGImageSourceCreateWithURL, (void **)&oldCGImageSourceCreateWithURL},
        {(void *)&CGContextSetFillColor, (void **)&newCGContextSetFillColor, (void **)&oldCGContextSetFillColor},

        {(void *)&LICreateIconForImages, (void **)&newLICreateIconForImages, (void **)&oldLICreateIconForImages},
        {(void *)&CFBundleCopyResourceURL, (void **)&newCFBundleCopyResourceURL, (void **)&oldCFBundleCopyResourceURL},
        {(void *)&CFBundleCopyResourceURLForLocalization, (void **)&newCFBundleCopyResourceURLForLocalization, (void **)&oldCFBundleCopyResourceURLForLocalization}
    };
    LHHookFunctions(hook, 5);

    struct libhooker_image *coreServicesImg = LHOpenImage("/System/Library/Frameworks/CoreServices.framework/CoreServices");
    if (coreServicesImg){
        const char *names[1] = {
            "__LSCheckEntitlementForAuditToken"
        };
        void *syms[1];
        LHFindSymbols(coreServicesImg, names, syms, 1);

        const struct LHFunctionHook hook13[1] = {
            {(void *)syms[0], (void **)&newLSCheckEntitlementForAuditToken, (void **)&oldLSCheckEntitlementForAuditToken}
        };
        LHHookFunctions(hook13, 1);

        LHCloseImage(coreServicesImg);
    }

    struct libhooker_image *mobileIconsImage = LHOpenImage("/System/Library/PrivateFrameworks/MobileIcons.framework/MobileIcons");
    if (mobileIconsImage){
        const char *names[1] = {
            "__LIIsURLContainedInDirectory"
        };
        void *syms[1];
        LHFindSymbols(mobileIconsImage, names, syms, 1);

        const struct LHFunctionHook hook135[1] = {
            {(void *)syms[0], (void **)&newLIIsURLContainedInDirectory, (void **)&oldLIIsURLContainedInDirectory}
        };
        LHHookFunctions(hook135, 1);

        LHCloseImage(mobileIconsImage);
    }
}
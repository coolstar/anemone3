#import "core/ANEMSettingsManager.h"

@interface LSApplicationProxy : NSObject
+ (nullable LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)arg1;
- (void)setAlternateIconName:(NSString *)name withResult:(void (^)(bool success))result;
@end

@interface IBTheme : NSObject
+ (void)resetThemes;
@end

static void checkBundle(NSString *bundleIdentifier, NSDictionary *iconNames, NSMutableDictionary *changesRequired){
	NSArray *themes = [[%c(ANEMSettingsManager) sharedManager] themeSettings];
	NSString *themesDir = [[%c(ANEMSettingsManager) sharedManager] themesDir];

	NSString *displayIdentifier = bundleIdentifier;

	if ([displayIdentifier isEqualToString:@"com.anemoneteam.anemone"]){
        displayIdentifier = @"com.anemonetheming.anemone";
    }

    if ([displayIdentifier isEqualToString:@"org.coolstar.electra1141"]){
    	displayIdentifier = @"org.coolstar.electra1131";
	}

    UIImage *icon = nil;
    for (NSString *theme in themes){
	    NSString *ibLargeThemePath = [NSString stringWithFormat:@"%@/%@/IconBundles/%@-large.png", themesDir, theme, displayIdentifier];
	    icon = [UIImage imageWithContentsOfFile:ibLargeThemePath];
	    if (icon == nil) {
		    NSString *ibThemePath = [NSString stringWithFormat:@"%@/%@/IconBundles/%@.png", themesDir, theme, displayIdentifier];
		    icon = [UIImage imageWithContentsOfFile:ibThemePath];
		}
		if (icon){
			break;
		}
	}

	
	if (icon){
		if (![[iconNames objectForKey:bundleIdentifier] isEqualToString:@"__ANEM__AltIcon"]){
			[changesRequired setValue:@(YES) forKey:bundleIdentifier];
		}
	} else {
		if ([[iconNames objectForKey:bundleIdentifier] isEqualToString:@"__ANEM__AltIcon"]){
			[changesRequired setValue:@(NO) forKey:bundleIdentifier];
		}
	}
}

static void forceReloadNow(){
	[[%c(ANEMSettingsManager) sharedManager] forceReloadNow];
	[%c(IBTheme) resetThemes];
}

%hook NSNotificationCenter
+ (void)initialize {
	%orig;
	[[NSNotificationCenter defaultCenter] addObserverForName:@"SBInstalledApplicationsDidChangeNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
        NSDictionary *appChangesDict = notification.userInfo;
        [[%c(ANEMSettingsManager) sharedManager] forceReloadNow];
        NSArray *added = appChangesDict[@"SBInstalledApplicationsAddedBundleIDs"];
        NSArray *modified = appChangesDict[@"SBInstalledApplicationsModifiedBundleIDs"];

        NSDictionary *iconNames = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.lsd.iconNames.plist"];
        
        NSMutableDictionary *changesRequired = [[NSMutableDictionary alloc] init];

        for (NSString *bundleIdentifier in added){
        	checkBundle(bundleIdentifier, iconNames, changesRequired);
        }
        for (NSString *bundleIdentifier in modified){
        	checkBundle(bundleIdentifier, iconNames, changesRequired);
        }

        for (NSString *bundleIdentifier in changesRequired){
    		LSApplicationProxy *app = [LSApplicationProxy applicationProxyForIdentifier:bundleIdentifier];
    		if ([changesRequired[bundleIdentifier] boolValue]){
    			[app setAlternateIconName:@"__ANEM__AltIcon" withResult:^(BOOL success){}];
    		} else {
    			[app setAlternateIconName:nil withResult:^(BOOL success){}];
    		}
    	}
    }];

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)forceReloadNow, CFSTR("com.anemoneteam.anemone/reload"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}
%end
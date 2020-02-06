#import <stdio.h>
#import <unistd.h>
#import <getopt.h>
#import <spawn.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import "../common/MobileCoreServices-private.h"

#pragma clang diagnostic push 
#pragma clang diagnostic ignored "-Wambiguous-macro"
#if TARGET_IPHONE_SIMULATOR
#define HOMEDIR NSHomeDirectory()
#else
#define HOMEDIR @"/var/mobile"
#endif
#pragma clang diagnostic pop

static NSString *const kANEMMobileCachesURL = @"file:///var/mobile/Library/Caches";
static NSString *const kANEMContainersSystem = @"file:///var/containers/Shared/SystemGroup";
static NSString *const kANEMCacheContainer = @"systemgroup.com.apple.lsd.iconscache/Library/Caches/";

typedef NS_ENUM(NSUInteger, ANEMRecacheExitReason) {
	ANEMRecacheExitReasonSuccess,
	ANEMRecacheExitReasonFailedEnumeration,
	ANEMRecacheExitReasonFailedRemoving
};

void help(char *name);
void killProcess(char *process);
BOOL clearCaches(BOOL verbose);

extern char **environ;

int run_cmd(const char *cmd)
{
    pid_t pid;
    const char *argv[] = {"sh", "-c", cmd, NULL};
    int status;
    status = posix_spawn(&pid, "/bin/sh", NULL, NULL, (char * const *)argv, NULL);
    if (status == 0) {
        if (waitpid(pid, &status, 0) != -1) {
            return status;
        } else {
            return -1;
        }
    } else {
        return -1;
    }
}

int main(int argc, char *argv[]) {
	@autoreleasepool {
		int noRespring = 0, verbose = 0;

		struct option longOptions[] = {
			{ "no-respring", no_argument, &noRespring, 'n' },
			{ "verbose", no_argument, &verbose, 'v' },
			{ "help", no_argument, NULL, '?' },
			{ NULL, 0, NULL, 0 }
		};

		int index = 0, code = 0;

		while ((code = getopt_long(argc, argv, "h", longOptions, &index)) != -1) {
			switch (code) {
				case 0:
				case 'n':
				case 'v':
					break;

				case 'h':
				default:
					help(argv[0]);
					return ANEMRecacheExitReasonSuccess;
					break;
			}
		}

		BOOL hadError = clearCaches(verbose);

		if (!noRespring) {
			run_cmd("/usr/bin/sbreload"); //sbreload works with uikittools-ng :)
		}

		return hadError ? ANEMRecacheExitReasonFailedRemoving : ANEMRecacheExitReasonSuccess;
	}
}

void help(char *name) {
	printf(
		"Usage: %s [OPTION...]\n"
		"Clear iOS image caches and restart SpringBoard.\n\n"

		"  --no-respring   Don't restart SpringBoard and backboardd after\n"
		"                  clearing caches.\n"
		"  --verbose       Display cache names as they are deleted.\n"
		"  --help          Give this help list.\n\n"

		"Email the Anemone team via Cydia for support.\n", name);
}

BOOL clearCaches(BOOL verbose) {
	LSApplicationProxy *proxy = [LSApplicationProxy applicationProxyForIdentifier:@"com.apple.Preferences"];

	static NSArray *CacheItems;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		CacheItems = @[
			@"com.anemonetheming.CarCache", //car file cache
			@"com.apple.IconsCache", @"SpringBoardIconCache", @"SpringBoardIconCache-small", // icon caches
			@"com.apple.newsstand", // 5.0+ newsstand graphics
			@"com.apple.UIStatusBar", // 6.0+ status bar graphics
			@"BarDialer", @"BarDialer_selected", @"BarRecents", @"BarRecents_selected", @"BarVM", @"BarVM_selected", // 6.0+ phone app tab bar
			@"com.apple.keyboards", //keyboard fonts cache
			@"Weather/MiniIcons", // weather icons cache
			@"MappedImageCache/NCUIMappedImageCache", //notifications cache
			@"MappedImageCache/Persistent" //control center, media controls
		];
	});

	printf("Clearing image caches.\n");

	NSFileManager *fileManager = [NSFileManager defaultManager];

	NSArray *cacheURLs = [NSArray arrayWithObjects:kANEMMobileCachesURL,[NSString stringWithFormat:@"%@/%@",kANEMContainersSystem,kANEMCacheContainer],nil];

	BOOL hadError = NO;

	for (NSString *cacheURL in cacheURLs){
		NSError *error = nil;
		NSArray *items = [fileManager contentsOfDirectoryAtURL:[NSURL URLWithString:cacheURL] includingPropertiesForKeys:nil options:kNilOptions error:&error];

		if (error) {
			NSLog(@"Failed to enumerate %@. The error was: %@.", cacheURL, error);
			return ANEMRecacheExitReasonFailedEnumeration;
		}

		for (NSURL *item in items) {
			NSString *name = item.pathComponents.lastObject;

			if ([name hasPrefix:@"com.apple.springboard"] || [name hasPrefix:@"com.apple.SpringBoard"] || [CacheItems containsObject:name]) {
				NSError *deleteError = nil;
				[fileManager removeItemAtURL:item error:&deleteError];

				if (deleteError) {
					NSLog(@"Failed to remove %@. The error was: %@.", item, deleteError);
					hadError = YES;
				} else if (verbose) {
					printf("Removed %s\n", item.absoluteString.UTF8String);
				}
			}
		}
	}

	// TODO: allow themes to provide custom cache delete paths

	run_cmd("/usr/bin/killall -KILL lsd lsdiconservice iconservicesagent");

	if (![[[proxy iconsDictionary] objectForKey:@"CFBundleAlternateIcons"] objectForKey:@"__ANEM__AltIcon"]){
		run_cmd("/usr/bin/uicache -a");
	}


	return hadError;
}

#import <iostream>
#import <string>
#import <objc/runtime.h>

void showHelp();
void listCar(int argc, char **argv);
void dumpFile(int argc, char **argv);
void dumpFiles(int argc, char **argv);

@interface _UIAssetManager : NSObject
+ (_UIAssetManager *)assetManagerForBundle:(NSBundle *)bundle;
@property (readonly) NSBundle *bundle;
@property (readonly) NSString *carFileName;
- (UIImage *)imageNamed:(NSString *)name;
@end

int main(int argc, char **argv, char **envp) {
	std::cout << "Car-Dump Version 1.0 for ThemeLib\n";
	std::cout << "© 2014, CoolStar. All Rights Reserved\n";
	if (argc < 3){
		showHelp();
		return 0;
	}
	if (strcmp(argv[1],"--help") == 0){
		showHelp();
		return 0;
	}
	if (strcmp(argv[1],"--list") == 0){
		listCar(argc,argv);
		return 0;
	}
	if (argc < 4){
		showHelp();
		return 0;
	}
	if (strcmp(argv[1],"--dump") == 0){
		dumpFile(argc,argv);
		return 0;
	}
	if (strcmp(argv[1],"--dumpall") == 0){
		dumpFiles(argc,argv);
		return 0;
	}
	return 0;
}

void showHelp(){
	std::cout << "USAGE: cardump [OPTION] [PATH TO OUTPUT] [PATH TO CAR FILE]";
	std::cout << "\n";
	std::cout << "--help					Show this Help Screen.\n";
	std::cout << "--list					List the file names of the car file.\n";
	std::cout << "--dumpall [DIRECTORY]		Dump All images to specified folder.\n";
	std::cout << "--dump [FILE]				Dump specific image to the current directory.\n";
}

void listCar(int argc, char **argv){
	const char *rawCarFilePath = argv[2];
	@autoreleasepool {
		NSString *carFilePath = [NSString stringWithUTF8String:rawCarFilePath];
		if (![carFilePath hasPrefix:@"/"]){
			carFilePath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:carFilePath];
		}
		if (![[NSFileManager defaultManager] fileExistsAtPath:carFilePath]){
			std::cout << "Error: ";
			std::cout << [carFilePath UTF8String];
			std::cout << " does not exist!\n";
			return;
		}
		NSString *bundlePath = [carFilePath stringByDeletingLastPathComponent];
		_UIAssetManager *manager = [objc_getClass("_UIAssetManager") assetManagerForBundle:[NSBundle bundleWithPath:bundlePath]];
		std::cout << "Listing contents of car file with name: ";
		std::cout << [manager.carFileName UTF8String];
		std::cout << " \n";
		std::cout << "Bundle Path: ";
		std::cout << [[manager.bundle bundlePath] UTF8String];
		std::cout << "\n";
		std::cout << "\n";
		NSArray *imageNames = [manager valueForKeyPath:@"catalog.themeStore.store.allRenditionNames"];
		for (NSString *imageName in imageNames){
			std::cout << [imageName UTF8String];
			std::cout << "\n";
		}
		std::cout << "\n";
	}
}

void dumpFile(int argc, char **argv){
	const char *rawCarFilePath = argv[3];
	const char *rawImageName = argv[2];
	@autoreleasepool {
		NSString *carFilePath = [NSString stringWithUTF8String:rawCarFilePath];
		if (![carFilePath hasPrefix:@"/"]){
			carFilePath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:carFilePath];
		}
		NSString *imageName = [NSString stringWithUTF8String:rawImageName];
		if (![imageName hasSuffix:@".png"])
			imageName = [imageName stringByAppendingString:@".png"];
		NSString *imageFilePath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:imageName];
		if (![[NSFileManager defaultManager] fileExistsAtPath:carFilePath]){
			std::cout << "Error: ";
			std::cout << [carFilePath UTF8String];
			std::cout << " does not exist!\n";
			return;
		}
		NSString *bundlePath = [carFilePath stringByDeletingLastPathComponent];
		_UIAssetManager *manager = [objc_getClass("_UIAssetManager") assetManagerForBundle:[NSBundle bundleWithPath:bundlePath]];
		std::cout << "Dumping from car file with name: ";
		std::cout << [manager.carFileName UTF8String];
		std::cout << " \n";
		std::cout << "Bundle Path: ";
		std::cout << [[manager.bundle bundlePath] UTF8String];
		std::cout << "\n";
		std::cout << "Dumping: ";
		std::cout << [imageName UTF8String];
		std::cout << "\n";
		if ([manager imageNamed:imageName]){
			UIImage *image = [manager imageNamed:imageName];
			NSData *data = UIImagePNGRepresentation(image);
			[data writeToFile:imageFilePath atomically:YES];
			std::cout << "Image dumped successfully!\n";
		} else {
			std::cout << "Error: Image not found in car.\n";
		}
		std::cout << "\n";
	}
}

void dumpFiles(int argc, char **argv){
	const char *rawCarFilePath = argv[3];
	const char *rawDirectoryName = argv[2];
	@autoreleasepool {
		NSString *carFilePath = [NSString stringWithUTF8String:rawCarFilePath];
		if (![carFilePath hasPrefix:@"/"]){
			carFilePath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:carFilePath];
		}
		NSString *directoryPath = [NSString stringWithUTF8String:rawDirectoryName];
		if (![directoryPath hasPrefix:@"/"])
			directoryPath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:directoryPath];
		if (![[NSFileManager defaultManager] fileExistsAtPath:carFilePath]){
			std::cout << "Error: ";
			std::cout << [carFilePath UTF8String];
			std::cout << " does not exist!\n";
			return;
		}
		if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath]){
			[[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
		}
		NSString *bundlePath = [carFilePath stringByDeletingLastPathComponent];
		_UIAssetManager *manager = [objc_getClass("_UIAssetManager") assetManagerForBundle:[NSBundle bundleWithPath:bundlePath]];
		std::cout << "Dumping from car file with name: ";
		std::cout << [manager.carFileName UTF8String];
		std::cout << " \n";
		std::cout << "Bundle Path: ";
		std::cout << [[manager.bundle bundlePath] UTF8String];
		std::cout << "\n";
		NSArray *imageNames = [manager valueForKeyPath:@"catalog.themeStore.store.allRenditionNames"];
		for (NSString *imageName in imageNames){
			if (![imageName hasSuffix:@".png"])
				imageName = [imageName stringByAppendingString:@".png"];
			NSString *imageFilePath = [directoryPath stringByAppendingPathComponent:imageName];
			std::cout << "Dumping: ";
			std::cout << [imageName UTF8String];
			std::cout << "\n";
			if ([manager imageNamed:imageName]){
				UIImage *image = [manager imageNamed:imageName];
				NSData *data = UIImagePNGRepresentation(image);
				[data writeToFile:imageFilePath atomically:YES];
				std::cout << "Image dumped successfully!\n";
			} else {
				std::cout << "Error: Image not found in car.\n";
			}
		}
		std::cout << "\n";
	}
}

// vim:ft=objc
#import "../core/Bundle.h"

@interface UIImage(Private)
- (UIImage *)_applicationIconImageForFormat:(int)arg1 precomposed:(BOOL)arg2 scale:(CGFloat)arg3;
@end

%group SpringBoard
%hook SBClockApplicationIconImageView
- (UIImage *)contentsImage {
	UIImage *ret = [%c(UIImage) imageWithContentsOfFile:[[NSBundle mainBundle] themedPathForImage:@"ClockIconBackgroundSquare"]];
	if (ret != nil){
		ret = [ret _applicationIconImageForFormat:2 precomposed:NO scale:[%c(UIScreen) mainScreen].scale];
	} else {
		ret = %orig;
	}
	return ret;
}
// Always make sure you clean up after yourself; Not doing so could have grave consequences!
%end
%end

%ctor {
	if (objc_getClass("SBClockApplicationIconImageView") != nil){
		%init(SpringBoard);
	}
}
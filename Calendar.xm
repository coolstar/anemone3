#import "core/ANEMSettingsManager.h"
#import "UIColor+HTMLColors.h"
#import <dlfcn.h>

@interface ISConcreteImage : NSObject
- (instancetype)initWithCGImage:(CGImageRef)cgImage scale:(CGFloat)scale minimumSize:(CGSize)minimumSize placeholder:(BOOL)placeholder;
- (CGImageRef) cgImage;
@end

@interface ISImageDescriptor : NSObject
- (instancetype)initWithSize:(CGSize)size scale:(CGFloat)scale;
- (void)setShouldApplyMask:(BOOL)applyMask;
@end

@interface ISIcon : NSObject
- (instancetype) initWithBundleIdentifier:(NSString *)bundleIdentifier;
- (ISConcreteImage *) imageForImageDescriptor:(ISImageDescriptor *)descriptor;
@end

@interface SBCalendarApplicationIcon : NSObject
- (UIFont *)numberFont;
- (UIColor *)colorForDayOfWeek;
- (void)drawTextIntoCurrentContextWithImageSize:(CGSize)imageSize iconBase:(UIImage *)base;
@end

static NSDictionary *dateSettings, *daySettings;

static CGFloat dateXoffset = 0.0f;
static CGFloat dateYoffset = 0.0f;
static CGFloat dateShadowXoffset = 0.0f;
static CGFloat dateShadowYoffset = 0.0f;
static CGFloat dateShadowBlurRadius = 0.0f;
static UIColor *dateTextColor = nil;
static NSString *dateTextCase = nil;
static UIColor *dateShadowColor = nil;

static NSString *dayFont = nil;
static CGFloat dayFontSize = 10.0f;
static CGFloat dayXoffset = 0.0f;
static CGFloat dayYoffset = 0.0f;
static CGFloat dayShadowXoffset = 0.0f;
static CGFloat dayShadowYoffset = 0.0f;
static CGFloat dayShadowBlurRadius = 0.0f;
static NSString *dayTextCase = nil;
static UIColor *dayShadowColor = nil;

static void getCalendarSettings(){
	dateSettings = nil;
	daySettings = nil;

	NSArray *themes = [[%c(ANEMSettingsManager) sharedManager] themeSettings];
	NSString *themesDir = [[%c(ANEMSettingsManager) sharedManager] themesDir];

	for (NSString *theme in themes)
	{
		NSString *path = [NSString stringWithFormat:@"%@/%@/Info.plist",themesDir,theme];
		NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfFile:path];
		if (dateSettings == nil)
		{
			dateSettings = themeDict[@"CalendarIconDateSettings"];
		}
		if (daySettings == nil){
			daySettings = themeDict[@"CalendarIconDaySettings"];
		}
		if (!(dateSettings == nil || [dateSettings isKindOfClass:[NSDictionary class]]) || !(daySettings == nil || [daySettings isKindOfClass:[NSDictionary class]])){
			dateSettings = nil;
			daySettings = nil;
		}
	}
}

static void loadCalendarSettings(){
	getCalendarSettings();

	dateXoffset = 0.0f;
	dateYoffset = 0.0f;
	dateShadowXoffset = 0.0f;
	dateShadowYoffset = 0.0f;
	dateShadowBlurRadius = 0.0f;
	dateTextColor = nil;
	dateShadowColor = nil;
	dateTextCase = nil;

	dayFont = nil;
	dayFontSize = 10.0f;
	dayXoffset = 0.0f;
	dayYoffset = 0.0f;
	dayShadowXoffset = 0.0f;
	dayShadowYoffset = 0.0f;
	dayShadowBlurRadius = 0.0f;
	dayShadowColor = nil;
	dayTextCase = nil;

	dateTextColor = [UIColor blackColor];
	dateShadowColor = [UIColor clearColor];

	dayFont = @".SFUIText-Medium";
	dayShadowColor = [UIColor clearColor];

	if ([[dateSettings objectForKey:@"TextXoffset"] isKindOfClass:[NSNumber class]])
		dateXoffset = [[dateSettings objectForKey:@"TextXoffset"] floatValue];
	if ([[dateSettings objectForKey:@"TextYoffset"] isKindOfClass:[NSNumber class]])
		dateYoffset = [[dateSettings objectForKey:@"TextYoffset"] floatValue];
	if ([[dateSettings objectForKey:@"TextColor"] isKindOfClass:[NSString class]])
		dateTextColor = [UIColor anem_colorWithCSS:[dateSettings objectForKey:@"TextColor"]];
	if ([[dateSettings objectForKey:@"TextCase"] isKindOfClass:[NSString class]])
		dateTextCase = [[dateSettings objectForKey:@"TextCase"] lowercaseString];
	if ([[dateSettings objectForKey:@"ShadowXoffset"] isKindOfClass:[NSNumber class]])
		dateShadowXoffset = [[dateSettings objectForKey:@"ShadowXoffset"] floatValue];
	if ([[dateSettings objectForKey:@"ShadowYoffset"] isKindOfClass:[NSNumber class]])
		dateShadowYoffset = [[dateSettings objectForKey:@"ShadowYoffset"] floatValue];
	if ([[dateSettings objectForKey:@"ShadowBlurRadius"] isKindOfClass:[NSNumber class]])
		dateShadowBlurRadius = [[dateSettings objectForKey:@"ShadowBlurRadius"] floatValue];
	if ([[dateSettings objectForKey:@"ShadowColor"] isKindOfClass:[NSString class]])
		dateShadowColor = [UIColor anem_colorWithCSS:[dateSettings objectForKey:@"ShadowColor"]];

	if ([[daySettings objectForKey:@"FontName"] isKindOfClass:[NSString class]])
		dayFont = [daySettings objectForKey:@"FontName"];
	if ([[daySettings objectForKey:@"FontSize"] isKindOfClass:[NSNumber class]])
		dayFontSize = [[daySettings objectForKey:@"FontSize"] floatValue];
	if ([[daySettings objectForKey:@"TextCase"] isKindOfClass:[NSString class]])
		dayTextCase = [[daySettings objectForKey:@"TextCase"] lowercaseString];
	if ([[daySettings objectForKey:@"TextXoffset"] isKindOfClass:[NSNumber class]])
		dayXoffset = [[daySettings objectForKey:@"TextXoffset"] floatValue];
	if ([[daySettings objectForKey:@"TextYoffset"] isKindOfClass:[NSNumber class]])
		dayYoffset = [[daySettings objectForKey:@"TextYoffset"] floatValue];
	if ([[daySettings objectForKey:@"ShadowXoffset"] isKindOfClass:[NSNumber class]])
		dayShadowXoffset = [[daySettings objectForKey:@"ShadowXoffset"] floatValue];
	if ([[daySettings objectForKey:@"ShadowYoffset"] isKindOfClass:[NSNumber class]])
		dayShadowYoffset = [[daySettings objectForKey:@"ShadowYoffset"] floatValue];
	if ([[daySettings objectForKey:@"ShadowBlurRadius"] isKindOfClass:[NSNumber class]])
		dayShadowBlurRadius = [[daySettings objectForKey:@"ShadowBlurRadius"] floatValue];
	if ([[daySettings objectForKey:@"ShadowColor"] isKindOfClass:[NSString class]])
		dayShadowColor = [UIColor anem_colorWithCSS:[daySettings objectForKey:@"ShadowColor"]];

	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
		dateYoffset+=14.0f;
		dayYoffset+=8.0f;
	} else{
		dateYoffset+=12.0f;
		dayYoffset+=6.0f;
	}
}

%hook SBCalendarApplicationIcon
- (UIImage *)_compositedIconImageForFormat:(int)format withBaseImageProvider:(UIImage *(^)())imageProvider {
	UIImage *baseImage = imageProvider();
	UIGraphicsBeginImageContextWithOptions(baseImage.size, NO, baseImage.scale);
	[self drawTextIntoCurrentContextWithImageSize:baseImage.size iconBase:baseImage];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

%new;
- (void)drawTextIntoCurrentContextWithImageSize:(CGSize)imageSize iconBase:(UIImage *)base {
	loadCalendarSettings();

	CGContextRef ctx = UIGraphicsGetCurrentContext();
	if (ctx == nil)
		return;
	[base drawInRect:CGRectMake(0,0,imageSize.width,imageSize.height)];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterNoStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	[dateFormatter setLocale:[NSLocale currentLocale]];

	NSString *dateFont = @".SFUIDisplay-ThinG2";
	CGFloat dateFontSize = 39.5;
	if ([self respondsToSelector:@selector(numberFont)]){
		dateFont = [[self numberFont] fontName];
		dateFontSize = [[self numberFont] pointSize];
	}
	if ([[dateSettings objectForKey:@"FontName"] isKindOfClass:[NSString class]])
		dateFont = [dateSettings objectForKey:@"FontName"];
	if ([[dateSettings objectForKey:@"FontSize"] isKindOfClass:[NSNumber class]])
		dateFontSize = [[dateSettings objectForKey:@"FontSize"] floatValue];

	NSDate *date = [NSDate date];
	[dateFormatter setDateFormat:@"d"];
	NSString *day = [dateFormatter stringFromDate:date];

	if ([dateTextCase isEqualToString:@"lowercase"])
		day = [day lowercaseString];
	else if ([dateTextCase isEqualToString:@"uppercase"])
		day = [day uppercaseString];

	UIFont *numberFont = [UIFont fontWithName:dateFont size:dateFontSize];
	CGSize size = CGSizeZero;
	if (!numberFont)
		numberFont = [UIFont systemFontOfSize:dateFontSize weight:UIFontWeightThin];
	size = [day sizeWithAttributes:@{NSFontAttributeName:numberFont}];

	CGContextSetShadowWithColor(ctx, CGSizeMake(dateShadowXoffset,dateShadowYoffset), dateShadowBlurRadius, dateShadowColor.CGColor);
	CGContextSetAlpha(ctx, CGColorGetAlpha(dateTextColor.CGColor));
	[day drawAtPoint:CGPointMake(dateXoffset + ((imageSize.width-size.width)/2.0f),dateYoffset) withAttributes:@{NSFontAttributeName:numberFont, NSForegroundColorAttributeName:dateTextColor}];

	UIColor *dayTextColor = [UIColor redColor];
	if ([self respondsToSelector:@selector(colorForDayOfWeek)])
		dayTextColor = [self colorForDayOfWeek];
	if ([[daySettings objectForKey:@"TextColor"] isKindOfClass:[NSString class]])
		dayTextColor = [UIColor anem_colorWithCSS:[daySettings objectForKey:@"TextColor"]];

	[dateFormatter setDateFormat:@"EEEE"];
	NSString *dayOfWeek = [dateFormatter stringFromDate:date];

	if ([dayTextCase isEqualToString:@"lowercase"])
		dayOfWeek = [dayOfWeek lowercaseString];
	else if ([dayTextCase isEqualToString:@"uppercase"])
		dayOfWeek = [dayOfWeek uppercaseString];

	UIFont *dayOfWeekFont = [UIFont fontWithName:dayFont size:dayFontSize];
	if (!dayOfWeekFont)
		dayOfWeekFont = [UIFont systemFontOfSize:dayFontSize weight:UIFontWeightMedium];
	size = [dayOfWeek sizeWithAttributes:@{NSFontAttributeName:dayOfWeekFont}];

	CGContextSetShadowWithColor(ctx, CGSizeMake(dayShadowXoffset,dayShadowYoffset), dayShadowBlurRadius, dayShadowColor.CGColor);

	CGContextSetAlpha(ctx, CGColorGetAlpha(dayTextColor.CGColor));
	[dayOfWeek drawAtPoint:CGPointMake(dayXoffset + ((imageSize.width-size.width)/2.0f),dayYoffset) withAttributes:@{NSFontAttributeName:dayOfWeekFont, NSForegroundColorAttributeName:dayTextColor}];
}
%end

static UIImage *lastCalendarImage = nil;

%hook CUIKIcon
- (ISConcreteImage *)imageForImageDescriptor:(ISImageDescriptor *)descriptor{
	%orig;
	ISConcreteImage *newImage = [[%c(ISConcreteImage) alloc] initWithCGImage:[lastCalendarImage CGImage] scale:lastCalendarImage.scale minimumSize:lastCalendarImage.size placeholder:NO];
	return newImage;
}
%end

bool renderImage13(NSDate *date, CGSize imageSize, CGFloat scale){
	loadCalendarSettings();

	CGSize textSize = CGSizeMake(60, 60);
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad){
		textSize = CGSizeMake(72, 72);
	}
	UIGraphicsBeginImageContextWithOptions(textSize, NO, scale);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	if (ctx == nil)
		return false;

	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterNoStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	[dateFormatter setLocale:[NSLocale currentLocale]];

	CGFloat dateFontSize = 39.5;
	if ([[dateSettings objectForKey:@"FontSize"] isKindOfClass:[NSNumber class]])
		dateFontSize = [[dateSettings objectForKey:@"FontSize"] floatValue];

	[dateFormatter setDateFormat:@"d"];
	NSString *day = [dateFormatter stringFromDate:date];

	if ([dateTextCase isEqualToString:@"lowercase"])
		day = [day lowercaseString];
	else if ([dateTextCase isEqualToString:@"uppercase"])
		day = [day uppercaseString];

	UIFont *numberFont = [UIFont systemFontOfSize:dateFontSize];

	CGSize size = CGSizeZero;
	if (numberFont)
		size = [day sizeWithAttributes:@{NSFontAttributeName:numberFont}];

	CGContextSetShadowWithColor(ctx, CGSizeMake(dateShadowXoffset,dateShadowYoffset), dateShadowBlurRadius, dateShadowColor.CGColor);
	CGContextSetAlpha(ctx, CGColorGetAlpha(dateTextColor.CGColor));
	[day drawAtPoint:CGPointMake(dateXoffset + ((textSize.width-size.width)/2.0f),dateYoffset) withAttributes:@{NSFontAttributeName:numberFont, NSForegroundColorAttributeName:dateTextColor}];

	UIColor *dayTextColor = [UIColor redColor];
	if ([[daySettings objectForKey:@"TextColor"] isKindOfClass:[NSString class]])
		dayTextColor = [UIColor anem_colorWithCSS:[daySettings objectForKey:@"TextColor"]];

	[dateFormatter setDateFormat:@"EEEE"];
	NSString *dayOfWeek = [dateFormatter stringFromDate:date];

	if ([dayTextCase isEqualToString:@"lowercase"])
		dayOfWeek = [dayOfWeek lowercaseString];
	else if ([dayTextCase isEqualToString:@"uppercase"])
		dayOfWeek = [dayOfWeek uppercaseString];

	UIFont *dayOfWeekFont = [UIFont systemFontOfSize:dayFontSize];
	if (dayOfWeekFont)
		size = [dayOfWeek sizeWithAttributes:@{NSFontAttributeName:dayOfWeekFont}];

	CGContextSetShadowWithColor(ctx, CGSizeMake(dayShadowXoffset,dayShadowYoffset), dayShadowBlurRadius, dayShadowColor.CGColor);

	CGContextSetAlpha(ctx, CGColorGetAlpha(dayTextColor.CGColor));
	[dayOfWeek drawAtPoint:CGPointMake(dayXoffset + ((textSize.width-size.width)/2.0f),dayYoffset) withAttributes:@{NSFontAttributeName:dayOfWeekFont, NSForegroundColorAttributeName:dayTextColor}];

	UIImage *textImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	UIGraphicsBeginImageContextWithOptions(imageSize, NO, scale);

	ctx = UIGraphicsGetCurrentContext();
	if (ctx == nil)
		return false;

	ISIcon *iconServicesIcon = [[%c(ISIcon) alloc] initWithBundleIdentifier:@"com.apple.mobilecal"];

	ISImageDescriptor *descriptor = [[%c(ISImageDescriptor) alloc] initWithSize:imageSize scale:scale];
	[descriptor setShouldApplyMask:YES];

	ISConcreteImage *rawIcon = [iconServicesIcon imageForImageDescriptor:descriptor];

	UIImage *rawIconUIImage = [UIImage imageWithCGImage:[rawIcon cgImage]];
	[rawIconUIImage drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
	[textImage drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];

	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	lastCalendarImage = newImage;
	return true;
}

%hook CUIKDefaultIconGenerator
- (CGImageRef)iconImageWithDate:(NSDate *)date calendar:(id)calendar format:(NSInteger)format size:(CGSize)imageSize scale:(CGFloat)scale {
	if (!renderImage13(date, imageSize, scale)){
		return nil;
	}
	return %orig;
}

- (CGImageRef)iconImageWithDateComponents:(NSDateComponents *)dateComponents calendar:(NSCalendar *)calendar format:(NSInteger)format size:(CGSize)imageSize scale:(CGFloat)scale {
	if (!renderImage13([calendar dateFromComponents:dateComponents], imageSize, scale)){
		return nil;
	}
	return %orig;
}
%end

%ctor {
	if (kCFCoreFoundationVersionNumber > MaxSupportedCFVersion)
		return;

	if (objc_getClass("ANEMSettingsManager") == nil){
		dlopen("/usr/lib/TweakInject/AnemoneCore.dylib",RTLD_LAZY);
	}
}

#import "NSImage+Size.h"

@implementation NSImage (WB_Size)

+ (NSSize)WB_sizeOfImageAtURL:(NSURL *)inURL
{
	if (inURL==nil)
		return NSZeroSize;
	
	CGImageSourceRef tImageSourceRef=CGImageSourceCreateWithURL((__bridge CFURLRef) inURL, NULL);
	
	if (tImageSourceRef==NULL)
		return NSZeroSize;
	
	CFDictionaryRef tDictionaryRef= CGImageSourceCopyPropertiesAtIndex(tImageSourceRef,0, NULL);
	
	CFRelease(tImageSourceRef);
	
	if (tDictionaryRef==NULL)
		return NSZeroSize;
	
	NSDictionary * tDictionary=(__bridge_transfer NSDictionary *)tDictionaryRef;
	
	NSSize tSize={
		.width=[tDictionary[(__bridge NSString *) kCGImagePropertyPixelWidth] floatValue],
		.height=[tDictionary[(__bridge NSString *) kCGImagePropertyPixelHeight] floatValue]
	};
	
	return tSize;
}

+ (NSSize)WB_sizeOfImageAtPath:(NSString *)inPath
{
	return [NSImage WB_sizeOfImageAtURL:[NSURL fileURLWithPath:inPath]];
}

@end

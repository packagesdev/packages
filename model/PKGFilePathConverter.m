
#import "PKGFilePathConverter.h"

#import "NSString+Packages.h"

@implementation PKGFilePathConverter

- (NSString *)absolutePathForFilePath:(PKGFilePath *)inFilePath
{
	if (inFilePath==nil)
		return nil;
	
	switch(inFilePath.type)
	{
		case PKGFilePathTypeAbsolute:
			
			return inFilePath.string;
			
		case PKGFilePathTypeRelativeToProject:
			
			return [inFilePath.string PKG_stringByAbsolutingWithPath:self.referenceProjectPath];
			
		case PKGFilePathTypeRelativeToReferenceFolder:
			
			return [inFilePath.string PKG_stringByAbsolutingWithPath:self.referenceFolderPath];
			
		default:
			break;
	}
	
	return nil;
}

- (PKGFilePath *)filePathForAbsolutePath:(NSString *)inAbsolutePath type:(PKGFilePathType)inType
{
	if (inAbsolutePath==nil)
		return nil;
	
	if (inType==PKGFilePathTypeAbsolute)
		return [[PKGFilePath alloc] initWithString:inAbsolutePath type:PKGFilePathTypeAbsolute];
	
	NSString * tReferencePath=nil;
	
	if (inType==PKGFilePathTypeRelativeToProject)
	{
		tReferencePath=self.referenceProjectPath;
	}
	else if (inType==PKGFilePathTypeRelativeToReferenceFolder)
	{
		tReferencePath=self.referenceFolderPath;
	}
	
	if (tReferencePath==nil)
	{
		return nil;
	}
	
	NSString * tConvertedPath=[inAbsolutePath PKG_stringByRelativizingToPath:tReferencePath];
	
	if (tConvertedPath==nil)
	{
		return nil;
	}
	
	return [[PKGFilePath alloc] initWithString:tConvertedPath type:inType];
}

- (BOOL)shiftTypeOfFilePath:(PKGFilePath *)inFilePath toType:(PKGFilePathType)inType
{
	if (inFilePath==nil)
		return NO;
	
	if (inFilePath.type==inType)
		return YES;
	
	if (inFilePath.string!=nil)
	{
		NSString * tAbsolutePath=[self absolutePathForFilePath:inFilePath];
		
		if (tAbsolutePath==nil)
			return NO;
		
		PKGFilePath * tFilePath=[self filePathForAbsolutePath:tAbsolutePath type:inType];
		
		if (tFilePath==nil)
			return NO;
		
		inFilePath.string=tFilePath.string;
	}
	
	inFilePath.type=inType;
	
	return YES;
}

@end

/*
 Copyright (c) 2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationBackgroundSettings+Builder.h"

#import "PKGProjectBuilder+PKGBuildEvent.h"
#import "PKGProjectBuilder+Documents.h"

#import "NSFileManager+Packages.h"

#define FILE_HEADER_SAMPLE_LENGTH	32

@implementation PKGPresentationBackgroundSettings (Builder)

+ (NSString *)lazyUTIForImageAtPath:(NSString *)inPath
{
	// Finding out whether a file is a PICT requires to load more bytes than FILE_HEADER_SAMPLE_LENGTH and it would be surprising if a lot of people are still using PICTs for image assets
	// => we don't support PICT at this time.
	
	if (inPath==nil)
		return nil;
	
	NSFileHandle * tFileHandle = [NSFileHandle fileHandleForReadingAtPath:inPath];
	NSData * tFileData = [tFileHandle readDataOfLength:FILE_HEADER_SAMPLE_LENGTH];
	[tFileHandle closeFile];
	
	NSUInteger tDataLength=tFileData.length;
	
	if (tDataLength==0)
		return nil;
	
	static NSDictionary * sKnownFormatMagicNumbers=nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		sKnownFormatMagicNumbers=@{
								   [NSData dataWithBytes:(unsigned char[]){0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A} length:8]:@"public.png",
								   
								   [NSData dataWithBytes:(unsigned char[]){0x49,0x49,0x2A,0x00} length:4]:@"public.tiff",
								   [NSData dataWithBytes:(unsigned char[]){0x4D,0x4D,0x00,0x2A} length:4]:@"public.tiff",
								   
								   [NSData dataWithBytes:(unsigned char[]){0xFF,0xD8,0xFF} length:3]:@"public.jpeg",
								   
								   
								   [NSData dataWithBytes:(unsigned char[]){0x25,0x50,0x44,0x46,0x2d} length:5]:@"com.adobe.pdf",
								   
								   [NSData dataWithBytes:(unsigned char[]){0xC8,0x00,0x79,0x00} length:4]:@"com.adobe.encapsulated-postscript"
								   
								   };
		
	});
	
	for(NSData * tKnownMagicNumber in sKnownFormatMagicNumbers)
	{
		NSUInteger tLength=tKnownMagicNumber.length;
		
		if (tLength>tDataLength)
			continue;
		
		if ([[tFileData subdataWithRange:NSMakeRange(0,tLength)] isEqualToData:tKnownMagicNumber]==YES)
			return sKnownFormatMagicNumbers[tKnownMagicNumber];
	}
	
	return nil;
}


+ (NSString *)elementNameForAppearanceMode:(PKGPresentationAppearanceMode)inAppearanceMode
{
	switch(inAppearanceMode)
	{
		case PKGPresentationAppearanceModeLight:
			
			return @"background";
			
		case PKGPresentationAppearanceModeDark:
			
			return @"background-darkAqua";
			
		default:
			
			break;
	}
	
	return nil;
}

+ (NSString *)proposedFileNameForAppearanceMode:(PKGPresentationAppearanceMode)inAppearanceMode
{
	switch(inAppearanceMode)
	{
		case PKGPresentationAppearanceModeLight:
			
			return @"background";
			
		case PKGPresentationAppearanceModeDark:
			
			return @"background-darkAqua";
			
		default:
			
			break;
	}
	
	return nil;
}

- (NSXMLElement *)projectBuilder:(PKGProjectBuilder *)inProjectBuilder elementForAppearanceMode:(PKGPresentationAppearanceMode)inAppearanceMode settings:(PKGPresentationBackgroundAppearanceSettings *)inAppearanceSettings copiedResourcesRegister:(NSMutableDictionary *)inCopiedResourcesRegister
{
	NSString * tAbsolutePath=[inProjectBuilder absolutePathForFilePath:inAppearanceSettings.imagePath];
	
	if (tAbsolutePath==nil)
	{
		[inProjectBuilder postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAbsolutePathCanNotBeComputed filePath:inAppearanceSettings.imagePath.string fileKind:PKGFileKindRegularFile]];
		
		return nil;
	}
	
	NSFileManager * tFileManager=[NSFileManager defaultManager];
	
	if ([tFileManager fileExistsAtPath:tAbsolutePath]==NO)
	{
		// File does not exist
		
		[inProjectBuilder postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileNotFound filePath:tAbsolutePath fileKind:PKGFileKindRegularFile]];
		
		return nil;
	}
	
	// Find the UTI type of the image file
	
	// A COMPLETER
	
	// Copy the Image to the appropriate location
	
	NSString * tResourcesPath=[inProjectBuilder distributionResources];
	
	if (tResourcesPath==nil)
	{
		// Could not create Resources folder
		
		// A COMPLETER
		
		[inProjectBuilder postCurrentStepFailureEvent:nil];
		
		return nil;
	}
	
	NSString * tAlreadyCopiedFileName=inCopiedResourcesRegister[tAbsolutePath];
	NSString * tSuitableFileName=nil;
	
	if (tAlreadyCopiedFileName==nil)
	{
		NSString * tProposedFileName=[PKGPresentationBackgroundSettings proposedFileNameForAppearanceMode:inAppearanceMode];
	
		tSuitableFileName=[inProjectBuilder suitableFileNameForProposedFileName:tProposedFileName inDirectory:tResourcesPath];
	
		if (tSuitableFileName==nil)
		{
			[inProjectBuilder postCurrentStepFailureEvent:[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileAlreadyExists tag:tProposedFileName]];
		
			// A COMPLETER
		
			return nil;
		}
		
		NSString * tDestinationPath=[tResourcesPath stringByAppendingPathComponent:tSuitableFileName];
		NSError * tError=nil;
		
		if ([tFileManager PKG_copyItemAtPath:tAbsolutePath toPath:tDestinationPath options:PKG_NSDeleteExisting error:NULL]==NO)
		{
			PKGBuildErrorEvent * tErrorEvent=[PKGBuildErrorEvent errorEventWithCode:PKGBuildErrorFileCanNotBeCopied filePath:tAbsolutePath fileKind:PKGFileKindRegularFile];
			tErrorEvent.otherFilePath=tDestinationPath;
			
			if (tError!=nil && [tError.domain isEqualToString:NSCocoaErrorDomain]==YES)
			{
				switch(tError.code)
				{
					case NSFileWriteVolumeReadOnlyError:
						tErrorEvent.subcode=PKGBuildErrorReadOnlyVolume;
						break;
						
					case NSFileWriteNoPermissionError:
						tErrorEvent.subcode=PKGBuildErrorWriteNoPermission;
						break;
						
					case NSFileWriteOutOfSpaceError:
						tErrorEvent.subcode=PKGBuildErrorNoMoreSpaceOnVolume;
						break;
				}
			}
			
			[inProjectBuilder postCurrentStepFailureEvent:tErrorEvent];
			
			return nil;
		}
		
		if ([inProjectBuilder setPosixPermissionsOfDocumentAtPath:tDestinationPath]==NO)
			return nil;
		
		inCopiedResourcesRegister[tAbsolutePath]=tSuitableFileName;
	}
	else
	{
		tSuitableFileName=tAlreadyCopiedFileName;
	}
	
	
	NSString * tElementName=[PKGPresentationBackgroundSettings elementNameForAppearanceMode:inAppearanceMode];
	
	NSXMLElement * tBackgroundElement=(NSXMLElement *) [NSXMLNode elementWithName:tElementName];
	
	// file [required]
	
	id tAttribute=[NSXMLNode attributeWithName:@"file" stringValue:tSuitableFileName];
	[tBackgroundElement addAttribute:tAttribute];
	
	
	// uti [required (but not really)]
	
	NSString * tUTI=[PKGPresentationBackgroundSettings lazyUTIForImageAtPath:tAbsolutePath];
	
	if (tUTI!=nil)
	{
		tAttribute=[NSXMLNode attributeWithName:@"uti" stringValue:tUTI];
		[tBackgroundElement addAttribute:tAttribute];
	}
	
	// scaling [optional]
	
	PKGImageScaling tScaling=inAppearanceSettings.imageScaling;
	
	switch(tScaling)
	{
		case PKGImageScalingProportionnaly:
			
			tAttribute=[NSXMLNode attributeWithName:@"scaling" stringValue:@"proportional"];
			break;
			
		case PKGImageScalingToFit:
			
			tAttribute=[NSXMLNode attributeWithName:@"scaling" stringValue:@"tofit"];
			break;
			
		case PKGImageScalingNone:
			
			tAttribute=[NSXMLNode attributeWithName:@"scaling" stringValue:@"none"];
			break;
	}
	
	[tBackgroundElement addAttribute:tAttribute];
	
	// alignment [optional]
	
	NSString * tAlignmentString=@"";
	
	PKGImageAlignment tAlignment=inAppearanceSettings.imageAlignment;
	
	switch(tAlignment)
	{
		case PKGImageAlignmentCenter:
			
			tAlignmentString=@"center";
			break;
			
		case PKGImageAlignmentTop:
			
			tAlignmentString=@"top";
			break;
			
		case PKGImageAlignmentTopLeft:
			
			tAlignmentString=@"topleft";
			break;
			
		case PKGImageAlignmentTopRight:
			
			tAlignmentString=@"topright";
			break;
			
		case PKGImageAlignmentleft:
			
			tAlignmentString=@"left";
			break;
			
		case PKGImageAlignmentBottom:
			
			tAlignmentString=@"bottom";
			break;
			
		case PKGImageAlignmentBottomLeft:
			
			tAlignmentString=@"bottomleft";
			break;
			
		case PKGImageAlignmentBottomRight:
			
			tAlignmentString=@"bottomright";
			break;
			
		case PKGImageAlignmentRight:
			
			tAlignmentString=@"right";
			break;
	}
	
	tAttribute=[NSXMLNode attributeWithName:@"alignment" stringValue:tAlignmentString];
	[tBackgroundElement addAttribute:tAttribute];
	
	// layout-direction [optional]
	
	PKGImageLayoutDirection tLayoutDirection=inAppearanceSettings.imageLayoutDirection;
	
	if (tLayoutDirection==PKGImageLayoutDirectionNatural)
	{
		tAttribute=[NSXMLNode attributeWithName:@"layout-direction" stringValue:@"natural"];
		[tBackgroundElement addAttribute:tAttribute];
	}
	
	return tBackgroundElement;
}

- (NSArray *)elementsForProjectBuilder:(PKGProjectBuilder *)inProjectBuilder
{
	NSMutableArray * tElements=[NSMutableArray array];
	
	NSMutableDictionary * tCopiedSourcesRegister=[NSMutableDictionary dictionary];
	
	if (self.sharedSettingsForAllAppearances==YES)
	{
		PKGPresentationBackgroundAppearanceSettings * tAppearanceSettings=[self appearanceSettingsForAppearanceMode:PKGPresentationAppearanceModeShared];
		
		/*if (tAppearanceSettings==nil)
		{
			if (outErrorEvent!=NULL)
			{
				// A COMPLETER
			}
			
			return nil;
		}*/
		
		if (tAppearanceSettings.showCustomImage==NO)
			return tElements;
		
		PKGFilePath * tFilePath=tAppearanceSettings.imagePath;
		
		if ([tFilePath isSet]==NO)
			return tElements;
		
		[inProjectBuilder postStep:PKGBuildStepDistributionBackgroundImage beginEvent:nil];
		
		for(NSString * tAppearanceName in [PKGPresentationBackgroundAppearanceSettings allAppearancesNames])
		{
			PKGPresentationAppearanceMode tApperanceMode=[PKGPresentationBackgroundAppearanceSettings appearanceModeForAppearanceName:tAppearanceName];
			
			if (tApperanceMode==PKGPresentationAppearanceModeUnknown)
			{
				// A COMPLETER
				
				// Post a warning?
				
				continue;
			}
			
			NSXMLElement * tElement=[self projectBuilder:inProjectBuilder elementForAppearanceMode:tApperanceMode settings:tAppearanceSettings copiedResourcesRegister:tCopiedSourcesRegister];
		
			if (tElement==nil)
				return nil;
		
			[tElements addObject:tElement];
		}
	}
	else
	{
		NSDictionary * tAllAppearancesSettings=self.appearancesSettings;
		
		BOOL tDidPostBeginEvent=NO;
		
		for(NSString * tAppearanceName in tAllAppearancesSettings)
		{
			PKGPresentationBackgroundAppearanceSettings * tAppearanceSettings=tAllAppearancesSettings[tAppearanceName];
			
			if (tAppearanceSettings.showCustomImage==NO)
				continue;
			
			PKGFilePath * tFilePath=tAppearanceSettings.imagePath;
			
			if ([tFilePath isSet]==NO)
				continue;
			
			if (tDidPostBeginEvent==NO)
			{
				[inProjectBuilder postStep:PKGBuildStepDistributionBackgroundImage beginEvent:nil];
				tDidPostBeginEvent=YES;
			}
			
			PKGPresentationAppearanceMode tApperanceMode=[PKGPresentationBackgroundAppearanceSettings appearanceModeForAppearanceName:tAppearanceName];
			
			if (tApperanceMode==PKGPresentationAppearanceModeUnknown)
			{
				// A COMPLETER
				
				// Post a warning?
				
				continue;
			}
			
			NSXMLElement * tElement=[self projectBuilder:inProjectBuilder elementForAppearanceMode:tApperanceMode settings:tAppearanceSettings copiedResourcesRegister:tCopiedSourcesRegister];
			
			if (tElement==nil)
				return nil;
			
			[tElements addObject:tElement];
		}
	}
	
	[inProjectBuilder postCurrentStepSuccessEvent:nil];
	
	return [tElements copy];
}

@end

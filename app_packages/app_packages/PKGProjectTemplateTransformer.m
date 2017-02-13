/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGProjectTemplateTransformer.h"

#import "NSString+Karelia.h"

#import "PKGProjectTemplateDefaultValuesSettings.h"

#import "PKGProject.h"

NSString * const PKGProjectTemplateTransformerUUIDKey=@"UUID";
NSString * const PKGProjectTemplateTransformerProjectNameKey=@"PROJECT_NAME";
NSString * const PKGProjectTemplateTransformerProjectNameDNRKey=@"PROJECT_NAME_REVERSE_DOMAIN_NAME";
NSString * const PKGProjectTemplateTransformerProjectPathKey=@"PROJECT_PATH";
NSString * const PKGProjectTemplateTransformerCompanyNameKey=@"COMPANY_NAME";
NSString * const PKGProjectTemplateTransformerCompanyPackageIdentifierKey=@"COMPANY_PACKAGE_IDENTIFIER";
NSString * const PKGProjectTemplateTransformerYearKey=@"YEAR";

@interface PKGProjectTemplateTransformer ()

+ (NSString *)_filteredProjectName:(NSString *)inProjectName;

- (BOOL)_preprocessPropertyList:(id)inPropertyList;

+ (BOOL)_preprocessArray:(NSMutableArray *)inMutableArray withKeywordsDictionary:(NSDictionary *)inKeywordsdictionary;
+ (BOOL)_preprocessDictionary:(NSMutableDictionary *)inMutableDictionary withKeywordsDictionary:(NSDictionary *)inKeywordsDictionary;

@end

@implementation PKGProjectTemplateTransformer

+ (NSString *)_filteredProjectName:(NSString *)inProjectName
{
	NSUInteger tLength=inProjectName.length;
	
	if (tLength==0)
		return inProjectName;
	
	unichar * tUnicharBuffer=(unichar *) malloc((tLength+1)*sizeof(unichar));
	 
	if (tUnicharBuffer==NULL)
		return nil;
	
	NSUInteger tNewLength=0;

	for(NSUInteger tIndex=0;tIndex<tLength;tIndex++)
	{
		unichar tCharacter=[inProjectName characterAtIndex:tIndex];

		if (tCharacter=='-' ||
			(tCharacter>='A' && tCharacter<='Z') ||
			(tCharacter>='a' && tCharacter<='z') ||
			(tCharacter>='0' && tCharacter<='9'))
		{
			tUnicharBuffer[tNewLength]=tCharacter;
 
			tNewLength+=1;
		}
	}

	NSString * tProjectNameFiltered=@"";
	
	if (tNewLength>0)
		tProjectNameFiltered=[NSString stringWithCharacters:tUnicharBuffer length:tNewLength];

	free(tUnicharBuffer);
	
	return tProjectNameFiltered;
}

- (BOOL)_preprocessPropertyList:(id)inPropertyList
{
	if (inPropertyList==nil)
		return NO;
	
	// Create keywords dictionary
	
	NSMutableDictionary * tMutableKeywordsDictionary=[NSMutableDictionary dictionary];
	
	tMutableKeywordsDictionary[PKGProjectTemplateTransformerUUIDKey]=[NSUUID UUID].UUIDString;
	tMutableKeywordsDictionary[PKGProjectTemplateTransformerProjectNameKey]=self.outputDocumentName;
	tMutableKeywordsDictionary[PKGProjectTemplateTransformerProjectNameDNRKey]=[PKGProjectTemplateTransformer _filteredProjectName:self.outputDocumentName];
	tMutableKeywordsDictionary[PKGProjectTemplateTransformerProjectPathKey]=[self.outputDirectory stringByExpandingTildeInPath];
	tMutableKeywordsDictionary[PKGProjectTemplateTransformerYearKey]=[NSString stringWithFormat:@"%d",(int)[[NSCalendarDate calendarDate] yearOfCommonEra]];
	
	PKGProjectTemplateDefaultValuesSettings * tDefaultValueSettings=[PKGProjectTemplateDefaultValuesSettings sharedSettings];
	
	for(NSString * tKey in tDefaultValueSettings.allKeys)
	{
		if ([tKey isEqualToString:PKGProjectTemplateCompanyNameKey]==YES)
		{
			tMutableKeywordsDictionary[PKGProjectTemplateTransformerCompanyNameKey]=[tDefaultValueSettings valueForKey:tKey];
		}
		else if ([tKey isEqualToString:PKGProjectTemplateCompanyIdentifierPrefixKey]==YES)
		{
			tMutableKeywordsDictionary[PKGProjectTemplateTransformerCompanyPackageIdentifierKey]=[tDefaultValueSettings valueForKey:tKey];
		}
		else
		{
			tMutableKeywordsDictionary[tKey]=[tDefaultValueSettings valueForKey:tKey];
		}
	}
	
	// Preprocess
	
	if ([inPropertyList isKindOfClass:NSMutableArray.class]==YES)
		return [PKGProjectTemplateTransformer _preprocessArray:inPropertyList withKeywordsDictionary:tMutableKeywordsDictionary];
	
	if ([inPropertyList isKindOfClass:NSMutableDictionary.class]==YES)
		return [PKGProjectTemplateTransformer _preprocessDictionary:inPropertyList withKeywordsDictionary:tMutableKeywordsDictionary];
	
	return NO;
}

+ (BOOL)_preprocessArray:(NSMutableArray *)inMutableArray withKeywordsDictionary:(NSDictionary *)inKeywordsDictionary
{
	NSUInteger tCount=[inMutableArray count];
	
	for(NSUInteger tIndex=0;tIndex<tCount;tIndex++)
	{
		id tObject=inMutableArray[tIndex];
		
		if ([tObject isKindOfClass:NSMutableArray.class]==YES)
		{
			if ([PKGProjectTemplateTransformer _preprocessArray:tObject withKeywordsDictionary:inKeywordsDictionary]==NO)
				return NO;
		}
		
		if ([tObject isKindOfClass:NSMutableDictionary.class]==YES)
		{
			if ([PKGProjectTemplateTransformer _preprocessDictionary:tObject withKeywordsDictionary:inKeywordsDictionary]==NO)
				return NO;
		}
		
		if ([tObject isKindOfClass:NSString.class]==YES)
		{
			NSString * tPreprocessedString=[((NSString *)tObject) replaceAllTextBetweenString:@"%%"
																					andString:@"%%"
																			   fromDictionary:inKeywordsDictionary];
			
			[inMutableArray replaceObjectAtIndex:tIndex
									  withObject:tPreprocessedString];
		}
	}
	
	return YES;
}

+ (BOOL)_preprocessDictionary:(NSMutableDictionary *)inMutableDictionary withKeywordsDictionary:(NSDictionary *)inKeywordsDictionary
{
	NSArray * tKeysArray=[inMutableDictionary allKeys];
	
	for(NSString * tKey in tKeysArray)
	{
		id tObject=inMutableDictionary[tKey];
		
		if ([tObject isKindOfClass:NSArray.class]==YES)
		{
			if ([PKGProjectTemplateTransformer _preprocessArray:tObject withKeywordsDictionary:inKeywordsDictionary]==NO)
				return NO;
		}
		
		if ([tObject isKindOfClass:NSMutableDictionary.class]==YES)
		{
			if ([PKGProjectTemplateTransformer _preprocessDictionary:tObject withKeywordsDictionary:inKeywordsDictionary]==NO)
				return NO;
		}
		
		if ([tObject isKindOfClass:NSString.class]==YES)
		{
			NSString * tPreprocessedString=[((NSString *)tObject) replaceAllTextBetweenString:@"%%"
																					andString:@"%%"
																			   fromDictionary:inKeywordsDictionary];
			
			inMutableDictionary[tKey]=tPreprocessedString;
		}
	}
	
	return YES;
}

#pragma mark -

- (void)transform
{
	NSFileManager * tFileManager=[NSFileManager defaultManager];
	NSError * tError=nil;
	
	NSString * tProjectDirectory=[self.outputDirectory stringByExpandingTildeInPath];
	
	// Create Project directory if needed
	
	if ([tFileManager fileExistsAtPath:tProjectDirectory]==NO)
	{
		if ([tFileManager createDirectoryAtPath:tProjectDirectory withIntermediateDirectories:NO attributes:nil error:&tError]==NO)
		{
			if (self.errorHandler!=nil)
				self.errorHandler(tError,PKGTransformationDirectoryCreationStep);
			
			return;
		}
	}
	
	// Read the template file as a property list
	
	NSString * tTemplateFile=self.inputProjectTemplate.templateFilePath;
	
	NSData * tData=[NSData dataWithContentsOfFile:tTemplateFile options:0 error:&tError];
	
	if (tData==nil)
	{
		if (self.errorHandler!=nil)
			self.errorHandler(tError,PKGTransformationTemplateReadStep);
		
		return;
	}
	
	id tPropertyList=[NSPropertyListSerialization propertyListWithData:tData options:NSPropertyListMutableContainers format:NULL error:&tError];
	
	if (tPropertyList==nil)
	{
		if (self.errorHandler!=nil)
			self.errorHandler(nil,PKGTransformationTemplateReadStep);
		
		return;
	}
	
	// Replace the keywords
	
	if ([self _preprocessPropertyList:tPropertyList]==NO)
	{
		if (self.errorHandler!=nil)
			self.errorHandler(nil,PKGTransformationTemplatePreprocessStep);
		
		return;
	}
	
	PKGAssistantPlugin * tAssistantPlugin=self.inputProjectTemplate.assistantPlugin;
	
	if (tAssistantPlugin!=nil)
	{
		// Transform into PKGProject
		
		PKGProject * tProject=[PKGProject projectFromPropertyList:tPropertyList error:&tError];
		
		if (tProject==nil)
		{
			if (self.errorHandler!=nil)
				self.errorHandler(tError,PKGTransformationProjectObjectificationStep);
			
			return;
		}
		
		if ([tAssistantPlugin preprocess:tProject]==NO)
		{
			if (self.errorHandler!=nil)
				self.errorHandler(nil,PKGTransformationProjectPreprocessStep);
			
			return;
		}
		
		// Revert to Property List to save on disk
		
		tPropertyList=[tProject representation];
	}
	
	tData=[NSPropertyListSerialization dataWithPropertyList:tPropertyList format:NSPropertyListXMLFormat_v1_0 options:0 error:&tError];
	
	if (tData==nil)
	{
		if (self.errorHandler!=nil)
			self.errorHandler(nil,PKGTransformationProjectWriteStep);
		
		return;
	}
	
	NSString * tNewProjectFilePath=[[tProjectDirectory stringByAppendingPathComponent:self.outputDocumentName] stringByAppendingPathExtension:@".pkgproj"];
	
	if ([tData writeToFile:tNewProjectFilePath options:NSDataWritingAtomic error:&tError]==NO)
	{
		if (self.errorHandler!=nil)
			self.errorHandler(tError,PKGTransformationProjectWriteStep);
		
		return;
	}
	
	if (self.completionHandler!=nil)
		self.completionHandler(tNewProjectFilePath);
}

@end

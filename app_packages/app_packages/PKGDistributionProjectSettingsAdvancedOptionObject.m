/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionProjectSettingsAdvancedOptionObject.h"

#import "PKGDistributionProjectSettingsAdvancedOptionHeader.h"
#import "PKGDistributionProjectSettingsAdvancedOptionBoolean.h"
#import "PKGDistributionProjectSettingsAdvancedOptionString.h"
#import "PKGDistributionProjectSettingsAdvancedOptionList.h"

NSString * const PKGDistributionProjectSettingsAdvancedOptionsObjectTypeKey=@"TYPE";
NSString * const PKGDistributionProjectSettingsAdvancedOptionsObjectTitleKey=@"TITLE";

NSString * const PKGDistributionProjectSettingsAdvancedOptionsSupportsAdvancedEditorKey=@"ADVANCED_EDITOR";
NSString * const PKGDistributionProjectSettingsAdvancedOptionsAdvancedEditorDescriptionKey=@"EDITOR";

@interface PKGDistributionProjectSettingsAdvancedOptionObject ()

	@property (readwrite) NSString * title;

@end

@implementation PKGDistributionProjectSettingsAdvancedOptionObject

+ (NSDictionary *)advancedOptionsRegistryWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	if (inRepresentation==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
										  code:PKGFileURLNilError
									  userInfo:nil];
		
		return nil;
	}
	
	if ([inRepresentation isKindOfClass:NSDictionary.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
										  code:PKGRepresentationInvalidTypeOfValueError
									  userInfo:nil];
		
		return nil;
	}
	
	NSMutableDictionary * tRegistry=[NSMutableDictionary dictionary];
	
	__block NSError * tError=nil;
	
	[inRepresentation enumerateKeysAndObjectsUsingBlock:^(NSString * bKey, NSDictionary * bRepresentation, BOOL *bOutStop) {
		
		if (bRepresentation==nil)
		{
			tError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
									   code:PKGFileURLNilError
								   userInfo:nil];
			
			*bOutStop=YES;
			
			return;
		}
		
		if ([bRepresentation isKindOfClass:NSDictionary.class]==NO)
		{
			tError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
									   code:PKGRepresentationInvalidTypeOfValueError
								   userInfo:nil];
			
			*bOutStop=YES;
			
			return;
		}
		
		NSString * tTypeName=bRepresentation[PKGDistributionProjectSettingsAdvancedOptionsObjectTypeKey];
		
		if (tTypeName==nil)
		{
			tError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
									   code:PKGFileURLNilError
								   userInfo:nil];
			
			*bOutStop=YES;
			
			return;
		}
		
		if ([tTypeName isKindOfClass:NSString.class]==NO)
		{
			tError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
									   code:PKGRepresentationInvalidTypeOfValueError
								   userInfo:nil];
			
			*bOutStop=YES;
			
			return;
		}
		
		PKGDistributionProjectSettingsAdvancedOptionObject * tObject=nil;
		
		if ([tTypeName isEqualToString:@"Boolean"]==YES)
		{
			tObject=[[PKGDistributionProjectSettingsAdvancedOptionBoolean alloc] initWithRepresentation:bRepresentation error:&tError];
		}
		else if ([tTypeName isEqualToString:@"String"]==YES)
		{
			tObject=[[PKGDistributionProjectSettingsAdvancedOptionString alloc] initWithRepresentation:bRepresentation error:&tError];
		}
		else if ([tTypeName isEqualToString:@"List"]==YES)
		{
			tObject=[[PKGDistributionProjectSettingsAdvancedOptionList alloc] initWithRepresentation:bRepresentation error:&tError];
		}
		else if ([tTypeName isEqualToString:@"Header"]==YES)
		{
			tObject=[[PKGDistributionProjectSettingsAdvancedOptionHeader alloc] initWithRepresentation:bRepresentation error:&tError];
		}
		
		if (tObject==nil)
		{
			*bOutStop=YES;
			
			return;
		}
		
		tRegistry[bKey]=tObject;
	}];
	
	if (tError!=nil)
	{
		if (outError!=NULL)
			*outError=tError;
		
		return nil;
	}
	
	return [tRegistry copy];
}

#pragma mark -

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	self=[super init];
	
	if (self!=nil)
	{
		NSString * tTitle=inRepresentation[PKGDistributionProjectSettingsAdvancedOptionsObjectTitleKey];
		
		PKGFullCheckStringValueForKey(tTitle,PKGDistributionProjectSettingsAdvancedOptionsObjectTitleKey);
		
		_title=[tTitle copy];
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	return [NSMutableDictionary dictionary];
}

#pragma mark -

- (BOOL)supportsAdvancedEditor
{
	return NO;
}

- (NSDictionary *)advancedEditorRepresentation
{
	return nil;
}

@end

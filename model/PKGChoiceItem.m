/*
 Copyright (c) 2016-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "PKGChoiceItem.h"

#import "PKGPackagesError.h"

#import "NSMutableDictionary+PKGLocalizedValues.h"

#import "NSArray+WBExtensions.h"


NSString * const PKGChoiceItemUUIDKey=@"UUID";

NSString * const PKGChoiceItemTypeKey=@"TYPE";

NSString * const PKGChoiceItemLocalizationsOfTitleKey=@"TITLE";

NSString * const PKGChoiceItemLocalizationsOfDescriptionKey=@"DESCRIPTION";

NSString * const PKGChoiceItemOptionsKey=@"OPTIONS";

NSString * const PKGChoiceItemRequirementsKey=@"REQUIREMENTS";

@interface PKGChoiceItem ()

	@property (readwrite,copy) NSString * UUID;

@end


@implementation PKGChoiceItem

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_UUID=[[NSUUID UUID] UUIDString];
		
		_localizedTitles=[NSMutableDictionary dictionary];
		
		_localizedDescriptions=[NSMutableDictionary dictionary];
		
		_options=[[PKGChoiceItemOptions alloc] init];
		
		_requirements=[NSMutableArray array];
	}
	
	return self;
}

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	if (inRepresentation==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationNilRepresentationError userInfo:nil];
		
		return nil;
	}
	
	if ([inRepresentation isKindOfClass:NSDictionary.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
		
		return nil;
	}
	
	self=[super init];
	
	if (self!=nil)
	{
		NSString * tString=inRepresentation[PKGChoiceItemUUIDKey];
		
		PKGFullCheckStringValueForKey(tString, PKGChoiceItemUUIDKey);
		
		_UUID=[tString copy];
		
		
		NSError * tError=nil;
		
		if (inRepresentation[PKGChoiceItemLocalizationsOfTitleKey]==nil)
		{
			_localizedTitles=[NSMutableDictionary dictionary];
		}
		else
		{
			_localizedTitles=[NSMutableDictionary PKG_dictionaryWithRepresentations:inRepresentation[PKGChoiceItemLocalizationsOfTitleKey] ofLocalizationsOfValueOfClass:NSString.class error:&tError];
		
			if (_localizedTitles==nil)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGChoiceItemLocalizationsOfTitleKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tError.code
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		if (inRepresentation[PKGChoiceItemLocalizationsOfTitleKey]==nil)
		{
			_localizedDescriptions=[NSMutableDictionary dictionary];
		}
		else
		{
			_localizedDescriptions=[NSMutableDictionary PKG_dictionaryWithRepresentations:inRepresentation[PKGChoiceItemLocalizationsOfDescriptionKey] ofLocalizationsOfValueOfClass:NSString.class error:&tError];
		
			if (_localizedDescriptions==nil)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGChoiceItemLocalizationsOfDescriptionKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tError.code
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		_options=[[PKGChoiceItemOptions alloc] initWithRepresentation:inRepresentation[PKGChoiceItemOptionsKey] error:&tError];
		
		if (_options==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValueError;
				
				NSString * tPathError=PKGChoiceItemOptionsKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
		}
		
		if (inRepresentation[PKGChoiceItemRequirementsKey]!=nil)
		{
			if ([inRepresentation[PKGChoiceItemRequirementsKey] isKindOfClass:NSArray.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGChoiceItemRequirementsKey}];
				
				return nil;
			}
			
			__block NSError * tBlockError=nil;
			
			_requirements=[[inRepresentation[PKGChoiceItemRequirementsKey] WB_arrayByMappingObjectsUsingBlock:^id(NSDictionary * bRequirementRepresentation,__attribute__((unused))NSUInteger bIndex){
				
				return [[PKGRequirement alloc] initWithRepresentation:bRequirementRepresentation error:&tBlockError];
			}] mutableCopy];
			
			if (_requirements==nil)
			{
				if (outError!=NULL)
				{
					NSInteger tCode=tBlockError.code;
					
					if (tCode==PKGRepresentationNilRepresentationError)
						tCode=PKGRepresentationInvalidValueError;
					
					NSString * tPathError=PKGChoiceItemRequirementsKey;
					
					if (tBlockError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tBlockError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tCode
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		else
		{
			_requirements=[NSMutableArray array];
		}
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	tRepresentation[PKGChoiceItemUUIDKey]=self.UUID;
	
	tRepresentation[PKGChoiceItemTypeKey]=@([self type]);
	
	tRepresentation[PKGChoiceItemLocalizationsOfTitleKey]=[self.localizedTitles PKG_representationsOfLocalizations];
	
	tRepresentation[PKGChoiceItemLocalizationsOfDescriptionKey]=[self.localizedDescriptions PKG_representationsOfLocalizations];
	
	tRepresentation[PKGChoiceItemOptionsKey]=[self.options representation];
	
	if (self.requirements.count>0)
	{
		tRepresentation[PKGChoiceItemRequirementsKey]=[self.requirements WB_arrayByMappingObjectsUsingBlock:^id(PKGRequirement * bRequirement,__attribute__((unused))NSUInteger bIndex){
			
			return [bRequirement representation];
		}];
	}
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendFormat:@"UUID: %@\n",self.UUID];
	
	[tDescription appendFormat:@"    Type: %@\n",([self type]==PKGChoiceItemTypePackage) ? @"Package" : @"Group"];
	
	[tDescription appendString:@"    Title:\n"];
	
	[self.localizedTitles enumerateKeysAndObjectsUsingBlock:^(NSString * bLanguage,NSString * bTitle,__attribute__((unused))BOOL * bOutStop){
	
		[tDescription appendFormat:@"      %@: %@\n",bLanguage,bTitle];
	}];
	
	[tDescription appendString:@"\n"];
	
	[tDescription appendString:@"    Description:\n"];
	
	[self.localizedDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString * bLanguage,NSString * bDescription,__attribute__((unused))BOOL * bOutStop){
		
		[tDescription appendFormat:@"      %@: %@\n",bLanguage,bDescription];
	}];
	
	[tDescription appendFormat:@"    %@\n",[self.options description]];
	
	[tDescription appendFormat:@"Requirements(%lu):\n",(unsigned long)self.requirements.count];
	
	for(PKGRequirement * tRequirement in self.requirements)
	{
		[tDescription appendFormat:@"%@\n",[tRequirement description]];
	}
	
	return tDescription;
	
}

#pragma mark -

- (PKGChoiceItemType)type
{
	return PKGChoiceItemTypeUnknown;
}

@end

@implementation PKGChoiceGroupItem

+ (BOOL)isRepresentationOfGroupChoiceItem:(NSDictionary *)inRepresentation
{
	return ([inRepresentation[PKGChoiceItemTypeKey] unsignedIntegerValue]==PKGChoiceItemTypeGroup);
}

- (NSMutableArray *)requirements
{
	if (self.options.hideChildren==NO)
		return nil;
	
	return [super requirements];
		
}

#pragma mark -

- (PKGChoiceItemType)type
{
	return PKGChoiceItemTypeGroup;
}

@end


NSString * const PKGChoicePackageItemPackageUUIDKey=@"PACKAGE_UUID";



@implementation PKGChoicePackageItem

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	NSError * tError=nil;
	
	self=[super initWithRepresentation:inRepresentation error:&tError];
	
	if (self!=nil)
	{
		_packageUUID=inRepresentation[PKGChoicePackageItemPackageUUIDKey];
		
		if (_packageUUID==nil)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidTypeOfValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGChoicePackageItemPackageUUIDKey}];
			
			return nil;
		}
		
		if (_packageUUID.length==0)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGChoicePackageItemPackageUUIDKey}];
			
			return nil;
		}
	}
	else
	{
		if (outError!=NULL)
			*outError=tError;
		
		return nil;
	}
	
	return self;
}

- (instancetype)initWithPackageComponent:(PKGPackageComponent *)inPackageComponent
{
	if (inPackageComponent==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_packageUUID=inPackageComponent.UUID;
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[super representation];
	
	tRepresentation[PKGChoicePackageItemPackageUUIDKey]=self.packageUUID;

	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendFormat:@"%@\n",[super description]];
	
	[tDescription appendFormat:@"Package UUID: %@\n",self.packageUUID];
	
	return tDescription;
}

#pragma mark -

- (PKGChoiceItemType)type
{
	return PKGChoiceItemTypePackage;
}

@end

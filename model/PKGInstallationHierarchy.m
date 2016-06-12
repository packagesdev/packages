/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGInstallationHierarchy.h"

#import "PKGPackagesError.h"

#import "NSDictionary+WBMapping.h"

NSString * const PKGInstallationHierarchyChoicesListKey=@"LIST";

NSString * const PKGInstallationHierarchyRemovedPackagesKey=@"REMOVED";

@interface PKGInstallationHierarchy ()

	@property (readwrite) PKGChoicesForest * choicesForest;

	@property (readwrite) NSMutableDictionary * removedPackagesChoices;

@end

@implementation PKGInstallationHierarchy

- (instancetype)initWithPackagesComponents:(NSArray *)inPackagesComponents
{
	if (inPackagesComponents==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_choicesForest=[[PKGChoicesForest alloc] initWithPackagesComponents:inPackagesComponents];
		
		if (_choicesForest==nil)
			return nil;
		
		_removedPackagesChoices=[NSMutableDictionary dictionary];
	}
	
	return self;
}

- (id) initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	if (inRepresentation==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationNilRepresentationError userInfo:nil];
		
		return nil;
	}
	
	if ([inRepresentation isKindOfClass:[NSDictionary class]]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
		
		return nil;
	}
	
	self=[super init];
	
	if (self!=nil)
	{
		__block NSError * tError=nil;
		
		_choicesForest=[[PKGChoicesForest alloc] initWithArrayRepresentation:inRepresentation[PKGInstallationHierarchyChoicesListKey] error:&tError];
		
		if (_choicesForest==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=PKGInstallationHierarchyChoicesListKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
		}
		
		if (inRepresentation[PKGInstallationHierarchyRemovedPackagesKey]==nil)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValue
										  userInfo:@{PKGKeyPathErrorKey:PKGInstallationHierarchyRemovedPackagesKey}];
			
			return nil;
		}
		
		if ([inRepresentation[PKGInstallationHierarchyRemovedPackagesKey] isKindOfClass:[NSArray class]]==NO)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidTypeOfValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGInstallationHierarchyRemovedPackagesKey}];
			
			return nil;
		}
		
		_removedPackagesChoices=[[inRepresentation[PKGInstallationHierarchyRemovedPackagesKey] WBmapObjectsUsingBlock:^id(NSString * bPackageUUID,NSDictionary * bChoiceItemRepresentation){
			
			return [[PKGChoiceItem alloc] initWithRepresentation:bChoiceItemRepresentation error:&tError];
		}] mutableCopy];
		
		if (_removedPackagesChoices==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=PKGInstallationHierarchyRemovedPackagesKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
		}
	}
	
	return self;
}

- (NSMutableDictionary *) representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	tRepresentation[PKGInstallationHierarchyChoicesListKey]=[self.choicesForest arrayRepresentation];
	
	tRepresentation[PKGInstallationHierarchyRemovedPackagesKey]=[self.removedPackagesChoices WBmapObjectsUsingBlock:^id(NSString * bPackageUUID,PKGChoiceItem * bChoiceItem){
		
		return [bChoiceItem representation];
	}];
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[self.choicesForest.rootNodes enumerateObjectsUsingBlock:^(PKGChoicesTreeNode * bChoiceTreeNode, NSUInteger bIndex, BOOL *outStop) {
		
		[tDescription appendFormat:@"    %@\n",[bChoiceTreeNode description]];
		
	}];
	
	[tDescription appendFormat:@"  Removed Packages(%lu):\n\n",(unsigned long)[self.removedPackagesChoices count]];
	
	[self.removedPackagesChoices enumerateKeysAndObjectsUsingBlock:^(NSString * bPackageUUID,PKGChoiceItem * bChoiceItem,BOOL *bOutStop){
	
		[tDescription appendFormat:@"     %@\n",bPackageUUID];
	}];
	
	return tDescription;
}

#pragma mark -

- (NSSet *)allPackagesUUIDs
{
	NSMutableSet * tMutableSet=[NSMutableSet set];
	
	[self.choicesForest.rootNodes enumerateObjectsUsingBlock:^(PKGChoicesTreeNode * bChoicesTreeNode,NSUInteger bIndex,BOOL *bOutStop){
		
		[bChoicesTreeNode enumerateRepresentedObjectsRecursivelyUsingBlock:^(PKGChoiceItem *bChoiceItem,BOOL * bTreeOutStop){
			
			if ([bChoiceItem type]==PKGChoiceItemTypePackage)
			{
				NSString * tUUID=((PKGChoicePackageItem *)bChoiceItem).packageUUUID;
				
				if ([tMutableSet containsObject:tUUID]==NO)
					[tMutableSet addObject:tUUID];
			}
		}];
	}];
	
	return [tMutableSet copy];
}

@end

/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGForest.h"

#import "PKGPackagesError.h"

#import "NSArray+WBExtensions.h"

@interface PKGForest ()
{
	NSArray * _cachedRepresentation;
}

	@property (nonatomic,readwrite) NSMutableArray * rootNodes;

@end

@implementation PKGForest

+ (Class)nodeClass
{
	return [PKGTreeNode class];
}

#pragma mark -

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_rootNodes=[NSMutableArray array];
	}
	
	return self;
}

- (instancetype)initWithArrayRepresentation:(NSArray *)inRepresentation error:(out NSError **)outError
{
	if (inRepresentation==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationNilRepresentationError userInfo:nil];
		
		return nil;
	}
	
	if ([inRepresentation isKindOfClass:NSArray.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
		
		return nil;
	}
	
	self=[super init];
	
	if (self!=nil)
	{
		_cachedRepresentation=inRepresentation;
	}
	
	return self;
}

- (instancetype)initWithRootNodes:(NSArray *)inRootNodes
{
	self=[super init];
	
	if (self!=nil)
	{
		_rootNodes=[inRootNodes mutableCopy];
	}
	
	return self;
}

- (NSMutableArray *)arrayRepresentation
{
	if (_cachedRepresentation!=nil)
		return [_cachedRepresentation mutableCopy];
	
	return [_rootNodes WB_arrayByMappingObjectsUsingBlock:^id(PKGTreeNode * bTreeNode,__attribute__((unused))NSUInteger bIndex){
		
		return [bTreeNode representation];
	}];
}

#pragma mark -

- (NSMutableArray *)rootNodes
{
	if (_rootNodes==nil)
	{
		if (_cachedRepresentation!=nil && [_cachedRepresentation isKindOfClass:NSArray.class]==YES)
		{
			__block NSError * tError=nil;
			
			_rootNodes=[[_cachedRepresentation WB_arrayByMappingObjectsUsingBlock:^id(NSDictionary * bNodeRepresentation,__attribute__((unused))NSUInteger bIndex){
				
				return [[[[self class] nodeClass] alloc] initWithRepresentation:bNodeRepresentation error:&tError];
				
			}] mutableCopy];
			
			if (_rootNodes==nil)
			{
				// A COMPLETER
			}
			
			_cachedRepresentation=nil;
		}
	}
	
	return _rootNodes;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	for(PKGTreeNode * tTreeNode in self.rootNodes)
		[tDescription appendFormat:@"  %@\n",[tTreeNode description]];
	
	return tDescription;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)inZone
{
	PKGForest * nForest=(PKGForest *)[[[self class] allocWithZone:inZone] init];
	
	if (nForest!=nil)
	{
		if (_cachedRepresentation!=nil)
		{
			nForest->_cachedRepresentation=[_cachedRepresentation copy];
		}
		else
		{
			nForest.rootNodes=[self.rootNodes WB_arrayByMappingObjectsUsingBlock:^id(PKGTreeNode * bTreeNode,NSUInteger bIndex){
				
				return [bTreeNode deepCopyWithZone:inZone];
			}];
		}
	}
	
	return nForest;
}

#pragma mark -

- (NSString *)indentationStringForTreeNode:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return nil;
	
	NSMutableString * tIndentation=[NSMutableString string];
	
	PKGTreeNode * tNode=inTreeNode;
	PKGTreeNode * tParent=[tNode parent];
	
	while (tParent!=nil)
	{
		NSInteger tIndex=[tParent indexOfChildIdenticalTo:tNode];
		
		[tIndentation insertString:[NSString stringWithFormat:@"%ld",(long)(tIndex+1)] atIndex:0];
		
		tNode=tParent;
		tParent=[tNode parent];
		
		[tIndentation insertString:@"." atIndex:0];
	}
	
	NSInteger tIndex=[self.rootNodes indexOfObject:tNode];
	
	[tIndentation insertString:[NSString stringWithFormat:@"%ld",(long)(tIndex+1)] atIndex:0];
	
	return [tIndentation copy];
}

@end

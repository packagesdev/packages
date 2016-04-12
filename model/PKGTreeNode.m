/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGTreeNode.h"

#import "PKGPackagesError.h"

#import "NSArray+WBMapping.h"

NSString * const PKGTreeNodeChildrenKey=@"CHILDREN";

@interface PKGTreeNode ()
{
	__weak PKGTreeNode * _parent;
	
	id<PKGObjectProtocol> _representedObject;
	
	NSMutableArray * _children;
}

- (void)setParent:(PKGTreeNode *)inParent;

@end


@implementation PKGTreeNode

+ (instancetype)treeNode
{
	return [[self alloc] init];
}

+ (instancetype)treeNodeWithRepresentedObject:(id<PKGObjectProtocol>)inRepresentedObject children:(NSArray *)inTreeNodes
{
	return [[self alloc] initWithRepresentedObject:inRepresentedObject children:inTreeNodes];
}

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_parent=nil;
		_children=[NSMutableArray array];
	}
	
	return self;
}

- (instancetype)initWithRepresentedObject:(id<PKGObjectProtocol>)inRepresentedObject children:(NSArray *)inTreeNodes
{
	self=[super init];
	
	if (self!=nil)
	{
		_representedObject=inRepresentedObject;
		
		_children=[inTreeNodes copy];
		
		[_children makeObjectsPerformSelector:@selector(setParent:) withObject:self];
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
	
	if ([inRepresentation isKindOfClass:[NSDictionary class]]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
		
		return nil;
	}
	
	self=[super init];
	
	if (self!=nil)
	{
		_parent=nil;
		
		__block NSError * tError=nil;
		
		_representedObject=[[[self representedObjectClassForRepresentation:inRepresentation] alloc] initWithRepresentation:inRepresentation error:&tError];
		
		if (_representedObject==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:tError.userInfo];
			}
			
			return nil;
		}
		
		NSArray * tChildrenRepresentation=inRepresentation[PKGTreeNodeChildrenKey];
		
		if (tChildrenRepresentation==nil)
		{
			_children=[NSMutableArray array];
		}
		else
		{
			if ([tChildrenRepresentation isKindOfClass:[NSArray class]]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGTreeNodeChildrenKey}];
				
				return nil;
			}
			
			_children=[[tChildrenRepresentation WBmapObjectsUsingBlock:^id(NSDictionary * bChildRepresentation, NSUInteger bIndex){
				PKGTreeNode * tChild=[[[self class] alloc] initWithRepresentation:bChildRepresentation error:&tError];
				
				[tChild setParent:self];
				
				return tChild;
			}] mutableCopy];
			
			if (_children==nil)
			{
				if (outError!=NULL)
				{
					NSInteger tCode=tError.code;
					
					if (tCode==PKGRepresentationNilRepresentationError)
						tCode=PKGRepresentationInvalidValue;
					
					NSString * tPathError=PKGTreeNodeChildrenKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tCode
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	NSMutableDictionary * tRepresentedObjectRepresentation=[_representedObject representation];
	
	if (tRepresentedObjectRepresentation!=nil)
		[tRepresentation addEntriesFromDictionary:tRepresentedObjectRepresentation];
	
	NSArray * tChildrenRepresentation=[_children WBmapObjectsUsingBlock:^id(PKGTreeNode * bTreeNode, NSUInteger bIndex){
		return [bTreeNode representation];
	}];
	
	if ([tChildrenRepresentation count]>0)
		tRepresentation[PKGTreeNodeChildrenKey]=tChildrenRepresentation;
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	// A COMPLETER
	
	return tDescription;
}

#pragma mark -

- (Class)representedObjectClassForRepresentation:(NSDictionary *)inRepresentation
{
	NSLog(@"You need to define the class of the represented object");
	
	return nil;
}

- (id<PKGObjectProtocol>)representedObject
{
	return _representedObject;
}

- (BOOL)isLeaf
{
	return ([self numberOfChildren]==0);
}

- (NSIndexPath *)indexPath
{
	// A COMPLETER
	
	return nil;
}

- (PKGTreeNode *)parent
{
	return _parent;
}

- (void)setParent:(PKGTreeNode *)inParent
{
	_parent=inParent;
}

- (NSUInteger)numberOfChildren
{
	return [_children count];
}

- (NSArray *)children
{
	return [_children copy];
}

- (BOOL)isDescendantOfNode:(PKGTreeNode *)inTreeNode
{
	PKGTreeNode * tParent = [self parent];
	
	while (tParent)
	{
		if (tParent == inTreeNode)
			return YES;
		
		tParent = [tParent parent];
	}
	
	return NO;
}

- (BOOL)isDescendantOfNodeInArray:(NSArray *)inTreeNodes
{
	for (PKGTreeNode * tTreeNode in inTreeNodes)
	{
		if ([self isDescendantOfNode:tTreeNode]==YES)
			return YES;
	}
	
	return NO;
}

- (PKGTreeNode *)descendantNodeAtIndex:(NSUInteger)inIndex
{
	if (inIndex>=[_children count])
		return nil;
	
	return [_children objectAtIndex:inIndex];
}

- (PKGTreeNode *)descendantNodeAtIndexPath:(NSIndexPath *)inIndexPath
{
	// A COMPLETER
	
	return nil;
}

- (void)addChild:(PKGTreeNode *)inTreeNode
{
	[inTreeNode setParent:self];
	[_children addObject:inTreeNode];
}

- (void)addChildren:(NSArray *)inTreeNodes
{
	[inTreeNodes makeObjectsPerformSelector:@selector(setParent:) withObject:self];
	[_children addObjectsFromArray:inTreeNodes];
}

- (void)insertChild:(PKGTreeNode *)inTreeNode atIndex:(NSUInteger)inIndex
{
	if (inTreeNode==nil || inIndex>[_children count])
		return;
	
	[inTreeNode setParent:self];
	[_children insertObject:inTreeNode atIndex:inIndex];
}

- (void)insertChildren:(NSArray *)inTreeNodes atIndex:(NSUInteger)inIndex
{
	if ([inTreeNodes count]==0 || inIndex>[_children count])
		return;
	
	[inTreeNodes makeObjectsPerformSelector:@selector(setParent:) withObject:self];
	[_children insertObjects:inTreeNodes atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(inIndex, [inTreeNodes count])]];
}

- (void)removeChildAtIndex:(NSUInteger)inIndex
{
	if (inIndex>=[_children count])
		return;
	
	PKGTreeNode * tTreeNode=_children[inIndex];
	
	[tTreeNode setParent:nil];
	
	[_children removeObjectAtIndex:inIndex];
}

- (void)removeChild:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return;
	
	[inTreeNode setParent:nil];
	[_children removeObjectIdenticalTo:inTreeNode];
}

- (void)removeChildren
{
	[_children makeObjectsPerformSelector:@selector(setParent:) withObject:self];
	[_children removeAllObjects];
}

- (void)removeFromParent
{
	[[self parent] removeChild:self];
}

@end


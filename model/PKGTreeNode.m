/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* Some portions of this code is from or inspired by the NSOutlineView sample code from Apple, inc */

#import "PKGTreeNode.h"

#import "PKGPackagesError.h"

#import "NSArray+WBExtensions.h"

NSString * const PKGTreeNodeChildrenKey=@"CHILDREN";

@interface PKGTreeNode ()
{
	__weak PKGTreeNode * _parent;
	
	id<PKGObjectProtocol> _representedObject;
	
	NSMutableArray * _children;
}

- (void)setParent:(PKGTreeNode *)inParent;

- (BOOL)_enumerateRepresentedObjectsRecursivelyUsingBlock:(void(^)(id<PKGObjectProtocol> representedObject,BOOL *stop))block;

@end


@implementation PKGTreeNode

+ (instancetype)treeNode
{
	return [[self alloc] init];
}

+ (instancetype)treeNodeWithRepresentedObject:(id<PKGObjectProtocol>)inRepresentedObject children:(NSArray *)inChildren
{
	return [[self alloc] initWithRepresentedObject:inRepresentedObject children:inChildren];
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

- (instancetype)initWithRepresentedObject:(id<PKGObjectProtocol>)inRepresentedObject children:(NSArray *)inChildren
{
	self=[super init];
	
	if (self!=nil)
	{
		_representedObject=inRepresentedObject;
		
		if (inChildren!=nil)
		{
			_children=[inChildren mutableCopy];
		
			[_children makeObjectsPerformSelector:@selector(setParent:) withObject:self];
		}
		else
		{
			_children=[NSMutableArray array];
		}
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
			if ([tChildrenRepresentation isKindOfClass:NSArray.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGTreeNodeChildrenKey}];
				
				return nil;
			}
			
			_children=[[tChildrenRepresentation WB_arrayByMappingObjectsUsingBlock:^id(NSDictionary * bChildRepresentation,__attribute__((unused))NSUInteger bIndex){
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
	
	NSArray * tChildrenRepresentation=[_children WB_arrayByMappingObjectsUsingBlock:^id(PKGTreeNode * bTreeNode,__attribute__((unused))NSUInteger bIndex){
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
	PKGTreeNode * tParent=[self parent];
	
	if (tParent==nil)
		return nil;
	
	NSIndexPath * tParentIndexPath=[tParent indexPath];
	
	NSUInteger tIndex=[[tParent children] indexOfObject:self];
	
	if (tParentIndexPath==nil)
		return [NSIndexPath indexPathWithIndex:tIndex];
	
	return [tParentIndexPath indexPathByAddingIndex:tIndex];
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

#pragma mark -

- (NSUInteger)indexOfChildIdenticalTo:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return NSNotFound;
	
	return [_children indexOfObjectIdenticalTo:inTreeNode];
}

#pragma mark -

- (void)addChild:(PKGTreeNode *)inChild
{
	[inChild setParent:self];
	[_children addObject:inChild];
}

- (void)addChildren:(NSArray *)inChildren
{
	[inChildren makeObjectsPerformSelector:@selector(setParent:) withObject:self];
	[_children addObjectsFromArray:inChildren];
}

- (void)insertChild:(PKGTreeNode *)inChild atIndex:(NSUInteger)inIndex
{
	if (inChild==nil || inIndex>[_children count])
		return;
	
	[inChild setParent:self];
	[_children insertObject:inChild atIndex:inIndex];
}

- (void)insertChildren:(NSArray *)inChildren atIndex:(NSUInteger)inIndex
{
	if ([inChildren count]==0 || inIndex>[_children count])
		return;
	
	[inChildren makeObjectsPerformSelector:@selector(setParent:) withObject:self];
	[_children insertObjects:inChildren atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(inIndex, [inChildren count])]];
}


- (void)insertAsSiblingOfNodes:(NSMutableArray *)inSiblings sortedUsingComparator:(NSComparator)inComparator
{
	if (inSiblings==nil || inComparator==nil)
		return;
	
	if ([inSiblings isKindOfClass:[NSMutableArray class]]==NO)
		return;
	
	if (inSiblings.count==0)
	{
		[inSiblings addObject:self];
		return;
	}
	
	[_children enumerateObjectsUsingBlock:^(PKGTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		if (inComparator(self,bTreeNode)!=NSOrderedDescending)
		{
			[self setParent:bTreeNode.parent];
			[_children insertObject:self atIndex:bIndex];
			*bOutStop=YES;
		}
	}];
}

- (void)insertAsSiblingOfNodes:(NSMutableArray *)inSiblings sortedUsingSelector:(SEL)inComparator
{
	if (inSiblings==nil || inComparator==nil)
		return;
	
	if ([inSiblings isKindOfClass:[NSMutableArray class]]==NO)
		return;
	
	if (inSiblings.count==0)
	{
		[inSiblings addObject:self];
		return;
	}
	
	NSInvocation * tInvocation=[NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:inComparator]];
	tInvocation.target=self;
	tInvocation.selector=inComparator;
	
	[_children enumerateObjectsUsingBlock:^(PKGTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		NSComparisonResult tComparisonResult;
		
		[tInvocation setArgument:&bTreeNode atIndex:2];
		[tInvocation invoke];
		[tInvocation getReturnValue:&tComparisonResult];
		
		if (tComparisonResult!=NSOrderedDescending)
		{
			[self setParent:bTreeNode.parent];
			[_children insertObject:self atIndex:bIndex];
			*bOutStop=YES;
		}
	}];
}

- (void)insertChild:(PKGTreeNode *)inChild sortedUsingComparator:(NSComparator)inComparator
{
	if (inChild==nil || inComparator==nil)
		return;
	
	if (_children.count==0)
	{
		[_children addObject:inChild];
		return;
	}
	
	[_children enumerateObjectsUsingBlock:^(PKGTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		if (inComparator(inChild,bTreeNode)!=NSOrderedDescending)
		{
			[inChild setParent:self];
			[_children insertObject:inChild atIndex:bIndex];
			*bOutStop=YES;
		}
	}];
}


- (void)insertChild:(PKGTreeNode *)inChild sortedUsingSelector:(SEL)inComparator
{
	if (inChild==nil || inComparator==nil)
		return;
	
	NSInvocation * tInvocation=[NSInvocation invocationWithMethodSignature:[inChild methodSignatureForSelector:inComparator]];
	tInvocation.target=inChild;
	tInvocation.selector=inComparator;
	
	if (_children.count==0)
	{
		[_children addObject:inChild];
		return;
	}
	
	[_children enumerateObjectsUsingBlock:^(PKGTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		NSComparisonResult tComparisonResult;
		
		[tInvocation setArgument:&bTreeNode atIndex:2];
		[tInvocation invoke];
		[tInvocation getReturnValue:&tComparisonResult];
		
		if (tComparisonResult!=NSOrderedDescending)
		{
			[inChild setParent:self];
			[_children insertObject:inChild atIndex:bIndex];
			*bOutStop=YES;
		}
	}];
}

- (void)removeChildAtIndex:(NSUInteger)inIndex
{
	if (inIndex>=[_children count])
		return;
	
	PKGTreeNode * tTreeNode=_children[inIndex];
	
	[tTreeNode setParent:nil];
	
	[_children removeObjectAtIndex:inIndex];
}

- (void)removeChildrenAtIndexes:(NSIndexSet *)inIndexSet
{
	if (inIndexSet==nil || [inIndexSet lastIndex]>=[_children count])
		return;
	
	[_children enumerateObjectsAtIndexes:inIndexSet options:0 usingBlock:^(PKGTreeNode *bTreeNode,__attribute__((unused))NSUInteger bIndex,__attribute__((unused))BOOL * boutStop){
	
		[bTreeNode setParent:nil];
	}];
	
	[_children removeObjectsAtIndexes:inIndexSet];
}

- (void)removeChild:(PKGTreeNode *)inChild
{
	if (inChild==nil)
		return;
	
	[inChild setParent:nil];
	[_children removeObjectIdenticalTo:inChild];
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

#pragma mark -

/* Code from the Apple Sample Code */

+ (NSArray *)minimumNodeCoverFromNodesInArray:(NSArray *)inArray
{
	NSMutableArray *tMinimumNodeCover = [NSMutableArray array];
	NSMutableArray * tNodeQueue = [NSMutableArray arrayWithArray:inArray];
	PKGTreeNode *tTreeNode = nil;
	
	while ([tNodeQueue count])
	{
		tTreeNode = tNodeQueue[0];
		[tNodeQueue removeObjectAtIndex:0];
		
		PKGTreeNode *tTreeNodeParent=[tTreeNode parent];
		
		while ( tTreeNodeParent && [tNodeQueue indexOfObjectIdenticalTo:tTreeNodeParent]!=NSNotFound)
		{
			[tNodeQueue removeObjectIdenticalTo: tTreeNode];
			tTreeNode = tTreeNodeParent;
			tTreeNodeParent=tTreeNode.parent;
		}
		
		if (![tTreeNode isDescendantOfNodeInArray: tMinimumNodeCover])
			[tMinimumNodeCover addObject: tTreeNode];
		
		[tNodeQueue removeObjectIdenticalTo: tTreeNode];
	}
	
	return [tMinimumNodeCover copy];
}

#pragma mark -

- (BOOL)_enumerateRepresentedObjectsRecursivelyUsingBlock:(void(^)(id<PKGObjectProtocol> representedObject,BOOL *stop))block
{
	BOOL tBlockDidStop=NO;

	(void)block(self.representedObject,&tBlockDidStop);
	if (tBlockDidStop==YES)
		return NO;

	for(PKGTreeNode * tTreeNode in self.children)
	{
		if ([tTreeNode _enumerateRepresentedObjectsRecursivelyUsingBlock:block]==NO)
			return NO;
	}
	
	return YES;
}
																													  																																												
- (void)enumerateRepresentedObjectsRecursivelyUsingBlock:(void(^)(id<PKGObjectProtocol> representedObject,BOOL *stop))block
{
	[self _enumerateRepresentedObjectsRecursivelyUsingBlock:block];
}

@end


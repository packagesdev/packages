/*
 Copyright (c) 2016-2017, Stephane Sudre
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
	
	id<PKGObjectProtocol,NSCopying> _representedObject;
	
	NSMutableArray * _children;
}

- (void)setParent:(PKGTreeNode *)inParent;

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

- (instancetype)initWithRepresentedObject:(id<PKGObjectProtocol,NSCopying>)inRepresentedObject children:(NSArray *)inChildren
{
	self=[super init];
	
	if (self!=nil)
	{
		_representedObject=inRepresentedObject;
		_parent=nil;
		
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
					tCode=PKGRepresentationInvalidValueError;
				
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
						tCode=PKGRepresentationInvalidValueError;
					
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
		tRepresentation=tRepresentedObjectRepresentation;
	
	NSArray * tChildrenRepresentation=[_children WB_arrayByMappingObjectsUsingBlock:^id(PKGTreeNode * bTreeNode,__attribute__((unused))NSUInteger bIndex){
		return [bTreeNode representation];
	}];
	
	if (tChildrenRepresentation.count>0)
		tRepresentation[PKGTreeNodeChildrenKey]=tChildrenRepresentation;
	else
	{
		static dispatch_once_t onceToken;
		static NSArray * sEmptyChildrenArray=nil;
		
		dispatch_once(&onceToken, ^{
			sEmptyChildrenArray=[NSArray array];
		});
		
		tRepresentation[PKGTreeNodeChildrenKey]=sEmptyChildrenArray;
	}
	
	return tRepresentation;
}

#pragma mark -

/*- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	// A COMPLETER
	
	return tDescription;
}*/

- (PKGTreeNode *)deepCopy
{
	return [self deepCopyWithZone:nil];
}

- (PKGTreeNode *)deepCopyWithZone:(NSZone *)inZone
{
	PKGTreeNode * nTreeNode=[[[self class] allocWithZone:inZone] init];
	
	if (nTreeNode!=nil)
	{
		nTreeNode->_representedObject=[_representedObject copyWithZone:inZone];
		
		for(PKGTreeNode * tChild in _children)
		{
			PKGTreeNode * nChild=[tChild deepCopyWithZone:inZone];
			
			if (nChild==nil)
				return nil;
			
			nChild.parent=self;
			
			[nTreeNode->_children addObject:nChild];
		}
	}
	
	return nTreeNode;
}

#pragma mark -

- (Class)representedObjectClassForRepresentation:(NSDictionary *)inRepresentation
{
	NSLog(@"You need to define the class of the represented object");
	
	return nil;
}

- (id<PKGObjectProtocol,NSCopying>)representedObject
{
	return _representedObject;
}

- (void)setRepresentedObject:(id<PKGObjectProtocol,NSCopying>)inRepresentedObject
{
	if (_representedObject!=inRepresentedObject)
		_representedObject=inRepresentedObject;
}

#pragma mark -

- (NSUInteger)height
{
	if (_children.count==0)
		return 0;
	
	NSUInteger tMaxChildHeight=0;
	
	for(PKGTreeNode * tChild in _children)
	{
		NSUInteger tChildHeight=[tChild height];
		
		if (tChildHeight>tMaxChildHeight)
			tMaxChildHeight=tChildHeight;
	}
	
	return (tMaxChildHeight+1);
}

- (NSUInteger)numberOfNodes
{
	NSUInteger tCount=1;
	
	for(PKGTreeNode * tChild in _children)
		tCount+=[tChild numberOfNodes];
	
	return tCount;
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
	return _children.count;
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

/*- (PKGTreeNode *)descendantNodeAtIndexPath:(NSIndexPath *)inIndexPath
{
	return nil;
}*/

- (PKGTreeNode *)childNodeAtIndex:(NSUInteger)inIndex
{
	if (inIndex>=_children.count)
		return nil;
	
	return [_children objectAtIndex:inIndex];
}

- (PKGTreeNode *)childNodeMatching:(BOOL (^)(id bTreeNode))inBlock
{
	if (inBlock==nil)
		return nil;
	
	for(PKGTreeNode * tChild in _children)
	{
		if (inBlock(tChild)==YES)
			return tChild;
	}
	
	return nil;
}

#pragma mark -

- (NSUInteger)indexOfChildIdenticalTo:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return NSNotFound;
	
	return [_children indexOfObjectIdenticalTo:inTreeNode];
}

- (NSUInteger)indexOfChildMatching:(BOOL (^)(id bTreeNode))inBlock
{
	if (inBlock==nil)
		return NSNotFound;
	
	__block NSUInteger tChildIndex=NSNotFound;
	
	[_children enumerateObjectsUsingBlock:^(PKGTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
	
		if (inBlock(bTreeNode)==YES)
		{
			tChildIndex=bIndex;
			*bOutStop=YES;
		}
	
	}];
	
	return tChildIndex;
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

- (BOOL)addUnmatchedDescendantsOfNode:(PKGTreeNode *)inTreeNode usingSelector:(SEL)inComparator
{
	if (inTreeNode==nil)
		return NO;
	
	__block BOOL tDidAddDescendants=NO;
	
	NSInvocation * tInvocation=[NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:inComparator]];
	tInvocation.selector=inComparator;
	
	for(PKGTreeNode * tDescendant in inTreeNode.children)
	{
		__block BOOL tMatched=NO;
		
		tInvocation.target=tDescendant;
		
		[_children enumerateObjectsUsingBlock:^(PKGTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
			
			NSComparisonResult tComparisonResult;
			
			[tInvocation setArgument:&bTreeNode atIndex:2];
			[tInvocation invoke];
			[tInvocation getReturnValue:&tComparisonResult];
			
			if (tComparisonResult==NSOrderedSame)
			{
				tMatched=YES;
				
				// Checked with the descendants
				
				tDidAddDescendants=[bTreeNode addUnmatchedDescendantsOfNode:tDescendant usingSelector:inComparator];
				*bOutStop=YES;
			}
		}];
					
		if (tMatched==NO)
		{
			tDidAddDescendants=YES;
			[tDescendant insertAsSiblingOfChildren:_children ofNode:self sortedUsingSelector:inComparator];
		}
	}
	
	return tDidAddDescendants;
}

- (PKGTreeNode *)filterRecursivelyUsingBlock:(BOOL (^)(id bTreeNode))inBlock
{
	return [self filterRecursivelyUsingBlock:inBlock maximumDepth:NSNotFound];
}

- (PKGTreeNode *)filterRecursivelyUsingBlock:(BOOL (^)(id bTreeNode))inBlock maximumDepth:(NSUInteger)inMaximumDepth
{
	if (inBlock==nil)
		return self;
	
	if (inMaximumDepth>0)
	{
		if (inMaximumDepth!=NSNotFound)
			inMaximumDepth--;
		
		NSUInteger tCount=_children.count;
		
		for(NSUInteger tIndex=tCount;tIndex>0;tIndex--)
		{
			PKGTreeNode * tResult=[_children[tIndex-1] filterRecursivelyUsingBlock:inBlock maximumDepth:inMaximumDepth];
			
			if (tResult==nil)
				[_children removeObjectAtIndex:tIndex-1];
		}
	}
	
	if (inBlock(self)==NO)
		return nil;
	
	return self;
}

- (void)insertChild:(PKGTreeNode *)inChild atIndex:(NSUInteger)inIndex
{
	if (inChild==nil || inIndex>_children.count)
		return;
	
	[inChild setParent:self];
	[_children insertObject:inChild atIndex:inIndex];
}

- (void)insertChildren:(NSArray *)inChildren atIndex:(NSUInteger)inIndex
{
	if (inChildren.count==0 || inIndex>_children.count)
		return;
	
	[inChildren makeObjectsPerformSelector:@selector(setParent:) withObject:self];
	[_children insertObjects:inChildren atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(inIndex, inChildren.count)]];
}


- (void)insertAsSiblingOfChildren:(NSMutableArray *)inChildren ofNode:(PKGTreeNode *)inParent sortedUsingComparator:(NSComparator)inComparator
{
	if (inChildren==nil || inComparator==nil)
		return;
	
	if ([inChildren isKindOfClass:NSMutableArray.class]==NO)
		return;
	
	if (inChildren.count==0)
	{
		[self setParent:inParent];
		[inChildren addObject:self];
		return;
	}
	
	__block BOOL tInserted=NO;
	
	[_children enumerateObjectsUsingBlock:^(PKGTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		if (inComparator(self,bTreeNode)!=NSOrderedDescending)
		{
			[self setParent:inParent];
			[inChildren insertObject:self atIndex:bIndex];
			tInserted=YES;
			*bOutStop=YES;
		}
	}];
	
	if (tInserted==0)
	{
		[self setParent:inParent];
		[inChildren addObject:self];
		return;
	}
}

- (void)insertAsSiblingOfChildren:(NSMutableArray *)inChildren ofNode:(PKGTreeNode *)inParent sortedUsingSelector:(SEL)inSelector
{
	if (inChildren==nil || inSelector==nil)
		return;
	
	if ([inChildren isKindOfClass:NSMutableArray.class]==NO)
		return;
	
	NSInvocation * tInvocation=[NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:inSelector]];
	tInvocation.target=self;
	tInvocation.selector=inSelector;
	
	__block BOOL tInserted=NO;
	
	[inChildren enumerateObjectsUsingBlock:^(PKGTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		NSComparisonResult tComparisonResult;
		
		[tInvocation setArgument:&bTreeNode atIndex:2];
		[tInvocation invoke];
		[tInvocation getReturnValue:&tComparisonResult];
		
		if (tComparisonResult!=NSOrderedDescending)
		{
			[self setParent:inParent];
			[inChildren insertObject:self atIndex:bIndex];
			tInserted=YES;
			*bOutStop=YES;
		}
	}];
	
	if (tInserted==0)
	{
		[self setParent:inParent];
		[inChildren addObject:self];
		return;
	}
}

- (void)insertChild:(PKGTreeNode *)inChild sortedUsingComparator:(NSComparator)inComparator
{
	if (inChild==nil || inComparator==nil)
		return;
	
	__block BOOL tDone=NO;
	
	[_children enumerateObjectsUsingBlock:^(PKGTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		if (inComparator(inChild,bTreeNode)!=NSOrderedDescending)
		{
			[inChild setParent:self];
			[self->_children insertObject:inChild atIndex:bIndex];
			
			tDone=YES;
			*bOutStop=YES;
		}
	}];
	
	if (tDone==YES)
		return;
	
	[inChild setParent:self];
	[_children addObject:inChild];
}


- (void)insertChild:(PKGTreeNode *)inChild sortedUsingSelector:(SEL)inSelector
{
	if (inChild==nil || inSelector==nil)
		return;
	
	NSInvocation * tInvocation=[NSInvocation invocationWithMethodSignature:[inChild methodSignatureForSelector:inSelector]];
	tInvocation.target=inChild;
	tInvocation.selector=inSelector;
	
	__block BOOL tDone=NO;
	
	[_children enumerateObjectsUsingBlock:^(PKGTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		NSComparisonResult tComparisonResult;
		
		[tInvocation setArgument:&bTreeNode atIndex:2];
		[tInvocation invoke];
		[tInvocation getReturnValue:&tComparisonResult];
		
		if (tComparisonResult!=NSOrderedDescending)
		{
			[inChild setParent:self];
			[self->_children insertObject:inChild atIndex:bIndex];
			
			tDone=YES;
			*bOutStop=YES;
		}
	}];
	
	if (tDone==YES)
		return;
	
	[inChild setParent:self];
	[_children addObject:inChild];
}

- (void)removeChildAtIndex:(NSUInteger)inIndex
{
	if (inIndex>=_children.count)
		return;
	
	PKGTreeNode * tTreeNode=_children[inIndex];
	
	[tTreeNode setParent:nil];
	
	[_children removeObjectAtIndex:inIndex];
}

- (void)removeChildrenAtIndexes:(NSIndexSet *)inIndexSet
{
	if (inIndexSet==nil || inIndexSet.lastIndex>=_children.count)
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
	
	NSUInteger tIndex=[_children indexOfObjectIdenticalTo:inChild];
	
	if (tIndex==NSNotFound)
		return;
	
	[inChild setParent:nil];
	[_children removeObjectAtIndex:tIndex];
}

- (void)removeChildrenInArray:(NSArray *)inArray
{
	NSMutableIndexSet * tIndexSet=[NSMutableIndexSet indexSet];
	
	[inArray enumerateObjectsUsingBlock:^(PKGTreeNode * bObject, NSUInteger bIndex, BOOL *bOutStop) {
		
		if ([self->_children containsObject:bObject]==YES)
		{
			[tIndexSet addIndex:bIndex];
			
			[bObject setParent:nil];
		}
	}];
	
	[_children removeObjectsAtIndexes:tIndexSet];
}

- (void)removeAllChildren
{
	[_children makeObjectsPerformSelector:@selector(setParent:) withObject:nil];
	[_children removeAllObjects];
}

- (void)removeFromParent
{
	[[self parent] removeChild:self];
}

- (void)sortChildrenUsingComparator:(NSComparator)inComparator
{
	if (inComparator==nil)
		return;
	
	[_children sortUsingComparator:inComparator];
}

- (void)sortChildrenUsingSelector:(SEL)inSelector
{
	if (inSelector==nil)
		return;
	
	[_children sortUsingSelector:inSelector];
}

#pragma mark -

/* Code from the Apple Sample Code */

+ (NSArray *)minimumNodeCoverFromNodesInArray:(NSArray *)inArray
{
	NSMutableArray *tMinimumNodeCover = [NSMutableArray array];
	NSMutableArray * tNodeQueue = [NSMutableArray arrayWithArray:inArray];
	PKGTreeNode *tTreeNode = nil;
	
	while (tNodeQueue.count)
	{
		tTreeNode = tNodeQueue[0];
		[tNodeQueue removeObjectAtIndex:0];
		
		PKGTreeNode *tTreeNodeParent=[tTreeNode parent];
		
		while (tTreeNodeParent && [tNodeQueue indexOfObjectIdenticalTo:tTreeNodeParent]!=NSNotFound)
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

+ (BOOL)nodesAreSiblings:(NSArray *)inTreeNodes
{
	NSUInteger tCount=inTreeNodes.count;
	
	if (tCount==0)
		return NO;
	
	if (tCount==1)
		return YES;
	
	PKGTreeNode * tParentNode=[((PKGTreeNode *)inTreeNodes[0]) parent];
	
	for(NSUInteger tIndex=1;tIndex<tCount;tIndex++)
	{
		if (tParentNode!=[((PKGTreeNode *)inTreeNodes[tIndex]) parent])
			return NO;
	}
	
	return YES;
}

#pragma mark -

- (void)enumerateRepresentedObjectsRecursivelyUsingBlock:(void(^)(id<PKGObjectProtocol> representedObject,BOOL *))block
{
	typedef void (^_recursiveBlock)(id<PKGObjectProtocol>,BOOL *);
	
	__block __weak BOOL (^_weakEnumerateRepresentedObjectsRecursively)(PKGTreeNode *,_recursiveBlock);
	__block BOOL(^_enumerateRepresentedObjectsRecursively)(PKGTreeNode *,_recursiveBlock);
	
	
	_enumerateRepresentedObjectsRecursively = ^BOOL(PKGTreeNode * bTreeNode,_recursiveBlock bBlock)
	{
		BOOL tBlockDidStop=NO;
		
		(void)block([bTreeNode representedObject],&tBlockDidStop);
		if (tBlockDidStop==YES)
			return NO;
		
		for(PKGTreeNode * tTreeNode in bTreeNode->_children)
		{
			if (_weakEnumerateRepresentedObjectsRecursively(tTreeNode,bBlock)==NO)
				return NO;
		}
		
		return YES;
	};
	
	_weakEnumerateRepresentedObjectsRecursively = _enumerateRepresentedObjectsRecursively;
	
	_enumerateRepresentedObjectsRecursively(self,block);
}

- (void)enumerateNodesUsingBlock:(void(^)(id bTreeNode,BOOL *))block
{
	typedef void (^_recursiveBlock)(id,BOOL *);
	
	__block __weak BOOL (^_weakEnumerateNodesRecursively)(PKGTreeNode *,_recursiveBlock);
	__block BOOL(^_enumerateNodesRecursively)(PKGTreeNode *,_recursiveBlock);
	
	_enumerateNodesRecursively = ^BOOL(PKGTreeNode * bTreeNode,_recursiveBlock bBlock)
	{
		BOOL tBlockDidStop=NO;
		
		(void)block(bTreeNode,&tBlockDidStop);
		if (tBlockDidStop==YES)
			return NO;
		
		for(PKGTreeNode * tTreeNode in bTreeNode->_children)
		{
			if (_weakEnumerateNodesRecursively(tTreeNode,bBlock)==NO)
				return NO;
		}
		
		return YES;
	};
	
	_weakEnumerateNodesRecursively = _enumerateNodesRecursively;
	
	_enumerateNodesRecursively(self,block);
}

- (void)enumerateNodesLenientlyUsingBlock:(void(^)(id bTreeNode,BOOL *bSkipChildren,BOOL *))block
{
	typedef void (^_recursiveBlock)(id,BOOL *,BOOL *);
	
	__block __weak BOOL (^_weakEnumerateNodesLenientlyRecursively)(PKGTreeNode *,_recursiveBlock);
	__block BOOL(^_enumerateNodesLenientlyRecursively)(PKGTreeNode *,_recursiveBlock);
	
	_enumerateNodesLenientlyRecursively = ^BOOL(PKGTreeNode * bTreeNode,_recursiveBlock bBlock)
	{
		BOOL tSkipChildren=NO;
		BOOL tBlockDidStop=NO;
		
		(void)block(bTreeNode,&tSkipChildren,&tBlockDidStop);
		if (tBlockDidStop==YES)
			return NO;
		
		if (tSkipChildren==YES)
			return YES;
		
		for(PKGTreeNode * tTreeNode in bTreeNode->_children)
		{
			if (_weakEnumerateNodesLenientlyRecursively(tTreeNode,bBlock)==NO)
				return NO;
		}
		
		return YES;
	};
	
	_weakEnumerateNodesLenientlyRecursively = _enumerateNodesLenientlyRecursively;
	
	_enumerateNodesLenientlyRecursively(self,block);
}

- (void)enumerateChildrenUsingBlock:(void(^)(id bTreeNode,BOOL *))block
{
	[_children enumerateObjectsUsingBlock:^(id bChild, NSUInteger bIndex, BOOL *bOutStop) {
		
		block(bChild,bOutStop);
	}];
}

@end


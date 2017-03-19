/*
 Copyright (c) 2016-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#import "PKGObjectProtocol.h"

@interface PKGTreeNode : NSObject <PKGObjectProtocol>

+ (instancetype)treeNodeWithRepresentedObject:(id<PKGObjectProtocol>)inRepresentedObject children:(NSArray *)inChildren;

- (instancetype)initWithRepresentedObject:(id<PKGObjectProtocol>)inRepresentedObject children:(NSArray *)inChildren;

- (PKGTreeNode *)deepCopy;

- (id<PKGObjectProtocol,NSCopying>)representedObject;

- (void)setRepresentedObject:(id<PKGObjectProtocol,NSCopying>)inRepresentedObject;

- (Class)representedObjectClassForRepresentation:(NSDictionary *)inRepresentation;

- (NSUInteger)height;

- (NSUInteger)numberOfNodes;

- (BOOL)isLeaf;

- (NSIndexPath *)indexPath;

- (PKGTreeNode *)parent;

- (NSUInteger)numberOfChildren;
- (NSArray *)children;

- (BOOL)isDescendantOfNode:(PKGTreeNode *)inTreeNode;
- (BOOL)isDescendantOfNodeInArray:(NSArray *)inTreeNodes;

- (PKGTreeNode *)descendantNodeAtIndex:(NSUInteger)inIndex;
- (PKGTreeNode *)descendantNodeAtIndexPath:(NSIndexPath *)inIndexPath;
- (PKGTreeNode *)descendantNodeMatching:(BOOL (^)(id bTreeNode))inBlock;

- (NSUInteger)indexOfChildIdenticalTo:(PKGTreeNode *)inTreeNode;
- (NSUInteger)indexOfChildMatching:(BOOL (^)(id bTreeNode))inBlock;

- (void)addChild:(PKGTreeNode *)inChild;
- (void)addChildren:(NSArray *)inChildren;

- (BOOL)addUnmatchedDescendantsOfNode:(PKGTreeNode *)inTreeNode usingSelector:(SEL)inComparator;
- (PKGTreeNode *)filterRecursivelyUsingBlock:(BOOL (^)(id bTreeNode))inBlock;
- (PKGTreeNode *)filterRecursivelyUsingBlock:(BOOL (^)(id bTreeNode))inBlock maximumDepth:(NSUInteger)inMaximumDepth;


- (void)insertChild:(PKGTreeNode *)inChild atIndex:(NSUInteger)inIndex;
- (void)insertChildren:(NSArray *)inChildren atIndex:(NSUInteger)inIndex;

- (void)insertAsSiblingOfChildren:(NSMutableArray *)inChildren ofNode:(PKGTreeNode *)inParent sortedUsingComparator:(NSComparator)inComparator;
- (void)insertAsSiblingOfChildren:(NSMutableArray *)inChildren ofNode:(PKGTreeNode *)inParent sortedUsingSelector:(SEL)inSelector;

- (void)insertChild:(PKGTreeNode *)inChild sortedUsingComparator:(NSComparator)inComparator;
- (void)insertChild:(PKGTreeNode *)inChild sortedUsingSelector:(SEL)inComparator;

- (void)removeChildAtIndex:(NSUInteger)inIndex;
- (void)removeChildrenAtIndexes:(NSIndexSet *)inIndexSet;
- (void)removeChild:(PKGTreeNode *)inChild;
- (void)removeChildren;
- (void)removeFromParent;

- (void)sortChildrenUsingComparator:(NSComparator)inComparator;
- (void)sortChildrenUsingSelector:(SEL)inSelector;

+ (NSArray *)minimumNodeCoverFromNodesInArray:(NSArray *)inArray;

- (void)enumerateRepresentedObjectsRecursivelyUsingBlock:(void(^)(id<PKGObjectProtocol> representedObject,BOOL *stop))block;

- (void)enumerateNodesUsingBlock:(void(^)(id bTreeNode,BOOL *stop))block;

@end


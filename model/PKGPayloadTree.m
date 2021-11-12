/*
 Copyright (c) 2016-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadTree.h"

#import "PKGPackagesError.h"

@interface PKGPayloadTreeNode (EmptyRootTreeNode)

+ (instancetype)emptyRootTreeNode;

@end

@implementation PKGPayloadTreeNode (EmptyRootTreeNode)

+ (instancetype)emptyRootTreeNode
{
	PKGPayloadTreeNode * tRootTreeNode=[[PKGPayloadTreeNode alloc] initWithRepresentedObject:[PKGFileItem folderTemplateWithName:@"/"
																															 uid:0
																															 gid:0
																													 permissions:0755]
																					children:nil];
	
	return tRootTreeNode;
}

@end

@interface PKGPayloadTree ()
{
	NSDictionary * _cachedRepresentation;
}

@end

@implementation PKGPayloadTree

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_rootNode=[PKGPayloadTreeNode emptyRootTreeNode];
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
		_cachedRepresentation=inRepresentation;
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	if (_cachedRepresentation!=nil)
		return [_cachedRepresentation mutableCopy];
	
	return [self.rootNode representation];
}

#pragma mark -

- (PKGPayloadTreeNode *)rootNode
{
	if (_rootNode==nil)
	{
		if (_cachedRepresentation!=nil)
		{
			NSError * tError=nil;
			
			_rootNode=[[PKGPayloadTreeNode alloc] initWithRepresentation:_cachedRepresentation error:&tError];
			
			if (_rootNode==nil)
			{
				//NSLog(@"%@ %d %@",tError.domain,(int)tError.code,tError.userInfo);
				
				// A COMPLETER
			}
			
			_cachedRepresentation=nil;
		}
	}
	
	return _rootNode;
}

#pragma mark - PKGRootNodesProtocol

- (PKGRootNodesTuple *)rootNodes
{
	PKGPayloadTreeNode * tRootNode=self.rootNode;
	
	if (tRootNode==nil)
		return [PKGRootNodesTuple rootNodeTupleWithArray:nil error:[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidValueError userInfo:nil]];	// A COMPLETER
	
	return [PKGRootNodesTuple rootNodeTupleWithArray:[NSMutableArray arrayWithObject:tRootNode] error:nil];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)inZone
{
	PKGPayloadTree * nPayloadtree=[[[self class] allocWithZone:inZone] init];
	
	if (nPayloadtree!=nil)
	{
		if (_cachedRepresentation!=nil)
		{
			nPayloadtree->_cachedRepresentation=[_cachedRepresentation copyWithZone:inZone];
			nPayloadtree.rootNode=nil;
		}
		else
		{
			nPayloadtree.rootNode=(PKGPayloadTreeNode *)[self.rootNode deepCopyWithZone:inZone];
		}
	}
	
	return nPayloadtree;
}

@end

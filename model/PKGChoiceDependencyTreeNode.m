/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGChoiceDependencyTreeNode.h"

#import "PKGPackagesError.h"

NSString * const PKGChoiceDependencyTreeLogicNodeTopChildKey=@"TOP";

NSString * const PKGChoiceDependencyTreeLogicNodeOperatorKey=@"OPERATOR";

NSString * const PKGChoiceDependencyTreeLogicNodeBottomChildKey=@"BOTTOM";


NSString * const PKGChoiceDependencyTreePredicateNodeChoiceUUIDKey=@"UUID";

NSString * const PKGChoiceDependencyTreePredicateNodeOperatorKey=@"COMPARATOR";

NSString * const PKGChoiceDependencyTreePredicateNodeStateKey=@"OBJECT";


@implementation PKGChoiceDependencyTreeNode

+ (id)dependencyTreeNodeWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	if (inRepresentation[PKGChoiceDependencyTreeLogicNodeTopChildKey]!=nil)
		return [[PKGChoiceDependencyTreeLogicNode alloc] initWithRepresentation:inRepresentation error:outError];
	
	if (inRepresentation[PKGChoiceDependencyTreePredicateNodeChoiceUUIDKey]!=nil)
		return [[PKGChoiceDependencyTreePredicateNode alloc] initWithRepresentation:inRepresentation error:outError];

	if (outError!=NULL)
		*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidValueError userInfo:nil];
	
	return nil;
}

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
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
	
	return self;
}

- (void)dealloc
{
	_parentNode=nil;
}

- (NSMutableDictionary *)representation
{
	return [NSMutableDictionary dictionary];
}

#pragma mark -

- (void)enumerateNodesUsingBlock:(void(^)(id bTreeNode,BOOL *bOutStop))block
{
	typedef void (^_recursiveBlock)(id,BOOL *);
	
	__block __weak BOOL (^_weakEnumerateNodesRecursively)(PKGChoiceDependencyTreeNode *,_recursiveBlock);
	__block BOOL(^_enumerateNodesRecursively)(PKGChoiceDependencyTreeNode *,_recursiveBlock);
	
	_enumerateNodesRecursively = ^BOOL(PKGChoiceDependencyTreeNode * bTreeNode,_recursiveBlock bBlock)
	{
		BOOL tBlockDidStop=NO;
		
		(void)block(bTreeNode,&tBlockDidStop);
		if (tBlockDidStop==YES)
			return NO;
		
		if ([bTreeNode isKindOfClass:PKGChoiceDependencyTreeLogicNode.class]==NO)
			return YES;
		
		PKGChoiceDependencyTreeLogicNode * tLogicNode=(PKGChoiceDependencyTreeLogicNode *)bTreeNode;
		
		if (_weakEnumerateNodesRecursively(tLogicNode.topChildNode,bBlock)==NO)
			return NO;
		
		if (_weakEnumerateNodesRecursively(tLogicNode.bottomChildNode,bBlock)==NO)
			return NO;
		
		return YES;
	};
	
	_weakEnumerateNodesRecursively = _enumerateNodesRecursively;
	
	_enumerateNodesRecursively(self,block);
}

- (void)enumeratePredicatesNodesUsingBlock:(void(^)(id bTreeNode,BOOL *bOutStop))block
{
	typedef void (^_recursiveBlock)(id,BOOL *);
	
	__block __weak BOOL (^_weakEnumerateNodesRecursively)(PKGChoiceDependencyTreeNode *,_recursiveBlock);
	__block BOOL(^_enumerateNodesRecursively)(PKGChoiceDependencyTreeNode *,_recursiveBlock);
	
	_enumerateNodesRecursively = ^BOOL(PKGChoiceDependencyTreeNode * bTreeNode,_recursiveBlock bBlock)
	{
		if ([bTreeNode isKindOfClass:PKGChoiceDependencyTreeLogicNode.class]==NO)
		{
			BOOL tBlockDidStop=NO;
		
			(void)block(bTreeNode,&tBlockDidStop);
			if (tBlockDidStop==YES)
				return NO;
			
			return YES;
		}
		
		PKGChoiceDependencyTreeLogicNode * tLogicNode=(PKGChoiceDependencyTreeLogicNode *)bTreeNode;
		
		if (_weakEnumerateNodesRecursively(tLogicNode.topChildNode,bBlock)==NO)
			return NO;
		
		if (_weakEnumerateNodesRecursively(tLogicNode.bottomChildNode,bBlock)==NO)
			return NO;
		
		return YES;
	};
	
	_weakEnumerateNodesRecursively = _enumerateNodesRecursively;
	
	_enumerateNodesRecursively(self,block);
}

@end




@implementation PKGChoiceDependencyTreeLogicNode

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	NSError * tError=nil;
	
	self=[super initWithRepresentation:inRepresentation error:&tError];
	
	if (self!=nil)
	{
		_topChildNode=[PKGChoiceDependencyTreeNode dependencyTreeNodeWithRepresentation:inRepresentation[PKGChoiceDependencyTreeLogicNodeTopChildKey] error:&tError];
		
		if (_topChildNode==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValueError;
				
				NSString * tPathError=PKGChoiceDependencyTreeLogicNodeTopChildKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
		}
		
		_topChildNode.parentNode=self;
		
		NSNumber * tNumber=inRepresentation[PKGChoiceDependencyTreeLogicNodeOperatorKey];
		
		PKGFullCheckNumberValueForKey(tNumber,PKGChoiceDependencyTreeLogicNodeOperatorKey);
		
		_operatorType=[tNumber unsignedIntegerValue];
		
		if (_operatorType>PKGLogicOperatorTypeDisjunction)
		{
			if (outError!=NULL)
			{
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGChoiceDependencyTreeLogicNodeOperatorKey}];
			}
			
			return nil;
		}
		
		_bottomChildNode=[PKGChoiceDependencyTreeNode dependencyTreeNodeWithRepresentation:inRepresentation[PKGChoiceDependencyTreeLogicNodeBottomChildKey] error:&tError];
		
		if (_bottomChildNode==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValueError;
				
				NSString * tPathError=PKGChoiceDependencyTreeLogicNodeBottomChildKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
		}
		
		_bottomChildNode.parentNode=self;
	}
	else
	{
		if (outError!=NULL)
			*outError=tError;
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[super representation];
	
	tRepresentation[PKGChoiceDependencyTreeLogicNodeTopChildKey]=[self.topChildNode representation];
	
	tRepresentation[PKGChoiceDependencyTreeLogicNodeOperatorKey]=@(self.operatorType);
	
	tRepresentation[PKGChoiceDependencyTreeLogicNodeBottomChildKey]=[self.bottomChildNode representation];
	
	return tRepresentation;
}

@end





@implementation PKGChoiceDependencyTreePredicateNode

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	NSError * tError=nil;
	
	self=[super initWithRepresentation:inRepresentation error:&tError];
	
	if (self!=nil)
	{
		NSString * tString=inRepresentation[PKGChoiceDependencyTreePredicateNodeChoiceUUIDKey];
		
		PKGFullCheckStringValueForKey(tString, PKGChoiceDependencyTreePredicateNodeChoiceUUIDKey);
		
		_choiceUUID=[tString copy];
		
		
		NSNumber * tNumber=inRepresentation[PKGChoiceDependencyTreePredicateNodeOperatorKey];
		
		PKGFullCheckNumberValueForKey(tNumber,PKGChoiceDependencyTreePredicateNodeOperatorKey);
		
		_operatorType=[tNumber unsignedIntegerValue];
		
		if (_operatorType>PKGPredicateOperatorTypeNotEqualTo)
		{
			if (outError!=NULL)
			{
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGChoiceDependencyTreePredicateNodeOperatorKey}];
			}
			
			return nil;
		}
		
		tNumber=inRepresentation[PKGChoiceDependencyTreePredicateNodeStateKey];
		
		PKGFullCheckNumberValueForKey(tNumber,PKGChoiceDependencyTreePredicateNodeStateKey);
		
		_referenceState=[tNumber unsignedIntegerValue];
		
		if (_referenceState>PKGPredicateReferenceStateSelected)
		{
			if (outError!=NULL)
			{
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGChoiceDependencyTreePredicateNodeStateKey}];
			}
			
			return nil;
		}
	}
	else
	{
		if (outError!=NULL)
			*outError=tError;
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[super representation];
	
	tRepresentation[PKGChoiceDependencyTreePredicateNodeChoiceUUIDKey]=self.choiceUUID;
	
	tRepresentation[PKGChoiceDependencyTreePredicateNodeOperatorKey]=@(self.operatorType);
	
	tRepresentation[PKGChoiceDependencyTreePredicateNodeStateKey]=@(self.referenceState);
	
	return tRepresentation;
}

@end

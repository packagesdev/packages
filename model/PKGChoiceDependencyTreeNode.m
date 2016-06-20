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

@implementation PKGChoiceDependencyTreeNode

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
	
	return self;
}

- (NSMutableDictionary *)representation
{
	return [NSMutableDictionary dictionary];
}

@end


NSString * const PKGChoiceDependencyTreeLogicNodeTopChildKey=@"TOP";

NSString * const PKGChoiceDependencyTreeLogicNodeOperatorKey=@"OPERATOR";

NSString * const PKGChoiceDependencyTreeLogicNodeBottomChildKey=@"BOTTOM";

@implementation PKGChoiceDependencyTreeLogicNode

- (id) initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	NSError * tError=nil;
	
	self=[super initWithRepresentation:inRepresentation error:&tError];
	
	if (self!=nil)
	{
		_topChildNode=[[PKGChoiceDependencyTreeNode alloc] initWithRepresentation:inRepresentation[PKGChoiceDependencyTreeLogicNodeTopChildKey] error:&tError];
		
		if (_topChildNode==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=PKGChoiceDependencyTreeLogicNodeTopChildKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
		}
		
		NSNumber * tNumber=inRepresentation[PKGChoiceDependencyTreeLogicNodeOperatorKey];
		
		PKGFullCheckNumberValueForKey(tNumber,PKGChoiceDependencyTreeLogicNodeOperatorKey);
		
		_operatorType=[tNumber unsignedIntegerValue];
		
		if (_operatorType>PKGLogicOperatorTypeDisjunction)
		{
			if (outError!=NULL)
			{
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValue
										  userInfo:@{PKGKeyPathErrorKey:PKGChoiceDependencyTreeLogicNodeOperatorKey}];
			}
			
			return nil;
		}
		
		_bottomChildNode=[[PKGChoiceDependencyTreeNode alloc] initWithRepresentation:inRepresentation[PKGChoiceDependencyTreeLogicNodeBottomChildKey] error:&tError];
		
		if (_bottomChildNode==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=PKGChoiceDependencyTreeLogicNodeBottomChildKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
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
	
	tRepresentation[PKGChoiceDependencyTreeLogicNodeTopChildKey]=[self.topChildNode representation];
	
	tRepresentation[PKGChoiceDependencyTreeLogicNodeOperatorKey]=@(self.operatorType);
	
	tRepresentation[PKGChoiceDependencyTreeLogicNodeBottomChildKey]=[self.bottomChildNode representation];
	
	return tRepresentation;
}

@end


NSString * const PKGChoiceDependencyTreePredicateNodeChoiceUUIDKey=@"UUID";

NSString * const PKGChoiceDependencyTreePredicateNodeOperatorKey=@"COMPARATOR";

NSString * const PKGChoiceDependencyTreePredicateNodeStateKey=@"OBJECT";


@implementation PKGChoiceDependencyTreePredicateNode

- (id) initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
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
											  code:PKGRepresentationInvalidValue
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
											  code:PKGRepresentationInvalidValue
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

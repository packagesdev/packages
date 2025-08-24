/*
 Copyright (c) 2017-2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDocumentRegistry.h"

@interface PKGDocumentRegistry ()
{
	NSMutableDictionary * _dictionary;
}

@end

@implementation PKGDocumentRegistry

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_dictionary=[NSMutableDictionary dictionary];
	}
	
	return self;
}

#pragma mark -

- (id)objectForKey:(NSString *)inKey
{
	if (inKey==nil)
		return nil;
	
	return _dictionary[inKey];
}

- (BOOL)boolForKey:(NSString *)inKey
{
	if (inKey==nil)
		return 0;
	
	NSNumber * tNumber=_dictionary[inKey];
	
	if (tNumber==nil || [tNumber isKindOfClass:NSNumber.class]==NO)
		return NO;
	
	return [tNumber boolValue];
}

- (NSInteger)integerForKey:(NSString *)inKey
{
	if (inKey==nil)
		return 0;
	
	NSNumber * tNumber=_dictionary[inKey];
	
	if (tNumber==nil || [tNumber isKindOfClass:NSNumber.class]==NO)
		return 0;
	
	return tNumber.integerValue;
}

#pragma mark -

- (void)setObject:(id)inObject forKey:(NSString *)inKey
{
	if (inObject==nil)
	{
		[self removeObjectForKey:inKey];
		
		return;
	}
	
	if (inKey==nil)
		return;
	
	_dictionary[inKey]=inObject;
}

- (void)setBool:(BOOL)inBoolean forKey:(NSString *)inKey
{
	if (inKey==nil)
		return;
	
	_dictionary[inKey]=@(inBoolean);
}

- (void)setInteger:(NSInteger)inInteger forKey:(NSString *)inKey
{
	if (inKey==nil)
		return;
	
	_dictionary[inKey]=@(inInteger);
}

#pragma mark -

- (id)objectForKeyedSubscript:(id)inKey
{
	if (inKey==nil)
		return nil;
	
	return _dictionary[inKey];
}

- (void)setObject:(id)inObject forKeyedSubscript:(id)inKey
{
	if (inObject==nil)
	{
		[self removeObjectForKey:inKey];
		
		return;
	}
	
	if (inKey==nil)
		return;
	
	_dictionary[inKey]=inObject;
}

#pragma mark -

- (void)removeObjectForKey:(NSString *)inKey
{
	if (inKey==nil)
		return;
	
	[_dictionary removeObjectForKey:inKey];
}

- (void)removeObjectForKeys:(NSArray *)inKeys
{
	if (inKeys.count==0)
		return;
	
	[_dictionary removeObjectsForKeys:inKeys];
}

@end

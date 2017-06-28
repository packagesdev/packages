/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGFileFilter.h"

#import "PKGPackagesError.h"

#import "NSArray+WBExtensions.h"

#import "RegexKitLite.h"

NSString * const PKGFilePredicateFileTypeKey=@"TYPE";

NSString * const PKGFilePredicateRegularExpressionKey=@"REGULAR_EXPRESSION";

NSString * const PKGFilePredicatePatternKey=@"STRING";


@implementation PKGFilePredicate

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_fileType=PKGFileSystemTypeFile;
		
		_regularExpression=NO;
		
		_pattern=@"";
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
		_fileType=[inRepresentation[PKGFilePredicateFileTypeKey] unsignedIntegerValue];
		
		if (_fileType>PKGFileSystemTypeFileOrFolder)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGFilePredicateFileTypeKey}];
			
			return nil;
		}
		
		_regularExpression=[inRepresentation[PKGFilePredicateRegularExpressionKey] boolValue];
		
		if ([inRepresentation[PKGFilePredicatePatternKey] isKindOfClass:NSString.class]==NO)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidTypeOfValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGFilePredicatePatternKey}];
			
			return nil;
		}
		
		_pattern=[inRepresentation[PKGFilePredicatePatternKey] copy];
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	tRepresentation[PKGFilePredicateFileTypeKey]=@(self.fileType);
	
	tRepresentation[PKGFilePredicateRegularExpressionKey]=@(self.regularExpression);
	
	tRepresentation[PKGFilePredicatePatternKey]=self.pattern;
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendString:@"      Type: "];
	 
	 switch(self.fileType)
	{
		case PKGFileSystemTypeFile:
			[tDescription appendString:@"File\n"];
			break;
			
		case PKGFileSystemTypeFolder:
			[tDescription appendString:@"Folder\n"];
			break;
			
		case PKGFileSystemTypeFileOrFolder:
			[tDescription appendString:@"File or Folder\n"];
			break;
			
	}
	
	[tDescription appendFormat:@"      Regular Expression: %@\n",(self.regularExpression==YES)? @"Yes" : @"No"];
	
	[tDescription appendFormat:@"      Pattern: \"%@\"\n",self.pattern];
	
	return tDescription;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)inZone
{
	PKGFilePredicate * nFilePredicate=[[[self class] allocWithZone:inZone] init];
	
	if (nFilePredicate!=nil)
	{
		nFilePredicate.fileType=self.fileType;
		nFilePredicate.regularExpression=self.regularExpression;
		nFilePredicate.pattern=[self.pattern copyWithZone:inZone];
	}
	
	return nFilePredicate;
}

#pragma mark -

- (BOOL)matchesFileNamed:(NSString *)inFileName ofType:(PKGFileSystemType)inType
{
	if (inFileName==nil)
		return NO;
	
	if (self.fileType!=PKGFileSystemTypeFileOrFolder && self.fileType!=inType)
		return NO;
	
	if ([self.pattern length]==0)
		return NO;
	
	if (self.regularExpression==YES)
		return [inFileName isMatchedByRegex:self.pattern options:RKLNoOptions inRange:((NSRange){0, NSUIntegerMax}) error:NULL];
	
	return ([self.pattern caseInsensitiveCompare:inFileName]==NSOrderedSame);
}

@end

NSString * const PKGFileFilterSeparatorKey=@"SEPARATOR";

NSString * const PKGFileFilterProtectedKey=@"PROTECTED";

@implementation PKGFileFilterFactory

+ (id<PKGFileFilterProtocol>)filterWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	if ([inRepresentation[PKGFileFilterSeparatorKey] boolValue]==YES)
	{
		NSError * tError=nil;
		
		PKGSeparatorFilter * tSeparatorFilter=[[PKGSeparatorFilter alloc] initWithRepresentation:inRepresentation error:&tError];
		
		if (tSeparatorFilter==nil)
		{
			if (outError!=NULL)
				*outError=tError;
		}
		
		return tSeparatorFilter;
	}
	
	if ([inRepresentation[PKGFileFilterProtectedKey] boolValue]==YES)
	{
		NSError * tError=nil;
		
		PKGDefaultFileFilter * tDefaultFileFilter=[[PKGDefaultFileFilter alloc] initWithRepresentation:inRepresentation error:&tError];
		
		if (tDefaultFileFilter==nil)
		{
			if (outError!=NULL)
				*outError=tError;
		}
		
		return tDefaultFileFilter;
	}
	
	NSError * tError=nil;
	
	PKGFileFilter * tFileFilter=[[PKGFileFilter alloc] initWithRepresentation:inRepresentation error:&tError];
	
	if (tFileFilter==nil)
	{
		if (outError!=NULL)
			*outError=tError;
	}
	
	return tFileFilter;
}

@end



@implementation PKGSeparatorFilter

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	self=[super init];
	
	return self;
}

- (NSMutableDictionary *) representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	tRepresentation[PKGFileFilterSeparatorKey]=@(YES);
	
	return tRepresentation;
}

#pragma mark -

- (BOOL)isSeparator
{
	return YES;
}

- (BOOL)isProtected
{
	return YES;
}

#pragma mark -

- (NSString *)description
{
	return @"    Separator\n";
}

- (id)copyWithZone:(NSZone *)inZone
{
	PKGSeparatorFilter * nSeparatorFilter=[[[self class] allocWithZone:inZone] init];
	
	return nSeparatorFilter;
}

@end


NSString * const PKGFileFilterEnabledKey=@"STATE";

NSString * const PKGFileFilterPredicatesKey=@"PATTERNS_ARRAY";

@interface PKGFileFilter ()

@property (readwrite) NSArray * predicates;

@end

@implementation PKGFileFilter

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_enabled=YES;
		
		_predicates=[NSArray arrayWithObject:[PKGFilePredicate new]];
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
		_enabled=[inRepresentation[PKGFileFilterEnabledKey] boolValue];
		
		__block NSError * tError=nil;
		
		if (inRepresentation[PKGFileFilterPredicatesKey]==nil)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationNilRepresentationError userInfo:nil];
		}
		
		if ([inRepresentation[PKGFileFilterPredicatesKey] isKindOfClass:NSArray.class]==NO)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidTypeOfValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGFileFilterPredicatesKey}];
			
			return nil;
		}
		
		_predicates=[inRepresentation[PKGFileFilterPredicatesKey] WB_arrayByMappingObjectsUsingBlock:^id(NSDictionary * bPredicateRepresentation, __attribute__((unused))NSUInteger bIndex){
			return [[PKGFilePredicate alloc] initWithRepresentation:bPredicateRepresentation error:&tError];
		}];
		
		if (_predicates==nil)
		{
			if (outError!=NULL)
				*outError=tError;
			
			return nil;
		}
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	tRepresentation[PKGFileFilterProtectedKey]=@(NO);
	
	tRepresentation[PKGFileFilterEnabledKey]=@(self.enabled);
	
	tRepresentation[PKGFileFilterPredicatesKey]=[self.predicates WB_arrayByMappingObjectsUsingBlock:^id(PKGFilePredicate * bPredicate,__attribute__((unused))NSUInteger bIndex){
		return [bPredicate representation];
	}];
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendFormat:@"    Enabled: %@\n",(self.enabled==YES)? @"Yes" : @"No"];
	
	[tDescription appendFormat:@"    Predicates(%lu):\n\n",(unsigned long)self.predicates.count];
	
	for(PKGFilePredicate * tPredicate in self.predicates)
	{
		[tDescription appendString:[tPredicate description]];
		
		[tDescription appendString:@"\n"];
	}
	
	return tDescription;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)inZone
{
	PKGFileFilter * nFileFilter=[[[self class] allocWithZone:inZone] init];
	
	if (nFileFilter!=nil)
	{
		nFileFilter.enabled=self.enabled;
		nFileFilter.predicates=[_predicates WB_arrayByMappingObjectsUsingBlock:^PKGFilePredicate *(PKGFilePredicate * bPredicate, NSUInteger bIndex) {
			return [bPredicate copyWithZone:inZone];
		}];
	}
	
	return nFileFilter;
}

#pragma mark -

- (BOOL)isSeparator
{
	return NO;
}

- (BOOL)isProtected
{
	return NO;
}

#pragma mark -

- (PKGFilePredicate *)predicate
{
	if (self.predicates.count==1)
		return self.predicates[0];
	
	return [PKGFilePredicate new];
}

- (void)setPredicate:(PKGFilePredicate *)inPredicate
{
	if (inPredicate==nil)
		self.predicates=@[];
	else
		self.predicates=@[inPredicate];
}

#pragma mark -

- (BOOL)matchesFileNamed:(NSString *)inFileName ofType:(PKGFileSystemType)inType
{
	if (inFileName==nil || self.enabled==NO)
		return NO;
	
	for(PKGFilePredicate * tPredicate in self.predicates)
	{
		if ([tPredicate matchesFileNamed:inFileName ofType:inType]==YES)
			return YES;
	}
	
	return NO;
}

@end


NSString * const PKGFileFilterDisplayNameKey=@"PROXY_NAME";

NSString * const PKGFileFilterToolTipKey=@"PROXY_TOOLTIP";


@interface PKGDefaultFileFilter ()

	@property (readwrite) NSString * displayName;

	@property (readwrite) NSString * tooltip;

@end

@implementation PKGDefaultFileFilter

@dynamic predicates;

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_displayName=@"";
		_tooltip=@"";
	}
	
	return self;
}

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	NSError * tError=nil;
	
	self=[super initWithRepresentation:inRepresentation error:&tError];
	
	if (self!=nil)
	{
		NSString * tString=inRepresentation[PKGFileFilterDisplayNameKey];
		
		PKGFullCheckStringValueForKey(tString,PKGFileFilterDisplayNameKey);
		
		_displayName=[tString copy];
		
		
		tString=inRepresentation[PKGFileFilterToolTipKey];
		
		PKGFullCheckStringValueForKey(tString,PKGFileFilterToolTipKey);
		
		_tooltip=[tString copy];
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
	
	tRepresentation[PKGFileFilterProtectedKey]=@(YES);
	
	tRepresentation[PKGFileFilterDisplayNameKey]=self.displayName;
	
	if (self.tooltip!=nil)
		tRepresentation[PKGFileFilterToolTipKey]=self.tooltip;
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	if ([self isSeparator]==YES)
		return [NSMutableString stringWithString:@"    Separator\n"];
		
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendFormat:@"    Display name: %@\n",self.displayName];
	[tDescription appendFormat:@"    Tool Tip: %@\n",self.tooltip];
	
	[tDescription appendString:[super description]];
	
	return tDescription;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)inZone
{
	PKGDefaultFileFilter * nDefaultFileFilter=[super copyWithZone:inZone];
	
	if (nDefaultFileFilter!=nil)
	{
		nDefaultFileFilter.displayName=[self.displayName copyWithZone:inZone];
		nDefaultFileFilter.tooltip=[self.tooltip copyWithZone:inZone];
	}
	
	return nDefaultFileFilter;
}

@end

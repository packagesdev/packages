/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGFilePath.h"

#import "PKGPackagesError.h"

NSString * const PKGFilePathTypeKey=@"PATH_TYPE";

NSString * const PKGFilePathStringKey=@"PATH";

@implementation PKGFilePath

+(instancetype)filePath
{
    return [[PKGFilePath alloc] init];
}

+(instancetype)filePathWithAbsolutePath:(NSString *)inPath
{
	if (inPath==nil)
		return nil;
	
	return [PKGFilePath filePathWithString:inPath type:PKGFilePathTypeAbsolute];
}

+ (instancetype)filePathWithName:(NSString *)inName
{
	if (inName==nil)
		return nil;
	
	return [PKGFilePath filePathWithString:inName type:PKGFilePathTypeName];
}

+(instancetype)filePathWithString:(NSString *)inString type:(PKGFilePathType)inType
{
    return [[PKGFilePath alloc] initWithString:inString type:inType];
}

+ (NSString *)lastPathComponentFromRepresentation:(NSDictionary *)inRepresentation
{
	if (inRepresentation==nil)
		return nil;
	
	return [inRepresentation[PKGFilePathStringKey] lastPathComponent];
}

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_type=PKGFilePathTypeAbsolute;
		
		_string=nil;
	}
	
	return self;
}

- (instancetype)initWithString:(NSString *)inString type:(PKGFilePathType)inType
{
	self=[super init];
	
	if (self!=nil)
	{
		_type=inType;
		
		_string=[inString copy];
	}
	
	return self;
}

- (id) initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
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
		_type=[inRepresentation[PKGFilePathTypeKey] unsignedIntegerValue];
		
		if (_type>PKGFilePathTypeMixed)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValue
										  userInfo:@{PKGKeyPathErrorKey:PKGFilePathTypeKey}];
			
			return nil;
		}
		
		_string=[inRepresentation[PKGFilePathStringKey] copy];
	}
	
	return self;
}

- (NSMutableDictionary *) representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	if(self.string==nil)
		return tRepresentation;
	
	tRepresentation[PKGFilePathTypeKey]=@(self.type);
	
	tRepresentation[PKGFilePathStringKey]=[self.string copy];
	
	return tRepresentation;
}

#pragma mark -

- (id)copyWithZone:(NSZone *)inZone
{
	return [[[self class] alloc] initWithString:self.string type:self.type];
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	switch(self.type)
	{
		case PKGFilePathTypeAbsolute:
			[tDescription appendString:@"(Absolute) "];
			break;
			
		case PKGFilePathTypeRelativeToProject:
			[tDescription appendString:@"(Project Relative) "];
			break;
			
		case PKGFilePathTypeName:
			return @"Name";
			
		case PKGFilePathTypeRelativeToReferenceFolder:
			[tDescription appendString:@"(Folder Relative) "];
			break;
			
		default:
			return @"Mixed";
	}
	
	[tDescription appendFormat:@"%@\n",self.string];
	
	return tDescription;
}

#pragma mark -

- (NSString *)lastPathComponent
{
	if(self.string==nil)
		return nil;
	
	return [self.string lastPathComponent];
}

- (BOOL)isSet
{
	return (self.string!=nil);
}

#pragma mark -

- (BOOL)isEqualToFilePath:(PKGFilePath *)inFilePath
{
	if (inFilePath==nil)
		return NO;
	
	if ([inFilePath isKindOfClass:PKGFilePath.class]==NO)
		return NO;
	
	if (self.type!=inFilePath.type)
		return NO;
	
	if (inFilePath.string==nil)
		return (self.string==nil);
	
	return [self.string isEqualToString:inFilePath.string];
}

@end

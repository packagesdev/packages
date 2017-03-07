/*
Copyright (c) 2008-2010, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGRequirementConverter.h"

@interface PKGAdditionalResource ()

	@property (readwrite) PKGFilePath * filePath;

	@property (readwrite) mode_t mode;

@end

@implementation PKGAdditionalResource

- (instancetype)initWithFilePath:(PKGFilePath *)inFilePath mode:(mode_t)inMode
{
	self=[super init];
	
	if (self!=nil)
	{
		_filePath=inFilePath;
		_mode=inMode;
	}
	
	return self;
}

- (NSUInteger)hash
{
	return [self.filePath hash];
}

@end



@interface PKGRequirementConverter ()
{
	NSBundle * _bundle;
}

@end

@implementation PKGRequirementConverter

- (id)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_bundle=[NSBundle bundleForClass:[self class]];
		
		if (_bundle==nil)
		{
			NSLog(@"[PKGRequirementConverter init] Unable to locate the bundle");
			return nil;
		}
	}
	
	return self;
}

#pragma mark -

- (NSDictionary *)requiredOptionsValuesWithParameters:(NSDictionary *) inParameters
{
	return nil;
}

- (NSArray *)requiredAdditionalResourcesWithParameters:(NSDictionary *) inParameters
{
	return nil;
}

- (PKGRequirementType)requirementTypeWithParameters:(NSDictionary *) inParameters
{
	return PKGRequirementTypeUndefined;
}

- (NSSet *)sharedConstantsNames
{
	NSString * tPath=[_bundle pathForResource:@"Constants" ofType:@"plist"];
	
	if (tPath==nil)
		return nil;
	
	NSDictionary * tDictionary=[NSDictionary dictionaryWithContentsOfFile:tPath];
	
	if (tDictionary==nil)
		return nil;
	
	NSArray * tNames=tDictionary[@"Names"];
	
	if ([tNames isKindOfClass:NSArray.class]==NO || [tNames count]==0)
		return nil;
	
	return [NSSet setWithArray:tNames];
}

- (NSString *)constantsForNames:(NSSet *)inNames
{
	if ([inNames count]==0)
		return nil;
	
	NSString * tPath=[_bundle pathForResource:@"Constants" ofType:@"plist"];
	
	if (tPath==nil)
		return nil;
	
	NSDictionary * tDictionary=[NSDictionary dictionaryWithContentsOfFile:tPath];
	
	if (tDictionary==nil)
		return nil;
	
	NSDictionary * tDefinitionsDictionary=tDictionary[@"Definitions"];
	
	if (tDefinitionsDictionary==nil)
		return nil;
	
	NSMutableString * tString=[NSMutableString string];
	
	for(NSString * tConstantName in inNames)
	{
		NSString * tValue=tDefinitionsDictionary[tConstantName];
		
		if (tValue!=nil)
		{
			NSString * tDefinitionString=[NSString stringWithFormat:@"\tconst %@=%@;\n",tConstantName,tValue];
			
			if (tDefinitionString!=nil)
				[tString appendString:tDefinitionString];
		}
	}
	
	return tString;
}

- (NSString *)variablesWithIndex:(NSInteger) inIndex tabulationDepth:(NSString *) inTabulationDepth parameters:(NSDictionary *) inParameters error:(NSError **) outError
{
	return @"";
}

- (NSDictionary *) sharedConstants
{
	NSString * tPath=[_bundle pathForResource:@"Constants" ofType:@"plist"];
	
	if (tPath==nil)
		return nil;
	
	return [NSDictionary dictionaryWithContentsOfFile:tPath];
}

- (NSDictionary *) sharedFunctionsImplementation
{
	NSString * tPath=[_bundle pathForResource:@"Functions" ofType:@"plist"];
	
	if (tPath==nil)
		return nil;
	
	return [NSDictionary dictionaryWithContentsOfFile:tPath];
}

- (NSString *) invocationWithFormat:(NSString *) inFormat parameters:(NSDictionary *) inParameters index:(NSInteger) inIndex error:(NSError **) outError
{
	// To implement in subclass
	
	return nil;
}

- (NSString *) invocationWithParameters:(NSDictionary *) inParameters index:(NSInteger) inIndex error:(NSError **) outError
{
	NSString * tString=NSLocalizedStringFromTableInBundle(@"InvocationFormat",@"Code",_bundle,@"");
	
	if (tString!=nil && inParameters!=nil)
		return [self invocationWithFormat:tString parameters:inParameters index:inIndex error:outError];
	
	return tString;
}

@end

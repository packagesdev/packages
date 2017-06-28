/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGProject.h"

#import "PKGPackagesError.h"

#import "PKGPackageProject.h"
#import "PKGDistributionProject.h"


NSString * const PKGFormatVersionKey=@"VERSION";
NSString * const PKGProjectTypeKey=@"TYPE";
NSString * const PKGProjectKey=@"PROJECT";
NSString * const PKGProjectCommentsKey=@"PROJECT_COMMENTS";

#define PKGPackagesVersion_2	2

const NSUInteger PKGPackagesVersioNumber=PKGPackagesVersion_2;


@interface PKGProject ()

	@property (readwrite) NSUInteger formatVersion;

@end


@implementation PKGProject

+ (id)projectFromPropertyList:(id)inPropertyList error:(out NSError **)outError
{
	if (inPropertyList==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
										  code:PKGFileURLNilError
									  userInfo:nil];
		
		return nil;
	}
	
	if ([inPropertyList isKindOfClass:NSDictionary.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
										  code:PKGRepresentationInvalidTypeOfValueError
									  userInfo:nil];
		
		return nil;
	}
	
	NSDictionary * tDictionary=inPropertyList;
	
	NSNumber * tNumber=tDictionary[PKGProjectTypeKey];
	
	if (tNumber==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
										  code:PKGRepresentationInvalidValueError
									  userInfo:@{PKGKeyPathErrorKey:PKGProjectTypeKey}];
		
		return nil;
	}
	
	PKGProjectType tProjectType=[tNumber unsignedIntegerValue];
	
	NSError * tError=nil;
	
	switch(tProjectType)
	{
		case PKGProjectTypeDistribution:
		{
			PKGDistributionProject * tDistributionProject=[[PKGDistributionProject alloc] initWithRepresentation:tDictionary error:&tError];
			
			if (tDistributionProject==nil)
			{
				if (outError!=NULL)
					*outError=tError;
			}
			
			return tDistributionProject;
		}
			
		case PKGProjectTypePackage:
		{
			PKGPackageProject * tPackageProject=[[PKGPackageProject alloc] initWithRepresentation:tDictionary error:&tError];
			
			if (tPackageProject==nil)
			{
				if (outError!=NULL)
					*outError=tError;
			}
			
			return tPackageProject;
		}
	}
	
	if (outError!=NULL)
		*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
									  code:PKGRepresentationInvalidValueError
								  userInfo:@{PKGKeyPathErrorKey:PKGProjectTypeKey}];
	
	return nil;
}

+ (id)projectWithContentsOfFile:(NSString *)inPath error:(out NSError **)outError
{
	NSError * tError=nil;
	
	PKGProject * tProject=[[PKGProject alloc] initWithContentsOfFile:inPath error:&tError];
	
	if (tProject==nil)
	{
		if (outError!=NULL)
			*outError=tError;
	}
	
	return tProject;
}

+ (id)projectWithContentsOfURL:(NSURL *)inURL  error:(out NSError **)outError
{
	NSError * tError=nil;
	
	PKGProject * tProject=[[PKGProject alloc] initWithContentsOfURL:inURL error:&tError];
	
	if (tProject==nil)
	{
		if (outError!=NULL)
			*outError=tError;
	}
	
	return tProject;
}

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_formatVersion=PKGPackagesVersioNumber;
	}
	
	return self;
}

- (id)initWithContentsOfFile:(NSString *)inPath error:(out NSError **)outError
{
	if (inPath==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGFilePathNilError userInfo:nil];
		
		return nil;
	}
	
	return [self initWithContentsOfURL:[NSURL fileURLWithPath:inPath] error:outError];
}

- (id)initWithContentsOfURL:(NSURL *)inURL error:(out NSError **)outError
{
	if (inURL==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
										  code:PKGFileURLNilError
									  userInfo:nil];
		
		return nil;
	}
	
	NSDictionary * tDictionary=[NSDictionary dictionaryWithContentsOfURL:inURL];
	
	if (tDictionary==nil)
	{
		if (outError!=NULL)
		{
			if ([inURL checkResourceIsReachableAndReturnError:outError] == NO)
				return nil;
		
		
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
										  code:PKGFileInvalidTypeOfFileError
									  userInfo:nil];
		}
		
		return nil;
	}
	
	if ([tDictionary isKindOfClass:NSDictionary.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
										  code:PKGRepresentationInvalidTypeOfValueError
									  userInfo:nil];
		
		return nil;
	}
	
	NSNumber * tNumber=tDictionary[PKGProjectTypeKey];
	
	if (tNumber==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
										  code:PKGRepresentationInvalidValueError
									  userInfo:@{PKGKeyPathErrorKey:PKGProjectTypeKey}];
		
		return nil;
	}
	
	PKGProjectType tProjectType=[tNumber unsignedIntegerValue];
	
	NSError * tError=nil;
	
	switch(tProjectType)
	{
		case PKGProjectTypeDistribution:
		{
			PKGDistributionProject * tDistributionProject=[[PKGDistributionProject alloc] initWithRepresentation:tDictionary error:&tError];
			
			if (tDistributionProject==nil)
			{
				if (outError!=NULL)
					*outError=tError;
			}
			
			return tDistributionProject;
		}
			
		case PKGProjectTypePackage:
		{
			PKGPackageProject * tPackageProject=[[PKGPackageProject alloc] initWithRepresentation:tDictionary error:&tError];
			
			if (tPackageProject==nil)
			{
				if (outError!=NULL)
					*outError=tError;
			}
			
			return tPackageProject;
		}
	}
	
	if (outError!=NULL)
		*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
									  code:PKGRepresentationInvalidValueError
								  userInfo:@{PKGKeyPathErrorKey:PKGProjectTypeKey}];
	
	return nil;
}

#pragma mark -

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
		NSNumber * tNumber=inRepresentation[PKGFormatVersionKey];
		
		if (tNumber!=nil)
			_formatVersion=[tNumber unsignedIntegerValue];
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	tRepresentation[PKGFormatVersionKey]=@(self.formatVersion);
	
	tRepresentation[PKGProjectTypeKey]=@(self.type);
	
	tRepresentation[PKGProjectKey]=[NSMutableDictionary dictionary];
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendFormat:@"(%@)\n",NSStringFromClass([self class])];
	
	[tDescription appendFormat:@"Format Version: %lu\n",(unsigned long)self.formatVersion];
	
	return tDescription;
}

#pragma mark -

- (BOOL)writeToFile:(NSString *)inPath atomically:(BOOL)inAtomically
{
	NSMutableDictionary * tMutableDictionary=[self representation];
	
	if (tMutableDictionary==nil)
		return NO;
	
	return [tMutableDictionary writeToFile:inPath atomically:inAtomically];
}

- (BOOL)writeToURL:(NSURL *)inURL atomically:(BOOL)inAtomically
{
	NSMutableDictionary * tMutableDictionary=[self representation];
	
	if (tMutableDictionary==nil)
		return NO;
	
	return [tMutableDictionary writeToURL:inURL atomically:inAtomically];
}

@end

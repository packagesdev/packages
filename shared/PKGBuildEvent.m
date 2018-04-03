/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGBuildEvent.h"

NSString * const PKGBuildEventFilePath=@"FilePath";

@implementation PKGBuildEvent

- (id)initWithRepresentation:(NSDictionary *)inRepresentation
{
	if (inRepresentation==nil || [inRepresentation isKindOfClass:[NSDictionary class]]==NO)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		// filePath
		
		NSString * tString=inRepresentation[PKGBuildEventFilePath];
		
		if (tString!=nil)
		{
			if ([tString isKindOfClass:[NSString class]]==NO)
				return nil;
			
			_filePath=[tString copy];
		}
	}
	
	return self;
}

+ (instancetype)eventWithFilePath:(NSString *)inFilePath
{
	if (inFilePath==nil)
		return nil;
	
	PKGBuildEvent * tBuildEvent=[[PKGBuildEvent alloc] init];
	
	if (tBuildEvent!=nil)
		tBuildEvent.filePath=inFilePath;
	
	return tBuildEvent;
}

- (NSDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	if (self.filePath!=nil)
		tRepresentation[PKGBuildEventFilePath]=self.filePath;
	
	return [tRepresentation copy];
}

@end

#pragma mark -

NSString * const PKGBuildErrorEventCodeKey=@"Code";

NSString * const PKGBuildErrorEventSubCodeKey=@"SubCode";

NSString * const PKGBuildErrorEventFileKindKey=@"FileKind";

NSString * const PKGBuildErrorEventOtherFileKey=@"OtherFile";

NSString * const PKGBuildErrorEventTagKey=@"Tag";


@implementation PKGBuildErrorEvent

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_code=PKGBuildErrorUnknown;
	}
	
	return self;
}

- (id)initWithRepresentation:(NSDictionary *)inRepresentation
{
	self=[super initWithRepresentation:inRepresentation];
	
	if (self!=nil)
	{
		// code
		
		NSNumber * tNumber=inRepresentation[PKGBuildErrorEventCodeKey];
		
		if (tNumber==nil || [tNumber isKindOfClass:[NSNumber class]]==NO)
			return nil;
			
		_code=[tNumber unsignedIntegerValue];
		
		// subcode
		
		tNumber=inRepresentation[PKGBuildErrorEventSubCodeKey];
		
		if (tNumber!=nil)
		{
			if ([tNumber isKindOfClass:[NSNumber class]]==NO)
				return nil;
			
			_subcode=[tNumber unsignedIntegerValue];
		}
		
		// fileKind
		
		tNumber=inRepresentation[PKGBuildErrorEventFileKindKey];
		
		if (tNumber!=nil)
		{
			if ([tNumber isKindOfClass:[NSNumber class]]==NO)
				return nil;
			
			_fileKind=[tNumber unsignedIntegerValue];
		}
		
		
		// tag
		
		NSString * tString=inRepresentation[PKGBuildErrorEventTagKey];
		
		if (tString!=nil)
		{
			if ([tString isKindOfClass:[NSString class]]==NO)
				return nil;
			
			_tag=[tString copy];
		}
		
		// otherFilePath
		
		tString=inRepresentation[PKGBuildErrorEventOtherFileKey];
		
		if (tString!=nil)
		{
			if ([tString isKindOfClass:[NSString class]]==NO)
				return nil;
			
			_otherFilePath=[tString copy];
		}
	}
	
	return self;
}

+ (instancetype)errorEventWithCode:(PKGBuildError)inCode
{
	PKGBuildErrorEvent * tBuildErrorEvent=[[PKGBuildErrorEvent alloc] init];
	
	if (tBuildErrorEvent!=nil)
	{
		tBuildErrorEvent.code=inCode;
	}
	
	return tBuildErrorEvent;
}

+ (instancetype)errorEventWithCode:(PKGBuildError)inCode filePath:(NSString *)inFilePath fileKind:(PKGBuildErrorFileKind)inKind
{
	if (inFilePath==nil)
		return nil;
	
	PKGBuildErrorEvent * tBuildErrorEvent=[[PKGBuildErrorEvent alloc] init];
	
	if (tBuildErrorEvent!=nil)
	{
		tBuildErrorEvent.code=inCode;
		tBuildErrorEvent.filePath=inFilePath;
		tBuildErrorEvent.fileKind=inKind;
	}
	
	return tBuildErrorEvent;
}

+ (instancetype)errorEventWithCode:(PKGBuildError)inCode tag:(NSString *)inTag
{
	if (inTag==nil)
		return nil;
	
	PKGBuildErrorEvent * tBuildErrorEvent=[[PKGBuildErrorEvent alloc] init];
	
	if (tBuildErrorEvent!=nil)
	{
		tBuildErrorEvent.code=inCode;
		tBuildErrorEvent.tag=inTag;
	}
	
	return tBuildErrorEvent;
}

- (NSDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[[super representation] mutableCopy];
	
	tRepresentation[PKGBuildErrorEventCodeKey]=@(self.code);
	
	if (self.subcode!=0)
		tRepresentation[PKGBuildErrorEventSubCodeKey]=@(self.subcode);
	
	if (self.fileKind!=0)
		tRepresentation[PKGBuildErrorEventFileKindKey]=@(self.fileKind);
	
	if (self.tag!=nil)
		tRepresentation[PKGBuildErrorEventTagKey]=[self.tag copy];
	
	if (self.otherFilePath!=nil)
		tRepresentation[PKGBuildErrorEventOtherFileKey]=[self.otherFilePath copy];
	
	return [tRepresentation copy];
}

@end

#pragma mark -

NSString * const PKGBuildInfoEventPackageUUIDKey=@"PackageUUID";

NSString * const PKGBuildInfoEventPackageNameKey=@"PackageName";

NSString * const PKGBuildInfoEventPackagesCountKey=@"PackagesCount";

@implementation PKGBuildInfoEvent

- (id)initWithRepresentation:(NSDictionary *)inRepresentation
{
	self=[super initWithRepresentation:inRepresentation];
	
	if (self!=nil)
	{
		// Package UUID
		
		NSString * tString=inRepresentation[PKGBuildInfoEventPackageUUIDKey];
		
		if (tString!=nil)
		{
			if ([tString isKindOfClass:[NSString class]]==NO)
				return nil;
			
			_packageUUID=[tString copy];
		}
		
		// Package Name
		
		tString=inRepresentation[PKGBuildInfoEventPackageNameKey];
		
		if (tString!=nil)
		{
			if ([tString isKindOfClass:[NSString class]]==NO)
				return nil;
			
			_packageName=[tString copy];
		}
		
		// Packages Count
		
		NSNumber * tNumber=inRepresentation[PKGBuildInfoEventPackagesCountKey];
		
		if (tNumber!=nil)
		{
			if ([tNumber isKindOfClass:[NSNumber class]]==NO)
				return nil;
			
			_packagesCount=[tNumber unsignedIntegerValue];
		}
	}
	
	return self;
}

+ (instancetype)infoEventWithPackageUUID:(NSString *)inUUID name:(NSString *)inName
{
	if (inUUID==nil)
		return nil;
	
	PKGBuildInfoEvent * tBuildInfoEvent=[[PKGBuildInfoEvent alloc] init];
	
	if (tBuildInfoEvent!=nil)
	{
		tBuildInfoEvent.packageUUID=[inUUID copy];
		
		tBuildInfoEvent.packageName=[inName copy];
	}
	
	return tBuildInfoEvent;
}

+ (instancetype)infoEventWithPackagesCount:(NSUInteger)inPackagesCount
{
	PKGBuildInfoEvent * tBuildInfoEvent=[[PKGBuildInfoEvent alloc] init];
	
	if (tBuildInfoEvent!=nil)
	{
		tBuildInfoEvent.packagesCount=inPackagesCount;
	}
	
	return tBuildInfoEvent;
}

- (NSDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[[super representation] mutableCopy];
	
	if (self.packageUUID!=nil)
		tRepresentation[PKGBuildInfoEventPackageUUIDKey]=[self.packageUUID copy];
	
	if (self.packageName!=nil)
		tRepresentation[PKGBuildInfoEventPackageNameKey]=[self.packageName copy];
	
	if (self.packagesCount>0)
		tRepresentation[PKGBuildInfoEventPackagesCountKey]=@(self.packagesCount);
	
	return [tRepresentation copy];
}

@end

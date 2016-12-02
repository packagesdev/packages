/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPackagePayload.h"

#import "PKGPackagesError.h"

NSString * const IPKGPackagePayloadTypeKey=@"PAYLOAD_TYPE";

NSString * const IPKGPackagePayloadDefaultInstallLocationKey=@"DEFAULT_INSTALL_LOCATION";

NSString * const IPKGPackagePayloadSplitForkIfNeededKey=@"SPLIT_FORKS";

NSString * const IPKGPackagePayloadHierarchyBaseVersion=@"VERSION";

NSString * const IPKGPackagePayloadHierarchyShowInvisibleFilesKey=@"SHOW_INVISIBLE";

NSString * const IPKGPackagePayloadHierarchyKey=@"HIERARCHY";

NSString * const IPKGPackagePayloadTreatMissingFilesAsWarningsKey=@"TREAT_MISSING_FILES_AS_WARNING";

@interface PKGPackagePayload ()
{
}

@end

@implementation PKGPackagePayload

+ (instancetype)emptyPayload
{
	return [[PKGPackagePayload alloc] init];
}

- (instancetype) init
{
	self=[super init];
	
	if (self!=nil)
	{
		_type=PKGPayloadInternal;
		
		_defaultInstallLocation=@"/";
		
		_splitForksIfNeeded=YES;
		
		_invisibleHierarchyIncluded=NO;
		
		_filesTree=[[PKGPayloadTree alloc] init];
		
		_treatMissingPayloadFilesAsWarnings=NO;
	}
	
	return self;
}

- (instancetype)initWithDefaultHierarchy:(NSDictionary *)inDefaultHierarchy error:(out NSError **)outError
{
	if (inDefaultHierarchy==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationNilRepresentationError userInfo:nil];
		
		return nil;
	}
	
	if ([inDefaultHierarchy isKindOfClass:NSDictionary.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
		
		return nil;
	}
	
	self=[super init];
	
	if (self!=nil)
	{
		_type=PKGPayloadInternal;
		
		_defaultInstallLocation=@"/";
		
		_splitForksIfNeeded=YES;
		
		_invisibleHierarchyIncluded=NO;
		
		NSNumber * tNumber=inDefaultHierarchy[IPKGPackagePayloadHierarchyBaseVersion];
		
		PKGFullCheckNumberValueForKey(tNumber,IPKGPackagePayloadHierarchyBaseVersion);
		
		_templateVersion=[tNumber unsignedIntegerValue];
		
		NSError * tError=nil;
		_filesTree=[[PKGPayloadTree alloc] initWithRepresentation:inDefaultHierarchy[IPKGPackagePayloadHierarchyKey] error:&tError];
		
		if (_filesTree==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=IPKGPackagePayloadHierarchyKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
		}
		
		_treatMissingPayloadFilesAsWarnings=NO;
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
		NSNumber * tNumber=inRepresentation[IPKGPackagePayloadTypeKey];
		
		PKGFullCheckNumberValueForKey(tNumber,IPKGPackagePayloadTypeKey);
		
		_type=[tNumber unsignedIntegerValue];
		
		if (_type>PKGPayloadExternal)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidValue
										  userInfo:@{PKGKeyPathErrorKey:IPKGPackagePayloadTypeKey}];
			
			return nil;
		}
		
		_defaultInstallLocation=[inRepresentation[IPKGPackagePayloadDefaultInstallLocationKey] copy];
		
		if (_defaultInstallLocation==nil)
		{
			_defaultInstallLocation=@"/";
		}
		else
		{
			if ([_defaultInstallLocation isKindOfClass:NSString.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:IPKGPackagePayloadDefaultInstallLocationKey}];
				
				return nil;
			}
		}
		
		if (inRepresentation[IPKGPackagePayloadSplitForkIfNeededKey]==nil)
			_splitForksIfNeeded=YES;
		else
			_splitForksIfNeeded=[inRepresentation[IPKGPackagePayloadSplitForkIfNeededKey] boolValue];
		
		
		tNumber=inRepresentation[IPKGPackagePayloadHierarchyBaseVersion];
		
		PKGFullCheckNumberValueForKey(tNumber,IPKGPackagePayloadHierarchyBaseVersion);
		
		_templateVersion=[tNumber unsignedIntegerValue];
		
		tNumber=inRepresentation[IPKGPackagePayloadHierarchyShowInvisibleFilesKey];
		
		PKGFullCheckNumberValueForKey(tNumber,IPKGPackagePayloadHierarchyShowInvisibleFilesKey);
		
		_invisibleHierarchyIncluded=[tNumber boolValue];
		
		NSError * tError=nil;
		
		_filesTree=[[PKGPayloadTree alloc] initWithRepresentation:inRepresentation[IPKGPackagePayloadHierarchyKey] error:&tError];
		
		if (_filesTree==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=IPKGPackagePayloadHierarchyKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:@{PKGKeyPathErrorKey:tPathError}];
			}
			
			return nil;
		}
		
		// A COMPLETER
		
		self.treatMissingPayloadFilesAsWarnings=[inRepresentation[IPKGPackagePayloadTreatMissingFilesAsWarningsKey] boolValue];
	}
	
	return self;
}

- (NSMutableDictionary *) representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	tRepresentation[IPKGPackagePayloadTypeKey]=@(self.type);
	
	tRepresentation[IPKGPackagePayloadDefaultInstallLocationKey]=self.defaultInstallLocation;
	
	tRepresentation[IPKGPackagePayloadSplitForkIfNeededKey]=@(self.splitForksIfNeeded);
	
	tRepresentation[IPKGPackagePayloadHierarchyBaseVersion]=@(self.templateVersion);
	
	tRepresentation[IPKGPackagePayloadHierarchyShowInvisibleFilesKey]=@(self.invisibleHierarchyIncluded);
	
	tRepresentation[IPKGPackagePayloadHierarchyKey]=[self.filesTree representation];
	
	// A COMPLETER
	
	tRepresentation[IPKGPackagePayloadTreatMissingFilesAsWarningsKey]=@(self.treatMissingPayloadFilesAsWarnings);
	
	return tRepresentation;
}

#pragma mark -

- (NSString *) description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendString:@"  Payload:\n"];
	[tDescription appendString:@"  -------\n\n"];
	
	[tDescription appendFormat:@"  Type: %@\n",(self.type==PKGPayloadInternal) ? @"Internal" : @"External"];
	
	[tDescription appendFormat:@"  Default Install Location: %@\n",self.defaultInstallLocation];
	
	[tDescription appendFormat:@"  Split Forks if Needed: %@\n",(self.splitForksIfNeeded==YES) ? @"Yes" : @"No"];
	
	[tDescription appendFormat:@"  Template Version: %lu\n",(unsigned long)self.templateVersion];
	
	[tDescription appendFormat:@"  Invisible Hierarchy Included: %@\n",(self.invisibleHierarchyIncluded==YES) ? @"Yes" : @"No"];
	
	// A COMPLETER
	
	return tDescription;
}

@end

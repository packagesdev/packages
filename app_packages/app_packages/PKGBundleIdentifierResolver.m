/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGBundleIdentifierResolver.h"

@interface PKGBundleIdentifierResolver ()
{
	NSMutableDictionary * _cachedResolutions;
	
	NSLock * _lock;
	
	NSWorkspace * _workspace;
	
	dispatch_queue_t _resolutionQueue;
}

@end

@implementation PKGBundleIdentifierResolver

+ (PKGBundleIdentifierResolver *)sharedResolver
{
	static PKGBundleIdentifierResolver * sResolver=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sResolver=[PKGBundleIdentifierResolver new];
	});

	return sResolver;
}

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_cachedResolutions=[NSMutableDictionary dictionary];
		
		_lock=[NSLock new];
		
		_workspace=[NSWorkspace sharedWorkspace];
		
		_resolutionQueue=dispatch_queue_create("bundle.identifier.resolution.queue", NULL);
	}
	
	return self;
}

#pragma mark -

- (NSString *)resolveBundleIdentifier:(NSString *)inBundleIdentifier completionHandler:(void (^)(NSString *))handler
{
	if (inBundleIdentifier==nil)
		return nil;
	
	NSString * tResolution=nil;
	
	[_lock lock];
	
	tResolution=_cachedResolutions[inBundleIdentifier];
	
	[_lock unlock];
	
	if (tResolution!=nil)
		return tResolution;
	
	dispatch_async(_resolutionQueue, ^{
		
		NSURL * tURL=[_workspace URLForApplicationWithBundleIdentifier:inBundleIdentifier];
		
		if (tURL==nil)
			return;
		
		NSBundle * tBundle=[NSBundle bundleWithURL:tURL];
		
		NSString * tDisplayName=[tBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
		
		if (tDisplayName==nil)
			tDisplayName=[tBundle objectForInfoDictionaryKey:@"CFBundleName"];
			
		if (tDisplayName==nil)
			return;
		
		[_lock lock];
		
		_cachedResolutions[inBundleIdentifier]=tDisplayName;
		
		[_lock unlock];
		
		if (handler!=NULL)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				handler(tDisplayName);
			});
		}
	});
	
	return nil;
}

@end

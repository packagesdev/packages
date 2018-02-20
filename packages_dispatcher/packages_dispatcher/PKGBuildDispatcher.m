/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGBuildDispatcher.h"

#import "PKGBuildDispatcher+Constants.h"

#import "PKGBuildDispatcherInterface.h"

#include <stdio.h>

NSString * const PKGPackagesBuilderToolPath=@"/Library/PrivilegedHelperTools/fr.whitebox.packages/packages_builder";

@interface PKGBuildDispatcher () <PKGBuildDispatcherInterface,NSXPCListenerDelegate>
{
	NSXPCListener * _listener;
	
	NSMutableDictionary * _endPointsRegistry;
}

@end

@implementation PKGBuildDispatcher

- (id)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_endPointsRegistry=[NSMutableDictionary dictionary];
		
		_listener=[[NSXPCListener alloc] initWithMachServiceName:PKGBuildDispatcherMachServiceName];
		_listener.delegate=self;
	}
	
	return self;
}

#pragma mark -

- (void)run
{
	[_listener resume];
}

#pragma mark - NSXPCListenerDelegate

- (BOOL)listener:(NSXPCListener *)inListener shouldAcceptNewConnection:(NSXPCConnection *)inNewConnection
{
	if(inNewConnection==nil)
		return NO;
	
	if (inListener!=_listener)
		return NO;
	
	inNewConnection.exportedInterface=[NSXPCInterface interfaceWithProtocol:@protocol(PKGBuildDispatcherInterface)];
	inNewConnection.exportedObject=self;
	
	[inNewConnection resume];
	
	return YES;
}

#pragma mark - PKGBuildDispatcher

- (void)lookForHandshakeEndpointForBuilderWithIdentifier:(NSString *)inUUID replyHandler:(void(^)(NSXPCListenerEndpoint *bHandshakeEndpoint))inReply;
{
	if (inUUID==nil)
		inReply(nil);
	
	dispatch_async(dispatch_get_main_queue(),^{
		
		NSXPCListenerEndpoint * tEndpoint=_endPointsRegistry[inUUID];
		
		if (tEndpoint==nil)
			fprintf(stderr, "Could not find record for build worker \"%s\"\n",[inUUID UTF8String]);
	
		inReply(tEndpoint);
	
		[_endPointsRegistry removeObjectForKey:inUUID];
	});
}

- (void)launchBuilderWithIdentifier:(NSString *)inUUID handshakeEndpoint:(NSXPCListenerEndpoint *)inHandshakeEndpoint
{
	if (inHandshakeEndpoint==nil || inUUID==nil)
		return;
	
	dispatch_async(dispatch_get_main_queue(),^{
	
		// Check the command line tool is still there
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:PKGPackagesBuilderToolPath]==NO)
		{
			fprintf(stderr, "Command line tool not found at path \"%s\"\n",[PKGPackagesBuilderToolPath UTF8String]);
			
			// Post Distributed Notification with inUUID
			
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:PKGPackagesDispatcherErrorDidOccurNotification
																		   object:inUUID
																		 userInfo:@{PKGPackagesDispatcherErrorTypeKey:@(PKGPackagesDispatcherErrorPackageBuilderNotFound)}
																		  options:NSNotificationDeliverImmediately|NSNotificationPostToAllSessions];
			
			return;
		}
		
		_endPointsRegistry[inUUID]=inHandshakeEndpoint;
		
		// Launch the command line tool
	
		NSTask * tBuildTask=[NSTask new];
		
		tBuildTask.launchPath=PKGPackagesBuilderToolPath;
		tBuildTask.arguments=@[@"-i",inUUID];
		tBuildTask.terminationHandler=^(NSTask *bTask) {
			
			dispatch_async(dispatch_get_main_queue(),^{
			
				if (bTask.terminationStatus!=0)
					fprintf(stderr, "Build \"%s\" failed\n",[inUUID UTF8String]);
				
				[_endPointsRegistry removeObjectForKey:inUUID];
			});
			
		};
		
		[tBuildTask launch];
	});
}

@end

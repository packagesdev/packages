/*
 Copyright (c) 2016-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGBuildOrderManager.h"

#import "PKGBuildDispatcherInterface.h"
#import "PKGBuildDispatcher+Constants.h"

#import "PKGBuildOrderExecutionAgent.h"

@interface PKGBuildOrderManager () <NSXPCListenerDelegate>
{
	NSXPCConnection * _dispatcherConnection;
	
	NSMutableDictionary * _executionAgentsRegistry;
}

- (void)connectToDispatcher;

@end

@implementation PKGBuildOrderManager

+(PKGBuildOrderManager *)defaultManager
{
	static PKGBuildOrderManager * sDefaultBuildOrderManager=nil;
	
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sDefaultBuildOrderManager=[[PKGBuildOrderManager alloc] init];
	});
	
	return sDefaultBuildOrderManager;
}

- (id)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_executionAgentsRegistry=[NSMutableDictionary dictionary];
	}
	
	return self;
}

#pragma mark -

- (void)connectToDispatcher
{
	if (_dispatcherConnection==nil)
	{
		_dispatcherConnection=[[NSXPCConnection alloc] initWithMachServiceName:PKGBuildDispatcherMachServiceName options:NSXPCConnectionPrivileged];
		_dispatcherConnection.remoteObjectInterface=[NSXPCInterface interfaceWithProtocol:@protocol(PKGBuildDispatcherInterface)];
		
		__weak NSXPCConnection *tWeakDispatcherConnection=_dispatcherConnection;
		
		tWeakDispatcherConnection.interruptionHandler=^{
			
			NSLog(@"Connection with dispatcher was interrupted");
			
			NSXPCConnection *tStrongConnection=tWeakDispatcherConnection;
			
			if (tStrongConnection!=nil)
				tStrongConnection.invalidationHandler = nil;
			
			_dispatcherConnection=nil;
		};
		
		tWeakDispatcherConnection.invalidationHandler=^{
			
			NSLog(@"Connection with dispatcher was invalidated");
			
			NSXPCConnection *tStrongConnection=tWeakDispatcherConnection;
			
			if (tStrongConnection!=nil)
				tStrongConnection.invalidationHandler = nil;
			
			_dispatcherConnection=nil;
		};
		
		[_dispatcherConnection resume];
	}
}

#pragma mark -

- (BOOL)executeBuildOrder:(PKGBuildOrder *)inBuildOrder setupHandler:(void(^)(PKGBuildNotificationCenter * bBuildNotificationCenter))inSetupHandler completionHandler:(void(^)(PKGBuildResult bBuildResult))inCompletionHandler communicationErrorHandler:(void(^)(NSError *))inCommunicationErrorHandler
{
	if (inBuildOrder==nil)
		return NO;
	
	[self connectToDispatcher];
	
	id<PKGBuildDispatcherInterface> tDispatcherProxy=[_dispatcherConnection remoteObjectProxyWithErrorHandler:^(NSError * bError) {
		
		if (inCommunicationErrorHandler!=nil)
			inCommunicationErrorHandler(bError);
	}];
	
	if (tDispatcherProxy==nil)
		return NO;
	
	PKGBuildOrderExecutionAgent * tBuildOrderExecutionAgent=[[PKGBuildOrderExecutionAgent alloc] initWithBuildOrder:inBuildOrder];
	
	tBuildOrderExecutionAgent.completionHandler=^(PKGBuildResult bResult){
		
		dispatch_async(dispatch_get_main_queue(), ^{
		
		[_executionAgentsRegistry removeObjectForKey:inBuildOrder.UUID];
		
		if (inCompletionHandler!=nil)
			inCompletionHandler(bResult);
		});
	};
	
	if (inSetupHandler!=nil)
		inSetupHandler(tBuildOrderExecutionAgent.buildNotificationCenter);
	
	
	// Add execution agent to registry
	
	_executionAgentsRegistry[inBuildOrder.UUID]=tBuildOrderExecutionAgent;
	
	[tDispatcherProxy launchBuilderWithIdentifier:inBuildOrder.UUID handshakeEndpoint:tBuildOrderExecutionAgent.handshakeEndpoint];
	
	return YES;
}

- (BOOL)abortBuildOrder:(PKGBuildOrder *)inBuildOrder
{
	if (inBuildOrder==nil)
		return NO;
	
	// Find execution agent for build order
	
	PKGBuildOrderExecutionAgent * tBuildOrderExecutionAgent=_executionAgentsRegistry[inBuildOrder.UUID];
	
	if (tBuildOrderExecutionAgent==nil)
		return NO;
	
	[tBuildOrderExecutionAgent abortExecution];
	
	return YES;
}

@end

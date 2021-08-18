/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPackagesBuilder.h"

#import "PKGBuildDispatcher+Constants.h"
#import "PKGBuildDispatcherInterface.h"

#import "PKGBuildHandshakeInterface.h"
#import "PKGBuildOrderExecutionAgentInterface.h"

#import "PKGProjectBuilder.h"
#import "PKGProjectBuilderInterface.h"

#import "NSXPCConnection+RequirementCheck.h"

@interface PKGPackagesBuilder () <NSXPCListenerDelegate>
{
	NSXPCListener * _listener;
	
	PKGProjectBuilder * _projectBuilder;
	
	NSXPCConnection * _handshakeConnection;
}

@end

@implementation PKGPackagesBuilder

- (instancetype)initWithUUID:(NSString *)inUUID
{
	if (inUUID==nil)
		return nil;
	
	if ([inUUID isKindOfClass:[NSString class]]==NO)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_UUID=[inUUID copy];
	}
	
	return self;
}

#pragma mark -

- (void)run
{
	// Connect to the Dispatcher
	
	NSXPCConnection * tBuildDispatcherConnection=[[NSXPCConnection alloc] initWithMachServiceName:PKGBuildDispatcherMachServiceName options:NSXPCConnectionPrivileged];
	tBuildDispatcherConnection.remoteObjectInterface=[NSXPCInterface interfaceWithProtocol:@protocol(PKGBuildDispatcherInterface)];
	
	__weak NSXPCConnection *tWeakConnection=tBuildDispatcherConnection;
	
	tBuildDispatcherConnection.invalidationHandler=^{
		
		NSXPCConnection *tStrongConnection=tWeakConnection;
		
		if (tStrongConnection!=nil)
			tStrongConnection.invalidationHandler = nil;
		
	};
	
	tBuildDispatcherConnection.interruptionHandler=nil;
	
	
	[tBuildDispatcherConnection resume];
	
	// Retrieve the endpoints provided by the promoter of the build
	
	[[tBuildDispatcherConnection remoteObjectProxyWithErrorHandler:^(NSError * bProxyError) {
		
		[tBuildDispatcherConnection invalidate];
		
		NSLog(@"Error");
		
	}] lookForHandshakeEndpointForBuilderWithIdentifier:self.UUID replyHandler:^(NSXPCListenerEndpoint *bHandshakeEndpoint){
	

		dispatch_async(dispatch_get_main_queue(), ^{
			
			[tBuildDispatcherConnection invalidate];
			
			if (bHandshakeEndpoint==nil)
			{
				NSLog(@"Error");
				
				// A COMPLETER
				
				return;
			}
				
			// Connect to the handshake endpoint of the promoter
			
			_handshakeConnection=[[NSXPCConnection alloc] initWithListenerEndpoint:bHandshakeEndpoint];
			_handshakeConnection.remoteObjectInterface=[NSXPCInterface interfaceWithProtocol:@protocol(PKGBuildHandshakeInterface)];
			
			__weak NSXPCConnection *tWeakHandshakeConnection=_handshakeConnection;
			
			_handshakeConnection.invalidationHandler=^{
				
				NSXPCConnection *tStrongConnection=tWeakHandshakeConnection;
				
				if (tStrongConnection!=nil)
					tStrongConnection.invalidationHandler = nil;
				
				_handshakeConnection=nil;
			};
			
			[_handshakeConnection resume];
			
			// Tell the promoter he can start sending build actions
			
			_listener=[NSXPCListener anonymousListener];
			_listener.delegate=self;
			
			[_listener resume];
				
			// Provide the endpoint to which the promoter should connect to to send build actions
			
			[[_handshakeConnection remoteObjectProxyWithErrorHandler:^(NSError * bProxyError) {
				
				dispatch_async(dispatch_get_main_queue(), ^{
					NSLog(@"Error");
				});
				
			}] builder:self.UUID didCreateEndPoint:_listener.endpoint];
		});
	}];
}

#pragma mark - NSXPCListenerDelegate

- (BOOL)listener:(NSXPCListener *)inListener shouldAcceptNewConnection:(NSXPCConnection *)inNewConnection
{
	if (inListener!=_listener)
		return NO;
	
	if (inNewConnection==nil)
		return NO;
	
    NSString * tRequirementString=@"anchor apple generic and certificate leaf [subject.OU] = \"NL5M9E394P\"";
    
    if ([inNewConnection checkValidityWithRequirement:tRequirementString]==NO)
    {
        NSLog(@"Denied connection attempt from pid \"%d\"\n",inNewConnection.processIdentifier);
        
        return NO;
    }
    
	_projectBuilder=[[PKGProjectBuilder alloc] init];
	_projectBuilder.userID=inNewConnection.effectiveUserIdentifier;
	_projectBuilder.groupID=inNewConnection.effectiveGroupIdentifier;
	_projectBuilder.executionAgentConnection=inNewConnection;
	
	inNewConnection.exportedInterface=[NSXPCInterface interfaceWithProtocol:@protocol(PKGProjectBuilderInterface)];
	inNewConnection.exportedObject=_projectBuilder;
	inNewConnection.remoteObjectInterface=[NSXPCInterface interfaceWithProtocol:@protocol(PKGBuildOrderExecutionAgentInterface)];
	
	[inNewConnection resume];
	
	return YES;
}

@end

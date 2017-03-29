/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGBuildOrderExecutionAgent.h"

#import "PKGBuildHandshakeInterface.h"
#import "PKGProjectBuilderInterface.h"

#import "PKGBuildOrderExecutionAgentInterface.h"

#import "PKGBuildDataSigner.h"

typedef NS_ENUM(NSUInteger, PKGAgentExecutionState)
{
	PKGAgentExecutionStateWaitingForHandshake,
	PKGAgentExecutionStateBuildLaunched,
	PKGAgentExecutionStateBuildAborted
};

@interface PKGBuildOrderExecutionAgent () <NSXPCListenerDelegate,PKGBuildHandshakeInterface,PKGBuildOrderExecutionAgentInterface>
{
	NSXPCConnection * _builderConnection;
	
	PKGAgentExecutionState _executionState;
}

	@property (readwrite) PKGBuildOrder * buildOrder;

	@property (readwrite) PKGBuildNotificationCenter * buildNotificationCenter;

	@property (readwrite) NSXPCListener * handshakelistener;

@end

@implementation PKGBuildOrderExecutionAgent

- (instancetype)initWithBuildOrder:(PKGBuildOrder *)inBuildOrder
{
	if (inBuildOrder==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_buildOrder=[inBuildOrder copy];
		
		_buildNotificationCenter=[PKGBuildNotificationCenter new];
		
		_handshakelistener=[NSXPCListener anonymousListener];
		_handshakelistener.delegate=self;
		
		_executionState=PKGAgentExecutionStateWaitingForHandshake;
		
		[_handshakelistener resume];
	}
	
	return self;
}

#pragma mark -

- (NSXPCListenerEndpoint *)handshakeEndpoint
{
	return _handshakelistener.endpoint;
}

- (void)setCompletionHandler:(PKGBuildCompletionHandler)inCompletionHandler
{
	if (inCompletionHandler!=self.completionHandler)
		_completionHandler=[inCompletionHandler copy];
	
	_buildNotificationCenter.completionHandler=inCompletionHandler;
}

#pragma mark -

- (void)abortExecution
{
	if (_executionState!=PKGAgentExecutionStateBuildLaunched)
		return;
	
	// A COMPLETER
	
	[[_builderConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
		NSLog(@"Error");
	}] cancelBuild];
	
	_executionState=PKGAgentExecutionStateBuildAborted;
	
	if (self.completionHandler!=nil)
		self.completionHandler(PKGBuildResultAborted);
}

#pragma mark - NSXPCListenerDelegate

- (BOOL)listener:(NSXPCListener *)inListener shouldAcceptNewConnection:(NSXPCConnection *)inNewConnection
{
	if (inListener==self.handshakelistener)
	{
		inNewConnection.exportedInterface=[NSXPCInterface interfaceWithProtocol:@protocol(PKGBuildHandshakeInterface)];
		inNewConnection.exportedObject=self;
		
		[inNewConnection resume];
		
		return YES;
	}
	
	return NO;
}

#pragma mark - PKGBuildHandshakeInterface

- (void)builder:(NSString *)inUUID didCreateEndPoint:(NSXPCListenerEndpoint *)inEndpoint
{
	if ([inUUID isEqualToString:self.buildOrder.UUID]==NO)
	{
		[self.handshakelistener invalidate];
		
		return;
	}
	
	_builderConnection=[[NSXPCConnection alloc] initWithListenerEndpoint:inEndpoint];
	_builderConnection.remoteObjectInterface=[NSXPCInterface interfaceWithProtocol:@protocol(PKGProjectBuilderInterface)];
	_builderConnection.exportedInterface=[NSXPCInterface interfaceWithProtocol:@protocol(PKGBuildOrderExecutionAgentInterface)];
	_builderConnection.exportedObject=self;
	
	__weak NSXPCConnection *tWeakOperatorConnection=_builderConnection;
	
	tWeakOperatorConnection.invalidationHandler=^{
		
		NSXPCConnection *tStrongConnection=tWeakOperatorConnection;
		
		if (tStrongConnection!=nil)
			tStrongConnection.invalidationHandler = nil;
		
		_builderConnection=nil;
	};
	
	tWeakOperatorConnection.interruptionHandler=^{
	
		if (self.completionHandler!=nil)
			self.completionHandler(PKGBuildResultFailedXPCConnectionInterrupted);
		
		// A COMPLETER
	};
	
	[_builderConnection resume];
	
	[[_builderConnection remoteObjectProxyWithErrorHandler:^(NSError * proxyError) {
		NSLog(@"Error");
		
		// A COMPLETER
	}] buildProjectOfBuildOrderRepresentation:[self.buildOrder representation]];
	
	_executionState=PKGAgentExecutionStateBuildLaunched;
}

#pragma mark - PKGBuildNotificationCenterInterface

- (void)postNotificationStepPath:(NSString *)inStepPathRepresentation state:(PKGBuildStepState)inState userInfo:(NSDictionary *)inUserInfo
{
	dispatch_async(dispatch_get_main_queue(),^ {
		[self.buildNotificationCenter postNotificationStepPath:inStepPathRepresentation state:inState userInfo:inUserInfo];
	});
}

#pragma mark - PKGSignatureCreatorInterface

- (void)createSignatureForData:(NSData *)inInputData usingIdentity:(NSString *)inIdentityName keychain:(NSString *)inKeychainpath replyHandler:(void(^)(PKGSignatureStatus bStatus,NSData * bSignedData))inReply
{
	dispatch_async(dispatch_get_main_queue(),^ {
		[[PKGBuildDataSigner sharedSigner] createSignatureForData:inInputData usingIdentity:inIdentityName keychain:inKeychainpath replyHandler:^(PKGSignatureStatus status,NSData *signedData){
		
			inReply(status,signedData);
		
		}];
	});
}

@end

/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGBuildNotificationCenter.h"

#import "NSIndexPath+Packages.h"

NSString * const PKGBuildEventNotification=@"PKGBuildEventNotification";
NSString * const PKGBuildDebugNotification=@"PKGBuildDebugNotification";


NSString * const PKGBuildStepKey=@"PKGBuildStep";
NSString * const PKGBuildStepPathKey=@"PKGBuildStepPath";
NSString * const PKGBuildStateKey=@"PKGBuildState";
NSString * const PKGBuildStepEventRepresentationKey=@"PKGBuildStepEventRepresentationKey";

@interface PKGBuildNotificationCenter () 

@end

@implementation PKGBuildNotificationCenter

#pragma mark - PKGBuildNotificationCenterInterface

- (void)postNotificationStepPath:(NSString *)inStepPathRepresentation state:(PKGBuildStepState)inState userInfo:(NSDictionary *)inUserInfo
{
	if (inStepPathRepresentation==nil)
	{
		NSLog(@"Missing Step Path Representation.");
		return;
	}
	
	NSMutableDictionary * tUserInfo=[NSMutableDictionary dictionary];
	
	NSIndexPath * tIndexPath=[[NSIndexPath alloc] PKG_initWithStringRepresentation:inStepPathRepresentation];
	
	tUserInfo[PKGBuildStepKey]=@([tIndexPath PKG_lastIndex]);
	tUserInfo[PKGBuildStepPathKey]=tIndexPath;
	tUserInfo[PKGBuildStateKey]=@(inState);
	
	if (inUserInfo!=nil)
		tUserInfo[PKGBuildStepEventRepresentationKey]=inUserInfo;
	
	dispatch_async(dispatch_get_main_queue(), ^{
	
		NSNotification * tNotification=[[NSNotification alloc] initWithName:PKGBuildEventNotification
																	 object:nil
																   userInfo:tUserInfo];
	
		[self postNotification:tNotification];
	});
}

@end

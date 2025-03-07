/*
 Copyright (c) 2017-2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGRequirementPanel.h"

#import "PKGRequirementWindowController.h"

#import "PKGDocumentWindowController.h"

@interface PKGRequirementPanel ()

	@property PKGRequirementWindowController * retainedWindowController;

	@property (nonatomic,readwrite) PKGDistributionProject * project;

- (void)_sheetDidEndSelector:(NSWindow *)inWindow returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo;

@end

@implementation PKGRequirementPanel

- (NSString *)prompt
{
	return self.retainedWindowController.prompt;
}

- (void)setPrompt:(NSString *)inPrompt
{
	self.retainedWindowController.prompt=inPrompt;
}

- (PKGRequirement *)requirement
{
	return self.retainedWindowController.requirement;
}

- (void)setRequirement:(PKGRequirement *)inRequirement
{
	self.retainedWindowController.requirement=inRequirement;
}

#pragma mark -

- (void)beginSheetModalForWindow:(NSWindow *)inWindow completionHandler:(void (^)(NSModalResponse response))handler
{
    self.document=((NSWindowController *) inWindow.windowController).document;
	self.project=(PKGDistributionProject *)((PKGDocumentWindowController *) inWindow.windowController).project;
	
	[self.retainedWindowController refreshUI];
	
	[inWindow beginSheet:self completionHandler:^(NSModalResponse bReturnCode) {
		
		if (handler!=nil)
			handler(bReturnCode);
		
		self.retainedWindowController=nil;
	}];
}

- (void)_sheetDidEndSelector:(PKGRequirementPanel *)inPanel returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo
{
	void(^handler)(NSInteger) = (__bridge_transfer void(^)(NSInteger)) contextInfo;
	
	if (handler!=nil)
		handler(inReturnCode);
	
	inPanel.retainedWindowController=nil;
	
	[inPanel orderOut:self];
}

@end

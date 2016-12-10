/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDocument.h"



#import "PKGPackageProjectMainViewController.h"
#import "PKGDistributionProjectMainViewController.h"

#define PKGDocumentWindowPackageProjectMinWidth				1026.0
#define PKGDocumentWindowPDistributionProjectMinWidth		1200.0
#define PKGDocumentWindowMinHeight							613.0


@interface PKGDocument ()
{
	PKGProjectMainViewController * _projectMainViewController;
}

	@property (readwrite) PKGProject * project;

- (IBAction)build:(id)sender;

@end

@implementation PKGDocument

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"PKGDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
	
	switch(self.project.type)
	{
		case PKGProjectTypeDistribution:
			
			_projectMainViewController=[PKGDistributionProjectMainViewController new];
			
			break;
			
		case PKGProjectTypePackage:
			
			_projectMainViewController=[PKGPackageProjectMainViewController new];
			
			break;
	}
	
	_projectMainViewController.project=self.project;
	
	NSWindow * tDocumentMainWindow=self.windowForSheet;
	
	NSView * tMainView=_projectMainViewController.view;
	
	NSRect tFrame=((NSView *)tDocumentMainWindow.contentView).bounds;
	
	[tMainView setFrame:tFrame];
	
	[_projectMainViewController WB_viewWillAdd];
	
	[tDocumentMainWindow.contentView addSubview:tMainView];
	
	[_projectMainViewController WB_viewDidAdd];
	
	[tDocumentMainWindow setMinSize:NSMakeSize(PKGDocumentWindowPackageProjectMinWidth, PKGDocumentWindowMinHeight)];
}

#pragma mark -

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	id tPropertyList=[self.project representation];
	
	if (tPropertyList==nil)
	{
	}
	
	NSError * tError;
	
	NSData * tData=[NSPropertyListSerialization dataWithPropertyList:tPropertyList format:NSPropertyListXMLFormat_v1_0 options:0 error:&tError];
	
	if (tData==nil)
	{
	}
	
	return tData;
	
	/*// Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
    return nil;*/
}

- (BOOL)readFromData:(NSData *)inData ofType:(NSString *)typeName error:(NSError **)outError
{
	NSError * tError;
	
	id tPropertyList=[NSPropertyListSerialization propertyListWithData:inData options:NSPropertyListImmutable format:NULL error:&tError];
	
	if (tPropertyList==nil)
	{
		
		return NO;
	}
	
	self.project=[PKGProject projectFromPropertyList:tPropertyList error:&tError];
	
	if (self.project==nil)
	{
		
		return NO;
	}
	
	return YES;
	
	/*// Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
    return NO;*/
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

#pragma mark -

- (IBAction)build:(id)sender
{
}

@end

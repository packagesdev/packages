/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGCommentsViewController.h"

@interface PKGCommentsViewController () <NSTextDelegate>
{
	IBOutlet NSTextView * _textView;
}

@end

@implementation PKGCommentsViewController

#pragma mark -

- (void)WB_viewWillAdd
{
	NSData * tData=self.comments.htmlData;
	
	if (tData.length==0)
	{
		[_textView setString:@""];
		return;
	}
	
	NSTextStorage * tTextStorage=_textView.textStorage;
	
	[tTextStorage beginEditing];
	
	NSDictionary * tAttributesDictionary;
	[tTextStorage readFromData:tData
					   options:@{NSDocumentTypeDocumentOption:NSHTMLTextDocumentType}
			documentAttributes:&tAttributesDictionary
						 error:NULL];
	
	[tTextStorage endEditing];
}

- (void)WB_viewDidAdd
{
	[self.view.window makeFirstResponder:_textView];
}

#pragma mark - NSTextDelegate

- (void)textDidChange:(NSNotification *)inNotification
{
	if (inNotification.object!=_textView)
		return;
	
	NSTextStorage * tTextStorage=[_textView textStorage];
	
	NSError * tError;
	NSData * tData=[tTextStorage dataFromRange:NSMakeRange(0,[tTextStorage length])
							documentAttributes:@{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType}
										 error:&tError];
	
	if (tData==nil)
	{
		
		return;
	}
	
	self.comments.htmlData=tData;
	
	// Note change
	
	[self noteDocumentHasChanged];
}

@end

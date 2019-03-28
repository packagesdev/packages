/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGFilesSelectionInspectorAttributesViewController.h"

#import "PKGFileNameFormatter.h"

#import "PKGPayloadTreeNode+UI.h"
#import "PKGFileItem+UI.h"

@interface PKGFilesSelectionInspectorAttributesViewController ()
{
	IBOutlet NSTextField * _fileNameTextField;
}

- (IBAction)rename:(id)sender;

@end

@implementation PKGFilesSelectionInspectorAttributesViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	PKGFileNameFormatter * tFileNameFormatter=[PKGFileNameFormatter new];
	tFileNameFormatter.fileNameCanStartWithDot=YES;
	
	_fileNameTextField.formatter=tFileNameFormatter;
}

- (void)refreshSingleSelection
{
	PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
	PKGFileItem * tFileItem=[tTreeNode representedObject];
	
	// File Name
	
	_fileNameTextField.textColor=[NSColor controlTextColor];
	
	if (tFileItem.type==PKGFileItemTypeNewFolder || tFileItem.payloadFileName!=nil)
	{
		if (_fileNameTextField.isBezeled==NO)
		{
			NSRect tFrame=_fileNameTextField.frame;
			
			tFrame.origin.y+=3.0;
			
			_fileNameTextField.frame=tFrame;
		}
		
		_fileNameTextField.editable=YES;
		_fileNameTextField.bezeled=YES;
		_fileNameTextField.drawsBackground=YES;
	}
	else
	{
		if (_fileNameTextField.isBezeled==YES)
		{
			NSRect tFrame=_fileNameTextField.frame;
			
			tFrame.origin.y-=3.0;
			
			_fileNameTextField.frame=tFrame;
		}
		
		_fileNameTextField.editable=NO;
		_fileNameTextField.selectable=YES;
		_fileNameTextField.bezeled=NO;
		_fileNameTextField.drawsBackground=NO;
	}
	
	_fileNameTextField.stringValue=tFileItem.fileName;
}

- (void)refreshMultipleSelection
{
	// File Name
	
	if (_fileNameTextField.isBezeled==YES)
	{
		NSRect tFrame=_fileNameTextField.frame;
		
		tFrame.origin.y-=3.0;
		
		_fileNameTextField.frame=tFrame;
	}
	
	_fileNameTextField.editable=NO;
	_fileNameTextField.selectable=YES;
	_fileNameTextField.bezeled=NO;
	_fileNameTextField.drawsBackground=NO;
	
	_fileNameTextField.stringValue=NSLocalizedString(@"Multiple Selection", @"");
	_fileNameTextField.textColor=[NSColor disabledControlTextColor];
}

#pragma mark -

- (IBAction)rename:(id)sender
{
	NSString * tNewName=_fileNameTextField.stringValue;
	PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
	
	if ([tNewName isEqualToString:tTreeNode.fileName]==NO)
	{
		if (self.delegate!=nil && [self.delegate viewController:self shouldRenameItem:tTreeNode to:tNewName]==NO)
		{
			_fileNameTextField.stringValue=tTreeNode.fileName;
			return;
		}
		
		[tTreeNode rename:tNewName];
		
		_fileNameTextField.stringValue=tNewName;
		
		[self.delegate viewController:self didRenameItem:tTreeNode to:tNewName];
	}
}

@end

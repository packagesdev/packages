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

#import "PKGPayloadTreeNode+UI.h"
#import "PKGFileItem+UI.h"

@interface PKGFilesSelectionInspectorAttributesViewController ()

@property (readwrite) PKGFileNameFormatter * fileNameFormatter;

- (IBAction)rename:(id)sender;

@end

@implementation PKGFilesSelectionInspectorAttributesViewController

- (instancetype)initWithDocument:(PKGDocument *)inDocument
{
    self=[super initWithDocument:inDocument];
    
    if (self!=nil)
    {
        _fileNameFormatter=[PKGFileNameFormatter new];
        _fileNameFormatter.fileNameCanStartWithDot=YES;
        _fileNameFormatter.keysReplacer=self;
    }
    
    return self;
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	self.fileNameTextField.formatter=self.fileNameFormatter;
}

- (void)refreshSingleSelection
{
    PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
	PKGFileItem * tFileItem=[tTreeNode representedObject];
	
	// File Name
	
    NSTextField * tTextField=self.fileNameTextField;
    
	tTextField.textColor=[NSColor controlTextColor];
	
	if (tFileItem.isNameEditable==YES)
	{
		if (tTextField.isBezeled==NO)
		{
			NSRect tFrame=tTextField.frame;
			
			tFrame.origin.y+=3.0;
			
			tTextField.frame=tFrame;
		}
		
		tTextField.editable=YES;
		tTextField.bezeled=YES;
		tTextField.drawsBackground=YES;
	}
	else
	{
		if (tTextField.isBezeled==YES)
		{
			NSRect tFrame=tTextField.frame;
			
			tFrame.origin.y-=3.0;
			
			tTextField.frame=tFrame;
		}
		
		tTextField.editable=NO;
		tTextField.selectable=YES;
		tTextField.bezeled=NO;
		tTextField.drawsBackground=NO;
	}
	
	tTextField.objectValue=tFileItem.fileName;
}

- (void)refreshMultipleSelection
{
	// File Name
	
	NSTextField * tTextField=self.fileNameTextField;
    
    if (tTextField.isBezeled==YES)
	{
		NSRect tFrame=tTextField.frame;
		
		tFrame.origin.y-=3.0;
		
		tTextField.frame=tFrame;
	}
	
	tTextField.editable=NO;
	tTextField.selectable=YES;
	tTextField.bezeled=NO;
	tTextField.drawsBackground=NO;
	
	tTextField.stringValue=NSLocalizedString(@"Multiple Selection", @"");
	tTextField.textColor=[NSColor disabledControlTextColor];
}

#pragma mark -

- (IBAction)rename:(NSTextField *)sender
{
    NSTextField * tTextField=self.fileNameTextField;
    
    NSString * tNewName=tTextField.objectValue;
	PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
	
	if ([tNewName isEqualToString:tTreeNode.fileName]==NO)
	{
		if (self.delegate!=nil && [self.delegate viewController:self shouldRenameItem:tTreeNode to:tNewName]==NO)
		{
			tTextField.objectValue=tTreeNode.fileName;
			return;
		}
		
		[tTreeNode rename:tNewName];
		
		tTextField.objectValue=tNewName;
		
		[self.delegate viewController:self didRenameItem:tTreeNode to:tNewName];
	}
}

#pragma mark - Notifications

- (void)userSettingsDidChange:(NSNotification *)inNotification
{
    [super userSettingsDidChange:inNotification];
    
    [self.fileNameTextField setNeedsDisplay:YES];
}

@end

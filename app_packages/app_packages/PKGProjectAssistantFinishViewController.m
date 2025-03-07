/*
 Copyright (c) 2008-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGProjectAssistantFinishViewController.h"

#import "PKGProjectTemplateAssistantDirectoryDeadDropView.h"

#import "PKGProjectTemplateAssistantSettingsKeys.h"

#import "PKGFileDeadDropTextField.h"

@interface PKGProjectAssistantFinishViewController () <NSControlTextEditingDelegate,PKGFileDeadDropViewDelegate,PKGFileDeadDropTextFieldDelegate>
{
	IBOutlet NSTextField * _projectNametextField;
	
	IBOutlet PKGFileDeadDropTextField * _projectDirectoryTextField;
	
	IBOutlet NSTextField * _actionDescriptionLabel;
	
	NSString * _projectName;	// Used to know which project name was used previously for the automatic project directory name
	
	BOOL _projectDirectoryWasChangedByUser;
}

- (void)_updateAfterModificationOfTextField:(NSTextField *)inTextField;

- (IBAction)selectDirectory:(id) sender;

@end

@implementation PKGProjectAssistantFinishViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
    _projectDirectoryTextField.deadDropDelegate=self;
	
	((PKGProjectTemplateAssistantDirectoryDeadDropView *)self.view).delegate=self;
}

#pragma mark -

- (PKGAssistantStepViewController *)nextStepViewController
{
	return nil;
}

- (BOOL)shouldShowNextStepViewController
{
	NSFileManager * tFileManager=[NSFileManager defaultManager];
	BOOL isDirectory;
	
	NSString * tProjectDirectory=[_projectDirectoryTextField.stringValue stringByExpandingTildeInPath];
	
	if ([tFileManager fileExistsAtPath:tProjectDirectory isDirectory:&isDirectory]==NO)
	{
		NSString * tParentProjectDirectory=[tProjectDirectory stringByDeletingLastPathComponent];
		
		if ([tFileManager fileExistsAtPath:tParentProjectDirectory isDirectory:&isDirectory]==NO)
		{
			NSBeep();
			
            NSAlert * tAlert=[NSAlert new];
            
            tAlert.messageText=NSLocalizedStringFromTable(@"The parent directory of the project directory you specified does not exist.",@"ProjectTemplateAssistant",@"No comment");
            tAlert.informativeText=NSLocalizedStringFromTable(@"Please select another location for the project.",@"ProjectTemplateAssistant",@"No comment");
			
			[tAlert beginSheetModalForWindow:self.view.window completionHandler:nil];
			
			return NO;
		}
		
		if (isDirectory==NO)
		{
			NSBeep();
			
            NSAlert * tAlert=[NSAlert new];
            
            tAlert.messageText=NSLocalizedString(@"The parent directory of the project directory you specified is not a directory.",@"No comment");
            tAlert.informativeText=NSLocalizedStringFromTable(@"Please select another location for the project.",@"ProjectTemplateAssistant",@"No comment");
			
			[tAlert beginSheetModalForWindow:self.view.window completionHandler:nil];
			
			return NO;
		}
	}
	else
	{
		if (isDirectory==NO)
		{
			NSBeep();
			
            NSAlert * tAlert=[NSAlert new];
            
            tAlert.messageText=NSLocalizedStringFromTable(@"A file with the same name as the project directory you specified already exists.",@"ProjectTemplateAssistant",@"No comment");
            tAlert.informativeText=NSLocalizedStringFromTable(@"Please select another location for the project.",@"ProjectTemplateAssistant",@"No comment");
			
			[tAlert beginSheetModalForWindow:self.view.window completionHandler:nil];
			
			return NO;
		}
	}
	
	// Check the name of the file
	
	NSString * tProjectName=_projectNametextField.stringValue;
	
	if ([tProjectName hasSuffix:@".pkgproj"]==YES)
		tProjectName=[tProjectName stringByDeletingPathExtension];
	
	// Check that there's not already a file with that name
	
	NSString * tNewPath=[[tProjectDirectory stringByAppendingPathComponent:tProjectName] stringByAppendingPathExtension:@"pkgproj"];
	
	if ([tFileManager fileExistsAtPath:tNewPath]==YES)
	{
		NSBeep();
		
		NSAlert * tAlert=[NSAlert new];
		
		tAlert.messageText=NSLocalizedStringFromTable(@"A file with this name already exists at this location.",@"ProjectTemplateAssistant",@"No comment");
		tAlert.informativeText=NSLocalizedStringFromTable(@"Please select another location for the project.",@"ProjectTemplateAssistant",@"No comment");
		
		[tAlert beginSheetModalForWindow:self.view.window completionHandler:nil];
		
		return NO;
	}
	
	[self.assistantController.assistantSettings setObject:tProjectName forKey:PKGProjectTemplateAssistantSettingsProjectNameKey];
	
	[self.assistantController.assistantSettings setObject:_projectDirectoryTextField.stringValue forKey:PKGProjectTemplateAssistantSettingsProjectDirectoryKey];
	
	return YES;
}

#pragma mark -

- (void)WB_viewWillAppear
{
	_projectName=[[self.assistantController.assistantSettings objectForKey:PKGProjectTemplateAssistantSettingsProjectNameKey] copy];
	
	if (_projectName.length==0)
	{
		self.assistantController.nextButton.enabled=NO;
		
		_actionDescriptionLabel.stringValue=@"";
	}
	else
	{
		self.assistantController.nextButton.enabled=YES;
	}
	
	_projectNametextField.stringValue=_projectName;
	
	NSString * tProjectDirectory=[[self.assistantController.assistantSettings objectForKey:PKGProjectTemplateAssistantSettingsProjectDirectoryKey] copy];
	
	_projectDirectoryTextField.stringValue= (tProjectDirectory.length==0) ? @"" : tProjectDirectory;
	
	self.assistantController.nextButton.title=NSLocalizedStringFromTable(@"Create",@"ProjectTemplateAssistant",@"");
}

- (void)WB_viewDidAppear
{
	[self.view.window makeFirstResponder:_projectNametextField];
}

#pragma mark -

- (void)_updateAfterModificationOfTextField:(NSTextField *)inTextField
{
	NSString * tProjectName=_projectNametextField.stringValue;
	NSString * tProjectDirectory=_projectDirectoryTextField.stringValue;
	
	// Update the tip label
	
	if (inTextField==_projectNametextField)
	{
		if (_projectDirectoryWasChangedByUser==NO)
		{
			if (_projectName.length>0 && [tProjectDirectory.lastPathComponent isEqualToString:_projectName])
				tProjectDirectory=[tProjectDirectory stringByDeletingLastPathComponent];
			
			tProjectDirectory=[tProjectDirectory stringByAppendingPathComponent:tProjectName];
			
			if ([tProjectDirectory hasSuffix:@"/"]==NO)
				tProjectDirectory=[tProjectDirectory stringByAppendingString:@"/"];
			
			_projectDirectoryTextField.stringValue=tProjectDirectory;
			
			_projectName=[tProjectName copy];
		}
	}
	else if (inTextField==_projectDirectoryTextField)
	{
		_projectDirectoryWasChangedByUser=YES;
	}
	
	// Update the tip label
	
	if (tProjectName.length==0 ||
		tProjectDirectory.length==0)
	{
		_actionDescriptionLabel.stringValue=@"";
	}
	else
	{
		NSString * tTipMessage=[NSString stringWithFormat:NSLocalizedStringFromTable(@"The project directory %@ will be created if necessary, and the project file %@.pkgproj will be created therein.",@"ProjectTemplateAssistant",@""),tProjectDirectory,tProjectName];
		
		_actionDescriptionLabel.stringValue=tTipMessage;
	}
}

#pragma mark -

- (IBAction)selectDirectory:(id) sender
{
	NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
	
	tOpenPanel.canChooseFiles=NO;
	tOpenPanel.canChooseDirectories=YES;
	tOpenPanel.canCreateDirectories=YES;
	tOpenPanel.prompt=NSLocalizedString(@"Choose",@"No comment");
	
	NSString * tPath=[_projectDirectoryTextField.stringValue stringByExpandingTildeInPath];
	
	if(tPath!=nil)
		tOpenPanel.directoryURL=[NSURL fileURLWithPath:tPath];
	
	[tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
		
		if (bResult!=WBFileHandlingPanelOKButton)
			return;
		
		NSString * tDirectoryPath=[tOpenPanel.URL.path stringByAbbreviatingWithTildeInPath];
		
		if (self->_projectDirectoryWasChangedByUser==NO)
			tDirectoryPath=[tDirectoryPath stringByAppendingPathComponent:self->_projectNametextField.stringValue];
		
		if ([tDirectoryPath hasSuffix:@"/"]==NO)
			tDirectoryPath=[tDirectoryPath stringByAppendingString:@"/"];
		
		BOOL tOldValue=self->_projectDirectoryWasChangedByUser;
		
		self->_projectDirectoryTextField.stringValue=tDirectoryPath;
		
		self->_projectDirectoryWasChangedByUser=tOldValue;
		
		[self _updateAfterModificationOfTextField:self->_projectDirectoryTextField];
	}];
}

#pragma mark -

- (void) controlTextDidEndEditing:(NSNotification *) inNotification
{
	if ([inNotification object]==_projectDirectoryTextField)
	{
		NSString * tProjectDirectory=_projectDirectoryTextField.stringValue;
		
		if ([tProjectDirectory hasSuffix:@"/"]==NO)
		{
			tProjectDirectory=[tProjectDirectory stringByAppendingString:@"/"];
			
			_projectDirectoryTextField.stringValue=tProjectDirectory;
		}
	}
}

- (void) controlTextDidChange:(NSNotification *) inNotification
{
	// Update the tip label
	
	if ([inNotification object]==_projectNametextField ||
		[inNotification object]==_projectDirectoryTextField)
	{
		self.assistantController.nextButton.enabled=([[[[inNotification userInfo] objectForKey:@"NSFieldEditor"] string] length]>0);
		
		// A COMPLETER (meilleure gestion de la chaine vide dans l'un des champs)
	}
	
	[self _updateAfterModificationOfTextField:[inNotification object]];
}

- (void)control:(NSControl *)inControl didFailToValidatePartialString:(NSString *)string errorDescription:(NSString *)inError
{
	if (inControl==_projectNametextField)
		NSBeep();
}

#pragma mark - PKGFileDeadDropViewDelegate

- (BOOL)fileDeadDropView:(PKGFileDeadDropView *)inView validateDropFiles:(NSArray *) inFilenames
{
	if ([inFilenames count]!=1)
		return NO;
	
	NSString * tPath=inFilenames[0];
	
	NSDictionary * tAttributes=[[NSFileManager defaultManager] attributesOfItemAtPath:tPath error:NULL];
	
	if (tAttributes==nil)
		return NO;
	
	return ([tAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]);
}

- (BOOL)fileDeadDropView:(PKGFileDeadDropView *)inView acceptDropFiles:(NSArray *) inFilenames
{
	if ([inFilenames count]!=1)
		return NO;
	
	NSString * tDirectoryPath=inFilenames[0];
	
	if (_projectDirectoryWasChangedByUser==NO)
		tDirectoryPath=[tDirectoryPath stringByAppendingPathComponent:[_projectNametextField stringValue]];
	
	if ([tDirectoryPath hasSuffix:@"/"]==NO)
		tDirectoryPath=[tDirectoryPath stringByAppendingString:@"/"];
	
	BOOL tOldValue=_projectDirectoryWasChangedByUser;
	
	_projectDirectoryTextField.stringValue=tDirectoryPath;
	
	_projectDirectoryWasChangedByUser=tOldValue;
	
	[self _updateAfterModificationOfTextField:_projectDirectoryTextField];
	
	return YES;
}

#pragma mark - PKGFileDeadDropTextFieldDelegate

- (BOOL)fileDeadDropTextField:(PKGFileDeadDropTextField *)inView validateDropFiles:(NSArray *) inFilenames
{
	if ([inFilenames count]!=1)
		return NO;
	
	NSString * tPath=inFilenames[0];
	
	NSDictionary * tAttributes=[[NSFileManager defaultManager] attributesOfItemAtPath:tPath error:NULL];
	
	if (tAttributes==nil)
		return NO;
	
	return ([tAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]);
}

- (BOOL)fileDeadDropTextField:(PKGFileDeadDropTextField *)inView acceptDropFiles:(NSArray *) inFilenames
{
	if ([inFilenames count]!=1)
		return NO;
	
	_projectDirectoryTextField.stringValue=inFilenames[0];
	
	return YES;
}

@end


#import "PKGProjectAssistantFinishViewController.h"

#import "PKGProjectTemplateAssistantDirectoryDeadDropView.h"

#import "PKGProjectTemplateAssistantSettingsKeys.h"

#import "PKGFileDeadDropTextField.h"

@interface PKGProjectAssistantFinishViewController () <NSControlTextEditingDelegate,PKGFileDeadDropViewDelegate,PKGFileDeadDropTextFieldDelegate>
{
	IBOutlet NSTextField * _projectNametextField;
	
	IBOutlet PKGFileDeadDropTextField * _projectDirectoryTextField;
	
	IBOutlet NSTextField * _actionDescriptionLabel;
	
	NSString * _projectName;
	
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
			
			NSAlert * tAlert=[NSAlert alertWithMessageText:NSLocalizedString(@"The parent directory of the project directory you specified does not exist.",@"No comment")
											 defaultButton:nil
										   alternateButton:nil
											   otherButton:nil
								 informativeTextWithFormat: NSLocalizedString(@"Please select another location for the project.",@"No comment")];
			
			[tAlert beginSheetModalForWindow:self.view.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
			
			return NO;
		}
		
		if (isDirectory==NO)
		{
			NSBeep();
			
			NSAlert * tAlert=[NSAlert alertWithMessageText:NSLocalizedString(@"The parent directory of the project directory you specified is not a directory.",@"No comment")
											 defaultButton:nil
										   alternateButton:nil
											   otherButton:nil
								 informativeTextWithFormat: NSLocalizedString(@"Please select another location for the project.",@"No comment")];
			
			[tAlert beginSheetModalForWindow:self.view.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
			
			return NO;
		}
	}
	else
	{
		if (isDirectory==NO)
		{
			NSBeep();
			
			NSAlert * tAlert=[NSAlert alertWithMessageText:NSLocalizedString(@"A file with the same name as the project directory you specified already exists.",@"No comment")
											 defaultButton:nil
										   alternateButton:nil
											   otherButton:nil
								 informativeTextWithFormat: NSLocalizedString(@"Please select another location for the project.",@"No comment")];
			
			[tAlert beginSheetModalForWindow:self.view.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
			
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
		
		NSAlert * tAlert=[NSAlert alertWithMessageText:NSLocalizedString(@"A file with this name already exists at this location.",@"No comment")
										 defaultButton:nil
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat: NSLocalizedString(@"Please select another location for the project.",@"No comment")];
		
		[tAlert beginSheetModalForWindow:self.view.window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
		
		return NO;
	}
	
	[self.assistantController.assistantSettings setObject:_projectName forKey:PKGProjectTemplateAssistantSettingsProjectNameKey];
	
	[self.assistantController.assistantSettings setObject:[_projectDirectoryTextField stringValue] forKey:PKGProjectTemplateAssistantSettingsProjectDirectoryKey];
	
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
	
	self.assistantController.nextButton.title=NSLocalizedString(@"Finish",@"");
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
			if (_projectName.length>0 && [[tProjectDirectory lastPathComponent] isEqualToString:_projectName])
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
		NSString * tTipMessage=[NSString stringWithFormat:NSLocalizedString(@"The project directory %@ will be created if necessary, and the project file %@.pkgproj will be created therein.",@""),tProjectDirectory,tProjectName];
		
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
		
		if (bResult!=NSFileHandlingPanelOKButton)
			return;
		
		NSString * tDirectoryPath=[tOpenPanel.URL.path stringByAbbreviatingWithTildeInPath];
		
		if (_projectDirectoryWasChangedByUser==NO)
			tDirectoryPath=[tDirectoryPath stringByAppendingPathComponent:_projectNametextField.stringValue];
		
		if ([tDirectoryPath hasSuffix:@"/"]==NO)
			tDirectoryPath=[tDirectoryPath stringByAppendingString:@"/"];
		
		BOOL tOldValue=_projectDirectoryWasChangedByUser;
		
		_projectDirectoryTextField.stringValue=tDirectoryPath;
		
		_projectDirectoryWasChangedByUser=tOldValue;
		
		[self _updateAfterModificationOfTextField:_projectDirectoryTextField];
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

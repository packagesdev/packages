/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDocument.h"

#import "PKGApplicationPreferences.h"

#import "PKGDocumentWindowController.h"

#import "PKGBuildDocumentWindowController.h"

#import "PKGBuildOrderManager.h"

#import "PKGBuildAndCleanObserverDataSource.h"

#import "PKGBuildEvent.h"


#import "NSAlert+block.h"

#import "NSString+Packages.h"

@interface PKGDocument ()
{
	NSURL * _temporaryProjectURL;
	
	NSString * _productPath;
	
	PKGBuildOrder * _currentBuildOrder;
	
	PKGBuildAndCleanObserverDataSource * _buildObserver;
	
	PKGBuildDocumentWindowController * _buildWindowController;
}

	@property (readwrite) PKGDocumentRegistry * registry;

	@property (readwrite) PKGDocumentWindowController * documentWindowController;


- (NSURL *)temporaryURLWithError:(NSError **)outError;

- (BOOL)_requestBuildWithOptions:(PKGBuildOptions)inRequestOptions;

// Build Menu

- (IBAction)showHideBuildWindow:(id)sender;

- (IBAction)build:(id)sender;
- (IBAction)buildAndRun:(id)sender;
- (IBAction)buildAndDebug:(id)sender;

- (IBAction)clean:(id)sender;

// Notifications

- (void)buildWindowWillClose:(NSNotification *)inNotification;

- (void)processBuildEventNotification:(NSNotification *)inNotification;

@end

@implementation PKGDocument

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_registry=[PKGDocumentRegistry new];
	}
	
	return self;
}

#pragma mark -

- (void)makeWindowControllers
{
	[self addWindowController:self.documentWindowController];
}

#pragma mark -

- (NSURL *)folderURL
{
	return self.fileURL.URLByDeletingLastPathComponent;
}

- (NSString *)folder
{
	return self.fileURL.path.stringByDeletingLastPathComponent;
}

- (NSString *)referenceProjectPath
{
	return self.folder;
}

- (NSString *)referenceFolderPath
{
	NSString * tReferenceProjectPath=self.documentWindowController.project.settings.referenceFolderPath;
	
	if (tReferenceProjectPath==nil)
		return self.folder;
	
	return tReferenceProjectPath;
}

- (PKGProject *)project
{
	return self.documentWindowController.project;
}

#pragma mark -

- (NSURL *)temporaryURLWithError:(NSError **)outError
{
	NSError * tError=nil;
	NSURL * tTemporaryFolderURL=[[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory
																	   inDomain:NSUserDomainMask
															  appropriateForURL:self.folderURL
																		 create:YES
																		  error:&tError];
	
	if (tTemporaryFolderURL==nil)
	{
		if (tError!=nil && outError!=nil)
			*outError=tError;
		
		return nil;
	}
	
	NSURL * tTemporaryProjectURL=[tTemporaryFolderURL URLByAppendingPathComponent:self.fileURL.path.lastPathComponent];
	
	if (tTemporaryProjectURL==nil)
	{
		// A COMPLETER
		
		return nil;
	}
	
	return tTemporaryProjectURL;
}

#pragma mark -

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	id tPropertyList=[self.documentWindowController.project representation];
	
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
	
	PKGProject * tProject=[PKGProject projectFromPropertyList:tPropertyList error:&tError];
	
	if (tProject==nil)
	{
		
		return NO;
	}
	
	self.documentWindowController=[[PKGDocumentWindowController alloc] initWithProject:tProject];
	
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

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError
{
	return nil;
}

#pragma mark -

- (BOOL)_requestBuildWithOptions:(PKGBuildOptions)inBuildOptions
{
	NSMutableDictionary * tExternalSettings=[NSMutableDictionary dictionary];
	
	NSString * tProjectPath=self.fileURL.path;
	
	_productPath=nil;
	_temporaryProjectURL=nil;
	
	if (self.isDocumentEdited==YES)
	{
		PKGPreferencesBuildUnsavedProjectSaveBehavior tBehavior=[PKGApplicationPreferences sharedPreferences].unsavedProjectSaveBehavior;
		
		switch(tBehavior)
		{
			case PKGPreferencesBuildUnsavedProjectSaveAskBeforeBuild:
			{
				NSAlert * tAlert=[NSAlert new];
				
				tAlert.messageText=[NSString stringWithFormat:NSLocalizedString(@"Do you want to save the changes you made in the project \"%@\" before building it?",@"No comment"),tProjectPath.lastPathComponent.stringByDeletingPathExtension];
				tAlert.informativeText=@"";
				
				[tAlert addButtonWithTitle:NSLocalizedString(@"Save",@"No comment")];
				[tAlert addButtonWithTitle:NSLocalizedString(@"Don't Save",@"No comment")];
				[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
				
				NSModalResponse tResponse=[tAlert runModal];
				
				switch(tResponse)
				{
					case NSAlertFirstButtonReturn:		// Save
						
						[self saveDocument:nil];
						
						break;
						
					case NSAlertSecondButtonReturn:	// Don't Save
					{
						_temporaryProjectURL=[self temporaryURLWithError:NULL];
						
						if (_temporaryProjectURL==nil)
						{
							// Show alert
							
							// A COMPLETER
							
							return NO;
						}
						
						if ([self.project writeToURL:_temporaryProjectURL atomically:YES]==NO)
						{
							// A COMPLETER
							
							return nil;
						}
						
						tProjectPath=_temporaryProjectURL.path;
						tExternalSettings[PKGBuildOrderExternalSettingsReferenceProjectFolderKey]=tProjectPath.stringByDeletingLastPathComponent;
						
						break;
					}
					case NSAlertThirdButtonReturn:		// Cancel
						
						return NO;
				}
				
				break;
			}
				
			case PKGPreferencesBuildUnsavedProjectSaveAlways:
				
				[self saveDocument:nil];
				
				break;
				
			case PKGPreferencesBuildUnsavedProjectSaveNever:
			{
				NSURL * tTemporaryURL=[self temporaryURLWithError:NULL];
				
				if (tTemporaryURL==nil)
				{
					// Show alert
					
					// A COMPLETER
					
					return NO;
				}
				
				if ([self.project writeToURL:_temporaryProjectURL atomically:YES]==NO)
				{
					// A COMPLETER
					
					return nil;
				}
				
				tProjectPath=_temporaryProjectURL.path;
				tExternalSettings[PKGBuildOrderExternalSettingsReferenceProjectFolderKey]=tProjectPath.stringByDeletingLastPathComponent;
				
				break;
			}
		}
	}
	
	if (tProjectPath==nil)
		return NO;
	
	NSString * tScratchFolder=[PKGApplicationPreferences sharedPreferences].temporaryBuildLocation;
	
	if (tScratchFolder!=nil)
		tExternalSettings[PKGBuildOrderExternalSettingsScratchFolderKey]=tScratchFolder;
	
	// A COMPLETER (gestion des User Defined Settings)
	
	
	
	_currentBuildOrder=[PKGBuildOrder new];
	
	_currentBuildOrder.projectPath=tProjectPath;
	_currentBuildOrder.buildOptions=inBuildOptions;
	_currentBuildOrder.externalSettings=[tExternalSettings copy];
	
	if ([[PKGBuildOrderManager defaultManager] executeBuildOrder:_currentBuildOrder
													setupHandler:^(PKGBuildNotificationCenter * bBuildNotificationCenter){
														
														// Register for notifications
														
														_buildObserver=[PKGBuildAndCleanObserverDataSource buildObserverDataSourceForDocument:self];
														
														[bBuildNotificationCenter addObserver:self selector:@selector(processBuildEventNotification:) name:PKGBuildEventNotification object:_currentBuildOrder];
														
														[bBuildNotificationCenter addObserver:_buildObserver selector:@selector(processBuildEventNotification:) name:PKGBuildEventNotification object:_currentBuildOrder];
														
														for(id tObserver in _documentWindowController.buildNotificationObservers)
															[bBuildNotificationCenter addObserver:tObserver selector:@selector(processBuildEventNotification:) name:PKGBuildEventNotification object:_currentBuildOrder];
														
														// Build Window
														
														if (_buildWindowController!=nil)
														{
															_buildWindowController.dataSource=_buildObserver;
															return;
														}
														
														if ([PKGApplicationPreferences sharedPreferences].showBuildWindowBehavior==PKGPreferencesBuildShowBuildWindowAlways)
														{
															_buildWindowController=[PKGBuildDocumentWindowController new];
															
															[self addWindowController:_buildWindowController];
															
															[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buildWindowWillClose:) name:NSWindowWillCloseNotification object:_buildWindowController.window];
															
															_buildWindowController.dataSource=_buildObserver;
															
															[_buildWindowController showWindow:self];
														}
													}
											   completionHandler:^(PKGBuildResult bResult){
												   
												   switch(bResult)
												   {
													   case PKGBuildResultBuildOrderExecutionAgentDidExit:
														   
														   // Post Notification
														   
														   _currentBuildOrder=nil;
														   
														   break;
														   
													   default:
														   
														   break;
												   }
											   }
									   communicationErrorHandler:^(NSError * bCommunicationError){
										   
										   _currentBuildOrder=nil;
										   
										   // Play Failure Sound if needed
										   
										   NSString * tSoundName=[PKGApplicationPreferences sharedPreferences].playedSoundForFailedBuild;
										   
										   if (tSoundName.length>0)
											   [[NSSound soundNamed:tSoundName] play];
										   
										   // Remove Temporary Folder
										   
										   if (_temporaryProjectURL!=nil)
										   {
											   [[NSFileManager defaultManager] removeItemAtURL:[_temporaryProjectURL URLByDeletingLastPathComponent] error:NULL];
											   _temporaryProjectURL=nil;
										   }
										   
										   // A COMPLETER
										   
									   }]==NO)
	{
		return NO;
	}
	
	return YES;
}

#pragma mark - Build menu

- (IBAction)showHideBuildWindow:(id)sender
{
	if (_buildWindowController==nil)
	{
		_buildWindowController=[PKGBuildDocumentWindowController new];
		[self addWindowController:_buildWindowController];
		
		_buildWindowController.dataSource=_buildObserver;
		
		[_buildWindowController showWindow:self];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buildWindowWillClose:) name:NSWindowWillCloseNotification object:_buildWindowController.window];
		
		return;
	}
	
	[_buildWindowController.window performClose:self];
}

- (IBAction)build:(id)sender
{
	[self _requestBuildWithOptions:0];
}

- (IBAction)buildAndRun:(id)sender
{
	[self _requestBuildWithOptions:PKGBuildOptionLaunchAfterBuild];
}

- (IBAction)buildAndDebug:(id)sender
{
	[self _requestBuildWithOptions:PKGBuildOptionLaunchAfterBuild|PKGBuildOptionDebugBuild];
}

- (IBAction)clean:(id)sender
{
	NSAlert * tAlert=[NSAlert new];
	
	tAlert.messageText=NSLocalizedString(@"Warning",@"No comment");
	tAlert.informativeText=NSLocalizedString(@"Cleaning will remove all packages and distributions from the Build location.",@"No comment");
	
	[tAlert addButtonWithTitle:NSLocalizedString(@"Clean",@"No comment")];
	[tAlert addButtonWithTitle:NSLocalizedString(@"Cancel",@"No comment")];
	
	[tAlert WB_beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSModalResponse bResponse){
		
		if (bResponse!=NSAlertFirstButtonReturn)
			return;
		
	}];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(showHideBuildWindow:))
	{
		inMenuItem.title=(_buildWindowController.window.isVisible==YES)? NSLocalizedStringFromTable(@"Hide Build Log Window",@"Build",@"No comment") : NSLocalizedStringFromTable(@"Build Results",@"Build",@"No comment");
		
		return YES;
	}
	
	if (tAction==@selector(build:) ||
		tAction==@selector(buildAndRun:) ||
		tAction==@selector(buildAndDebug:))
	{
		return (_currentBuildOrder==nil);
	}
	
	if (tAction==@selector(clean:))
	{
		// A COMPLETER
	}
	
	return YES;
}

#pragma mark - PKGFilePathConverter

- (NSString *)absolutePathForFilePath:(PKGFilePath *)inFilePath
{
	if (inFilePath==nil)
		return nil;
	
	switch(inFilePath.type)
	{
		case PKGFilePathTypeAbsolute:
			
			return inFilePath.string;
			
		case PKGFilePathTypeRelativeToProject:
			
			return [inFilePath.string PKG_stringByAbsolutingWithPath:self.referenceProjectPath];
			
		case PKGFilePathTypeRelativeToReferenceFolder:
			
			return [inFilePath.string PKG_stringByAbsolutingWithPath:self.referenceFolderPath];
			
		default:
			break;
	}
	
	return nil;
}

- (PKGFilePath *)filePathForAbsolutePath:(NSString *)inAbsolutePath type:(PKGFilePathType)inType
{
	if (inAbsolutePath==nil)
		return nil;
	
	if (inType==PKGFilePathTypeAbsolute)
		return [[PKGFilePath alloc] initWithString:inAbsolutePath type:PKGFilePathTypeAbsolute];
	
	NSString * tReferencePath=nil;
	
	if (inType==PKGFilePathTypeRelativeToProject)
	{
		tReferencePath=self.referenceProjectPath;
	}
	else if (inType==PKGFilePathTypeRelativeToReferenceFolder)
	{
		tReferencePath=self.referenceFolderPath;
	}
	
	if (tReferencePath==nil)
	{
		return nil;
	}
	
	NSString * tConvertedPath=[inAbsolutePath PKG_stringByRelativizingToPath:tReferencePath];
	
	if (tConvertedPath==nil)
	{
		return nil;
	}
	
	return [[PKGFilePath alloc] initWithString:tConvertedPath type:inType];
}

- (BOOL)shiftTypeOfFilePath:(PKGFilePath *)inFilePath toType:(PKGFilePathType)inType
{
	if (inFilePath==nil)
		return NO;
	
	if (inFilePath.type==inType)
		return YES;
	
	if (inFilePath.string!=nil)
	{
		NSString * tAbsolutePath=[self absolutePathForFilePath:inFilePath];
		
		if (tAbsolutePath==nil)
			return NO;
		
		PKGFilePath * tFilePath=[self filePathForAbsolutePath:tAbsolutePath type:inType];
		
		if (tFilePath==nil)
			return NO;
		
		inFilePath.string=tFilePath.string;
	}
	
	inFilePath.type=inType;
	
	return YES;
}

#pragma mark - Notifications

- (void)buildWindowWillClose:(NSNotification *)inNotification
{
	
	_buildWindowController=nil;
}

- (void)processBuildEventNotification:(NSNotification *)inNotification
{
	if (inNotification==nil)
		return;
	
	NSDictionary * tUserInfo=inNotification.userInfo;
	
	if (tUserInfo==nil)
		return;
	
	NSNumber * tNumber=tUserInfo[PKGBuildStepKey];
	
	if ([tNumber isKindOfClass:NSNumber.class]==NO)
		return;
	
	PKGBuildStep tStep=[tNumber unsignedIntegerValue];
	
	NSIndexPath * tStepPath=tUserInfo[PKGBuildStepPathKey];
	
	if ([tStepPath isKindOfClass:NSIndexPath.class]==NO)
		return;
	
	
	tNumber=tUserInfo[PKGBuildStateKey];
	
	if ([tNumber isKindOfClass:NSNumber.class]==NO)
		return;
	
	PKGBuildStepState tState=[tNumber unsignedIntegerValue];
	
	
	NSDictionary * tRepresentation=tUserInfo[PKGBuildStepEventRepresentationKey];
	
	if (tRepresentation!=nil && [tRepresentation isKindOfClass:NSDictionary.class]==NO)
		return;
	
	if (tState==PKGBuildStepStateInfo)
	{
		PKGBuildInfoEvent * tInfoEvent=[[PKGBuildInfoEvent alloc] initWithRepresentation:tRepresentation];
		
		if (tStep==PKGBuildStepProject)
			_productPath=tInfoEvent.filePath;
		
		return;
	}
	
	if (tState==PKGBuildStepStateFailure)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGBuildEventNotification object:nil];
		
		// Play Failure Sound if needed
		
		NSString * tSoundName=[PKGApplicationPreferences sharedPreferences].playedSoundForFailedBuild;
		
		if (tSoundName.length>0)
			[[NSSound soundNamed:tSoundName] play];
		
		// Remove Temporary Folder
		
		if (_temporaryProjectURL!=nil)
		{
			[[NSFileManager defaultManager] removeItemAtURL:_temporaryProjectURL.URLByDeletingLastPathComponent error:NULL];
			_temporaryProjectURL=nil;
		}
		
		// Show Build Window if needed
		
		if (_buildWindowController==nil)
		{
			if ([PKGApplicationPreferences sharedPreferences].showBuildWindowBehavior==PKGPreferencesBuildShowBuildWindowOnErrors)
			{
				_buildWindowController=[PKGBuildDocumentWindowController new];
				_buildWindowController.dataSource=_buildObserver;
				
				[self addWindowController:_buildWindowController];
				
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buildWindowWillClose:) name:NSWindowWillCloseNotification object:_buildWindowController.window];
				
				[_buildWindowController showWindow:self];
			}
			
			return;
		}
		
		// Hide Build Window if needed
		
		if ([PKGApplicationPreferences sharedPreferences].hideBuildWindowBehavior==PKGPreferencesBuildHideBuildWindowAlways)
		{
			if (_buildWindowController!=nil && _buildWindowController.window.isVisible==YES)
				[_buildWindowController.window performClose:self];
		}
		
		_currentBuildOrder=nil;
		
		return;
	}
	
	if (tState==PKGBuildStepStateSuccess)
	{
		if (tStep==PKGBuildStepProject)
		{
			[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGBuildEventNotification object:nil];
			
			_currentBuildOrder=nil;
			
			// Play Success Sound if needed
			
			NSString * tSoundName=[PKGApplicationPreferences sharedPreferences].playedSoundForSuccessfulBuild;
			
			if (tSoundName.length>0)
				[[NSSound soundNamed:tSoundName] play];
			
			// Remove Temporary Folder
			
			if (_temporaryProjectURL!=nil)
			{
				[[NSFileManager defaultManager] removeItemAtURL:_temporaryProjectURL.URLByDeletingLastPathComponent error:NULL];
				_temporaryProjectURL=nil;
			}
			
			// Hide Build Window if needed
			
			if ([PKGApplicationPreferences sharedPreferences].hideBuildWindowBehavior!=PKGPreferencesBuildHideBuildWindowNever)
			{
				if (_buildWindowController!=nil && _buildWindowController.window.isVisible==YES)
					[_buildWindowController.window performClose:self];
			}
			
			PKGBuildOrder * tBuildOrder=inNotification.object;
			
			if ((tBuildOrder.buildOptions&PKGBuildOptionLaunchAfterBuild)==0)
				return;
			
			if (_productPath.length==0)
			{
				// A COMPLETER
				
				return;
			}
			
			if ([[NSWorkspace sharedWorkspace] openFile:_productPath]==YES)
				return;
			
			// A COMPLETER
			
			NSLog(@"[PKGDocument processBuildEventNotification:] Error when opening file \'%@\'",_productPath);
		}
	}
}

@end

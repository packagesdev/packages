/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDocumentWindowController.h"

#import "PKGDocument.h"

#import "PKGDistributionProject+Edition.h"

#import "PKGPackageProjectMainViewController.h"
#import "PKGDistributionProjectMainViewController.h"

#import "PKGDocumentWindowStatusViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGBuildOrderManager.h"

#import "PKGBuildEvent.h"

#import "NSAlert+block.h"

#define PKGDocumentWindowPackageProjectMinWidth				1026.0
#define PKGDocumentWindowDistributionProjectMinWidth		1200.0
#define PKGDocumentWindowMinHeight							613.0

@interface PKGDocumentWindowController ()
{
	PKGProjectMainViewController * _projectMainViewController;
	
	PKGDocumentWindowStatusViewController * _statusViewController;
	
	NSURL * _temporaryProjectURL;
	
	NSString * _productPath;
}

	@property (nonatomic) BOOL showsBuildStatus;

	@property (readwrite) PKGProject * project;



- (BOOL)_asynchronouslRequestBuildWithOptions:(PKGBuildOptions)inRequestOptions;

- (BOOL)_requestBuildWithOptions:(PKGBuildOptions)inRequestOptions;

- (IBAction)upgradeToDistribution:(id)sender;

// Build Commands

- (IBAction)build:(id)sender;
- (IBAction)buildAndRun:(id)sender;
- (IBAction)buildAndDebug:(id)sender;

- (IBAction)clean:(id)sender;

#pragma mark -

- (void)processBuildEventNotification:(NSNotification *)inNotification;

@end

@implementation PKGDocumentWindowController

- (instancetype)initWithProject:(PKGProject *)inProject
{
	self=[super init];
	
	if (self!=nil)
	{
		_project=inProject;
		
		self.shouldCloseDocument=YES;
	}
	
	return self;
}

- (NSString *)windowNibName
{
	return @"PKGDocumentWindowController";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	[self.window setContentBorderThickness:33.0 forEdge:NSMinYEdge];
	
	NSView * tContentView=self.window.contentView;
	
	NSRect tMiddleFrame=self.middleAccessoryView.frame;
	NSRect tRightFrame=self.rightAccessoryView.frame;
	
	tMiddleFrame.size.width=NSMaxX(tContentView.frame)-NSMinX(tMiddleFrame);
	
	tRightFrame.origin.x=NSMaxX(tContentView.frame);
	
	self.middleAccessoryView.frame=tMiddleFrame;
	self.rightAccessoryView.frame=tRightFrame;
	
	[self setMainViewController];
}

#pragma mark -

- (void)setContentsOfRightAccessoryView:(NSView *)inView
{
	NSArray * tSubViews=self.rightAccessoryView.subviews;
	
	if (tSubViews.count==0 && inView==nil)
		return;
	
	for(NSView * tSubView in tSubViews)
		[tSubView removeFromSuperview];
	
	NSView * tContentView=self.window.contentView;
	
	NSRect tMiddleFrame=self.middleAccessoryView.frame;
	NSRect tRightFrame=self.rightAccessoryView.frame;
	
	if (inView==nil)
	{
		// Hide Right Accessory View
		
		tMiddleFrame.size.width=NSMaxX(tContentView.frame)-NSMinX(tMiddleFrame);
		
		tRightFrame.origin.x=NSMaxX(tContentView.frame);
		
		self.middleAccessoryView.frame=tMiddleFrame;
		self.rightAccessoryView.frame=tRightFrame;
	}
	else
	{
		// Show/Resize Accessory View
		
		tRightFrame.size=inView.frame.size;
		
		[self.rightAccessoryView addSubview:inView];
		
		tRightFrame.origin.x=NSMaxX(tContentView.frame)-NSWidth(tRightFrame);
		
		tMiddleFrame.size.width=NSMaxX(tContentView.frame)-NSMinX(tMiddleFrame)-NSWidth(tRightFrame);
		
		self.middleAccessoryView.frame=tMiddleFrame;
		self.rightAccessoryView.frame=tRightFrame;
	}
}

- (void)setShowsBuildStatus:(BOOL)inShowsBuildStatus
{
	if (_showsBuildStatus==inShowsBuildStatus)
		return;
	
	if (inShowsBuildStatus==YES)
	{
		if (_statusViewController==nil)
			_statusViewController=[PKGDocumentWindowStatusViewController new];
		
		if (_statusViewController.view.superview==nil)
		{
			_statusViewController.view.frame=self.middleAccessoryView.bounds;
			
			[_statusViewController WB_viewWillAppear];
			
			[self.middleAccessoryView addSubview:_statusViewController.view];
			
			[_statusViewController WB_viewDidAppear];
		}
	}
	else
	{
		if (_statusViewController.view.superview!=nil)
		{
			[_statusViewController WB_viewWillDisappear];
			
			[_statusViewController.view removeFromSuperview];
			
			[_statusViewController WB_viewDidDisappear];
			
			_statusViewController=nil;
		}
	}
}

#pragma mark -

- (void)setMainViewController
{
	if (_projectMainViewController!=nil)
	{
		[_projectMainViewController WB_viewWillDisappear];
		
		[_projectMainViewController.view removeFromSuperview];
		
		[_projectMainViewController WB_viewDidDisappear];
	}
	
	switch(self.project.type)
	{
		case PKGProjectTypeDistribution:
			
			_projectMainViewController=[[PKGDistributionProjectMainViewController alloc] initWithDocument:self.document];
			
			self.window.minSize=NSMakeSize(PKGDocumentWindowDistributionProjectMinWidth, PKGDocumentWindowMinHeight);
			
			NSRect tWindowFrame=self.window.frame;
			
			if (NSWidth(tWindowFrame)<PKGDocumentWindowDistributionProjectMinWidth)
			{
				tWindowFrame.size.width=PKGDocumentWindowDistributionProjectMinWidth;
				
				[self.window setFrame:tWindowFrame display:YES];
			}
			
			break;
			
		case PKGProjectTypePackage:
			
			_projectMainViewController=[[PKGPackageProjectMainViewController alloc] initWithDocument:self.document];
			
			self.window.minSize=NSMakeSize(PKGDocumentWindowPackageProjectMinWidth, PKGDocumentWindowMinHeight);
			
			break;
	}
	
	_projectMainViewController.project=self.project;
	
	NSView * tContentView=self.window.contentView;
	
	NSView * tMainView=_projectMainViewController.view;
	
	tMainView.frame=tContentView.bounds;
	
	[_projectMainViewController WB_viewWillAppear];
	
	[tContentView addSubview:tMainView];
	
	[_projectMainViewController WB_viewDidAppear];
}

#pragma mark - Project Menu

- (IBAction)upgradeToDistribution:(id)sender
{
	PKGDistributionProject * tDistributionProject=[[PKGDistributionProject alloc] initWithPackageProject:(PKGPackageProject *)self.project];
	
	if (tDistributionProject==nil)
	{
		// A COMPLETER
		
		return;
	}
	
	self.showsBuildStatus=NO;
	
	self.project=tDistributionProject;
	
	[self setMainViewController];
}

#pragma mark -

- (NSString *)temporarySavedProjectPath
{
	NSError * tError=nil;
	NSURL * tTemporaryFolderURL=[[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory
																	   inDomain:NSUserDomainMask
															  appropriateForURL:[self.document folderURL]
																		 create:YES
																		  error:&tError];
	
	NSString * tExplanationString=nil;
	
	if (tTemporaryFolderURL==nil)
	{
		// A COMPLETER
		
		return nil;
	}
	
	NSURL * tTemporaryProjectURL=[tTemporaryFolderURL URLByAppendingPathComponent:[self.document fileURL].path.lastPathComponent];
	
	if (tTemporaryProjectURL==nil)
	{
		// A COMPLETER
		
		return nil;
	}
	
	if ([self.project writeToURL:tTemporaryProjectURL atomically:YES]==NO)
	{
		// A COMPLETER
		
		return nil;
	}
	
	return tTemporaryProjectURL.path;
	
	/*NSFileManager * tFileManager=[NSFileManager defaultManager];
	
	if ([tFileManager fileExistsAtPath:tTempPath isDirectory:&isDirectory]==NO)
	{
		if ([tFileManager createDirectoryAtPath:tTempPath withIntermediateDirectories:NO attributes:nil error:NULL]==NO)
		{
			tExplanationString=NSLocalizedStringFromTable(@"Creation of temporary folder failed.",@"Build",@"");
			
			goto bail;
		}
	}
	else
	{
		if (isDirectory==NO)
		{
			if ([tFileManager removeItemAtPath:tTempPath error:NULL]==NO)
			{
				tExplanationString=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Removing file at path '%@' failed.",@"Build",@""),tTempPath];
				
				goto bail;
			}
			else
			{
				if ([tFileManager createDirectoryAtPath:tTempPath withIntermediateDirectories:NO attributes:nil error:NULL]==NO)
				{
					tExplanationString=NSLocalizedStringFromTable(@"Creation of temporary folder failed.",@"Build",@"");
					
					goto bail;
				}
			}
		}
	}
	
	NSString * tTemporaryProjectPath=[NSString stringWithFormat:@"%@/%d/%@",ICPREFERENCES_DEFAULT_TEMPORARY_BUILD_LOCATION,getuid(),[[[self fileURL] path] lastPathComponent]];
	
	if (tTemporaryProjectPath!=nil)
	{
		if ([self.project writeToURL:[NSURL fileURLWithPath:tTemporaryProjectPath] atomically:YES]==NO)
		{
			
		}
	}
	
	return tTemporaryProjectPath;
	
bail:
	
	NSBeep();
	
	NSBeginAlertSheet(NSLocalizedStringFromTable(@"Packages is unable to build the project because a temporary project file can not be created.",@"Build",@""),
					  nil,
					  nil,
					  nil,
					  [self windowForSheet],
					  nil, 
					  nil,
					  nil,
					  NULL,
					  @"%@",tExplanationString);
	
	return nil;*/
}

- (BOOL)_asynchronouslRequestBuildWithOptions:(PKGBuildOptions)inBuildOptions
{
	NSMutableDictionary * tExternalSettings=[NSMutableDictionary dictionary];
	
	NSDocument * tDocument=self.document;
	
	NSString * tProjectPath=tDocument.fileURL.path;
	
	_productPath=nil;
	_temporaryProjectURL=nil;
	
	if (tDocument.isDocumentEdited==YES)
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
						
						[tDocument saveDocument:nil];
						
						break;
						
					case NSAlertSecondButtonReturn:	// Don't Save
					{
						_temporaryProjectURL=[self.document temporaryURLWithError:NULL];
						
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
				
				[tDocument saveDocument:nil];
				
				break;
				
			case PKGPreferencesBuildUnsavedProjectSaveNever:
			{
				NSURL * tTemporaryURL=[self.document temporaryURLWithError:NULL];
				
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
	
	
	
	PKGBuildOrder * tBuildOrder=[[PKGBuildOrder alloc] init];
	
	tBuildOrder.projectPath=tProjectPath;
	tBuildOrder.buildOptions=inBuildOptions;
	tBuildOrder.externalSettings=[tExternalSettings copy];
	
	if ([[PKGBuildOrderManager defaultManager] executeBuildOrder:tBuildOrder
													setupHandler:^(PKGBuildNotificationCenter * bBuildNotificationCenter){
														
														// Register for notifications
												 
														[bBuildNotificationCenter addObserver:self selector:@selector(processBuildEventNotification:) name:PKGBuildEventNotification object:tBuildOrder];
														[bBuildNotificationCenter addObserver:_statusViewController selector:@selector(processBuildEventNotification:) name:PKGBuildEventNotification object:tBuildOrder];
														
														
											 }
											   completionHandler:^(PKGBuildResult bResult){
											   
												   switch(bResult)
												   {
													   case PKGBuildResultBuildOrderExecutionAgentDidExit:
														   
														   // Post Notification
														   
														   break;
														   
													   default:
														   
														   break;
												   }
										   }
									   communicationErrorHandler:^(NSError * bCommunicationError){
									   
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
		;
	}
	/*int tResult=[ICDispatchBuildUtilities  buildProjectAtPath:tProjectPath withNotificationPath:[[self fileURL] path] locationEnabled:inLocationEnabled];
	
	switch(tResult)
	{
		case -1:
			
			NSBeep();
			
			NSBeginAlertSheet(NSLocalizedStringFromTable(@"No signal from the packages_dispatcher process",@"Build",@"No comment"),
							  nil,
							  nil,
							  nil,
							  [self windowForSheet],
							  nil,
							  nil,
							  nil,
							  NULL,
							  NSLocalizedStringFromTable(@"The packages_dispatcher process is not responding. Packages can't build any project when this process is not running.",@"Build",@"No comment"));
			
			return NO;
			
		case NO:
			
			NSBeep();
			
			return NO;
			
		case YES:
			
			building_=YES;
			
			break;
	}
	
	return YES;*/
	
	return NO;
}

- (BOOL)_requestBuildWithOptions:(PKGBuildOptions)inRequestOptions
 {
	 self.showsBuildStatus=YES;

	BOOL tResult=[self _asynchronouslRequestBuildWithOptions:inRequestOptions];

	if (tResult==YES)
	{
		// Notify the Build Window
		
		//[[NSNotificationCenter defaultCenter] postNotificationName:PACKAGES_BUILDER_NOTIFICATION_BUILD_DID_START object:self];
		
		if ([PKGApplicationPreferences sharedPreferences].showBuildWindowBehavior==PKGPreferencesBuildShowBuildWindowAlways)
		{
			//[buildWindowController_ showWindow:self cleanWindow:YES];
		}
	}

	return tResult;
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
	
	[tAlert WB_beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse bResponse){
		
		if (bResponse!=NSAlertFirstButtonReturn)
			return;
		
		
	}];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;

	if (tAction==@selector(upgradeToDistribution:))
		return [self.project isKindOfClass:PKGPackageProject.class];
	
	if (tAction==@selector(build:) ||
		tAction==@selector(buildAndRun:) ||
		tAction==@selector(buildAndDebug:) ||
		tAction==@selector(clean:))
	{
		// A COMPLETER
	}
	
	return YES;
}

#pragma mark -

- (void)processBuildEventNotification:(NSNotification *)inNotification
{
	if (inNotification==nil)
		return;
	
	NSDictionary * tUserInfo=[inNotification userInfo];
	
	if (tUserInfo==nil)
		return;
	
	NSNumber * tNumber=tUserInfo[PKGBuildStepKey];
	
	if ([tNumber isKindOfClass:[NSNumber class]]==NO)
		return;
	
	PKGBuildStep tStep=[tNumber unsignedIntegerValue];
	
	NSIndexPath * tStepPath=tUserInfo[PKGBuildStepPathKey];
	
	if ([tStepPath isKindOfClass:[NSIndexPath class]]==NO)
		return;
	
	
	tNumber=tUserInfo[PKGBuildStateKey];
	
	if ([tNumber isKindOfClass:[NSNumber class]]==NO)
		return;
	
	PKGBuildStepState tState=[tNumber unsignedIntegerValue];
	
	
	NSDictionary * tRepresentation=tUserInfo[PKGBuildStepEventRepresentationKey];
	
	if (tRepresentation!=nil && [tRepresentation isKindOfClass:[NSDictionary class]]==NO)
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
			[[NSFileManager defaultManager] removeItemAtURL:[_temporaryProjectURL URLByDeletingLastPathComponent] error:NULL];
			_temporaryProjectURL=nil;
		}
		
		return;
	}
	
	if (tState==PKGBuildStepStateSuccess)
	{
		if (tStep==PKGBuildStepProject)
		{
			[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGBuildEventNotification object:nil];
			
			//building_=NO;
			
			// Play Success Sound if needed
			
			NSString * tSoundName=[PKGApplicationPreferences sharedPreferences].playedSoundForSuccessfulBuild;
			
			if (tSoundName.length>0)
				[[NSSound soundNamed:tSoundName] play];
			
			// Remove Temporary Folder
			
			if (_temporaryProjectURL!=nil)
			{
				[[NSFileManager defaultManager] removeItemAtURL:[_temporaryProjectURL URLByDeletingLastPathComponent] error:NULL];
				_temporaryProjectURL=nil;
			}
			
			PKGBuildOrder * tBuildOrder=inNotification.object;
			
			if ((tBuildOrder.buildOptions|PKGBuildOptionLaunchAfterBuild)==0)
				return;
			
			if (_productPath.length==0)
			{
				// A COMPLETER
				
				return;
			}
			
			if ([[NSWorkspace sharedWorkspace] openFile:_productPath]==YES)
				return;
			
			// A COMPLETER
			
			NSLog(@"[PKGDocumentWindowController processBuildEventNotification:] Error when opening file \'%@\'",_productPath);
		}
	}
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
	[_projectMainViewController updateViewMenu];
}

@end

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

#import "PKGPackageProjectMainViewController.h"
#import "PKGDistributionProjectMainViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGBuildOrderManager.h"

#define PKGDocumentWindowPackageProjectMinWidth				1026.0
#define PKGDocumentWindowDistributionProjectMinWidth		1200.0
#define PKGDocumentWindowMinHeight							613.0

@interface PKGDocumentWindowController ()
{
	PKGProjectMainViewController * _projectMainViewController;
	
	BOOL _launchAfterBuild;
}

	@property (readwrite) PKGProject * project;

- (NSString *)temporarySavedProjectPath;

- (BOOL)buildAsynchronousWithSearchLocationEnabled:(BOOL)inLocationEnabled;

- (BOOL)_buildWithSearchLocationEnabled:(BOOL)inLocationEnabled;

// Build Commands

- (IBAction)build:(id)sender;
- (IBAction)buildAndRun:(id)sender;
- (IBAction)buildAndDebug:(id)sender;

- (IBAction)clean:(id)sender;

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
	
	switch(self.project.type)
	{
		case PKGProjectTypeDistribution:
			
			_projectMainViewController=[[PKGDistributionProjectMainViewController alloc] initWithDocument:self.document];
			
			[self.window setMinSize:NSMakeSize(PKGDocumentWindowDistributionProjectMinWidth, PKGDocumentWindowMinHeight)];
			
			break;
			
		case PKGProjectTypePackage:
			
			_projectMainViewController=[[PKGPackageProjectMainViewController alloc] initWithDocument:self.document];
			
			[self.window setMinSize:NSMakeSize(PKGDocumentWindowPackageProjectMinWidth, PKGDocumentWindowMinHeight)];
			
			break;
	}
	
	_projectMainViewController.project=self.project;
	
	NSView * tContentView=self.window.contentView;
	
	NSView * tMainView=_projectMainViewController.view;
	
	NSRect tBounds=tContentView.bounds;
	
	tMainView.frame=tBounds;
	
	[_projectMainViewController WB_viewWillAppear];
	
	[tContentView addSubview:tMainView];
	
	[_projectMainViewController WB_viewDidAppear];
	
	[self.window setContentBorderThickness:33.0 forEdge:NSMinYEdge];
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

- (BOOL)buildAsynchronouslyInDebugMode:(BOOL)inDebugMode
{
	_launchAfterBuild=NO;
	
	NSMutableDictionary * tExternalSettings=[NSMutableDictionary dictionary];
	
	NSDocument * tDocument=self.document;
	
	NSString * tProjectPath=tDocument.fileURL.path;
	
	if (tDocument.isDocumentEdited==YES)
	{
		PKGPreferencesBuildUnsavedProjectSaveBehavior tBehavior=[PKGApplicationPreferences sharedPreferences].unsavedProjectSaveBehavior;
		
		switch(tBehavior)
		{
			case PKGPreferencesBuildUnsavedProjectSaveAskBeforeBuild:
			{
				NSString * tAlertTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Do you want to save the changes you made in the project \"%@\" before building it?",@"Build",@"No comment"),tProjectPath.lastPathComponent.stringByDeletingPathExtension];
				
				NSInteger tReturnCode=NSRunAlertPanel(tAlertTitle,@"",NSLocalizedString(@"Save",@"No comment"),NSLocalizedString(@"Don't Save",@"No comment"),NSLocalizedString(@"Cancel",@"No comment"));
				
				switch(tReturnCode)
				{
					case NSAlertDefaultReturn:		// Save
						
						[tDocument saveDocument:nil];
						
						break;
						
					case NSAlertAlternateReturn:	// Don't Save
						
						tProjectPath=[self temporarySavedProjectPath];
						tExternalSettings[PKGBuildOrderExternalSettingsReferenceProjectFolderKey]=tProjectPath.stringByDeletingLastPathComponent;
						
						break;
						
					case NSAlertOtherReturn:		// Cancel
						
						return NO;
				}
			
				break;
			}
				
			case PKGPreferencesBuildUnsavedProjectSaveAlways:
				
				[tDocument saveDocument:nil];
				
				break;
				
			case PKGPreferencesBuildUnsavedProjectSaveNever:
				
				tProjectPath=[self temporarySavedProjectPath];
				tExternalSettings[PKGBuildOrderExternalSettingsReferenceProjectFolderKey]=tProjectPath.stringByDeletingLastPathComponent;
				
				break;
		}
	}
	
	if (tProjectPath==nil)
		return NO;
	
	NSString * tScratchFolder=[PKGApplicationPreferences sharedPreferences].temporaryBuildLocation;
	
	if (tScratchFolder!=nil)
		tExternalSettings[PKGBuildOrderExternalSettingsScratchFolderKey]=tScratchFolder;
	
	// A COMPLETER (gestion des User Defined Settings)
	
	/*PKGCommandLineBuildObserver * tBuildObserver=[[PKGCommandLineBuildObserver alloc] init];
	tBuildObserver.verbose=tVerbose;*/
	
	PKGBuildOrder * tBuildOrder=[[PKGBuildOrder alloc] init];
	
	tBuildOrder.projectPath=tProjectPath;
	tBuildOrder.buildOptions=(inDebugMode==YES) ? PKGBuildOptionsDebugBuild : 0;
	tBuildOrder.externalSettings=[tExternalSettings copy];
	
	if ([[PKGBuildOrderManager defaultManager] executeBuildOrder:tBuildOrder
													setupHandler:^(PKGBuildNotificationCenter * bBuildNotificationCenter){
												 
												 // Register for notifications
												 
												 /*[bBuildNotificationCenter addObserver:tBuildObserver selector:@selector(processBuildEventNotification:) name:PKGBuildEventNotification object:nil];
												 [bBuildNotificationCenter addObserver:tBuildObserver selector:@selector(processBuildDebugNotification:) name:PKGBuildDebugNotification object:nil];*/
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

- (BOOL)_buildWithSearchLocationEnabled:(BOOL)inLocationEnabled
 {
	/*[IBbuildStatusLabel_ setStringValue:NSLocalizedStringFromTable(@"Building...",@"Build",@"")];
	
	[IBbuildStatusProgressIndicator_ setIndeterminate:NO];
	
	[IBbuildStatusProgressIndicator_ setDoubleValue:0];
	
	[IBbuildStatusProgressIndicator_ setMaxValue:4];*/

	BOOL tResult=[self buildAsynchronousWithSearchLocationEnabled:inLocationEnabled];

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
	[self _buildWithSearchLocationEnabled:YES];
}

- (IBAction)buildAndRun:(id)sender
{
	if ([self _buildWithSearchLocationEnabled:YES]==YES)
		_launchAfterBuild=YES;
}

- (IBAction)buildAndDebug:(id)sender
{
	if ([self _buildWithSearchLocationEnabled:NO]==YES)
		_launchAfterBuild=YES;
}

- (IBAction)clean:(id)sender
{
}

#pragma mark -

- (void)windowDidBecomeMain:(NSNotification *)notification
{
	[_projectMainViewController updateViewMenu];
}



@end

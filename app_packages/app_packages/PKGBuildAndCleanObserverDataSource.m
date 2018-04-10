/*
 Copyright (c) 2017-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGBuildAndCleanObserverDataSource.h"

#import "PKGBuildDispatcher+Constants.h"

#import "PKGProject.h"
#import "PKGDistributionProject.h"


#import "PKGBuildEventsForest.h"

#import "PKGBuildNotificationCenter.h"
#import "PKGBuildEvent.h"

typedef NS_ENUM(NSUInteger, PKGObserverDataSourceType)
{
	PKGObserverDataSourceBuild,
	PKGObserverDataSourceClean
};

@interface PKGBuildAndCleanObserverDataSource ()
{
	PKGProject * _project;
	
	PKGBuildEventsForest * _tree;
	
	PKGBuildEventTreeNode * _currentBuildTreeNode;
	
	NSUInteger _numberOfPackagesToBuild;
	
	NSUInteger _indexOfPackagesBeingBuilt;
}

@property (nonatomic,readwrite,copy) NSString * statusDescription;

@end

@implementation PKGBuildAndCleanObserverDataSource

+ (PKGBuildAndCleanObserverDataSource *)buildObserverDataSourceForDocument:(PKGDocument *)inDocument
{
	PKGBuildAndCleanObserverDataSource * nObserverDataSource=[[PKGBuildAndCleanObserverDataSource alloc] initWithDocument:inDocument type:PKGObserverDataSourceBuild];
	
	return nObserverDataSource;
}

- (instancetype)initWithDocument:(PKGDocument *)inDocument type:(PKGObserverDataSourceType)inType
{
	self=[super init];
	
	if (self!=nil)
	{
		_project=inDocument.project;
		
		switch(inType)
		{
			case PKGObserverDataSourceBuild:
				
				_tree=[PKGBuildEventsForest buildEventsTreeForDocumentNamed:inDocument.displayName];
				
				_currentBuildTreeNode=_tree.rootNodes.array.firstObject;
				
				break;
				
			case PKGObserverDataSourceClean:
				
				// A COMPLETER
				
				break;
		}
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (void)setDelegate:(id<PKGBuildAndCleanObserverDataSourceDelegate>)inDelegate
{
	if (_delegate==inDelegate)
		return;
	
	_delegate=inDelegate;
	
	[_delegate buildAndCleanObserverDataSource:self shouldReloadDataAndExpandItem:_tree.rootNodes.array.firstObject];
}

- (PKGInstallerAppPackageType)packageType
{
	if (_project==nil || _project.type==PKGProjectTypePackage)
		return PKGInstallerAppRawPackage;
	
	PKGDistributionProject * tDistributionProject=(PKGDistributionProject *)_project;
	
	return (tDistributionProject.isFlat==YES) ? PKGInstallerAppDistributionFlat : PKGInstallerAppDistributionBundle;
}

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)inOutlineView numberOfChildrenOfItem:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return _tree.rootNodes.array.count;
	
	return inTreeNode.numberOfChildren;
}

- (id)outlineView:(NSOutlineView *)inOutlineView child:(NSInteger)inIndex ofItem:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return _tree.rootNodes.array[inIndex];
	
	return [inTreeNode childNodeAtIndex:inIndex];
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView isItemExpandable:(PKGTreeNode *)inTreeNode
{
	return ([inTreeNode isLeaf]==NO);
}

#pragma mark -

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
	
	PKGBuildStep tStep=tNumber.unsignedIntegerValue;
	
	NSIndexPath * tStepPath=tUserInfo[PKGBuildStepPathKey];
	
	if ([tStepPath isKindOfClass:NSIndexPath.class]==NO)
		return;
	
	
	tNumber=tUserInfo[PKGBuildStateKey];
	
	if ([tNumber isKindOfClass:NSNumber.class]==NO)
		return;
	
	PKGBuildStepState tState=tNumber.unsignedIntegerValue;
	
	
	NSDictionary * tRepresentation=tUserInfo[PKGBuildStepEventRepresentationKey];
	
	if (tRepresentation!=nil && [tRepresentation isKindOfClass:NSDictionary.class]==NO)
		return;
	
	// Retrieve the data necessary for the status label
	
	if (tState==PKGBuildStepStateInfo)
	{
		PKGBuildInfoEvent * tInfoEvent=[[PKGBuildInfoEvent alloc] initWithRepresentation:tRepresentation];
		
		switch(tStep)
		{
			case PKGBuildStepDistribution:
				
				_numberOfPackagesToBuild=tInfoEvent.packagesCount;
				
				break;
				
			default:
				
				break;
		}
	}
	else if (tState==PKGBuildStepStateBegin)
	{
		switch(tStep)
		{
			case PKGBuildStepProject:
				
				self.statusDescription=NSLocalizedStringFromTable(@"Building...",@"Build",@"");
				
				_numberOfPackagesToBuild=0;
				_indexOfPackagesBeingBuilt=0;
				
				break;
				
			case PKGBuildStepDistribution:
				
				_indexOfPackagesBeingBuilt=0;
				
				break;
				
			case PKGBuildStepPackage:
				
				self.statusDescription=NSLocalizedStringFromTable(@"Building package...",@"Build",@"");
				
				break;
				
			case PKGBuildStepPackageCreate:
			case PKGBuildStepPackageReference:
			case PKGBuildStepPackageImport:
				
				if (_numberOfPackagesToBuild>0)
				{
					_indexOfPackagesBeingBuilt++;
					
					if (_numberOfPackagesToBuild==1)
						self.statusDescription=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Building %lu of 1 package...",@"Build",@""),(unsigned long)_indexOfPackagesBeingBuilt];
					else
						self.statusDescription=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Building %lu of %lu packages...",@"Build",@""),(unsigned long)_indexOfPackagesBeingBuilt,(unsigned long)_numberOfPackagesToBuild];
				}
				
				break;
				
			default:
				break;
		}
	}
	else if (tState==PKGBuildStepStateFailure)
	{
		self.statusDescription=NSLocalizedStringFromTable(@"Build failed",@"Build",@"");
	}
	else if (tState==PKGBuildStepStateSuccess)
	{
		if (tStep==PKGBuildStepProject)
			self.statusDescription=NSLocalizedStringFromTable(@"Build succeeded",@"Build",@"");
	}
	/*
	
	else if (tEventInfoID==IC_BUILDER_NOTIFICATION_INFO_EVENT_CLEAN)
	{
		int tStep;
		int tState;
		
		tStep=[[tUserInfo objectForKey:IC_BUILDER_INFORMATION_STEP] intValue];
		
		tState=[[tUserInfo objectForKey:IC_BUILDER_INFORMATION_STATE] intValue];
		
		if (tStep==IC_BUILDER_INFORMATION_STEP_CLEAN)
		{
			if (tState==IC_BUILDER_BUILD_STATE_END_SUCCESS)
			{
				[IBstatusLabel_ setStringValue:NSLocalizedStringFromTable(@"Clean succeeded",@"Build",@"")];
			}
			else if (tState==IC_BUILDER_BUILD_STATE_END_FAILURE)
			{
				[IBstatusLabel_ setStringValue:NSLocalizedStringFromTable(@"Clean failed",@"Build",@"")];
			}
		}
		else if (tStep==IC_BUILDER_INFORMATION_STEP_CLEAN_OBJECT)
		{
		}
		else
		{
			NSLog(@"[ICBuildWindowController builderNotification:] Unknown Step");
		}
	}*/
	
	
	
	NSString * (^fileItemTypeName)(PKGBuildErrorFileKind)=^NSString *(PKGBuildErrorFileKind bFileKind)
	{
		switch(bFileKind)
		{
			case PKGFileKindRegularFile:
				
				return NSLocalizedStringFromTable(@"the file",@"Build",@"");
				
			case PKGFileKindFolder:
				
				return NSLocalizedStringFromTable(@"the folder",@"Build",@"");
				
			case PKGFileKindPlugin:
				
				return NSLocalizedStringFromTable(@"the plugin",@"Build",@"");
				
			case PKGFileKindTool:
				
				return NSLocalizedStringFromTable(@"the tool",@"Build",@"");
				
			case PKGFileKindPackage:
				
				return NSLocalizedStringFromTable(@"the package",@"Build",@"");
				
			case PKGFileKindBundle:
				
				return NSLocalizedStringFromTable(@"the bundle",@"Build",@"");
		}
		
		return nil;
	};
	
	
	
	if (tState==PKGBuildStepStateBegin)
	{
		PKGBuildInfoEvent * tInfoEvent=[[PKGBuildInfoEvent alloc] initWithRepresentation:tRepresentation];
		
		PKGBuildEventItemType tType=PKGBuildEventItemStep;
		NSString * tTitle=nil;
		NSString * tSubTitle=nil;
		
		switch(tStep)
		{
			case PKGBuildStepProject:
			case PKGBuildStepDistribution:
			case PKGBuildStepPackage:
				
				return;
			
			case PKGBuildStepProjectBuildFolder:
				
				tTitle=NSLocalizedStringFromTable(@"Create build folder",@"Build",@"");
				break;
				
			case PKGBuildStepDistributionWelcomeMessage:
				
				tTitle=NSLocalizedStringFromTable(@"Copy introduction documents",@"Build",@"");
				break;
				
			case PKGBuildStepDistributionReadMeMessage:
				
				tTitle=NSLocalizedStringFromTable(@"Copy readme documents",@"Build",@"");
				break;
				
			case PKGBuildStepDistributionLicenseMessage:
				
				tTitle=NSLocalizedStringFromTable(@"Copy license documents",@"Build",@"");
				break;
				
			case PKGBuildStepDistributionConclusionMessage:
				
				tTitle=NSLocalizedStringFromTable(@"Copy conclusion documents",@"Build",@"");
				break;
				
			case PKGBuildStepDistributionBackgroundImage:
				
				tTitle=NSLocalizedStringFromTable(@"Copy background image",@"Build",@"");
				break;
				
			case PKGBuildStepDistributionScript:
				
				tType=PKGBuildEventItemDistributionScript;
				tTitle=NSLocalizedStringFromTable(@"Create distribution script",@"Build",@"");
				tSubTitle=NSLocalizedStringFromTable(@"Distribution script and other resources",@"Build",@"");
				
				break;
			case PKGBuildStepDistributionChoicesHierarchies:
				
				tTitle=NSLocalizedStringFromTable(@"Create hierarchy of choices",@"Build",@"");
				
				break;
				
			case PKGBuildStepDistributionInstallationRequirements:
				
				tTitle=NSLocalizedStringFromTable(@"Create installation and volume requirements",@"Build",@"");
				break;
				
			case PKGBuildStepDistributionJavaScript:
				
				tTitle=NSLocalizedStringFromTable(@"Create JavaScript code",@"Build",@"");
				break;
				
			case PKGBuildStepDistributionInstallerPlugins:
				
				tTitle=NSLocalizedStringFromTable(@"Copy Installer plugins",@"Build",@"");
				break;
				
			case PKGBuildStepXarCreate:
				
				tTitle=NSLocalizedStringFromTable(@"Create xar archive",@"Build",@"");
				break;
				
			case PKGBuildStepDistributionResources:
				
				tTitle=NSLocalizedStringFromTable(@"Copy extra resources",@"Build",@"");
				break;
				
			case PKGBuildStepDistributionScripts:
				
				tType=PKGBuildEventItemStepParent;
				tTitle=NSLocalizedStringFromTable(@"Scripts payload",@"Build",@"");
				
				break;
				
			case PKGBuildStepPackageCreate:
			case PKGBuildStepPackageReference:
			case PKGBuildStepPackageImport:
			{
				if ([_project isKindOfClass:PKGDistributionProject.class]==NO)
					return;
				
				
				
				PKGDistributionProject * tDistributionProject=(PKGDistributionProject *)_project;
				
				PKGPackageComponent * tPackageComponent=[tDistributionProject packageComponentWithUUID:tInfoEvent.packageUUID];
				
				if (tPackageComponent==nil)
				{
					NSLog(@"No component with UUID \"%@\" was found in this project",tInfoEvent.packageUUID);
					
					return;
				}
				
				if (tStep==PKGBuildStepPackageCreate)
					tType=PKGBuildEventItemDistributionPackageProject;
				else
					tType=PKGBuildEventItemDistributionPackage;
				
				NSString * tString=nil;
				NSString * tPackageName=tInfoEvent.packageName;
				
				if (tStep==PKGBuildStepPackageImport)
				{
					tString=@"Import package";
					
					PKGFilePath * tImportpath=tPackageComponent.importPath;
					
					if (tImportpath==nil)
					{
						NSLog(@"The import path for package UUID \"%@\" is missing",tInfoEvent.packageUUID);
							  
						return;
					}
					
					tSubTitle=tImportpath.string;
				}
				else if (tStep==PKGBuildStepPackageReference)
				{
					tString=@"Create reference to package";
					
					PKGPackageSettings * tPackageSettings=tPackageComponent.packageSettings;
						
					NSString * tLocationURL=tPackageSettings.locationURL;
					
					if (tLocationURL.length>0)
					{
						NSString * tURLPrefix=tPackageSettings.locationScheme;
						
						if (tURLPrefix!=nil)
						{
							tLocationURL=tPackageSettings.locationPath;
							
							tLocationURL=[tLocationURL stringByAppendingPathComponent:tPackageName];
							
							if (tLocationURL!=nil)
								tSubTitle=[NSString stringWithFormat:@"%@%@.pkg",tURLPrefix,tLocationURL];
						}
					}
					else
					{
						tSubTitle=[NSString stringWithFormat:@"-://%@.pkg",tPackageName];
					}
				}
				else
				{
					tString=@"Create package";
					
					tSubTitle=tPackageName;
				}
				
				tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(tString,@"Build",@""),tPackageName];
				
				break;
			}
				
			case PKGBuildStepPackagePayload:
				
				tType=PKGBuildEventItemStepParent;
				tTitle=NSLocalizedStringFromTable(@"Create payload",@"Build",@"");
				
				break;
				
			case PKGBuildStepScriptsPayload:
				
				tType=PKGBuildEventItemStepParent;
				tTitle=NSLocalizedStringFromTable(@"Scripts payload",@"Build",@"");
				
				break;
				
			case PKGBuildStepPackageInfo:
				
				tTitle=NSLocalizedStringFromTable(@"Create PackageInfo document",@"Build",@"");
				break;
				
			case PKGBuildStepPayloadAssemble:
				
				tTitle=NSLocalizedStringFromTable(@"Assemble payload files",@"Build",@"");
				break;
				
			case PKGBuildStepPayloadSplit:
				
				tTitle=NSLocalizedStringFromTable(@"Split forks",@"Build",@"");
				break;
				
			case PKGBuildStepPayloadBom:
				
				tTitle=NSLocalizedStringFromTable(@"Create bill of materials",@"Build",@"");
				break;
				
			case PKGBuildStepPayloadPax:
				
				tTitle=NSLocalizedStringFromTable(@"Create pax archive",@"Build",@"");
				break;
				
			default:
				
				break;
		}
		
		PKGBuildEventItem * tBuildEventItem=[PKGBuildEventItem new];
		
		tBuildEventItem.type=tType;
		tBuildEventItem.title=tTitle;
		tBuildEventItem.subTitle=tSubTitle;
		tBuildEventItem.state=PKGBuildEventItemStateRunning;
		
		PKGBuildEventTreeNode * tBuildEventTreeNode=[[PKGBuildEventTreeNode alloc] initWithRepresentedObject:tBuildEventItem children:nil];
		
		[_currentBuildTreeNode addChild:tBuildEventTreeNode];
		
		_currentBuildTreeNode=tBuildEventTreeNode;
		
		[_delegate buildAndCleanObserverDataSource:self shouldReloadDataAndExpandItem:([_currentBuildTreeNode isLeaf]==NO) ? _currentBuildTreeNode : nil];
	}
	else if (tState==PKGBuildStepStateFailure)
	{
		PKGBuildError tFailureReason=PKGBuildErrorUnknown;
		
		PKGBuildErrorEvent * tErrorEvent=[[PKGBuildErrorEvent alloc] initWithRepresentation:tRepresentation];
		NSString * tTitle=nil;
		
		if (tErrorEvent!=nil)
			tFailureReason=tErrorEvent.code;
		
		if (tFailureReason==PKGBuildErrorUnknown)
		{
			tTitle=NSLocalizedStringFromTable(@"Unknown Error",@"Build",@"No comment");
		}
		else if (tFailureReason==PKGBuildErrorOutOfMemory)
		{
			tTitle=NSLocalizedStringFromTable(@"Not enough memory to perform operation",@"Build",@"No comment");
		}
		else
		{
			NSString * tTag=tErrorEvent.tag;
			
			NSString * tFilePath=tErrorEvent.filePath;
			PKGBuildErrorFileKind tFileKind=tErrorEvent.fileKind;
			
			switch(tFailureReason)
			{
				case PKGBuildErrorMissingInformation:
					
					if ([tTag isEqualToString:@"PKGPackageSettingsLocationTypeKey"]==YES)
						tTitle=NSLocalizedStringFromTable(@"The location of the package has not been fully defined.",@"Build",@"");
					else
						tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Missing information for tag '%@'",@"Build",@""),tTag];
					
					break;
					
				case PKGBuildErrorMissingBuildData:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Missing build data for tag '%@'",@"Build",@""),tTag];
					
					break;
					
				case PKGBuildErrorIncorrectValue:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Incorrect value for object with tag '%@'",@"Build",@""),tTag];
					
					break;
					
				case PKGBuildErrorFileIncorrectType:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Incorrect type for file at path '%@'",@"Build",@""),tFilePath];
					
					break;
				
				case PKGBuildErrorFileAbsolutePathCanNotBeComputed:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"An absolute path can not be computed from path '%@'",@"Build",@""),tFilePath];
					
					break;
					
				/*case IC_BUILDER_FAILURE_REASON_FILE_INSUFFICIENT_PERMISSIONS_WRITE:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Insufficient privileges to write at path \"%@\"",@"Build",@""),tFilePath];
					
					break;
					
				*/
				
				case PKGBuildErrorFileAccountsCanNotBeSet:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Insufficient privileges to set accounts for path '%@'",@"Build",@""),tFilePath];
					
					break;
					
				case PKGBuildErrorFileAttributesCanNotBeRead:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to read attributes of item at path '%@'",@"Build",@""),tFilePath];
					
					break;
				
				case PKGBuildErrorFileAttributesCanNotBeSet:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to set attributes of item at path '%@'",@"Build",@""),tFilePath];
					
					break;
					
				case PKGBuildErrorExternalToolFailure:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ returned error code (%d)",@"Build",@""),[tFilePath lastPathComponent],tErrorEvent.toolTerminationStatus];
					
					if (tErrorEvent.tag!=nil)
						tTitle=[tTitle stringByAppendingFormat:NSLocalizedStringFromTable(@": %@",@"Build",@""),tErrorEvent.tag];

					break;
					
				case PKGBuildErrorUnknownLanguage:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Language (%@) not supported",@"Build",@""),tTag];
					
					break;
					
				case PKGBuildErrorLicenseTemplateNotFound:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"License template for \"%@\" can not be found",@"Build",@""),tTag];
					
					break;
					
				/*case IC_BUILDER_FAILURE_REASON_PACKAGE_SAME_NAME:
					
					// A COMPLETER
					
					break;*/
					
				case PKGBuildErrorEmptyString:
					
					tTitle=nil;
					
					if (tStep==PKGBuildStepPackageInfo ||
						tStep==PKGBuildStepPackageReference)
					{
						if ([tTag isEqualToString:@"PKGPackageSettingsIdentifierKey"]==YES)
							tTitle=NSLocalizedStringFromTable(@"The identifier of the package can not be empty.",@"Build",@"");
						else if ([tTag isEqualToString:@"PKGPackageSettingsVersionKey"]==YES)
							tTitle=NSLocalizedStringFromTable(@"The version of the package can not be empty.",@"Build",@"");
					}
					else if (tStep==PKGBuildStepDistribution)
					{
						if ([tTag isEqualToString:@"PKGProjectSettingsNameKey"]==YES)
							tTitle=NSLocalizedStringFromTable(@"The name of the project can not be empty.",@"Build",@"");
					}
					else if (tStep==PKGBuildStepPackageCreate)
					{
						if ([tTag isEqualToString:@"PKGPackageSettingsNameKey"]==YES)
							tTitle=NSLocalizedStringFromTable(@"The name of the package can not be empty.",@"Build",@"");
					}
					
					if ([tTag isEqualToString:@"PKGPackageSettingsLocationTypeKey"]==YES)
						tTitle=NSLocalizedStringFromTable(@"The location of the package has not been fully defined.",@"Build",@"");
					
					if (tTitle==nil)
						tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"String can not be empty for tag '%@'",@"Build",@""),tTag];
					
					break;
					
				
					
				case PKGBuildErrorFileNotFound:
					
					tTitle=nil;
					
					if (tStep==PKGBuildStepPackageImport)
					{
						if ([tTag isEqualToString:@"PKGPackageSettingsLocationPathKey"]==YES)
							tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to find %@ at path '%@'",@"Build",@""),fileItemTypeName(PKGFileKindPackage),tFilePath];
					}
					
					if (tTitle==nil)
						tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to find %@ at path '%@'",@"Build",@""),fileItemTypeName(tFileKind),tFilePath];
					
					break;
					
				case PKGBuildErrorFileCanNotBeCreated:
					
					if ([tFilePath isEqualToString:@"Scratch_Location"]==NO)
						tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to create %@ at path '%@'",@"Build",@""),fileItemTypeName(tFileKind),tFilePath];
					else
						tTitle=NSLocalizedStringFromTable(@"Unable to create scratch location folder",@"Build",@"");
					
					switch(tErrorEvent.subcode)
					{
						case PKGBuildErrorNoMoreSpaceOnVolume:
							
							tTitle=[tTitle stringByAppendingString:NSLocalizedStringFromTable(@" because there's no space left on disk",@"Build",@"")];
							break;
							
						case PKGBuildErrorReadOnlyVolume:
							
							tTitle=[tTitle stringByAppendingString:NSLocalizedStringFromTable(@" because the disk is read only",@"Build",@"")];
							break;
							
						case PKGBuildErrorWriteNoPermission:
							
							// A COMPLETER (Improve the scratch location with the path from the preferences) 
							
							tTitle=[tTitle stringByAppendingFormat:NSLocalizedStringFromTable(@" because you don't have permission to create it inside the folder \'%@\'",@"Build",@""),([tFilePath isEqualToString:@"Scratch_Location"]==YES) ? @"/tmp/private/" : tFilePath.stringByDeletingLastPathComponent.lastPathComponent];
							break;
							
						default:
							break;
					}
					
					break;
					
				case PKGBuildErrorFileCanNotBeCopied:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to copy item at path '%@'",@"Build",@""),tFilePath];
					
					switch(tErrorEvent.subcode)
					{
						case PKGBuildErrorFileNotFound:
							tTitle=[tTitle stringByAppendingString:NSLocalizedStringFromTable(@" because the item could not be found",@"Build",@"")];
							break;
							
						case PKGBuildErrorNoMoreSpaceOnVolume:
							
							tTitle=[tTitle stringByAppendingString:NSLocalizedStringFromTable(@" because there's no space left on disk",@"Build",@"")];
							break;
							
						case PKGBuildErrorReadOnlyVolume:
							
							tTitle=[tTitle stringByAppendingString:NSLocalizedStringFromTable(@" because the disk is read only",@"Build",@"")];
							break;
							
						case PKGBuildErrorWriteNoPermission:
							
							tTitle=[tTitle stringByAppendingFormat:NSLocalizedStringFromTable(@" because you don't have permission to create it inside the folder \'%@\'",@"Build",@""),tFilePath.stringByDeletingLastPathComponent.lastPathComponent];
							break;
							
						default:
							break;
					}
					
					break;
					
				case PKGBuildErrorFileCanNotBeDeleted:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to delete %@ at path '%@'",@"Build",@""),fileItemTypeName(tFileKind),tFilePath];
					
					switch(tErrorEvent.subcode)
					{
						case PKGBuildErrorFileNotFound:
							
							tTitle=[tTitle stringByAppendingFormat:NSLocalizedStringFromTable(@" because the item could not be found",@"Build",@"")];
							break;
							
						case PKGBuildErrorReadOnlyVolume:
							
							tTitle=[tTitle stringByAppendingString:NSLocalizedStringFromTable(@" because the disk is read only",@"Build",@"")];
							break;
							
						case PKGBuildErrorWriteNoPermission:
							
							tTitle=[tTitle stringByAppendingString:NSLocalizedStringFromTable(@" because you don't have permission to access it",@"Build",@"")];
							break;
							
						default:
							break;
					}
					
					break;
				
					
					/* Requirements and Locators errors */
					
					
				case PKGBuildErrorRequirementMissingConverter:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Converter not found for requirement of type '%@'",@"Build",@""),tTag];
					
					break;
					
				case PKGBuildErrorRequirementConversionError:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"No code generated for requirement '%@'",@"Build",@""),tTag];
					
					switch(tErrorEvent.subcode)
					{
						case PKGBuildErrorConverterMissingParameter:
							
							tTitle=[tTitle stringByAppendingFormat:NSLocalizedStringFromTable(@" because the parameter %@ is missing",@"Build",@""),tErrorEvent.otherFilePath];
							
							break;
							
						case PKGBuildErrorConverterInvalidParameter:
							
							tTitle=[tTitle stringByAppendingFormat:NSLocalizedStringFromTable(@" because the parameter %@ is invalid",@"Build",@""),tErrorEvent.otherFilePath];
							
							break;
							
						case PKGBuildErrorOutOfMemory:
							
							tTitle=[tTitle stringByAppendingString:NSLocalizedStringFromTable(@" because available memory is too low",@"Build",@"")];
							
							break;
							
						default:
							break;
					}
					
					break;
					
				case PKGBuildErrorLocatorMissingConverter:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Converter not found for locator of type '%@'",@"Build",@""),tTag];
					
					break;
					
				case PKGBuildErrorLocatorConversionError:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"No code generated for locator '%@'",@"Build",@""),tTag];
					
					switch(tErrorEvent.subcode)
					{
						case PKGBuildErrorConverterMissingParameter:
							
							tTitle=[tTitle stringByAppendingFormat:NSLocalizedStringFromTable(@" because the parameter %@ is missing",@"Build",@""),tErrorEvent.otherFilePath];
							
							break;
							
						case PKGBuildErrorConverterInvalidParameter:
							
							tTitle=[tTitle stringByAppendingFormat:NSLocalizedStringFromTable(@" because the parameter %@ is invalid",@"Build",@""),tErrorEvent.otherFilePath];
							
							break;
							
						case PKGBuildErrorOutOfMemory:
							
							tTitle=[tTitle stringByAppendingString:NSLocalizedStringFromTable(@" because available memory is too low",@"Build",@"")];
							
							break;
							
						default:
							break;
					}
					
					break;
					

					/* Signing errors */
					
				case PKGBuildErrorSigningUnknown:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to sign the data (%d)",@"Build",@""),tErrorEvent.subcode];
					
					break;
					
				case PKGBuildErrorSigningTimeOut:
					
					tTitle=NSLocalizedStringFromTable(@"Signing operation timed out",@"Build",@"");
					
					break;
					
				case PKGBuildErrorSigningAuthorizationDenied:
					
					tTitle=NSLocalizedStringFromTable(@"Signing operation denied",@"Build",@"");
					
					break;
					
				case PKGBuildErrorSigningCertificateNotFound:
					
					tTitle=NSLocalizedStringFromTable(@"Unable to find signing certificate",@"Build",@"");
					
					break;
					
				case PKGBuildErrorSigningKeychainNotFound:
					
					tTitle=NSLocalizedStringFromTable(@"Unable to find keychain",@"Build",@"");
					
					break;
				
				case PKGBuildErrorSigningCertificatePrivateKeyNotFound:
					
					tTitle=NSLocalizedStringFromTable(@"Unable to find the private key for the Developer ID Installer certificate",@"Build",@"");
					
					break;
					
				default:
					
					// A COMPLETER
					
					break;
			}
		}
		
		if (tTitle!=nil)
		{
			PKGBuildEventItem * nBuildEventItem=[PKGBuildEventItem new];
		
			nBuildEventItem.type=PKGBuildEventItemErrorDescription;
			nBuildEventItem.state=PKGBuildEventItemStateFailure;
			nBuildEventItem.title=tTitle;
			
			PKGBuildEventTreeNode * tBuildEventTreeNode=[[PKGBuildEventTreeNode alloc] initWithRepresentedObject:nBuildEventItem children:nil];
			
			[_currentBuildTreeNode addChild:tBuildEventTreeNode];
		}
		
		PKGBuildEventTreeNode * tBuildEventParentTreeNode=_currentBuildTreeNode;
		
		while (tBuildEventParentTreeNode!=nil)
		{
			PKGBuildEventItem * tBuildEventItem=[tBuildEventParentTreeNode representedObject];
			tBuildEventItem.state=PKGBuildEventItemStateFailure;
			
			tBuildEventParentTreeNode=(PKGBuildEventTreeNode *) [tBuildEventParentTreeNode parent];
		}
		
		NSDateFormatter * tDateFormatter=[NSDateFormatter new];
		tDateFormatter.formatterBehavior=NSDateFormatterBehavior10_4;
		tDateFormatter.dateStyle=NSDateFormatterShortStyle;
		tDateFormatter.timeStyle=NSDateFormatterShortStyle;
		
		PKGBuildEventItem * nBuildEventItem=[PKGBuildEventItem new];
		
		nBuildEventItem.type=PKGBuildEventItemConclusion;
		nBuildEventItem.title=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Build Failed \t%@",@"Build",@"No comment"),[tDateFormatter stringForObjectValue:[NSDate date]]];
		nBuildEventItem.subTitle=NSLocalizedStringFromTable(@"1 error",@"Build",@"No comment");
		nBuildEventItem.state=PKGBuildEventItemStateFailure;
		
		PKGBuildEventTreeNode * nBuildEventTreeNode=[[PKGBuildEventTreeNode alloc] initWithRepresentedObject:nBuildEventItem children:nil];
		
		[_tree.rootNodes.array addObject:nBuildEventTreeNode];
		
		[_delegate buildAndCleanObserverDataSource:self shouldReloadDataAndExpandItem:([_currentBuildTreeNode isLeaf]==NO) ? _currentBuildTreeNode : nil];
	}
	else if (tState==PKGBuildStepStateWarning)
	{
		PKGBuildError tFailureReason=PKGBuildErrorUnknown;
		
		PKGBuildErrorEvent * tErrorEvent=[[PKGBuildErrorEvent alloc] initWithRepresentation:tRepresentation];
		NSString * tTitle=nil;
		
		if (tErrorEvent!=nil)
			tFailureReason=tErrorEvent.code;

		if (tFailureReason==PKGBuildErrorUnknown)
		{
		}
		else if (tFailureReason==PKGBuildErrorOutOfMemory)
		{
			tTitle=NSLocalizedStringFromTable(@"Not enough memory to perform operation",@"Build",@"No comment");
		}
		else
		{
			NSString * tTag=tErrorEvent.tag;
			
			NSString * tFilePath=tErrorEvent.filePath;
			PKGBuildErrorFileKind tFileKind=tErrorEvent.fileKind;
			
			switch(tFailureReason)
			{
				case PKGBuildErrorFileNotFound:	// Exists
					
					tTitle=nil;
					
					if (tStep==PKGBuildStepPackageImport)
					{
						if ([tTag isEqualToString:@"PKGPackageSettingsLocationPathKey"]==YES)
							tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to find %@ at path '%@'",@"Build",@""),fileItemTypeName(PKGFileKindPackage),tFilePath];
					}
					
					if (tTitle==nil)
						tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to find %@ at path '%@'",@"Build",@""),fileItemTypeName(tErrorEvent.fileKind),tFilePath];
					
					break;
					
				case PKGBuildErrorFileCanNotBeCopied:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to copy item at path '%@'",@"Build",@""),tFilePath];
					
					switch(tErrorEvent.subcode)
					{
						case PKGBuildErrorFileNotFound:
							
							tTitle=[tTitle stringByAppendingString:NSLocalizedStringFromTable(@" because the item could not be found",@"Build",@"")];
							break;
							
						default:
							break;
					}
					
					break;
					
				case PKGBuildErrorFileCanNotBeDeleted:
					
					tTitle=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to remove %@ at path '%@'",@"Build",@""),fileItemTypeName(tFileKind),tFilePath];
					
					switch(tErrorEvent.subcode)
					{
						case PKGBuildErrorReadOnlyVolume:
							
							tTitle=[tTitle stringByAppendingString:NSLocalizedStringFromTable(@" because the disk is read only",@"Build",@"")];
							break;
							
						case PKGBuildErrorWriteNoPermission:
							
							tTitle=[tTitle stringByAppendingString:NSLocalizedStringFromTable(@" because you don't have permission to access it",@"Build",@"")];
							break;
							
						default:
							break;
					}
					
				default:
					
					break;
			}
		}
		
		if (tTitle!=nil)
		{
			PKGBuildEventItem * nBuildEventItem=[PKGBuildEventItem new];
			
			nBuildEventItem.type=PKGBuildEventItemErrorDescription;
			nBuildEventItem.state=PKGBuildEventItemStateWarning;
			nBuildEventItem.title=tTitle;
			
			PKGBuildEventTreeNode * tBuildEventTreeNode=[[PKGBuildEventTreeNode alloc] initWithRepresentedObject:nBuildEventItem children:nil];
			
			[_currentBuildTreeNode addChild:tBuildEventTreeNode];
		}
		
		PKGBuildEventTreeNode * tBuildEventParentTreeNode=_currentBuildTreeNode;
		
		while (tBuildEventParentTreeNode!=nil)
		{
			PKGBuildEventItem * tBuildEventItem=[tBuildEventParentTreeNode representedObject];
			tBuildEventItem.state=PKGBuildEventItemStateWarning;
			
			tBuildEventParentTreeNode=(PKGBuildEventTreeNode *) [tBuildEventParentTreeNode parent];
		}
		
		[_delegate buildAndCleanObserverDataSource:self shouldReloadDataAndExpandItem:([_currentBuildTreeNode isLeaf]==NO) ? _currentBuildTreeNode : nil];
	}
	else if (tState==PKGBuildStepStateSuccess)
	{
		switch (tStep)
		{
			case PKGBuildStepProject:
			{
				PKGBuildEventItem * tBuildEventItem=[_currentBuildTreeNode representedObject];
				
				tBuildEventItem.state=PKGBuildEventItemStateSuccess;
				
				// Add Conclusion item
				
				NSDateFormatter * tDateFormatter=[NSDateFormatter new];
				tDateFormatter.formatterBehavior=NSDateFormatterBehavior10_4;
				tDateFormatter.dateStyle=NSDateFormatterShortStyle;
				tDateFormatter.timeStyle=NSDateFormatterShortStyle;
				
				tBuildEventItem=[PKGBuildEventItem new];
				
				tBuildEventItem.type=PKGBuildEventItemConclusion;
				tBuildEventItem.title=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Build Succeeded \t%@",@"Build",@"No comment"),[tDateFormatter stringForObjectValue:[NSDate date]]];
				tBuildEventItem.subTitle=NSLocalizedStringFromTable(@"No issues",@"Build",@"No comment");
				tBuildEventItem.state=PKGBuildEventItemStateSuccess;
				
				PKGBuildEventTreeNode * tBuildEventTreeNode=[[PKGBuildEventTreeNode alloc] initWithRepresentedObject:tBuildEventItem children:nil];
				
				[_tree.rootNodes.array addObject:tBuildEventTreeNode];
				
				[_delegate buildAndCleanObserverDataSource:self shouldReloadDataAndCollapseItem:([_currentBuildTreeNode isLeaf]==NO) ? _currentBuildTreeNode : nil];
				
				break;
			}
			case PKGBuildStepDistribution:
			case PKGBuildStepPackage:
				
				return;
				
			case PKGBuildStepPackageCreate:
			
				if ([_project isKindOfClass:PKGDistributionProject.class]==NO)
					return;
				
			default:
			{
				PKGBuildEventItem * tBuildEventItem=[_currentBuildTreeNode representedObject];
				
				if (tBuildEventItem.state!=PKGBuildEventItemStateWarning)
					tBuildEventItem.state=PKGBuildEventItemStateSuccess;
				
				[_delegate buildAndCleanObserverDataSource:self shouldReloadDataAndCollapseItem:([_currentBuildTreeNode isLeaf]==NO) ? _currentBuildTreeNode : nil];
				
				_currentBuildTreeNode=(PKGBuildEventTreeNode *)[_currentBuildTreeNode parent];
			}
		}
	}
}

- (void)processDispatchErrorNotification:(NSNotification *)inNotification
{
	PKGBuildEventItem * nBuildEventItem=[PKGBuildEventItem new];
	
	nBuildEventItem.type=PKGBuildEventItemErrorDescription;
	nBuildEventItem.state=PKGBuildEventItemStateFailure;
	
	NSDictionary * tUserInfo=inNotification.userInfo;
	
	if (tUserInfo==nil)
	{
		nBuildEventItem.title=NSLocalizedStringFromTable(@"Unknown Error",@"Build",@"No comment");
	}
	else
	{
		NSNumber * tNumber=tUserInfo[PKGPackagesDispatcherErrorTypeKey];
		
		if ([tNumber isKindOfClass:NSNumber.class]==NO)
		{
			nBuildEventItem.title=NSLocalizedStringFromTable(@"Unknown Error",@"Build",@"No comment");
		}
		else
		{
			PKGPackagesDispatcherErrorType tErrroType=[tNumber unsignedIntegerValue];
			
			switch(tErrroType)
			{
				case PKGPackagesDispatcherErrorPackageBuilderNotFound:
					
					nBuildEventItem.title=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to find tool '%@'",@"Build",@"No comment"),@"packages_builder"];
					
					break;
			}
		}
	}
	
	PKGBuildEventTreeNode * tBuildEventTreeNode=[[PKGBuildEventTreeNode alloc] initWithRepresentedObject:nBuildEventItem children:nil];
	
	[_currentBuildTreeNode addChild:tBuildEventTreeNode];
	
	PKGBuildEventTreeNode * tBuildEventParentTreeNode=_currentBuildTreeNode;
	
	while (tBuildEventParentTreeNode!=nil)
	{
		PKGBuildEventItem * tBuildEventItem=[tBuildEventParentTreeNode representedObject];
		tBuildEventItem.state=PKGBuildEventItemStateFailure;
		
		tBuildEventParentTreeNode=(PKGBuildEventTreeNode *) [tBuildEventParentTreeNode parent];
	}
	
	NSDateFormatter * tDateFormatter=[NSDateFormatter new];
	tDateFormatter.formatterBehavior=NSDateFormatterBehavior10_4;
	tDateFormatter.dateStyle=NSDateFormatterShortStyle;
	tDateFormatter.timeStyle=NSDateFormatterShortStyle;
	
	nBuildEventItem=[PKGBuildEventItem new];
	
	nBuildEventItem.type=PKGBuildEventItemConclusion;
	nBuildEventItem.title=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Build Failed \t%@",@"Build",@"No comment"),[tDateFormatter stringForObjectValue:[NSDate date]]];
	nBuildEventItem.subTitle=NSLocalizedStringFromTable(@"1 error",@"Build",@"No comment");
	nBuildEventItem.state=PKGBuildEventItemStateFailure;
	
	PKGBuildEventTreeNode * nBuildEventTreeNode=[[PKGBuildEventTreeNode alloc] initWithRepresentedObject:nBuildEventItem children:nil];
	
	[_tree.rootNodes.array addObject:nBuildEventTreeNode];
	
	[_delegate buildAndCleanObserverDataSource:self shouldReloadDataAndExpandItem:([_currentBuildTreeNode isLeaf]==NO) ? _currentBuildTreeNode : nil];
}

@end

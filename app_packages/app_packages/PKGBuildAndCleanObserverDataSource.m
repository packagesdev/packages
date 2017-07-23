
#import "PKGBuildAndCleanObserverDataSource.h"

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
				
				_currentBuildTreeNode=_tree.rootNodes.firstObject;
				
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
	
	[_delegate buildAndCleanObserverDataSource:self shouldReloadDataAndExpandItem:_tree.rootNodes.firstObject];
}

- (NSString *)statusDescription
{
	// A COMPLETER
	
	return nil;
}

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)inOutlineView numberOfChildrenOfItem:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return _tree.rootNodes.count;
	
	return inTreeNode.numberOfChildren;
}

- (id)outlineView:(NSOutlineView *)inOutlineView child:(NSInteger)inIndex ofItem:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return _tree.rootNodes[inIndex];
	
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
					// A COMPLETER
				}
				
				tType=PKGBuildEventItemDistributionPackage;
				
				NSString * tString=nil;
				NSString * tPackageName=tInfoEvent.packageName;
				
				if (tStep==PKGBuildStepPackageImport)
				{
					tString=@"Import package";
					
					PKGFilePath * tImportpath=tPackageComponent.importPath;
					
					if (tImportpath==nil)
					{
						// A COMPLETER
					}
					
					tSubTitle=tImportpath.string;
				}
				else if (tStep==PKGBuildStepPackageReference)
				{
					tString=@"Create reference to package";
					
					PKGPackageSettings * tPackageSettings=tPackageComponent.packageSettings;
					
					PKGPackageLocationType tLocationType=tPackageSettings.locationType;
						
					NSString * tLocationURL=tPackageSettings.locationURL;
					
					if (tLocationURL.length>0)
					{
						NSString * tURLPrefix=nil;
						
						if (tLocationType==PKGPackageLocationHTTPURL)
						{
							tURLPrefix=@"http://";
						}
						else if (tLocationType==PKGPackageLocationRemovableMedia)
						{
							tURLPrefix=@"x-disc://";
						}
						
						if (tURLPrefix!=nil)
						{
							if ([tLocationURL hasPrefix:tURLPrefix]==YES)
								tLocationURL=[tLocationURL substringFromIndex:tURLPrefix.length];
							
							if ([tLocationURL hasPrefix:@"/"]==YES)
								tLocationURL=[tLocationURL substringFromIndex:1];
							
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
				
				[_tree.rootNodes addObject:tBuildEventTreeNode];
						
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

@end

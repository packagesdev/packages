
#import "PKGPresentationInstallationTypeSingleSelectionViewController.h"

#import "PKGChoiceTreeNode+UI.h"

#import "PKGInstallerApp.h"

#import "PKGDistributionProject.h"

#import "PKGPresentationInstallationTypeChoiceRequirementsViewController.h"

@interface PKGPresentationInstallationTypeSingleSelectionViewController ()
{
	IBOutlet NSImageView * _choiceIconView;
	
	IBOutlet NSTextField * _choicePackageNameLabel;
	
	IBOutlet NSTextField * _choiceTypeLabel;
	
	IBOutlet NSTabView * _tabView;
	
	NSTabViewItem * _requirementsTabViewItem;
	
	PKGPresentationInstallationTypeChoiceRequirementsViewController * _requirementsViewController;
}

@end

@implementation PKGPresentationInstallationTypeSingleSelectionViewController

- (void)dealloc
{
	_requirementsTabViewItem=nil;
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_requirementsTabViewItem=[_tabView tabViewItemAtIndex:[_tabView indexOfTabViewItemWithIdentifier:@"Requirements"]];
}

#pragma mark -

- (void)setChoiceTreeNode:(PKGChoiceTreeNode *)inChoiceTreeNode
{
	_choiceTreeNode=inChoiceTreeNode;
	
	[self refreshUI];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	if (_requirementsViewController!=nil)
		[_requirementsViewController WB_viewWillAppear];
	
	[self refreshUI];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	if (_requirementsViewController!=nil)
		[_requirementsViewController WB_viewDidAppear];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	if (_requirementsViewController!=nil)
		[_requirementsViewController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	if (_requirementsViewController!=nil)
		[_requirementsViewController WB_viewDidDisappear];
}

- (void)refreshUI
{
	if (_choiceIconView==nil)
		return;
	
	if (self.choiceTreeNode==nil)
		return;
	
	PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
	PKGChoiceItemType tChoiceType=tChoiceItem.type;
	BOOL tIsMergedPackageChoice=self.choiceTreeNode.isMergedPackagesChoice;
	
	// Icon, Name, Type
	
	switch(tChoiceType)
	{
		case PKGChoiceItemTypePackage:
		{
			_choiceIconView.image=[[PKGInstallerApp installerApp] iconForPackageType:PKGInstallerAppRawPackage];
			
			NSString * tPackageUUID=((PKGChoicePackageItem *)tChoiceItem).packageUUID;
			
			if (tPackageUUID!=nil)
			{
				PKGPackageComponent * tPackageComponent=[((PKGDistributionProject *)self.documentProject) packageComponentWithUUID:tPackageUUID];
				
				_choicePackageNameLabel.stringValue=(tPackageComponent==nil) ? @"" : tPackageComponent.packageSettings.name;
			}
			
			_choiceTypeLabel.stringValue=NSLocalizedString(@"Package", @"");
			
			break;
		}
		case PKGChoiceItemTypeGroup:
		{
			NSUInteger tCount=[self.choiceTreeNode numberOfChildren];
			
			if (tIsMergedPackageChoice==YES)
			{
				_choiceIconView.image=[NSImage imageNamed:@"PackagesCombination"];
				
				_choicePackageNameLabel.stringValue=NSLocalizedString(@"Combination of Packages",@"");
				
				if (tCount==1)
				_choiceTypeLabel.stringValue=NSLocalizedString(@"1 package",@"");
				else
					_choiceTypeLabel.stringValue=[NSString stringWithFormat:NSLocalizedString(@"%lu packages",@""),(unsigned long)tCount];
			}
			else
			{
				
				_choiceIconView.image=[NSImage imageNamed:@"checkboxgroupUbuntu"];
				
				_choicePackageNameLabel.stringValue=NSLocalizedString(@"Group of Choices",@"");
				
				switch(tCount)
				{
					case 0:
						
						_choiceTypeLabel.stringValue=NSLocalizedString(@"No sub-choices", @"");
						break;
						
					case 1:
						
						_choiceTypeLabel.stringValue=NSLocalizedString(@"1 sub-choice", @"");
						break;
						
					default:
						
						_choiceTypeLabel.stringValue=[NSString stringWithFormat:NSLocalizedString(@"%lu sub-choices",@""),(unsigned long)tCount];
						break;
				}
			}
			
			break;
		}
		default:
			
			// Oh Oh
			
			return;
	}
	
	// Requirements
	
	if (tChoiceType==PKGChoiceItemTypeGroup && tIsMergedPackageChoice==NO)
	{
		if (_tabView.numberOfTabViewItems==2)
			[_tabView removeTabViewItem:_requirementsTabViewItem];
	}
	else
	{
		if (_tabView.numberOfTabViewItems==1)
			[_tabView addTabViewItem:_requirementsTabViewItem];
		
		if (_requirementsViewController==nil)
		{
			_requirementsViewController=[[PKGPresentationInstallationTypeChoiceRequirementsViewController alloc] initWithDocument:self.document];
		
			_requirementsViewController.view.frame=_requirementsTabViewItem.view.bounds;
			
			
			[_requirementsViewController WB_viewWillAppear];
			
			[_requirementsTabViewItem.view addSubview:_requirementsViewController.view];
			
			[_requirementsViewController WB_viewDidAppear];
		}
	}
}

@end

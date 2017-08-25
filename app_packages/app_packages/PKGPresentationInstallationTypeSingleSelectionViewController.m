/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationInstallationTypeSingleSelectionViewController.h"

#import "PKGChoiceTreeNode+UI.h"

#import "PKGInstallerApp.h"

#import "PKGDistributionProject.h"

#import "PKGPresentationInstallationTypeChoiceAttributesViewController.h"

#import "PKGPresentationInstallationTypeChoiceRequirementsViewController.h"

@interface PKGPresentationInstallationTypeSingleSelectionViewController ()
{
	IBOutlet NSImageView * _choiceIconView;
	
	IBOutlet NSTextField * _choicePackageNameLabel;
	
	IBOutlet NSTextField * _choiceTypeLabel;
	
	IBOutlet NSTabView * _tabView;
	
	NSTabViewItem * _requirementsTabViewItem;
	
	PKGPresentationInstallationTypeChoiceAttributesViewController * _attributesViewController;
	
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
	
	NSTabViewItem * tAttributesTabViewItem=[_tabView tabViewItemAtIndex:[_tabView indexOfTabViewItemWithIdentifier:@"Attributes"]];
	
	_attributesViewController=[[PKGPresentationInstallationTypeChoiceAttributesViewController alloc] initWithDocument:self.document];
	
	_attributesViewController.choiceTreeNode=self.selectedChoiceTreeNode;
	_attributesViewController.choicesForest=self.choicesForest;
	
	_attributesViewController.view.frame=[tAttributesTabViewItem.view bounds];
	
	[tAttributesTabViewItem.view addSubview:_attributesViewController.view];
	
	_requirementsTabViewItem=[_tabView tabViewItemAtIndex:[_tabView indexOfTabViewItemWithIdentifier:@"Requirements"]];
}

#pragma mark -

- (void)setSelectedChoiceTreeNode:(PKGChoiceTreeNode *)inSelectedChoiceTreeNode
{
	_selectedChoiceTreeNode=inSelectedChoiceTreeNode;
	
	_attributesViewController.choiceTreeNode=_selectedChoiceTreeNode;
	
	[self refreshUI];
}

- (void)setChoicesForest:(PKGChoicesForest *)inChoicesForest
{
	_choicesForest=inChoicesForest;
	
	_attributesViewController.choicesForest=_choicesForest;
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	if (_attributesViewController!=nil)
		[_attributesViewController WB_viewWillAppear];
	
	if (_requirementsViewController!=nil)
		[_requirementsViewController WB_viewWillAppear];
	
	[self refreshUI];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	if (_attributesViewController!=nil)
		[_attributesViewController WB_viewDidAppear];
	
	if (_requirementsViewController!=nil)
		[_requirementsViewController WB_viewDidAppear];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	if (_attributesViewController!=nil)
		[_attributesViewController WB_viewWillDisappear];
	
	if (_requirementsViewController!=nil)
		[_requirementsViewController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	if (_attributesViewController!=nil)
		[_attributesViewController WB_viewDidDisappear];
	
	if (_requirementsViewController!=nil)
		[_requirementsViewController WB_viewDidDisappear];
}

- (void)refreshUI
{
	if (_choiceIconView==nil)
		return;
	
	if (self.selectedChoiceTreeNode==nil)
		return;
	
	PKGChoiceItem * tChoiceItem=[self.selectedChoiceTreeNode representedObject];
	PKGChoiceItemType tChoiceType=tChoiceItem.type;
	BOOL tIsMergedPackageChoice=self.selectedChoiceTreeNode.isMergedPackagesChoice;
	
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
			
			_choiceTypeLabel.stringValue=NSLocalizedStringFromTable(@"Package", @"Presentation",@"");
			
			break;
		}
		case PKGChoiceItemTypeGroup:
		{
			NSUInteger tCount=[self.selectedChoiceTreeNode numberOfChildren];
			
			if (tIsMergedPackageChoice==YES)
			{
				_choiceIconView.image=[NSImage imageNamed:@"PackagesCombination"];
				
				_choicePackageNameLabel.stringValue=NSLocalizedStringFromTable(@"Combination of Packages", @"Presentation",@"");
				
				if (tCount==1)
				_choiceTypeLabel.stringValue=NSLocalizedStringFromTable(@"1 package", @"Presentation",@"");
				else
					_choiceTypeLabel.stringValue=[NSString stringWithFormat:NSLocalizedStringFromTable(@"%lu packages", @"Presentation",@""),(unsigned long)tCount];
			}
			else
			{
				_choiceIconView.image=[NSImage imageNamed:@"checkboxgroupUbuntu"];
				
				_choicePackageNameLabel.stringValue=NSLocalizedStringFromTable(@"Group of Choices", @"Presentation",@"");
				
				switch(tCount)
				{
					case 0:
						
						_choiceTypeLabel.stringValue=NSLocalizedStringFromTable(@"No sub-choices",  @"Presentation",@"");
						break;
						
					case 1:
						
						_choiceTypeLabel.stringValue=NSLocalizedStringFromTable(@"1 sub-choice",  @"Presentation",@"");
						break;
						
					default:
						
						_choiceTypeLabel.stringValue=[NSString stringWithFormat:NSLocalizedStringFromTable(@"%lu sub-choices", @"Presentation",@""),(unsigned long)tCount];
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
		
			_requirementsViewController.view.frame=[_requirementsTabViewItem.view bounds];
			
			
			[_requirementsViewController WB_viewWillAppear];
			
			[_requirementsTabViewItem.view addSubview:_requirementsViewController.view];
			
			[_requirementsViewController WB_viewDidAppear];
		}
		
		PKGPresentationInstallationTypeChoiceRequirementsDataSource * tDataSource=[PKGPresentationInstallationTypeChoiceRequirementsDataSource new];
		
		tDataSource.choiceItem=tChoiceItem;
		
		_requirementsViewController.dataSource=tDataSource;
	}
}

@end

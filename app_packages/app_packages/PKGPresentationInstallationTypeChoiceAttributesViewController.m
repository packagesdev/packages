/*
 Copyright (c) 2017-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationInstallationTypeChoiceAttributesViewController.h"

#import "PKGPresentationLocalizationsDataSource.h"

#import "PKGPresentationLocalizedStringsViewController.h"

#import "PKGChoiceItemOptionsDependencies+UI.h"
#import "PKGChoiceTreeNode+UI.h"
#import "PKGPresentationInstallationTypeStepSettings+UI.h"

#import "PKGChoicesForest+DependenciesEdition.h"

#import "NSPopUpButton+OptimizedSize.h"



typedef NS_ENUM(NSInteger, PKGVisibilityTag)
{
	PKGVisibleTag=0,
	PKGInvisibleTag=1
};

@interface PKGPresentationInstallationTypeChoiceAttributesViewController () <PKGPresentationLocalizationsDataSourceDelegate>
{
	IBOutlet NSView * _titlesSectionView;
	
	IBOutlet NSView * _descriptionsSectionView;
	
	IBOutlet NSView * _extendedAttributesSectionView_;
	
	IBOutlet NSPopUpButton * _choiceVisibilityPopUpButton;
	
	IBOutlet NSPopUpButton * _choicePackageStatePopUpButton;
	
	IBOutlet NSButton * _choicePackageStateEditButton;
	
	
	PKGPresentationLocalizedStringsViewController * _localizedTitlesViewController;
	
	PKGPresentationLocalizedStringsViewController * _localizedDescriptionsViewController;
}

- (IBAction)switchPackageVisibility:(id)sender;

- (IBAction)switchPackageState:(id)sender;

- (IBAction)editChoiceState:(id)sender;

// Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification;

@end

@implementation PKGPresentationInstallationTypeChoiceAttributesViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	_localizedTitlesViewController=[[PKGPresentationLocalizedStringsViewController alloc] initWithDocument:self.document];
	_localizedTitlesViewController.label=NSLocalizedStringFromTable(@"Title", @"Presentation",@"");
	_localizedTitlesViewController.informationLabel=NSLocalizedStringFromTable(@"Click + to add a title localization.", @"Presentation",@"");
	
	if (self.choiceTreeNode!=nil)
	{
		PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
		
		PKGPresentationLocalizationsDataSource * tDataSource=[PKGPresentationLocalizationsDataSource new];
		
		tDataSource.localizations=tChoiceItem.localizedTitles;
		tDataSource.delegate=self;
		
		_localizedTitlesViewController.dataSource=tDataSource;
	}
	
	_localizedTitlesViewController.view.frame=_titlesSectionView.bounds;
	
	[_titlesSectionView addSubview:_localizedTitlesViewController.view];
	
	_localizedDescriptionsViewController=[[PKGPresentationLocalizedStringsViewController alloc] initWithDocument:self.document];
	_localizedDescriptionsViewController.label=NSLocalizedStringFromTable(@"Description", @"Presentation",@"");
	_localizedDescriptionsViewController.informationLabel=NSLocalizedStringFromTable(@"Click + to add a description localization.\nUse alt+return for line breaks.", @"Presentation",@"");
	
	if (self.choiceTreeNode!=nil)
	{
		PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
		
		PKGPresentationLocalizationsDataSource * tDataSource=[PKGPresentationLocalizationsDataSource new];
		
		tDataSource.localizations=tChoiceItem.localizedDescriptions;
		tDataSource.delegate=self;
		
		_localizedDescriptionsViewController.dataSource=tDataSource;
	}
	
	_localizedDescriptionsViewController.view.frame=_descriptionsSectionView.bounds;
	_localizedDescriptionsViewController.tableView.rowHeight=60.0;
	
	
	[_descriptionsSectionView addSubview:_localizedDescriptionsViewController.view];
}

#pragma mark -

- (void)setChoiceTreeNode:(PKGChoiceTreeNode *)inChoiceTreeNode
{
	_choiceTreeNode=inChoiceTreeNode;
	
	if (_localizedTitlesViewController!=nil)
	{
		PKGChoiceItem * tChoiceItem=[_choiceTreeNode representedObject];
		
		PKGPresentationLocalizationsDataSource * tDataSource=[PKGPresentationLocalizationsDataSource new];
		
		tDataSource.localizations=tChoiceItem.localizedTitles;
		tDataSource.delegate=self;
		
		_localizedTitlesViewController.dataSource=tDataSource;
	}
	
	if (_localizedDescriptionsViewController!=nil)
	{
		PKGChoiceItem * tChoiceItem=[_choiceTreeNode representedObject];
		
		PKGPresentationLocalizationsDataSource * tDataSource=[PKGPresentationLocalizationsDataSource new];
		
		tDataSource.localizations=tChoiceItem.localizedDescriptions;
		tDataSource.delegate=self;
		
		_localizedDescriptionsViewController.dataSource=tDataSource;
	}
	
	[self refreshUI];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[_localizedTitlesViewController WB_viewWillAppear];
	
	[_localizedDescriptionsViewController WB_viewWillAppear];
	
	[self viewFrameDidChange:[NSNotification notificationWithName:NSViewFrameDidChangeNotification object:self.view]];
	
	[self refreshUI];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[_localizedTitlesViewController WB_viewDidAppear];
	
	[_localizedDescriptionsViewController WB_viewDidAppear];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self.view];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[_localizedTitlesViewController WB_viewWillDisappear];
	
	[_localizedDescriptionsViewController WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self.view];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
	
	[_localizedTitlesViewController WB_viewDidDisappear];
	
	[_localizedDescriptionsViewController WB_viewDidDisappear];
}

- (void)refreshUI
{
	if (_choiceVisibilityPopUpButton==nil)
		return;
	
	PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
	PKGChoiceItemOptions * tOptions=tChoiceItem.options;
	
	// Visibility
	
	[_choiceVisibilityPopUpButton selectItemWithTag:(tOptions.hidden==YES) ? PKGInvisibleTag : PKGVisibleTag];
	
	// State
	
	[_choicePackageStatePopUpButton removeAllItems];
	
	NSMenu * tMenu=[[NSMenu alloc] init];
	
	if (self.choiceTreeNode.isGenuineGroupChoice==YES)
	{
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Always Enabled",@"Presentation",@"") action:nil keyEquivalent:@""];
		tMenuItem.tag=PKGEnabledChoiceGroupState;
		
		[tMenu addItem:tMenuItem];
		
		tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Always Disabled",@"Presentation",@"") action:nil keyEquivalent:@""];
		[tMenuItem setTag:PKGDisabledChoiceGroupState];
		
		[tMenu addItem:tMenuItem];
		
		tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Dependent on Other Choices",@"Presentation",@"") action:nil keyEquivalent:@""];
		[tMenuItem setTag:PKGDependentChoiceGroupState];
				
		[tMenu addItem:tMenuItem];
	}
	else
	{
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Required",@"Presentation",@"") action:nil keyEquivalent:@""];
		tMenuItem.tag=PKGRequiredChoiceState;
		
		[tMenu addItem:tMenuItem];
		
		tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Selected",@"Presentation",@"") action:nil keyEquivalent:@""];
		[tMenuItem setTag:PKGSelectedChoiceState];
		
		[tMenu addItem:tMenuItem];
		
		tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Unselected",@"Presentation",@"") action:nil keyEquivalent:@""];
		[tMenuItem setTag:PKGUnselectedChoiceState];
		
		[tMenu addItem:tMenuItem];
		
		tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Dependent on Other Choices",@"Presentation",@"") action:nil keyEquivalent:@""];
		[tMenuItem setTag:PKGDependentChoiceState];
		
		[tMenu addItem:tMenuItem];
	}
	
	_choicePackageStatePopUpButton.menu=tMenu;
	
	/*NSRect tFrame=_choicePackageStatePopUpButton.frame;
	
	tFrame.size.width=[_choicePackageStatePopUpButton optimizedSize].width;
	
	_choicePackageStatePopUpButton.frame=tFrame;*/
	
	[_choicePackageStatePopUpButton selectItemWithTag:tOptions.state];
	
	if (self.choiceTreeNode.isGenuineGroupChoice==YES)
		_choicePackageStateEditButton.hidden=(tOptions.state!=PKGDependentChoiceGroupState);
	else
		_choicePackageStateEditButton.hidden=(tOptions.state!=PKGDependentChoiceState);
}

#pragma mark -

- (IBAction)switchPackageVisibility:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
	PKGChoiceItemOptions * tOptions=tChoiceItem.options;
	
	if (tOptions.hidden==(tTag==PKGInvisibleTag))
		return;
	
	tOptions.hidden=(tTag==PKGInvisibleTag);
	
	if (tOptions.state==PKGUnselectedChoiceState)
	{
		tOptions.state=PKGSelectedChoiceState;
		[_choicePackageStatePopUpButton selectItemWithTag:tOptions.state];
	}
	
	[self noteDocumentHasChanged];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationInstallationTypeStepSettingsDidChangeNotification object:self.document userInfo:@{}];	// A COMPLETER
}

- (IBAction)switchPackageState:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
	PKGChoiceItemOptions * tOptions=tChoiceItem.options;
	
	if (tTag==tOptions.state)
		return;
	
	tOptions.state=tTag;
	
	if (tTag==PKGDependentChoiceState ||
		tTag==PKGDependentChoiceGroupState)
	{
		if (tTag==PKGDependentChoiceGroupState)
		{
			tOptions.stateDependencies=[PKGChoiceItemOptionsDependencies new];
			// A COMPLETER
		}
		else
		{
			tOptions.stateDependencies=[PKGChoiceItemOptionsDependencies new];
			tOptions.stateDependencies.enabledStateDependencyType=PKGEnabledStateDependencyTypeAlways;
		}
		
		_choicePackageStateEditButton.hidden=NO;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[[NSNotificationCenter defaultCenter] postNotificationName:PKGChoiceItemOptionsDependenciesEditionWillBeginNotification object:self.document userInfo:@{PKGChoiceDependencyTreeNodeKey:self.choiceTreeNode,
																																									PKGChoiceDependencyForestKey:self.choicesForest}];
		});
	}
	else
	{
		tOptions.stateDependencies=nil;
		_choicePackageStateEditButton.hidden=YES;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationInstallationTypeStepSettingsDidChangeNotification object:self.document userInfo:@{}];	// A COMPLETER
	
	[self noteDocumentHasChanged];
}

- (IBAction)editChoiceState:(id)sender
{
	dispatch_async(dispatch_get_main_queue(), ^{
		
		[[NSNotificationCenter defaultCenter] postNotificationName:PKGChoiceItemOptionsDependenciesEditionWillBeginNotification object:self.document userInfo:@{PKGChoiceDependencyTreeNodeKey:self.choiceTreeNode,
																																								PKGChoiceDependencyForestKey:self.choicesForest}];
	});
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(switchPackageState:))
	{
		switch(inMenuItem.tag)
		{
			case PKGUnselectedChoiceState:
			{
				PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
				
				return (tChoiceItem.options.isHidden==NO);
			}
				
			case PKGDependentChoiceState:
			{
				NSMutableDictionary * tMutableDictionary=[self.choicesForest availableDependenciesDictionaryForSelectedStateOfLeafNode:self.choiceTreeNode];
				
				return (tMutableDictionary.count>0);
			}
				
			case PKGDependentChoiceGroupState:
			{
				NSMutableDictionary * tMutableDictionary=[self.choicesForest availableDependenciesDictionaryForEnabledStateOfGroupNode:self.choiceTreeNode];
				
				return (tMutableDictionary.count>0);
			}
		}
	}
	
	return YES;
}

#pragma mark - PKGPresentationLocalizationsDataSourceDelegate

- (id)defaultValueForLocalizationsDataSource:(PKGPresentationLocalizationsDataSource *)inDataSource
{
	return @"";
}

- (void)localizationsDataSource:(PKGPresentationLocalizationsDataSource *)inDataSource localizationsDataDidChange:(BOOL)inNumberOfLocalizationsDidChange
{
	[self noteDocumentHasChanged];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationInstallationTypeStepSettingsDidChangeNotification object:self.document userInfo:@{}];	// A COMPLETER
	
	if (inNumberOfLocalizationsDidChange==YES)
		[self viewFrameDidChange:[NSNotification notificationWithName:NSViewFrameDidChangeNotification object:self.view]];
}

#pragma mark - Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification
{
	NSRect tTitleSectionRect=_titlesSectionView.frame;
	NSRect tDescriptionSectionRect=_descriptionsSectionView.frame;
	NSRect tExtendedAttributesSectionRect=_extendedAttributesSectionView_.frame;
	
	tExtendedAttributesSectionRect.origin.y=-1.0;
	
	CGFloat tAvailableHeight=NSHeight(self.view.frame)-NSMaxY(tExtendedAttributesSectionRect);
	
	PKGChoiceItem * tChoiceItem=[self.choiceTreeNode representedObject];
	

	NSUInteger tLocalizedTitlesCount=tChoiceItem.localizedTitles.count;
	
	if (tLocalizedTitlesCount<2)
		tLocalizedTitlesCount=2;
	
	CGFloat tTitleRowHeight=_localizedTitlesViewController.tableView.rowHeight;
	NSSize tTitleSize=_localizedTitlesViewController.tableView.intercellSpacing;
	
	CGFloat tIdealHeightTitleSection=NSHeight(tTitleSectionRect)-NSHeight(_localizedTitlesViewController.tableView.enclosingScrollView.frame)+tTitleRowHeight*tLocalizedTitlesCount+(tLocalizedTitlesCount-1.0)*tTitleSize.height+10.0;
	
	
	NSUInteger tLocalizedDescriptionsCount=tChoiceItem.localizedDescriptions.count;
	
	if (tLocalizedDescriptionsCount<2)
		tLocalizedDescriptionsCount=2;
	
	CGFloat tDescriptionRowHeight=_localizedDescriptionsViewController.tableView.rowHeight;
	NSSize tDescriptionSize=_localizedDescriptionsViewController.tableView.intercellSpacing;
	
	CGFloat tIdealHeightDescriptionSection=NSHeight(tDescriptionSectionRect)-NSHeight(_localizedDescriptionsViewController.tableView.enclosingScrollView.frame)+tDescriptionRowHeight*tLocalizedDescriptionsCount+(tLocalizedDescriptionsCount-1.0)*tDescriptionSize.height+10.0;
	
	
	CGFloat tRatio=(tDescriptionRowHeight+tDescriptionSize.height)/(tDescriptionRowHeight+tDescriptionSize.height+tTitleRowHeight+tTitleSize.height);
	
	
	if ((tIdealHeightTitleSection+tIdealHeightDescriptionSection)>tAvailableHeight)
	{
		CGFloat tMissingHeight=tIdealHeightTitleSection+tIdealHeightDescriptionSection-tAvailableHeight;
		
		if (tLocalizedTitlesCount>2 && tLocalizedDescriptionsCount>2)
		{
			tIdealHeightDescriptionSection=tIdealHeightDescriptionSection-floor(tRatio*tMissingHeight);
			
			tIdealHeightTitleSection=tAvailableHeight-tIdealHeightDescriptionSection;
		}
		else
		{
			if (tLocalizedDescriptionsCount>2)
			{
				tIdealHeightDescriptionSection=tIdealHeightDescriptionSection-tMissingHeight;
			}
			else if (tIdealHeightTitleSection>2)
			{
				tIdealHeightTitleSection=tIdealHeightTitleSection-tMissingHeight;
			}
		}
	}
	
	CGFloat tExtraHeight=tAvailableHeight-(tIdealHeightTitleSection+tIdealHeightDescriptionSection);
	
	if (tExtraHeight>0)
		tDescriptionSectionRect.size.height=tAvailableHeight-tIdealHeightTitleSection;
	else
		tDescriptionSectionRect.size.height=tIdealHeightDescriptionSection;
	
	
	
	_extendedAttributesSectionView_.frame=tExtendedAttributesSectionRect;
	
	tDescriptionSectionRect.origin.y=NSMaxY(tExtendedAttributesSectionRect);
	
	_descriptionsSectionView.frame=tDescriptionSectionRect;
	
	
	
	tTitleSectionRect.origin.y=NSMaxY(tDescriptionSectionRect);
	tTitleSectionRect.size.height=tAvailableHeight-NSHeight(tDescriptionSectionRect);
	
	_titlesSectionView.frame=tTitleSectionRect;
	
	[self.view setNeedsDisplay:YES];
}

@end

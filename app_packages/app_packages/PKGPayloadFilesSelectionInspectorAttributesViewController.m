/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadFilesSelectionInspectorAttributesViewController.h"

#import "PKGCheckboxTableCellView.h"

#import "PKGPayloadTreeNode+UI.h"
#import "PKGFileItem+UI.h"

#import "PKGUsersAndGroupsMonitor.h"

#import "NSTableView+Geometry.h"

#import "PKGApplicationPreferences.h"

#import "PKGElasticFolderNameFormatter.h"

#include <sys/stat.h>

#define PKGAccountMenuTemporaryUnselectableItemTag	(UINT16_MAX+1)

@interface PKGPayloadFilesSelectionInspectorAttributesViewController () <NSTableViewDelegate,NSTableViewDataSource>
{
	IBOutlet NSPopUpButton * _fileOwnerPopUpButton;
	
	IBOutlet NSPopUpButton * _fileGroupPopUpButton;
	
	
	IBOutlet NSTextField * _filePermissionsTextField;
	
	IBOutlet NSTableView * _filePermissionsTableView;
	
	IBOutlet NSTableView * _fileSpecialBitsTableView;
	
	
	
	PKGUsersAndGroupsMonitor * _usersAndGroupsMonitor;
	
	BOOL _canEditPOSIXPermissions;
	
	mode_t _POSIXPermissions;
	
	mode_t _mixedPOSIXPermissions;
	
	char _statType;
	
	NSInteger _cachedOwner;
	
	NSInteger _cachedGroup;
    
    PKGElasticFolderNameFormatter * _cachedElasticFolderNameFormatter;
}

- (IBAction)switchOwner:(id)sender;

- (IBAction)switchGroup:(id)sender;

- (IBAction)switchPermissions:(id)sender;

- (IBAction)switchPermissionsBit:(id)sender;

// Notification

- (void)showServicesUsersAndGroupsSettingsDidChange:(NSNotification *)inNotification;

@end

@implementation PKGPayloadFilesSelectionInspectorAttributesViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
    _cachedElasticFolderNameFormatter=[PKGElasticFolderNameFormatter new];
    _cachedElasticFolderNameFormatter.keysReplacer=self;
    
	// Build the Owner and Group menus
	
	_usersAndGroupsMonitor=[PKGUsersAndGroupsMonitor sharedMonitor];

	_fileOwnerPopUpButton.menu=[_usersAndGroupsMonitor localUsersMenuWithServicesUsers:[PKGApplicationPreferences sharedPreferences].showServicesUsersAndGroups];
	
	_fileGroupPopUpButton.menu=[_usersAndGroupsMonitor localGroupsMenuWithServicesGroups:[PKGApplicationPreferences sharedPreferences].showServicesUsersAndGroups];
	
	// Dynamically resize the tableview to take into account the change of height of the headerCell in Siesta and Siesta Grande
	
	CGFloat tTotalHeight=[_filePermissionsTableView enclosingScrollViewHeightForNumberOfRows:3];
	
	NSRect tScrollViewFrame=_filePermissionsTableView.enclosingScrollView.frame;
	tScrollViewFrame.origin.y-=(tTotalHeight-NSHeight(tScrollViewFrame));
	tScrollViewFrame.size.height=tTotalHeight;
	
	_filePermissionsTableView.enclosingScrollView.frame=tScrollViewFrame;
	
	
	tTotalHeight=[_fileSpecialBitsTableView enclosingScrollViewHeightForNumberOfRows:3];
	
	tScrollViewFrame=_fileSpecialBitsTableView.enclosingScrollView.frame;
	tScrollViewFrame.origin.y-=(tTotalHeight-NSHeight(tScrollViewFrame));
	tScrollViewFrame.size.height=tTotalHeight;
	
	_fileSpecialBitsTableView.enclosingScrollView.frame=tScrollViewFrame;
	
	// Register for notifications
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showServicesUsersAndGroupsSettingsDidChange:) name:PKGPreferencesFilesShowServicesUsersAndGroupsDidChangeNotification object:nil];
}

#pragma mark -

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGPreferencesFilesShowServicesUsersAndGroupsDidChangeNotification object:nil];
}

- (void)refreshSingleSelection
{
	[super refreshSingleSelection];
	
	PKGPayloadTreeNode * tTreeNode=self.selectedItems.lastObject;
	PKGFileItem * tFileItem=[tTreeNode representedObject];
	
	[tFileItem createTemporaryAuxiliaryIfNeededWithAbsolutePath:[self.filePathConverter absolutePathForFilePath:tFileItem.filePath]];
	
	_statType=tFileItem.fileType;
	
	_canEditPOSIXPermissions=YES;
	_mixedPOSIXPermissions=0;
	_POSIXPermissions=tFileItem.permissions;
	
	_cachedOwner=tFileItem.uid;
	_cachedGroup=tFileItem.gid;
	
    if (tFileItem.type==PKGFileItemTypeNewElasticFolder)
        self.fileNameTextField.formatter=_cachedElasticFolderNameFormatter;
    else
        self.fileNameTextField.formatter=self.fileNameFormatter;
    
	switch(tFileItem.type)
	{
		case PKGFileItemTypeHiddenFolderTemplate:
		case PKGFileItemTypeFolderTemplate:
			
			_canEditPOSIXPermissions=NO;
			
			break;
			
		case PKGFileItemTypeNewFolder:
        case PKGFileItemTypeNewElasticFolder:
			
            break;
			
		case PKGFileItemTypeFileSystemItem:
			
			if (tFileItem.isSymbolicLink==YES)
			{
				_canEditPOSIXPermissions=NO;
				
				PKGPayloadTreeNode * tParentNode=(PKGPayloadTreeNode *)tTreeNode.parent;
				
				if (tParentNode!=nil)
				{
					PKGFileItem * tParentFileItem=[tParentNode representedObject];
					
					_cachedOwner=tParentFileItem.uid;
					_cachedGroup=tParentFileItem.gid;
					
					_POSIXPermissions=tParentFileItem.permissions;
				}
			}
			
			break;
			
		default:
			
			break;
	}
	
	// Owner & Group
	
	_fileOwnerPopUpButton.enabled=_canEditPOSIXPermissions;
	
	NSInteger tTemporaryUnselectableIndex=[_fileOwnerPopUpButton indexOfItemWithTag:PKGAccountMenuTemporaryUnselectableItemTag];
	
	if (tTemporaryUnselectableIndex!=-1)
		[_fileOwnerPopUpButton removeItemAtIndex:tTemporaryUnselectableIndex];
	
	NSString * tPosixName=[_usersAndGroupsMonitor posixNameForUserAccountID:(uid_t)_cachedOwner];
	
	if (tPosixName==nil || [_fileOwnerPopUpButton indexOfItemWithTag:_cachedOwner]==-1)
	{
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:(tPosixName!=nil) ? tPosixName : [NSString stringWithFormat:@"%u",(uint32_t) _cachedOwner]
                                                          action:nil
                                                   keyEquivalent:@""];
		
		tMenuItem.tag=PKGAccountMenuTemporaryUnselectableItemTag;
		tMenuItem.enabled=NO;
		
		[_fileOwnerPopUpButton.menu insertItem:tMenuItem atIndex:0];
		
		[_fileOwnerPopUpButton selectItemWithTag:PKGAccountMenuTemporaryUnselectableItemTag];
	}
	else
	{
		[_fileOwnerPopUpButton selectItemWithTag:_cachedOwner];
	}
	
	// Group
	
	_fileGroupPopUpButton.enabled=_canEditPOSIXPermissions;
	
	tTemporaryUnselectableIndex=[_fileGroupPopUpButton indexOfItemWithTag:PKGAccountMenuTemporaryUnselectableItemTag];
	
	if (tTemporaryUnselectableIndex!=-1)
		[_fileGroupPopUpButton removeItemAtIndex:tTemporaryUnselectableIndex];
	
	tPosixName=[_usersAndGroupsMonitor posixNameForGroupAccountID:(gid_t)_cachedGroup];
	
	
	if (tPosixName==nil || [_fileGroupPopUpButton indexOfItemWithTag:_cachedGroup]==-1)
	{
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:(tPosixName!=nil) ? tPosixName : [NSString stringWithFormat:@"%u",(uint32_t) _cachedGroup]
                                                          action:nil
                                                   keyEquivalent:@""];
		
		tMenuItem.tag=PKGAccountMenuTemporaryUnselectableItemTag;
		tMenuItem.enabled=NO;
		
		[_fileGroupPopUpButton.menu insertItem:tMenuItem atIndex:0];
		
		[_fileGroupPopUpButton selectItemWithTag:PKGAccountMenuTemporaryUnselectableItemTag];
	}
	else
	{
		[_fileGroupPopUpButton selectItemWithTag:_cachedGroup];
	}
	
	// Permissions
	
	_filePermissionsTextField.stringValue=[PKGFileItem representationOfPOSIXPermissions:_POSIXPermissions fileType:tFileItem.fileType];
	
	[_filePermissionsTableView reloadData];
	[_fileSpecialBitsTableView reloadData];
}

- (void)refreshMultipleSelection
{
	[super refreshMultipleSelection];
	
	__block NSInteger tCommonUid=NSNotFound;
	__block NSInteger tCommonGid=NSNotFound;
	__block BOOL tMixedUids=NO;
	__block BOOL tMixedGids=NO;
	
	_statType=0;
	
	_canEditPOSIXPermissions=YES;
	_mixedPOSIXPermissions=0;
	
	[self.selectedItems enumerateObjectsUsingBlock:^(PKGPayloadTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOut) {
		PKGFileItem * tFileItem=[bTreeNode representedObject];
		
		[tFileItem createTemporaryAuxiliaryIfNeededWithAbsolutePath:[self.filePathConverter absolutePathForFilePath:tFileItem.filePath]];
		
		unsigned char tFileType=tFileItem.fileType;
		
		switch(tFileItem.type)
		{
			case PKGFileItemTypeHiddenFolderTemplate:
			case PKGFileItemTypeFolderTemplate:
				
				_canEditPOSIXPermissions=NO;
				break;
				
			case PKGFileItemTypeFileSystemItem:
				
				if (tFileItem.isSymbolicLink==YES)
				{
					_canEditPOSIXPermissions=NO;
					
					PKGPayloadTreeNode * tParentNode=(PKGPayloadTreeNode *)bTreeNode.parent;
					
					if (tParentNode!=nil)
						tFileItem=[tParentNode representedObject];
				}
				break;
				
			default:
				
				break;
		}
		
		if (bIndex==0)
		{
			tCommonUid=tFileItem.uid;
			tCommonGid=tFileItem.gid;
			_POSIXPermissions=tFileItem.permissions;
			
			_statType=tFileType;
		}
		else
		{
			if (tCommonUid!=tFileItem.uid)
				tMixedUids=YES;
				
			if (tCommonGid!=tFileItem.gid)
				tMixedGids=YES;
			
			if (_statType!=tFileType)
				_statType='?';
			
			mode_t tXoredPermissions=_POSIXPermissions^tFileItem.permissions;
			
			_mixedPOSIXPermissions=_mixedPOSIXPermissions|tXoredPermissions;
		}
	}];
	
	// Owner and Group
	
	_fileOwnerPopUpButton.enabled=_canEditPOSIXPermissions;
	
	NSInteger tTemporaryUnselectableIndex=[_fileOwnerPopUpButton indexOfItemWithTag:PKGAccountMenuTemporaryUnselectableItemTag];
	
	if (tTemporaryUnselectableIndex!=-1)
		[_fileOwnerPopUpButton removeItemAtIndex:tTemporaryUnselectableIndex];
	
	if (tMixedUids==YES)
	{
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Mixed",@"No comment")
                                                          action:nil
                                                   keyEquivalent:@""];
		
		tMenuItem.tag=PKGAccountMenuTemporaryUnselectableItemTag;
		tMenuItem.enabled=NO;
		
		[_fileOwnerPopUpButton.menu insertItem:tMenuItem atIndex:0];
		
		[_fileOwnerPopUpButton selectItemWithTag:PKGAccountMenuTemporaryUnselectableItemTag];
	}
	else
	{
		NSString * tPosixName=[_usersAndGroupsMonitor posixNameForUserAccountID:(uid_t)tCommonUid];
	
		if (tPosixName==nil)
		{
			NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%d",(int32_t) tCommonUid]
                                                              action:nil
                                                       keyEquivalent:@""];
			
			tMenuItem.tag=PKGAccountMenuTemporaryUnselectableItemTag;
			tMenuItem.enabled=NO;
			
			[_fileOwnerPopUpButton.menu insertItem:tMenuItem atIndex:0];
			
			[_fileOwnerPopUpButton selectItemWithTag:PKGAccountMenuTemporaryUnselectableItemTag];
		}
		else
		{
			[_fileOwnerPopUpButton selectItemWithTag:tCommonUid];
		}
	}
	
	// Group
	
	_fileGroupPopUpButton.enabled=_canEditPOSIXPermissions;
	
	tTemporaryUnselectableIndex=[_fileGroupPopUpButton indexOfItemWithTag:PKGAccountMenuTemporaryUnselectableItemTag];
	
	if (tTemporaryUnselectableIndex!=-1)
		[_fileGroupPopUpButton removeItemAtIndex:tTemporaryUnselectableIndex];
	
	if (tMixedGids==YES)
	{
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Mixed",@"No comment")
                                                          action:nil
                                                   keyEquivalent:@""];
		
		tMenuItem.tag=PKGAccountMenuTemporaryUnselectableItemTag;
		tMenuItem.enabled=NO;
		
		[_fileGroupPopUpButton.menu insertItem:tMenuItem atIndex:0];
		
		[_fileGroupPopUpButton selectItemWithTag:PKGAccountMenuTemporaryUnselectableItemTag];
	}
	else
	{
		NSString * tPosixName=[_usersAndGroupsMonitor posixNameForGroupAccountID:(gid_t)tCommonGid];
		
		if (tPosixName==nil)
		{
			NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%d",(int32_t) tCommonGid]
                                                              action:nil
                                                       keyEquivalent:@""];
			
			tMenuItem.tag=PKGAccountMenuTemporaryUnselectableItemTag;
			tMenuItem.enabled=NO;
			
			[_fileGroupPopUpButton.menu insertItem:tMenuItem atIndex:0];
			
			[_fileGroupPopUpButton selectItemWithTag:PKGAccountMenuTemporaryUnselectableItemTag];
		}
		else
		{
			[_fileGroupPopUpButton selectItemWithTag:tCommonGid];
		}
	}
	
	// Permissions
	
	_filePermissionsTextField.stringValue=[PKGFileItem representationOfPOSIXPermissions:_POSIXPermissions mixedPermissions:_mixedPOSIXPermissions fileType:_statType];
	
	[_filePermissionsTableView reloadData];
	[_fileSpecialBitsTableView reloadData];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=[inMenuItem action];
	
	if (tAction==@selector(switchPermissions:))
		return _canEditPOSIXPermissions;
	
	if (tAction==@selector(switchOwner:) ||
		tAction==@selector(switchGroup:))
		return (inMenuItem.tag>=0 && inMenuItem.tag<=UINT16_MAX);
	
	return YES;
}

- (IBAction)switchOwner:(NSPopUpButton *)sender;
{
	NSInteger tTag=sender.selectedItem.tag;
	
	if (tTag!=_cachedOwner)
	{
		for(PKGPayloadTreeNode * tTreeNode in self.selectedItems)
		{
			PKGFileItem * tFileItem=[tTreeNode representedObject];
			
			tFileItem.uid=(uid_t)tTag;
		}
		
		[self.delegate viewController:self didUpdateSelectedItems:self.selectedItems];
		
		_cachedOwner=tTag;
	}
}

- (IBAction)switchGroup:(NSPopUpButton *)sender
{
	NSInteger tTag=sender.selectedItem.tag;
	
	if (tTag!=_cachedGroup)
	{
		for(PKGPayloadTreeNode * tTreeNode in self.selectedItems)
		{
			PKGFileItem * tFileItem=[tTreeNode representedObject];
			
			tFileItem.gid=(gid_t)tTag;
		}
		
		[self.delegate viewController:self didUpdateSelectedItems:self.selectedItems];
		
		_cachedGroup=tTag;
	}
}

- (IBAction)switchPermissions:(NSPopUpButton *)sender
{
	mode_t tPermissions=sender.selectedItem.tag;
	
	if (tPermissions!=(_POSIXPermissions & ~_mixedPOSIXPermissions))
	{
		_POSIXPermissions=tPermissions;
		_mixedPOSIXPermissions=0;
		
		for(PKGPayloadTreeNode * tTreeNode in self.selectedItems)
		{
			PKGFileItem * tFileItem=[tTreeNode representedObject];
			
			tFileItem.permissions=tPermissions;
		}
		
		_filePermissionsTextField.stringValue=[PKGFileItem representationOfPOSIXPermissions:_POSIXPermissions fileType:_statType];
		
		[_filePermissionsTableView reloadData];
		
		[_fileSpecialBitsTableView reloadData];
		
		[self.delegate viewController:self didUpdateSelectedItems:self.selectedItems];
	}
}

- (IBAction)switchPermissionsBit:(NSButton *)sender
{
	NSInteger tState=sender.state;
	NSInteger tFlag=sender.tag;
	
	if (tState!=WBControlStateValueOff)
	{
		_POSIXPermissions|=tFlag;
		sender.state=WBControlStateValueOn;
	}
	else
	{
		_POSIXPermissions&=~tFlag;
		sender.state=WBControlStateValueOff;
	}

	_mixedPOSIXPermissions&=~tFlag;
	
	for(PKGPayloadTreeNode * tTreeNode in self.selectedItems)
	{
		PKGFileItem * tFileItem=[tTreeNode representedObject];
		
		tFileItem.permissions=(_POSIXPermissions & ~_mixedPOSIXPermissions)|(tFileItem.permissions&_mixedPOSIXPermissions);
	}
	
	_filePermissionsTextField.stringValue=[PKGFileItem representationOfPOSIXPermissions:_POSIXPermissions mixedPermissions:_mixedPOSIXPermissions fileType:_statType];
	
	[self.delegate viewController:self didUpdateSelectedItems:self.selectedItems];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
	if (inTableView==_filePermissionsTableView || inTableView==_fileSpecialBitsTableView)
		return 3;
	
	return 0;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	if (inTableView==_filePermissionsTableView)
	{
		NSString * tTableColumnIdentifier=inTableColumn.identifier;
		NSTableCellView * tCellView=[_filePermissionsTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		
		if ([tTableColumnIdentifier isEqualToString:@"owner"]==YES)
		{
			NSTextField * tTextField=tCellView.textField;
			
			switch(inRow)
			{
				case 0:
					tTextField.stringValue=NSLocalizedString(@"Owner",@"");
					break;
					
				case 1:
					tTextField.stringValue=NSLocalizedString(@"Group",@"");
					break;
					
				case 2:
					tTextField.stringValue=NSLocalizedString(@"Others",@"");
					break;
			}
			
			return tCellView;
		}
		
		NSButton * tCheckBox=((PKGCheckboxTableCellView *)tCellView).checkbox;
		int tFlag=0;
		
		tCheckBox.enabled=_canEditPOSIXPermissions;
		tCheckBox.action=@selector(switchPermissionsBit:);
		tCheckBox.target=self;
		tCheckBox.allowsMixedState=YES;
		
		if ([tTableColumnIdentifier isEqualToString: @"read"]==YES)
		{
			switch(inRow)
			{
				case 0:
					tFlag=S_IRUSR;
					break;
				case 1:
					tFlag=S_IRGRP;
					break;
				case 2:
					tFlag=S_IROTH;
					break;
			}
		}
		else if ([tTableColumnIdentifier isEqualToString: @"write"]==YES)
		{
			switch(inRow)
			{
				case 0:
					tFlag=S_IWUSR;
					break;
				case 1:
					tFlag=S_IWGRP;
					break;
				case 2:
					tFlag=S_IWOTH;
					break;
			}
		}
		else if ([tTableColumnIdentifier isEqualToString: @"exec"]==YES)
		{
			switch(inRow)
			{
				case 0:
					tFlag=S_IXUSR;
					break;
				case 1:
					tFlag=S_IXGRP;
					break;
				case 2:
					tFlag=S_IXOTH;
					break;
			}
		}
		
		tCheckBox.tag=tFlag;
		
		if ((_mixedPOSIXPermissions & tFlag)==tFlag)
			tCheckBox.state=WBControlStateValueMixed;
		else
			tCheckBox.state=((_POSIXPermissions & tFlag)==tFlag) ? WBControlStateValueOn : WBControlStateValueOff;
		
		return tCellView;
	}
	
	if (inTableView==_fileSpecialBitsTableView)
	{
		NSString * tTableColumnIdentifier=inTableColumn.identifier;
		NSTableCellView * tCellView=[_fileSpecialBitsTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		
		if ([tTableColumnIdentifier isEqualToString:@"name"]==YES)
		{
			NSTextField * tTextField=tCellView.textField;
			
			switch(inRow)
			{
				case 0:
					tTextField.stringValue=NSLocalizedString(@"SetUID",@"");
					break;
					
				case 1:
					tTextField.stringValue=NSLocalizedString(@"SetGID",@"");
					break;
					
				case 2:
					tTextField.stringValue=NSLocalizedString(@"Sticky",@"");
					break;
			}
			
			return tCellView;
		}
		
		NSButton * tCheckBox=((PKGCheckboxTableCellView *)tCellView).checkbox;
		int tFlag=0;
		
		tCheckBox.enabled=_canEditPOSIXPermissions;
		tCheckBox.action=@selector(switchPermissionsBit:);
		tCheckBox.target=self;
		tCheckBox.allowsMixedState=YES;
		
		switch(inRow)
		{
			case 0:
				tFlag=S_ISUID;
				break;
			case 1:
				tFlag=S_ISGID;
				break;
			case 2:
				tFlag=S_ISTXT;
				break;
		}
		
		tCheckBox.tag=tFlag;
		
		if ((_mixedPOSIXPermissions & tFlag)==tFlag)
			tCheckBox.state=WBControlStateValueMixed;
		else
			tCheckBox.state=((_POSIXPermissions & tFlag)==tFlag) ? WBControlStateValueOn : WBControlStateValueOff;
		
		return tCellView;
	}
	
	return nil;
}

-(void)tableView:(NSTableView *)inTableView didAddRowView:(NSTableRowView *)inRowView forRow:(NSInteger)inRow
{
	if (inTableView!=_fileSpecialBitsTableView || inRowView==nil)
		return;
	
	if ((inRow%2)==1)
	{
		if ([inTableView WB_isEffectiveAppearanceDarkAqua]==NO)
			inRowView.backgroundColor=[NSColor colorWithDeviceRed:1.0 green:213.0/255.0 blue:202.0/255.0 alpha:1.0];
		else
			inRowView.backgroundColor=[NSColor colorWithDeviceRed:210.0/255.0 green:68.0/255.0 blue:72.0/255.0 alpha:0.5];
	}
}

#pragma mark -

- (void)showServicesUsersAndGroupsSettingsDidChange:(NSNotification *)inNotification
{
	_fileOwnerPopUpButton.menu=[_usersAndGroupsMonitor localUsersMenuWithServicesUsers:[PKGApplicationPreferences sharedPreferences].showServicesUsersAndGroups];
	
	_fileGroupPopUpButton.menu=[_usersAndGroupsMonitor localGroupsMenuWithServicesGroups:[PKGApplicationPreferences sharedPreferences].showServicesUsersAndGroups];
	
	if (self.selectedItems==nil)
		return;
	
	if (self.selectedItems.count>1)
	{
		[self refreshMultipleSelection];
	}
	else
	{
		[self refreshSingleSelection];
	}
}

@end

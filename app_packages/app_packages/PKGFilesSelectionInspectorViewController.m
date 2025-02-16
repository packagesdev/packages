/*
 Copyright (c) 2017-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGFilesSelectionInspectorViewController.h"

#import "PKGPayloadTreeNode+UI.h"
#import "PKGFileItem+UI.h"

#import "PKGArchitectureUtilities.h"

#import "PKGFilesSelectionInspectorAttributesViewController.h"

#import "_PKGFileItemAuxiliary.h"

#import "PKGReplaceableStringFormatter.h"

@interface PKGFilesSelectionInspectorViewController ()
{
	IBOutlet NSImageView * _iconView;
	
	IBOutlet NSTextField * _bigNameTextField;
	
	IBOutlet NSTextField * _lastModifiedDateTextField;
	
	IBOutlet NSTextField * _architecturesLabel;
	
	IBOutlet NSTextField * _architecturesTextField;
	
	IBOutlet NSTextField * _fileTypeTextField;
	
	IBOutlet NSTextField * _referenceTypeTextField;
	
	IBOutlet NSPopUpButton * _referenceTypePopUpButton;
	
	IBOutlet NSTextField * _sourcePathTextField;
	
	IBOutlet NSTextField * _destinationPathTextField;
	
	NSUInteger _filePathType;
    
    PKGReplaceableStringFormatter * _cachedFormatter;
}

+ (NSImage *)iconForItemAtPath:(NSString *)inPath type:(PKGFileItemType)inType;

- (void)_refreshSelectionForFileSystemTreeNode:(PKGPayloadTreeNode *)inTreeNode atPath:(NSString *)inPath;
- (void)_refreshSelectionForNonFileSystemTreeNode:(PKGPayloadTreeNode *)inTreeNode atPath:(NSString *)inPath;

- (void)refreshSingleSelection;
- (void)refreshMultipleSelection;

- (IBAction)switchFilePathType:(id)sender;

- (IBAction)showInFinder:(id)sender;
- (IBAction)chooseFileSystemItemSource:(id)sender;

@end

@implementation PKGFilesSelectionInspectorViewController

+ (NSImage *)iconForItemAtPath:(NSString *)inPath type:(PKGFileItemType)inType
{
	if (inType==PKGFileItemTypeRoot)
		return nil;
	
	// New Folder
	
	if (inType==PKGFileItemTypeNewFolder)
	{
		static NSImage * sFolderIcon=nil;
		static dispatch_once_t onceFolderToken;
		
		dispatch_once(&onceFolderToken, ^{
			
			sFolderIcon=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
			
		});
		
		return sFolderIcon;
	}
	
    // New Elastic Folder
    
     if (inType==PKGFileItemTypeNewElasticFolder)
     {
         static NSImage * sElasticFolderIcon=nil;
         static dispatch_once_t onceElasticFolderToken;
         
         dispatch_once(&onceElasticFolderToken, ^{
             
             sElasticFolderIcon=[NSImage imageWithSize:NSMakeSize(32.0,32.0) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
                 
                 NSImage * tFolderIcon=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
                 
                 CGFloat tSideLength=round(NSWidth(dstRect)*0.75);
                 NSRect tRect;
                 
                 tRect.size=NSMakeSize(tSideLength,tSideLength);
                 tRect.origin.x=0;
                 tRect.origin.y=NSMaxY(dstRect)-tSideLength;
                 
                 [tFolderIcon drawInRect:tRect fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:1.0];
                 
                 tRect.origin.x=tSideLength*0.25;
                 tRect.origin.y=NSMinY(dstRect);
                 
                 [tFolderIcon drawInRect:tRect fromRect:NSZeroRect operation:WBCompositingOperationSourceOver fraction:1.0];
                 
                 return YES;
             }];
             
         });
         
         return sElasticFolderIcon;
     }
    
	if (inPath==nil)
		return nil;
	
	// Folder Template
	
	if (inType==PKGFileItemTypeHiddenFolderTemplate || inType==PKGFileItemTypeFolderTemplate)
	{
		static NSMutableDictionary * sFolderTemplateIconsCache=nil;
		static dispatch_once_t onceFolderTemplateToken;
		
		dispatch_once(&onceFolderTemplateToken, ^{
			
			sFolderTemplateIconsCache=[NSMutableDictionary dictionary];
			
		});
		
		NSImage * tFolderTemplateIcon=sFolderTemplateIconsCache[inPath];
		
		if (tFolderTemplateIcon==nil)
		{
			if ([[NSFileManager defaultManager] fileExistsAtPath:inPath]==NO)
				tFolderTemplateIcon=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
			else
				tFolderTemplateIcon=[[NSWorkspace sharedWorkspace] iconForFile:inPath];
			
			if (tFolderTemplateIcon)
				sFolderTemplateIconsCache[inPath]=tFolderTemplateIcon;
		}
		
		return tFolderTemplateIcon;
	}
	
	// Real File System Item
	
	static NSCache * sFileSystemItemIconsCache=nil;
	static dispatch_once_t onceFileSystemItemToken;
	
	dispatch_once(&onceFileSystemItemToken, ^{
		
		sFileSystemItemIconsCache=[NSCache new];
		sFileSystemItemIconsCache.countLimit=100;
	});
	
	NSImage * tFileSystemItemIcon=[sFileSystemItemIconsCache objectForKey:inPath];
	
	if (tFileSystemItemIcon==nil)
	{
		tFileSystemItemIcon=[[NSWorkspace sharedWorkspace] iconForFile:inPath];
		
		if (tFileSystemItemIcon!=nil)
			[sFileSystemItemIconsCache setObject:tFileSystemItemIcon forKey:inPath];
	}
	
	return tFileSystemItemIcon;
}

- (instancetype)initWithDocument:(PKGDocument *)inDocument
{
    self=[super initWithDocument:inDocument];
    
    if (self!=nil)
    {
        _cachedFormatter=[PKGReplaceableStringFormatter new];
        _cachedFormatter.keysReplacer=self;
        
        _tabViewItemViewControllers=[NSMutableArray array];
    }
    
    return self;
}

#pragma mark -

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	NSDateFormatter * tDateFormater=[NSDateFormatter new];
	
	tDateFormater.formatterBehavior=NSDateFormatterBehavior10_4;
	tDateFormater.dateStyle=NSDateFormatterMediumStyle;
	tDateFormater.timeStyle=NSDateFormatterShortStyle;
	
	_lastModifiedDateTextField.formatter=tDateFormater;
	
	NSUInteger tIndex=[tabView indexOfTabViewItemWithIdentifier:@"tabviewitem.attributes"];
	
	if (tIndex==NSNotFound)
	{
		// A COMPLETER
		
		return;
	}
	
	NSView * tView=[tabView tabViewItemAtIndex:tIndex].view;
	
	PKGFilesSelectionInspectorTabViewItemViewController * tTabViewItemViewController=[self attributesViewController];
	
	if (tTabViewItemViewController==nil)
	{
		// A COMPLETER
		
		return;
	}
	
	tTabViewItemViewController.delegate=self.delegate;
	
	[_tabViewItemViewControllers addObject:tTabViewItemViewController];
	
	tTabViewItemViewController.view.frame=tView.bounds;
	
	[tView addSubview:tTabViewItemViewController.view];
}

- (PKGFilesSelectionInspectorTabViewItemViewController *)attributesViewController
{
	return [[PKGFilesSelectionInspectorAttributesViewController alloc] initWithDocument:self.document];
}

#pragma mark -

- (void)setDelegate:(id<PKGFilesSelectionInspectorDelegate>)inDelegate
{
	_delegate=inDelegate;
	
	for(PKGFilesSelectionInspectorTabViewItemViewController * tTabViewItemViewController in _tabViewItemViewControllers)
		tTabViewItemViewController.delegate=inDelegate;
}

- (void)setSelectedItems:(NSArray *)inSelectedItems
{
	if ([_selectedItems isEqualToArray:inSelectedItems]==NO)
	{
		_selectedItems=inSelectedItems;
		
		for(PKGFilesSelectionInspectorTabViewItemViewController * tTabViewItemViewController in _tabViewItemViewControllers)
			tTabViewItemViewController.selectedItems=_selectedItems;
		
		[self refreshUI];
	}
}

#pragma mark -

- (void)refreshUI
{
	if (_iconView==nil || self.selectedItems==nil)
		return;
	
	if (self.selectedItems.count>1)
	{
		[self refreshMultipleSelection];
		
		for(PKGFilesSelectionInspectorTabViewItemViewController * tTabViewItemViewController in _tabViewItemViewControllers)
			[tTabViewItemViewController refreshMultipleSelection];
	}
	else
	{
		[self refreshSingleSelection];
		
		for(PKGFilesSelectionInspectorTabViewItemViewController * tTabViewItemViewController in _tabViewItemViewControllers)
			[tTabViewItemViewController refreshSingleSelection];
	}
}

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
    
    [self.tabViewItemViewControllers.firstObject WB_viewWillAppear];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[self refreshUI];
	
    [self.tabViewItemViewControllers.firstObject WB_viewDidAppear];
    
	// Register for notifications (rename folder)
	
	// A COMPLETER
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
    
    [self.tabViewItemViewControllers.firstObject WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
    
    [self.tabViewItemViewControllers.firstObject WB_viewDidDisappear];
}

#pragma mark -

- (void)_refreshSelectionForFileSystemTreeNode:(PKGPayloadTreeNode *)inTreeNode atPath:(NSString *)inPath
{
	if (inTreeNode==nil)
		return;
	
	PKGFileItem * tFileItem=[inTreeNode representedObject];
	
	NSError * tError=nil;
	
	NSDictionary * tAttributesDictionary=(inPath!=nil) ? [[NSFileManager defaultManager] attributesOfItemAtPath:inPath error:&tError] : @{};
	
	if (tAttributesDictionary==nil)
	{
		if ([tError.domain isEqualToString:NSCocoaErrorDomain]==NO || tError.code!=NSFileReadNoSuchFileError)
		{
			NSLog(@"Could not read file attributes");
			
			return;
		}
		
		// Following code works also for a nil attributesDictionary
	}
	
	// Icon
	
	static NSImage * sSelectionUnknownFSObjectIcon=nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		
		sSelectionUnknownFSObjectIcon=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kUnknownFSObjectIcon)];
		
	});
	
	_iconView.image=(inPath!=nil) ? [PKGFilesSelectionInspectorViewController iconForItemAtPath:inPath type:PKGFileItemTypeFileSystemItem] : sSelectionUnknownFSObjectIcon;
	
	// Big Name
	
    _bigNameTextField.formatter=(tFileItem.isNameEditable==YES) ? _cachedFormatter : nil;
	_bigNameTextField.objectValue=tFileItem.fileName;
	
	// Last Modification Date
	
	NSDate * tModificationDate=tAttributesDictionary[NSFileModificationDate];
	
	if (tModificationDate!=nil)
		_lastModifiedDateTextField.objectValue=tModificationDate;
	else
		_lastModifiedDateTextField.stringValue=@"-";
	
	// Architectures & Type
	
	_architecturesLabel.stringValue=NSLocalizedString(@"Architectures:",@"");
	_architecturesTextField.stringValue=@"-";
	
	NSString * tFileTypeString=tAttributesDictionary[NSFileType];
	
	if ([tFileTypeString isEqualToString:NSFileTypeSymbolicLink]==YES)
	{
		_fileTypeTextField.stringValue=NSLocalizedString(@"Symbolic link",@"No comment");
	}
	else
	{
		BOOL tIsFile=[tFileTypeString isEqualToString:NSFileTypeRegular];
		
		if (tIsFile==YES || [tFileTypeString isEqualToString:NSFileTypeDirectory]==YES)		// A COMPLETER Should improve a lot to take into account disclosed bundles with removed descendants.
		{
			NSString * tExecutableFilePath=nil;
			
			if (tIsFile==NO)
			{
				NSBundle * tBundle=[NSBundle bundleWithPath:inPath];
				NSString * tIdentifier=tBundle.infoDictionary[@"CFBundleIdentifier"];
				
				if ([tIdentifier isKindOfClass:NSString.class]==YES && tIdentifier.length>0)
					tExecutableFilePath=tBundle.executablePath;
			}
			else
			{
				tExecutableFilePath=inPath;
			}
			
			NSArray * tArchitecturesArray=nil;
			
			if (tExecutableFilePath!=nil)
				tArchitecturesArray=[PKGArchitectureUtilities architecturesOfFileAtPath:tExecutableFilePath];
			
			if (tArchitecturesArray.count>0)
			{
				// Label
				
				if (tArchitecturesArray.count==1)
					_architecturesLabel.stringValue=NSLocalizedString(@"Architecture:",@"");
				
				_architecturesTextField.stringValue=[tArchitecturesArray componentsJoinedByString:@" | "];
				
				// File Type
				
				NSString * tTypeString=nil;
				
				if (tIsFile==NO)
				{
					NSString * (^typeOfBundleWithExtension)(NSString *) = ^NSString *(NSString * bExtension)
					{
						if (bExtension.length==0)
							return NSLocalizedString(@"Bundle",@"No comment");
						
						static NSDictionary * sTypeForExtensionDictionary=nil;
						static dispatch_once_t onceToken;
						
						dispatch_once(&onceToken, ^{
							
							sTypeForExtensionDictionary=[NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"FileExtensions" withExtension:@"plist"]];
							
						});
						
						NSString * tTypeString=sTypeForExtensionDictionary[bExtension];
						
						return (tTypeString!=nil) ? tTypeString : NSLocalizedString(@"Bundle",@"No comment");
						
					};
					
					tTypeString=typeOfBundleWithExtension([inPath pathExtension]);
				}
				else
				{
					tTypeString=NSLocalizedString(@"Executable",@"No comment");
				}
				
				if (tTypeString!=nil)
					_fileTypeTextField.stringValue=tTypeString;
			}
			else
			{
				_fileTypeTextField.stringValue=(tIsFile==YES) ? NSLocalizedString(@"File",@"No comment") : NSLocalizedString(@"Folder",@"No comment");
			}
		}
		else
		{
			_fileTypeTextField.stringValue=NSLocalizedString(@"N/A",@"No comment");
		}
	}
	
	// Reference Type
	
	_referenceTypeTextField.hidden=YES;
	_referenceTypePopUpButton.hidden=NO;
	
	_referenceTypePopUpButton.enabled=(inPath!=nil);
	
	_filePathType=tFileItem.filePath.type;
	
	[_referenceTypePopUpButton selectItemWithTag:_filePathType];
	
	// Source
	
	_sourcePathTextField.textColor=[NSColor labelColor];
	_sourcePathTextField.formatter=(tFileItem.isNameEditable==YES) ? _cachedFormatter : nil;
    _sourcePathTextField.objectValue=tFileItem.filePath.string;
	
	// Destination
	
	if (_destinationPathTextField!=nil)
	{
		_destinationPathTextField.textColor=[NSColor labelColor];
        _destinationPathTextField.formatter=(tFileItem.isNameEditable==YES) ? _cachedFormatter : nil;
		_destinationPathTextField.objectValue=[inTreeNode filePathWithSeparator:@"/"];
	}
}

- (void)_refreshSelectionForNonFileSystemTreeNode:(PKGPayloadTreeNode *)inTreeNode atPath:(NSString *)inPath
{
	if (inTreeNode==nil || inPath==nil)
		return;
	
	PKGFileItem * tFileItem=[inTreeNode representedObject];
	PKGFileItemType tFileType=tFileItem.type;
	
	// Icon
	
	_iconView.image=[PKGFilesSelectionInspectorViewController iconForItemAtPath:inPath type:tFileType];
	
	// Big Name
	
	_bigNameTextField.formatter=(tFileItem.isNameEditable==YES) ? _cachedFormatter : nil;
    _bigNameTextField.objectValue=tFileItem.fileName;
	
	// Last Modification Date
	
	_lastModifiedDateTextField.stringValue=@"-";
	
	// Architecture
	
	_architecturesLabel.stringValue=NSLocalizedString(@"Architectures:",@"");
	_architecturesTextField.stringValue=@"-";
	
	// Type
	
	_fileTypeTextField.textColor=[NSColor labelColor];
	
	NSString * tTypeString=nil;
	
	switch(tFileType)
	{
		case PKGFileItemTypeHiddenFolderTemplate:
		case PKGFileItemTypeFolderTemplate:
			
			tTypeString=NSLocalizedString(@"Standard folder",@"No comment");
			
			break;
			
		case PKGFileItemTypeNewFolder:
			
			tTypeString=NSLocalizedString(@"Custom folder",@"No comment");
			
			break;
        
        case PKGFileItemTypeNewElasticFolder:
            
            tTypeString=NSLocalizedString(@"Custom elastic folder",@"No comment");
            
            break;
            
		default:
			
			break;
	}
	
	if (tTypeString!=nil)
		_fileTypeTextField.stringValue=tTypeString;
	
	// Reference Type
	
	_referenceTypeTextField.hidden=NO;
	_referenceTypePopUpButton.hidden=YES;
	
	// Source
	
	_sourcePathTextField.textColor=[NSColor labelColor];
	_sourcePathTextField.stringValue=@"-";
	
	// Destination
	
	if (_destinationPathTextField!=nil)
	{
		_destinationPathTextField.textColor=[NSColor labelColor];
		_destinationPathTextField.formatter=(tFileItem.isNameEditable==YES) ? _cachedFormatter : nil;
        _destinationPathTextField.objectValue=inPath;
	}
}

- (void)refreshSingleSelection
{
	PKGPayloadTreeNode * tSelectedNode=[self.selectedItems lastObject];
	PKGFileItem * tSelectedItem=[tSelectedNode representedObject];
	
	NSInteger tMixedIndex=[_referenceTypePopUpButton indexOfItemWithTag:PKGFilePathTypeMixed];
	
	if (tMixedIndex!=-1)
		[_referenceTypePopUpButton removeItemAtIndex:tMixedIndex];
	
	if (tSelectedItem.type==PKGFileItemTypeFileSystemItem)
	{
		[self _refreshSelectionForFileSystemTreeNode:tSelectedNode atPath:[tSelectedNode referencedPathUsingConverter:self.filePathConverter]];
	}
	else
	{
		[self _refreshSelectionForNonFileSystemTreeNode:tSelectedNode atPath:[tSelectedNode filePathWithSeparator:@"/"]];
	}
}

- (void)refreshMultipleSelection
{
	// Icon
	
	static NSImage * sMultipleSelectionIcon=nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		
		sMultipleSelectionIcon=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kUnknownFSObjectIcon)];
		
	});
	
	_iconView.image=sMultipleSelectionIcon;

	// Big Name
	
	_bigNameTextField.stringValue=NSLocalizedString(@"Multiple Selection",@"No comment");
	
	// Last Modification Date
	
	_lastModifiedDateTextField.stringValue=@"-";
	
	// Architectures
	
	_architecturesLabel.stringValue=NSLocalizedString(@"Architectures:",@"No comment");
	
	_architecturesTextField.stringValue=@"-";
	
	// Type
	
	_fileTypeTextField.textColor=[NSColor secondaryLabelColor];
	_fileTypeTextField.stringValue=NSLocalizedString(@"Multiple Selection",@"No comment");
	
	// Reference Type
	
	_filePathType=NSNotFound;
	__block BOOL tCanSwitchPathType=YES;
	
	[self.selectedItems enumerateObjectsUsingBlock:^(PKGPayloadTreeNode * bTreeNode, NSUInteger bIndex,BOOL * bOutStop){
	
		PKGFileItem * tSelectedItem=[bTreeNode representedObject];
		
		switch(tSelectedItem.type)
		{
			case PKGFileItemTypeHiddenFolderTemplate:
			case PKGFileItemTypeFolderTemplate:
			case PKGFileItemTypeNewFolder:
            case PKGFileItemTypeNewElasticFolder:
				
				tCanSwitchPathType=NO;
				*bOutStop=YES;
				
				break;
				
			case PKGFileItemTypeFileSystemItem:
				
				if (self->_filePathType==NSNotFound)
				{
					self->_filePathType=tSelectedItem.filePath.type;
				}
				else
				{
					if (tSelectedItem.filePath.type!=self->_filePathType)
					{
						self->_filePathType=PKGFilePathTypeMixed;
						*bOutStop=YES;
					}
				}
				
				break;
				
			default:
				break;
		}
	
	}];
	
	if (tCanSwitchPathType==NO)
	{
		_referenceTypeTextField.hidden=NO;
		_referenceTypePopUpButton.hidden=YES;
	}
	else
	{
		_referenceTypeTextField.hidden=YES;
		_referenceTypePopUpButton.hidden=NO;
		
		NSInteger tMixedIndex=[_referenceTypePopUpButton indexOfItemWithTag:PKGFilePathTypeMixed];
		
		if (_filePathType==PKGFilePathTypeMixed)
		{
			_referenceTypePopUpButton.enabled=YES;
			
			if (tMixedIndex==-1)
			{
				NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Mixed",@"No comment")
                                                                  action:nil
                                                           keyEquivalent:@""];
			
				tMenuItem.image=[NSImage imageNamed:@"MixedMenuItemUbuntu"];
				tMenuItem.target=nil;
				tMenuItem.enabled=NO;
				tMenuItem.tag=PKGFilePathTypeMixed;
				
				[_referenceTypePopUpButton.menu insertItem:tMenuItem atIndex:0];
			}
			
			[_referenceTypePopUpButton selectItemWithTag:PKGFilePathTypeMixed];
			
			[_referenceTypePopUpButton setNeedsDisplay:YES];
		}
		else
		{
			if (tMixedIndex!=-1)
				[_referenceTypePopUpButton removeItemAtIndex:tMixedIndex];
			
			[_referenceTypePopUpButton selectItemWithTag:_filePathType];
		}
	}
	
	// Source
	
	_sourcePathTextField.textColor=[NSColor secondaryLabelColor];
	_sourcePathTextField.stringValue=NSLocalizedString(@"Multiple Selection",@"No comment");
	
	// Destination
	
	if (_destinationPathTextField!=nil)
	{
		_destinationPathTextField.textColor=[NSColor secondaryLabelColor];
		_destinationPathTextField.stringValue=NSLocalizedString(@"Multiple Selection",@"No comment");
	}
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(showInFinder:))
	{
		for(PKGPayloadTreeNode * tTreeNode in self.selectedItems)
		{
			if ([tTreeNode isFileSystemItemNode]==NO)
				return NO;
			
			if ([tTreeNode isReferencedItemMissing]==YES)
				return NO;
		}
		
		return YES;
	}
	
	if (tAction==@selector(switchFilePathType:))
		return (inMenuItem.tag!=PKGFilePathTypeMixed);
	
	if (tAction==@selector(chooseFileSystemItemSource:))
	{
		if (self.selectedItems.count!=1)
			return NO;
		
		return [self.selectedItems.lastObject isFileSystemItemNode];
	}
	
	return YES;
}

- (IBAction)switchFilePathType:(NSPopUpButton *)sender
{
	PKGFilePathType tType=sender.selectedItem.tag;
	
	if (tType!=_filePathType)
	{
		for(PKGPayloadTreeNode * tTreeNode in self.selectedItems)
		{
			PKGFileItem * tFileItem=[tTreeNode representedObject];
			
			if ([self.filePathConverter shiftTypeOfFilePath:tFileItem.filePath toType:tType]==NO)
			{
				// A COMPLETER
			}
		}
		
		_filePathType=tType;
		
		if (self.selectedItems.count==1)
		{
			PKGPayloadTreeNode * tSelectedNode=self.selectedItems.lastObject;
			PKGFileItem * tSelectedItem=[tSelectedNode representedObject];
			
			_sourcePathTextField.stringValue=tSelectedItem.filePath.string;
		}
		
		[self.delegate viewController:self didUpdateSelectedItems:self.selectedItems];
	}
}

- (IBAction)showInFinder:(id)sender
{
	NSWorkspace * tWorkSpace=[NSWorkspace sharedWorkspace];
	
	for(PKGPayloadTreeNode * tTreeNode in self.selectedItems)
		[tWorkSpace selectFile:[tTreeNode referencedPathUsingConverter:self.filePathConverter] inFileViewerRootedAtPath:@""];
}

- (IBAction)chooseFileSystemItemSource:(id)sender
{
	PKGPayloadTreeNode * tSelectedNode=[self.selectedItems lastObject];
	
	NSOpenPanel * tOpenPanel=[NSOpenPanel openPanel];
	
	tOpenPanel.resolvesAliases=NO;
	tOpenPanel.treatsFilePackagesAsDirectories=YES;
	tOpenPanel.canChooseFiles=tSelectedNode.isLeaf;
	tOpenPanel.canChooseDirectories=YES;
	tOpenPanel.canCreateDirectories=NO;
	
	tOpenPanel.prompt=NSLocalizedString(@"Choose",@"No comment");
	
	[tOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bResult){
		
		if (bResult!=WBFileHandlingPanelOKButton)
			return;
		
		PKGFileItem * tSelectedItem=[tSelectedNode representedObject];
		
		PKGFilePath * tFilePath=[self.filePathConverter filePathForAbsolutePath:tOpenPanel.URL.path type:tSelectedItem.filePath.type];
		
		if (tFilePath==nil)
		{
			return;
		}
		
		tSelectedItem.filePath.string=tFilePath.string;
		
		// Refresh Inspector
		
		[self _refreshSelectionForFileSystemTreeNode:tSelectedNode atPath:tOpenPanel.URL.path];
		
		[tSelectedItem resetAuxiliaryData];
		
		// Refresh Hierarchy
		
		[self.delegate viewController:self didUpdateSelectedItems:self.selectedItems];
	}];
}

#pragma mark - Notifications

- (void)userSettingsDidChange:(NSNotification *)inNotification
{
    [super userSettingsDidChange:inNotification];
    
    [_bigNameTextField setNeedsDisplay:YES];
    
    [_sourcePathTextField setNeedsDisplay:YES];
    
    [_destinationPathTextField setNeedsDisplay:YES];
}

@end

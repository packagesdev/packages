
#import "PKGFilesSelectionInspectorViewController.h"

#import "PKGPayloadTreeNode+UI.h"
#import "PKGFileItem+UI.h"

#import "PKGArchitectureUtilities.h"

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
	
	
	IBOutlet NSTabView * _tabView;
	
	NSUInteger _cachedFilePathType;
}

+ (NSImage *)iconForItemAtPath:(NSString *)inPath type:(PKGFileItemType)inType;

- (void)refreshUI;

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

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	NSDateFormatter * tDateFormater=[NSDateFormatter new];
	
	tDateFormater.formatterBehavior=NSDateFormatterBehavior10_4;
	tDateFormater.dateStyle=NSDateFormatterMediumStyle;
	tDateFormater.timeStyle=NSDateFormatterShortStyle;
	
	_lastModifiedDateTextField.formatter=tDateFormater;
}

#pragma mark -

- (void)setSelectedItems:(NSArray *)inSelectedItems
{
	if ([_selectedItems isEqualToArray:inSelectedItems]==NO)
	{
		_selectedItems=inSelectedItems;
		[self refreshUI];
	}
}

#pragma mark -

- (void)WB_viewWillAppear
{
}

- (void)WB_viewDidAppear
{
	[self refreshUI];
	
	// Register for notifications (rename folder)
	
	// A COMPLETER
}

- (void)WB_viewWillDisappear
{
}

- (void)WB_viewDidDisappear
{
}

#pragma mark -

- (void)refreshUI
{
	if (_iconView==nil || self.selectedItems==nil)
		return;
	
	if (self.selectedItems.count>1)
		[self refreshMultipleSelection];
	else
		[self refreshSingleSelection];
}

- (void)_refreshSelectionForFileSystemTreeNode:(PKGPayloadTreeNode *)inTreeNode atPath:(NSString *)inPath
{
	if (inTreeNode==nil || inPath==nil)
		return;
	
	PKGFileItem * tFileItem=[inTreeNode representedObject];
	
	NSError * tError=nil;
	
	NSDictionary * tAttributesDictionary=[[NSFileManager defaultManager] attributesOfItemAtPath:inPath error:&tError];
	
	if (tAttributesDictionary==nil)
	{
		// A COMPLETER
		
		return;
	}
	
	// Icon
	
	_iconView.image=[PKGFilesSelectionInspectorViewController iconForItemAtPath:inPath type:PKGFileItemTypeFileSystemItem];
	
	// Big Name
	
	_bigNameTextField.stringValue=tFileItem.fileName;
	
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
		
		if (tIsFile==YES || [tFileTypeString isEqualToString:NSFileTypeDirectory]==YES)
		{
			NSString * tExecutableFilePath=nil;
			
			if (tIsFile==NO)
			{
				NSBundle * tBundle=[NSBundle bundleWithPath:inPath];
				
				if (tBundle!=nil)
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
	
	_cachedFilePathType=tFileItem.filePath.type;
	
	[_referenceTypePopUpButton selectItemWithTag:_cachedFilePathType];
	
	// Source
	
	_sourcePathTextField.textColor=[NSColor blackColor];
	_sourcePathTextField.stringValue=tFileItem.filePath.string;
	
	// Destination
	
	if (_destinationPathTextField!=nil)
	{
		_destinationPathTextField.textColor=[NSColor blackColor];
		_destinationPathTextField.stringValue=inTreeNode.filePath;
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
	
	_bigNameTextField.stringValue=tFileItem.fileName;
	
	// Last Modification Date
	
	_lastModifiedDateTextField.stringValue=@"-";
	
	// Architecture
	
	_architecturesLabel.stringValue=NSLocalizedString(@"Architectures:",@"");
	_architecturesTextField.stringValue=@"-";
	
	// Type
	
	_fileTypeTextField.textColor=[NSColor blackColor];
	
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
			
		default:
			
			break;
	}
	
	if (tTypeString!=nil)
		_fileTypeTextField.stringValue=tTypeString;
	
	// Reference Type
	
	_referenceTypeTextField.hidden=NO;
	_referenceTypePopUpButton.hidden=YES;
	
	// Source
	
	_sourcePathTextField.textColor=[NSColor blackColor];
	_sourcePathTextField.stringValue=@"-";
	
	// Destination
	
	if (_destinationPathTextField!=nil)
	{
		_destinationPathTextField.textColor=[NSColor blackColor];
		_destinationPathTextField.stringValue=inPath;
	}
}

- (void)refreshSingleSelection
{
	PKGPayloadTreeNode * tSelectedNode=[self.selectedItems lastObject];
	PKGFileItem * tSelectedItem=[tSelectedNode representedObject];
	
	NSLog(@"%@",NSStringFromClass([tSelectedItem class]));
	
	if (tSelectedItem.type==PKGFileItemTypeFileSystemItem)
	{
		[self _refreshSelectionForFileSystemTreeNode:tSelectedNode atPath:[tSelectedNode referencedPathUsingConverter:self.filePathConverter]];
	}
	else
	{
		[self _refreshSelectionForNonFileSystemTreeNode:tSelectedNode atPath:tSelectedNode.filePath];
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
	
	_fileTypeTextField.textColor=[NSColor grayColor];
	_fileTypeTextField.stringValue=NSLocalizedString(@"Multiple Selection",@"No comment");
	
	// Reference Type
	
	_cachedFilePathType=NSNotFound;
	__block BOOL tCanSwitchPathType=YES;
	
	[self.selectedItems enumerateObjectsUsingBlock:^(PKGPayloadTreeNode * bTreeNode, NSUInteger bIndex,BOOL * bOutStop){
	
		PKGFileItem * tSelectedItem=[bTreeNode representedObject];
		
		switch(tSelectedItem.type)
		{
			case PKGFileItemTypeHiddenFolderTemplate:
			case PKGFileItemTypeFolderTemplate:
			case PKGFileItemTypeNewFolder:
				
				tCanSwitchPathType=NO;
				*bOutStop=YES;
				
				break;
				
			case PKGFileItemTypeFileSystemItem:
				
				if (_cachedFilePathType==NSNotFound)
				{
					_cachedFilePathType=tSelectedItem.filePath.type;
				}
				else
				{
					if (tSelectedItem.filePath.type!=_cachedFilePathType)
					{
						_cachedFilePathType=PKGFilePathTypeMixed;
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
		
		if (_cachedFilePathType==PKGFilePathTypeMixed)
		{
			_referenceTypePopUpButton.enabled=YES;
			
			[_referenceTypePopUpButton insertItemWithTitle:NSLocalizedString(@"Mixed",@"No comment")
												   atIndex:0];
			
			NSMenuItem * tMenuItem=[_referenceTypePopUpButton itemAtIndex:0];
			
			tMenuItem.image=[NSImage imageNamed:@"MixedMenuItemUbuntu"];
			tMenuItem.target=nil;
			tMenuItem.enabled=NO;
			tMenuItem.tag=PKGFilePathTypeMixed;
			
			[_referenceTypePopUpButton selectItemAtIndex:0];
			
			[_referenceTypePopUpButton setNeedsDisplay:YES];
		}
		else
		{
			[_referenceTypePopUpButton selectItemWithTag:_cachedFilePathType];
		}
	}
	
	// Source
	
	_sourcePathTextField.textColor=[NSColor grayColor];
	_sourcePathTextField.stringValue=NSLocalizedString(@"Multiple Selection",@"No comment");
	
	// Destination
	
	if (_destinationPathTextField!=nil)
	{
		_destinationPathTextField.textColor=[NSColor grayColor];
		_destinationPathTextField.stringValue=NSLocalizedString(@"Multiple Selection",@"No comment");
	}
}

#pragma mark -

- (IBAction)switchFilePathType:(NSPopUpButton *)sender
{
	PKGFilePathType tType=[sender selectedItem].tag;
	
	if (tType!=_cachedFilePathType)
	{
		for(PKGPayloadTreeNode * tTreeNode in self.selectedItems)
		{
			PKGFileItem * tFileItem=[tTreeNode representedObject];
			
			if ([self.filePathConverter shiftTypeOfFilePath:tFileItem.filePath toType:tType]==NO)
			{
				// A COMPLETER
			}
		}
		
		if (self.selectedItems.count==1)
		{
			PKGPayloadTreeNode * tSelectedNode=[self.selectedItems lastObject];
			PKGFileItem * tSelectedItem=[tSelectedNode representedObject];
			
			_sourcePathTextField.stringValue=tSelectedItem.filePath.string;
		}
		
		[self.delegate filesSelectionInspectorViewController:self didUpdateFileItems:self.selectedItems];
	}
}

- (IBAction)showInFinder:(id)sender
{
	NSWorkspace * tWorkSpace=[NSWorkspace sharedWorkspace];
	
	for(PKGPayloadTreeNode * tTreeNode in self.selectedItems)
		[tWorkSpace selectFile:[tTreeNode referencedPathUsingConverter:self.filePathConverter] inFileViewerRootedAtPath:@""];
}

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(showInFinder:) ||
		tAction==@selector(switchFilePathType:))
		return YES;
	
	if (tAction==@selector(chooseFileSystemItemSource:))
	{
		if (self.selectedItems.count!=1)
			return NO;
		
		return [[self.selectedItems lastObject] isFileSystemItemNode];
	}
	
	return YES;
}

- (IBAction)chooseFileSystemItemSource:(id)sender;
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
		
		if (bResult!=NSFileHandlingPanelOKButton)
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
		
		// Refresh Hierarchy
		
		[self.delegate filesSelectionInspectorViewController:self didUpdateFileItems:self.selectedItems];
	}];
}

@end

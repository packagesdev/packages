/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionProjectSourceListDataSource.h"

#import "PKGDistributionProject+Edition.h"
#import "PKGFilePathConverter+Edition.h"

#import "PKGPackageComponent+UI.h"
#import "PKGDistributionProject+UI.h"

#import "PKGPackageComponent+Transformation.h"

#import "PKGDistributionProjectSourceListForest.h"
#import "PKGDistributionProjectSourceListTreeNode.h"
#import "PKGDistributionProjectSourceListGroupItem.h"
#import "PKGDistributionProjectSourceListPackageComponentItem.h"

#import "NSOutlineView+Selection.h"

#import "NSArray+UniqueName.h"
#import "NSString+BaseName.h"

#import "PKGProjectTemplateDefaultValuesSettings.h"

#import "PKGOwnershipAndReferenceStyleViewController.h"
#import "PKGApplicationPreferences.h"

#import "PKGOwnershipAndReferenceStylePanel.h"

#import "PKGArchive.h"

NSString * PKGPackageComponentPromisedPboardTypeRepresentationKey=@"PackageRepresentationKey";
NSString * PKGPackageComponentPromisedPboardTypeSourceFilePathConverterReferenceProjectPathKey=@"ReferenceProjectPathKey";
NSString * PKGPackageComponentPromisedPboardTypeSourceFilePathConverterReferenceFolderPathKey=@"ReferenceFolderPathKey";

@interface PKGPackagesImportPanelDelegate : NSObject<NSOpenSavePanelDelegate>
{
	NSFileManager * _fileManager;
}

	@property NSArray * importedPackageComponents;
	@property (weak) id<PKGFilePathConverter> filePathConverter;

@end

@implementation PKGPackagesImportPanelDelegate

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_fileManager=[NSFileManager defaultManager];
	}
	
	return self;
}

#pragma mark - NSOpenSavePanelDelegate

- (BOOL)panel:(NSOpenPanel *)inPanel shouldEnableURL:(NSURL *)inURL
{
	if (inURL.isFileURL==NO)
		return NO;
	
	NSString * tAbsolutePath=inURL.path;
	
	if (tAbsolutePath==nil)
		return NO;
	
	BOOL isDirectory;
	
	[_fileManager fileExistsAtPath:tAbsolutePath isDirectory:&isDirectory];
	
	if (isDirectory==YES)
		return YES;
	
	// Check whether the package has not been imported yet.
	
	if ([self.importedPackageComponents indexOfObjectPassingTest:^BOOL(PKGPackageComponent *bPackageComponent,NSUInteger bIndex,BOOL * bOutStop){
		
		return ([[self.filePathConverter absolutePathForFilePath:bPackageComponent.importPath] caseInsensitiveCompare:tAbsolutePath]==NSOrderedSame);
		
	}]!=NSNotFound)
		return NO;
	
	// Check whether it's a flat package or not
	
	PKGArchive * tPackageArchive=[PKGArchive archiveAtPath:tAbsolutePath];
	
	return [tPackageArchive isFlatPackage];
}

@end

@interface PKGDistributionProjectSourceListDataSource ()
{
	PKGDistributionProjectSourceListForest * _forest;
	
	PKGPackagesImportPanelDelegate * _importPanelDelegate;
	
	NSArray * _internalDragData;
}

- (void)outlineView:(NSOutlineView *)inOutlineView addPackageComponent:(PKGPackageComponent *)inPackageComponent;
- (void)outlineView:(NSOutlineView *)inOutlineView addPackageComponents:(NSArray *)inPackageComponents;

@end

@implementation PKGDistributionProjectSourceListDataSource

+ (NSArray *)supportedDraggedTypes
{
	return @[NSFilenamesPboardType,PKGPackageComponentPromisedPboardType];
}

- (void)setDistributionProject:(PKGDistributionProject *)inDistributionProject
{
	if (_distributionProject!=inDistributionProject)
	{
		_distributionProject=inDistributionProject;
		
		_forest=[[PKGDistributionProjectSourceListForest alloc] initWithPackageComponents:_distributionProject.packageComponents];
	}
}

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)inOutlineView numberOfChildrenOfItem:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return _forest.rootNodes.count;
	
	return inTreeNode.numberOfChildren;
}

- (id)outlineView:(NSOutlineView *)inOutlineView child:(NSInteger)inIndex ofItem:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return _forest.rootNodes[inIndex];
	
	return [inTreeNode childNodeAtIndex:inIndex];
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView isItemExpandable:(PKGTreeNode *)inTreeNode
{
	return ([inTreeNode isLeaf]==NO);
}

#pragma mark - NSPasteboardOwner

- (void)pasteboard:(NSPasteboard *)inPasteboard provideDataForType:(NSString *)inType
{
	if (inPasteboard==nil || inType==nil)
		return;
	
	if ([inType isEqualToString:PKGPackageComponentPromisedPboardType]==YES)
	{
		NSArray * tPackageComponentsRepresentationsArray=[_internalDragData WB_arrayByMappingObjectsUsingBlock:^NSDictionary *(PKGPackageComponent * bPackageComponent,NSUInteger bIndex){
			
			PKGPackageComponent * tPackageComponentCopy=[bPackageComponent copy];
			
			return [tPackageComponentCopy representation];
			
		}];
		
		[inPasteboard setPropertyList:@{
										PKGPackageComponentPromisedPboardTypeRepresentationKey:tPackageComponentsRepresentationsArray,
										PKGPackageComponentPromisedPboardTypeSourceFilePathConverterReferenceProjectPathKey:self.filePathConverter.referenceProjectPath,
										PKGPackageComponentPromisedPboardTypeSourceFilePathConverterReferenceFolderPathKey:self.filePathConverter.referenceFolderPath
										}
							  forType:PKGPackageComponentPromisedPboardType];
	}
}

#pragma mark - Drag and Drop support

- (void)outlineView:(NSOutlineView *)inOutlineView draggingSession:(NSDraggingSession *)inDraggingSession endedAtPoint:(NSPoint)inScreenPoint operation:(NSDragOperation)inOperation
{
	_internalDragData=nil;
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView writeItems:(NSArray*)inItems toPasteboard:(NSPasteboard*)inPasteboard
{
	if (inOutlineView==nil)
		return NO;
	
	NSArray * tFilteredItems=[inItems WB_filteredArrayUsingBlock:^BOOL(PKGDistributionProjectSourceListTreeNode * bTreeNode, NSUInteger bIndex) {
		return [bTreeNode isPackageComponentNode];
	}];
	
	if (tFilteredItems.count==0)
		return NO;
	
	__block NSMutableArray * tPackageComponents=[NSMutableArray array];
	
	NSArray * tComponentsUUIDS=[tFilteredItems WB_arrayByMappingObjectsUsingBlock:^id(PKGDistributionProjectSourceListTreeNode * bTreeNode, NSUInteger bIndex) {
		PKGDistributionProjectSourceListPackageComponentItem * tPackageComponentItem=bTreeNode.representedObject;
		
		[tPackageComponents addObject:tPackageComponentItem.packageComponent];
		
		return tPackageComponentItem.packageComponent.UUID;
	}];
	
	if (tComponentsUUIDS.count==0)
		return NO;
	
	[inPasteboard declareTypes:@[PKGPackageComponentUUIDsPboardType,PKGPackageComponentPromisedPboardType] owner:self];
	
	[inPasteboard setPropertyList:tComponentsUUIDS forType:PKGPackageComponentUUIDsPboardType];
	
	_internalDragData=[tPackageComponents copy];
	
	return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView*)inOutlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(PKGDistributionProjectSourceListTreeNode *)inProposedTreeNode proposedChildIndex:(NSInteger)inChildIndex
{
	if (inOutlineView==nil)
		return NSDragOperationNone;
	
	if (inProposedTreeNode==nil)
		return NSDragOperationNone;
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]!=nil)
	{
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
		
		if (tArray==nil || [tArray isKindOfClass:NSArray.class]==NO || tArray.count==0)
		{
			// We were provided invalid data
			
			// A COMPLETER
			
			return NSDragOperationNone;
		}
		
		NSArray * tAlreadyImportedPaths=[self.distributionProject.importedPackageComponents WB_arrayByMappingObjectsUsingBlock:^(PKGPackageComponent * bPackageComponent,NSUInteger bIndex){
		
			return [self.filePathConverter absolutePathForFilePath:bPackageComponent.importPath];
		}];
		
		if (tAlreadyImportedPaths==nil)
		{
			NSLog(@"Error when computing the list of paths for already imported packages");
		}
		
		for(NSString * tPath in tArray)
		{
			if ([tAlreadyImportedPaths containsObject:tPath]==YES)
				return NSDragOperationNone;
			
			PKGArchive * tArchive=[PKGArchive archiveAtPath:tPath];
			
			if ([tArchive isFlatPackage]==NO)
				return NSDragOperationNone;
		}
		
		[inOutlineView setDropItem:nil dropChildIndex:-1];
		
		return NSDragOperationCopy;
	}
	
	if ([tPasteBoard availableTypeFromArray:@[PKGPackageComponentPromisedPboardType]]!=nil)
	{
		if ([[info draggingSource] window]==inOutlineView.window)	// We can't accept drop from ourselves
			return NSDragOperationNone;
		
		[inOutlineView setDropItem:nil dropChildIndex:-1];
			
		return NSDragOperationCopy;
	}
	
	return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView*)inOutlineView acceptDrop:(id <NSDraggingInfo>)info item:(PKGDistributionProjectSourceListTreeNode *)inProposedTreeNode childIndex:(NSInteger)inChildIndex
{
	if (inOutlineView==nil)
		return NO;

	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	// Filenames
	
	if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]!=nil)
	{
		NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
		
		PKGOwnershipAndReferenceStylePanel * tPanel=[PKGOwnershipAndReferenceStylePanel ownershipAndReferenceStylePanel];
		
		tPanel.canChooseOwnerAndGroupOptions=NO;
		tPanel.referenceStyle=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
		
		[tPanel beginSheetModalForWindow:inOutlineView.window completionHandler:^(NSModalResponse bResponse){
			
			if (bResponse==PKGPanelCancelButton)
				return;
			
			PKGFilePathType tFileType=tPanel.referenceStyle;
			
			__block NSMutableArray * tTemporaryComponents=[self.distributionProject.packageComponents mutableCopy];
			
			NSArray * tImportedPackageComponents=[tArray WB_arrayByMappingObjectsLenientlyUsingBlock:^PKGPackageComponent *(NSString * bImportPath, NSUInteger bIndex) {
				
				PKGFilePath * tFilePath=[self.filePathConverter filePathForAbsolutePath:bImportPath type:tFileType];
				
				if (tFilePath==nil)
				{
					// A COMPLETER
					
					return nil;
				}
				
				PKGPackageComponent * tPackageComponent=[PKGPackageComponent importedComponentWithFilePath:tFilePath];
				
				NSString * tName=[tTemporaryComponents uniqueNameWithBaseName:[bImportPath.lastPathComponent stringByDeletingPathExtension] usingNameExtractor:^NSString *(PKGPackageComponent * bPackageComponent, NSUInteger bIndex) {
					return bPackageComponent.packageSettings.name;
				}];
				
				if (tName!=nil)
					tPackageComponent.packageSettings.name=tName;
				
				[tTemporaryComponents addObject:tPackageComponent];
				
				return tPackageComponent;
			}];
			
			[self outlineView:inOutlineView addPackageComponents:tImportedPackageComponents];
		}];
		
		return YES;		// It may at the end not be accepted by the completion handler from the sheet
	}
	
	if ([tPasteBoard availableTypeFromArray:@[PKGPackageComponentPromisedPboardType]]!=nil)
	{
		NSDictionary * tDictionary=(NSDictionary *)[tPasteBoard propertyListForType:PKGPackageComponentPromisedPboardType];
		
		NSArray * tPackageComponentsRepresentations=tDictionary[PKGPackageComponentPromisedPboardTypeRepresentationKey];
		NSMutableArray * tListedComponents=[self.distributionProject.packageComponents mutableCopy];
		NSMutableArray * tNewPackageComponents=[NSMutableArray array];
		
		PKGFilePathConverter * tSourceFilePathConverter=[PKGFilePathConverter new];
		tSourceFilePathConverter.referenceProjectPath=tDictionary[PKGPackageComponentPromisedPboardTypeSourceFilePathConverterReferenceProjectPathKey];
		tSourceFilePathConverter.referenceFolderPath=tDictionary[PKGPackageComponentPromisedPboardTypeSourceFilePathConverterReferenceFolderPathKey];
		
		[tPackageComponentsRepresentations enumerateObjectsUsingBlock:^(NSDictionary * bRepresentation, NSUInteger bIndex, BOOL *bOutStop) {
			
			NSError * tError=nil;
			
			PKGPackageComponent * tPackageComponent=[[PKGPackageComponent alloc] initWithRepresentation:bRepresentation error:&tError];
			
			if (tPackageComponent==nil)
			{
				if (tError!=nil)
				{
					NSLog(@"%@",tError);
					
					// A COMPLETER
				}
				
				*bOutStop=YES;
			}
			
			NSString * tPackageComponentName=tPackageComponent.packageSettings.name;
			
			if ([self.distributionProject.packageComponents indexesOfObjectsPassingTest:^BOOL(PKGPackageComponent * bPackageComponent,NSUInteger bIndex,BOOL * bOutStop){
				
				return ([bPackageComponent.packageSettings.name caseInsensitiveCompare:tPackageComponentName]==NSOrderedSame);
				
			}].count>0)
			{
				NSString * tName=[tListedComponents uniqueNameWithBaseName:tPackageComponentName usingNameExtractor:^NSString *(PKGPackageComponent * bPackageComponent, NSUInteger bIndex) {
					return bPackageComponent.packageSettings.name;
				}];
				
				if (tName==nil)
				{
					// A COMPLETER
					
					*bOutStop=YES;
				}
				
				tPackageComponent.packageSettings.name=tName;
				
				[tListedComponents addObject:tPackageComponent];
			}
			
			[tPackageComponent transformAllPathsUsingSourceConverter:tSourceFilePathConverter destinationConverter:self.filePathConverter];
			
			[tNewPackageComponents addObject:tPackageComponent];
		}];
		
		[self outlineView:inOutlineView addPackageComponents:tNewPackageComponents];
		
		return YES;
	}
	
	return NO;
}

#pragma mark -

- (void)addProjectPackageComponent:(NSOutlineView *)inOutlineView
{
	PKGPackageComponent * tProjectComponent=[PKGPackageComponent projectComponent];
	
	// Name
	
	NSString * tName=[self.distributionProject.packageComponents uniqueNameWithBaseName:NSLocalizedString(@"untitled package",@"No comment") usingNameExtractor:^NSString *(PKGPackageComponent *bPackageComponent,NSUInteger bIndex){
	
		return bPackageComponent.packageSettings.name;
	}];
	
	tProjectComponent.packageSettings.name=(tName==nil)? @"" : tName;
	
	// Identifier
	
	NSArray * tNameComponents=[tProjectComponent.packageSettings.name componentsSeparatedByString:@" "];
	
	NSString * tPackageIdentifier=[tNameComponents componentsJoinedByString:@"-"];
	if (tPackageIdentifier==nil)
		tPackageIdentifier=@"";
	
	NSString * tDefaultIdentifierPrefix=[[PKGProjectTemplateDefaultValuesSettings sharedSettings] valueForKey:PKGProjectTemplateCompanyIdentifierPrefixKey];
	
	if (tDefaultIdentifierPrefix!=nil)
	{
		NSString * tFormat=@"%@%@";
		
		if ([tDefaultIdentifierPrefix hasSuffix:@"."]==NO)
			tFormat=@"%@.%@";
		
		tPackageIdentifier=[NSString stringWithFormat:tFormat,tDefaultIdentifierPrefix,tPackageIdentifier];
	}
	
	tPackageIdentifier=[self.distributionProject.packageComponents uniqueNameWithBaseName:tPackageIdentifier format:@"%@-@lu" options:NSCaseInsensitiveSearch usingNameExtractor:^NSString *(PKGPackageComponent *bPackageComponent,NSUInteger bIndex){
		
		return bPackageComponent.packageSettings.identifier;
	}];
	
	tProjectComponent.packageSettings.identifier=(tPackageIdentifier==nil)? @"" : tPackageIdentifier;
	
	[self outlineView:inOutlineView addPackageComponent:tProjectComponent];
}

- (void)addReferencePackageComponent:(NSOutlineView *)inOutlineView
{
	PKGPackageComponent * tProjectComponent=[PKGPackageComponent referenceComponent];
	
	NSString * tName=[self.distributionProject.packageComponents uniqueNameWithBaseName:NSLocalizedString(@"untitled package",@"No comment") usingNameExtractor:^NSString *(PKGPackageComponent *bPackageComponent,NSUInteger bIndex){
		
		return bPackageComponent.packageSettings.name;
	}];
	
	tProjectComponent.packageSettings.name=(tName==nil)? @"" : tName;
	
	[self outlineView:inOutlineView addPackageComponent:tProjectComponent];
}

- (void)importPackageComponent:(NSOutlineView *)inOutlineView
{
	NSOpenPanel * tImportPanel=[NSOpenPanel openPanel];
	
	tImportPanel.resolvesAliases=YES;
	tImportPanel.canChooseFiles=YES;
	tImportPanel.allowsMultipleSelection=YES;
	tImportPanel.treatsFilePackagesAsDirectories=YES;
	tImportPanel.canCreateDirectories=NO;
	tImportPanel.prompt=NSLocalizedString(@"Import", @"");
	
	NSArray * tImportedPackageComponents=self.distributionProject.importedPackageComponents;
	
	_importPanelDelegate=[PKGPackagesImportPanelDelegate new];
	
	_importPanelDelegate.filePathConverter=self.filePathConverter;
	_importPanelDelegate.importedPackageComponents=tImportedPackageComponents;
	
	tImportPanel.delegate=_importPanelDelegate;
	
	__block PKGFilePathType tReferenceStyle=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
	
	PKGOwnershipAndReferenceStyleViewController * tOwnershipAndReferenceStyleViewController=[PKGOwnershipAndReferenceStyleViewController new];
	
	tOwnershipAndReferenceStyleViewController.canChooseOwnerAndGroupOptions=NO;
	tOwnershipAndReferenceStyleViewController.referenceStyle=tReferenceStyle;
	
	NSView * tAccessoryView=tOwnershipAndReferenceStyleViewController.view;
	
	tImportPanel.accessoryView=tAccessoryView;
	
	[tImportPanel beginSheetModalForWindow:inOutlineView.window completionHandler:^(NSInteger bResult){
		
		if (bResult!=WBFileHandlingPanelOKButton)
			return;
		
		PKGFilePathType tFileType=tOwnershipAndReferenceStyleViewController.referenceStyle;
		
		__block NSMutableArray * tTemporaryComponents=[NSMutableArray arrayWithArray:self.distributionProject.packageComponents];
		
		NSFileManager * tFileManager=[NSFileManager defaultManager];
		
		NSArray * tImportedPackageComponents=[tImportPanel.URLs WB_arrayByMappingObjectsLenientlyUsingBlock:^PKGPackageComponent *(NSURL * bImportURL, NSUInteger bIndex) {
			
			NSString * tAbsolutePath=bImportURL.path;
			BOOL tIsDirectory=NO;
			
			if ([tFileManager fileExistsAtPath:tAbsolutePath isDirectory:&tIsDirectory]==YES && tIsDirectory==YES)	// Exclude directories at this step as we can't disable them when browsing in the open panel
				return nil;
			
			PKGFilePath * tFilePath=[self.filePathConverter filePathForAbsolutePath:tAbsolutePath type:tFileType];
			
			if (tFilePath==nil)
			{
				// A COMPLETER
				
				return nil;
			}
			
			PKGPackageComponent * tPackageComponent=[PKGPackageComponent importedComponentWithFilePath:tFilePath];
			
			NSString * tName=[tTemporaryComponents uniqueNameWithBaseName:[tAbsolutePath.lastPathComponent stringByDeletingPathExtension] usingNameExtractor:^NSString *(PKGPackageComponent * bPackageComponent, NSUInteger bIndex) {
				return bPackageComponent.packageSettings.name;
			}];
			
			tPackageComponent.packageSettings.name=tName;
			
			[tTemporaryComponents addObject:tPackageComponent];
			
			return tPackageComponent;
		}];
		
		[self outlineView:inOutlineView addPackageComponents:tImportedPackageComponents];
	}];
}

- (void)outlineView:(NSOutlineView *)inOutlineView addPackageComponent:(PKGPackageComponent *)inPackageComponent
{
	if (inPackageComponent==nil)
		return;
	
	[self outlineView:inOutlineView addPackageComponents:@[inPackageComponent]];
}

- (void)outlineView:(NSOutlineView *)inOutlineView addPackageComponents:(NSArray *)inPackageComponents
{
	if (inOutlineView==nil || inPackageComponents.count==0)
		return;
	
	[self.distributionProject addPackageComponents:inPackageComponents];
	
	NSMutableSet * tMutableSet=[NSMutableSet set];
	
	for(PKGPackageComponent * tPackageComponent in inPackageComponents)
	{
		[_forest addPackageComponent:tPackageComponent];
		
		[tMutableSet addObject:tPackageComponent];
	}
	
	if (tMutableSet.count==0)
		return;
	
	[self.delegate sourceListDataDidChange:self];
	
	// Post Notification
	
	// A COMPLETER (PKGDistributionProjectDidAddPackageComponentNotification ?)
	
	[inOutlineView reloadData];
	
	NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
	
	for(PKGPackageComponent * tPackageComponent in tMutableSet)
	{
		PKGDistributionProjectSourceListTreeNode * tTreeNode=[_forest treeNodeForPackageComponent:tPackageComponent];
	
		[inOutlineView expandItem:tTreeNode.parent];
	
		NSInteger tSelectedRow=(tTreeNode==nil) ? 0 : [inOutlineView rowForItem:tTreeNode];
	
		if (tSelectedRow==-1)
			tSelectedRow=0;
		
		[tMutableIndexSet addIndex:tSelectedRow];
	}
	
	[inOutlineView scrollRowToVisible:(tMutableIndexSet.firstIndex==NSNotFound) ? 0 : tMutableIndexSet.firstIndex];
	
	[inOutlineView selectRowIndexes:tMutableIndexSet byExtendingSelection:NO];
}

- (id)packageComponentItemMatchingPackageComponent:(PKGPackageComponent *)inPackageComponent
{
	if (inPackageComponent==nil)
		return nil;
	
	return [_forest treeNodeForPackageComponent:inPackageComponent];
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView shouldRenamePackageComponent:(PKGDistributionProjectSourceListTreeNode *)inPackageComponentTreeNode as:(NSString *)inNewName
{
	if (inOutlineView==nil || inPackageComponentTreeNode==nil || inNewName==nil)
		return NO;
	
	PKGPackageComponent * tPackageComponent=((PKGDistributionProjectSourceListPackageComponentItem *) [inPackageComponentTreeNode representedObject]).packageComponent;
	NSString * tName=tPackageComponent.packageSettings.name;
	
	if ([tName compare:inNewName]==NSOrderedSame)
		return NO;
	
	if ([tName caseInsensitiveCompare:inNewName]!=NSOrderedSame)
	{
		NSUInteger tLength=inNewName.length;
		
		if (tLength==0)
		{
			NSIndexSet * tReloadRowIndexes=[NSIndexSet indexSetWithIndex:[inOutlineView rowForItem:inPackageComponentTreeNode]];
			NSIndexSet * tReloadColumnIndexes=[NSIndexSet indexSetWithIndex:[inOutlineView columnWithIdentifier:@"sourcelist.name"]];
			
			[inOutlineView reloadDataForRowIndexes:tReloadRowIndexes columnIndexes:tReloadColumnIndexes];
			
			return NO;
		}
		
		void (^renameAlertBailOut)(NSString *,NSString *) = ^(NSString *bMessageText,NSString *bInformativeText)
		{
			NSAlert * tAlert=[NSAlert new];
			tAlert.alertStyle=WBAlertStyleCritical;
			tAlert.messageText=bMessageText;
			tAlert.informativeText=bInformativeText;
			
			[tAlert beginSheetModalForWindow:inOutlineView.window completionHandler:^(NSModalResponse bResponse){
				
			}];
		};
		
		if (tLength>=256)
		{
			renameAlertBailOut([NSString stringWithFormat:NSLocalizedString(@"The name \"%@\" can't be used.",@""),inNewName],NSLocalizedString(@"Try using a name with fewer characters.",@""));
			
			return NO;
		}
		
		if ([inNewName isEqualToString:@".."]==YES ||
			[inNewName isEqualToString:@"."]==YES ||
			[inNewName rangeOfString:@"/"].location!=NSNotFound)
		{
			renameAlertBailOut([NSString stringWithFormat:NSLocalizedString(@"The name \"%@\" can't be used.",@""),inNewName],NSLocalizedString(@"Try using a name with no punctuation marks.",@""));
			
			return NO;
		}
		
		if ([self.distributionProject.packageComponents indexesOfObjectsPassingTest:^BOOL(PKGPackageComponent * bPackageComponent,NSUInteger bIndex,BOOL * bOutStop){
			
			return ([bPackageComponent.packageSettings.name caseInsensitiveCompare:inNewName]==NSOrderedSame);
			
		}].count>0)
		{
			renameAlertBailOut([NSString stringWithFormat:NSLocalizedString(@"The name \"%@\" is already taken.",@""),inNewName],NSLocalizedString(@"Please choose a different name.",@""));
			
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView renamePackageComponent:(PKGDistributionProjectSourceListTreeNode *)inPackageComponentTreeNode as:(NSString *)inNewName
{
	if (inOutlineView==nil || inPackageComponentTreeNode==nil || inNewName==nil)
		return NO;
	
	PKGPackageComponent * tPackageComponent=((PKGDistributionProjectSourceListPackageComponentItem *) [inPackageComponentTreeNode representedObject]).packageComponent;
	tPackageComponent.packageSettings.name=inNewName;
	
	[inPackageComponentTreeNode.parent sortChildrenUsingComparator:^NSComparisonResult(PKGDistributionProjectSourceListTreeNode * bTreeNode1,PKGDistributionProjectSourceListTreeNode * bTreeNode2){
	
		return [((PKGDistributionProjectSourceListPackageComponentItem *) [bTreeNode1 representedObject]).packageComponent.packageSettings.name caseInsensitiveCompare:((PKGDistributionProjectSourceListPackageComponentItem *) [bTreeNode2 representedObject]).packageComponent.packageSettings.name];
		
	}];
	
	[self.delegate sourceListDataDidChange:self];
	
	[inOutlineView reloadData];
	
	NSInteger tSelectedRow=[inOutlineView rowForItem:inPackageComponentTreeNode];
	
	if (tSelectedRow!=-1)
	{
		[inOutlineView scrollRowToVisible:tSelectedRow];
		[inOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:tSelectedRow] byExtendingSelection:NO];
	}
	
	return YES;
}

- (void)outlineView:(NSOutlineView *)inOutlineView duplicateItems:(NSArray *)inItems
{
	if (inOutlineView==nil || inItems.count==0)
		return;
	
	__block NSMutableArray * tTemporaryComponents=[self.distributionProject.packageComponents mutableCopy];
	
	NSArray * tDuplicatedPackageComponents=[inItems WB_arrayByMappingObjectsLenientlyUsingBlock:^PKGPackageComponent *(PKGDistributionProjectSourceListTreeNode * bSourceListTreeNode, NSUInteger bIndex) {

		PKGDistributionProjectSourceListPackageComponentItem * tPackageComponentItem=[bSourceListTreeNode representedObject];
		
		PKGPackageComponent * tNewPackageComponent=[tPackageComponentItem.packageComponent copy];
		
		// Unique Name
		
		NSString * tBaseName=[tNewPackageComponent.packageSettings.name PKG_baseName];
		
		NSString * tNewName=[tTemporaryComponents uniqueNameWithBaseName:[tBaseName stringByAppendingString:NSLocalizedString(@" copy", @"")]
													  usingNameExtractor:^NSString *(PKGPackageComponent * bPackageComponent, NSUInteger bIndex) {
			return bPackageComponent.packageSettings.name;
		}];
		
		if (tNewName!=nil)
			tNewPackageComponent.packageSettings.name=tNewName;
		
		// Unique Identifier
		
		tBaseName=[tNewPackageComponent.packageSettings.identifier PKG_baseNameWithPattern:@"-[0-9]*$"];
		
		NSString * tNewIdentifier=[tTemporaryComponents uniqueNameWithBaseName:tBaseName format:@"%@-%lu" options:NSCaseInsensitiveSearch usingNameExtractor:^NSString *(PKGPackageComponent *bPackageComponent,NSUInteger bIndex){
			
			return bPackageComponent.packageSettings.identifier;
		}];
		
		if (tNewIdentifier!=nil)
			tNewPackageComponent.packageSettings.identifier=tNewIdentifier;
		

		[tTemporaryComponents addObject:tNewPackageComponent];
		
		return tNewPackageComponent;
	}];
	
	[self outlineView:inOutlineView addPackageComponents:tDuplicatedPackageComponents];
}

- (void)outlineView:(NSOutlineView *)inOutlineView removeItems:(NSArray *)inItems
{
	if (inOutlineView==nil || inItems.count==0)
		return;
	
	// Save the selection if needed
	
	NSArray * tSavedSelectedItems=nil;
	
	if (inItems.count==1)
	{
		if ([inOutlineView isRowSelected:[inOutlineView rowForItem:inItems[0]]]==NO)
			tSavedSelectedItems=[inOutlineView WB_selectedItems];
	}
	
	NSInteger tFirstIndex=[inOutlineView rowForItem:inItems[0]];
	
	
	NSArray * tRemovedPackageComponents=[inItems WB_arrayByMappingObjectsUsingBlock:^id(PKGTreeNode * bTreeNode, NSUInteger bIndex) {
		
		PKGDistributionProjectSourceListPackageComponentItem * tPackageComponentItem=[bTreeNode representedObject];
		
		return tPackageComponentItem.packageComponent;
	}];
	
	[self.distributionProject removePackageComponents:tRemovedPackageComponents];
	
	[_forest removeNodes:inItems];
	
	[self.delegate sourceListDataDidChange:self];
	
	inOutlineView.allowsEmptySelection=YES;
	
	[inOutlineView deselectAll:nil];
	
	[inOutlineView reloadData];
	
	if (tSavedSelectedItems!=nil)
	{
		NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
		
		for(id tItem in tSavedSelectedItems)
		{
			NSInteger tIndex=[inOutlineView rowForItem:tItem];
			
			if (tIndex!=-1)
				[tMutableIndexSet addIndex:tIndex];
		}
		
		[inOutlineView selectRowIndexes:tMutableIndexSet byExtendingSelection:NO];
	}
	
	if (inOutlineView.numberOfSelectedRows==0)
	{
		NSInteger tNewSelectionIndex=tFirstIndex-1;
		
		for(;tNewSelectionIndex>=1;tNewSelectionIndex--)
		{
			PKGDistributionProjectSourceListTreeNode * tTreeNode=[inOutlineView itemAtRow:tNewSelectionIndex];
			
			if (tTreeNode==nil)
				continue;
			
			PKGDistributionProjectSourceListPackageComponentItem * tPackageComponentItem=[tTreeNode representedObject];
			
			if ([tPackageComponentItem isKindOfClass:PKGDistributionProjectSourceListPackageComponentItem.class]==NO)
				continue;
			
			break;
		}
		
		[inOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:tNewSelectionIndex] byExtendingSelection:NO];
	}
	
	inOutlineView.allowsEmptySelection=NO;
	
	// Post Notification to trigger the appropiate cleaning operations in the project
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PKGDistributionProjectDidRemovePackageComponentsNotification object:self.filePathConverter userInfo:@{@"Objects":tRemovedPackageComponents}];
}

@end

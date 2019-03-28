/*
 Copyright (c) 2016-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <AppKit/AppKit.h>

#import "PKGFilePath.h"

extern NSString * const PKGPayloadItemsPboardType;

@class PKGPayloadDataSource;

@protocol PKGPayloadDataSourceDelegate <NSObject>

- (NSMutableDictionary *)disclosedDictionary;

- (void)payloadDataDidChange:(PKGPayloadDataSource *)inPayloadDataSource;

@end

typedef NS_OPTIONS(NSUInteger, PKGPayloadAddOptions)
{
	PKGPayloadAddKeepOwnership = 1 << 0,
	PKGPayloadAddReplaceParents = 1 << 1,
};

typedef NS_OPTIONS(NSUInteger, PKGPayloadExpandOptions)
{
	PKGPayloadExpandKeepOwnership = 1 << 0,
	PKGPayloadExpandRecursively = 1 << 1,
};

typedef NS_OPTIONS(NSUInteger, PKGFileAttributesOptions)
{
	PKGFileAttributesOwnerAndGroup = 1 << 0,
	PKGFileAttributesPOSIXPermissions = 1 << 1,
};

@interface PKGPayloadDataSource : NSObject <NSOutlineViewDataSource>

	@property NSMutableArray * rootNodes;

	@property BOOL editableRootNodes;

	@property id<PKGFilePathConverter> filePathConverter;

	@property (nonatomic,weak) id<PKGPayloadDataSourceDelegate> delegate;

	@property (readonly,nonatomic) PKGFileAttributesOptions managedAttributes;

+ (NSArray *)supportedDraggedTypes;

- (id)itemAtPath:(NSString *)inPath;

- (id)surrogateItemForItem:(id)inItem;

- (NSArray *)siblingsOfItem:(id)inItem;

- (void)outlineView:(NSOutlineView *)inOutlineView reloadDataForItems:(NSArray *)inItems;

- (void)outlineView:(NSOutlineView *)inOutlineView discloseItemIfNeeded:(id)inItem;

- (BOOL)outlineView:(NSOutlineView *)inOutlineView shouldDrawTargetCrossForItem:(id)inItem;

- (BOOL)outlineView:(NSOutlineView *)inOutlineView addFileNames:(NSArray *)inPaths referenceType:(PKGFilePathType)inReferenceType toParents:(NSArray *)inParents options:(PKGPayloadAddOptions)inOptions;

- (BOOL)outlineView:(NSOutlineView *)inOutlineView addItem:(id)inItem toParent:(id)inParent;

- (BOOL)outlineView:(NSOutlineView *)inOutlineView addNewFolderToParent:(id)inParent;

- (BOOL)outlineView:(NSOutlineView *)inOutlineView shouldRenameNewFolder:(id)inNewFolderItem as:(NSString *)inNewName;

- (BOOL)outlineView:(NSOutlineView *)inOutlineView renameItem:(id)inNewFolderItem as:(NSString *)inNewName;

- (void)outlineView:(NSOutlineView *)inOutlineView removeItems:(NSArray *)inItems;

- (void)outlineView:(NSOutlineView *)inOutlineView expandItem:(id)inItem options:(PKGPayloadExpandOptions)inOptions;

- (void)outlineView:(NSOutlineView *)inOutlineView expandAllItemsWithOptions:(PKGPayloadExpandOptions)inOptions;

- (void)outlineView:(NSOutlineView *)inOutlineView contractItem:(id)inItem;

- (void)expandByDefault:(NSOutlineView *)inOutlineView;

- (void)outlineView:(NSOutlineView *)inOutlineView transformItemIfNeeded:(id)inItem;

@end

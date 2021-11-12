/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadTreeNode.h"

@interface PKGPayloadTreeNode (UI)

	@property (nonatomic,readonly,copy) NSString *fileName;

+ (PKGPayloadTreeNode *)newFolderNodeWithParentNode:(PKGPayloadTreeNode *)inParentNode siblings:(NSArray *)inSiblings;

+ (PKGPayloadTreeNode *)newElasticFolderNodeWithParentNode:(PKGPayloadTreeNode *)inParentNode siblings:(NSArray *)inSiblings;

+ (BOOL)validateFolderName:(NSString *)inFolderName;
+ (BOOL)validateElasticFolderName:(NSString *)inElasticFolderName;

- (NSString *)filePathWithSeparator:(NSString *)inSeparator;

- (NSComparisonResult)compareName:(PKGPayloadTreeNode *)inPayloadTreeNode;

- (void)rename:(NSString *)inFolderName;

- (BOOL)isHiddenTemplateNode;
- (BOOL)isTemplateNode;
- (BOOL)isFileSystemItemNode;
- (BOOL)isElasticFolder;
- (BOOL)isExcluded;

- (BOOL)isContentsDisclosed;
- (BOOL)isReferencedItemMissing;

- (BOOL)isSelectableAsInstallationLocation;

@end

@interface PKGPayloadTreeNodeAttributedImage : NSObject

	@property NSImage * image;

	@property CGFloat alpha;

	@property BOOL drawsTargetCross;

	@property BOOL drawsSymbolicLinkArrow;

    @property (getter=isElasticFolder) BOOL elasticFolder;

@end

@interface PKGPayloadTreeNode (PKGFileHierarchy)

	@property (nonatomic,readonly) PKGPayloadTreeNodeAttributedImage * nameAttributedIcon;

	@property (nonatomic,readonly,copy) NSAttributedString * nameAttributedTitle;

	@property (nonatomic,readonly,getter=isNameTitleEditable) BOOL nameTitleEditable;

	@property (nonatomic,readonly,copy) NSString * ownerTitle;

	@property (nonatomic,readonly,copy) NSString * groupTitle;

	@property (nonatomic,readonly,copy) NSString * posixPermissionsTitle;


- (NSString *)referencedPathUsingConverter:(id<PKGFilePathConverter>)inPathConverter;



- (BOOL)needsRefresh:(NSTimeInterval)inTimeMark;

- (void)refreshWithAbsolutePath:(NSString *)inAbsolutePath fileFilters:(NSArray *)inFileFilters;

@end

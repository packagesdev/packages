
#import "PKGPayloadTreeNode.h"

@interface PKGPayloadTreeNode (UI)

	@property (nonatomic,readonly,copy) NSString *filePath;

+ (PKGPayloadTreeNode *)newFolderNodeWithParentNode:(PKGPayloadTreeNode *)inParentNode;

+ (PKGPayloadTreeNode *)newFolderNodeWithSiblingsNodes:(NSArray *)inSiblingsNodes;

+ (NSString *)uniqueFileNameAmongSiblings:(NSArray *)inSiblings;

- (NSComparisonResult)compareName:(PKGPayloadTreeNode *)inPayloadTreeNode;

- (BOOL)isTemplateNode;
- (BOOL)isFileSystemItemNode;


@end

@interface PKGPayloadTreeNode (PKGFileHierarchy)

	@property (nonatomic,readonly) NSImage * nameIcon;

	@property (nonatomic,readonly,copy) NSAttributedString * nameTitle;

	@property (nonatomic,readonly,getter=isNameTitleEditable) BOOL nameTitleEditable;

	@property (nonatomic,readonly,copy) NSString * ownerTitle;

	@property (nonatomic,readonly,copy) NSString * groupTitle;

	@property (nonatomic,readonly,copy) NSString * posixPermissionsTitle;


- (NSString *)referencedPathUsingConverter:(id<PKGFilePathConverter>)inPathConverter;



- (BOOL)needsRefresh:(NSTimeInterval)inTimeMark;

- (void)refreshWithAbsolutePath:(NSString *)inAbsolutePath fileFilters:(NSArray *)inFileFilters;

@end
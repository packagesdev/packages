
#import <AppKit/AppKit.h>

#import "PKGFileItem.h"

@interface _PKGFileItemAuxiliary : NSObject

	@property (readonly) double refreshTimeMark;

	@property (readonly,copy) NSString * referencedItemPath;

	@property (readonly) NSImage * icon;

	@property (readonly,getter=isExcluded) BOOL excluded;

	@property (readonly,getter=isSymbolicLink) BOOL symbolicLink;

	@property (readonly,getter=isReferencedItemMissing) BOOL referencedItemMissing;

	@property (readonly) char fileMode;


+ (NSImage *)cachedIconForTemplateFolderAtPath:(NSString *)inPath enabled:(BOOL)inEnabled;

+ (NSImage *)cachedGenericFolderIcon;

+ (NSImage *)cachedGenericFolderIconDisabled;

- (void)updateWithReferencedItemPath:(NSString *)inPath type:(PKGFileItemType)inType fileFilters:(NSArray *)inFileFilters;

@end

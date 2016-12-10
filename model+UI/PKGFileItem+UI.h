
#import <AppKit/AppKit.h>

#import "PKGFileItem.h"

@interface PKGFileItem (UI)

	@property (nonatomic,readonly) NSTimeInterval refreshTimeMark;

	@property (nonatomic,readonly,copy) NSString *fileName;

	@property (nonatomic,readonly,copy) NSString *referencedItemPath;

	@property (nonatomic,readonly) NSImage * icon;

	@property (nonatomic,readonly) NSImage * disabledIcon;

	@property (nonatomic,getter=isExcluded,readonly) BOOL excluded;

	@property (nonatomic,getter=isSymbolicLink,readonly) BOOL symbolicLink;

	@property (nonatomic,getter=isReferencedItemMissing,readonly) BOOL referencedItemMissing;

	@property (nonatomic,readonly,copy) NSString * posixPermissionsRepresentation;

- (void)refreshAuxiliaryWithAbsolutePath:(NSString *)inAbsolutePath fileFilters:(NSArray *)inFileFilters;

@end

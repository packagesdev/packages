
#import <Foundation/Foundation.h>

#import "PKGRequirementFailureMessage.h"

@class PKGDistributionRequirementMessagesDataSource;

@protocol PKGDistributionRequirementMessagesDataSourceDelegate <NSObject>

- (PKGRequirementFailureMessage *)defaultMessage;

- (void)messagesDataDidChange:(PKGDistributionRequirementMessagesDataSource *)inDataSource;

@end

@interface PKGDistributionRequirementMessagesDataSource : NSObject <NSTableViewDataSource>

	@property (nonatomic) NSMutableDictionary * messages;

	@property (weak) id<PKGDistributionRequirementMessagesDataSourceDelegate> delegate;

- (NSIndexSet *)availableLanguageTagsSet;

- (NSString *)tableView:(NSTableView *)inTableView languageAtRow:(NSInteger)inRow;

- (id)tableView:(NSTableView *)inTableView itemAtRow:(NSInteger)inRow;

- (void)tableView:(NSTableView *)inTableView setLanguageTag:(NSInteger)inLanguageTag forItemAtRow:(NSInteger)inRow;

- (void)tableView:(NSTableView *)inTableView setTitle:(NSString *)inTitle forItemAtRow:(NSInteger)inRow;
- (void)tableView:(NSTableView *)inTableView setDescription:(NSString *)inDescription forItemAtRow:(NSInteger)inRow;

- (void)addNewItem:(NSTableView *)inTableView;

- (void)tableView:(NSTableView *)inTableView removeItemsAtIndexes:(NSIndexSet *)inIndexSet;

@end

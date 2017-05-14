
#import <Foundation/Foundation.h>

@class PKGPresentationLocalizationsDataSource;

@protocol PKGPresentationLocalizationsDataSourceDelegate <NSObject>

- (id)defaultValue;

- (void)localizationsDidChange:(PKGPresentationLocalizationsDataSource *)inDataSource;

@end

@interface PKGPresentationLocalizationsDataSource : NSObject <NSTableViewDataSource>

@property (nonatomic) NSMutableDictionary * localizations;

@property (nonatomic,weak) id<PKGPresentationLocalizationsDataSourceDelegate> delegate;

- (NSIndexSet *)availableLanguageTagsSet;

- (NSString *)tableView:(NSTableView *)inTableView languageAtRow:(NSInteger)inRow;

- (id)tableView:(NSTableView *)inTableView itemAtRow:(NSInteger)inRow;

- (void)tableView:(NSTableView *)inTableView setLanguageTag:(NSInteger)inLanguageTag forItemAtRow:(NSInteger)inRow;
- (void)tableView:(NSTableView *)inTableView setValue:(id)inValue forItemAtRow:(NSInteger)inRow;

- (void)addNewItem:(NSTableView *)inTableView;

- (void)tableView:(NSTableView *)inTableView removeItemsAtIndexes:(NSIndexSet *)inIndexSet;

@end


#import "PKGDistributionRequirementMessagesDataSource.h"

#import "PKGLocalizationUtilities.h"

@interface PKGDistributionRequirementMessagesDataSource ()
{
	NSMutableArray * _cachedLanguages;
}

@end

@implementation PKGDistributionRequirementMessagesDataSource

- (void)setMessages:(NSMutableDictionary *)inMessages
{
	if (_messages!=inMessages)
	{
		_messages=inMessages;
		
		_cachedLanguages=[inMessages.allKeys mutableCopy];
	}
}

#pragma mark -

- (NSIndexSet *)availableLanguageTagsSet
{
	NSArray * tEnglishLanguagesArray=[PKGLocalizationUtilities englishLanguages];
	
	NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, tEnglishLanguagesArray.count)];
	
	[_cachedLanguages enumerateObjectsUsingBlock:^(NSString * bEnglishLanguage, NSUInteger bIndex, BOOL *bOutStop) {
		
		NSUInteger tIndex=[tEnglishLanguagesArray indexOfObject:bEnglishLanguage];
		
		if (tIndex!=NSNotFound)
			[tMutableIndexSet removeIndex:tIndex];
	}];
	
	return [tMutableIndexSet copy];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
	return _cachedLanguages.count;
}

#pragma mark -

- (NSString *)tableView:(NSTableView *)inTableView languageAtRow:(NSInteger)inRow
{
	if (inTableView==nil)
		return nil;
	
	if (inRow<0 || inRow>=_cachedLanguages.count)
		return nil;
	
	return _cachedLanguages[inRow];
}

- (id)tableView:(NSTableView *)inTableView itemAtRow:(NSInteger)inRow
{
	if (inTableView==nil)
		return nil;
	
	if (inRow<0 || inRow>=_cachedLanguages.count)
		return nil;
	
	return self.messages[_cachedLanguages[inRow]];
}

- (void)tableView:(NSTableView *)inTableView setLanguageTag:(NSInteger)inLanguageTag forItemAtRow:(NSInteger)inRow
{
	if (inTableView==nil)
		return;
	
	if (inRow<0 || inRow>=_cachedLanguages.count)
		return;
	
	NSString * tOldLanguageName=_cachedLanguages[inRow];
	NSString * tLanguageName=[PKGLocalizationUtilities englishLanguages][inLanguageTag];
	
	if ([tOldLanguageName isEqualToString:tLanguageName]==YES)
		return;
	
	// Save selection
	
	NSIndexSet * tSelectedRows=inTableView.selectedRowIndexes;
	NSMutableArray * tSelectedLanguages=[[_cachedLanguages objectsAtIndexes:tSelectedRows] mutableCopy];
	
	if ([tSelectedLanguages containsObject:tOldLanguageName]==YES)
	{
		[tSelectedLanguages removeObject:tOldLanguageName];
		[tSelectedLanguages addObject:tLanguageName];
	}
	
	[_cachedLanguages replaceObjectAtIndex:inRow withObject:tLanguageName];
	[_cachedLanguages sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	self.messages[tLanguageName]=self.messages[tOldLanguageName];
	[self.messages removeObjectForKey:tOldLanguageName];
	
	[inTableView reloadData];
	
	[self.delegate messagesDataDidChange:self];
	
	// Restore selection
	
	NSUInteger tIndex=[_cachedLanguages indexOfObject:tLanguageName];
	
	if (tIndex==NSNotFound)
		return;
	
	[inTableView scrollRowToVisible:tIndex];
	
	NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
	
	for(NSString * tSelectedLanguageName in tSelectedLanguages)
	{
		NSUInteger tIndex=[_cachedLanguages indexOfObject:tSelectedLanguageName];
		
		if (tIndex!=NSNotFound)
			[tMutableIndexSet addIndex:tIndex];
	}
	
	[inTableView selectRowIndexes:tMutableIndexSet byExtendingSelection:NO];
}

- (void)tableView:(NSTableView *)inTableView setTitle:(NSString *)inTitle forItemAtRow:(NSInteger)inRow
{
	if (inTableView==nil || inTitle==nil)
		return;
	
	if (inRow<0 || inRow>=_cachedLanguages.count)
		return;
	
	PKGRequirementFailureMessage * tMessage=self.messages[_cachedLanguages[inRow]];
	
	if (tMessage==nil)
		return;
	
	tMessage.messageTitle=inTitle;
	
	[self.delegate messagesDataDidChange:self];
}

- (void)tableView:(NSTableView *)inTableView setDescription:(NSString *)inDescription forItemAtRow:(NSInteger)inRow
{
	if (inTableView==nil || inDescription==nil)
		return;
	
	if (inRow<0 || inRow>=_cachedLanguages.count)
		return;
	
	PKGRequirementFailureMessage * tMessage=self.messages[_cachedLanguages[inRow]];
	
	if (tMessage==nil)
		return;
	
	tMessage.messageDescription=inDescription;
	
	[self.delegate messagesDataDidChange:self];
}

#pragma mark -

- (void)addNewItem:(NSTableView *)inTableView
{
	if (inTableView==nil)
		return;
	
	NSString * tLanguageName=[PKGLocalizationUtilities nextPreferredLanguageAfterLanguages:_cachedLanguages];
	
	if (tLanguageName==nil)
		return;
	
	PKGRequirementFailureMessage * tMessage=[self.delegate defaultMessage];
	
	[_cachedLanguages addObject:tLanguageName];
	
	[_cachedLanguages sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	self.messages[tLanguageName]=tMessage;
	
	[inTableView reloadData];
	
	[self.delegate messagesDataDidChange:self];
	
	NSUInteger tIndex=[_cachedLanguages indexOfObject:tLanguageName];
	
	if (tIndex==NSNotFound)
		return;
	
	[inTableView scrollRowToVisible:tIndex];
	
	[inTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tIndex] byExtendingSelection:NO];
}

- (void)tableView:(NSTableView *)inTableView removeItemsAtIndexes:(NSIndexSet *)inIndexSet
{
	if (inTableView==nil || inIndexSet==nil)
		return;
	
	[inIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex, BOOL *bOutStop) {
		
		NSString * tLanguageKey=_cachedLanguages[bIndex];
		
		[self.messages removeObjectForKey:tLanguageKey];
	}];
	
	[_cachedLanguages removeObjectsAtIndexes:inIndexSet];
	
	[inTableView deselectAll:nil];
	
	[inTableView reloadData];
	
	[self.delegate messagesDataDidChange:self];
}

@end
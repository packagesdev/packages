/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationLocalizationsDataSource.h"

#import "PKGLocalizationUtilities.h"

#import "NSObject+Conformance.h"

@interface PKGPresentationLocalizationsDataSource ()
{
	NSMutableArray * _cachedLanguages;
}

@end

@implementation PKGPresentationLocalizationsDataSource

- (void)setLocalizations:(NSMutableDictionary *)inLocalizations
{
	if (_localizations!=inLocalizations)
		_localizations=inLocalizations;
	
	_cachedLanguages=[_localizations.allKeys mutableCopy];
}

- (void)setDelegate:(id<PKGPresentationLocalizationsDataSourceDelegate>)inDelegate
{
	if (_delegate==inDelegate)
		return;
	
	if (inDelegate==nil)
	{
		_delegate=nil;
		return;
	}
	
	if ([((NSObject *)inDelegate) WB_doesReallyConformToProtocol:@protocol(PKGPresentationLocalizationsDataSourceDelegate)]==NO)
		return;
	
	_delegate=inDelegate;
}

- (NSArray *)allLanguages
{
	return [_cachedLanguages copy];
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

- (NSInteger)tableView:(NSTableView *)inTableView rowForLanguage:(NSString *)inLanguage
{
	if (inLanguage==nil)
		return -1;
	
	NSUInteger tRow=[_cachedLanguages indexOfObject:inLanguage];
	
	if (tRow==NSNotFound)
		return -1;
	
	return tRow;
}

- (id)tableView:(NSTableView *)inTableView itemAtRow:(NSInteger)inRow
{
	if (inTableView==nil)
		return nil;
	
	if (inRow<0 || inRow>=_cachedLanguages.count)
		return nil;
	
	return self.localizations[_cachedLanguages[inRow]];
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
	
	self.localizations[tLanguageName]=self.localizations[tOldLanguageName];
	[self.localizations removeObjectForKey:tOldLanguageName];
	
	[inTableView reloadData];
	
	[self.delegate localizationsDataSource:self localizationsDataDidChange:NO];
	
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

- (void)tableView:(NSTableView *)inTableView setValue:(id)inValue forItemAtRow:(NSInteger)inRow
{
	if (inTableView==nil || inValue==nil)
		return;
	
	if (inRow<0 || inRow>=_cachedLanguages.count)
		return;
	
	self.localizations[_cachedLanguages[inRow]]=inValue;
	
	[inTableView reloadData];
	
	[self.delegate localizationsDataSource:self localizationsDataDidChange:NO];
}

#pragma mark -

- (void)tableView:(NSTableView *)inTableView addValue:(id)inValue forLanguage:(NSString *)inLanguage
{
	if (inTableView==nil || inValue==nil || inLanguage==nil)
		return;
	
	[_cachedLanguages addObject:inLanguage];
	
	[_cachedLanguages sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	self.localizations[inLanguage]=inValue;
	
	[inTableView reloadData];
	
	[self.delegate localizationsDataSource:self localizationsDataDidChange:YES];
	
	NSUInteger tIndex=[_cachedLanguages indexOfObject:inLanguage];
	
	if (tIndex==NSNotFound)
		return;
	
	[inTableView scrollRowToVisible:tIndex];
	
	[inTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tIndex] byExtendingSelection:NO];
}

- (void)tableView:(NSTableView *)inTableView addValues:(NSArray *)inValues forLanguages:(NSArray *)inLanguages
{
	if (inTableView==nil || inValues.count!=inLanguages.count || inValues.count==0)
		return;
	
	[_cachedLanguages addObjectsFromArray:inLanguages];
	
	[_cachedLanguages sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	NSUInteger tCount=inLanguages.count;
	
	for(NSUInteger tIndex=0;tIndex<tCount;tIndex++)
		self.localizations[inLanguages[tIndex]]=inValues[tIndex];
	
	[inTableView reloadData];
	
	[self.delegate localizationsDataSource:self localizationsDataDidChange:YES];
	
	NSMutableIndexSet * tMutableIndexSet=[NSMutableIndexSet indexSet];
	
	for(NSString * tLanguage in inLanguages)
	{
		NSUInteger tIndex=[_cachedLanguages indexOfObject:tLanguage];
		
		if (tIndex==NSNotFound)
			return;
		
		[tMutableIndexSet addIndex:tIndex];
	}
	
	[inTableView scrollRowToVisible:tMutableIndexSet.firstIndex];
	
	[inTableView selectRowIndexes:tMutableIndexSet byExtendingSelection:NO];
}

- (void)addNewItem:(NSTableView *)inTableView
{
	if (inTableView==nil)
		return;
	
	NSString * tLanguage=[PKGLocalizationUtilities nextPreferredLanguageAfterLanguages:_cachedLanguages];
	
	if (tLanguage==nil)
		return;
	
	id tValue=[self.delegate defaultValueForLocalizationsDataSource:self];
	
	[_cachedLanguages addObject:tLanguage];
	
	[_cachedLanguages sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	self.localizations[tLanguage]=tValue;
	
	[inTableView reloadData];
	
	[self.delegate localizationsDataSource:self localizationsDataDidChange:YES];
	
	NSUInteger tIndex=[_cachedLanguages indexOfObject:tLanguage];
	
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
		
		[self.localizations removeObjectForKey:tLanguageKey];
	}];
	
	[_cachedLanguages removeObjectsAtIndexes:inIndexSet];
	
	[inTableView deselectAll:nil];
	
	[inTableView reloadData];
	
	[self.delegate localizationsDataSource:self localizationsDataDidChange:YES];
}

@end

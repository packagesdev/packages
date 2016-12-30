/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGFileFiltersDataSource.h"

#import "PKGFileFilter.h"

@interface PKGFileFiltersDataSource ()

	@property (readwrite) NSMutableArray * filesFilters;

@end

@implementation PKGFileFiltersDataSource

- (instancetype)initWithFileFilters:(NSMutableArray *)inArray
{
	self=[super init];
	
	if (self!=nil)
	{
		_filesFilters=inArray;
	}
	
	return self;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)inTableView
{
	if (inTableView==nil)
		return 0;
	
	return self.filesFilters.count;
}

#pragma mark -

- (id)tableView:(NSTableView *)inTableView itemAtRow:(NSInteger)inRow
{
	if (inTableView==nil)
		return nil;
	
	if (inRow<0 || inRow>=self.filesFilters.count)
		return nil;
	
	return self.filesFilters[inRow];
}

- (NSArray *)tableView:(NSTableView *)inTableView itemsAtRowIndexes:(NSIndexSet *)inIndexSet
{
	if (inTableView==nil || inIndexSet==nil)
		return nil;
	
	if (inIndexSet.lastIndex>=self.filesFilters.count)
		return nil;
	
	return [self.filesFilters objectsAtIndexes:inIndexSet];
}

- (void)tableView:(NSTableView *)inTableView addItem:(PKGFileFilter *)inFileFilter
{
	if (inTableView==nil || inFileFilter==nil)
		return;
	
	[self.filesFilters addObject:inFileFilter];
	
	[inTableView deselectAll:self];
	
	[self.delegate fileFiltersDataDidChange:self];
	
	[inTableView reloadData];
	
	[inTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self.filesFilters.count-1] byExtendingSelection:NO];
}

- (void)tableView:(NSTableView *)inTableView removeItems:(NSArray *)inItems
{
	if (inTableView==nil || inItems==nil)
		return;
	
	[self.filesFilters removeObjectsInArray:inItems];
	
	[inTableView deselectAll:self];
	
	[self.delegate fileFiltersDataDidChange:self];
	
	[inTableView reloadData];
}

@end

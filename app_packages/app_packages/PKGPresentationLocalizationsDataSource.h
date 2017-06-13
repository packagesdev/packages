/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#import "PKGDocument.h"

@class PKGPresentationLocalizationsDataSource;

@protocol PKGPresentationLocalizationsDataSourceDelegate <NSObject>

- (id)defaultValueForLocalizationsDataSource:(PKGPresentationLocalizationsDataSource *)inDataSource;

- (PKGDocument *)document;

- (void)localizationsDataSource:(PKGPresentationLocalizationsDataSource *)inDataSource localizationsDataDidChange:(BOOL)inNumberOfLocalizationsDidChange;

@end

@interface PKGPresentationLocalizationsDataSource : NSObject <NSTableViewDataSource>

	@property (nonatomic) NSMutableDictionary * localizations;

	@property (nonatomic,weak) id<PKGPresentationLocalizationsDataSourceDelegate> delegate;

	@property (readonly) NSArray * allLanguages;

- (NSIndexSet *)availableLanguageTagsSet;

- (NSString *)tableView:(NSTableView *)inTableView languageAtRow:(NSInteger)inRow;

- (NSInteger)tableView:(NSTableView *)inTableView rowForLanguage:(NSString *)inLanguage;

- (id)tableView:(NSTableView *)inTableView itemAtRow:(NSInteger)inRow;

- (void)tableView:(NSTableView *)inTableView setLanguageTag:(NSInteger)inLanguageTag forItemAtRow:(NSInteger)inRow;
- (void)tableView:(NSTableView *)inTableView setValue:(id)inValue forItemAtRow:(NSInteger)inRow;

- (void)tableView:(NSTableView *)inTableView addValue:(id)inValue forLanguage:(NSString *)inLanguage;
- (void)tableView:(NSTableView *)inTableView addValues:(NSArray *)inValues forLanguages:(NSArray *)inLanguages;

- (void)addNewItem:(NSTableView *)inTableView;

- (void)tableView:(NSTableView *)inTableView removeItemsAtIndexes:(NSIndexSet *)inIndexSet;

@end

/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationLocalizationsFilePathDataSource.h"

#import "PKGFilePath.h"

#import "NSFileManager+FileTypes.h"

#import "PKGPresentationLocalizableStepSettings+UI.h"

#import "PKGLocalizationUtilities.h"

#import "PKGApplicationPreferences.h"

#import "PKGOwnershipAndReferenceStylePanel.h"

@implementation PKGPresentationLocalizationsFilePathDataSource

+ (NSArray *)supportedDraggedTypes
{
	return @[NSFilenamesPboardType];
}

- (BOOL)sameFileTypeForAllLocalizations
{
	NSUInteger tCount=self.localizations.count;
	
	if (tCount==0)
		return YES;
	
	__block NSString * tUTITemplate=nil;
	__block BOOL tSameType=YES;
	
	[self.localizations enumerateKeysAndObjectsUsingBlock:^(NSString * bLocalizationKey, PKGFilePath * bFilePath, BOOL *bOutStop) {
		
		if (bFilePath.isSet==NO)
			return;
		
		NSString * tAbsolutePath=[self.delegate.document absolutePathForFilePath:bFilePath];
		
		NSError * tError;
		NSString * tUTIType=[[NSWorkspace sharedWorkspace] typeOfFile:tAbsolutePath error:&tError];
		
		if (tUTIType==nil)
		{
			// A COMPLETER
			
			return;
		}
		
		if (tUTITemplate==nil)
		{
			tUTITemplate=tUTIType;
			return;
		}
		
		if (UTTypeEqual((__bridge CFStringRef) tUTIType,(__bridge CFStringRef) tUTITemplate)==FALSE)
		{
			*bOutStop=YES;
			
			tSameType=NO;
			
			return ;
		}
	}];

	
	return tSameType;
}

#pragma mark - Drag & Drop

- (NSDragOperation)tableView:(NSTableView *)inTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)inRow proposedDropOperation:(NSTableViewDropOperation)inDropOperation
{
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]==nil)
		return NSDragOperationNone;

	NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
	
	NSUInteger tCount=tArray.count;
	
	if (tCount==0)
		return NSDragOperationNone;
	
	if (inDropOperation==NSTableViewDropOn && tCount>1)
		return NSDragOperationNone;
	
	NSFileManager * tFileManager=[NSFileManager defaultManager];
	NSArray * tTextDocumentTypes=[PKGPresentationLocalizableStepSettings textDocumentTypes];
	
	for(NSString * tPath in tArray)
	{
		if ([tFileManager WB_fileAtPath:tPath matchesTypes:tTextDocumentTypes]==NO)
			return NSDragOperationNone;
	}
	
	if (inDropOperation==NSTableViewDropOn)
		return NSDragOperationCopy;
	
	if (tCount>1)
	{
		NSMutableSet * tNewLanguages=[NSMutableSet set];
		
		for(NSString * tPath in tArray)
		{
			NSString * tNewLanguage=[PKGLocalizationUtilities possibleLanguageForFileAtPath:tPath];
		
			if (tNewLanguage==nil)
				return NSDragOperationNone;
			
			if ([tNewLanguages containsObject:tNewLanguage]==YES)
				return NSDragOperationNone;
			
			if ([self.allLanguages containsObject:tNewLanguage]==YES)
				return NSDragOperationNone;
			
			[tNewLanguages addObject:tNewLanguage];
		}
		
		[inTableView setDropRow:-1 dropOperation:NSTableViewDropOn];
		
		return NSDragOperationCopy;
	}
	
	if (self.allLanguages.count==0)
	{
		[inTableView setDropRow:-1 dropOperation:NSTableViewDropOn];
		
		return NSDragOperationCopy;
	}
	
	NSString * tPath=tArray.lastObject;
	
	NSString * tNewLanguage=[PKGLocalizationUtilities possibleLanguageForFileAtPath:tPath];
	
	if (tNewLanguage!=nil)
	{
		NSInteger tRow=[self tableView:inTableView rowForLanguage:tNewLanguage];
		
		if (tRow==-1)
			return NSDragOperationCopy;
		
		[inTableView setDropRow:tRow dropOperation:NSTableViewDropOn];
			
		return NSDragOperationCopy;
	}
	
	// Check that some languages are still not used
	
	if ([PKGLocalizationUtilities nextPreferredLanguageAfterLanguages:self.allLanguages]!=nil)
	{
		[inTableView setDropRow:-1 dropOperation:NSTableViewDropOn];
		
		return NSDragOperationCopy;
	}
	
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)inTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)inRow dropOperation:(NSTableViewDropOperation)inDropOperation
{
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	if ([tPasteBoard availableTypeFromArray:@[NSFilenamesPboardType]]==nil)
		return NO;
	
	NSArray * tArray=(NSArray *) [tPasteBoard propertyListForType:NSFilenamesPboardType];
	
	if (inDropOperation!=NSTableViewDropOn)
		return NO;
	
	if (inRow!=-1)
	{
		NSString * tPath=tArray.lastObject;
		PKGFilePath * tFilePath=[self tableView:inTableView itemAtRow:inRow];
		
		tFilePath=[self.delegate.document filePathForAbsolutePath:tPath type:tFilePath.type];
		
		[self tableView:inTableView setValue:tFilePath forItemAtRow:inRow];
		
		return YES;
	}
	
	if (tArray.count>1)
	{
		if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==NO)
		{
			NSInteger tPathType=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
			
			NSMutableArray * tValues=[NSMutableArray array];
			NSMutableArray * tLanguages=[NSMutableArray array];
			
			for(NSString * tPath in tArray)
			{
				NSString * tLanguage=[PKGLocalizationUtilities possibleLanguageForFileAtPath:tPath];
				
				[tLanguages addObject:tLanguage];
				
				PKGFilePath * tFilePath=[self.delegate.document filePathForAbsolutePath:tPath type:tPathType];
				
				[tValues addObject:tFilePath];
			}
			
			[self tableView:inTableView addValues:tValues forLanguages:tLanguages];
			
			return YES;
		}
		
		PKGOwnershipAndReferenceStylePanel * tPanel=[PKGOwnershipAndReferenceStylePanel ownershipAndReferenceStylePanel];
		
		tPanel.canChooseOwnerAndGroupOptions=NO;
		tPanel.keepOwnerAndGroup=NO;
		tPanel.referenceStyle=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
		
		[tPanel beginSheetModalForWindow:inTableView.window completionHandler:^(NSInteger bReturnCode){
			
			if (bReturnCode==PKGPanelCancelButton)
				return;
			
			NSInteger tPathType=tPanel.referenceStyle;
			
			NSMutableArray * tValues=[NSMutableArray array];
			NSMutableArray * tLanguages=[NSMutableArray array];
			
			for(NSString * tPath in tArray)
			{
				NSString * tLanguage=[PKGLocalizationUtilities possibleLanguageForFileAtPath:tPath];
				
				[tLanguages addObject:tLanguage];
				
				PKGFilePath * tFilePath=[self.delegate.document filePathForAbsolutePath:tPath type:tPathType];
				
				[tValues addObject:tFilePath];
			}
			
			[self tableView:inTableView addValues:tValues forLanguages:tLanguages];
		}];
	}
	
	NSString * tPath=tArray.lastObject;
	
	// Check that some languages are still not used
	
	NSString * tNewLanguage=[PKGLocalizationUtilities possibleLanguageForFileAtPath:tPath];
	
	if (tNewLanguage==nil)
		tNewLanguage=self.delegate.document.registry[PKGDistributionPresentationCurrentPreviewLanguage];
	
	if ([self.allLanguages containsObject:tNewLanguage]==YES)
		tNewLanguage=[PKGLocalizationUtilities nextPreferredLanguageAfterLanguages:self.allLanguages];
	
	if (tNewLanguage==nil)
		return NO;
	
	if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==NO)
	{
		NSInteger tPathType=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
		
		PKGFilePath * tFilePath=[self.delegate.document filePathForAbsolutePath:tPath type:tPathType];
		
		[self tableView:inTableView addValue:tFilePath forLanguage:tNewLanguage];
		
		return YES;
	}
	
	PKGOwnershipAndReferenceStylePanel * tPanel=[PKGOwnershipAndReferenceStylePanel ownershipAndReferenceStylePanel];
	
	tPanel.canChooseOwnerAndGroupOptions=NO;
	tPanel.keepOwnerAndGroup=NO;
	tPanel.referenceStyle=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
	
	[tPanel beginSheetModalForWindow:inTableView.window completionHandler:^(NSInteger bReturnCode){
		
		if (bReturnCode==PKGPanelCancelButton)
			return;
		
		NSInteger tPathType=tPanel.referenceStyle;
		
		PKGFilePath * tFilePath=[self.delegate.document filePathForAbsolutePath:tPath type:tPathType];
		
		[self tableView:inTableView addValue:tFilePath forLanguage:tNewLanguage];
	}];
	
	return YES;
}

@end

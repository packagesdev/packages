/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationSectionTextDocumentViewController.h"

#import "NSFileManager+FileTypes.h"

#import "PKGPresentationStepSettings+UI.h"
#import "PKGPresentationLocalizableStepSettings+UI.h"

#import "PKGApplicationPreferences.h"
#import "PKGOwnershipAndReferenceStylePanel.h"

#import "PKGPresentationSectionTextDocumentViewDropView.h"

@interface PKGPresentationSectionTextDocumentViewController ()
{
	NSString * _cachedDocumentPath;
	
	NSDate * _cachedModificationDate;
	
	IBOutlet PKGPresentationSectionTextDocumentViewDropView * _missingDocumentView;
	IBOutlet NSImageView * _missingIconView;
}

	@property (readwrite) IBOutlet PKGPresentationTextView * textView;

// Notifications

- (void)windowStateDidChange:(NSNotification *)inNotification;

- (void)settingsDidChange:(NSNotification *)inNotification;

@end

@implementation PKGPresentationSectionTextDocumentViewController

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
	
	self.textView.textContainerInset=NSMakeSize(7.0,7.0);
	self.textView.drawsBackground=NO;
	self.textView.enclosingScrollView.drawsBackground=NO;
	
	self.textView.presentationDelegate=self;
	
	[self.textView registerForDraggedTypes:@[NSFilenamesPboardType]];
	
	
	_missingDocumentView.hidden=YES;
	_missingDocumentView.delegate=self;
	
	_missingIconView.image=[NSImage imageNamed:@"MissingFile"];
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[self refreshUIForLocalization:self.localization];
	
	[self viewFrameDidChange:nil];
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	// Register for Notifications
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self.view];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowStateDidChange:) name:NSWindowDidBecomeMainNotification object:self.view.window];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowStateDidChange:) name:NSWindowDidResignMainNotification object:self.view.window];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsDidChange:) name:PKGPresentationStepSettingsDidChangeNotification object:self.settings];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGPresentationStepSettingsDidChangeNotification object:nil];
}

- (void)WB_viewDidDisappear
{
	[super WB_viewDidDisappear];
}

#pragma mark -

- (NSString *)textDocumentPathForLocalization:(NSString *)inLocalization
{
	PKGFilePath * tFilePath=[((PKGPresentationLocalizableStepSettings *)self.settings) valueForLocalization:inLocalization exactMatch:NO];
	
	return [self.filePathConverter absolutePathForFilePath:tFilePath];
}

- (void)setTextDocumentPath:(NSString *)inPath forLocalization:(NSString *)inLocalization
{
	if (inPath==nil || inLocalization==nil)
		return;
	
	PKGFilePath * tFilePath=((PKGPresentationLocalizableStepSettings *)self.settings).localizations[inLocalization];
	
	void (^finalizeSetTextDocumentPath)(PKGFilePath *) = ^(PKGFilePath * bFilePath) {
	
		((PKGPresentationLocalizableStepSettings *)self.settings).localizations[inLocalization]=bFilePath;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:PKGPresentationStepSettingsDidChangeNotification object:self.settings userInfo:@{}];
		
		[self noteDocumentHasChanged];
	};
	
	if (tFilePath!=nil)
	{
		NSString * tAbsolutePath=[self.filePathConverter absolutePathForFilePath:tFilePath];
		
		if ([inPath isEqualToString:tAbsolutePath]==YES)
			return;
		
		tFilePath=[self.filePathConverter filePathForAbsolutePath:inPath type:tFilePath.type];
	}
	else
	{
		if ([PKGApplicationPreferences sharedPreferences].showOwnershipAndReferenceStyleCustomizationDialog==YES)
		{
			PKGOwnershipAndReferenceStylePanel * tPanel=[PKGOwnershipAndReferenceStylePanel ownershipAndReferenceStylePanel];
			
			tPanel.canChooseOwnerAndGroupOptions=NO;
			tPanel.keepOwnerAndGroup=NO;
			tPanel.referenceStyle=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
			
			[tPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger bReturnCode){
				
				if (bReturnCode==PKGPanelCancelButton)
					return;
				
				PKGFilePath * tNewFilePath=[self.filePathConverter filePathForAbsolutePath:inPath type:[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle];
				
				finalizeSetTextDocumentPath(tNewFilePath);
			}];
			
			return;
		}
		
		tFilePath=[self.filePathConverter filePathForAbsolutePath:inPath type:[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle];
	}
	
	finalizeSetTextDocumentPath(tFilePath);
}

#pragma mark -

- (void)refreshUIForLocalization:(NSString *)inLocalization
{
	if (self.textView==nil)
		return;
	
	if (inLocalization==nil || self.settings==nil)
		return;
	
	_cachedDocumentPath=nil;
	_cachedModificationDate=nil;
	
	NSFileManager * tFileManager=[NSFileManager defaultManager];
	
	_cachedDocumentPath=[self textDocumentPathForLocalization:inLocalization];
	
	if (_cachedDocumentPath==nil)
	{
		// A COMPLETER
	
		return;
	}
	
	self.textView.enclosingScrollView.hidden=NO;
	_missingDocumentView.hidden=YES;
	
	if ([tFileManager fileExistsAtPath:_cachedDocumentPath]==NO)
	{
		//_cachedDocumentPath=nil;
		
		_missingDocumentView.hidden=NO;
		self.textView.enclosingScrollView.hidden=YES;
		
		return;
	}
	
	self.textView.string=@"";
	
	NSTextStorage * tTextStorage=self.textView.textStorage;
	
	[tTextStorage beginEditing];
	
	NSURL * tFileURL=[NSURL fileURLWithPath:_cachedDocumentPath];
	NSError * tError=nil;
	
	BOOL tSuccess=[tTextStorage readFromURL:tFileURL
									options:@{NSBaseURLDocumentOption:tFileURL,
											  NSFontAttributeName:[NSFont fontWithName:@"Helvetica" size:12.0]}
						 documentAttributes:nil
									  error:&tError];
	
	[tTextStorage endEditing];
	
	if (tSuccess==YES)
	{
		if (NSAppKitVersionNumber>=NSAppKitVersionNumber10_14)
			[self.textView setTextColor:[NSColor textColor]];
		
		[self.textView scrollRangeToVisible:NSMakeRange(0,1)];
	
		NSDictionary * tAttributesDictionary=[tFileManager attributesOfItemAtPath:_cachedDocumentPath error:NULL];
	
		if (tAttributesDictionary!=nil)
			_cachedModificationDate=tAttributesDictionary[NSFileModificationDate];
	}
	else
	{
		// A COMPLETER
	}
}

#pragma mark - PKGPresentationTextViewDelegate

- (NSDragOperation)presentationTextView:(PKGPresentationTextView *)inPresentationTextView validateDrop:(id <NSDraggingInfo>)info
{
	if (inPresentationTextView!=_textView)
		return NSDragOperationNone;
	
	NSPasteboard * tPasteBoard=[info draggingPasteboard];
	
	if ([[tPasteBoard types] containsObject:NSFilenamesPboardType]==NO)
		return NSDragOperationNone;
	
	NSDragOperation tSourceDragMask=[info draggingSourceOperationMask];
	
	if ((tSourceDragMask & NSDragOperationCopy)==0)
		return NSDragOperationNone;
	
	NSArray * tFiles = [tPasteBoard propertyListForType:NSFilenamesPboardType];
	if (tFiles.count!=1)
		return NSDragOperationNone;
	
	NSString * tFilePath=tFiles.lastObject;
	
	if ([[NSFileManager defaultManager] WB_fileAtPath:tFilePath matchesTypes:[PKGPresentationLocalizableStepSettings textDocumentTypes]]==NO)
		return NSDragOperationNone;
	
	return NSDragOperationCopy;
}

- (BOOL)presentationTextView:(PKGPresentationTextView *)inPresentationTextView acceptDrop:(id <NSDraggingInfo>)info
{
	NSPasteboard * tPasteBoard = [info draggingPasteboard];
	
	if ([[tPasteBoard types] containsObject:NSFilenamesPboardType]==NO)
		return NO;
	
	NSArray * tFiles = [tPasteBoard propertyListForType:NSFilenamesPboardType];
	
	if (tFiles.count!=1)
		return NO;
	
	[self setTextDocumentPath:tFiles.lastObject forLocalization:self.localization];
	
	return YES;
}

#pragma mark - PKGFileDeadDropViewDelegate

- (BOOL)fileDeadDropView:(PKGPresentationSectionTextDocumentViewDropView *)inView validateDropFiles:(NSArray *)inFilenames
{
	if (inFilenames.count!=1)
		return NO;
	
	return [[NSFileManager defaultManager] WB_fileAtPath:inFilenames.lastObject matchesTypes:[PKGPresentationLocalizableStepSettings textDocumentTypes]];
}

- (BOOL)fileDeadDropView:(PKGPresentationSectionTextDocumentViewDropView *)inView acceptDropFiles:(NSArray *)inFilenames
{
	if (inFilenames.count!=1)
		return NO;
	
	[self setTextDocumentPath:inFilenames.lastObject forLocalization:self.localization];
	
	return YES;
}

#pragma mark - Notifications

- (void)windowStateDidChange:(NSNotification *)inNotification
{
	if (_cachedDocumentPath==nil)
		return;
	
	NSFileManager * tFileManager=[NSFileManager defaultManager];
	
	if ([tFileManager fileExistsAtPath:_cachedDocumentPath]==NO)
	{
		[self refreshUIForLocalization:self.localization];
		return;
	}
	
	if (_cachedModificationDate!=nil)
	{
		NSDictionary * tAttributesDictionary=[tFileManager attributesOfItemAtPath:_cachedDocumentPath error:NULL];
		NSDate * tDate=tAttributesDictionary[NSFileModificationDate];
	
		if ([tDate compare:_cachedModificationDate]!=NSOrderedDescending)
			return;
	}
	
	[self refreshUIForLocalization:self.localization];
}

- (void)settingsDidChange:(NSNotification *)inNotification
{
	[self refreshUIForLocalization:self.localization];
}

#pragma mark - Notifications

- (void)viewFrameDidChange:(NSNotification *)inNotification
{
	NSRect tBounds=_missingDocumentView.bounds;
	
	NSRect tFrame=_missingIconView.frame;
	
	tFrame.origin.x=round(NSMidX(tBounds)-NSWidth(tFrame)*0.5);
	tFrame.origin.y=round(NSMidY(tBounds)-NSHeight(tFrame)*0.5);
	
	_missingIconView.frame=tFrame;
}

@end

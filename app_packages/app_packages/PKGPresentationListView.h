/*
Copyright (c) 2007-2010, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Cocoa/Cocoa.h>

@protocol PKGPresentationListViewDelegate;
@protocol PKGPresentationListViewDataSource;

@interface PKGPresentationListView : NSView

	@property (weak) id <PKGPresentationListViewDataSource> dataSource;

	@property (weak) id <PKGPresentationListViewDelegate> delegate;

- (NSInteger)selectedStep;

- (void)selectStep:(NSInteger)inStep;

- (void)reloadData;

@end


@protocol PKGPresentationListViewDataSource <NSObject>

- (NSInteger)numberOfStepsInPresentationListView:(PKGPresentationListView *)inPresentationListView;

- (id)presentationListView:(PKGPresentationListView *)inPresentationListView objectForStep:(NSInteger)inStep;

@optional

// Drag and Drop

- (BOOL)presentationListView:(PKGPresentationListView *)inPresentationListView writeStep:(NSInteger) inStep toPasteboard:(NSPasteboard*) inPasteboard;

- (NSDragOperation)presentationListView:(PKGPresentationListView*)inPresentationListView validateDrop:(id <NSDraggingInfo>)info proposedStep:(NSInteger)inStep;

- (BOOL)presentationListView:(PKGPresentationListView*)inPresentationListView acceptDrop:(id <NSDraggingInfo>)info step:(NSInteger)inStep;

@end


@protocol PKGPresentationListViewDelegate <NSObject>

@optional

- (BOOL)presentationListView:(PKGPresentationListView *)inPresentationListView shouldSelectStep:(NSInteger)inStep;

- (void)presentationListViewSelectionDidChange:(NSNotification *)inNotification;

- (BOOL)presentationListView:(PKGPresentationListView *)inPresentationListView stepWillBeVisible:(NSInteger)inStep;

@end
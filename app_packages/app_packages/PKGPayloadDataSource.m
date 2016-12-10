/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadDataSource.h"

#import "PKGPayloadTreeNode+UI.h"

@implementation PKGPayloadDataSource

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)inOutlineView numberOfChildrenOfItem:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return self.rootNodes.count;
	
	return inTreeNode.numberOfChildren;
}

- (id)outlineView:(NSOutlineView *)inOutlineView child:(NSInteger)inIndex ofItem:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return self.rootNodes[inIndex];
	
	return [inTreeNode descendantNodeAtIndex:inIndex];
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView isItemExpandable:(PKGTreeNode *)inTreeNode
{
	return ([inTreeNode isLeaf]==NO);
}

#pragma mark -

- (BOOL) outlineView:(NSOutlineView *) inOutlineView writeItems:(NSArray*) inItems toPasteboard:(NSPasteboard*)pboard
{
	for(PKGPayloadTreeNode * tPayloadTreeNode in inItems)
	{
		if ([tPayloadTreeNode isTemplateNode]==YES)
			return NO;
	}
	
	// A COMPLETER
	
	return YES;
}

- (NSDragOperation) outlineView:(NSOutlineView*) inOutlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(PKGPayloadTreeNode *) inItem proposedChildIndex:(NSInteger)childIndex
{
	// A COMPLETER
	
	return NSDragOperationCopy;
}

- (BOOL)outlineView:(NSOutlineView*) inOutlineView acceptDrop:(id <NSDraggingInfo>)info item:(PKGPayloadTreeNode *)targetItem childIndex:(NSInteger)childIndex
{
	// A COMPLETER
	
	return YES;
}

@end
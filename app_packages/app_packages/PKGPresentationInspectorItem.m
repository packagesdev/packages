/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationInspectorItem.h"

@interface PKGPresentationInspectorItem ()

	@property (readwrite,copy) NSString * localizedTitle;

	@property (readwrite) PKGPresentationInspectorItemTag tag;

	@property (readwrite) Class viewControllerClass;

	@property (readwrite) Class inspectorViewControllerClass;

@end

@implementation PKGPresentationInspectorItem

+ (NSArray *)inspectorItems
{
	static NSArray * sInspectorItems=nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSMutableArray * tMutableArray=[NSMutableArray array];
		
		// Title
		
		PKGPresentationInspectorItem * tInspectorItem=[PKGPresentationInspectorItem new];
		
		tInspectorItem.localizedTitle=NSLocalizedStringFromTable(@"Title",@"Presentation",@"");
		tInspectorItem.tag=PKGPresentationInspectorItemTitle;
		tInspectorItem.viewControllerClass=NSClassFromString(@"PKGPresentationSectionIntroductionViewController");
		tInspectorItem.inspectorViewControllerClass=NSClassFromString(@"PKGPresentationTitleInspectorViewController");
		
		[tMutableArray addObject:tInspectorItem];
		
		// Background
		
		tInspectorItem=[PKGPresentationInspectorItem new];
		
		tInspectorItem.localizedTitle=NSLocalizedStringFromTable(@"Background",@"Presentation",@"");
		tInspectorItem.tag=PKGPresentationInspectorItemBackground;
		tInspectorItem.viewControllerClass=NSClassFromString(@"PKGPresentationSectionIntroductionViewController");
		tInspectorItem.inspectorViewControllerClass=NSClassFromString(@"PKGPresentationBackgroundInspectorViewController");
		
		[tMutableArray addObject:tInspectorItem];
		
		// Introduction
		
		tInspectorItem=[PKGPresentationInspectorItem new];
		
		tInspectorItem.localizedTitle=NSLocalizedStringFromTable(@"Introduction",@"Presentation",@"");
		tInspectorItem.tag=PKGPresentationInspectorItemIntroduction;
		tInspectorItem.viewControllerClass=NSClassFromString(@"PKGPresentationSectionIntroductionViewController");
		tInspectorItem.inspectorViewControllerClass=NSClassFromString(@"PKGPresentationIntroductionInspectorViewController");
		
		[tMutableArray addObject:tInspectorItem];
		
		// Read Me
		
		tInspectorItem=[PKGPresentationInspectorItem new];
		
		tInspectorItem.localizedTitle=NSLocalizedStringFromTable(@"Read Me",@"Presentation",@"");
		tInspectorItem.tag=PKGPresentationInspectorItemReadMe;
		tInspectorItem.viewControllerClass=NSClassFromString(@"PKGPresentationSectionReadMeViewController");
		tInspectorItem.inspectorViewControllerClass=NSClassFromString(@"PKGPresentationReadMeInspectorViewController");
		
		[tMutableArray addObject:tInspectorItem];
		
		// License
		
		tInspectorItem=[PKGPresentationInspectorItem new];
		
		tInspectorItem.localizedTitle=NSLocalizedStringFromTable(@"License",@"Presentation",@"");
		tInspectorItem.tag=PKGPresentationInspectorItemLicense;
		tInspectorItem.viewControllerClass=NSClassFromString(@"PKGPresentationSectionLicenseViewController");
		tInspectorItem.inspectorViewControllerClass=NSClassFromString(@"PKGPresentationLicenseInspectorViewController");
		
		[tMutableArray addObject:tInspectorItem];
		
		// Installation Type
		
		tInspectorItem=[PKGPresentationInspectorItem new];
		
		tInspectorItem.localizedTitle=NSLocalizedStringFromTable(@"Installation Type",@"Presentation",@"");
		tInspectorItem.tag=PKGPresentationInspectorItemInstallationType;
		tInspectorItem.viewControllerClass=NSClassFromString(@"PKGPresentationSectionInstallationTypeViewController");
		tInspectorItem.inspectorViewControllerClass=NSClassFromString(@"PKGPresentationInstallationTypeInspectorViewController");
		
		[tMutableArray addObject:tInspectorItem];
		
		// Summary
		
		tInspectorItem=[PKGPresentationInspectorItem new];
		
		tInspectorItem.localizedTitle=NSLocalizedStringFromTable(@"Summary",@"Presentation",@"");
		tInspectorItem.tag=PKGPresentationInspectorItemSummary;
		tInspectorItem.viewControllerClass=NSClassFromString(@"PKGPresentationSectionSummaryViewController");
		tInspectorItem.inspectorViewControllerClass=NSClassFromString(@"PKGPresentationSummaryInspectorViewController");
		[tMutableArray addObject:tInspectorItem];
		
		// Plugin
		
		tInspectorItem=[PKGPresentationInspectorItem new];
		
		tInspectorItem.localizedTitle=NSLocalizedStringFromTable(@"Installer Plugin",@"Presentation",@"");
		tInspectorItem.tag=PKGPresentationInspectorItemPlugIn;
		tInspectorItem.viewControllerClass=NSClassFromString(@"PKGPresentationSectionInstallerPluginViewController");
		tInspectorItem.inspectorViewControllerClass=NSClassFromString(@"PKGPresentationInstallerPluginInspectorViewController");
		
		[tMutableArray addObject:tInspectorItem];
		
		sInspectorItems=[tMutableArray copy];
	});
	
	return sInspectorItems;
}

+ (PKGPresentationInspectorItem *)inspectorItemForTag:(PKGPresentationInspectorItemTag) inTag
{
	NSArray * tArray=[PKGPresentationInspectorItem inspectorItems];
	
	NSUInteger tIndex=[tArray indexOfObjectPassingTest:^BOOL(PKGPresentationInspectorItem * bInspectorItem, NSUInteger bIndex, BOOL *bOutStop) {
		return (bInspectorItem.tag==inTag);
	}];
	
	if (tIndex==NSNotFound)
		return nil;
	
	return ((PKGPresentationInspectorItem *)tArray[tIndex]);
}


+ (Class)viewControllerClassForTag:(PKGPresentationInspectorItemTag) inTag
{
	NSArray * tArray=[PKGPresentationInspectorItem inspectorItems];
	
	NSUInteger tIndex=[tArray indexOfObjectPassingTest:^BOOL(PKGPresentationInspectorItem * bInspectorItem, NSUInteger bIndex, BOOL *bOutStop) {
		return (bInspectorItem.tag==inTag);
	}];
	
	if (tIndex==NSNotFound)
		return nil;
	
	return ((PKGPresentationInspectorItem *)tArray[tIndex]).viewControllerClass;
}

+ (Class)inspectorViewControllerClassForTag:(PKGPresentationInspectorItemTag) inTag
{
	NSArray * tArray=[PKGPresentationInspectorItem inspectorItems];
	
	NSUInteger tIndex=[tArray indexOfObjectPassingTest:^BOOL(PKGPresentationInspectorItem * bInspectorItem, NSUInteger bIndex, BOOL *bOutStop) {
		return (bInspectorItem.tag==inTag);
	}];
	
	if (tIndex==NSNotFound)
		return nil;
	
	return ((PKGPresentationInspectorItem *)tArray[tIndex]).inspectorViewControllerClass;
}

+ (PKGPresentationInspectorItemTag)tagForViewControllerClass:(Class)inClass
{
	NSArray * tArray=[PKGPresentationInspectorItem inspectorItems];
	
	NSUInteger tIndex=[tArray indexOfObjectPassingTest:^BOOL(PKGPresentationInspectorItem * bInspectorItem, NSUInteger bIndex, BOOL *bOutStop) {
		return (bInspectorItem.viewControllerClass==inClass);
	}];
	
	if (tIndex==NSNotFound)
		return -1;
	
	return ((PKGPresentationInspectorItem *)tArray[tIndex]).tag;
}

@end

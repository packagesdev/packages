/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionProjectExporter.h"

#import "PKGPackageProject.h"

#import "PKGDistributionProjectSettings+Edition.h"

#import "PKGPackagePayload+Transformation.h"
#import "PKGPackageScriptsAndResources+Transformation.h"

#import "PKGFilePathConverter.h"

@implementation PKGDistributionProjectExporter

- (void)exportPackageComponent:(PKGPackageComponent *)inPackageComponent asPackageProjectAtURL:(NSURL *)inURL completionHandler:(void (^)(BOOL bSuccess))inCompletionHandler
{
	if (self.project==nil || self.projectFilePathConverter==nil)
	{
		return;
	}
	
	if (inPackageComponent==nil || inURL==nil)
	{
		return;
	}
	
	// Operations that need to be done on the main queue
	
	PKGPackageComponent * tPackageComponentCopy=[inPackageComponent copy];
	
	if (tPackageComponentCopy==nil)
	{
		if (inCompletionHandler!=nil)
			inCompletionHandler(NO);
	}
	
	PKGPackageProject * tNewRawPackageProject=[PKGPackageProject new];
	
	tNewRawPackageProject.settings=[((PKGDistributionProjectSettings *)self.project.settings) packageProjectSettings];
	tNewRawPackageProject.comments=[self.project.comments copy];
	
	// Operations that can be dispatched on another queue
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
		
		tNewRawPackageProject.settings.name=tPackageComponentCopy.packageSettings.name;
		tNewRawPackageProject.settings.buildPath=[PKGFilePath filePathWithString:@"build" type:PKGFilePathTypeRelativeToProject];
		
		tNewRawPackageProject.packageSettings=tPackageComponentCopy.packageSettings;
		tNewRawPackageProject.payload=tPackageComponentCopy.payload;
		tNewRawPackageProject.scriptsAndResources=tPackageComponentCopy.scriptsAndResources;

		PKGFilePathConverter * tFilePathConverter=[PKGFilePathConverter new];
		
		tFilePathConverter.referenceProjectPath=inURL.URLByDeletingLastPathComponent.path;
		tFilePathConverter.referenceFolderPath=tNewRawPackageProject.settings.referenceFolderPath;
		if (tFilePathConverter.referenceFolderPath==nil)
			tFilePathConverter.referenceFolderPath=tFilePathConverter.referenceProjectPath;
		
		[tNewRawPackageProject.payload transformAllPathsUsingSourceConverter:self.projectFilePathConverter destinationConverter:tFilePathConverter];
		
		[tNewRawPackageProject.scriptsAndResources transformAllPathsUsingSourceConverter:self.projectFilePathConverter destinationConverter:tFilePathConverter];
		
		// Write to Disk
		
		if ([tNewRawPackageProject writeToURL:inURL atomically:YES]==NO)
		{
			// A COMPLETER
			
			if (inCompletionHandler!=nil)
			{
				dispatch_async(dispatch_get_main_queue(),^{
					inCompletionHandler(NO);
				});
			}
		}
		
		if (inCompletionHandler!=nil)
		{
			dispatch_async(dispatch_get_main_queue(),^{
				inCompletionHandler(YES);
			});
		}
	});
}

@end

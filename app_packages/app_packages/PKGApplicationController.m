/*
Copyright (c) 2007-2016, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGApplicationController.h"

#import "PKGAboutBoxWindowController.h"

#import "PKGPreferencesWindowController.h"

#import "PKGApplicationPreferences.h"

#import "PKGProjectTemplateAssistantWindowController.h"

#import "WBRemoteVersionChecker.h"

@interface PKGApplicationController ()

@end

@implementation PKGApplicationController

- (void) awakeFromNib
{
	// A COMPLETER
}

#pragma mark -

- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *) sender
{
    self.launchedNormally=YES;
		
	if ([PKGApplicationPreferences sharedPreferences].dontShowProjectAssistantOnLaunch==NO)
		[NSApp runModalForWindow:[PKGProjectTemplateAssistantWindowController new].window];
	
	return NO;
}

#pragma mark -

- (IBAction)showAboutBox:(id) sender
{
	[PKGAboutBoxWindowController showAbouxBox];
}

- (IBAction)showPreferences:(id) sender
{
    [PKGPreferencesWindowController showPreferences];
}

- (IBAction)newProject:(id) sender
{
    [NSApp runModalForWindow:[PKGProjectTemplateAssistantWindowController new].window];
}

- (IBAction) showPackageFormatDocumentation:(id) sender
{
    // Try local first
    
    NSURL * tURL=nil;
    
    /*if (NSAppKitVersionNumber>=664.0)
    {
        NSFileManager * tFileManager=[NSFileManager defaultManager];
        
        if ([tFileManager fileExistsAtPath:NSLocalizedString(@"/Developer/Documentation/DeveloperTools/Conceptual/SoftwareDistribution/index.html",@"No comment")]==YES)
        {
            tURL=[NSURL fileURLWithPath:NSLocalizedString(@"/Developer/Documentation/DeveloperTools/Conceptual/SoftwareDistribution/index.html",@"No comment")];
        }
    }
    
    if (tURL==nil)
    {
        tURL=[NSURL URLWithString:NSLocalizedString(@"http://developer.apple.com/documentation/DeveloperTools/Conceptual/SoftwareDistribution/index.html",@"No comment")];
    }
    
    if (tURL!=nil)
    {
        [[NSWorkspace sharedWorkspace] openURL:tURL];
    }*/
}

- (IBAction)showUserGuide:(id) sender
{
	NSURL * tURL=[NSURL URLWithString:NSLocalizedString(@"http://s.sudre.free.fr/Software/documentation/Packages/en/index.html",@"No comment")];
    
    if (tURL!=nil)
		[[NSWorkspace sharedWorkspace] openURL:tURL];

}

- (IBAction)sendFeedback:(id) sender
{
	NSDictionary * tDictionary=[[NSBundle mainBundle] infoDictionary];
	
	NSString * tString=[NSString stringWithFormat:NSLocalizedString(@"mailto:dev.packages@gmail.com?subject=[Packages%%20%@]%%20Feedback%%20(build%%20%@)",@"No comment"),tDictionary[@"CFBundleShortVersionString"],
																																				tDictionary[@"CFBundleVersion"]];
    NSURL * tURL=[NSURL URLWithString:tString];
    
    if (tURL!=nil)
		[[NSWorkspace sharedWorkspace] openURL:tURL];
}

- (IBAction)showPackagesWebSite:(id) sender
{
    NSURL * tURL=[NSURL URLWithString:NSLocalizedString(@"http://s.sudre.free.fr/Software/Packages/about.html",@"No comment")];
    
    if (tURL!=nil)
		[[NSWorkspace sharedWorkspace] openURL:tURL];
}

#pragma mark -

- (NSError *) application:(NSApplication *) inApplication willPresentError:(NSError *) inError
{
	/*if (inError!=nil)
	{
		if ([inError.domain isEqualToString:ICDOCUMENT_ERROR_DOMAIN]==YES)
		{
			NSString * tLocalizedDescription=@"";
			NSString * tLocalizedRecoverySuggestion=@"";
			
			NSDictionary * tUserInfo=inError.userInfo;
			
			NSInteger tCode=inError.code;
			
			switch(tCode)
			{
				case ICDOCUMENT_ERROR_LOAD_VERSION_TOO_NEW:
				
					tLocalizedDescription=[NSString stringWithFormat:NSLocalizedString(@"The document '%@' was created with a newer version of Packages.",@""),[[[tUserInfo[ICDOCUMENT_ERROR_METADATA] path] lastPathComponent] stringByDeletingPathExtension]];
					
					tLocalizedRecoverySuggestion=NSLocalizedString(@"The document can not be opened by this version of Packages.",@"");
					
					break;
				
				case ICDOCUMENT_ERROR_LOAD_INVALID_DOCUMENT:
					
					tLocalizedDescription=[NSString stringWithFormat:NSLocalizedString(@"The document '%@' can not be opened.",@""),[[[tUserInfo[ICDOCUMENT_ERROR_METADATA] path] lastPathComponent] stringByDeletingPathExtension]];
					
					tLocalizedRecoverySuggestion=NSLocalizedString(@"The document is either corrupted or not a Packages document.",@"");
					
					break;
					
				case ICDOCUMENT_ERROR_UNKNOWN_ERROR:
				
					return inError;
			}
			
			NSDictionary * tDictionary=@{NSLocalizedDescriptionKey:tLocalizedDescription,
										 NSLocalizedRecoverySuggestionErrorKey:tLocalizedRecoverySuggestion};
	
			return [NSError errorWithDomain:ICDOCUMENT_ERROR_DOMAIN
									   code:tCode
								   userInfo:tDictionary];
		}
	}*/
	
	return inError;
}

- (void) applicationWillFinishLaunching:(NSNotification *) inNotification
{
	//[ICDocumentController sharedDocumentController];
}

- (void) applicationDidFinishLaunching:(NSNotification *) inNotification
{
	[WBRemoteVersionChecker sharedChecker];
	
	NSArray * tCurrentlyOpenedDocuments=[[NSDocumentController sharedDocumentController] documents];

	if (tCurrentlyOpenedDocuments==nil || [tCurrentlyOpenedDocuments count]==0)
	{
		self.launchedNormally=YES;
		
		/*if ([PKGApplicationPreferences sharedPreferences].dontShowProjectAssistantOnLaunch==NO)
			[[PKGProjectTemplateAssistantWindowController sharedController] createNewProject];*/
	}
}

@end

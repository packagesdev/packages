/*
Copyright (c) 2004-2016, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Foundation/Foundation.h>

#include <sys/types.h>
#include <unistd.h>

#import "PKGCommandLineBuildObserver.h"

#import "PKGBuildOrderManager.h"


void usage(void);

void usage(void)
{
    (void)fprintf(stderr, "%s\n","usage: packagesbuild [-v] [-d] [-F <reference folder>] [-t <temporary build location>] "
                          " file ...");
    
    exit(1);
}

#pragma mark -

int main (int argc, const char * argv[])
{
	@autoreleasepool
	{
		int ch;
		BOOL tVerbose=NO;
		BOOL tDebug=NO;
		char * tCScratchPath=NULL;
		char * tCReferenceFolder=NULL;
		
		// Check the parameters
		
		while ((ch = getopt(argc,(char **) argv,"vd?F:t:")) != -1)
		{
			switch(ch)
			{
				 case 'F':
				
					tCReferenceFolder=optarg;
					
					break;
					
				case 'd':
				
					tDebug=YES;
					
					break;
					
				case 't':
				
					tCScratchPath=optarg;
					
					break;
					
				case 'v':
				
					tVerbose=YES;
					
					break;
					
				case '?':
				default:
					usage();
			}
		}
		
		argv+=optind;
		argc-=optind;
		
		if (argc < 1)
		{
			usage();
			
			exit(EXIT_FAILURE);
		}
		
		NSString * tScratchFolder=nil;
		NSString * tReferenceFolder=nil;
		
		NSFileManager * tFileManager=[NSFileManager defaultManager];
		
		NSString * tCurrentDirectory=[tFileManager currentDirectoryPath];
		
		if (tCScratchPath!=NULL)
		{
			tScratchFolder=[[NSString stringWithUTF8String:tCScratchPath] stringByStandardizingPath];
		
			if ([tScratchFolder characterAtIndex:0]!='/')
				tScratchFolder=[tCurrentDirectory stringByAppendingPathComponent:tScratchFolder];
			
			if ([tFileManager fileExistsAtPath:tScratchFolder]==NO)
			{
			   (void)fprintf(stderr, "Temporary build location \'%s\' does not exist.\n",tCScratchPath);
	
				exit(EXIT_FAILURE);
			}
		}
		
		if (tCReferenceFolder!=NULL)
		{
			tReferenceFolder=[[NSString stringWithUTF8String:tCReferenceFolder] stringByStandardizingPath];
		
			if ([tReferenceFolder characterAtIndex:0]!='/')
				tReferenceFolder=[tCurrentDirectory stringByAppendingPathComponent:tReferenceFolder];
			
			BOOL isDirectory;
			
			if ([tFileManager fileExistsAtPath:tReferenceFolder isDirectory:&isDirectory]==NO)
			{
			   (void)fprintf(stderr, "Reference folder \'%s\' does not exist.\n",tCReferenceFolder);
	
				exit(EXIT_FAILURE);
			}
			
			if (isDirectory==NO)
			{
				(void)fprintf(stderr, "Reference folder path \'%s\' is not a directory.\n",tCReferenceFolder);
	
				exit(EXIT_FAILURE);
			}
		}
		
		NSString * tProjectPath=[[NSString stringWithUTF8String:argv[0]] stringByStandardizingPath];
		
		if ([tProjectPath characterAtIndex:0]!='/')
			tProjectPath=[tCurrentDirectory stringByAppendingPathComponent:tProjectPath];
		
		if ([tFileManager fileExistsAtPath:tProjectPath]==NO)
		{
			(void)fprintf(stderr, "No such file or directory (%s)\n",argv[0]);
			
			exit(EXIT_FAILURE);
		}
	

		NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
		
		if (tReferenceFolder!=nil)
			tMutableDictionary[PKGBuildOrderExternalSettingsReferenceFolderKey]=tReferenceFolder;
		
		if (tScratchFolder!=nil)
			tMutableDictionary[PKGBuildOrderExternalSettingsScratchFolderKey]=tScratchFolder;
		
		// A COMPLETER (gestion des User Defined Settings)
		
		PKGCommandLineBuildObserver * tBuildObserver=[[PKGCommandLineBuildObserver alloc] init];
		tBuildObserver.verbose=tVerbose;
		
		PKGBuildOrder * tBuildOrder=[[PKGBuildOrder alloc] init];
		
		tBuildOrder.projectPath=tProjectPath;
		tBuildOrder.buildOptions=(tDebug==YES) ? PKGBuildOptionsDebugBuild : 0;
		tBuildOrder.externalSettings=[tMutableDictionary copy];
		
		[[PKGBuildOrderManager defaultManager] executeBuildOrder:tBuildOrder
													setupHandler:^(PKGBuildNotificationCenter * bBuildNotificationCenter){
												 
												 // Register for notifications
												 
												 [bBuildNotificationCenter addObserver:tBuildObserver selector:@selector(processBuildEventNotification:) name:PKGBuildEventNotification object:nil];
												 [bBuildNotificationCenter addObserver:tBuildObserver selector:@selector(processBuildDebugNotification:) name:PKGBuildDebugNotification object:nil];
											 }
											   completionHandler:^(PKGBuildResult bResult){
												   
												   if (bResult==PKGBuildResultSuccessful)
													   exit(EXIT_SUCCESS);
												   
												   exit(EXIT_FAILURE);
											   }
									   communicationErrorHandler:^(NSError * bCommunicationError){
										   
										   // A COMPLETER
									   }];
		
		dispatch_main();
	}
	
    return EXIT_FAILURE;
}

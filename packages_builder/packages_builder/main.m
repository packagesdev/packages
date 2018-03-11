/*
Copyright (c) 2008-2016, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Foundation/Foundation.h>

#import "PKGBuildLogger.h"

#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>

#import "PKGPackagesBuilder.h"
#import "PKGProjectBuilder.h"
#import "PKGBuildOrder.h"

int main (int argc, const char * argv[])
{
	@autoreleasepool
	{
		static char optstring[]="i:F:f:u:g:t:s:d";
		int optch;
		
		NSString * tProjectPath=nil;
		NSString * tReferenceFolderPath=nil;
		int64_t tUserID=-1;
        int64_t tGroupID=-1;
		NSString * tScratchPath=nil;
		BOOL tDebug=NO;
		
		NSString * tUUID=nil;
		
		/*int i;		// For debug
		
		for(i=0;i<argc;i++)
		{
			NSLog(@"%s\n",argv[i]);
		}*/
		
		while ((optch = getopt(argc,(char **)argv,optstring))!=-1)
		{
			switch(optch)
			{
				case 'i':
					
					if (argc>3)
						return EXIT_FAILURE;
					
					if (*optarg==0)
					{
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Missing UUID (-i)"];
						return EXIT_FAILURE;
					}
					
					tUUID=[NSString stringWithUTF8String:optarg];
					
					break;
				
				case 'd':
					
					tDebug=YES;
					
					break;
				
				case 'F':
				
					if (*optarg==0)
					{
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Missing reference folder path (-F)"];
						return EXIT_FAILURE;
					}
					
					tReferenceFolderPath=[NSString stringWithUTF8String:optarg];
					break;
				
				case 'f':
				
					if (*optarg==0)
					{
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Missing file path (-f)"];
						return EXIT_FAILURE;
					}
					
					tProjectPath=[NSString stringWithUTF8String:optarg];
					break;
					
				case 'u':
				
					if (*optarg==0)
					{
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Missing User ID (-u)"];
						return EXIT_FAILURE;
					}
				
					tUserID=atoi(optarg);
					break;
					
				case 'g':
				
					if (*optarg==0)
					{
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Missing Group ID (-g)"];
						return EXIT_FAILURE;
					}
					
					tGroupID=atoi(optarg);
					break;
					
				case 't':	// Deprecated parameters. We always use goldin.
				
					break;
					
				case 's':
					
					if (*optarg==0)
					{
						[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Missing Scratch path (-s)"];
						return EXIT_FAILURE;
					}
					
					tScratchPath=[NSString stringWithUTF8String:optarg];
					break;
				
				default:
				
					break;
			}
		}
		
		if (tUUID!=nil)
		{
			PKGPackagesBuilder * tPackagesBuilder=[[PKGPackagesBuilder alloc] initWithUUID:tUUID];
			
			[tPackagesBuilder run];
			
			dispatch_main();
			
			return EXIT_FAILURE;
		}
		
		if (tProjectPath==nil)
		{
			[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Missing file path (-f)"];
			return EXIT_FAILURE;
		}
		
		if (tUserID==-1)
		{
			[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Missing User ID (-u)"];
			return EXIT_FAILURE;
		}
		
		if (tGroupID==-1)
		{
			[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Missing Group ID (-g)"];
			return EXIT_FAILURE;
		}
		
		/* Init Supplemental Groups */
		
		struct passwd * tPasswordPtr=getpwuid((uid_t)tUserID);
		
		if (tPasswordPtr==NULL)
		{
			[[PKGBuildLogger defaultLogger] logMessageWithLevel:PKGLogLevelError format:@"Could not retrieve user name from uid"];
			return EXIT_FAILURE;
		}
		
		initgroups(tPasswordPtr->pw_name, (int)tGroupID);
		
		
		NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
		
		if (tReferenceFolderPath!=nil)
			tMutableDictionary[PKGBuildOrderExternalSettingsReferenceFolderKey]=tReferenceFolderPath;
		
		if (tScratchPath!=nil)
			tMutableDictionary[PKGBuildOrderExternalSettingsScratchFolderKey]=tScratchPath;
		
		PKGBuildOrder * tBuildOrder=[[PKGBuildOrder alloc] init];
		
		tBuildOrder.projectPath=tProjectPath;
		tBuildOrder.buildOptions=(tDebug==YES)? PKGBuildOptionDebugBuild : 0;
		tBuildOrder.externalSettings=[tMutableDictionary copy];
		
		PKGProjectBuilder * tProjectBuilder=[[PKGProjectBuilder alloc] init];
		
		tProjectBuilder.userID=(uid_t)tUserID;
		tProjectBuilder.groupID=(gid_t)tGroupID;
		
		[tProjectBuilder buildProjectOfBuildOrderRepresentation:[tBuildOrder representation]];
		
		dispatch_main();
		
		return EXIT_FAILURE;
	}
    
    return EXIT_SUCCESS;
}

/*
 Copyright (c) 2012-2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#include <getopt.h>

#import "PUUtilities.h"

#include "usage.h"

#define FILE_OPT				"file"
#define HELP_OPT				"help"

#define __PACKAGESUTIL_NAME__	"packagesutil"

#define __PACKAGESUTIL_VERSION__				"2.0"

NSString * checkFile(const char * inFilePath);

NSString * checkFile(const char * inFilePath)
{
	NSString * tProjectFilePath=nil;
	
	if (inFilePath!=NULL)
	{
		char tResolvedPath[PATH_MAX*2];
		
		char * tAbsolutePath=realpath(inFilePath,tResolvedPath);
		
		if (tAbsolutePath!=NULL)
		{
			NSFileManager * tFileManager=[NSFileManager defaultManager];
		
			tProjectFilePath=[tFileManager stringWithFileSystemRepresentation:tResolvedPath length:strlen(tResolvedPath)];
			
			if (tProjectFilePath!=nil)
			{
				BOOL isDirectory;
				
				if ([tFileManager fileExistsAtPath:tProjectFilePath isDirectory:&isDirectory]==YES)
				{
					if (isDirectory==YES)
					{
						// Should be a file
						
						(void)fprintf(stderr, "%s: %s: is a directory\n",__PACKAGESUTIL_NAME__,inFilePath);
						
						tProjectFilePath=nil;
					}
				}
				else
				{
					// File not found
					
					(void)fprintf(stderr, "%s: %s: No such file or directory\n",__PACKAGESUTIL_NAME__,inFilePath);
					
					tProjectFilePath=nil;
				}
			}
			else
			{
				// A COMPLETER
			}
		}
		else
		{
			// Check errno
			
			switch(errno)
			{
				case ENAMETOOLONG:
					
					(void)fprintf(stderr, "%s: Absolute path is too long\n",__PACKAGESUTIL_NAME__);
					
					break;
					
				case ENOENT:
				case ENOTDIR:
					
					(void)fprintf(stderr, "%s: %s: No such file or directory\n",__PACKAGESUTIL_NAME__,inFilePath);
					
					break;
					
				case ENOMEM:
					
					(void)fprintf(stderr, "%s: Memory too low\n",__PACKAGESUTIL_NAME__);
					
					break;
			}
		}

	}
	else
	{
		// Missing file argument
		
		(void)fprintf(stderr, "%s: Missing --file argument\n",__PACKAGESUTIL_NAME__);
		
		usage();
	}
	
	return tProjectFilePath;
}

int main (int argc, const char * argv[])
{
	char * tCFilePath=NULL;
	int tExitResult=1;
	int tHelpOption=0;
	
	static const struct option long_options[]=
	{
		{FILE_OPT, required_argument,NULL,0},
		{HELP_OPT	, no_argument,NULL,0},
		{NULL, 0, NULL, 0} /* End of array need by getopt_long do not delete it*/
	};
	
	while (1)
	{
		int c;
		int option_index = 0;
		const char * tShortOptions="";
		
		c = getopt_long_only(argc, (char * const *) argv, tShortOptions,long_options, &option_index);
		
		if (c== EOF)
		{
			break;
		}
		else if (c==0)
		{
			const char * tOptionName=long_options[option_index].name;
			
			if (strncmp(FILE_OPT,tOptionName,strlen(FILE_OPT))==0)
			{
				tCFilePath=strdup(optarg);
				
				// A COMPLETER
			}
			else if (strncmp(HELP_OPT,tOptionName,strlen(HELP_OPT))==0)
			{
				tHelpOption=1;
			}
		}
	}
	
	if (optind < argc)
    {
		@autoreleasepool
		{
			[[PUUtilities sharedUtilities] setHelpRequired:(tHelpOption==1)];
		
			const char * tVerb=argv[optind];
			
			if (strncmp("set",tVerb,3)==0)
			{
				if (optind==(argc-1))
				{
					if (tHelpOption==1)
					{
						usage_set();
						
						exit(0);
					}
				}
				
				NSString * tProjectFilePath=checkFile(tCFilePath);
				
				free(tCFilePath);
				
				if (tProjectFilePath!=nil || tHelpOption==1)
				{
					NSMutableArray * tMutableArray=nil;
					BOOL tResult;
					
					optind++;
					
					if (optind<argc)
					{
						tMutableArray=[NSMutableArray arrayWithCapacity:argc-optind];
						
						if (tMutableArray!=nil)
						{
							for(int i=optind;i<argc;i++)
							{
								NSString * tArgument=[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding];
								
								if (tArgument==nil)
									tArgument=[NSString stringWithCString:argv[i] encoding:NSUnicodeStringEncoding];
								
								if (tArgument!=nil)
									[tMutableArray addObject:tArgument];
							}
						}
						else
						{
							// A COMPLETER
						}
					}
					
					tResult=[[PUUtilities sharedUtilities] setValue:tMutableArray forFileAtPath:tProjectFilePath];
					
					if (tResult==YES)
						tExitResult=0;
				}
			}
			else if (strncmp("get",tVerb,3)==0)
			{
				if (optind==(argc-1))
				{
					if (tHelpOption==1)
					{
						usage_get();
						
						exit(0);
					}
				}
				
				NSString * tProjectFilePath=checkFile(tCFilePath);
				
				free(tCFilePath);
				
				if (tProjectFilePath!=nil || tHelpOption==1)
				{
					NSMutableArray * tMutableArray=nil;
					BOOL tResult;
					
					optind++;
					
					if (optind<argc)
					{
						tMutableArray=[NSMutableArray arrayWithCapacity:argc-optind];
						
						if (tMutableArray!=nil)
						{
							for(int i=optind;i<argc;i++)
							{
								NSString * tArgument=[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding];
								
								if (tArgument==nil)
									tArgument=[NSString stringWithCString:argv[i] encoding:NSUnicodeStringEncoding];
								
								if (tArgument!=nil)
									[tMutableArray addObject:tArgument];
							}
						}
						else
						{
							// A COMPLETER
						}
					}
					
					tResult=[[PUUtilities sharedUtilities] getValue:tMutableArray forFileAtPath:tProjectFilePath];
					
					if (tResult==YES)
						tExitResult=0;
				}
			}
			else if (strncmp("add",tVerb,3)==0)
			{
				optind++;
				
				if (optind < argc)
				{
					// A COMPLETER
				}
				else
				{
					// A COMPLETER
				}
				
				free(tCFilePath);
			}
			
			else if (strncmp("remove",tVerb,6)==0)
			{
				optind++;
				
				if (optind < argc)
				{
					// A COMPLETER
				}
				else
				{
					// A COMPLETER
				}
				
				free(tCFilePath);
			}
			else if (strncmp("version",tVerb,7)==0)
			{
				optind++;
				
				if (optind < argc)
				{
					usage();
				}
				else
				{
					(void)fprintf(stdout, "%s\n",__PACKAGESUTIL_VERSION__);
					
					tExitResult=0;
				}
				
				free(tCFilePath);
			}
			else
			{
				usage();
				
				tExitResult=1;
				
				free(tCFilePath);
			}
		}
	}
	else
	{
		free(tCFilePath);
        
        if (tHelpOption==1)
			tExitResult=0;
		
		usage();
	}
    
	return tExitResult;
}

/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#include <getopt.h>

#import "BLDComparator.h"

#define EXPECTED_OPT			"expected"
#define HELP_OPT				"help"

NSString * checkDirectoryPath(const char * inDirectoryPath);

NSString * checkDirectoryPath(const char * inDirectoryPath)
{
	NSString * tBuildDirectoryPath=nil;
	
	if (inDirectoryPath!=NULL)
	{
		char tResolvedPath[PATH_MAX*2];
		
		char * tAbsolutePath=realpath(inDirectoryPath,tResolvedPath);
		
		if (tAbsolutePath!=NULL)
		{
			NSFileManager * tFileManager=[NSFileManager defaultManager];
			
			tBuildDirectoryPath=[tFileManager stringWithFileSystemRepresentation:tResolvedPath length:strlen(tResolvedPath)];
			
			if (tBuildDirectoryPath!=nil)
			{
				BOOL isDirectory;
				
				if ([tFileManager fileExistsAtPath:tBuildDirectoryPath isDirectory:&isDirectory]==YES)
				{
					if (isDirectory==NO)
					{
						// Should be a directory
						
						(void)fprintf(stderr, "%s: %s: is not a directory\n",__CMPBUILD_NAME__,inDirectoryPath);
						
						tBuildDirectoryPath=nil;
					}
				}
				else
				{
					// File not found
					
					(void)fprintf(stderr, "%s: %s: No such file or directory\n",__CMPBUILD_NAME__,inDirectoryPath);
					
					tBuildDirectoryPath=nil;
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
					
					(void)fprintf(stderr, "%s: Absolute path is too long\n",__CMPBUILD_NAME__);
					
					break;
					
				case ENOENT:
				case ENOTDIR:
					
					(void)fprintf(stderr, "%s: %s: No such file or directory\n",__CMPBUILD_NAME__,inDirectoryPath);
					
					break;
					
				case ENOMEM:
					
					(void)fprintf(stderr, "%s: Memory too low\n",__CMPBUILD_NAME__);
					
					break;
			}
		}
		
	}
	
	return tBuildDirectoryPath;
}

int main(int argc, const char * argv[])
{
	char * tCExpectedDirectoryPath=NULL;
	int tHelpOption=0;
	
	static const struct option long_options[]=
	{
		{EXPECTED_OPT, required_argument,NULL,0},
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
			
			if (strncmp(EXPECTED_OPT,tOptionName,strlen(EXPECTED_OPT))==0)
			{
				tCExpectedDirectoryPath=strdup(optarg);
			}
			else if (strncmp(HELP_OPT,tOptionName,strlen(HELP_OPT))==0)
			{
				tHelpOption=1;
			}
		}
	}
	
	if (tHelpOption==1)
	{
		[BLDComparator usage];
		return 0;
	}
	
	if (optind==(argc-1) && tCExpectedDirectoryPath!=NULL)
	{
		const char * tCBuildDirectoryPath=argv[optind];
		
		@autoreleasepool
		{
			NSString * tExpectedBuildDirectoryPath=checkDirectoryPath(tCExpectedDirectoryPath);
			
			if (tExpectedBuildDirectoryPath==nil)
				return 1;
			
			free(tCExpectedDirectoryPath);
			
			NSString * tBuildDirectoryPath=checkDirectoryPath(tCBuildDirectoryPath);
			
			if (tBuildDirectoryPath==nil)
				return 1;
			
			// Compare
			
			BLDComparator * tComparator=[[BLDComparator alloc] init];
			tComparator.buildDirectoryPath=tBuildDirectoryPath;
			tComparator.expectedBuildDirectoryPath=tExpectedBuildDirectoryPath;
			
			return ([tComparator compare]==YES) ? 0 : 1;
		}
	}
	else
	{
		[BLDComparator usage];
		return 1;
	}
	
    return 0;
}

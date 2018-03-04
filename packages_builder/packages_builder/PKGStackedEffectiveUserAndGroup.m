/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGStackedEffectiveUserAndGroup.h"

@interface PKGStackedEffectiveUserAndGroup ()
{
	uid_t _savedUserID;
	gid_t _savedGroupID;
}

@end

@implementation PKGStackedEffectiveUserAndGroup

- (instancetype)initWithUserID:(uid_t)inUserID andGroupID:(gid_t)inGroupID
{
	self=[super init];
	
	if (self!=nil)
	{
		_savedUserID=geteuid();
		_savedGroupID=getegid();
		
		if (setegid(inGroupID)==-1)
		{
			int errfound=errno;
			
			fprintf(stdout, "%d",errfound);
		}
		
		if (seteuid(inUserID)==-1)
		{
			fprintf(stdout, "Unable to set the effective user id to %d (%d).\n",inUserID,errno);
			
			exit(EXIT_FAILURE);
		}
		
		
	}
	
	return self;
}

- (void)dealloc
{
	if (seteuid(_savedUserID)==-1)
	{
		fprintf(stdout, "Unable to revert the effective user id to %d.\n",_savedUserID);
		
		exit(EXIT_FAILURE);
	}
	
	setegid(_savedGroupID);
}

@end

/*
Copyright (c) 2008-2010, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGBuildLogger.h"

#ifndef __DEBUG__
#include <asl.h>
#endif


@interface PKGBuildLogger ()
{
#ifndef __DEBUG__
	aslclient client_;
	
	aslmsg message_;
#endif
}

@end

@implementation PKGBuildLogger

+ (PKGBuildLogger *)defaultLogger
{
	static PKGBuildLogger * sLogger=nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sLogger=[[PKGBuildLogger alloc] init];
	});
	
	return sLogger;
}

- (id)init
{
	self=[super init];
	
	if (self!=nil)
	{
	
#ifndef __DEBUG__

		/*client_=asl_open(const char *ident, "fr.whitebox.packages.builder", uint32_t opts);
		
		message_=asl_new(ASL_TYPE_MSG);*/

#endif

	}
	
	return self;
}

- (void) dealloc
{

#ifndef __DEBUG__

	/*asl_free(message_);
	
	asl_close(client_);*/

#endif
}

#pragma mark -

- (void)logMessageWithLevel:(PKGLogLevel)inLevel format:(NSString *) format, ...
{
	va_list ap;
	
	va_start(ap, format);
	
#ifndef __DEBUG__

	NSString * tString;
	
	tString=[[NSString alloc] initWithFormat:format arguments:ap];
	
	if (tString!=nil)
	{
		asl_log(NULL, NULL, inLevel,"%s", [tString UTF8String]);
	}
	/*asl_log(g_asl, log_msg, ASL_LEVEL_ERR, 
"launch_data_new_string(\"" LAUNCH_KEY_CHECKIN "\") Unable to create 
string."); */

#else
	
	NSLogv(format, ap);

#endif

	va_end(ap);
}

@end

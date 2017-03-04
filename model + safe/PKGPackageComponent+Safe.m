/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPackageComponent+Safe.h"

#import "PKGApplicationPreferences.h"

@implementation PKGPackageComponent (Safe)

- (PKGPackagePayload *)payload_safe
{
	if (self.payload==nil)
	{
		NSString * tPath=[[NSBundle mainBundle] pathForResource:@"DefaultFileHierarchy" ofType:@"plist"];
		
		if (tPath==nil)
		{
			NSLog(@"DefaultFileHierachy.plist file not found");
			
			return nil;
		}
		
		NSError * tError=nil;
		NSData * tData=[NSData dataWithContentsOfFile:tPath options:0 error:&tError];
		
		if (tData==nil)
		{
			// A COMPLETER
		}
		
		id tPropertyList=[NSPropertyListSerialization propertyListWithData:tData options:0 format:NULL error:&tError];
		
		if (tPropertyList==nil)
		{
			// A COMPLETER
		}
		
		PKGPackagePayload * tPayload=[[PKGPackagePayload alloc] initWithDefaultHierarchy:tPropertyList error:&tError];
		
		if (tPayload==nil)
		{
			// A COMPLETER
		}
		
		self.payload=tPayload;
	}
	
	return self.payload;
}

- (PKGPackageScriptsAndResources *)scriptsAndResources_safe
{
	if (self.scriptsAndResources==nil)
	{
		PKGPackageScriptsAndResources * tScriptsAndResources=[PKGPackageScriptsAndResources new];
		
		if (tScriptsAndResources==nil)
		{
			// A COMPLETER
			
			return nil;
		}
		
		tScriptsAndResources.preInstallationScriptPath.type=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
		tScriptsAndResources.postInstallationScriptPath.type=[PKGApplicationPreferences sharedPreferences].defaultFilePathReferenceStyle;
		
		self.scriptsAndResources=tScriptsAndResources;
	}
	
	return self.scriptsAndResources;
}

@end

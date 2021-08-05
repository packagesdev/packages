/*
 Copyright (c) 2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGBuildOrderErrorAuditor.h"

NSString * const PKGPackagesDispatcherToolPath=@"/Library/PrivilegedHelperTools/fr.whitebox.packages/packages_dispatcher";

NSString * const PKGPackagesDispatcherLaunchdConfigurationFilePath=@"/Library/LaunchDaemons/fr.whitebox.packages.build.dispatcher.plist";

@implementation PKGBuildOrderErrorAuditor

- (PKGPackagesDispatcherErrorType)dispatcherErrorType
{
	NSFileManager * tFileManager=[NSFileManager defaultManager];
	BOOL tIsDirectory;
	
	// Check whether the packages_dispatcher tool is installed
	
	if ([tFileManager fileExistsAtPath:PKGPackagesDispatcherToolPath isDirectory:&tIsDirectory]==NO || tIsDirectory==YES)
		return PKGPackagesDispatcherErrorPackagesDispatcherNotFound;
	
	// Check whether the fr.whitebox.packages.build.dispatcher.plist is installed
	
	if ([tFileManager fileExistsAtPath:PKGPackagesDispatcherLaunchdConfigurationFilePath isDirectory:&tIsDirectory]==NO || tIsDirectory==YES)
		return PKGPackagesDispatcherErrorLaunchDaemonConfigurationFileNotFound;
	
	// Check the permissions of the the fr.whitebox.packages.build.dispatcher.plist file (-rw-r--r--  root:wheel)
	
	NSDictionary * tAttributes=[tFileManager attributesOfItemAtPath:PKGPackagesDispatcherLaunchdConfigurationFilePath error:NULL];
	
	if (tAttributes!=nil)
	{
		unsigned int tUnixPermissions=[tAttributes[NSFilePosixPermissions] unsignedIntValue];
		
		if (tUnixPermissions!=0644)
			return PKGPackagesDispatcherErrorLaunchDaemonConfigurationFileNotFoundInvalidPermissions;
		
		int tOwner=[tAttributes[NSFileOwnerAccountID] unsignedIntValue];
		int tGroup=[tAttributes[NSFileGroupOwnerAccountID] unsignedIntValue];
		
		if (tOwner!=0 || tGroup!=0)
			return PKGPackagesDispatcherErrorLaunchDaemonConfigurationFileNotFoundInvalidPermissions;
	}
	
	return PKGPackagesDispatcherErrorPackagesDispatcherNotResponding;
}

@end

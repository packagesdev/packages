/*
 Copyright (c) 2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSXPCConnection+RequirementCheck.h"

@interface NSXPCConnection(PrivateAPI)

    @property (nonatomic, readonly) audit_token_t auditToken;

@end

@implementation NSXPCConnection (PKG_RequirementCheck)

- (BOOL)checkValidityWithRequirement:(NSString *)inRequirementString
{
    // Check that the connection is legit (reformated and modified code from https://blog.obdev.at/what-we-have-learned-from-a-vulnerability/)
    
    audit_token_t tAuditToken=self.auditToken;
    
    NSData * tTokenData=[NSData dataWithBytes:&tAuditToken length:sizeof(audit_token_t)];
    NSDictionary * tAttributes=@{
                                 @"audit" : tTokenData      // kSecGuestAttributeAudit is not defined on OS X 10.10 at least
                                 };
    SecCodeRef tCodeRef=NULL;
	
	OSStatus tStatus=SecCodeCopyGuestWithAttributes(NULL, (__bridge CFDictionaryRef)tAttributes, kSecCSDefaultFlags, &tCodeRef);
	
	if (tStatus==errSecCSUnsupportedGuestAttributes)
	{
		tAttributes=@{
					  (__bridge NSString *)kSecGuestAttributePid : @(self.processIdentifier)      // Fall back to process identifier for identification
					  };
		
		
		tStatus=SecCodeCopyGuestWithAttributes(NULL, (__bridge CFDictionaryRef)tAttributes, kSecCSDefaultFlags, &tCodeRef);
	}
	
	if (tStatus!=errSecSuccess)
	{
		return NO;
	}
	
    // Check for hardened runtime flag if running on macOS 10.14 or later
    
    NSProcessInfo * tProcessInfo=[NSProcessInfo processInfo];
    
    if ([tProcessInfo respondsToSelector:@selector(operatingSystemVersionString)]==YES) // Available on 10.9.2 (so if it's not there we're definitely on an OS earlier than 10.14)
    {
        NSOperatingSystemVersion tVersion=tProcessInfo.operatingSystemVersion;
        
        if (tVersion.majorVersion>=10 && tVersion.minorVersion>=14)
        {
            CFDictionaryRef tCodeSigningInformation=NULL;
            if (SecCodeCopySigningInformation(tCodeRef, kSecCSDynamicInformation, &tCodeSigningInformation) != errSecSuccess)
            {
                CFRelease(tCodeRef);
                return NO;
            }
        
            uint32_t csFlags=[((__bridge NSDictionary *)tCodeSigningInformation)[(__bridge NSString *)kSecCodeInfoStatus] intValue];
            CFRelease(tCodeSigningInformation);
            
            if ((csFlags & kSecCodeSignatureRuntime) != kSecCodeSignatureRuntime)
            {
                CFRelease(tCodeRef);
                
                return NO;
            }
		}
    }
    
    SecRequirementRef tRequirement=NULL;
    
    if (SecRequirementCreateWithString((__bridge CFStringRef)inRequirementString, kSecCSDefaultFlags, &tRequirement) != errSecSuccess)
    {
        CFRelease(tCodeRef);
        
        return NO;
    }
    
    tStatus=SecCodeCheckValidityWithErrors(tCodeRef, kSecCSDefaultFlags, tRequirement, NULL);
    CFRelease(tCodeRef);
    CFRelease(tRequirement);
    
    return (tStatus == errSecSuccess);
}

@end

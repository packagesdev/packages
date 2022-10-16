/*
Copyright (c) 2004-2022, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGCertificatesUtilities.h"

#import "NSArray+WBExtensions.h"

NSString * const PKGLoginKeychainPath=@"~/Library/Keychains/login.keychain";

@implementation PKGCertificatesUtilities

+ (NSArray *)availableCertificates
{
	NSDictionary * tQueryDictionary=@{(id)kSecClass:(id)kSecClassCertificate,
									  (id)kSecMatchSubjectStartsWith:@"Developer ID Installer:",
									  (id)kSecReturnRef:@(YES),
									  (id)kSecMatchLimit:(id)kSecMatchLimitAll};
	
	CFArrayRef tResults=NULL;
	
	OSStatus tStatus=SecItemCopyMatching((__bridge CFDictionaryRef)tQueryDictionary, (CFTypeRef *)&tResults);
	
	if (tStatus!=errSecSuccess)
	{
		NSString * tErrorString=(__bridge_transfer NSString *)SecCopyErrorMessageString(tStatus, NULL);
		
		NSLog(@"SecItemCopyMatching failed: %@",tErrorString);
		
		return [NSArray array];
	}
	
	if (tResults==NULL)
		return [NSArray array];
	
	return (__bridge_transfer NSArray *)tResults;
}

+ (NSArray *)availableIdentities
{
	NSDictionary * tQueryDictionary=@{(id)kSecClass:(id)kSecClassIdentity,
									  (id)kSecMatchSubjectStartsWith:@"Developer ID Installer:",
									  (id)kSecAttrCanSign:@(YES),
									  (id)kSecReturnRef:@(YES),
									  (id)kSecMatchLimit:(id)kSecMatchLimitAll};
	
	CFArrayRef tResults=NULL;
	
	OSStatus tStatus=SecItemCopyMatching((__bridge CFDictionaryRef)tQueryDictionary, (CFTypeRef *)&tResults);
	
	if (tStatus!=errSecSuccess)
	{
		NSString * tErrorString=(__bridge_transfer NSString *)SecCopyErrorMessageString(tStatus, NULL);
		
		NSLog(@"SecItemCopyMatching failed: %@",tErrorString);
		
		return [NSArray array];
	}
	
	if (tResults==NULL)
		return [NSArray array];
	
	return (__bridge_transfer NSArray *)tResults;
}

+ (SecCertificateRef)copyOfCertificateWithName:(NSString *)inName isExpired:(BOOL *)outExpired
{
    OSStatus tStatus=0;
    
    if (outExpired!=NULL)
        *outExpired=NO;
    
    SecIdentityRef tIdentityRef=[PKGCertificatesUtilities identityWithName:inName atPath:nil options:PKGCertificateSearchNonExpired error:&tStatus];
	
	if (tIdentityRef==NULL)
    {
        switch(tStatus)
        {
            case errSecItemNotFound:    // There might an identity with an expired certificate.
                
                tIdentityRef=[PKGCertificatesUtilities identityWithName:inName atPath:nil options:0 error:&tStatus];
                
                if (tIdentityRef!=NULL && outExpired!=NULL)
                    *outExpired=YES;
                
                break;
        }
        
        if (tIdentityRef==NULL)
            return NULL;
    }
    
	SecCertificateRef tCertificateRef=NULL;
	SecIdentityCopyCertificate(tIdentityRef,&tCertificateRef);
	
	return tCertificateRef;
}

+ (SecCertificateRef)certificateWithName:(NSString *)inName atPath:(NSString *)inPath options:(PKGCertificateSearchOptions)inOptions error:(OSStatus *)outError
{
	if (inName.length==0)
	{
		if (outError!=NULL)
			*outError=0;
		
		return NULL;
	}
	
	NSArray * tKeychainPaths=((inPath!=nil) ? @[inPath] : nil);
	
	NSArray * tSecKeychainArray=[tKeychainPaths WB_arrayByMappingObjectsLenientlyUsingBlock:^id(NSString * bKeychainPath,NSUInteger bIndex){
		
		SecKeychainRef tKeyChainRef=NULL;
		
		OSStatus tStatus=SecKeychainOpen(inPath.fileSystemRepresentation,&tKeyChainRef);
		
		if (tStatus!=errSecSuccess)
		{
			NSLog(@"SecKeychainOpen error:%ld",(long)tStatus);
			
			return nil;
		}
		
		return (__bridge id)tKeyChainRef;   // A TESTER: It probably needs a transfer or to release the ref later.
	}];
	
	NSMutableDictionary * tQueryDictionary=[@{(id)kSecClass:(id)kSecClassCertificate,
											  (id)kSecMatchSubjectWholeString:inName,
											  (id)kSecReturnRef:@(YES),
											  (id)kSecMatchLimit:(id)kSecMatchLimitOne} mutableCopy];
	
	if (tSecKeychainArray.count>0)
		tQueryDictionary[(id)kSecMatchSearchList]=tSecKeychainArray;
	
	if ((inOptions & PKGCertificateSearchNonExpired)!=0)
        tQueryDictionary[(id)kSecMatchValidOnDate]=[NSDate date];
    
	SecCertificateRef tResult=NULL;
	
	OSStatus tStatus=SecItemCopyMatching((__bridge CFDictionaryRef)tQueryDictionary, (CFTypeRef *)&tResult);
	
	if (outError!=NULL)
		*outError=tStatus;
	
	return tResult;
}

+ (SecIdentityRef)identityWithName:(NSString *)inName atPath:(NSString *)inPath options:(PKGCertificateSearchOptions)inOptions  error:(OSStatus *)outError;
{
	if (inName.length==0)
	{
		if (outError!=NULL)
			*outError=0;
		
		return NULL;
	}
	
	NSArray * tKeychainPaths=((inPath!=nil) ? @[inPath] : nil);
	
	NSArray * tSecKeychainArray=[tKeychainPaths WB_arrayByMappingObjectsLenientlyUsingBlock:^id(NSString * bKeychainPath,NSUInteger bIndex){
	
		SecKeychainRef tKeyChainRef=NULL;
		
		OSStatus tStatus=SecKeychainOpen(inPath.fileSystemRepresentation,&tKeyChainRef);
			
		if (tStatus!=errSecSuccess)
		{
			NSLog(@"SecKeychainOpen error:%ld",(long)tStatus);
			
			return nil;
		}
		
        return (__bridge id)tKeyChainRef;   // A TESTER: It probably needs a transfer or to release the ref later.
	}];
	
	NSMutableDictionary * tQueryDictionary=[@{(id)kSecClass:(id)kSecClassIdentity,
											  (id)kSecMatchSubjectWholeString:inName,
											  (id)kSecAttrCanSign:@(YES),
											  (id)kSecReturnRef:@(YES),
											  (id)kSecMatchLimit:(id)kSecMatchLimitOne} mutableCopy];
	
	if (tSecKeychainArray.count>0)
		tQueryDictionary[(__bridge NSString *)kSecMatchSearchList]=tSecKeychainArray;
	
    if ((inOptions & PKGCertificateSearchNonExpired)!=0)
        tQueryDictionary[(id)kSecMatchValidOnDate]=[NSDate date];
    
	SecIdentityRef tResult=NULL;
	
	OSStatus tStatus=SecItemCopyMatching((__bridge CFDictionaryRef)tQueryDictionary, (CFTypeRef *)&tResult);
	
	if (outError!=NULL)
		*outError=tStatus;
	
	return tResult;
}

+ (SecIdentityRef)identityWithName:(NSString *)inName atPath:(NSString *)inPath error:(PKGCertificateErrorCode *)outErrorCode
{
    if (outErrorCode!=NULL)
        *outErrorCode=0;
    
    if (inName.length==0 || (inPath!=nil && inPath.length==0))
    {
        if (outErrorCode!=NULL)
            *outErrorCode=PKGCertificateErrorInvalidParameters;
        
        return NULL;
    }
    
    OSStatus tError=0;
    
    // Try to find a valid identity (i.e. not expired and with a private key)
    
    SecIdentityRef tSecIdentityRef=[PKGCertificatesUtilities identityWithName:inName atPath:inPath options:PKGCertificateSearchNonExpired error:&tError];
    
    if (tSecIdentityRef!=NULL)
        return tSecIdentityRef;
    
    // Do we have a non expired identity without a private key?
    
    tError=0;
    
    SecCertificateRef tCertificateRef=[PKGCertificatesUtilities certificateWithName:inName atPath:inPath options:PKGCertificateSearchNonExpired error:&tError];
    
    if (tCertificateRef!=NULL)
    {
        // Missing Private key
        
        if (outErrorCode!=NULL)
            *outErrorCode=PKGCertificateErrorMissingPrivateKey;
        
        return NULL;
    }
    
    // Do we have an expired identity?
    
    tError=0;
    
    tSecIdentityRef=[PKGCertificatesUtilities identityWithName:inName atPath:inPath options:0 error:&tError];
    
    if (tSecIdentityRef!=NULL)
    {
        // Expired certificate
        
        if (outErrorCode!=NULL)
            *outErrorCode=PKGCertificateErrorExpiredCertificate;
        
        return NULL;
    }
    
    tCertificateRef=[PKGCertificatesUtilities certificateWithName:inName atPath:inPath options:0 error:&tError];
    
    if (tCertificateRef!=NULL)
    {
        // Expired certificate and Missing Private key
        
        if (outErrorCode!=NULL)
            *outErrorCode=PKGCertificateErrorExpiredCertificate;
        
        return NULL;
    }
    
    // Missing Identity and certificate
    
    if (outErrorCode!=NULL)
        *outErrorCode=PKGCertificateErrorMissingCertificate;
    
    return NULL;
}

@end

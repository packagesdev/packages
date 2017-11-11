/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGBuildDataSigner.h"

#import "PKGCertificatesUtilities.h"

@interface PKGBuildDataSigner ()
{
	dispatch_queue_t _signingQueue;
}

@end

@implementation PKGBuildDataSigner

+ (PKGBuildDataSigner *)sharedSigner
{
	static PKGBuildDataSigner * sDataSigner=nil;
	
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sDataSigner=[[PKGBuildDataSigner alloc] init];
	});
	
	return sDataSigner;
}

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_signingQueue=dispatch_queue_create("", DISPATCH_QUEUE_SERIAL);
	}
	
	return self;
}

#pragma mark - PKGSignatureCreatorInterface

- (void)createSignatureForData:(NSData *)inInputData usingIdentity:(NSString *)inIdentityName keychain:(NSString *)inKeychainpath replyHandler:(void(^)(PKGSignatureStatus bStatus,NSData * bSignedData))inReply
{
	if (inReply==nil)
		return;
	
	if (inInputData==nil || inIdentityName==nil)
	{
		inReply(PKGSignatureStatusErrorUnknown,nil);
		return;
	}
	
	SecIdentityRef tSecIdentityRef=[PKGCertificatesUtilities identityWithName:inIdentityName atPath:[PKGLoginKeychainPath stringByExpandingTildeInPath]];
	
	if (tSecIdentityRef==NULL && inKeychainpath!=nil)
		tSecIdentityRef=[PKGCertificatesUtilities identityWithName:inIdentityName atPath:inKeychainpath];
	
	if (tSecIdentityRef==NULL)
	{
		inReply(PKGSignatureStatusIdentityNotFound,nil);
		return;
	}
	
	SecKeyRef tPrivateKeyRef=NULL;
	
	OSStatus tStatus=SecIdentityCopyPrivateKey(tSecIdentityRef, &tPrivateKeyRef);
	
	CFRelease(tSecIdentityRef);
	
	if (tStatus!=errSecSuccess)
	{
		NSString * tErrorString=(__bridge_transfer NSString *)SecCopyErrorMessageString(tStatus,NULL);
		
		NSLog(@"%@",tErrorString);
		
		CFRelease(tPrivateKeyRef);
		
		inReply(PKGSignatureStatusErrorUnknown,nil);
		return;
	}
	
	dispatch_async(_signingQueue, ^{
	
		CFErrorRef tErrorRef=NULL;
		
		SecTransformRef tTransformRef=SecSignTransformCreate(tPrivateKeyRef, &tErrorRef);
		
		if (tTransformRef==NULL)
		{
			CFRelease(tPrivateKeyRef);
			
			if (tErrorRef!=NULL)
			{
				NSString * tErrorDescription=(__bridge_transfer NSString *)CFErrorCopyDescription(tErrorRef);
				
				NSLog(@"%@",tErrorDescription);
				
				CFRelease(tErrorRef);
			}
			
			inReply(PKGSignatureStatusErrorUnknown,nil);
			return;
		}
		
		if (SecTransformSetAttribute(tTransformRef,kSecInputIsAttributeName,kSecInputIsDigest,&tErrorRef)==FALSE)
		{
			CFRelease(tTransformRef);
			CFRelease(tPrivateKeyRef);
			
			if (tErrorRef!=NULL)
			{
				NSString * tErrorDescription=(__bridge_transfer NSString *)CFErrorCopyDescription(tErrorRef);
				
				NSLog(@"%@",tErrorDescription);
				
				CFRelease(tErrorRef);
			}
			
			inReply(PKGSignatureStatusErrorUnknown,nil);
			return;
		}
		
		if (SecTransformSetAttribute(tTransformRef,kSecTransformInputAttributeName, (__bridge CFDataRef)inInputData,&tErrorRef)==FALSE)
		{
			CFRelease(tTransformRef);
			CFRelease(tPrivateKeyRef);
			
			if (tErrorRef!=NULL)
			{
				NSString * tErrorDescription=(__bridge_transfer NSString *)CFErrorCopyDescription(tErrorRef);
				
				NSLog(@"%@",tErrorDescription);
				
				CFRelease(tErrorRef);
			}
			
			inReply(PKGSignatureStatusErrorUnknown,nil);
			return;
		}
		
		CFTypeRef tTypeRef=SecTransformExecute(tTransformRef, &tErrorRef);
		
		if (tTypeRef==NULL)
		{
			CFRelease(tTransformRef);
			CFRelease(tPrivateKeyRef);
			
			if (tErrorRef!=NULL)
			{
				//NSString * tErrorDomain=(__bridge NSString *) CFErrorGetDomain(tErrorRef);
				CFIndex tErrorCode=CSSM_ERRCODE(CFErrorGetCode(tErrorRef));
				
				switch(tErrorCode)
				{
					case CSSM_ERRCODE_OPERATION_AUTH_DENIED:
						
						inReply(PKGSignatureStatusKeychainAccessDenied,nil);
						return;
						
					// A COMPLETER
						
					default:
					{
						NSString * tErrorDescription=(__bridge_transfer NSString *)CFErrorCopyDescription(tErrorRef);
						
						NSLog(@"%@",tErrorDescription);
					
						break;
					}
				}
				
				
				
				CFRelease(tErrorRef);
			}
			
			inReply(PKGSignatureStatusErrorUnknown,nil);
			return;
		}
		
		inReply(PKGSignatureStatusSuccess,(__bridge_transfer NSData *)tTypeRef);
		
		CFRelease(tTransformRef);
		CFRelease(tPrivateKeyRef);
	});
}

@end

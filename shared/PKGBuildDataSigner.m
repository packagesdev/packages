/*
 Copyright (c) 2016-2022, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGBuildDataSigner.h"

#import "PKGCertificatesUtilities.h"

/* From
 
   SecCmsBase.h: https://opensource.apple.com/source/libsecurity_smime/libsecurity_smime-24739/lib/SecCmsBase.h.auto.html
   CMSPrivate.h: https://opensource.apple.com/source/Security/Security-55179.13/libsecurity_cms/lib/CMSPrivate.h.auto.html
 
 */

#define PKGCFCoreFoundationVersionNumber11_0_1   1770.106

typedef struct SecCmsMessageStr *SecCmsMessageRef;

extern OSStatus CMSEncoderGetCmsMessage(CMSEncoderRef cmsEncoder,SecCmsMessageRef *cmsMessage);
extern CFMutableDictionaryRef SecCmsTSAGetDefaultContext(CFErrorRef *error);
extern void CmsMessageSetTSAContext(CMSEncoderRef cmsEncoder, CFTypeRef tsaContext);

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



- (void)createSignatureOfType:(PKGSignatureType)inSignatureType forData:(NSData *)inInputData usingIdentity:(NSString *)inIdentityName keychain:(NSString *)inKeychainPath replyHandler:(void(^)(PKGSignatureStatus bStatus,NSData * bSignedData))inReply
{
	[self createSignatureOfType:inSignatureType forData:inInputData usingIdentity:inIdentityName keychain:inKeychainPath useTSA:NO replyHandler:inReply];
}

- (void)createSignatureOfType:(PKGSignatureType)inSignatureType forData:(NSData *)inInputData usingIdentity:(NSString *)inIdentityName keychain:(NSString *)inKeychainPath useTSA:(BOOL)inUseTSA replyHandler:(void(^)(PKGSignatureStatus bStatus,NSData * bSignedData))inReply
{
	if (inReply==nil)
		return;
	
	if (inInputData==nil || inIdentityName==nil)
	{
		inReply(PKGSignatureStatusErrorUnknown,nil);
		return;
	}
	
	OSStatus tIdentityError=0;
	
	SecIdentityRef tSecIdentityRef=[PKGCertificatesUtilities identityWithName:inIdentityName atPath:[PKGLoginKeychainPath stringByExpandingTildeInPath] error:&tIdentityError];
	
	if (tSecIdentityRef==NULL && inKeychainPath!=nil)
	{
		tIdentityError=0;
		
		tSecIdentityRef=[PKGCertificatesUtilities identityWithName:inIdentityName atPath:inKeychainPath error:&tIdentityError];
	}
	
	if (tSecIdentityRef==NULL)
	{
		NSLog(@"identityWithName:atPath:error: error code (%d)",tIdentityError);
		
		inReply(PKGSignatureStatusIdentityNotFound,nil);
		return;
	}
	
	SecKeyRef tPrivateKeyRef=NULL;
	
	if (inSignatureType==PKGSignatureRSA)
	{
		OSStatus tStatus=SecIdentityCopyPrivateKey(tSecIdentityRef, &tPrivateKeyRef);
	
		if (tStatus!=errSecSuccess)
		{
			CFRelease(tSecIdentityRef);
			
			NSString * tErrorString=(__bridge_transfer NSString *)SecCopyErrorMessageString(tStatus,NULL);
			
			NSLog(@"SecIdentityCopyPrivateKey: %@",tErrorString);
			
			CFRelease(tPrivateKeyRef);
			
			inReply(PKGSignatureStatusErrorUnknown,nil);
			return;
		}
		
		CFRelease(tSecIdentityRef);
	}
	
	dispatch_async(_signingQueue, ^{
	
		if (inSignatureType==PKGSignatureRSA)
		{
			CFErrorRef tErrorRef=NULL;
			
			SecTransformRef tTransformRef=SecSignTransformCreate(tPrivateKeyRef, &tErrorRef);
			
			if (tTransformRef==NULL)
			{
				CFRelease(tPrivateKeyRef);
				
				if (tErrorRef!=NULL)
				{
					NSString * tErrorDescription=(__bridge_transfer NSString *)CFErrorCopyDescription(tErrorRef);
					
					NSLog(@"SecSignTransformCreate: %@",tErrorDescription);
					
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
					
					NSLog(@"SecTransformSetAttribute (kSecInputIsAttributeName): %@",tErrorDescription);
					
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
					
					NSLog(@"SecTransformSetAttribute (kSecTransformInputAttributeName): %@",tErrorDescription);
					
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
							
							NSLog(@"SecTransformExecute: %@",tErrorDescription);
						
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
		}
		else if (inSignatureType==PKGSignatureCMS)
		{
			CMSEncoderRef tEncoderRef;
			
			OSStatus tStatus=CMSEncoderCreate(&tEncoderRef);
			
			if (tStatus!=errSecSuccess)
			{
				CFRelease(tSecIdentityRef);
				
				NSLog(@"CMSEncoderCreate: %@",(__bridge_transfer NSString *)SecCopyErrorMessageString(tStatus,NULL));
				
				inReply(PKGSignatureStatusErrorUnknown,nil);
				
				return;
			}
			
			tStatus=CMSEncoderAddSigners(tEncoderRef,tSecIdentityRef);
			
			CFRelease(tSecIdentityRef);
			
			if (tStatus!=errSecSuccess)
			{
				CFRelease(tEncoderRef);
				
				NSLog(@"CMSEncoderAddSigners: %@",(__bridge_transfer NSString *)SecCopyErrorMessageString(tStatus,NULL));
				
				inReply(PKGSignatureStatusErrorUnknown,nil);
				
				return;
			}

			tStatus=CMSEncoderSetHasDetachedContent(tEncoderRef,true);
			
			if (tStatus!=errSecSuccess)
			{
				CFRelease(tEncoderRef);
				
				NSLog(@"CMSEncoderSetHasDetachedContent: %@",(__bridge_transfer NSString *)SecCopyErrorMessageString(tStatus,NULL));
				
				inReply(PKGSignatureStatusErrorUnknown,nil);
				
				return;
			}
			
			tStatus=CMSEncoderSetCertificateChainMode(tEncoderRef,kCMSCertificateChainWithRoot);
			
			if (tStatus!=errSecSuccess)
			{
				CFRelease(tEncoderRef);
				
				NSLog(@"CMSEncoderSetCertificateChainMode: %@",(__bridge_transfer NSString *)SecCopyErrorMessageString(tStatus,NULL));
				
				inReply(PKGSignatureStatusErrorUnknown,nil);
				
				return;
			}
			
            // Only run this code on macOS BS and later
            
            if (kCFCoreFoundationVersionNumber>=PKGCFCoreFoundationVersionNumber11_0_1)
            {
                tStatus=CMSEncoderAddSignedAttributes(tEncoderRef, kCMSAttrSigningTime);
            
                if (tStatus!=errSecSuccess)
                {
                    CFRelease(tEncoderRef);
                
                    NSLog(@"CMSEncoderAddSignedAttributes: %@",(__bridge_transfer NSString *)SecCopyErrorMessageString(tStatus,NULL));
                
                    inReply(PKGSignatureStatusErrorUnknown,nil);
                
                    return;
                }
            }
            
			if (inUseTSA==YES)
			{
				CFMutableDictionaryRef tTSAContextDictionaryRef=SecCmsTSAGetDefaultContext(NULL);
				
				SecCmsMessageRef tMessageRef=NULL;

				tStatus=CMSEncoderGetCmsMessage(tEncoderRef, &tMessageRef);
				
				if (tMessageRef != NULL)
					CmsMessageSetTSAContext(tEncoderRef,tTSAContextDictionaryRef);
			}
			
			tStatus=CMSEncoderUpdateContent(tEncoderRef, inInputData.bytes, inInputData.length);
			
			if (tStatus!=errSecSuccess)
			{
				CFRelease(tEncoderRef);
				
				NSLog(@"CMSEncoderUpdateContent: %@",(__bridge_transfer NSString *)SecCopyErrorMessageString(tStatus,NULL));
				
				inReply(PKGSignatureStatusErrorUnknown,nil);
				
				return;
			}
			
			CFDataRef tEncodedDataRef;
			
			tStatus=CMSEncoderCopyEncodedContent(tEncoderRef, &tEncodedDataRef);
			
			if (tStatus!=errSecSuccess)
			{
				CFRelease(tEncoderRef);
				
				PKGSignatureStatus tSignatureStatus=PKGSignatureStatusErrorUnknown;
				
				switch(tStatus)
				{
					case errSecTimestampServiceNotAvailable:
						
						tSignatureStatus=PKGSignatureStatusTimestampServiceNotAvailable;
						
						break;
						
					default:
						
						NSLog(@"CMSEncoderCopyEncodedContent: %@",(__bridge_transfer NSString *)SecCopyErrorMessageString(tStatus,NULL));
						
						break;
				}
				
				inReply(tSignatureStatus,nil);
				
				return;
			}
			
			inReply(PKGSignatureStatusSuccess,(__bridge_transfer NSData *)tEncodedDataRef);
		}
	});
}

@end

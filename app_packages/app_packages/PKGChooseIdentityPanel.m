/*
 Copyright (c) 2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGChooseIdentityPanel.h"

#import "PKGCertificatesUtilities.h"

#import <SecurityInterface/SFChooseIdentityPanel.h>

@interface PKGChooseIdentityPanel ()
{
	SFChooseIdentityPanel * _chooseIdentityPanel;
}

	@property (readwrite,copy) NSString * identity;

@end

@implementation PKGChooseIdentityPanel

- (void)sheetDidEnd:(NSAlert *)alert returnCode:(NSInteger)inReturnCode contextInfo:(void *)contextInfo
{
	void(^handler)(NSInteger) = (__bridge_transfer void(^)(NSInteger)) contextInfo;
	
	if (handler!=nil)
	{
		if (inReturnCode!=WBModalResponseOK)
		{
			handler(WBModalResponseCancel);
			return;
		}
		
		SecIdentityRef tIdentityRef=[_chooseIdentityPanel identity];
		
		if (tIdentityRef==NULL)
		{
			// A COMPLETER
			
			/*handler(NSAlertErrorReturn);
			
			return;*/
		}
		
		SecCertificateRef tCertificateRef;
		OSStatus tStatus=SecIdentityCopyCertificate(tIdentityRef,&tCertificateRef);
		
		if (tStatus!=noErr)
		{
			// A COMPLETER
			
			/*handler(NSAlertErrorReturn);
			
			return;*/
		}
		
		CFStringRef tCertificateNameRef;
		
		if (SecCertificateCopyCommonName(tCertificateRef, &tCertificateNameRef)!=errSecSuccess)
		{
			NSBeep();
			
			CFRelease(tCertificateRef);
			
			NSAlert * tAlert=[NSAlert new];
			
			tAlert.alertStyle=WBAlertStyleWarning;
			
			tAlert.messageText=NSLocalizedString(@"The Identity of the certificate could not be retrieved.",@"No comment");
			tAlert.informativeText=NSLocalizedString(@"Packages will keep using the previous certificate set.",@"No comment");
			
			[tAlert runModal];
			
			handler(NSAlertErrorReturn);
			
			return;
		}
		
		self.identity=(__bridge_transfer NSString *)tCertificateNameRef;
		
		handler(WBModalResponseOK);
		
		// Release Memory
		
		CFRelease(tCertificateRef);
	}
}

- (BOOL)beginSheetModalForWindow:(NSWindow *)sheetWindow completionHandler:(void (^)(NSInteger bReturnCode))handler
{
	self.identity=nil;
	
	NSArray * tIdentitiesArray=[PKGCertificatesUtilities availableIdentities];
	
	if (tIdentitiesArray.count==0)
	{
		NSArray * tCertificatesArray=[PKGCertificatesUtilities availableCertificates];
		
		NSAlert * tAlert=[NSAlert new];
		
		[tAlert addButtonWithTitle:NSLocalizedString(@"OK",@"No Comment")];
		
		if (tCertificatesArray.count==0)
		{
			tAlert.messageText=NSLocalizedString(@"No certificates Alert Message Text",@"");
			tAlert.informativeText=NSLocalizedString(@"No certificates Alert Informative Text",@"");
			
			[tAlert addButtonWithTitle:NSLocalizedString(@"Go to Apple Developer website",@"No Comment")];
		}
		else
		{
			if (tCertificatesArray.count==1)
			{
				SecCertificateRef tCertificateRef=(__bridge SecCertificateRef)tCertificatesArray.firstObject;
				
				CFStringRef tCommonNameRef=NULL;
				
				OSStatus tStatus=SecCertificateCopyCommonName(tCertificateRef,&tCommonNameRef);
				
				if (tStatus!=errSecSuccess)
				{
					NSLog(@"Could not obtain the Certificate Common Name (%d)",(int)tStatus);
					
					tAlert.messageText=NSLocalizedString(@"No signing certificate Alert Message Text",@"");
				}
				else
				{
					tAlert.messageText=[NSString stringWithFormat: NSLocalizedString(@"The \"%@\" certificate available in the Keychain can not be used to sign a package or flat distribution.",@""),(__bridge NSString *)tCommonNameRef];
					
					CFRelease(tCommonNameRef);
				}
				
				tAlert.informativeText=NSLocalizedString(@"There is no private key associated to this certificate.",@"");
			}
			else
			{
				tAlert.messageText=NSLocalizedString(@"No signing certificates Alert Message Text",@"");
				tAlert.informativeText=NSLocalizedString(@"There are no private keys associated to these certificates.",@"");
			}
		}
		
		[tAlert beginSheetModalForWindow:sheetWindow completionHandler:^(NSModalResponse bResponse){
			
			if (bResponse==NSAlertSecondButtonReturn)
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"url.apple.developer.website.certificates",@"")]];
		}];
		
		return NO;
	}
	
	_chooseIdentityPanel=[SFChooseIdentityPanel new];
	
	[_chooseIdentityPanel setInformativeText:self.informativeText];
	
	[_chooseIdentityPanel setAlternateButtonTitle:NSLocalizedString(@"Cancel",@"")];
	
	[_chooseIdentityPanel beginSheetForWindow:sheetWindow
								modalDelegate:self
							   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
								  contextInfo:(__bridge_retained void*)[handler copy]
								   identities:tIdentitiesArray
									  message:self.messageText];
	
	return YES;
}

- (NSInteger)runModal
{
	NSArray * tIdentitiesArray=[PKGCertificatesUtilities availableIdentities];
	
	if (tIdentitiesArray.count==0)
	{
		NSArray * tCertificatesArray=[PKGCertificatesUtilities availableCertificates];
		
		NSAlert * tAlert=[NSAlert new];
		
		[tAlert addButtonWithTitle:NSLocalizedString(@"OK",@"No Comment")];
		
		if (tCertificatesArray.count==0)
		{
			tAlert.messageText=NSLocalizedString(@"No certificates Alert Message Text",@"");
			tAlert.informativeText=NSLocalizedString(@"No certificates Alert Informative Text",@"");
			
			[tAlert addButtonWithTitle:NSLocalizedString(@"Go to Apple Developer website",@"No Comment")];
		}
		else
		{
			if (tCertificatesArray.count==1)
			{
				SecCertificateRef tCertificateRef=(__bridge SecCertificateRef)tCertificatesArray.firstObject;
				
				CFStringRef tCommonNameRef=NULL;
				
				OSStatus tStatus=SecCertificateCopyCommonName(tCertificateRef,&tCommonNameRef);
				
				if (tStatus!=errSecSuccess)
				{
					NSLog(@"Could not obtain the Certificate Common Name (%d)",(int)tStatus);
					
					tAlert.messageText=NSLocalizedString(@"No signing certificate Alert Message Text",@"");
				}
				else
				{
					tAlert.messageText=[NSString stringWithFormat: NSLocalizedString(@"The \"%@\" certificate available in the Keychain can not be used to sign a package or flat distribution.",@""),(__bridge NSString *)tCommonNameRef];
					
					CFRelease(tCommonNameRef);
				}
				
				tAlert.informativeText=NSLocalizedString(@"There is no private key associated to this certificate.",@"");
			}
			else
			{
				tAlert.messageText=NSLocalizedString(@"No signing certificates Alert Message Text",@"");
				tAlert.informativeText=NSLocalizedString(@"There are no private keys associated to these certificates.",@"");
			}
		}
		
		NSModalResponse tResponse=[tAlert runModal];
		
		if (tResponse==NSAlertSecondButtonReturn)
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"url.apple.developer.website.certificates",@"")]];
		
		return NSAlertErrorReturn;
	}
	
	_chooseIdentityPanel=[SFChooseIdentityPanel new];
	
	[_chooseIdentityPanel setInformativeText:self.informativeText];
	
	[_chooseIdentityPanel setAlternateButtonTitle:NSLocalizedString(@"Cancel",@"")];
	
	NSInteger tResult=[_chooseIdentityPanel runModalForIdentities:tIdentitiesArray message:self.messageText];
	
	if (tResult!=WBModalResponseOK)
		return tResult;
	
	SecIdentityRef tIdentityRef=[_chooseIdentityPanel identity];
	
	if (tIdentityRef==NULL)
	{
		// A COMPLETER
		
		//return NSAlertErrorReturn;
	}
	
	SecCertificateRef tCertificateRef;
	OSStatus tStatus=SecIdentityCopyCertificate(tIdentityRef,&tCertificateRef);
	
	if (tStatus!=noErr)
	{
		// A COMPLETER
		
		//return NSAlertErrorReturn;
	}
	
	CFStringRef tCertificateNameRef;
	
	if (SecCertificateCopyCommonName(tCertificateRef, &tCertificateNameRef)!=errSecSuccess)
	{
		NSBeep();
		
		CFRelease(tCertificateRef);
		
		NSAlert * tAlert=[NSAlert new];
		
		tAlert.alertStyle=WBAlertStyleWarning;
		
		tAlert.messageText=NSLocalizedString(@"The Identity of the certificate could not be retrieved.",@"No comment");
		tAlert.informativeText=NSLocalizedString(@"Packages will keep using the previous certificate set.",@"No comment");
		
		[tAlert runModal];
		
		return NSAlertErrorReturn;
	}
	
	self.identity=(__bridge_transfer NSString *)tCertificateNameRef;
	
	// Release Memory
	
	CFRelease(tCertificateRef);
	
	return WBModalResponseOK;
}

@end


#import "PKGCertificateSealWindowController.h"

#import "PKGCertificateSealView.h"

#import "PKGCertificatePanel.h"

@interface PKGCertificateSealWindowController ()
{
	IBOutlet PKGCertificateSealView * _sealView;
}

- (IBAction)showCertificate:(id)sender;

@end

@implementation PKGCertificateSealWindowController

- (void)dealloc
{
	if (_certificate!=NULL)
		CFRelease(_certificate);
}

- (NSString *)windowNibName
{
	return @"PKGCertificateSealWindowController";
}

- (void)awakeFromNib
{
	self.window.backgroundColor=[NSColor clearColor];
	
	self.window.opaque=NO;
}

#pragma mark -

- (void)setCertificate:(SecCertificateRef)inCertificate
{
	if (_certificate!=inCertificate)
	{
		if (_certificate!=NULL)
			CFRelease(_certificate);
		
		_certificate=(SecCertificateRef) CFRetain(inCertificate);
	}
}

#pragma mark -

- (IBAction)showCertificate:(id)sender
{
	PKGCertificatePanel * tCertificatePanel=[PKGCertificatePanel certificatePanel];
	
	tCertificatePanel.certificate=self.certificate;
	
	[tCertificatePanel beginSheetModalForWindow:self.window.parentWindow completionHandler:nil];
}

@end

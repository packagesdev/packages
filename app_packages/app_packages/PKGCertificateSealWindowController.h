
#import <Cocoa/Cocoa.h>

#import <Security/Security.h>

@interface PKGCertificateSealWindowController : NSWindowController

	@property (nonatomic) SecCertificateRef certificate;

@end

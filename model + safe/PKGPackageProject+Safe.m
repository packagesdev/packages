
#import "PKGPackageProject+Safe.h"

@implementation PKGPackageProject (Safe)

- (PKGPackagePayload *)payload_safe
{
	if (self.payload==nil)
	{
		NSString * tPath=[[NSBundle mainBundle] pathForResource:@"DefaultFileHierachy" ofType:@"plist"];
		
		if (tPath==nil)
		{
			// A COMPLETER
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

@end

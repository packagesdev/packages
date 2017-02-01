
#import "PKGPackageProject+Safe.h"

#import "PKGApplicationPreferences.h"

@implementation PKGPackageProject (Safe)

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

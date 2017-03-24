
#import "PKGDistributionProjectSettingsAdvancedOptionsList.h"

NSString * const PKGDistributionProjectSettingsAdvancedOptionsListSupportsAdvancedEditorKey=@"ADVANCED_EDITOR";
NSString * const PKGDistributionProjectSettingsAdvancedOptionsListAdvancedEditorDescriptionKey=@"EDITOR";


@interface PKGDistributionProjectSettingsAdvancedOptionsList ()
{
	BOOL _supportsAdvancedEditor;
}

@end

@implementation PKGDistributionProjectSettingsAdvancedOptionsList

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	NSError * tError=nil;
	
	self=[super initWithRepresentation:inRepresentation error:&tError];
	
	if (self==nil)
	{
		if (outError!=NULL)
			*outError=tError;
	}
	
	NSNumber * tNumber=inRepresentation[PKGDistributionProjectSettingsAdvancedOptionsListSupportsAdvancedEditorKey];
	
	if (tNumber!=nil)
	{
		if ([tNumber isKindOfClass:NSNumber.class]==NO)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidTypeOfValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGDistributionProjectSettingsAdvancedOptionsListSupportsAdvancedEditorKey}];
			
			return nil;
		}
		
		_supportsAdvancedEditor=[tNumber boolValue];
	}
	else
	{
		_supportsAdvancedEditor=NO;
	}
	
	if (_supportsAdvancedEditor==YES)
	{
		NSDictionary * tDictionary=inRepresentation[PKGDistributionProjectSettingsAdvancedOptionsListAdvancedEditorDescriptionKey];
	
		if (tDictionary==nil)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGFileURLNilError
										  userInfo:nil];
			
			return nil;
		}
		
		if ([tDictionary isKindOfClass:NSDictionary.class]==NO)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidTypeOfValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGDistributionProjectSettingsAdvancedOptionsListAdvancedEditorDescriptionKey}];
			
			return nil;
		}
		
		// A COMPLETER
	}
	
	return self;
}

#pragma mark -

- (BOOL)supportsAdvancedEditor
{
	return _supportsAdvancedEditor;
}

@end

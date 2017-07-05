
#import "PKGProjectTemplateDefaultValuesSettings.h"

#import <AddressBook/AddressBook.h>

#import "NSArray+Reverse.h"

NSString * const PKGProjectTemplateDefaultValueSettingsKey=@"template.keywords";

NSString * const PKGProjectTemplateCompanyNameKey=@"company.name";

NSString * const PKGProjectTemplateCompanyIdentifierPrefixKey=@"company.identifier.prefix";



@interface PKGProjectTemplateDefaultValuesSettings ()
{
	NSMutableDictionary * _defaultValues;
}

@property (readwrite) NSArray * allKeys;

+ (NSString *)_defaultCompanyName;

+ (NSArray *)_commonISPDomainName;
+ (NSString *)_defaultPackageIdentifierPrefix;

@end

@implementation PKGProjectTemplateDefaultValuesSettings

+ (PKGProjectTemplateDefaultValuesSettings *)sharedSettings
{
	static dispatch_once_t onceToken;
	static PKGProjectTemplateDefaultValuesSettings * sSettings=nil;
	
	dispatch_once(&onceToken, ^{
		
		sSettings=[PKGProjectTemplateDefaultValuesSettings new];
	});
	
	return sSettings;
}


+ (NSString *)_defaultCompanyName
{
	static NSString * const PKGProjectTemplateCompanyNameDefaultValue=@"My Great Company";
	
	ABPerson * tMe=[[ABAddressBook sharedAddressBook] me];
		
	if (tMe!=nil)
	{
		NSString * tCompanyProperty=(NSString *) [tMe valueForProperty:kABOrganizationProperty];
		
		if ([tCompanyProperty length]>0)
			return tCompanyProperty;
	}
	
	return PKGProjectTemplateCompanyNameDefaultValue;
}

+ (NSArray *)_commonISPDomainName
{
	static dispatch_once_t onceToken;
	static NSArray * sCommonISPDomainName=nil;
	
	dispatch_once(&onceToken, ^{

		sCommonISPDomainName=@[@"aol.com",
							   @"gmail.com",
							   @"gmx.com",
							   @"hotmail.com",
							   @"live.com",
							   @"mac.com",
							   @"me.com",
							   @"msn.com",
							   @"yahoo.com",
							   @"ymail.com",
							  
							   // Belgium
							  
							   @"mail.be",
							  
							   // Canada
							  
							   @"sympatico.ca",
							  
							   // France
							  
							   @"aliceadsl.fr",
							   @"caramail.com",
							   @"club-internet.fr",
							   @"free.fr",
							   @"freesbee.fr",
							   @"hotmail.fr",
							   @"infonie.fr",
							   @"laposte.net",
							   @"lavache.com",
							   @"libertysurf.fr",
							   @"live.fr",
							   @"orange.fr",
							   @"wanadoo.fr",
							   @"worldonline.fr",
							   @"voila.fr",
							   @"yahoo.fr",
							  
							   // UK
							  
							   @"gmx.co.uk",
							  
							   // US
							  
							   @"gmx.us",
							  
							   // Disposable
							  
							   @"baxomale.ht.cx",
							   @"maboard.com",
							   @"tilien.com"
							   ];
	});
	
	return sCommonISPDomainName;
}

+ (NSString *)_defaultPackageIdentifierPrefix
{
	static NSString * const PKGProjectTemplateCompanyIdentifierPrefixDefaultValue=@"com.mygreatcompany.pkg";
	
	ABPerson * tMe=[[ABAddressBook sharedAddressBook] me];
		
	ABMultiValue * tMailProperty=(ABMultiValue *) [tMe valueForProperty:kABEmailProperty];
		
	if (tMailProperty==nil)
		return PKGProjectTemplateCompanyIdentifierPrefixDefaultValue;
	
	NSUInteger tCount=[tMailProperty count];
	
	for(NSUInteger i=0;i<tCount;i++)
	{
		if ([[tMailProperty labelAtIndex:i] isEqualToString:kABEmailWorkLabel]==YES)
		{
			NSString * tMailAddress=[[tMailProperty valueAtIndex:i] lowercaseString];
			
			if ([tMailAddress length]>4)
			{
				NSArray * tMailAddressComponents=[tMailAddress componentsSeparatedByString:@"@"];
				
				if ([tMailAddressComponents count]>1)
				{
					NSString * tDomainName=tMailAddressComponents[1];
					
					if ([tDomainName length]>3)
					{
						// Check it's not a well-known ISP domain name
						
						if ([[PKGProjectTemplateDefaultValuesSettings _commonISPDomainName] containsObject:tDomainName]==NO)
						{
							NSArray * tReversedDomainNameComponents=[[tDomainName componentsSeparatedByString:@"."] WB_reversedArray];
							
							if (tReversedDomainNameComponents!=nil)
							{
								NSString * tReversedDomainName=[tReversedDomainNameComponents componentsJoinedByString:@"."];
								
								return [NSString stringWithFormat:@"%@.pkg",tReversedDomainName];
							}
						}
					}
				}
			}
		}
	}
	
	return PKGProjectTemplateCompanyIdentifierPrefixDefaultValue;
}

#pragma mark -

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_defaultValues=[[[NSUserDefaults standardUserDefaults] dictionaryForKey:PKGProjectTemplateDefaultValueSettingsKey] mutableCopy];
		
		if (_defaultValues==nil)
			_defaultValues=[NSMutableDictionary dictionary];
		
		NSDictionary * tDefaultTemplates=@{PKGProjectTemplateCompanyNameKey:[PKGProjectTemplateDefaultValuesSettings _defaultCompanyName],
										   PKGProjectTemplateCompanyIdentifierPrefixKey:[PKGProjectTemplateDefaultValuesSettings _defaultPackageIdentifierPrefix]
							};
		
		[tDefaultTemplates enumerateKeysAndObjectsUsingBlock:^(NSString * bKey,id bObject,BOOL *bOutStop){
			
			if (self->_defaultValues[bKey]==nil)
				self->_defaultValues[bKey]=bObject;
			
		}];
		
		NSMutableArray * tMutableArray=[[_defaultValues allKeys] mutableCopy];
		
		[tMutableArray sortUsingComparator:^NSComparisonResult(NSString * bKey,NSString *bOtherKey){
			
			return [NSLocalizedStringFromTable(bKey,@"Preferences",@"") compare:NSLocalizedStringFromTable(bOtherKey,@"Preferences",@"")];
		}];
		
		_allKeys=[tMutableArray copy];
	}
	
	return self;
}

- (id)valueForKey:(NSString *)inKey
{
	if (inKey==nil)
		return nil;
	
	return _defaultValues[inKey];
}

- (void)setValue:(id)inValue forKey:(NSString *)inKey
{
	if (inKey==nil)
		return;
	
	if (inValue==nil)
		[_defaultValues removeObjectForKey:inKey];
	else
		_defaultValues[inKey]=inValue;
	
	[[NSUserDefaults standardUserDefaults] setObject:_defaultValues forKey:PKGProjectTemplateDefaultValueSettingsKey];
		
}

@end

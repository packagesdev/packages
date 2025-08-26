/*
 Copyright (c) 2016-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationSection.h"

#import "PKGPackagesError.h"

#import "NSArray+WBExtensions.h"

NSString * const PKGPresentationSectionViewControllerClassNameKey_Deprecated=@"ICPRESENTATION_CHAPTER_VIEW_CONTROLLER_CLASS";

NSString * const PKGPresentationSectionPluginPathKey=@"ICPRESENTATION_CHAPTER_VIEW_CONTROLLER_INSTALLERPLUGIN_PATH";

NSString * const PKGPresentationSectionInstallerPluginNameKey_Deprecated=@"INSTALLER_PLUGIN";

NSString * const PKGPresentationSectionListTitleKey_Deprecated=@"LIST_TITLE_KEY";

NSString * const PKGPresentationSectionListTitleValue_Deprecated=@"InstallerSectionTitle";


NSString * const PKGPresentationSectionIntroductionName=@"Introduction";
NSString * const PKGPresentationSectionIntroductionPluginName=@"Introduction";
NSString * const PKGPresentationSectionIntroductionViewControllerClassName_Deprecated=@"ICPresentationViewIntroductionController";

NSString * const PKGPresentationSectionReadMeName=@"ReadMe";
NSString * const PKGPresentationSectionReadMePluginName=@"ReadMe";
NSString * const PKGPresentationSectionReadMeNameViewControllerClassName_Deprecated=@"ICPresentationViewReadMeController";

NSString * const PKGPresentationSectionLicenseName=@"License";
NSString * const PKGPresentationSectionLicensePluginName=@"License";
NSString * const PKGPresentationSectionLicenseViewControllerClassName_Deprecated=@"ICPresentationViewLicenseController";

NSString * const PKGPresentationSectionDestinationSelectName=@"DestinationSelect";
NSString * const PKGPresentationSectionDestinationSelectPluginName=@"TargetSelect";
NSString * const PKGPresentationSectionDestinationSelectViewControllerClassName_Deprecated=@"ICPresentationViewDestinationSelectController";

NSString * const PKGPresentationSectionInstallationTypeName=@"InstallationType";
NSString * const PKGPresentationSectionInstallationTypePluginName=@"PackageSelection";
NSString * const PKGPresentationSectionInstallationTypeViewControllerClassName_Deprecated=@"ICPresentationViewInstallationTypeController";

NSString * const PKGPresentationSectionInstallationName=@"Installation";
NSString * const PKGPresentationSectionInstallationPluginName=@"Install";
NSString * const PKGPresentationSectionInstallationViewControllerClassName_Deprecated=@"ICPresentationViewInstallationController";

NSString * const PKGPresentationSectionSummaryName=@"Summary";
NSString * const PKGPresentationSectionSummaryPluginName=@"Summary";
NSString * const PKGPresentationSectionSummaryViewControllerClassName_Deprecated=@"ICPresentationViewSummaryController";

NSString * const PKGPresentationSectionPluginViewControllerClassName_Deprecated=@"ICPresentationViewInstallerPluginController";

@interface PKGPresentationSection ()

	@property (readwrite) NSString * installerPluginName;

	@property (nonatomic,readwrite) NSString * name;

+ (NSString *)_sectionNameForInstallerPluginNamed:(NSString *)inBundleName;

- (NSString *)viewControllerClassName;

@end

@implementation PKGPresentationSection

+ (NSArray *)defaultSectionsList
{
	NSArray * tDefaultSectionNames=@[PKGPresentationSectionIntroductionPluginName,
									 PKGPresentationSectionReadMePluginName,
									 PKGPresentationSectionLicensePluginName,
									 PKGPresentationSectionDestinationSelectPluginName,
									 PKGPresentationSectionInstallationTypePluginName,
									 PKGPresentationSectionInstallationPluginName,
									 PKGPresentationSectionSummaryPluginName];
	
	return [tDefaultSectionNames WB_arrayByMappingObjectsUsingBlock:^PKGPresentationSection *(NSString * bSectionName, NSUInteger bIndex) {
		PKGPresentationSection * tPresentationSection=[PKGPresentationSection new];
		
		tPresentationSection.installerPluginName=bSectionName;
		tPresentationSection.name=[PKGPresentationSection _sectionNameForInstallerPluginNamed:bSectionName];
		
		return tPresentationSection;
	}];
}

+ (NSString *)_sectionNameForInstallerPluginNamed:(NSString *)inBundleName
{
	if (inBundleName==nil)
		return nil;
	
	static NSDictionary *sSectionNameForInstallerPluginNameDictionary = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sSectionNameForInstallerPluginNameDictionary = @{PKGPresentationSectionIntroductionPluginName:PKGPresentationSectionIntroductionName,
														 PKGPresentationSectionReadMePluginName:PKGPresentationSectionReadMeName,
														 PKGPresentationSectionLicensePluginName:PKGPresentationSectionLicenseName,
														 PKGPresentationSectionDestinationSelectPluginName:PKGPresentationSectionDestinationSelectName,
														 PKGPresentationSectionInstallationTypePluginName:PKGPresentationSectionInstallationTypeName,
														 PKGPresentationSectionInstallationPluginName:PKGPresentationSectionInstallationName,
														 PKGPresentationSectionSummaryPluginName:PKGPresentationSectionSummaryName
										};
	});
	
	return sSectionNameForInstallerPluginNameDictionary[inBundleName];
}

+ (NSString *)installerPluginNameForSectionName:(NSString *)inSectionName
{
	if (inSectionName==nil)
		return nil;
	
	static NSDictionary *sInstallerPluginNameForSectionNameDictionary = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sInstallerPluginNameForSectionNameDictionary = @{PKGPresentationSectionIntroductionName:PKGPresentationSectionIntroductionPluginName,
														 PKGPresentationSectionReadMeName:PKGPresentationSectionReadMePluginName,
														 PKGPresentationSectionLicenseName:PKGPresentationSectionLicensePluginName,
														 PKGPresentationSectionDestinationSelectName:PKGPresentationSectionDestinationSelectPluginName,
														 PKGPresentationSectionInstallationTypeName:PKGPresentationSectionInstallationTypePluginName,
														 PKGPresentationSectionInstallationName:PKGPresentationSectionInstallationPluginName,
														 PKGPresentationSectionSummaryName:PKGPresentationSectionSummaryPluginName
														 };
	});
	
	return sInstallerPluginNameForSectionNameDictionary[inSectionName];
}

- (instancetype)initWithPluginPath:(PKGFilePath *)inPath
{
	self=[super init];
	
	if (self!=nil)
	{
		_pluginPath=inPath;
	}
	
	return self;
}

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	if (inRepresentation==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationNilRepresentationError userInfo:nil];
		
		return nil;
	}
	
	if ([inRepresentation isKindOfClass:NSDictionary.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
		
		return nil;
	}
	
	self=[super init];
	
	if (self!=nil)
	{
		if (inRepresentation[PKGPresentationSectionPluginPathKey]==nil)
		{
			_installerPluginName=inRepresentation[PKGPresentationSectionInstallerPluginNameKey_Deprecated];
		
			_name=[PKGPresentationSection _sectionNameForInstallerPluginNamed:_installerPluginName];
		}
		else
		{
			
			NSError * tError=nil;
			
			_pluginPath=[[PKGFilePath alloc] initWithRepresentation:inRepresentation[PKGPresentationSectionPluginPathKey] error:&tError];
			
			if (_pluginPath==nil)
			{
				if (outError!=NULL)
				{
					NSInteger tCode=tError.code;
					
					if (tCode==PKGRepresentationNilRepresentationError)
						tCode=PKGRepresentationInvalidValueError;
					
					NSString * tPathError=PKGPresentationSectionPluginPathKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tCode
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	/* Only kept for backward compatibility as the corresponding value was in theory only useful to the Editor UI */
	
	tRepresentation[PKGPresentationSectionViewControllerClassNameKey_Deprecated]=[self viewControllerClassName];
	
	if (self.pluginPath==nil)
	{
		/* Ideally, the name of the section should have been used to identify a section as nothing guarantees that the names of Installer.app's plugins won't change in the future.
		 
		 Also, we should be able to work without using Installer.app resources for localizations
		 */
		
		tRepresentation[PKGPresentationSectionInstallerPluginNameKey_Deprecated]=self.installerPluginName;
		
		/* Only kept for backward compatibility as the value is actually a constant for all sections */
		
		tRepresentation[PKGPresentationSectionListTitleKey_Deprecated]=PKGPresentationSectionListTitleValue_Deprecated;	// Only useful for backward compatibility
	}
	else
	{
		tRepresentation[PKGPresentationSectionPluginPathKey]=[self.pluginPath representation];
	}
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	if (self.pluginPath!=nil)
		[tDescription appendFormat:@"  o %@ -> %@\n",[self.pluginPath.lastPathComponent stringByDeletingPathExtension],[self.pluginPath description]];
	else
		[tDescription appendFormat:@"  o %@\n",_name];
	
	return tDescription;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)inZone
{
	PKGPresentationSection * nPresentationSection=[[[self class] allocWithZone:inZone] init];
	
	if (nPresentationSection!=nil)
	{
		nPresentationSection.installerPluginName=[self.installerPluginName copyWithZone:inZone];
		nPresentationSection.name=[_name copyWithZone:inZone];
		nPresentationSection.pluginPath=[self.pluginPath copyWithZone:inZone];
	}
	
	return nPresentationSection;
}

#pragma mark -

- (NSString *)viewControllerClassName
{
	if (self.pluginPath!=nil)
		return PKGPresentationSectionPluginViewControllerClassName_Deprecated;
	
	if (_name==nil)
		return nil;
	
	static NSDictionary *sClassNameForNameDictionary = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sClassNameForNameDictionary = @{PKGPresentationSectionIntroductionName:PKGPresentationSectionIntroductionViewControllerClassName_Deprecated,
										PKGPresentationSectionReadMeName:PKGPresentationSectionReadMeNameViewControllerClassName_Deprecated,
										PKGPresentationSectionLicenseName:PKGPresentationSectionLicenseViewControllerClassName_Deprecated,
										PKGPresentationSectionDestinationSelectName:PKGPresentationSectionDestinationSelectViewControllerClassName_Deprecated,
										PKGPresentationSectionInstallationTypeName:PKGPresentationSectionInstallationTypeViewControllerClassName_Deprecated,
										PKGPresentationSectionInstallationName:PKGPresentationSectionInstallationViewControllerClassName_Deprecated,
										PKGPresentationSectionSummaryName:PKGPresentationSectionSummaryViewControllerClassName_Deprecated
										};
	});
	
	return sClassNameForNameDictionary[_name];
}

- (NSString *)name
{
	if (self.pluginPath!=nil)
		return self.pluginPath.lastPathComponent;
		
	return _name;
}

- (BOOL)isPlugin
{
	return (self.pluginPath!=nil);
}

@end

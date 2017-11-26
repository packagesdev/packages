/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PKGBuildError)
{
	PKGBuildErrorUnknown=0,
	PKGBuildErrorOutOfMemory=1,
	PKGBuildErrorMissingInformation=2,
	PKGBuildErrorMissingBuildData=3,
	PKGBuildErrorIncorrectValue=4,
	
	PKGBuildErrorFileNotFound=10,
	PKGBuildErrorFileCanNotBeCreated=11,
	PKGBuildErrorFileCanNotBeCopied=12,
	PKGBuildErrorFileCanNotBeDeleted=13,
	
	PKGBuildErrorFileCanNotBeOpened=15,
	PKGBuildErrorFileCanNotBeRead=16,
	PKGBuildErrorFileAlreadyExists=17,
	
	PKGBuildErrorFileAbsolutePathCanNotBeComputed=19,
	
	PKGBuildErrorFilePosixPermissionsCanNotBeSet=20,
	PKGBuildErrorFileAccountsCanNotBeSet=21,
	
	PKGBuildErrorFileAttributesCanNotBeRead=25,
	PKGBuildErrorFileAttributesCanNotBeSet=26,
	PKGBuildErrorFileExtendedAttributesCanNotBeRead=27,
	PKGBuildErrorFileExtendedAttributesCanNotBeSet=28,
	
	PKGBuildErrorFileIncorrectType=30,
	
	PKGBuildErrorBuildFolderNotWritable=40,
	
	
	PKGBuildErrorExternalToolFailure=50,
	
	PKGBuildErrorNoMoreSpaceOnVolume=100,
	PKGBuildErrorReadOnlyVolume=101,
	PKGBuildErrorWriteNoPermission=102,
	
	
	PKGBuildErrorUnknownLanguage=150,
	
	
	PKGBuildErrorLicenseTemplateNotFound=200,
	
	PKGBuildErrorBundleIdentifierNotFound=250,
	
	PKGBuildErrorEmptyString=400,
	
	
	PKGBuildErrorRequirementMissingConverter=420,
	PKGBuildErrorRequirementConversionError=421,
	
	
	PKGBuildErrorLocatorMissingConverter=422,
	PKGBuildErrorLocatorConversionError=423,
	
	PKGBuildErrorConverterMissingParameter=430,
	PKGBuildErrorConverterInvalidParameter=431,
	
	PKGBuildErrorSigningUnknown=500,
	PKGBuildErrorSigningTimeOut=501,
	PKGBuildErrorSigningAuthorizationDenied=502,
	PKGBuildErrorSigningCertificateNotFound=503,
	PKGBuildErrorSigningCertificateChainBroken=504,
	PKGBuildErrorSigningCertificatePrivateKeyNotFound=505,
	PKGBuildErrorSigningTrustEvaluationFailure=506,
	PKGBuildErrorSigningKeychainNotFound=507
};

typedef NS_ENUM(NSUInteger, PKGBuildErrorFileKind)
{
	PKGFileKindRegularFile=0,
	PKGFileKindFolder,
	PKGFileKindPlugin,
	PKGFileKindTool,
	PKGFileKindPackage,
	PKGFileKindBundle
};

@interface PKGBuildEvent : NSObject

	@property (copy) NSString *filePath;

+ (instancetype)eventWithFilePath:(NSString *)inFilePath;

- (id)initWithRepresentation:(NSDictionary *)inRepresentation;

- (NSDictionary *)representation;

@end


@interface PKGBuildErrorEvent : PKGBuildEvent

	@property PKGBuildError code;

	@property PKGBuildError subcode;


	// File Info

	@property (copy) NSString *otherFilePath;

	@property PKGBuildErrorFileKind fileKind;


	// Tag info

	@property (copy) NSString *tag;

	// Tool Error Code

	@property int toolTerminationStatus;


+ (instancetype)errorEventWithCode:(PKGBuildError)inCode;

+ (instancetype)errorEventWithCode:(PKGBuildError)inCode filePath:(NSString *)inFilePath fileKind:(PKGBuildErrorFileKind)inKind;

+ (instancetype)errorEventWithCode:(PKGBuildError)inCode tag:(NSString *)inTag;


@end


@interface PKGBuildInfoEvent : PKGBuildEvent

	@property (copy) NSString *packageUUID;

	@property (copy) NSString * packageName;

	@property NSUInteger packagesCount;

+ (instancetype)infoEventWithPackageUUID:(NSString *)inUUID name:(NSString *)inName;

+ (instancetype)infoEventWithPackagesCount:(NSUInteger)inPackagesCount;

@end

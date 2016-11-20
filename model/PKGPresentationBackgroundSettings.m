/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPresentationBackgroundSettings.h"

#import "PKGPackagesError.h"

NSString * const PKGPresentationBackgroundShowCustomImageKey=@"CUSTOM";

NSString * const PKGPresentationBackgroundImagePathKey=@"BACKGROUND_PATH";

NSString * const PKGPresentationBackgroundImageAlignmentKey=@"ALIGNMENT";

NSString * const PKGPresentationBackgroundImageScalingKey=@"SCALING";

@implementation PKGPresentationBackgroundSettings

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_showCustomImage=NO;
		
		_imagePath=nil;
		
		_imageAlignment=PKGImageAlignmentleft;
		_imageScaling=PKGImageScalingProportionnaly;
	}
	
	return self;
}

- (id) initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	NSError * tError=nil;
	
	self=[super initWithRepresentation:inRepresentation error:&tError];
	
	if (self!=nil)
	{
		NSNumber * tNumber=inRepresentation[PKGPresentationBackgroundShowCustomImageKey];
		
		if (tNumber==nil)
		{
			_showCustomImage=NO;
		}
		else
		{
			if ([tNumber isKindOfClass:NSNumber.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGPresentationBackgroundShowCustomImageKey}];
				
				return nil;
			}
			
			_showCustomImage=[tNumber boolValue];
		}
		
		_imagePath=[[PKGFilePath alloc] initWithRepresentation:inRepresentation[PKGPresentationBackgroundImagePathKey] error:&tError];	// can be nil
		
		if (_imagePath==nil)
		{
			if (tError.code!=PKGRepresentationNilRepresentationError)
			{
				if (outError!=NULL)
				{
					NSString * tPathError=PKGPresentationBackgroundImagePathKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tError.code
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
		
		tNumber=inRepresentation[PKGPresentationBackgroundImageAlignmentKey];
		
		if (tNumber==nil)
		{
			_imageAlignment=PKGImageAlignmentleft;
		}
		else
		{
			if ([tNumber isKindOfClass:NSNumber.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGPresentationBackgroundImageAlignmentKey}];
				
				return nil;
			}

			_imageAlignment=[tNumber unsignedIntegerValue];
		
			if (_imageAlignment>PKGImageAlignmentRight)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidValue
											  userInfo:@{PKGKeyPathErrorKey:PKGPresentationBackgroundImagePathKey}];
				
				return nil;
			}
		}
		
		tNumber=inRepresentation[PKGPresentationBackgroundImageScalingKey];
		
		if (tNumber==nil)
		{
			_imageScaling=PKGImageScalingProportionnaly;
		}
		else
		{
			if ([tNumber isKindOfClass:NSNumber.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGPresentationBackgroundImageScalingKey}];
				
				return nil;
			}
			
			_imageScaling=[tNumber unsignedIntegerValue];
		
			if (_imageScaling>PKGImageScalingNone)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidValue
											  userInfo:@{PKGKeyPathErrorKey:PKGPresentationBackgroundImageScalingKey}];
				
				return nil;
			}
		}
	}
	else
	{
		if (outError!=NULL)
			*outError=tError;
	}
	
	return self;
}

- (NSMutableDictionary *) representation
{
	NSMutableDictionary * tRepresentation=[super representation];
	
	if (self.showCustomImage==NO)
		return tRepresentation;
	
	tRepresentation[PKGPresentationBackgroundShowCustomImageKey]=@(YES);
	
	NSMutableDictionary * tFilePathRepresentationDictionary=[self.imagePath representation];
	
	if (tFilePathRepresentationDictionary!=nil)
		tRepresentation[PKGPresentationBackgroundImagePathKey]=[self.imagePath representation];
	
	tRepresentation[PKGPresentationBackgroundImageAlignmentKey]=@(self.imageAlignment);
	
	tRepresentation[PKGPresentationBackgroundImageScalingKey]=@(self.imageScaling);
	
	return tRepresentation;
}

#pragma mark -

- (NSString *) description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendString:@"  Background Settings:\n"];
	[tDescription appendString:@"  -------------------\n\n"];
	
	[tDescription appendFormat:@"%@",[super description]];
	
	return tDescription;
}

@end

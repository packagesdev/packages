/*
 Copyright (c) 2017-2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionProjectSettingsAdvancedOptionBoolean.h"

NSString * const PKGDistributionProjectSettingsAdvancedOptionsBooleanDontSetNoKey=@"BOOLEAN-DONT-SET-NO";

@interface PKGDistributionProjectSettingsAdvancedOptionBoolean ()

	@property (readwrite) BOOL dontSetNO;

@end

@implementation PKGDistributionProjectSettingsAdvancedOptionBoolean

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	NSError * tError=nil;
	
	self=[super initWithRepresentation:inRepresentation error:&tError];
	
	if (self==nil)
	{
		if (outError!=NULL)
			*outError=tError;
        
        return nil;
	}
	
	NSNumber * tNumber=inRepresentation[PKGDistributionProjectSettingsAdvancedOptionsBooleanDontSetNoKey];
	
	if (tNumber!=nil)
	{
		if ([tNumber isKindOfClass:NSNumber.class]==NO)
		{
			if (outError!=NULL)
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:PKGRepresentationInvalidTypeOfValueError
										  userInfo:@{PKGKeyPathErrorKey:PKGDistributionProjectSettingsAdvancedOptionsBooleanDontSetNoKey}];
			
			return nil;
		}
	
		_dontSetNO=tNumber.boolValue;
	}
	else
	{
		_dontSetNO=NO;
	}
		
	return self;
}

@end

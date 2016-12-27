/*
 Copyright (c) 2012, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "WBRemoteVersionChecker.h"

#define WBREMOTEVERSIONREMINDER_PERIOD	(24*3600)		// Every day
#define WBREMOTEVERSIONCHECK_PERIOD		(3*24*3600)		// Every 3 days

NSString * const WBRemoteCheckEnabledKey=@"WBRemoteCheckEnabled";
NSString * const WBRemoteLastCheckDateKey=@"WBRemoteLastCheckDate";
NSString * const WBLastReminderDateKey=@"WBLastReminderDate";
NSString * const WBRemoteAvailableVersionKey=@"WBRemoteAvailableVersion";
NSString * const WBRemoteAvailableVersionURLKey=@"WBRemoteAvailableVersionURL";


NSString * const WBSkipRemoteAvailableVersionKey=@"WBSkipRemoteAvailableVersion";

NSString * const WBVersionCheckURL=@"WBVersionCheckURL";

@interface WBRemoteVersionChecker () <NSURLConnectionDataDelegate>
{
	NSString * _productName;
	NSString * _productLocalVersion;
	NSString * _productCheckURL;
	
	NSUserDefaults * _defaults;
	
	NSMutableData * _data;
}

@end

@implementation WBRemoteVersionChecker

+ (WBRemoteVersionChecker *) sharedChecker
{
	static dispatch_once_t onceToken;
	static WBRemoteVersionChecker * sRemoteVersionChecker=nil;
	
	dispatch_once(&onceToken, ^{
		
		sRemoteVersionChecker=[WBRemoteVersionChecker new];
	});
	
	return sRemoteVersionChecker;
}

#pragma mark -

- (id) init
{
	self=[super init];
	
	if (self!=nil)
	{
		NSBundle * tBundle=[NSBundle mainBundle];
		
		_productName=[tBundle objectForInfoDictionaryKey:@"CFBundleName"];
		_productLocalVersion=[tBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
		_productCheckURL=[tBundle objectForInfoDictionaryKey:WBVersionCheckURL];
		
		_defaults=[NSUserDefaults standardUserDefaults];
		
		if ([_productLocalVersion length]>0)
		{
			NSDate * tCurrentDate=[NSDate date];
			
			if ([_defaults boolForKey:WBSkipRemoteAvailableVersionKey]==NO)
			{
				NSString * tRemoteVersion=[_defaults objectForKey:WBRemoteAvailableVersionKey];
				
				if (tRemoteVersion!=nil)
				{
					if ([tRemoteVersion compare:_productLocalVersion options:NSNumericSearch]==NSOrderedDescending)
					{
						NSDate * tLastReminderDate=[_defaults objectForKey:WBLastReminderDateKey];
						
						if (tLastReminderDate==nil || [tCurrentDate timeIntervalSinceDate:tLastReminderDate]>WBREMOTEVERSIONREMINDER_PERIOD)
						{
							NSString * tDownloadURL=[_defaults objectForKey:WBRemoteAvailableVersionURLKey];
							
							if (tDownloadURL!=nil)
							{
								// Display dialog
								
								NSAlert * tAlert=[NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"A new version of %@ is available.",@"RemoteCheck",@""),_productName]
																 defaultButton:NSLocalizedStringFromTable(@"Download",@"RemoteCheck",@"")
															   alternateButton: NSLocalizedStringFromTable(@"Skip This Version",@"RemoteCheck",@"")
																   otherButton:NSLocalizedStringFromTable(@"Remind Me Later",@"RemoteCheck",@"")
													 informativeTextWithFormat:@"%@",[NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ %@ is now available - you have %@. Would you like to download it now?",@"RemoteCheck",@""),_productName,tRemoteVersion,_productLocalVersion]];
								
								
								NSModalResponse tResponse=[tAlert runModal];
								
								switch(tResponse)
								{
									case NSAlertDefaultReturn:
										
										// Download
										
										[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:tDownloadURL]];
										
										[_defaults setObject:[NSDate date] forKey:WBLastReminderDateKey];
										
										break;
										
									case NSAlertAlternateReturn:
										
										// Skip
										
										[_defaults setBool:YES forKey:WBSkipRemoteAvailableVersionKey];
										
										break;
										
									case NSAlertOtherReturn:
										
										// Remind me later
									
										[_defaults setObject:[NSDate date] forKey:WBLastReminderDateKey];
										
										break;
										
									default:
										
										break;
								}
							}
						}
					}
				}
			}
		
			if ([_productCheckURL length]>0)
			{
				// Check whether it's time to check for a newer version
				
				id tObject=[_defaults objectForKey:WBRemoteCheckEnabledKey];
				
				if (tObject==nil || [_defaults boolForKey:WBRemoteCheckEnabledKey]==YES)
				{
					NSDate * tLastCheckDate=[_defaults objectForKey:WBRemoteLastCheckDateKey];
					
					if (tLastCheckDate==nil || ([tCurrentDate timeIntervalSinceDate:tLastCheckDate]>WBREMOTEVERSIONCHECK_PERIOD))
					{
						// Perform Remote Check
						
						_data=nil;
						
						NSURLRequest * tRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:_productCheckURL]];
						
						if (tRequest!=nil)
						{
							NSURLConnection * tURLConnection=[[NSURLConnection alloc] initWithRequest:tRequest delegate:self];
							
							if (tURLConnection==nil)
							{
								NSLog(@"Could not allocate NSURLConnection");
							}
						}
						else
						{
							NSLog(@"Could not allocate NSURLRequest");
						}

					}
				}
			}
		}
	}
	
	return self;
}

#pragma mark -

- (BOOL)checkEnabled
{
	id tObject=[_defaults objectForKey:WBRemoteCheckEnabledKey];
	
	if (tObject==nil || [_defaults boolForKey:WBRemoteCheckEnabledKey]==YES)
		return YES;
	
	return NO;
}

- (void)setCheckEnabled:(BOOL)inBool
{
	[_defaults setBool:inBool forKey:WBRemoteCheckEnabledKey];
}

#pragma mark - NSURLConnectionDataDelegate

- (void) connection:(NSURLConnection *) inConnection didReceiveResponse:(NSURLResponse *) inResponse
{
	if (inConnection!=nil)
	{
		NSHTTPURLResponse * tHTTPResponse=(NSHTTPURLResponse *) inResponse;
		
		switch ([tHTTPResponse statusCode])
		{
			case 200:
				
				break;
				
			default:
				
				[inConnection cancel];
				
				break;
		}
	}
}

- (void) connection:(NSURLConnection *) inConnection didReceiveData:(NSData *) inData
{
    if (inConnection!=nil && inData!=nil)
	{
        if (_data==nil)
			_data=[inData mutableCopy];
        else
			[_data appendData:inData];
    }
}

- (void) connection:(NSURLConnection *) inConnection didFailWithError:(NSError *) inError
{
	if (inConnection!=nil)
		_data=nil;
}

- (void) connectionDidFinishLoading:(NSURLConnection *) inConnection
{
	if (inConnection!=nil)
	{
        if (_data!=nil)
		{
			[_defaults setObject:[NSDate date] forKey:WBRemoteLastCheckDateKey];
			
			NSPropertyListFormat tPropertyListFormat;
			NSDictionary * tDictionary=[NSPropertyListSerialization propertyListFromData:_data
																		mutabilityOption:NSPropertyListImmutable
																				  format:&tPropertyListFormat
																		errorDescription:NULL];
			
			if (tDictionary!=nil)
			{
				NSString * tRemoteVersion=tDictionary[WBRemoteAvailableVersionKey];
				
				NSString * tLocalRemoteVersion=[_defaults objectForKey:WBRemoteAvailableVersionKey];
				
				if (tLocalRemoteVersion!=nil)
				{
					if ([tRemoteVersion compare:tLocalRemoteVersion options:NSNumericSearch]!=NSOrderedDescending)
						goto bail;
				}
				
				if (_productLocalVersion!=nil)
				{
					if ([tRemoteVersion compare:_productLocalVersion options:NSNumericSearch]==NSOrderedDescending)
					{
						NSString * tRemoteURL=[tDictionary objectForKey:WBRemoteAvailableVersionURLKey];
						
						if (tRemoteURL!=nil)
						{
							[_defaults setObject:tRemoteURL forKey:WBRemoteAvailableVersionURLKey];
							[_defaults setObject:tRemoteVersion forKey:WBRemoteAvailableVersionKey];
							[_defaults setBool:NO forKey:WBSkipRemoteAvailableVersionKey];
						}
					}
				}
			}
		}
																		   
bail:
																		   
		_data=nil;
    }
}

@end

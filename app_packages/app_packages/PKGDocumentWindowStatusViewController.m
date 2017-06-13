/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDocumentWindowStatusViewController.h"

#import "PKGBuildNotificationCenter.h"

#import "PKGBuildEvent.h"

#import "PKGApplicationPreferences.h"

@interface PKGDocumentWindowStatusViewController ()
{
	IBOutlet NSTextField * _statusLabel;
	
	IBOutlet NSProgressIndicator * _progressIndicator;
	
	NSUInteger _numberOfPackagesToBuild;
	NSUInteger _indexOfPackagesBeingBuilt;
}

@end

@implementation PKGDocumentWindowStatusViewController

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
}

#pragma mark - Notifications

- (void)processBuildEventNotification:(NSNotification *)inNotification
{
	if (inNotification==nil)
		return;
	
	NSDictionary * tUserInfo=[inNotification userInfo];
	
	if (tUserInfo==nil)
		return;
	
	NSNumber * tNumber=tUserInfo[PKGBuildStepKey];
	
	if ([tNumber isKindOfClass:[NSNumber class]]==NO)
		return;
	
	PKGBuildStep tStep=[tNumber unsignedIntegerValue];
	
	NSIndexPath * tStepPath=tUserInfo[PKGBuildStepPathKey];
	
	if ([tStepPath isKindOfClass:[NSIndexPath class]]==NO)
		return;
	
	
	tNumber=tUserInfo[PKGBuildStateKey];
	
	if ([tNumber isKindOfClass:[NSNumber class]]==NO)
		return;
	
	PKGBuildStepState tState=[tNumber unsignedIntegerValue];
	
	
	NSDictionary * tRepresentation=tUserInfo[PKGBuildStepEventRepresentationKey];
	
	if (tRepresentation!=nil && [tRepresentation isKindOfClass:[NSDictionary class]]==NO)
		return;
	
	if (tState==PKGBuildStepStateInfo)
	{
		PKGBuildInfoEvent * tInfoEvent=[[PKGBuildInfoEvent alloc] initWithRepresentation:tRepresentation];
		
		switch(tStep)
		{
			case PKGBuildStepDistribution:
				
				_numberOfPackagesToBuild=tInfoEvent.packagesCount;
				_progressIndicator.maxValue=_numberOfPackagesToBuild*3+3;
				
				break;
			
			default:
				
				break;
		}
		
		return;
	}
	
	if (tState==PKGBuildStepStateBegin)
	{
		switch(tStep)
		{
			case PKGBuildStepProject:
				
				_statusLabel.stringValue=NSLocalizedStringFromTable(@"Building...",@"BuildNotification",@"");
				
				_progressIndicator.minValue=0.0;
				_progressIndicator.maxValue=4.0;
				_progressIndicator.doubleValue=0.0;
				
				_progressIndicator.hidden=NO;
				
				_numberOfPackagesToBuild=0;
				_indexOfPackagesBeingBuilt=0;
				
				break;
				
			case PKGBuildStepDistribution:
				
				_indexOfPackagesBeingBuilt=0;
	
				break;
				
			case PKGBuildStepPackage:
				
				_statusLabel.stringValue=NSLocalizedStringFromTable(@"Building package...",@"BuildNotification",@"");
				
				break;
				
			case PKGBuildStepPackageCreate:
			case PKGBuildStepPackageReference:
			case PKGBuildStepPackageImport:
				
				if (_numberOfPackagesToBuild>0)
				{
					_indexOfPackagesBeingBuilt++;
					
					if (_numberOfPackagesToBuild==1)
						_statusLabel.stringValue=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Building %lu of 1 package...",@"BuildNotification",@""),(unsigned long)_indexOfPackagesBeingBuilt];
					else
						_statusLabel.stringValue=[NSString stringWithFormat:NSLocalizedStringFromTable(@"Building %lu of %lu packages...",@"BuildNotification",@""),(unsigned long)_indexOfPackagesBeingBuilt,(unsigned long)_numberOfPackagesToBuild];
				}
				
				break;
				
			default:
				break;
		}
		
		return;
	}
	
	if (tState==PKGBuildStepStateFailure)
	{
		_statusLabel.stringValue=NSLocalizedStringFromTable(@"Build failed",@"BuildNotification",@"");
		
		_progressIndicator.hidden=YES;
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGBuildEventNotification object:nil];
		
		return;
	}

	if (tState==PKGBuildStepStateSuccess)
	{
		// Progress Indicator
		
		switch(tStep)
		{
			case PKGBuildStepProject:
			case PKGBuildStepDistribution:
			case PKGBuildStepPackage:
				
			case PKGBuildStepDistributionScript:
				
			case PKGBuildStepPackageCreate:
			case PKGBuildStepPackageInfo:
			case PKGBuildStepPackagePayload:
				
				_progressIndicator.doubleValue=_progressIndicator.doubleValue+1.0;
				
				break;
				
			case PKGBuildStepPackageReference:
			case PKGBuildStepPackageImport:
				
				_progressIndicator.doubleValue=_progressIndicator.doubleValue+3.0;
				
				break;
			
			default:
				return;
		}
		
		if (tStep==PKGBuildStepProject)
		{
			[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGBuildEventNotification object:nil];
			
			_statusLabel.stringValue=NSLocalizedStringFromTable(@"Build succeeded",@"BuildNotification",@"");
			
			_progressIndicator.hidden=YES;
		}
	}
}

@end

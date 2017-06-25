/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDistributionProject+Edition.h"

#import "PKGDistributionProjectSettings+Edition.h"
#import "PKGPresentationInstallationTypeStepSettings+Edition.h"

@implementation PKGDistributionProject (Edition)

- (instancetype)initWithPackageProject:(PKGPackageProject *)inPackageProject
{
	self=[self init];
	
	if (self!=nil)
	{
		PKGPackageComponent * tPackageComponent=[[PKGPackageComponent alloc] initWithProjectPackageObject:inPackageProject];
		
		if (tPackageComponent==nil)
			return nil;
		
		tPackageComponent.packageSettings.name=inPackageProject.settings.name;
		
		self.settings=[[PKGDistributionProjectSettings alloc] initWithProjectSettings:inPackageProject.settings];
		
		self.presentationSettings=[PKGDistributionProjectPresentationSettings new];
		
		self.requirementsAndResources=nil;
		
		self.comments=[inPackageProject.comments copy];
		
		[self.packageComponents addObject:tPackageComponent];
	}
	
	return self;
}

- (void)addPackageComponent:(PKGPackageComponent *)inPackageComponent
{
	if (inPackageComponent==nil)
		return;
	
	[self addPackageComponents:@[inPackageComponent]];
}

- (void)addPackageComponents:(NSArray *)inPackageComponents
{
	if (inPackageComponents.count==0)
		return;
	
	[self.packageComponents addObjectsFromArray:inPackageComponents];
	
	PKGPresentationInstallationTypeStepSettings * tInstallationTypeSettings=self.presentationSettings.installationTypeSettings;
	
	if (tInstallationTypeSettings==nil)
		return;
	
	[tInstallationTypeSettings addChoicesForPackageComponents:inPackageComponents];
}

- (void)removePackageComponents:(NSArray *)inPackageComponents
{
	if (inPackageComponents.count==0)
		return;
	
	[self.packageComponents removeObjectsInArray:inPackageComponents];
	
	PKGPresentationInstallationTypeStepSettings * tInstallationTypeSettings=self.presentationSettings.installationTypeSettings;
	
	if (tInstallationTypeSettings==nil)
		return;
	
	NSArray * tPackageComponentsUUIDs=[inPackageComponents WB_arrayByMappingObjectsUsingBlock:^id(PKGPackageComponent * bPackageComponent, NSUInteger bIndex) {
		
		return bPackageComponent.UUID;
		
	}];
	
	// Update the installation type hierarchies
	
	[tInstallationTypeSettings removeAllReferencesToPackageComponentUUIDs:tPackageComponentsUUIDs];
}

@end

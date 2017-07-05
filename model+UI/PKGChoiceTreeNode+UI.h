/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGChoicesForest.h"

typedef NS_ENUM(NSInteger, PKGChoiceSelectedState) {
	PKGChoiceSelectedStateUnknown=-5,
	PKGChoiceSelectedStateMixed=-1,
	PKGChoiceSelectedStateOff=0,
	PKGChoiceSelectedStateOn=1,
	PKGChoiceSelectedStateDependent=2
};

@interface PKGChoiceTreeNode (UI)

	@property (nonatomic,readonly,copy) NSString * choiceUUID;

	@property (nonatomic,readonly,copy) NSString * packageUUID;

	@property (nonatomic,readonly,getter=isInvisible) BOOL invisible;

	@property (nonatomic,readonly,getter=isEnabled) BOOL enabled;

	@property (nonatomic,readonly,getter=isPackageChoice) BOOL packageChoice;

	@property (nonatomic,readonly,getter=isGenuineGroupChoice) BOOL genuineChoice;

	@property (nonatomic,readonly,getter=isMergedPackagesChoice) BOOL mergedPackagesChoice;

	@property (nonatomic,readonly,getter=isMergedIntoPackagesChoice) BOOL mergedIntoPackagesChoice;

	@property (nonatomic,readonly) PKGChoiceSelectedState selectedState;

	//@property (nonatomic,readonly,copy) NSString * nameTitle;

	@property (nonatomic,readonly,copy) NSString * choiceAction;

- (NSString *)titleForLocalization:(NSString *)inLocalization;

- (NSString *)descriptionForLocalization:(NSString *)inLocalization;

@end

extern NSString * const PKGInstallationHierarchyChoicesUUIDsPboardType;
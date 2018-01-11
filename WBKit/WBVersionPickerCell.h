/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>

#import "WBVersion.h"
#import "WBVersionsHistory.h"

extern NSString * const WBVersionPickerCellSelectedElementDidChangeNotification;

typedef NS_ENUM(NSUInteger, WBVersionPickerCellElementType)
{
	WBVersionPickerCellElementMajorVersion=0,
	WBVersionPickerCellElementMinorVersion=1,
	WBVersionPickerCellElementPatchVersion=2,
	
	WBVersionPickerCellElementSeparator=10
};

typedef NS_ENUM(NSUInteger, WBVersionPickerStyle)
{
    WBTextFieldAndStepperVersionPickerStyle    = 0,
    WBTextFieldVersionPickerStyle              = 1
};

@protocol WBVersionPickerCellDelegate;

@interface WBVersionPickerCell : NSActionCell

	@property (nonatomic,copy) WBVersionsHistory * versionsHistory;

	@property (nonatomic,copy) WBVersion * minVersion;

	@property (nonatomic,copy) WBVersion * maxVersion;

	@property (nonatomic,copy) WBVersion * versionValue;



	@property (nonatomic,copy) NSColor * textColor;

	@property (nonatomic,copy) NSColor * backgroundColor;

	@property (nonatomic) BOOL drawsBackground;

	@property (nonatomic) WBVersionPickerStyle versionPickerStyle;


	@property (nonatomic,weak) id<WBVersionPickerCellDelegate> delegate;


@end

@protocol WBVersionPickerCellDelegate <NSObject>

	@optional

- (WBVersion *)versionPickerCell:(WBVersionPickerCell *)inVersionPickerCell versionValueForProposedVersionValue:(WBVersion *)inProposedVersion;

- (BOOL)versionPickerCell:(WBVersionPickerCell *)inVersionPickerCell shouldSelectElementType:(WBVersionPickerCellElementType)inElementType;

- (void)versionPickerCellSelectedElementDidChange:(WBVersionPickerCell *)inVersionPickerCell;

@end

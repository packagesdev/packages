/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGLicenseProvider+UI.h"

#import "NSString+Karelia.h"

@interface PKGTokenTextAttachmentCell ()
{
	BOOL _highlighted;
}

@end

@implementation PKGTokenTextAttachmentCell

- (NSSize)cellSize
{
	NSSize tSize=[self.tokenLabel size];
	
	tSize.height+=4.0;
	tSize.width+=tSize.height;
	
	return tSize;
}

- (NSPoint)cellBaselineOffset
{
	return NSMakePoint(-1., -6.);
}

#pragma mark -

- (void)highlight:(BOOL)inHihglight withFrame:(NSRect)inCellFrame inView:(NSView *)inControlView
{
	//NSLog(@"highlight");
	
	_highlighted=inHihglight;
	[inControlView setNeedsDisplayInRect:inCellFrame];
}

- (void)drawWithFrame:(NSRect)inCellFrame inView:(NSView *)inControlView characterIndex:(NSUInteger)charIndex layoutManager:(NSLayoutManager *)layoutManager;
{
	CGFloat tRadius=round([self cellSize].height*0.5);
	
	NSRect tRect=NSInsetRect(inCellFrame,1.0, 1.0);
	tRect.origin.x+=0.5;
	tRect.origin.y+=0.5;
	
	NSBezierPath* tBezierPath=[NSBezierPath bezierPathWithRoundedRect:tRect xRadius:tRadius yRadius:tRadius];
	
	if (_highlighted==NO)
		[[NSColor colorWithCalibratedRed:215.0/255.0 green:226.0/255.0 blue:246.0/255.0 alpha:1.0] setFill];
	else
		[[NSColor colorWithCalibratedRed:60.0/255.0 green:116.0/255.0 blue:231.0/255.0 alpha:1.0] setFill];	// 36 /93 / 226  ; 60 / 116 /231
	
	[tBezierPath fill];
	
	if (_highlighted==NO)
		[[NSColor colorWithCalibratedRed:149.0/255.0 green:176.0/255.0 blue:231.0/255.0 alpha:1.0] setStroke];
	else
		[[NSColor colorWithCalibratedRed:40.0/255.0 green:75.0/255.0 blue:141.0/255.0 alpha:1.0] setStroke];
	
	[tBezierPath stroke];
	
	
	
	NSSize tSize=[self.tokenLabel size];
	
	NSRect tTextRect=NSMakeRect(NSMinX(inCellFrame)+tRadius-1.0,NSMaxY(inCellFrame)-4.0,tSize.width,tSize.height);
	
	NSDictionary * tAttributes=[self.tokenLabel attributesAtIndex:0 longestEffectiveRange:NULL inRange:NSMakeRange(0,self.tokenLabel.string.length)];
	
	NSMutableDictionary * tDrawingAttributes=[tAttributes mutableCopy];
	[tDrawingAttributes removeObjectForKey:NSParagraphStyleAttributeName];
	tDrawingAttributes[NSForegroundColorAttributeName]=(_highlighted==NO) ? [NSColor textColor] : [NSColor whiteColor];
	
	[self.tokenLabel.string drawWithRect:tTextRect options:0 attributes:tDrawingAttributes];
}

@end

@implementation PKGLicenseProvider (UI)

+ (void)UI_replaceKeywords:(NSDictionary *)inDictionary inAttributedString:(NSMutableAttributedString *)inMutableAttributedString
{
	if (inDictionary==nil || inMutableAttributedString==nil)
		return;
	
	NSString * tString=inMutableAttributedString.string;
	NSRange tFoundRange={.location=0,.length=0};
	
	while (1)
	{
		tFoundRange=[tString rangeFromString:@"%%" toString:@"%%" options:0 range:NSMakeRange(NSMaxRange(tFoundRange),[tString length]-NSMaxRange(tFoundRange))];
		
		if (tFoundRange.location==NSNotFound)
			return;
		
		NSString * tKey=[tString substringWithRange:NSMakeRange(tFoundRange.location+2,tFoundRange.length-4)];
		NSString * tValue=inDictionary[tKey];
		
		if (tValue!=nil && [tValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length>0)
		{
			[inMutableAttributedString replaceCharactersInRange:tFoundRange
													 withString:tValue];
		}
		else
		{
			NSTextAttachment * tTextAttachment=[[NSTextAttachment alloc] initWithFileWrapper:nil];
			
			PKGTokenTextAttachmentCell * tTokenTextAttachmentCell=[[PKGTokenTextAttachmentCell alloc] initTextCell:@""];
			
			tTokenTextAttachmentCell.tokenLabel=[inMutableAttributedString attributedSubstringFromRange:NSMakeRange(tFoundRange.location+2,tFoundRange.length-4)];
			
			tTextAttachment.attachmentCell=tTokenTextAttachmentCell;
			
			NSAttributedString * tAttributedString=[NSAttributedString attributedStringWithAttachment:tTextAttachment];
			
			[inMutableAttributedString replaceCharactersInRange:tFoundRange
										   withAttributedString:tAttributedString];
		}
		
		tString=inMutableAttributedString.string;
		
		tFoundRange.length=tValue.length;
	}
}

@end


#import "NSTextFieldCell+LabelColor.h"

#include <objc/runtime.h>

@implementation NSTextFieldCell (LabelColor_WB)

+ (void)LABELCOLOR_Swizzle:(SEL)inOriginalSelector with:(SEL)inSHITSelector
{
	Class tClass=[self class];
	
	Method originalMethod = class_getInstanceMethod(tClass, inOriginalSelector);
	Method swizzledMethod = class_getInstanceMethod(tClass, inSHITSelector);
	
	// When swizzling a class method, use the following:
	// Class class = object_getClass((id)self);
	// ...
	// Method originalMethod = class_getClassMethod(class, inOriginalSelector);
	// Method swizzledMethod = class_getClassMethod(class, inSHITSelector);
	
	BOOL didAddMethod =
	class_addMethod(tClass,
					inOriginalSelector,
					method_getImplementation(swizzledMethod),
					method_getTypeEncoding(swizzledMethod));
	
	if (didAddMethod==YES)
	{
		class_replaceMethod(tClass,
							inSHITSelector,
							method_getImplementation(originalMethod),
							method_getTypeEncoding(originalMethod));
	}
	else
	{
		method_exchangeImplementations(originalMethod, swizzledMethod);
	}
}

+ (void)load
{
	if (NSAppKitVersionNumber<NSAppKitVersionNumber10_10)
		return;
	
	[self LABELCOLOR_Swizzle:@selector(textColor) with:@selector(LABELCOLOR_textColor)];
}

- (NSColor *)LABELCOLOR_textColor
{
	NSColor * tColor=[self LABELCOLOR_textColor];
	
	if ([self isMemberOfClass:[NSTextFieldCell class]]==NO)
		return tColor;
	
	if (self.isEditable==YES || self.drawsBackground==YES)
		return tColor;
	
	NSView * tSuperview=[self.controlView superview];
	
	if (tSuperview==nil)
		return tColor;
	
	if ([tSuperview isKindOfClass:[NSTableCellView class]]==YES)
		return tColor;
	
	
	
	if ([tColor isEqual:[NSColor controlTextColor]]==YES)
		return [NSColor labelColor];
	
	if ([tColor isEqual:[NSColor disabledControlTextColor]]==YES)
		return [NSColor secondaryLabelColor];
	
	return tColor;
}

@end

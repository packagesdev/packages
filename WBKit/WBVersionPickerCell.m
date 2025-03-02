
#import "WBVersionPickerCell.h"

#ifndef MAC_OS_X_VERSION_10_10
#define MAC_OS_X_VERSION_10_10 101000
#endif

#ifndef NSAppKitVersionNumber10_14
#define NSAppKitVersionNumber10_14 1641
#endif


// --------- Private APIs ------------

@interface NSView (AppKit_Non_Public_APIs)

- (BOOL)_automaticFocusRingDisabled;

@end

@interface NSWindow (AppKit_Non_Public_APIs)

- (BOOL)hasKeyAppearance;

@end

@interface NSCell (AppKit_Non_Public_APIs)

- (void)_contents;

- (void)_updateInvalidatedObjectValue:(id)inValue;

@end

void _NSDrawCarbonThemeBezel(NSRect,BOOL,BOOL);

//---------------------------------------

@interface WBVersionPickerCellElement : NSObject <NSCopying>

    @property WBVersionPickerCellElementType elementType;
    @property (copy) NSString * stringValue;
    @property NSRect frame;

- (instancetype)initWithElementType:(WBVersionPickerCellElementType)inElementType frame:(NSRect)inFrame stringValue:(NSString *)inStringValue;

@end

@implementation WBVersionPickerCellElement

- (instancetype)initWithElementType:(WBVersionPickerCellElementType)inElementType frame:(NSRect)inFrame stringValue:(NSString *)inStringValue
{
	self=[super init];
	
	if (self!=nil)
	{
		_elementType=inElementType;
		_frame=inFrame;
		_stringValue=[inStringValue copy];
	}
	
	return self;
}

- (id)copyWithZone:(NSZone *)inZone
{
	WBVersionPickerCellElement * nVersionPickerCellElement=[[self class] allocWithZone:inZone];
	
    if (nVersionPickerCellElement!=nil)
    {
        nVersionPickerCellElement.elementType=self.elementType;
        nVersionPickerCellElement.frame=self.frame;
        nVersionPickerCellElement.stringValue=self.stringValue;
    }
    
	return nVersionPickerCellElement;
}

@end

NSString * const WBVersionPickerCellSelectedElementDidChangeNotification=@"WBVersionPickerCellSelectedElementDidChangeNotification";

typedef NS_ENUM(NSUInteger, WBVersionPickerCellTrackingAreaType)
{
	WBVersionPickerCellTrackingAreaNone=0,
	WBVersionPickerCellTrackingAreaText,
	WBVersionPickerCellTrackingAreaStepper
};

#define WBVersionPickerCell_Padding_Left	2.5
#define WBVersionPickerCell_Padding_Right	2.5
#define WBVersionPickerCell_Padding_Bottom	2.5
#define WBVersionPickerCell_Padding_Top		2.5

@interface WBVersionPickerCell ()
{
	NSNumberFormatter * _numberFormatter;
	
	NSMutableArray * _elements;
	NSStepperCell * _stepperCell;
	
	
	WBVersionPickerCellTrackingAreaType _trackingArea;
	
    NSInteger _selectedElementIndex;
	
	BOOL _didEditElement;
	BOOL _didEnableEditionTimer;
}

- (IBAction)takeValueFrom:(id)sender;
- (NSStepperCell *)stepperCell;

- (NSRect)focusRingMaskBoundsForFrame:(NSRect)inFrame inView:(NSView *)inView;

- (CGFloat)horizontalOffsetForElementsOfTextAreaFrame:(NSRect)inTextAreaFrame;
- (BOOL)isWritingDirectionRightToLeft;
- (NSSize)proposedTextAreaSize;
- (void)getTextAreaFrame:(NSRect *)outTextAreaFrame stepperCellFrame:(NSRect *)outStepperFrame forVersionPickerCellFrame:(NSRect)inCellFrame;

- (NSInteger)indexOfElementAtPoint:(NSPoint)inPoint inTextAreaFrame:(NSRect)inFrame;

- (void)selectedElementDidChange;

- (void)updateElements;
- (void)updateSelectedElementWithDelta:(NSInteger)inDelta;
- (void)_commitElementFieldChanges;
- (void)_userEditExpired:(id)inObject;

- (void)endEditingSelectedElement;

- (void)selectFirstElement;
- (void)selectLastElement;

- (void)selectPreviousElement;
- (void)selectNextElement;

- (void)updateElementsStringValuesForVersionChange;

- (NSInteger)_digitForLocalizedDigitCharacter:(unichar)inCharacter;
- (void)_insertDigit:(NSInteger)inDigit;
- (void)_deleteDigit;

@end

@implementation WBVersionPickerCell

+ (void)initialize
{
	if (self==[WBVersionPickerCell class])
        [self setVersion:1];
}

- (instancetype)init
{
	self=[super initTextCell:@""];
    
    [self commonInit];
    
    return self;
}

- (instancetype)initTextCell:(NSString *)inString
{
    self=[super initTextCell:inString];
    
    [self commonInit];
    
    return self;
}

- (void)commonInit
{
    _trackingArea=WBVersionPickerCellTrackingAreaNone;
    
    _versionPickerStyle=WBTextFieldAndStepperVersionPickerStyle;
    
    _backgroundColor=[[NSColor controlBackgroundColor] copy];
    _textColor=[[NSColor controlTextColor] copy];
    
    [super setFont:[NSFont systemFontOfSize:[self controlSize]]];
    
    _numberFormatter=[NSNumberFormatter new];
    _numberFormatter.formatterBehavior=NSNumberFormatterBehavior10_4;
    _numberFormatter.locale=[NSLocale currentLocale];
    
    _versionsHistory=[WBVersionsHistory versionsHistory];
    
    _minVersion=nil;
    _maxVersion=nil;
    
    _didEditElement=NO;
    _didEnableEditionTimer=NO;
    
    [self setVersionValue:[WBVersion new]];
    
    [self updateElements];
}

#pragma mark - Layout computations

- (NSSize)cellSize
{
    NSSize tSize=[self proposedTextAreaSize];
	
	if (self.versionPickerStyle==WBTextFieldAndStepperVersionPickerStyle)
	{
		NSSize tStepperCellSize=[[self stepperCell] cellSize];
		
		tSize.width=tSize.width+tStepperCellSize.width;
		
		if (tStepperCellSize.height>tSize.height)
			tSize.height=tStepperCellSize.height;
	}
	
	return tSize;
}

- (CGFloat)horizontalOffsetForElementsOfTextAreaFrame:(NSRect)inTextAreaFrame
{
    if (_elements.count==0 || [self isWritingDirectionRightToLeft]==NO)
        return 0.0;
    
    WBVersionPickerCellElement * tLastElement=_elements.lastObject;
        
	return (NSMaxX(inTextAreaFrame)-NSMaxX(tLastElement.frame)-WBVersionPickerCell_Padding_Right);
}

- (NSSize)proposedTextAreaSize
{
    if (_elements.count==0)
		[self updateElements];
    
    NSSize tSize=NSZeroSize;
    
    if (_elements.count>0)
    {
        WBVersionPickerCellElement * tFirstElement=_elements.firstObject;
        WBVersionPickerCellElement * tLastElement=_elements.lastObject;
        
        NSRect tFirstFrame=tFirstElement.frame;
        NSRect tLastFrame=tLastElement.frame;
        
        tSize.width=NSMaxX(tLastFrame)-NSMinX(tFirstFrame);
        tSize.height=NSHeight(tFirstFrame);
    }
	
	tSize.width+=(WBVersionPickerCell_Padding_Left+WBVersionPickerCell_Padding_Right);
	tSize.height+=(WBVersionPickerCell_Padding_Bottom+WBVersionPickerCell_Padding_Top);
	
    return tSize;
}

- (void)getTextAreaFrame:(NSRect *)outTextAreaFrame stepperCellFrame:(NSRect *)outStepperFrame forVersionPickerCellFrame:(NSRect)inCellFrame
{
    NSSize tDesiredTextAreaSize=[self proposedTextAreaSize];
    
    NSRect tTextAreaFrame;
    
    tTextAreaFrame.origin=NSZeroPoint;
    tTextAreaFrame.size.width=NSWidth(inCellFrame);
    tTextAreaFrame.size.height=tDesiredTextAreaSize.height;
    
    if (self.versionPickerStyle==WBTextFieldAndStepperVersionPickerStyle)
    {
        NSSize tStepperCellSize=[[self stepperCell] cellSize];
		CGFloat tStepperCellHeight=tStepperCellSize.height;
		
		switch([self controlSize])
		{
			case WBControlSizeRegular:
				
				tStepperCellHeight-=4.0;
				break;
				
			case WBControlSizeSmall:
				
				tStepperCellHeight-=2.0;
				break;
				
			default:
				
				break;
		}
		
        tTextAreaFrame.size.width-=tStepperCellSize.width;
        
        NSRect tStepperFrame;
        BOOL isRTL=[self isWritingDirectionRightToLeft];
        
        if (isRTL==YES)
        {
            tStepperFrame.origin.x=NSMinX(inCellFrame);
            tTextAreaFrame.origin.x=tStepperCellSize.width;
        }
        else
        {
            tStepperFrame.origin.x=NSWidth(tTextAreaFrame);
        }
		
        tStepperFrame.origin.y=0;
        tStepperFrame.size.width=tStepperCellSize.width;
        tStepperFrame.size.height=tStepperCellHeight;
        
        if (tDesiredTextAreaSize.height<NSHeight(tStepperFrame))
            tTextAreaFrame.size.height=NSHeight(tStepperFrame);
        
        if (tDesiredTextAreaSize.height>NSHeight(tStepperFrame))
            tStepperFrame.origin.y=(tDesiredTextAreaSize.height-NSHeight(tStepperFrame))*0.5;
        
		if (outStepperFrame!=NULL)
			*outStepperFrame=tStepperFrame;
    }
    else
    {
        if (outStepperFrame!=NULL)
			*outStepperFrame=NSZeroRect;
    }
    
    if (outTextAreaFrame!=NULL)
		*outTextAreaFrame=tTextAreaFrame;
}

#pragma mark - Properties accessors

- (void)setFont:(NSFont *)inFont
{
    [super setFont:inFont];
    
    if (_elements!=nil)
        [self updateElements];
    
    [((NSControl *)[self controlView]) updateCell:self];
    [((NSControl *)[self controlView]) invalidateIntrinsicContentSizeForCell:self];
}

- (void)setTextColor:(NSColor *)inTextColor
{
	if ([_textColor isEqual:inTextColor]==NO)
	{
        _textColor=[inTextColor copy];
        [((NSControl *)[self controlView]) updateCell:self];
    }
}

- (void)setBackgroundColor:(NSColor *)inBackgroundColor
{
	if ([_backgroundColor isEqual:inBackgroundColor]==NO)
	{
        _backgroundColor=[inBackgroundColor copy];
        [((NSControl *)[self controlView]) updateCell:self];
    }
}

- (void)setDrawsBackground:(BOOL)inDrawsBackground
{
	if (_drawsBackground!=inDrawsBackground)
    {
         _drawsBackground=inDrawsBackground;
         [((NSControl *)[self controlView]) updateCell:self];
    }
}

- (void)setEnabled:(BOOL)inEnabled
{
    if (self.versionPickerStyle==WBTextFieldAndStepperVersionPickerStyle)
        [[self stepperCell] setEnabled:inEnabled];
    
    [super setEnabled:inEnabled];
	
	if (inEnabled==NO)
		_selectedElementIndex=[self firstSelectableElement];
}

- (WBVersion *)versionValue
{
	[self _contents];

    return [self objectValue];
}

- (void)setVersionValue:(WBVersion *)inVersionValue
{
	[self setObjectValue:inVersionValue];
}

- (void)setObjectValue:(id)inObject
{
    if ([inObject respondsToSelector:@selector(isKindOfClass:)]==YES && [inObject isKindOfClass:WBVersion.class]==YES)
		[self _constrainAndSetVersionValue:inObject sendActionIfChanged:NO beepIfNoChange:NO];
}

- (void)setMinVersion:(WBVersion *)inMinVersion
{
	if (_minVersion!=inMinVersion)
	{
		_minVersion=[inMinVersion copy];
		
		if (_minVersion!=nil)
			[self setVersionValue:self.versionValue];
    }
}

- (void)setMaxVersion:(WBVersion *)inMaxVersion
{
	if (_maxVersion!=inMaxVersion)
	{
		_maxVersion=[inMaxVersion copy];
		
		if (_maxVersion!=nil)
			[self setVersionValue:self.versionValue];
    }
}
- (void)setVersionPickerStyle:(WBVersionPickerStyle)inVersionPickerStyle
{
    if (inVersionPickerStyle>WBTextFieldVersionPickerStyle)
        return;
    
    if (_versionPickerStyle==inVersionPickerStyle)
        return;
    
    _versionPickerStyle=inVersionPickerStyle;
    
    if (_versionPickerStyle==WBTextFieldVersionPickerStyle)
		_stepperCell=nil;
    
    _elements=nil;
    
    [((NSControl *)[self controlView]) updateCell:self];
    [((NSControl *)[self controlView]) invalidateIntrinsicContentSizeForCell:self];
}

- (void)setVersionsHistory:(WBVersionsHistory *)inVersionsHistory
{
	if (inVersionsHistory==nil)
		inVersionsHistory=[WBVersionsHistory versionsHistory];
	
	if (_versionsHistory==inVersionsHistory)
		return;
	
	_versionsHistory=[inVersionsHistory copy];
	
	WBVersion * tNewVersionValue=self.versionValue;
	
	if ([_versionsHistory validateVersion:tNewVersionValue]==NO)
	{
		// Set the version value to the minimum one according to the versions history
		
		WBVersionComponents * tVersionComponents=[WBVersionComponents new];
		
		tVersionComponents.majorVersion=[_versionsHistory minimumRangeOfUnit:WBMajorVersionUnit].location;
		tVersionComponents.minorVersion=[_versionsHistory minimumRangeOfUnit:WBMinorVersionUnit].location;
		tVersionComponents.patchVersion=[_versionsHistory minimumRangeOfUnit:WBPatchVersionUnit].location;
		
		tNewVersionValue=[_versionsHistory versionFromComponents:tVersionComponents];
	}
	
	tNewVersionValue=[self _constrainVersionValue:tNewVersionValue];
	
	[self setVersionValue:tNewVersionValue];
	
	[self updateElements];
	
	[((NSControl *)[self controlView]) updateCell:self];
}

- (void)setDelegate:(id<WBVersionPickerCellDelegate>)inDelegate
{
	_delegate=inDelegate;
	
	if (_selectedElementIndex<0)
		return;
	
	if (_elements==nil || _selectedElementIndex>=_elements.count)
		return;
	
	if (_delegate!=nil && [_delegate respondsToSelector:@selector(versionPickerCell:shouldSelectElementType:)]==YES)
	{
		WBVersionPickerCellElement * tCellElement=_elements[_selectedElementIndex];
		
		if ([_delegate versionPickerCell:self shouldSelectElementType:tCellElement.elementType]==NO)
		{
			_selectedElementIndex=[self firstSelectableElement];
			
			[self selectedElementDidChange];
			[((NSControl *)[self controlView]) updateCell:self];
		}
	}
}

#pragma mark -

- (void)updateElementsStringValuesForVersionChange
{
	for(WBVersionPickerCellElement * tElement in _elements)
	{
		if (tElement.elementType!=WBVersionPickerCellElementSeparator)
			tElement.stringValue=[self _stringForVersionPickerElement:tElement.elementType];
	}
}

- (WBVersion *)_constrainVersionValue:(WBVersion *)inVersionValue
{
	WBVersion * tVersionValue=inVersionValue;
	
	if (self.minVersion!=nil && [self.minVersion compare:inVersionValue]==NSOrderedDescending)
        tVersionValue=self.minVersion;
	
	if (self.maxVersion!=nil && [inVersionValue compare:self.maxVersion]==NSOrderedDescending)
        tVersionValue=self.maxVersion;
	
	if ([self.delegate respondsToSelector:@selector(versionPickerCell:versionValueForProposedVersionValue:)]==YES)
        tVersionValue=[self.delegate versionPickerCell:self versionValueForProposedVersionValue:tVersionValue];
	
	return tVersionValue;
}

- (BOOL)_constrainAndSetVersionValue:(WBVersion *)inVersionValue sendActionIfChanged:(BOOL)inSendAction beepIfNoChange:(BOOL)inBeep
{
	WBVersion * tOldVersionValue=self.versionValue;
	WBVersion * tNewVersionValue=[self _constrainVersionValue:inVersionValue];
	
	if (tOldVersionValue!=nil && [tOldVersionValue isEqual:tNewVersionValue]==YES)
    {
        if (inBeep==YES)
            NSBeep();
			
        return NO;
	}
	
	[super setObjectValue:tNewVersionValue];
	
	[self updateElementsStringValuesForVersionChange];
	
	[((NSControl *)[self controlView]) updateCell:self];
	
	if (inSendAction==YES)
    {
        NSControl * tControlView=(NSControl *)[self controlView];
        
        if ([tControlView respondsToSelector:@selector(sendAction:to:)]==YES)
            [tControlView sendAction:[self action] to:[self target]];
        else
            [NSApp sendAction:[self action] to:[self target] from:tControlView];
    }
    
    return YES;
}

#pragma mark -

- (BOOL)isWritingDirectionRightToLeft
{
    NSString * tLanguageCode=[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
    
    return ([NSParagraphStyle defaultWritingDirectionForLanguage:tLanguageCode]==NSWritingDirectionRightToLeft);
}

#pragma mark - Internal Navigation

- (NSInteger)firstSelectableElement
{
	NSInteger tSelectableIndex=-1;
	NSInteger tIndex=0;
	
	while (tIndex<_elements.count)
	{
		WBVersionPickerCellElement * tCellElement=_elements[tIndex];
		
		if (tCellElement.elementType!=WBVersionPickerCellElementSeparator)
		{
			if (self.delegate==nil ||
				[self.delegate respondsToSelector:@selector(versionPickerCell:shouldSelectElementType:)]==NO ||
				[self.delegate versionPickerCell:self shouldSelectElementType:tCellElement.elementType]==YES)
			{
				tSelectableIndex=tIndex;
				break;
			}
		}
		
		tIndex++;
	}
	
	if (tSelectableIndex==-1)
		NSLog(@"<%@: 0x%lx> No selectable elements. There might be a problem",NSStringFromClass([self class]),(unsigned long)self);
	
	return tSelectableIndex;
}

- (NSInteger)lastSelectableElement
{
	NSInteger tSelectableIndex=-1;
	
	NSInteger tIndex=_elements.count-1;
	
	while (tIndex>=0)
	{
		WBVersionPickerCellElement * tCellElement=_elements[tIndex];
		
		if (tCellElement.elementType!=WBVersionPickerCellElementSeparator)
		{
			if (self.delegate==nil ||
				[self.delegate respondsToSelector:@selector(versionPickerCell:shouldSelectElementType:)]==NO ||
				[self.delegate versionPickerCell:self shouldSelectElementType:tCellElement.elementType]==YES)
			{
				tSelectableIndex=tIndex;
				break;
			}
		}
		
		tIndex--;
	}
	
	if (tSelectableIndex==-1)
		NSLog(@"<%@: 0x%lx> No selectable elements. There might be a problem",NSStringFromClass([self class]),(unsigned long)self);
	
	return tSelectableIndex;
}

- (void)selectFirstElement
{
	_selectedElementIndex=[self firstSelectableElement];
	
	if (_selectedElementIndex<0)
		return;
	
	[self selectedElementDidChange];
	[((NSControl *)[self controlView]) updateCell:self];
}

- (void)selectPreviousElement
{
    if (_selectedElementIndex<0)
        return;
    
    NSInteger tSavedIndex=_selectedElementIndex;
	
    do
    {
        _selectedElementIndex--;
        
        if (_selectedElementIndex<0)
            _selectedElementIndex=_elements.count-1;
		
		WBVersionPickerCellElement * tCellElement=_elements[_selectedElementIndex];
		
        if (tCellElement.elementType!=WBVersionPickerCellElementSeparator)
		{
			if (self.delegate==nil ||
				[self.delegate respondsToSelector:@selector(versionPickerCell:shouldSelectElementType:)]==NO ||
				[self.delegate versionPickerCell:self shouldSelectElementType:tCellElement.elementType]==YES)
			{
				break;
			}
		}
    }
    while (_selectedElementIndex!=tSavedIndex);
    
    [self selectedElementDidChange];
    [((NSControl *)[self controlView]) updateCell:self];
}

- (void)selectNextElement
{
	if (_selectedElementIndex<0)
		return;
	
	NSInteger tSavedIndex=_selectedElementIndex;
	
	do
	{
		_selectedElementIndex++;
		
		if (_selectedElementIndex>=_elements.count)
			_selectedElementIndex=0;
		
		WBVersionPickerCellElement * tCellElement=_elements[_selectedElementIndex];
		
		if (tCellElement.elementType!=WBVersionPickerCellElementSeparator)
		{
			if (self.delegate==nil ||
				[self.delegate respondsToSelector:@selector(versionPickerCell:shouldSelectElementType:)]==NO ||
				[self.delegate versionPickerCell:self shouldSelectElementType:tCellElement.elementType]==YES)
			{
				break;
			}
		}
	}
	while (_selectedElementIndex!=tSavedIndex);
	
	[self selectedElementDidChange];
	[((NSControl *)[self controlView]) updateCell:self];
}

- (void)selectLastElement
{
    _selectedElementIndex=[self lastSelectableElement];
    
    if (_selectedElementIndex<0)
		return;
    
    [self selectedElementDidChange];
    [((NSControl *)[self controlView]) updateCell:self];
}

- (void)selectedElementDidChange
{
	if ([self.delegate respondsToSelector:@selector(versionPickerCellSelectedElementDidChange:)]==YES)
		[self.delegate versionPickerCellSelectedElementDidChange:self];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:WBVersionPickerCellSelectedElementDidChangeNotification object:self];
}

#pragma mark -

- (NSString *)_stringForVersionPickerElement:(WBVersionPickerCellElementType)inVersionPickerElement
{
	WBVersionComponents * tVersionComponents=[self.versionsHistory components:WBMajorVersionUnit|WBMinorVersionUnit|WBPatchVersionUnit fromVersion:self.versionValue];
	
	NSInteger tValue=-1;
	
	switch(inVersionPickerElement)
	{
		case WBVersionPickerCellElementMajorVersion:
			
			tValue=tVersionComponents.majorVersion;
			break;
			
		case WBVersionPickerCellElementMinorVersion:
			
			tValue=tVersionComponents.minorVersion;
			break;
			
		case WBVersionPickerCellElementPatchVersion:
			
			tValue=tVersionComponents.patchVersion;
			break;
            
        default:
			
            break;
	}
	
	NSString * tString=[NSString stringWithFormat:@"%ld",(long)tValue];
    
    return tString;
}

- (void)addElementOfType:(WBVersionPickerCellElementType)inElementType referenceStrings:(NSArray *)inReferenceStrings
{
    NSRect tElementFrame=NSZeroRect;

    NSDictionary * tAttributesDictionary=@{NSFontAttributeName:self.font};
    
    for(NSString * tReferenceString in inReferenceStrings)
    {
    	NSSize tSize=[tReferenceString sizeWithAttributes:tAttributesDictionary];
    	
    	if (tSize.width>NSWidth(tElementFrame))
            tElementFrame.size.width=tSize.width;
            
        if (tSize.height>NSHeight(tElementFrame))
            tElementFrame.size.height=tSize.height;
    }
    
    WBVersionPickerCellElement * tLastElement=_elements.lastObject;
	tElementFrame.origin.x=(tLastElement!=nil) ? NSMaxX(tLastElement.frame) : WBVersionPickerCell_Padding_Left;
    
    NSString * tStringValue=inReferenceStrings.firstObject;
    
    if (inElementType!=WBVersionPickerCellElementSeparator)
    	tStringValue=[self _stringForVersionPickerElement:inElementType];
    
    WBVersionPickerCellElement * nElement=[[WBVersionPickerCellElement alloc] initWithElementType:inElementType frame:tElementFrame stringValue:tStringValue];
    
    [_elements addObject:nElement];
}

- (void)updateElements
{
    _elements=[NSMutableArray array];
	
	[self addElementOfType:WBVersionPickerCellElementMajorVersion referenceStrings:@[@"88"]];
	[self addElementOfType:WBVersionPickerCellElementSeparator referenceStrings:@[@"."]];
	[self addElementOfType:WBVersionPickerCellElementMinorVersion referenceStrings:@[@"44"]];
	[self addElementOfType:WBVersionPickerCellElementSeparator referenceStrings:@[@"."]];
	[self addElementOfType:WBVersionPickerCellElementPatchVersion referenceStrings:@[@"44"]];
    
    _selectedElementIndex=[self firstSelectableElement];
    
    [self selectedElementDidChange];
}

#pragma mark -

- (IBAction)takeValueFrom:(id)sender
{
	[self _cancelUserEditTimer];
	_didEditElement=NO;
	
	[self updateElementsStringValuesForVersionChange];
	[((NSControl *)[self controlView]) updateCell:self];
	
    if (_selectedElementIndex>=0)
    {
		NSStepperCell * tStepperCell=[self stepperCell];
		
		if (tStepperCell==nil)
			return;
		
		[self updateSelectedElementWithDelta:round([tStepperCell doubleValue])];
		
		[tStepperCell setDoubleValue:0.0];
    }
}

- (NSStepperCell *)stepperCell
{
    if (self.versionPickerStyle==WBTextFieldAndStepperVersionPickerStyle)
    {
		if (_stepperCell==nil)
		{
			_stepperCell=[NSStepperCell new];
			
			[_stepperCell setTarget:self];
			[_stepperCell setAction:@selector(takeValueFrom:)];
            
            [_stepperCell setValueWraps:NO];
			[_stepperCell setMinValue:-1.0];
			[_stepperCell setMaxValue:1.0];
			[_stepperCell setDoubleValue:0.0];
			[_stepperCell setIncrement:2.0];
			
			[_stepperCell setEnabled:[self isEnabled]];
		}
        
		if ([self controlSize]!=[_stepperCell controlSize])
			[_stepperCell setControlSize:[self controlSize]];
    }
    
    return _stepperCell;
}

#pragma mark -

- (NSRect)focusRingMaskBoundsForFrame:(NSRect)inFrame inView:(NSView *)inView
{
    if ([self isEditable]==NO || [self showsFirstResponder]==NO)
        return NSZeroRect;
    
    NSRect tTextAreaFrame;
        	
    [self getTextAreaFrame:&tTextAreaFrame stepperCellFrame:NULL forVersionPickerCellFrame:inFrame];
 			
    return tTextAreaFrame;
}

#pragma mark -

- (void)drawWithFrame:(NSRect)inFrame inView:(NSView *)inView
{
	if ([self isBordered]==YES)
		[self _updateInvalidatedObjectValue:nil];
            
	BOOL tShowFocusRing=NO;
	
	if ([inView _automaticFocusRingDisabled]==YES)
	{
		NSFocusRingType tFocusRingType=[self focusRingType];
		
		if (tFocusRingType==NSFocusRingTypeNone)
			tFocusRingType=[[self class] defaultFocusRingType];
		
		if ([self showsFirstResponder]==NO ||
			(tFocusRingType==NSFocusRingTypeNone) ||
			([inView.window firstResponder]!=inView))
		{
			tShowFocusRing=NO;
		}
		else
		{
			tShowFocusRing=[inView.window hasKeyAppearance];
		}
	}
	
	NSRect tStepperCellFrame;
	NSRect tTextAreaFrame;
	
	[self getTextAreaFrame:&tTextAreaFrame stepperCellFrame:&tStepperCellFrame forVersionPickerCellFrame:inFrame];
	
	if (self.versionPickerStyle==WBTextFieldAndStepperVersionPickerStyle)
        [[self stepperCell] drawWithFrame:tStepperCellFrame inView:inView];
	
	if (tShowFocusRing==YES)
	{
		[NSGraphicsContext saveGraphicsState];
		NSSetFocusRingStyle((self.drawsBackground==YES) ? NSFocusRingBelow : NSFocusRingOnly);
		
		[[self backgroundColor] set];

		NSRectFill(tTextAreaFrame);
		[NSGraphicsContext restoreGraphicsState];
	}
	else
	{
		if (self.drawsBackground==YES)
		{
			[[self backgroundColor] set];
			
			NSRectFill(tTextAreaFrame);
		}
	}
	
	if ([self isBezeled]==YES)
	{
        if (NSAppKitVersionNumber>=NSAppKitVersionNumber10_14)
        {
            [[NSColor containerBorderColor] set];
            
            NSFrameRectWithWidthUsingOperation(tTextAreaFrame,1.0, WBCompositingOperationSourceOver);
        }
        else
        {
            BOOL tIsDrawnEditable=([self isEnabled]==YES) ? [self isEditable] : NO;
		
            _NSDrawCarbonThemeBezel(tTextAreaFrame,tIsDrawnEditable,[inView isFlipped]);
        }
	}
	else
	{
		if ([self isBordered]==YES)	// Bordered and bezeled are mutually exclusive
		{
			[[NSColor blackColor] setFill];
			
			NSFrameRectWithWidthUsingOperation(tTextAreaFrame,-1.0, WBCompositingOperationSourceOver);
		}
	}
	
	[NSGraphicsContext saveGraphicsState];
	
	NSRectClip(tTextAreaFrame);
	
	CGFloat tOffset=[self horizontalOffsetForElementsOfTextAreaFrame:tTextAreaFrame];
	
    WBVersionPickerCellElement * tSelectedElement=nil;
    
	if ([self showsFirstResponder]==YES && [inView.window hasKeyAppearance]==YES && [inView.window firstResponder]==inView)
	{
		if (_selectedElementIndex>=0 && _selectedElementIndex<_elements.count)
		{
			tSelectedElement=_elements[_selectedElementIndex];
			
			NSRect tElementFrame=NSInsetRect(tSelectedElement.frame,-1.0, 0.0);
			
			tElementFrame=NSOffsetRect(tElementFrame,tOffset,(-1.0+(1.0+WBVersionPickerCell_Padding_Bottom)));
			
			[NSColor.selectedContentBackgroundColor setFill];

#define WBVersionPickerCellSelectedElementRadius	3.0
			
			[[NSBezierPath bezierPathWithRoundedRect:tElementFrame xRadius:WBVersionPickerCellSelectedElementRadius yRadius:WBVersionPickerCellSelectedElementRadius] fill];
		}
	}
	
    NSMutableParagraphStyle * tMutableParagraphStyle=[NSMutableParagraphStyle new];
	tMutableParagraphStyle.alignment=WBTextAlignmentCenter;
    
	NSColor * tTextColor;
	
	if (self.isEnabled==NO)
	{
		tTextColor=[NSColor disabledControlTextColor];
	}
	else
	{
		tTextColor=self.textColor;
		
		if (tTextColor==nil)
			tTextColor=[NSColor controlTextColor];
	}
	
	NSDictionary * tAttributesDictionary=@{NSFontAttributeName:self.font,
										   NSForegroundColorAttributeName:tTextColor,
										   NSParagraphStyleAttributeName:tMutableParagraphStyle};
	
	NSDictionary * tDisabledAttributesDictionary=@{NSFontAttributeName:self.font,
												   NSForegroundColorAttributeName:[NSColor disabledControlTextColor],
												   NSParagraphStyleAttributeName:tMutableParagraphStyle};
	
	for(WBVersionPickerCellElement * tElement in _elements)
	{
		NSRect tElementFrame=NSOffsetRect(tElement.frame,tOffset, (1.0+WBVersionPickerCell_Padding_Bottom)	);
		
		if (self.delegate!=nil &&
			[self.delegate respondsToSelector:@selector(versionPickerCell:shouldSelectElementType:)]==YES &&
			[self.delegate versionPickerCell:self shouldSelectElementType:tElement.elementType]==NO)
		
			[tElement.stringValue drawInRect:tElementFrame withAttributes:tDisabledAttributesDictionary];
		else
        {
			if (tSelectedElement==tElement)
            {
                NSDictionary * tSelectedAttributesDictionary=@{NSFontAttributeName:self.font,
                                                       NSForegroundColorAttributeName:[NSColor alternateSelectedControlTextColor],
                                                       NSParagraphStyleAttributeName:tMutableParagraphStyle};
                
                [tElement.stringValue drawInRect:tElementFrame withAttributes:tSelectedAttributesDictionary];
            }
            else
                [tElement.stringValue drawInRect:tElementFrame withAttributes:tAttributesDictionary];
        }
	}
	
	[NSGraphicsContext restoreGraphicsState];
}

#pragma mark - Mouse interaction

- (NSInteger)indexOfElementAtPoint:(NSPoint)inPoint inTextAreaFrame:(NSRect)inFrame
{
    CGFloat tOffset=[self horizontalOffsetForElementsOfTextAreaFrame:inFrame];
	
    for(NSInteger tIndex=_elements.count-1;tIndex>=0;tIndex--)
    {
        WBVersionPickerCellElement * tElement=_elements[tIndex];
        
        NSRect tElementFrame=NSOffsetRect(tElement.frame,tOffset,0);
        
        if (NSPointInRect(inPoint,tElementFrame)==YES)
            return tIndex;
    }
    
    return -1;
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView
{
	return NO;
}

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView
{
	return NO;
}

- (BOOL)trackMouse:(NSEvent *)inEvent inRect:(NSRect)inRect ofView:(NSView *)inView untilMouseUp:(BOOL)aBool
{
	NSPoint tPoint=[inView convertPoint:inEvent.locationInWindow fromView:nil];
	NSEventType tType=inEvent.type;
	
	if (tType==WBEventTypeLeftMouseDown)
		_trackingArea=WBVersionPickerCellTrackingAreaNone;
	
	NSRect tTextAreaFrame;
	NSRect tStepperCellFrame;
	
	[self getTextAreaFrame:&tTextAreaFrame stepperCellFrame:&tStepperCellFrame forVersionPickerCellFrame:inRect];
	
	WBVersionPickerCellTrackingAreaType tTrackingArea=WBVersionPickerCellTrackingAreaNone;
	
	if (self.versionPickerStyle==WBTextFieldAndStepperVersionPickerStyle && NSPointInRect(tPoint,tStepperCellFrame)==YES)
		tTrackingArea=WBVersionPickerCellTrackingAreaStepper;
	
	if (tTrackingArea==WBVersionPickerCellTrackingAreaNone && NSPointInRect(tPoint,tTextAreaFrame)==YES)
		tTrackingArea=WBVersionPickerCellTrackingAreaText;
	

	if (tType==WBEventTypeLeftMouseDragged && _trackingArea!=tTrackingArea)
		return NO;
	
	if (tType==WBEventTypeLeftMouseDown)
		_trackingArea=tTrackingArea;
	
	if (tTrackingArea==WBVersionPickerCellTrackingAreaStepper)
	{
		[self endEditingSelectedElement];
		
		return [[self stepperCell] trackMouse:inEvent inRect:tStepperCellFrame ofView:inView untilMouseUp:aBool];
	}
	
	if (tTrackingArea==WBVersionPickerCellTrackingAreaText)
	{
		NSInteger tIndex=[self indexOfElementAtPoint:tPoint inTextAreaFrame:tTextAreaFrame];
		
		if (tIndex!=-1 && tIndex!=_selectedElementIndex)
		{
			WBVersionPickerCellElement * tCellElement=_elements[tIndex];
			
			if (tCellElement.elementType!=WBVersionPickerCellElementSeparator)
			{
				if (self.delegate==nil ||
					[self.delegate respondsToSelector:@selector(versionPickerCell:shouldSelectElementType:)]==NO ||
					[self.delegate versionPickerCell:self shouldSelectElementType:tCellElement.elementType]==YES)
				{
					[self endEditingSelectedElement];
					_selectedElementIndex=tIndex;
					[self selectedElementDidChange];
				}
			}
		}
	}
	
	[((NSControl *)[self controlView]) updateCell:self];
	
	return NO;
}

#if (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10)
- (NSCellHitResult)hitTestForEvent:(NSEvent *)inEvent inRect:(NSRect)inRect ofView:(NSView *)inView
#else
- (NSUInteger)hitTestForEvent:(NSEvent *)inEvent inRect:(NSRect)inRect ofView:(NSView *)inView
#endif
{
	NSPoint tPoint=[inView convertPoint:inEvent.locationInWindow fromView:nil];
	
	NSRect tTextAreaFrame;
	NSRect tStepperFrame;
	
	[self getTextAreaFrame:&tTextAreaFrame stepperCellFrame:&tStepperFrame forVersionPickerCellFrame:inRect];
	
	if (self.versionPickerStyle==WBTextFieldAndStepperVersionPickerStyle && NSMouseInRect(tPoint, tStepperFrame,[inView isFlipped])==YES)
		return [[self stepperCell] hitTestForEvent:inEvent inRect:tStepperFrame ofView:inView];
	
	return ([self indexOfElementAtPoint:tPoint inTextAreaFrame:tTextAreaFrame]==-1) ? NSCellHitNone : (NSCellHitContentArea|NSCellHitEditableTextArea|NSCellHitTrackableArea);
}

#pragma mark - Keyboard Interaction

- (NSInteger)_digitForLocalizedDigitCharacter:(unichar)inCharacter
{
	NSNumber * tNumber=[_numberFormatter numberFromString:[NSString stringWithFormat:@"%c", inCharacter]];
    
    if (tNumber==nil)
    	return -1;
    
    return [tNumber integerValue];
}

- (void)_insertDigit:(NSInteger)inDigit
{
	if (_selectedElementIndex<0 || _elements.count==0)
		return;
	
    if (_didEditElement==NO && _didEnableEditionTimer==YES)
	{
		NSBeep();
		return;
	}
	
	WBVersionPickerCellElement * tElement=_elements[_selectedElementIndex];
	
    NSInteger tNewValue=inDigit;
    
	if (_didEditElement==YES)
	{
		tNewValue=tNewValue+10*[[_numberFormatter numberFromString:tElement.stringValue] integerValue];
	}
	
	NSRange tAllowedRange;
	
	switch(tElement.elementType)
	{
		case WBVersionPickerCellElementMajorVersion:
			
			tAllowedRange=[self.versionsHistory  maximumRangeOfUnit:WBMajorVersionUnit];
            
			break;
			
		case WBVersionPickerCellElementMinorVersion:
			
			tAllowedRange=[self.versionsHistory rangeOfUnit:WBMinorVersionUnit inUnit:WBMajorVersionUnit forVersion:self.versionValue];
			
			break;
			
		case WBVersionPickerCellElementPatchVersion:
			
			tAllowedRange=[self.versionsHistory rangeOfUnit:WBPatchVersionUnit inUnit:WBMinorVersionUnit forVersion:self.versionValue];
			
			break;
			
		default:
            
            tAllowedRange=NSMakeRange(NSNotFound,0);
            
			break;
	}
	
	if (tNewValue<tAllowedRange.location || tNewValue>=NSMaxRange(tAllowedRange))
	{
		NSBeep();
	}
	else
	{
        NSUInteger tMaxLength=[_numberFormatter stringFromNumber:@(NSMaxRange(tAllowedRange))].length;
		
		NSString * tStringValue=[_numberFormatter stringFromNumber:@(tNewValue)];
        
        tElement.stringValue=tStringValue;
		
		_didEditElement=YES;
        
        if (tStringValue.length<tMaxLength)
            [((NSControl *)[self controlView]) updateCell:self];
        else
            [self _commitElementFieldChanges];
	}
	
	[WBVersionPickerCell cancelPreviousPerformRequestsWithTarget:self selector:@selector(_userEditExpired:) object:nil];
	[self performSelector:@selector(_userEditExpired:) withObject:self afterDelay:[NSEvent keyRepeatDelay] inModes:@[NSRunLoopCommonModes]];
	
	_didEnableEditionTimer=YES;
}

- (void)endEditingSelectedElement
{
	[self _commitElementFieldChanges];
	[self _cancelUserEditTimer];
}

- (void)_commitElementFieldChanges
{
    if (_selectedElementIndex<0 || _didEditElement==NO)
        return;
    
    WBVersionComponents * tVersionComponents=[self.versionsHistory components:WBMajorVersionUnit|WBMinorVersionUnit|WBPatchVersionUnit fromVersion:self.versionValue];
    WBVersionPickerCellElement * tElement=_elements[_selectedElementIndex];
    
    NSInteger tValue=[tElement.stringValue integerValue];
    
    NSRange tAllowedRange;
    
    switch(tElement.elementType)
    {
        case WBVersionPickerCellElementMajorVersion:
            
            tAllowedRange=[self.versionsHistory maximumRangeOfUnit:WBMajorVersionUnit];
            
            if (NSLocationInRange(tValue,tAllowedRange)==YES)
				tVersionComponents.majorVersion=tValue;
            
            break;
            
        case WBVersionPickerCellElementMinorVersion:
            
            tAllowedRange=[self.versionsHistory rangeOfUnit:WBMinorVersionUnit inUnit:WBMajorVersionUnit forVersion:self.versionValue];
            
            if (NSLocationInRange(tValue,tAllowedRange)==YES)
				tVersionComponents.minorVersion=tValue;
            
            break;
            
        case WBVersionPickerCellElementPatchVersion:
            
            tAllowedRange=[self.versionsHistory rangeOfUnit:WBPatchVersionUnit inUnit:WBMinorVersionUnit forVersion:self.versionValue];
            
            if (NSLocationInRange(tValue,tAllowedRange)==YES)
				tVersionComponents.patchVersion=tValue;
            
            break;
            
        default:
            
            break;
    }
    
    WBVersion * tVersion=[self.versionsHistory versionFromComponents:tVersionComponents];
    
    if ([self _constrainAndSetVersionValue:tVersion sendActionIfChanged:YES beepIfNoChange:NO]==NO)
    {
        [self updateElementsStringValuesForVersionChange];
        [((NSControl *)[self controlView]) updateCell:self];
    }
	
	_didEditElement=NO;
}

- (void)_deleteDigit
{
    if (_selectedElementIndex>=0 && (_didEditElement==YES || _didEnableEditionTimer==NO))
    {
        WBVersionPickerCellElement * tElement=_elements[_selectedElementIndex];
        NSString * tStringValue=tElement.stringValue;
        
        NSUInteger tLength=tStringValue.length;
        
        if (tLength>0)
        {
            tElement.stringValue=[tStringValue substringWithRange:NSMakeRange(0,tLength-1)];
            [((NSControl *)[self controlView]) updateCell:self];
        }
        
        _didEditElement=YES;
        
        [self _cancelUserEditTimer];
        
        _didEnableEditionTimer=YES;
    }
    else
    {
        NSBeep();
    }
}
                                                                                   
- (void)_cancelUserEditTimer
{
    _didEnableEditionTimer=NO;
	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_userEditExpired:) object:nil];
}

- (void)_userEditExpired:(id)inObject
{
    _didEnableEditionTimer=NO;
	
	if (_didEditElement==YES)
		[self _commitElementFieldChanges];
}

- (void)updateSelectedElementWithDelta:(NSInteger)inDelta
{
    if (_selectedElementIndex<0)
    	return;
    
	WBVersion * tVersion=self.versionValue;
    WBVersionComponents * tVersionComponents=[WBVersionComponents new];
    
    WBVersionPickerCellElement * tElement=_elements[_selectedElementIndex];
    
    switch(tElement.elementType)
	{
		case WBVersionPickerCellElementMajorVersion:
			
			tVersionComponents.majorVersion=inDelta;
			break;
		
		case WBVersionPickerCellElementMinorVersion:
			
			tVersionComponents.minorVersion=inDelta;
			break;
		
		case WBVersionPickerCellElementPatchVersion:
            
			tVersionComponents.patchVersion=inDelta;
			break;
			
        default:
            
            break;
	}
	
    WBVersion * tNewVersion=[self.versionsHistory versionByAddingComponents:tVersionComponents toVersion:tVersion];
    
    if (tNewVersion!=nil)
		[self _constrainAndSetVersionValue:tNewVersion sendActionIfChanged:YES beepIfNoChange:YES];
}

// Not sure why it's a private API since it's the only way to handle keyDown events

- (BOOL)keyDown:(NSEvent *)inEvent inRect:(NSRect)inRect ofView:(NSView *)inView
{
	NSString * tCharacters=inEvent.characters;
	NSUInteger tLength=tCharacters.length;
	
	for(NSUInteger tIndex=0;tIndex<tLength;tIndex++)
	{
		unichar tCharacter=[tCharacters characterAtIndex:tIndex];
		
		switch(tCharacter)
		{
			case 0x7f:	// Del
			case NSDeleteFunctionKey:
			case NSDeleteCharFunctionKey:
				
				[self _deleteDigit];
				
				break;
				
			case NSUpArrowFunctionKey:
				
				[self endEditingSelectedElement];
				[self updateSelectedElementWithDelta:1];
				
				break;
				
			case NSDownArrowFunctionKey:
				
				[self endEditingSelectedElement];
				[self updateSelectedElementWithDelta:-1];
				
				break;
				
			case NSLeftArrowFunctionKey:
				
				[self endEditingSelectedElement];
				[self selectPreviousElement];
				
				break;
				
			case NSRightArrowFunctionKey:
				
				[self endEditingSelectedElement];
				[self selectNextElement];
				
				break;
				
			case 0x09:  // Tab
				
				[self endEditingSelectedElement];
				
                if (_selectedElementIndex>=[self lastSelectableElement])
                    return NO;
				
				[self selectNextElement];
				
				break;
				
			case 0x19:	// Back Tab
				
				[self endEditingSelectedElement];
				
				if (_selectedElementIndex<=[self firstSelectableElement])
                    return NO;
				
				[self selectPreviousElement];
				
				break;
				
			case 0xa:   // New line
			case 0xd:
				
				[self endEditingSelectedElement];
				
				return NO;
				
			default:
			{
				NSInteger tDigit=[self _digitForLocalizedDigitCharacter:tCharacter];
				
				if (tDigit<0)
					return NO;
				
				[self _insertDigit:tDigit];
				
				break;
			}
		}
	}
	
	return YES;
}

@end

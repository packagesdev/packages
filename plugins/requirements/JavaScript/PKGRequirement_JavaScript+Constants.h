#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PKGJavaScriptReturnValue)
{
	PKGJavaScriptReturnFalse=0,
	PKGJavaScriptReturnTrue=1
};

extern NSString * const PKGRequirementJavaScriptSharedSourceCodeKey;

extern NSString * const PKGRequirementJavaScriptFunctionKey;

extern NSString * const PKGRequirementJavaScriptParametersKey;

extern NSString * const PKGRequirementJavaScriptReturnValueKey;
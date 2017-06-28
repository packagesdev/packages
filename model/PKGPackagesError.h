
#import <Foundation/Foundation.h>

extern NSString * const PKGPackagesModelErrorDomain;

enum
{
	PKGRepresentationNilRepresentationError=0,		// Only set when the representation is nil, use PKGRepresentationInvalidValue otherwise if nil is not an accepted value
	PKGRepresentationInvalidTypeOfValueError=1,
	PKGRepresentationInvalidValueError=2,
	
	PKGFileInvalidTypeOfFileError=300,
	
	PKGFilePathNilError=1000,
	PKGFileURLNilError=1001,
};

extern NSString * const PKGKeyPathErrorKey;


#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import "NSIndexPath+Packages.h"

@interface unit_tests : XCTestCase

@end

@implementation unit_tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - NSIndexPath + Packages

- (void)test_string_representation_empty
{
	// Given
	
	NSIndexPath * tIndexPath=[[NSIndexPath alloc] init];
	
	// When
	
	NSString * tStringRepresentation=[tIndexPath PKG_stringRepresentation];
	
	// Then
	
    XCTAssertEqualObjects(@"", tStringRepresentation);
}

- (void)test_string_representation_1
{
	// Given
	
	NSIndexPath * tIndexPath=[NSIndexPath indexPathWithIndex:1];
	
	// When
	
	NSString * tStringRepresentation=[tIndexPath PKG_stringRepresentation];
	
	// Then
	
	XCTAssertEqualObjects(@"1", tStringRepresentation);
}

- (void)test_string_representation_1_2
{
	// Given
	
	NSUInteger tIndexes[2]={1,2};
	
	NSIndexPath * tIndexPath=[NSIndexPath indexPathWithIndexes:tIndexes length:2];
	
	// When
	
	NSString * tStringRepresentation=[tIndexPath PKG_stringRepresentation];
	
	// Then
	
	XCTAssertEqualObjects(@"1:2", tStringRepresentation);
}

- (void)test_last_index_empty
{
	// Given
	
	NSIndexPath * tIndexPath=[[NSIndexPath alloc] init];
	
	// When
	
	NSUInteger tIndex=[tIndexPath PKG_lastIndex];
	
	// Then
	
	XCTAssertEqual(NSNotFound,tIndex);
}

- (void)test_last_index_1
{
	// Given
	
	NSIndexPath * tIndexPath=[NSIndexPath indexPathWithIndex:1];
	
	// When
	
	NSUInteger tIndex=[tIndexPath PKG_lastIndex];
	
	// Then
	
	XCTAssertEqual(1,tIndex);
}

- (void)test_last_index_1_2
{
	// Given
	
	NSUInteger tIndexes[2]={1,2};
	
	NSIndexPath * tIndexPath=[NSIndexPath indexPathWithIndexes:tIndexes length:2];
	
	// When
	
	NSUInteger tIndex=[tIndexPath PKG_lastIndex];
	
	// Then
	
	XCTAssertEqual(2,tIndex);
}

- (void)test_init_with_string_representation_empty
{
	// Given
	
	NSString * tStringRepresentation=@"";
	
	// When
	
	NSIndexPath * tIndexPath=[[NSIndexPath alloc] PKG_initWithStringRepresentation:tStringRepresentation];
	
	XCTAssertEqualObjects([[NSIndexPath alloc] init], tIndexPath);
}

- (void)test_init_with_string_representation_1
{
	// Given
	
	NSString * tStringRepresentation=@"1";
	
	// When
	
	NSIndexPath * tIndexPath=[[NSIndexPath alloc] PKG_initWithStringRepresentation:tStringRepresentation];
	
	XCTAssertEqualObjects([NSIndexPath indexPathWithIndex:1], tIndexPath);
}

- (void)test_init_with_string_representation_1_2
{
	// Given
	
	NSString * tStringRepresentation=@"1:2";
	
	// When
	
	NSIndexPath * tIndexPath=[[NSIndexPath alloc] PKG_initWithStringRepresentation:tStringRepresentation];
	
	NSUInteger tIndexes[2]={1,2};
	
	XCTAssertEqualObjects([NSIndexPath indexPathWithIndexes:tIndexes length:2], tIndexPath);
}

- (void)test_init_with_string_representation_1_2_
{
	// Given
	
	NSString * tStringRepresentation=@"1:2:";
	
	// When
	
	NSIndexPath * tIndexPath=[[NSIndexPath alloc] PKG_initWithStringRepresentation:tStringRepresentation];
	
	NSUInteger tIndexes[2]={1,2};
	
	XCTAssertEqualObjects([NSIndexPath indexPathWithIndexes:tIndexes length:2], tIndexPath);
}

@end

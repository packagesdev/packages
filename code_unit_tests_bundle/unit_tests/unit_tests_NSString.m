
#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import "NSString+Packages.h"

@interface unit_tests_NSString : XCTestCase

@end

@implementation unit_tests_NSString

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
	[super tearDown];
}

#pragma mark - PKG_stringByDeletingPathPkgExtension

- (void)test_string_by_deleting_path_pkg_extension_no_extension
{
	// Given
	
	NSString * tPath=@"/Users/Shared/Test";
	
	// When
	
	NSString * tNewString=[tPath PKG_stringByDeletingPathPkgExtension];
	
	// Then
	
	NSString * tExpectedPath=@"/Users/Shared/Test";
	
    XCTAssertEqualObjects(tExpectedPath, tNewString);
}

- (void)test_string_by_deleting_path_pkg_extension_dummy_extension
{
	// Given
	
	NSString * tPath=@"/Users/Shared/Test.dummy";
	
	// When
	
	NSString * tNewString=[tPath PKG_stringByDeletingPathPkgExtension];
	
	// Then
	
	NSString * tExpectedPath=@"/Users/Shared/Test.dummy";
	
    XCTAssertEqualObjects(tExpectedPath, tNewString);
}

- (void)test_string_by_deleting_path_pkg_extension_pkg_extension
{
	// Given
	
	NSString * tPath=@"/Users/Shared/Test.pkg";
	
	// When
	
	NSString * tNewString=[tPath PKG_stringByDeletingPathPkgExtension];
	
	// Then
	
	NSString * tExpectedPath=@"/Users/Shared/Test";
	
    XCTAssertEqualObjects(tExpectedPath, tNewString);
}

#pragma mark - PKG_stringByRelativizingToPath

- (void)test_string_by_relativizing_to_path_nil
{
	// Given
	
	NSString * tPath=@"/Users/Shared/Test";
	
	// When
	
	NSString * tRelativePath=[tPath PKG_stringByRelativizingToPath:nil];
	
	// Then
	
	NSString * tExpectedPath=@"/Users/Shared/Test";
	
	XCTAssertEqualObjects(tExpectedPath, tRelativePath);
}

- (void)test_string_by_relativizing_to_path_empty_string
{
	// Given
	
	NSString * tPath=@"/Users/Shared/Test";
	
	// When
	
	NSString * tRelativePath=[tPath PKG_stringByRelativizingToPath:@""];
	
	// Then
	
	NSString * tExpectedPath=@"/Users/Shared/Test";
	
	XCTAssertEqualObjects(tExpectedPath, tRelativePath);
}

- (void)test_string_by_relativizing_to_path_non_absolute_path
{
	// Given
	
	NSString * tPath=@"/Users/Shared/Test";
	
	// When
	
	NSString * tRelativePath=[tPath PKG_stringByRelativizingToPath:@"dummy"];
	
	// Then
	
	NSString * tExpectedPath=@"/Users/Shared/Test";
	
	XCTAssertEqualObjects(tExpectedPath, tRelativePath);
}

- (void)test_string_by_relativizing_to_path_root_path
{
	// Given
	
	NSString * tPath=@"/Users/Shared/Test";
	
	// When
	
	NSString * tRelativePath=[tPath PKG_stringByRelativizingToPath:@"/"];
	
	// Then
	
	NSString * tExpectedPath=@"/Users/Shared/Test";
	
	XCTAssertEqualObjects(tExpectedPath, tRelativePath);
}

- (void)test_string_by_relativizing_to_path_parent_path
{
	// Given
	
	NSString * tPath=@"/Users/Shared/Test";
	
	// When
	
	NSString * tRelativePath=[tPath PKG_stringByRelativizingToPath:@"/Users/Shared"];
	
	// Then
	
	NSString * tExpectedPath=@"Test";
	
	XCTAssertEqualObjects(tExpectedPath, tRelativePath);
}

- (void)test_string_by_relativizing_to_path_parent_path_with_ending_separator
{
	// Given
	
	NSString * tPath=@"/Users/Shared/Test/";
	
	// When
	
	NSString * tRelativePath=[tPath PKG_stringByRelativizingToPath:@"/Users/Shared"];
	
	// Then
	
	NSString * tExpectedPath=@"Test";
	
	XCTAssertEqualObjects(tExpectedPath, tRelativePath);
}

#pragma mark - PKG_stringByAbsolutingWithPath

- (void)test_string_by_absoluting_with_path_nil
{
	// Given
	
	NSString * tPath=@"../Test";
	
	// When
	
	NSString * tAbsolutePath=[tPath PKG_stringByAbsolutingWithPath:nil];
	
	// Then
	
	NSString * tExpectedPath=@"../Test";
	
	XCTAssertEqualObjects(tExpectedPath, tAbsolutePath);
}

- (void)test_string_by_absoluting_with_path_empty_string
{
	// Given
	
	NSString * tPath=@"../Test";
	
	// When
	
	NSString * tAbsolutePath=[tPath PKG_stringByAbsolutingWithPath:@""];
	
	// Then
	
	NSString * tExpectedPath=@"../Test";
	
	XCTAssertEqualObjects(tExpectedPath, tAbsolutePath);
}

- (void)test_string_by_absoluting_with_path_non_absolute_path
{
	// Given
	
	NSString * tPath=@"../Test";
	
	// When
	
	NSString * tAbsolutePath=[tPath PKG_stringByAbsolutingWithPath:@"dummy"];
	
	// Then
	
	NSString * tExpectedPath=@"../Test";
	
	XCTAssertEqualObjects(tExpectedPath, tAbsolutePath);
}

- (void)test_string_by_absoluting_with_path_root_path_fail
{
	// Given
	
	NSString * tPath=@"../Test";
	
	// When
	
	NSString * tAbsolutePath=[tPath PKG_stringByAbsolutingWithPath:@"/"];
	
	// Then
	
	XCTAssertNil(tAbsolutePath);	// Should be nil
}

- (void)test_string_by_absoluting_with_path_root_path_ok
{
	// Given
	
	NSString * tPath=@"./Test";
	
	// When
	
	NSString * tAbsolutePath=[tPath PKG_stringByAbsolutingWithPath:@"/"];
	
	// Then
	
	NSString * tExpectedPath=@"/Test";
	
	XCTAssertEqualObjects(tExpectedPath, tAbsolutePath);
}

@end

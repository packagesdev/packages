
#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import "NSDictionary+WBMapping.h"

@interface unit_tests_NSDictionary : XCTestCase

@end

@implementation unit_tests_NSDictionary

- (void)setUp
{
	[super setUp];
}

- (void)tearDown
{
	[super tearDown];
}

#pragma mark - WB_dictionaryByMappingObjectsUsingBlock

- (void)test_dictionary_by_mapping_objects_using_block_nil_block
{
	// Given
	
	NSDictionary * tDictionary=@{@"A":@"1",
								 @"B":@"2"};
	
	// When
	
	NSDictionary * tMappedDictionary=[tDictionary WB_dictionaryByMappingObjectsUsingBlock:nil];
	
	// Then
	
	XCTAssertEqualObjects(tDictionary, tMappedDictionary);
}

- (void)test_dictionary_by_mapping_objects_using_block_conversion_ok
{
	// Given
	
	NSDictionary * tDictionary=@{@"A":@"1",
								 @"B":@"2"};
	
	// When
	
	NSDictionary * tMappedDictionary=[tDictionary WB_dictionaryByMappingObjectsUsingBlock:^id(NSString *bKey,NSString *bObject){
		
		return @([bObject integerValue]);
		
	}];
	
	// Then
	
	NSDictionary * tExpectedDictionary=@{@"A":@(1),
										 @"B":@(2)};
	
	XCTAssertEqualObjects(tExpectedDictionary, tMappedDictionary);
}

- (void)test_dictionary_by_mapping_objects_using_block_class_unchanged
{
	// Given
	
	NSDictionary * tDictionary=@{@"A":@"1",
								 @"B":@"2"};
	
	NSMutableDictionary * tMutableDictionary=[@{@"A":@"1",
											    @"B":@"2"} mutableCopy];
	
	// When
	
	NSDictionary * tMappedDictionary=[tDictionary WB_dictionaryByMappingObjectsUsingBlock:^id(NSString *bKey,NSString *bObject){
		
		return @([bObject integerValue]);
		
	}];
	
	NSMutableDictionary * tMutableMappedDictionary=[tMutableDictionary WB_dictionaryByMappingObjectsUsingBlock:^id(NSString *bKey,NSString *bObject){
		
		return @([bObject integerValue]);
		
	}];
	
	// Then
	
	XCTAssertTrue([tMappedDictionary isKindOfClass:[NSDictionary class]]);
	XCTAssertTrue([tMutableMappedDictionary isKindOfClass:[NSMutableDictionary class]]);
}

- (void)test_dictionary_by_mapping_objects_using_block_conversion_failed
{
	// Given
	
	NSDictionary * tDictionary=@{@"A":@"1",
								 @"B":@"2"};
	
	// When
	
	NSDictionary * tMappedDictionary=[tDictionary WB_dictionaryByMappingObjectsUsingBlock:^id(NSString *bKey,NSString *bObject){
		
		if ([bKey isEqualToString:@"A"]==YES)
			return nil;
		
		return bObject;
	}];
	
	// Then
	
	XCTAssertNil(tMappedDictionary);
}

#pragma mark - WB_dictionaryByMappingObjectsLenientlyUsingBlock

- (void)test_dictionary_by_mapping_objects_leniently_using_block_nil_block
{
	// Given
	
	NSDictionary * tDictionary=@{@"A":@"1",
								 @"B":@"2"};
	
	// When
	
	NSDictionary * tMappedDictionary=[tDictionary WB_dictionaryByMappingObjectsLenientlyUsingBlock:nil];
	
	// Then
	
	XCTAssertEqualObjects(tDictionary, tMappedDictionary);
}

- (void)test_dictionary_by_mapping_objects_leniently_using_block_conversion_ok
{
	// Given
	
	NSDictionary * tDictionary=@{@"A":@"1",
								 @"B":@"2"};
	
	// When
	
	NSDictionary * tMappedDictionary=[tDictionary WB_dictionaryByMappingObjectsLenientlyUsingBlock:^id(NSString *bKey,NSString *bObject){
		
		return @([bObject integerValue]);
		
	}];
	
	// Then
	
	NSDictionary * tExpectedDictionary=@{@"A":@(1),
										 @"B":@(2)};
	
	XCTAssertEqualObjects(tExpectedDictionary, tMappedDictionary);
}

- (void)test_dictionary_by_mapping_objects_leniently_using_block_class_unchanged
{
	// Given
	
	NSDictionary * tDictionary=@{@"A":@"1",
								 @"B":@"2"};
	
	NSMutableDictionary * tMutableDictionary=[@{@"A":@"1",
											    @"B":@"2"} mutableCopy];
	
	// When
	
	NSDictionary * tMappedDictionary=[tDictionary WB_dictionaryByMappingObjectsLenientlyUsingBlock:^id(NSString *bKey,NSString *bObject){
		
		return @([bObject integerValue]);
		
	}];
	
	NSMutableDictionary * tMutableMappedDictionary=[tMutableDictionary WB_dictionaryByMappingObjectsLenientlyUsingBlock:^id(NSString *bKey,NSString *bObject){
		
		return @([bObject integerValue]);
		
	}];
	
	// Then
	
	XCTAssertTrue([tMappedDictionary isKindOfClass:[NSDictionary class]]);
	XCTAssertTrue([tMutableMappedDictionary isKindOfClass:[NSMutableDictionary class]]);
}

- (void)test_dictionary_by_mapping_objects_leniently_using_block_conversion_sometimes_fails
{
	// Given
	
	NSDictionary * tDictionary=@{@"A":@"1",
								 @"B":@"2"};
	
	// When
	
	NSDictionary * tMappedDictionary=[tDictionary WB_dictionaryByMappingObjectsLenientlyUsingBlock:^id(NSString *bKey,NSString *bObject){
		
		if ([bKey isEqualToString:@"A"]==YES)
			return nil;
		
		return @([bObject integerValue]);
		
	}];
	
	// Then
	
	NSDictionary * tExpectedDictionary=@{@"B":@(2)};
	
	XCTAssertEqualObjects(tExpectedDictionary, tMappedDictionary);
}

#pragma mark - WB_filteredDictionaryUsingBlock

- (void)test_filtered_dictionary_using_block_nil_block
{
	// Given
	
	NSDictionary * tDictionary=@{@"A":@"1",
								 @"B":@"2"};
	
	// When
	
	NSDictionary * tFilteredDictionary=[tDictionary WB_filteredDictionaryUsingBlock:nil];
	
	// Then
	
	XCTAssertEqualObjects(tDictionary, tFilteredDictionary);
}

- (void)test_filtered_dictionary_using_block_filter_ok
{
	// Given
	
	NSDictionary * tDictionary=@{@"A":@"1",
								 @"B":@"2"};
	
	// When
	
	NSDictionary * tFilteredDictionary=[tDictionary WB_filteredDictionaryUsingBlock:^BOOL(NSString *bKey,NSString *bObject){
		
		return ([bKey isEqualToString:@"A"]);
		
	}];
	
	// Then
	
	NSDictionary * tExpectedDictionary=@{@"A":@"1"};
	
	XCTAssertEqualObjects(tExpectedDictionary, tFilteredDictionary);
}

- (void)test_filtered_dictionary_using_block_class_unchanged
{
	// Given
	
	NSDictionary * tDictionary=@{@"A":@"1",
								 @"B":@"2"};
	
	NSMutableDictionary * tMutableDictionary=[@{@"A":@"1",
												@"B":@"2"} mutableCopy];
	
	// When
	
	NSDictionary * tFilteredDictionary=[tDictionary WB_filteredDictionaryUsingBlock:^BOOL(NSString *bKey,NSString *bObject){
		
		return ([bKey isEqualToString:@"A"]);
		
	}];
	
	NSMutableDictionary * tMutableFilteredDictionary=[tMutableDictionary WB_filteredDictionaryUsingBlock:^BOOL(NSString *bKey,NSString *bObject){
		
		return ([bKey isEqualToString:@"A"]);
		
	}];
	
	// Then
	
	XCTAssertTrue([tFilteredDictionary isKindOfClass:[NSDictionary class]]);
	XCTAssertTrue([tMutableFilteredDictionary isKindOfClass:[NSMutableDictionary class]]);
}

@end

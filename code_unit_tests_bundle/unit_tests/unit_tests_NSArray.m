
#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import "NSArray+WBExtensions.h"

@interface unit_test_NSArray : XCTestCase

@end

@implementation unit_test_NSArray

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - NSArray + WBExtensions

- (void)test_array_by_mapping_objects_using_block_nil_block
{
    // Given
    
    NSArray * tArray=@[@"1",@"2"];
    
    // When
    
    NSArray * tMappedArray=[tArray WB_arrayByMappingObjectsUsingBlock:nil];
    
    // Then
    
    XCTAssertEqualObjects(tArray, tMappedArray);
}

- (void)test_array_by_mapping_objects_using_block_conversion_ok
{
    // Given
    
    NSArray * tArray=@[@"1",@"2"];
    
    // When
    
    NSArray * tMappedArray=[tArray WB_arrayByMappingObjectsUsingBlock:^id(NSString *bString,NSUInteger bIndex){
       
        return @([bString length]);
        
    }];
    
    // Then
    
    NSArray * tLengthsArray=@[@(1),@(1)];
    
    XCTAssertEqualObjects(tLengthsArray, tMappedArray);
}

- (void)test_array_by_mapping_objects_using_block_class_unchanged
{
    // Given
    
    NSArray * tArray=@[@"1",@"2"];
    NSMutableArray * tMutableArray=[@[@"1",@"2"] mutableCopy];
    
    // When
    
    NSArray * tMappedArray=[tArray WB_arrayByMappingObjectsUsingBlock:^id(NSString *bString,NSUInteger bIndex){
        
        return @([bString length]);
        
    }];
    
    NSMutableArray * tMutableMappedArray=[tMutableArray WB_arrayByMappingObjectsUsingBlock:^id(NSString *bString,NSUInteger bIndex){
        
        return @([bString length]);
        
    }];
    
    // Then
    
    XCTAssertTrue([tMappedArray isKindOfClass:[NSArray class]]);
    XCTAssertTrue([tMutableMappedArray isKindOfClass:[NSMutableArray class]]);
}

- (void)test_array_by_mapping_objects_using_block_conversion_failed
{
    // Given
    
    NSArray * tArray=@[@"1",@"17",@"3"];
    
    // When
    
    NSArray * tMappedArray=[tArray WB_arrayByMappingObjectsUsingBlock:^id(NSString *bString,NSUInteger bIndex){
        
        NSUInteger tLength=[bString length];
        
        if ((tLength%2)==0)
            return nil;
        
        return @(tLength);
        
    }];
    
    // Then
    
    XCTAssertNil(tMappedArray);
}

- (void)test_array_by_mapping_objects_leniently_using_block_nil_block
{
    // Given
    
    NSArray * tArray=@[@"1",@"2"];
    
    // When
    
    NSArray * tMappedArray=[tArray WB_arrayByMappingObjectsLenientlyUsingBlock:nil];
    
    // Then
    
    XCTAssertEqualObjects(tArray, tMappedArray);
}

- (void)test_array_by_mapping_objects_leniently_using_block_conversion_ok
{
    // Given
    
    NSArray * tArray=@[@"1",@"2"];
    
    // When
    
    NSArray * tMappedArray=[tArray WB_arrayByMappingObjectsLenientlyUsingBlock:^id(NSString *bString,NSUInteger bIndex){
        
        return @([bString length]);
        
    }];
    
    // Then
    
    NSArray * tLengthsArray=@[@(1),@(1)];
    
    XCTAssertEqualObjects(tLengthsArray, tMappedArray);
}

- (void)test_array_by_mapping_objects_leniently_using_block_class_unchanged
{
    // Given
    
    NSArray * tArray=@[@"1",@"2"];
    NSMutableArray * tMutableArray=[@[@"1",@"2"] mutableCopy];
    
    // When
    
    NSArray * tMappedArray=[tArray WB_arrayByMappingObjectsLenientlyUsingBlock:^id(NSString *bString,NSUInteger bIndex){
        
        return @([bString length]);
        
    }];
    
    NSMutableArray * tMutableMappedArray=[tMutableArray WB_arrayByMappingObjectsLenientlyUsingBlock:^id(NSString *bString,NSUInteger bIndex){
        
        return @([bString length]);
        
    }];
    
    // Then
    
    XCTAssertTrue([tMappedArray isKindOfClass:[NSArray class]]);
    XCTAssertTrue([tMutableMappedArray isKindOfClass:[NSMutableArray class]]);
}

- (void)test_array_by_mapping_objects_leniently_using_block_conversion_sometimes_fails
{
    // Given
    
    NSArray * tArray=@[@"1",@"17",@"3"];
    
    // When
    
    NSArray * tMappedArray=[tArray WB_arrayByMappingObjectsLenientlyUsingBlock:^id(NSString *bString,NSUInteger bIndex){
        
        NSUInteger tLength=[bString length];
        
        if ((tLength%2)==0)
            return nil;
        
        return @(tLength);
        
    }];
    
    // Then
    
    NSArray * tLengthsArray=@[@(1),@(1)];
    
    XCTAssertEqualObjects(tLengthsArray, tMappedArray);
}



- (void)test_filtered_array_using_block_nil_block
{
    // Given
    
    NSArray * tArray=@[@"1",@"2"];
    
    // When
    
    NSArray * tFilteredArray=[tArray WB_filteredArrayUsingBlock:nil];
    
    // Then
    
    XCTAssertEqualObjects(tArray, tFilteredArray);
}

- (void)test_filtered_array_using_block_filter_ok
{
    // Given
    
    NSArray * tArray=@[@"1",@"2"];
    
    // When
    
    NSArray * tFilteredArray=[tArray WB_filteredArrayUsingBlock:^BOOL(NSString * bString,NSUInteger bIndex){
    
        return [bString containsString:@"1"];
    
    }];
    
    // Then
    
    NSArray * tExpectedArray=@[@"1"];
    
    XCTAssertEqualObjects(tExpectedArray, tFilteredArray);
}

- (void)test_filtered_array_using_block_class_unchanged
{
    // Given
    
    NSArray * tArray=@[@"1",@"2"];
    NSArray * tMutableArray=[@[@"1",@"2"] mutableCopy];
    
    // When
    
    NSArray * tFilteredArray=[tArray WB_filteredArrayUsingBlock:^BOOL(NSString * bString,NSUInteger bIndex){
        
        return [bString containsString:@"1"];
        
    }];
    
    NSArray * tMutableFilteredArray=[tMutableArray WB_filteredArrayUsingBlock:^BOOL(NSString * bString,NSUInteger bIndex){
        
        return [bString containsString:@"1"];
        
    }];
    
    // Then
    
    XCTAssertTrue([tFilteredArray isKindOfClass:[NSArray class]]);
    XCTAssertTrue([tMutableFilteredArray isKindOfClass:[NSMutableArray class]]);
}

@end

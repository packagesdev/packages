//
//  NSFileManager+Compression.h
//  testCompressionFramework
//
//  Created by stephane on 21/06/2022.
//  Copyright © 2022 Whitebox. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <compression.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WBCompressionAlgorithm)
{
    WBCompressionLZ4 = COMPRESSION_LZ4,     // 04 22 4d 18
    WBCompressionZLIB = COMPRESSION_ZLIB,   // 78 01 - No Compression/low
    // 78 5E
    // 78 9C - Default Compression
    // 78 DA
    WBCompressionLZMA = COMPRESSION_LZMA,   // FD 37 7A 58 5A ?
    WBCompressionLZ4RAW = COMPRESSION_LZ4_RAW,
    WBCompressionLZFSE = COMPRESSION_LZFSE  // 62 76 78 32 ?
};

@interface NSFileManager (WBCompression)

- (BOOL)WB_compressItemAtURL:(NSURL *)inSourceURL toURL:(NSURL *)inDestinationURL algorithm:(WBCompressionAlgorithm)inAlgorithm error:(NSError **)outError;

- (BOOL)WB_decompressItemAtURL:(NSURL *)inSourceURL toURL:(NSURL *)inDestinationURL algorithm:(WBCompressionAlgorithm *)outAlgorithm error:(NSError **)outError;

@end

NS_ASSUME_NONNULL_END

//
//  NSFileManager+Compression.m
//  testCompressionFramework
//
//  Created by stephane on 21/06/2022.
//  Copyright © 2022 Whitebox. All rights reserved.
//

//

/*
 Based on the Apple Sample Code: CompressingAndDecompressingFilesWithStreamCompression, so parts of this code is concerned by this:
 
 Copyright © 2021 Apple Inc.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
*/

#import "NSFileManager+Compression.h"

#define WBCOMPRESSION_COMPRESS_BUFFER_SIZE  32768

@implementation NSFileManager (Compression)

- (BOOL)WB_compressItemAtURL:(NSURL *)inSourceURL toURL:(NSURL *)inDestinationURL algorithm:(WBCompressionAlgorithm)inAlgorithm error:(NSError **)outError
{
    if ([inSourceURL isKindOfClass:[NSURL class]]==NO || [inDestinationURL isKindOfClass:[NSURL class]]==NO || (inAlgorithm < WBCompressionLZ4 || inAlgorithm > COMPRESSION_LZFSE))
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:@{}];    // Underlying error?
        
        return NO;
    }
    
    if (inSourceURL.isFileURL==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSCocoaErrorDomain
                                          code:NSFileReadUnsupportedSchemeError
                                      userInfo:@{
                                                 NSURLErrorKey:inSourceURL
                                                 }];
        
        return NO;
    }
    
    if (inDestinationURL.isFileURL==NO)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSCocoaErrorDomain
                                          code:NSFileWriteUnsupportedSchemeError
                                      userInfo:@{
                                                 NSURLErrorKey:inDestinationURL
                                                 }];
        
        return NO;
    }
    
    // Allocate buffer.
    
    uint8_t * tDestinationBuffer=malloc(WBCOMPRESSION_COMPRESS_BUFFER_SIZE*sizeof(uint8_t));
    
    if (tDestinationBuffer==NULL)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:ENOMEM userInfo:@{}];
        
        return NO;
    }
    
    NSFileHandle * tSourceFileHandle = [NSFileHandle fileHandleForReadingFromURL:inSourceURL error:outError];
    
    if (tSourceFileHandle==nil)
    {
        free(tDestinationBuffer);
        
        return NO;
    }
    
    if ([[NSData data] writeToURL:inDestinationURL options:NSDataWritingWithoutOverwriting error:outError]==NO)
    {
        [tSourceFileHandle closeFile];
        
        free(tDestinationBuffer);
        
        return NO;
    }
    
    NSFileHandle * tDestinationFileHandle = [NSFileHandle fileHandleForWritingToURL:inDestinationURL error:outError];
    
    if (tDestinationFileHandle==nil)
    {
        [self removeItemAtURL:inDestinationURL error:NULL];
        
        [tSourceFileHandle closeFile];
        
        free(tDestinationBuffer);
        
        return NO;
    }
    
    compression_stream * tCompressionStream=malloc(sizeof(compression_stream));
    
    if (tCompressionStream==NULL)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:ENOMEM userInfo:@{}];
        
        [tDestinationFileHandle closeFile];
        
        [self removeItemAtURL:inDestinationURL error:NULL];
        
        [tSourceFileHandle closeFile];
        
        free(tDestinationBuffer);
        
        return NO;
    }
    
    compression_status tStatus = compression_stream_init(tCompressionStream,COMPRESSION_STREAM_ENCODE,(compression_algorithm)inAlgorithm);
    
    if (tStatus == COMPRESSION_STATUS_ERROR)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSCocoaErrorDomain code:ENOMEM userInfo:@{}];    // A CHANGER
        
        compression_stream_destroy(tCompressionStream);
        free(tCompressionStream);
        
        [tDestinationFileHandle closeFile];
        
        [self removeItemAtURL:inDestinationURL error:NULL];
        
        [tSourceFileHandle closeFile];
        
        free(tDestinationBuffer);
        
        return NO;
    }
    
    // Initialize Compression Stream Structure
    tCompressionStream->src_size = 0;
    tCompressionStream->dst_ptr = tDestinationBuffer;
    tCompressionStream->dst_size = WBCOMPRESSION_COMPRESS_BUFFER_SIZE;
    
    NSData * tReadData=nil;
    
    do
    {
        int flags = 0;
        
        if (tCompressionStream->src_size == 0)
        {
            tReadData = [tSourceFileHandle readDataOfLength:WBCOMPRESSION_COMPRESS_BUFFER_SIZE];
            
            tCompressionStream->src_size = tReadData.length;
            
            if (tReadData.length < WBCOMPRESSION_COMPRESS_BUFFER_SIZE)
                flags = COMPRESSION_STREAM_FINALIZE;
        }
        
        NSUInteger count = tReadData.length;
        
        tCompressionStream->src_ptr = tReadData.bytes + (count - tCompressionStream->src_size);
        
        tStatus = compression_stream_process(tCompressionStream, flags);
        
        switch(tStatus)
        {
            case COMPRESSION_STATUS_OK:
            case COMPRESSION_STATUS_END:
            {
                NSData * tWriteData = [[NSData alloc] initWithBytesNoCopy:tDestinationBuffer
                                                                   length:WBCOMPRESSION_COMPRESS_BUFFER_SIZE - tCompressionStream->dst_size
                                                             freeWhenDone:NO];
                
                [tDestinationFileHandle writeData:tWriteData];
                
                tCompressionStream->dst_ptr = tDestinationBuffer;
                tCompressionStream->dst_size = WBCOMPRESSION_COMPRESS_BUFFER_SIZE;
                
                break;
            }
            case COMPRESSION_STATUS_ERROR:
                
                if (outError!=NULL)
                    *outError=[NSError errorWithDomain:NSCocoaErrorDomain code:ENOMEM userInfo:@{}];    // A CHANGER
                
                break;
        }
    }
    while(tStatus == COMPRESSION_STATUS_OK);
    
    [tSourceFileHandle closeFile];
    [tDestinationFileHandle closeFile];
    
    compression_stream_destroy(tCompressionStream);
    free(tCompressionStream);
    
    free(tDestinationBuffer);
    
    return (tStatus == COMPRESSION_STATUS_END);
}

- (BOOL)WB_decompressItemAtURL:(NSURL *)inSourceURL toURL:(NSURL *)inDestinationURL algorithm:(WBCompressionAlgorithm *)outAlgorithm error:(NSError **)outError
{
    
    return NO;
}

@end

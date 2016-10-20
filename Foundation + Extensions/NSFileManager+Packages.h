/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, PKG_NSFileManagerCopyOptions) {
	PKG_NSDeleteExisting = 1
};

@interface NSFileManager (Packages)

- (NSDictionary *)PKG_extendedAttributesOfItemAtPath:(NSString *)inPath error:(NSError *__autoreleasing *)outError;

- (BOOL)PKG_setExtendedAttributes:(NSDictionary *)inExtendedAttributes ofItemAtPath:(NSString *)inPath error:(NSError *__autoreleasing *)outError;

- (BOOL)PKG_copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath options:(PKG_NSFileManagerCopyOptions)inOptions error:(NSError *__autoreleasing *)outError;

- (BOOL)PKG_isEmptyDirectoryAtPath:(NSString *)inPath;

- (BOOL)PKG_setPosixPermissions:(mode_t)inPosixPermisions ofItemAtPath:(NSString *)inPath error:(NSError *__autoreleasing *)outError;

- (BOOL)PKG_setPosixPermissions:(mode_t)inPosixPermisions ofItemAndDescendantsAtPath:(NSString *)inPath error:(NSError *__autoreleasing *)outError;

- (BOOL)PKG_setOwnerAccountID:(uid_t)inOwnerAccountID groupAccountID:(gid_t)inGroupAccountID ofItemAndDescendantsAtPath:(NSString *)inPath error:(NSError *__autoreleasing *)outError;

- (NSInteger)PKG_numberOfItemsInDirectoryAtPath:(NSString *)inPath sizeOnDisk:(off_t *)outSize;

@end


extern NSString * const PKGFileFinderInfoKey;
extern NSString * const PKGFileResourceForkKey;


extern NSString * const PKGPackagesFileManagerErrorDomain;

enum {
	PKGFileManagerMemoryCanNotBeAllocated=1,
	
	PKGFileManagerObjectConversionError=10,
	
};

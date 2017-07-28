/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGDocument.h"



#import "NSString+Packages.h"

@interface PKGDocument ()

	@property (readwrite) PKGDocumentRegistry * registry;

	@property (readwrite) PKGDocumentWindowController * documentWindowController;


@end

@implementation PKGDocument

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_registry=[PKGDocumentRegistry new];
	}
	
	return self;
}

#pragma mark -

- (void)makeWindowControllers
{
	[self addWindowController:self.documentWindowController];
}

#pragma mark -

- (NSURL *)folderURL
{
	return self.fileURL.URLByDeletingLastPathComponent;
}

- (NSString *)folder
{
	return self.fileURL.path.stringByDeletingLastPathComponent;
}

- (NSString *)referenceProjectPath
{
	return self.folder;
}

- (NSString *)referenceFolderPath
{
	NSString * tReferenceProjectPath=self.documentWindowController.project.settings.referenceFolderPath;
	
	if (tReferenceProjectPath==nil)
		return self.folder;
	
	return tReferenceProjectPath;
}

- (PKGProject *)project
{
	return self.documentWindowController.project;
}

#pragma mark -

- (NSURL *)temporaryURLWithError:(NSError **)outError
{
	NSError * tError=nil;
	NSURL * tTemporaryFolderURL=[[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory
																	   inDomain:NSUserDomainMask
															  appropriateForURL:self.folderURL
																		 create:YES
																		  error:&tError];
	
	if (tTemporaryFolderURL==nil)
	{
		if (tError!=nil && outError!=nil)
			*outError=tError;
		
		return nil;
	}
	
	NSURL * tTemporaryProjectURL=[tTemporaryFolderURL URLByAppendingPathComponent:self.fileURL.path.lastPathComponent];
	
	if (tTemporaryProjectURL==nil)
	{
		// A COMPLETER
		
		return nil;
	}
	
	return tTemporaryProjectURL;
}

#pragma mark -

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	id tPropertyList=[self.documentWindowController.project representation];
	
	if (tPropertyList==nil)
	{
	}
	
	NSError * tError;
	
	NSData * tData=[NSPropertyListSerialization dataWithPropertyList:tPropertyList format:NSPropertyListXMLFormat_v1_0 options:0 error:&tError];
	
	if (tData==nil)
	{
	}
	
	return tData;
	
	/*// Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
    return nil;*/
}

- (BOOL)readFromData:(NSData *)inData ofType:(NSString *)typeName error:(NSError **)outError
{
	NSError * tError;
	
	id tPropertyList=[NSPropertyListSerialization propertyListWithData:inData options:NSPropertyListImmutable format:NULL error:&tError];
	
	if (tPropertyList==nil)
	{
		
		return NO;
	}
	
	PKGProject * tProject=[PKGProject projectFromPropertyList:tPropertyList error:&tError];
	
	if (tProject==nil)
	{
		
		return NO;
	}
	
	self.documentWindowController=[[PKGDocumentWindowController alloc] initWithProject:tProject];
	
	return YES;
	
	/*// Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
    return NO;*/
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

#pragma mark -

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError
{
	return nil;
}

#pragma mark - PKGFilePathConverter

- (NSString *)absolutePathForFilePath:(PKGFilePath *)inFilePath
{
	if (inFilePath==nil)
		return nil;
	
	switch(inFilePath.type)
	{
		case PKGFilePathTypeAbsolute:
			
			return inFilePath.string;
			
		case PKGFilePathTypeRelativeToProject:
			
			return [inFilePath.string PKG_stringByAbsolutingWithPath:self.referenceProjectPath];
			
		case PKGFilePathTypeRelativeToReferenceFolder:
			
			return [inFilePath.string PKG_stringByAbsolutingWithPath:self.referenceFolderPath];
			
		default:
			break;
	}
	
	return nil;
}

- (PKGFilePath *)filePathForAbsolutePath:(NSString *)inAbsolutePath type:(PKGFilePathType)inType
{
	if (inAbsolutePath==nil)
		return nil;
	
	if (inType==PKGFilePathTypeAbsolute)
		return [[PKGFilePath alloc] initWithString:inAbsolutePath type:PKGFilePathTypeAbsolute];
	
	NSString * tReferencePath=nil;
	
	if (inType==PKGFilePathTypeRelativeToProject)
	{
		tReferencePath=self.referenceProjectPath;
	}
	else if (inType==PKGFilePathTypeRelativeToReferenceFolder)
	{
		tReferencePath=self.referenceFolderPath;
	}
	
	if (tReferencePath==nil)
	{
		return nil;
	}
	
	NSString * tConvertedPath=[inAbsolutePath PKG_stringByRelativizingToPath:tReferencePath];
	
	if (tConvertedPath==nil)
	{
		return nil;
	}
	
	return [[PKGFilePath alloc] initWithString:tConvertedPath type:inType];
}

- (BOOL)shiftTypeOfFilePath:(PKGFilePath *)inFilePath toType:(PKGFilePathType)inType
{
	if (inFilePath==nil)
		return NO;
	
	if (inFilePath.type==inType)
		return YES;
	
	if (inFilePath.string!=nil)
	{
		NSString * tAbsolutePath=[self absolutePathForFilePath:inFilePath];
		
		if (tAbsolutePath==nil)
			return NO;
		
		PKGFilePath * tFilePath=[self filePathForAbsolutePath:tAbsolutePath type:inType];
		
		if (tFilePath==nil)
			return NO;
		
		inFilePath.string=tFilePath.string;
	}
	
	inFilePath.type=inType;
	
	return YES;
}

@end

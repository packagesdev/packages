/*
 Copyright (c) 2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadTreeNode+Bundle.h"
#import "PKGPayloadTreeNode+UI.h"

@implementation PKGPayloadTreeNode (Bundle)

- (PKGTriboolean)isBundleWithFilePathConverter:(id<PKGFilePathConverter>)inFilePathConverter bundleIdentifier:(NSString **)outBundleIdentifier
{
	PKGFileItem * tRepresentedObject=self.representedObject;
	
	if (tRepresentedObject.type<PKGFileItemTypeNewFolder)
		return NO_value;
	
	// There must be an extension
	
	NSString * tPathExtension=[tRepresentedObject.filePath.string pathExtension];
	
	if (tPathExtension.length==0)
		return NO_value;
	
	if (tRepresentedObject.type==PKGFileItemTypeFileSystemItem)
	{
		NSString * tAbsolutePath=[self referencedPathUsingConverter:inFilePathConverter];
		
		if (tAbsolutePath==nil)
		{
			NSLog(@"<0x%lx> Failed to compute reference path",(unsigned long)self);
			return NO_value;
		}
		
		// If it's a real filesystem item, it must be a directory
		
		NSError * tError=nil;
		NSDictionary * tAttributesDictionary=[[NSFileManager defaultManager] attributesOfItemAtPath:tAbsolutePath error:&tError];
		
		if (tAttributesDictionary==nil)
		{
			if ([tError.domain isEqualToString:NSCocoaErrorDomain]==YES && tError.code==NSFileReadNoSuchFileError)
				return INDETERMINED_value;
			
			return NO_value;
		}
		
		if ([tAttributesDictionary[NSFileType] isEqualToString:NSFileTypeDirectory]==NO)
			return NO_value;
		
		// Check whether there is a Info.plist file with a bundle identifier if the directory's contents is not disclosed
		
		if (tRepresentedObject.isContentsDisclosed==NO)
		{
			NSBundle * tBundle=[NSBundle bundleWithPath:tAbsolutePath];
			
			if (tBundle.bundleIdentifier.length==0)
				return NO_value;
			
			if (outBundleIdentifier!=NULL)
				*outBundleIdentifier=[tBundle.bundleIdentifier copy];
			
			return YES_value;
		}
	}
	
	// This will also work for the PKGFileItemTypeNewFolder case
	
	// Check whether there is a Info.plist file with a bundle identifier in the children
	
	PKGPayloadTreeNode * tInfoPListNode=(PKGPayloadTreeNode *)[self childNodeMatching:^BOOL(PKGPayloadTreeNode *bChildNode){
		
		PKGFileItem * tRepresentedChildObject=bChildNode.representedObject;
		
		if (tRepresentedChildObject.type!=PKGFileItemTypeFileSystemItem)
			return NO;
		
		return ([tRepresentedChildObject.filePath.string isEqualToString:@"Info.plist"]) ? YES : NO;
	}];
	
	if (tInfoPListNode!=nil)
	{
		NSString * tInfoPlistPath=[tInfoPListNode referencedPathUsingConverter:inFilePathConverter];
		
		if (tInfoPlistPath==nil)
		{
			NSLog(@"<0x%lx> Failed to compute Info.plist path",(unsigned long)tInfoPListNode);
			return NO_value;
		}
		
		NSError * tError=nil;
		NSData * tData=[NSData dataWithContentsOfFile:tInfoPlistPath options:0 error:&tError];
		
		if (tData==nil)
		{
			if ([tError.domain isEqualToString:NSCocoaErrorDomain]==YES && tError.code==NSFileReadNoSuchFileError)
				return INDETERMINED_value;
		}
		else
		{
			NSDictionary * tDictionary=[NSPropertyListSerialization propertyListWithData:tData options:NSPropertyListImmutable format:NULL error:NULL];
			
			if (tDictionary!=nil)
			{
				NSString * tBundleIdentifier=tDictionary[@"CFBundleIdentifier"];
				
				if ([tBundleIdentifier isKindOfClass:NSString.class]==NO)
					return NO_value;
				
				if (tBundleIdentifier.length==0)
					return NO_value;
				
				if (outBundleIdentifier!=NULL)
					*outBundleIdentifier=[tBundleIdentifier copy];
				
				return YES_value;
			}
		}
	}
	
	PKGPayloadTreeNode * tContentsNode=(PKGPayloadTreeNode *)[self childNodeMatching:^BOOL(PKGPayloadTreeNode *bChildNode){
		
		PKGFileItem * tRepresentedChildObject=bChildNode.representedObject;
		
		if (tRepresentedChildObject.type<PKGFileItemTypeNewFolder)
			return NO_value;
		
		return ([tRepresentedChildObject.filePath.string isEqualToString:@"Contents"]) ? YES_value : NO_value;
	}];
	
	if (tContentsNode==nil)
		return NO_value;
	
	PKGFileItem * tContentsRepresentedObject=tContentsNode.representedObject;
	
	if (tContentsRepresentedObject.type==PKGFileItemTypeFileSystemItem)
	{
		NSString * tAbsolutePath=[tContentsNode referencedPathUsingConverter:inFilePathConverter];
		
		if (tAbsolutePath==nil)
		{
			NSLog(@"<0x%lx> Failed to compute reference path",(unsigned long)tContentsNode);
			return NO_value;
		}
		
		NSError * tError=nil;
		NSDictionary * tAttributesDictionary=[[NSFileManager defaultManager] attributesOfItemAtPath:tAbsolutePath error:&tError];
		
		if (tAttributesDictionary==nil)
		{
			if ([tError.domain isEqualToString:NSCocoaErrorDomain]==YES && tError.code==NSFileReadNoSuchFileError)
				return INDETERMINED_value;
			
			return NO_value;
		}
		
		if ([tAttributesDictionary[NSFileType] isEqualToString:NSFileTypeDirectory]==NO)
			return NO_value;
		
		// Check whether there is a Info.plist file with a bundle identifier
		
		if (tContentsRepresentedObject.isContentsDisclosed==NO)
		{
			NSString * tInfoPlistPath=[tAbsolutePath stringByAppendingPathComponent:@"Info.plist"];
			
			BOOL isDirectory;
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:tInfoPlistPath isDirectory:&isDirectory]==NO || isDirectory==YES)
				return NO_value;
			
			NSDictionary * tDictionary=[NSDictionary dictionaryWithContentsOfFile:tInfoPlistPath];
			
			if (tDictionary==nil)
				return NO_value;
			
			NSString * tBundleIdentifier=tDictionary[@"CFBundleIdentifier"];
			
			if ([tBundleIdentifier isKindOfClass:NSString.class]==NO)
				return NO_value;
			
			if (tBundleIdentifier.length==0)
				return NO_value;
			
			if (outBundleIdentifier!=NULL)
				*outBundleIdentifier=[tBundleIdentifier copy];
			
			return YES_value;
		}
	}
	
	tInfoPListNode=(PKGPayloadTreeNode *)[self childNodeMatching:^BOOL(PKGPayloadTreeNode *bChildNode){
		
		PKGFileItem * tRepresentedChildObject=bChildNode.representedObject;
		
		if (tRepresentedChildObject.type!=PKGFileItemTypeFileSystemItem)
			return NO_value;
		
		return ([tRepresentedChildObject.filePath.string isEqualToString:@"Info.plist"]==YES) ? YES_value : NO_value;
	}];
	
	if (tInfoPListNode==nil)
		return NO_value;
	
	NSString * tInfoPlistPath=[tInfoPListNode referencedPathUsingConverter:inFilePathConverter];
	
	if (tInfoPlistPath==nil)
	{
		NSLog(@"<0x%lx> Failed to compute Info.plist path",(unsigned long)tInfoPListNode);
		return NO_value;
	}
	
	NSError * tError=nil;
	NSData * tData=[NSData dataWithContentsOfFile:tInfoPlistPath options:0 error:&tError];
	
	if (tData==nil)
	{
		if ([tError.domain isEqualToString:NSCocoaErrorDomain]==YES && tError.code==NSFileReadNoSuchFileError)
			return INDETERMINED_value;
		
		return NO_value;
	}
	
	NSDictionary * tDictionary=[NSPropertyListSerialization propertyListWithData:tData options:NSPropertyListImmutable format:NULL error:NULL];
	
	if (tDictionary==nil)
		return NO_value;
	
	
	NSString * tBundleIdentifier=tDictionary[@"CFBundleIdentifier"];
	
	if ([tBundleIdentifier isKindOfClass:NSString.class]==NO)
		return NO_value;
	
	if (tBundleIdentifier.length==0)
		return NO_value;
	
	if (outBundleIdentifier!=NULL)
		*outBundleIdentifier=[tBundleIdentifier copy];
	
	return YES_value;
}

@end

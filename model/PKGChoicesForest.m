/*
 Copyright (c) 2016-2017, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGChoicesForest.h"

#import "NSArray+WBExtensions.h"

@implementation PKGChoiceTreeNode

- (Class)representedObjectClassForRepresentation:(NSDictionary *)inRepresentation;
{
	if ([PKGChoiceGroupItem isRepresentationOfGroupChoiceItem:inRepresentation]==YES)
		return PKGChoiceGroupItem.class;
	
	return PKGChoicePackageItem.class;
}

- (BOOL)isLeaf
{
	PKGChoiceItem * tChoiceItem=[self representedObject];
	
	return (tChoiceItem.type!=PKGChoiceItemTypeGroup);
}

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	[tDescription appendFormat:@"%@",[(NSObject *)self.representedObject description]];
	
	[self.children enumerateObjectsUsingBlock:^(PKGChoiceTreeNode * bChildTreeNode,__attribute__((unused))NSUInteger bIndex,__attribute__((unused))BOOL * bOutStop){
	
		[tDescription appendFormat:@"%@\n",[bChildTreeNode description]];
	}];
	
	return tDescription;
}

@end



@implementation PKGChoicesForest

+ (Class)nodeClass
{
	return PKGChoiceTreeNode.class;
}

- (id)initWithPackagesComponents:(NSArray *)inArray
{
	if (inArray==nil)
		return nil;
	
	NSArray * tRootNodes=[inArray WB_arrayByMappingObjectsUsingBlock:^PKGChoiceTreeNode *(PKGPackageComponent * bComponent, __attribute__((unused))NSUInteger bIndex) {
		
		PKGChoicePackageItem * tChoicePackageItem=[[PKGChoicePackageItem alloc] initWithPackageComponent:bComponent];
		
		return [[PKGChoiceTreeNode alloc] initWithRepresentedObject:tChoicePackageItem children:nil];
		
	}];
	
	self=[super initWithRootNodes:tRootNodes];
	
	return self;
}

@end

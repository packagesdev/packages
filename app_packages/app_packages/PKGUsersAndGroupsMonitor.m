/*
 Copyright (c) 2017-2018, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGUsersAndGroupsMonitor.h"

#import <OpenDirectory/OpenDirectory.h>

#include <notify.h>
#include <notify_keys.h>

#include <pthread.h>

@interface PKGUsersAndGroupsMonitor ()
{
	NSMutableDictionary * _userAccountID_PosixNameCache;
	NSMutableDictionary * _posixName_userAccountIDCache;
	
	NSMutableDictionary * _groupAccountID_PosixNameCache;
	NSMutableDictionary * _posixName_groupAccountIDCache;
	
	pthread_rwlock_t _userAccountMutex;
	pthread_rwlock_t _groupAccountMutex;
	
	int _usersNotificationToken;
	int _groupsNotificationToken;
	
	ODSession * _openDirectorySession;
	ODNode * _openDirectoryRootNode;
	
	ODQuery * _usersQuery;
	ODQuery * _groupsQuery;
}

- (void)_refreshUsersCache;
- (void)_refreshGroupsCache;

- (void)refreshCache;

@end

@implementation PKGUsersAndGroupsMonitor

+ (PKGUsersAndGroupsMonitor *)sharedMonitor
{
	static PKGUsersAndGroupsMonitor * sMonitor=nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		sMonitor=[[PKGUsersAndGroupsMonitor alloc] init];
	});
	
	return sMonitor;
}

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_userAccountID_PosixNameCache=[NSMutableDictionary dictionary];
		_posixName_userAccountIDCache=[NSMutableDictionary dictionary];
		
		_groupAccountID_PosixNameCache=[NSMutableDictionary dictionary];
		_posixName_groupAccountIDCache=[NSMutableDictionary dictionary];
		
		int tMutexError=pthread_rwlock_init(&_userAccountMutex,NULL);
		
		if (tMutexError!=0)
		{
			switch(tMutexError)
			{
				case EAGAIN:
					
					NSLog(@"The system lacks the necessary resources to initialize the read/write lock");
					
					break;
					
				case ENOMEM:
					
					NSLog(@"Memory is not sufficient enough to initialize the read/write lock");
					
					break;
					
				case EBUSY:
					
					NSLog(@"Trying to re-initialize the read/write lock");
					
					break;
					
				case EINVAL:
					
					NSLog(@"Incorrect attributes are used to initialize the read/write lock");
					
					break;
					
				default:
					
					NSLog(@"Unknown reason prevents the initialization of the read/write lock");
			}
			
			return nil;
		}
		
		tMutexError=pthread_rwlock_init(&_groupAccountMutex,NULL);
		
		if (tMutexError!=0)
		{
			pthread_rwlock_destroy(&_userAccountMutex);
			
			switch(tMutexError)
			{
				case EAGAIN:
					
					NSLog(@"The system lacks the necessary resources to initialize the read/write lock");
					
					break;
					
				case ENOMEM:
					
					NSLog(@"Memory is not sufficient enough to initialize the read/write lock");
					
					break;
					
				case EBUSY:
					
					NSLog(@"Trying to re-initialize the read/write lock");
					
					break;
					
				case EINVAL:
					
					NSLog(@"Incorrect attributes are used to initialize the read/write lock");
					
					break;
					
				default:
					
					NSLog(@"Unknown reason prevents the initialization of the read/write lock");
			}
			
			return nil;
		}
		
		_openDirectorySession=[ODSession defaultSession];
		
		NSError * tError=nil;
		
		_openDirectoryRootNode=[ODNode nodeWithSession:_openDirectorySession type:kODNodeTypeLocalNodes error:&tError];
		
		if (_openDirectoryRootNode==nil)
		{
			NSLog(@"Could not create a ODNode for the default session and local nodes: %@",tError);
			
			pthread_rwlock_destroy(&_userAccountMutex);
			
			pthread_rwlock_destroy(&_groupAccountMutex);
			
			return nil;
		}
		
		_usersQuery = [ODQuery queryWithNode:_openDirectoryRootNode forRecordTypes:kODRecordTypeUsers attribute:nil matchType:0 queryValues:nil returnAttributes:@[kODAttributeTypeUniqueID] maximumResults:0 error:&tError];
		
		if (_usersQuery==nil)
		{
			// A COMPLETER
		}
		
		
		_groupsQuery = [ODQuery queryWithNode:_openDirectoryRootNode forRecordTypes:kODRecordTypeGroups attribute:nil matchType:0 queryValues:nil returnAttributes:@[kODAttributeTypePrimaryGroupID] maximumResults:0 error:&tError];
		
		if (_groupsQuery==nil)
		{
			// A COMPLETER
		}
		
		[self refreshCache];
		
		notify_register_dispatch(kNotifyDSCacheInvalidationUser, &_usersNotificationToken, dispatch_get_main_queue(), ^(int bToken){
		
			pthread_rwlock_wrlock(&self->_userAccountMutex);
			
			[self refreshCache];
			
			pthread_rwlock_unlock(&self->_userAccountMutex);
		
		});
		
		notify_register_dispatch(kNotifyDSCacheInvalidationGroup, &_groupsNotificationToken, dispatch_get_main_queue(), ^(int bToken){
			
			pthread_rwlock_wrlock(&self->_groupAccountMutex);
			
			[self _refreshGroupsCache];
			
			pthread_rwlock_unlock(&self->_groupAccountMutex);
			
		});
	}
	
	return self;
}

-(void)dealloc
{
	// Need to be tested
	
	pthread_rwlock_destroy(&_userAccountMutex);
	
	pthread_rwlock_destroy(&_groupAccountMutex);
	
	notify_cancel(_usersNotificationToken);
	
	notify_cancel(_groupsNotificationToken);
}

#pragma mark -

- (void)_refreshUsersCache
{
	_userAccountID_PosixNameCache=[NSMutableDictionary dictionary];
	_posixName_userAccountIDCache=[NSMutableDictionary dictionary];
	
	NSArray * tResults=[_usersQuery resultsAllowingPartial:NO error:NULL];
	
	for (ODRecord * tResult in tResults)
	{
		NSString * tPosixName=[tResult recordName];
		
		if (tPosixName.length==0)
		{
			// A COMPLETER
			
			continue;
		}
		
		NSError * tError=nil;
		
		NSArray * tValues=[tResult valuesForAttribute:kODAttributeTypeUniqueID error:&tError];
		
		if (tValues==nil)
		{
		}
		
		if (tValues.count==0)
		{
			// A COMPLETER
			
			continue;
		}
		
		NSString * tValue=tValues[0];
		
		if ([tValue isKindOfClass:NSString.class]==NO)
		{
		}
		
		NSNumber * tNumber=@(tValue.integerValue);
		
		_userAccountID_PosixNameCache[tNumber]=tPosixName;
		_posixName_userAccountIDCache[tPosixName]=tNumber;
	}
}

- (void)_refreshGroupsCache
{
	_groupAccountID_PosixNameCache=[NSMutableDictionary dictionary];
	_posixName_groupAccountIDCache=[NSMutableDictionary dictionary];
	
	NSArray * tResults=[_groupsQuery resultsAllowingPartial:NO error:NULL];
	
	for (ODRecord * tResult in tResults)
	{
		NSString * tPosixName=[tResult recordName];
		
		if (tPosixName.length==0)
		{
			// A COMPLETER
			
			continue;
		}
		
		NSError * tError=nil;
		
		NSArray * tValues=[tResult valuesForAttribute:kODAttributeTypePrimaryGroupID error:&tError];
		
		if (tValues==nil)
		{
		}
		
		if (tValues.count==0)
		{
			// A COMPLETER
			
			continue;
		}
		
		NSString * tValue=tValues[0];
		
		if ([tValue isKindOfClass:NSString.class]==NO)
		{
		}
		
		NSNumber * tNumber=@(tValue.integerValue);
		
		_groupAccountID_PosixNameCache[tNumber]=tPosixName;
		_posixName_groupAccountIDCache[tPosixName]=tNumber;
	}
}

// A VOIR (It might be necessary to perform this in a secondary thread as Apple's API was observed once to hang waiting for a semaphore on macOS BS)

- (void)refreshCache
{
	[self _refreshUsersCache];
	[self _refreshGroupsCache];
}

#pragma mark -

- (uid_t)userAccountIDForPosixName:(NSString *)inPosixName
{
	if (inPosixName==nil)
		return -1;
	
	uid_t tUserAccountID=-1;
	
	int tError=pthread_rwlock_rdlock(&_userAccountMutex);
	
	if (tError!=0)
		NSLog(@"user read lock error: %d",tError);
	
	tUserAccountID=[_posixName_userAccountIDCache[inPosixName] unsignedIntValue];
	
	pthread_rwlock_unlock(&_userAccountMutex);
	
	return tUserAccountID;
}

- (gid_t)groupAccountForPosixName:(NSString *)inPosixName
{
	if (inPosixName==nil)
		return -1;
	
	uid_t tGroupAccountID=-1;
	
	int tError=pthread_rwlock_rdlock(&_groupAccountMutex);
	
	if (tError!=0)
		NSLog(@"group read lock error: %d",tError);
	
	tGroupAccountID=[_posixName_groupAccountIDCache[inPosixName] unsignedIntValue];
	
	pthread_rwlock_unlock(&_groupAccountMutex);
	
	return tGroupAccountID;
}

- (NSString *)posixNameForUserAccountID:(uid_t)inUID
{
	int tError=pthread_rwlock_rdlock(&_userAccountMutex);
	
	if (tError!=0)
		NSLog(@"user read lock error: %d",tError);
	
	NSString * tPosixName=_userAccountID_PosixNameCache[@(inUID)];
	
	pthread_rwlock_unlock(&_userAccountMutex);
	
	return tPosixName;
}

- (NSString *)posixNameForGroupAccountID:(gid_t)inGID
{
	int tError=pthread_rwlock_rdlock(&_groupAccountMutex);
	
	if (tError!=0)
		NSLog(@"group read lock error: %d",tError);
	
	NSString * tPosixName=_groupAccountID_PosixNameCache[@(inGID)];
	
	pthread_rwlock_unlock(&_groupAccountMutex);
	
	return tPosixName;
}

- (NSArray *)allLocalUserPosixNames
{
	int tError=pthread_rwlock_rdlock(&_userAccountMutex);
	
	if (tError!=0)
		NSLog(@"user read lock error: %d",tError);
	
	NSArray * tArray=[[_posixName_userAccountIDCache allKeys] sortedArrayUsingSelector:@selector(compare:)];
	
	pthread_rwlock_unlock(&_userAccountMutex);
	
	return tArray;
}

- (NSArray *)allLocalGroupsPosixNames
{
	int tError=pthread_rwlock_rdlock(&_groupAccountMutex);
	
	if (tError!=0)
		NSLog(@"group read lock error: %d",tError);
	
	NSArray * tArray=[[_posixName_groupAccountIDCache allKeys] sortedArrayUsingSelector:@selector(compare:)];
	
	pthread_rwlock_unlock(&_groupAccountMutex);
	
	return tArray;
}

#pragma mark -

- (NSMenu *)localUsersMenu
{
	return [self localUsersMenuWithServicesUsers:YES];
}

- (NSMenu *)localUsersMenuWithServicesUsers:(BOOL)inIncludeServicesUsers
{
	NSMenu * tMenu=[[NSMenu alloc] initWithTitle:@""];
	
	int tError=pthread_rwlock_rdlock(&_userAccountMutex);
	
	if (tError!=0)
		NSLog(@"user read lock error: %d",tError);
	
	NSArray * tAllKeys=[_posixName_userAccountIDCache.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	if (inIncludeServicesUsers==NO)
	{
		tAllKeys=[tAllKeys WB_filteredArrayUsingBlock:^BOOL(NSString * bPosixName,NSUInteger bIndex) {
			
			return ([bPosixName hasPrefix:@"_"]==NO);
			
		}];
	}
	
	[tAllKeys enumerateObjectsUsingBlock:^(NSString * bPosixName,NSUInteger bIndex,BOOL * bOutStop){
	
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:bPosixName action:nil keyEquivalent:@""];
		NSNumber * tNumber=self->_posixName_userAccountIDCache[bPosixName];
		
		if (tNumber==nil)
			return;
		
		tMenuItem.tag=tNumber.integerValue;
		
		[tMenu addItem:tMenuItem];
	
	}];
	
	pthread_rwlock_unlock(&_userAccountMutex);
	
	return tMenu;
}

- (NSMenu *)localGroupsMenu
{
	return [self localGroupsMenuWithServicesGroups:YES];
}

- (NSMenu *)localGroupsMenuWithServicesGroups:(BOOL)inIncludeServicesGroups
{
	NSMenu * tMenu=[[NSMenu alloc] initWithTitle:@""];
	
	int tError=pthread_rwlock_rdlock(&_groupAccountMutex);
	
	if (tError!=0)
		NSLog(@"user read lock error: %d",tError);
	
	NSArray * tAllKeys=[_posixName_groupAccountIDCache.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	if (inIncludeServicesGroups==NO)
	{
		tAllKeys=[tAllKeys WB_filteredArrayUsingBlock:^BOOL(NSString * bPosixName,NSUInteger bIndex) {
			
			return ([bPosixName hasPrefix:@"_"]==NO);
			
		}];
	}
	
	[tAllKeys enumerateObjectsUsingBlock:^(NSString * bPosixName,NSUInteger bIndex,BOOL * bOutStop){
		
		NSMenuItem * tMenuItem=[[NSMenuItem alloc] initWithTitle:bPosixName action:nil keyEquivalent:@""];
		NSNumber * tNumber=self->_posixName_groupAccountIDCache[bPosixName];
		
		if (tNumber==nil)
			return;
		
		tMenuItem.tag=tNumber.integerValue;
		
		[tMenu addItem:tMenuItem];
		
	}];
	
	pthread_rwlock_unlock(&_userAccountMutex);
	
	return tMenu;
}

@end

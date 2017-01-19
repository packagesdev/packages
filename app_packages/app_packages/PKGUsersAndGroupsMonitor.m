/*
 Copyright (c) 2017, Stephane Sudre
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
			// A COMPLETER
			
			return nil;
		}
		
		tMutexError=pthread_rwlock_init(&_groupAccountMutex,NULL);
		
		if (tMutexError!=0)
		{
			pthread_rwlock_destroy(&_userAccountMutex);
			
			// A COMPLETER
			
			return nil;
		}
		
		_openDirectorySession=[ODSession defaultSession];
		
		NSError * tError=nil;
		
		_openDirectoryRootNode=[ODNode nodeWithSession:_openDirectorySession type:kODNodeTypeLocalNodes error:&tError];
		
		if (_openDirectoryRootNode==nil)
		{
			// A COMPLETER
		}
		
		_usersQuery = [ODQuery queryWithNode:_openDirectoryRootNode forRecordTypes:kODRecordTypeUsers attribute:nil matchType:0 queryValues:nil returnAttributes:@[kODAttributeTypeUniqueID] maximumResults:0 error:&tError];
		
		if (_usersQuery==nil)
		{
		}
		
		
		_groupsQuery = [ODQuery queryWithNode:_openDirectoryRootNode forRecordTypes:kODRecordTypeGroups attribute:nil matchType:0 queryValues:nil returnAttributes:@[kODAttributeTypePrimaryGroupID] maximumResults:0 error:&tError];
		
		if (_groupsQuery==nil)
		{
		}
		
		[self refreshCache];
		
		notify_register_dispatch(kNotifyDSCacheInvalidationUser, &_usersNotificationToken, dispatch_get_main_queue(), ^(int bToken){
		
			pthread_rwlock_wrlock(&_userAccountMutex);
			
			[self refreshCache];
			
			pthread_rwlock_unlock(&_userAccountMutex);
		
		});
		
		notify_register_dispatch(kNotifyDSCacheInvalidationUser, &_groupsNotificationToken, dispatch_get_main_queue(), ^(int bToken){
			
			pthread_rwlock_wrlock(&_groupAccountMutex);
			
			[self _refreshGroupsCache];
			
			pthread_rwlock_unlock(&_groupAccountMutex);
			
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
	NSString * tPosixName=nil;
	
	int tError=pthread_rwlock_rdlock(&_userAccountMutex);
	
	if (tError!=0)
		NSLog(@"user read lock error: %d",tError);
	
	tPosixName=_userAccountID_PosixNameCache[@(inUID)];
	
	pthread_rwlock_unlock(&_userAccountMutex);
	
	return tPosixName;
}

- (NSString *)posixNameForGroupAccountID:(gid_t)inGID
{
	NSString * tPosixName=nil;
	
	int tError=pthread_rwlock_rdlock(&_groupAccountMutex);
	
	if (tError!=0)
		NSLog(@"group read lock error: %d",tError);
	
	tPosixName=_groupAccountID_PosixNameCache[@(inGID)];
	
	pthread_rwlock_unlock(&_groupAccountMutex);
	
	return tPosixName;
}

- (NSArray *)allLocalUserPosixNames
{
	NSArray * tArray=nil;
	
	int tError=pthread_rwlock_rdlock(&_userAccountMutex);
	
	if (tError!=0)
		NSLog(@"user read lock error: %d",tError);
	
	tArray=[[_posixName_userAccountIDCache allKeys] sortedArrayUsingSelector:@selector(compare:)];
	
	pthread_rwlock_unlock(&_userAccountMutex);
	
	return tArray;
}

- (NSArray *)allLocalGroupsPosixNames
{
	NSArray * tArray=nil;
	
	int tError=pthread_rwlock_rdlock(&_groupAccountMutex);
	
	if (tError!=0)
		NSLog(@"group read lock error: %d",tError);
	
	tArray=[[_posixName_groupAccountIDCache allKeys] sortedArrayUsingSelector:@selector(compare:)];
	
	pthread_rwlock_unlock(&_groupAccountMutex);
	
	return tArray;
}

@end

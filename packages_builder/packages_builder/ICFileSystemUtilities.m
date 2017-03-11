/*
Copyright (c) 2008-2012, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "ICFileSystemUtilities.h"

#include <CoreServices/CoreServices.h>

#include <sys/stat.h>

static OSErr MyFSPathMakeRef(const char * inPath, FSRef * outFSRef );

@implementation ICFileSystemUtilities

/*- (BOOL)copyItemAtURL:(NSURL *)srcURL
 toURL:(NSURL *)dstURL
 error:(NSError * _Nullable *)error;
 */


+ (int) copyPath:(NSString *) fromPath toPath:(NSString *) toDirectoryPath
{
	OSStatus tStatus;
	OSErr tErr;
	FSRef sourceRef, destRef;
	
	tErr = MyFSPathMakeRef( [fromPath UTF8String], &sourceRef );
        
	if( tErr == noErr)	// Get FSRef to destination object
	{
		// We don't have to worry about the symlink problem (2489632) here	
		// cause we would want to copy into the target of the symlink	
		// anyways.  And if its not a symlink, no problems...		
		
		tErr = FSPathMakeRef( (unsigned char *) [toDirectoryPath UTF8String], &destRef, NULL );
		
		if( tErr == noErr )					// make sure the dest is a directory
		{
			tStatus=FSCopyObjectSync(&sourceRef,&destRef,NULL,NULL,kFSFileOperationOverwrite);
	
			if (tStatus==noErr)
			{
				return ICFSU_OK;
			}
			
			switch(tStatus)
			{
				case fnfErr:
				
					return ICFSU_MISSING_FILE;
			}
		}
	}
	else
	{
		switch(tErr)
		{
			case fnfErr:
			
				return ICFSU_MISSING_FILE;
		}
	}
	
	return ICFSU_ERROR;
}

@end

static OSErr MyFSPathMakeRef( const char * inPath, FSRef * outFSRef )
{
	FSRef			tmpFSRef;
	char			tmpPath[ PATH_MAX ],
					*tmpNamePtr;
	OSErr			err;
        char * tCharPtr;
					/* Get local copy of incoming path					*/
	strcpy( tmpPath, (char*)inPath );

					/* Get the name of the object from the given path	*/
					/* Find the last / and change it to a '\0' so		*/
					/* tmpPath is a path to the parent directory of the	*/
					/* object and tmpNamePtr is the name				*/
	tmpNamePtr = strrchr( tmpPath, '/' );
	if( *(tmpNamePtr + 1) == '\0' )
	{				/* in case the last character in the path is a /	*/
		*tmpNamePtr = '\0';
		tmpNamePtr = strrchr( tmpPath, '/' );
	}
	*tmpNamePtr = '\0';
	tmpNamePtr++;
	
        tCharPtr=tmpNamePtr;
        
        while (*tCharPtr!='\0')
        {
            if ((*tCharPtr)==':')
            {
                *tCharPtr='/';
            }
        
            tCharPtr++;
        }
        
					/* Get the FSRef to the parent directory			*/
	err = FSPathMakeRef( (unsigned char*)tmpPath, &tmpFSRef, NULL );
	
	if( err == noErr )
	{				/* Convert the name to a Unicode string and pass it	*/
					/* to FSMakeFSRefUnicode to actually get the FSRef	*/
					/* to the object (symlink)							*/
            UniChar			uniName[255];
            CFStringRef 	tmpStringRef = CFStringCreateWithCString( kCFAllocatorDefault, tmpNamePtr, kCFStringEncodingUTF8 );
		
			if( tmpStringRef != NULL )
            {
				CFStringGetCharacters(tmpStringRef, CFRangeMake(0, CFStringGetLength(tmpStringRef)), uniName);
				
				err = FSMakeFSRefUnicode( &tmpFSRef, CFStringGetLength( tmpStringRef ), uniName, kTextEncodingUnknown, &tmpFSRef );
				
				CFRelease( tmpStringRef );
            }
            else
            {
                err = 1;
            }
        }
	
	if( err == noErr )
        {
            *outFSRef = tmpFSRef;
	}
        
	return err;
}

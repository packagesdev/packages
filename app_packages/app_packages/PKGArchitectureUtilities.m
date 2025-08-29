/*
Copyright (c) 2007-2020, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGArchitectureUtilities.h"

#include <mach-o/loader.h>
#include <mach-o/fat.h>

#ifdef __LP64__

typedef OSType CFragArchitecture;
enum 
{
	/* Values for type CFragArchitecture.*/
	kPowerPCCFragArch             = 'pwpc',
	kMotorola68KCFragArch         = 'm68k',
	kAnyCFragArch                 = 0x3F3F3F3F
};

#endif

@implementation PKGArchitectureUtilities 

+ (NSArray *)architecturesOfFileAtPath:(NSString *)inPath
{
	if (inPath==nil)
		return nil;
	
	FILE * tFile=fopen([inPath fileSystemRepresentation],"r");
	
	if (tFile==NULL)
	{
		switch(errno)
		{
			case EACCES:
				
				NSLog(@"[PKGArchitectureUtilities architecturesOfFileAtPath:] Read permission denied \'%@\'",inPath);
				break;
				
			case ENOENT:
			case ENOTDIR:
				
				NSLog(@"[PKGArchitectureUtilities architecturesOfFileAtPath:] File not found \'%@\'",inPath);
				break;
		}
		
		return nil;
	}
	
	uint32_t tMagicCookie;
	
	if (fread(&tMagicCookie,sizeof(uint32_t),1,tFile)!=1)
	{
		if (feof(tFile)!=0)
		{
			fclose(tFile);
			return @[];
		}
		
		int tError=ferror(tFile);
		
		switch(tError)
		{
			case EISDIR:
				
				fclose(tFile);
				return nil;
				
			case EINVAL:
			{
				fseek(tFile, 0L, SEEK_END);
				long tSize = ftell(tFile);
				
				if (tSize==0)
				{
					fclose(tFile);
					
					return @[];
				}
			}
			
			default:
				
				NSLog(@"[PKGArchitectureUtilities architecturesOfFileAtPath:] Read error (%d) \'%@\'",tError,inPath);
				
				fclose(tFile);
				
				return nil;
		}
	}
	
#if BYTE_ORDER==LITTLE_ENDIAN
	tMagicCookie=CFSwapInt32(tMagicCookie);
#endif
		
	fseek(tFile,0,SEEK_SET);
	
	if (tMagicCookie==kPEFTag1)
	{
		// PEF
		
		PEFContainerHeader tContainerHeader;
		
		size_t tReadSize=fread(&tContainerHeader,sizeof(PEFContainerHeader),1,tFile);
		fclose(tFile);
		
		if (tReadSize!=1)
		{
			NSLog(@"[PKGArchitectureUtilities architecturesOfFileAtPath:] Read error (%d) \'%@\'",errno,inPath);
			
			return nil;
		}
			
#if BYTE_ORDER==LITTLE_ENDIAN
		tContainerHeader.tag2=CFSwapInt32(tContainerHeader.tag2);
		tContainerHeader.architecture=CFSwapInt32(tContainerHeader.architecture);
#endif

		if (tContainerHeader.tag2==kPEFTag2 &&
			tContainerHeader.architecture==kPowerPCCFragArch)
			return @[@"ppc"];
		
		return @[];
	}

	// mach-o
		
	if (tMagicCookie==FAT_MAGIC || tMagicCookie==FAT_CIGAM)
	{
		// FAT
		
		struct fat_header tFatHeader;
		
		if (fread(&tFatHeader,sizeof(struct fat_header),1,tFile)!=1)
		{
			fclose(tFile);
			
			NSLog(@"[PKGArchitectureUtilities architecturesOfFileAtPath:] Read error (%d) \'%@\'",errno,inPath);
			
			return nil;
		}
		
		NSMutableArray * tMutableArray=[NSMutableArray array];
		
#if BYTE_ORDER==LITTLE_ENDIAN
		tFatHeader.nfat_arch=CFSwapInt32(tFatHeader.nfat_arch);
#endif

		for(uint32_t i=0;i<tFatHeader.nfat_arch;i++)
		{
			struct fat_arch tFatArch;
		
			if (fread(&tFatArch,sizeof(struct fat_arch),1,tFile)==1)
			{
#if BYTE_ORDER==LITTLE_ENDIAN
				tFatArch.cputype=CFSwapInt32(tFatArch.cputype);
#endif										

				switch(tFatArch.cputype)
				{
					case CPU_TYPE_ARM:
					
						[tMutableArray addObject:@"arm"];
						
						break;
					
					case CPU_TYPE_ARM64:
						
						[tMutableArray addObject:@"arm64"];
						
						break;
					
					case CPU_TYPE_X86:
					
						[tMutableArray addObject:@"i386"];
						
						break;
						
					case CPU_TYPE_X86_64:
					
						[tMutableArray addObject:@"x86_64"];
						
						break;
						
					case CPU_TYPE_POWERPC:
					
						[tMutableArray addObject:@"ppc"];
						
						break;
						
					case CPU_TYPE_POWERPC64:
					
						[tMutableArray addObject:@"ppc64"];
						
						break;
				}
			}
			else
			{
				break;
			}
		}
		
		fclose(tFile);
		
		return [tMutableArray sortedArrayUsingSelector:@selector(compare:)];
	}
	
    if (tMagicCookie==FAT_MAGIC_64 || tMagicCookie==FAT_CIGAM_64)
    {
        // FAT
        
        struct fat_header tFatHeader;
        
        if (fread(&tFatHeader,sizeof(struct fat_header),1,tFile)!=1)
        {
            fclose(tFile);
            
            NSLog(@"[PKGArchitectureUtilities architecturesOfFileAtPath:] Read error (%d) \'%@\'",errno,inPath);
            
            return nil;
        }
        
        NSMutableArray * tMutableArray=[NSMutableArray array];
        
#if BYTE_ORDER==LITTLE_ENDIAN
        tFatHeader.nfat_arch=CFSwapInt32(tFatHeader.nfat_arch);
#endif
        
        for(uint32_t i=0;i<tFatHeader.nfat_arch;i++)
        {
            struct fat_arch_64 tFatArch;
            
            if (fread(&tFatArch,sizeof(struct fat_arch_64),1,tFile)==1)
            {
#if BYTE_ORDER==LITTLE_ENDIAN
                tFatArch.cputype=CFSwapInt32(tFatArch.cputype);
#endif
                
                switch(tFatArch.cputype)
                {
                    case CPU_TYPE_ARM:
                        
                        [tMutableArray addObject:@"arm"];
                        
                        break;
                        
                    case CPU_TYPE_ARM64:
                        
                        [tMutableArray addObject:@"arm64"];
                        
                        break;
                        
                    case CPU_TYPE_X86:
                        
                        [tMutableArray addObject:@"i386"];
                        
                        break;
                        
                    case CPU_TYPE_X86_64:
                        
                        [tMutableArray addObject:@"x86_64"];
                        
                        break;
                        
                    case CPU_TYPE_POWERPC:
                        
                        [tMutableArray addObject:@"ppc"];
                        
                        break;
                        
                    case CPU_TYPE_POWERPC64:
                        
                        [tMutableArray addObject:@"ppc64"];
                        
                        break;
                }
            }
			else
			{
				break;
			}
        }
        
        fclose(tFile);
        
        return [tMutableArray sortedArrayUsingSelector:@selector(compare:)];
    }
    
	if (tMagicCookie==MH_MAGIC || tMagicCookie==MH_CIGAM)
	{
		// 32-bit
		
		struct mach_header tMachHeader;
		
		size_t tReadSize=fread(&tMachHeader,sizeof(struct mach_header),1,tFile);
		fclose(tFile);
		
		if (tReadSize!=1)
		{
			NSLog(@"[PKGArchitectureUtilities architecturesOfFileAtPath:] Read error (%d) \'%@\'",errno,inPath);
			
			return nil;
		}
		
		if (tMagicCookie==MH_CIGAM)
		{
#if BYTE_ORDER==BIG_ENDIAN
			tMachHeader.cputype=CFSwapInt32(tMachHeader.cputype);
#endif
		}
		else
		{
#if BYTE_ORDER==LITTLE_ENDIAN
			tMachHeader.cputype=CFSwapInt32(tMachHeader.cputype);
#endif
		}

		switch(tMachHeader.cputype)
		{
			case CPU_TYPE_ARM:
				
				return @[@"arm"];
			
			case CPU_TYPE_X86:
			
				return @[@"i386"];
				
			case CPU_TYPE_POWERPC:
			
				return @[@"ppc"];
		}
		
		return @[];
	}
	
	if (tMagicCookie==MH_MAGIC_64 || tMagicCookie==MH_CIGAM_64)
	{
		// 64-bit
		
		struct mach_header_64 tMachHeader64;
		
		size_t tReadSize=fread(&tMachHeader64,sizeof(struct mach_header_64),1,tFile);
		fclose(tFile);
		
		if (tReadSize!=1)
		{
			NSLog(@"[PKGArchitectureUtilities architecturesOfFileAtPath:] Read error (%d) \'%@\'",errno,inPath);
			
			return nil;
		}
		
		if (tMagicCookie==MH_CIGAM_64)
		{
#if BYTE_ORDER==BIG_ENDIAN
			tMachHeader64.cputype=CFSwapInt32(tMachHeader64.cputype);
#endif
		}
		else
		{
#if BYTE_ORDER==LITTLE_ENDIAN
			tMachHeader64.cputype=CFSwapInt32(tMachHeader64.cputype);
#endif
		}
		
		switch(tMachHeader64.cputype)
		{
			case CPU_TYPE_ARM64:
				
				return @[@"arm64"];
			
			case CPU_TYPE_X86_64:
			
				return @[@"x86_64"];
				
			case CPU_TYPE_POWERPC64:
			
				return @[@"ppc64"];
		}
		
		return @[];
	}
	
	fclose(tFile);
	
	return @[];
}

@end

//
//  PKGBuildInformation+Accumulate.m
//  packages_builder
//
//  Created by stephane on 02/08/2021.
//

#import "PKGBuildInformation+Accumulate.h"

#include <sys/stat.h>
#include <fts.h>

#include <mach-o/loader.h>
#include <mach-o/fat.h>

#import "PKGArchitectureUtilities.h"

@interface PKGBuildInformation (Accumulate_Private)

- (void)_processRegularFile:(char *)inPath;

@end

@implementation PKGBuildInformation (Accumulate)

- (void)_processRegularFile:(char *)inPath
{
    // Read the first 4 bytes to eliminate obvious non Mach-o files
    
    FILE * tRegularFile=fopen(inPath,"r");
    
    if (tRegularFile==NULL)
        return;
    
    uint32_t tMagicCookie;
    
    size_t tSize=fread(&tMagicCookie,sizeof(uint32_t),1,tRegularFile);
    
    fclose(tRegularFile);
    
    if (tSize!=1)
        return;
    
#if BYTE_ORDER==LITTLE_ENDIAN
    tMagicCookie=CFSwapInt32(tMagicCookie);
#endif
    
    if (tMagicCookie==kPEFTag1 ||
        tMagicCookie==FAT_MAGIC ||
        tMagicCookie==FAT_CIGAM ||
        tMagicCookie==MH_MAGIC ||
        tMagicCookie==MH_CIGAM ||
        tMagicCookie==MH_MAGIC_64 ||
        tMagicCookie==MH_CIGAM_64 )
    {
        NSArray * tHostArchitectures=[PKGArchitectureUtilities architecturesOfFileAtPath:[NSString stringWithUTF8String:inPath]];
        
        if (tHostArchitectures.count==0)
        {
            if (tHostArchitectures==nil)
            {
                NSLog(@"An error when trying to find the included architectures for file \"%s\". Will not be able to determine the hostArchitectures automatically.",inPath);
            
                [self updateHostArchitecturesSetWithSet:[NSSet set]];
            }
            else
            {
                NSLog(@"Mach-o file with no architectures, this is weird. %s",inPath);
            }
        }
        else
        {
            [self updateHostArchitecturesSetWithSet:[NSSet setWithArray:tHostArchitectures]];
        }
    }
}

- (void)accumulateHostArchitecturesInFileHierarchyAtPath:(NSString *)inFileHierarchyPath
{
    if (inFileHierarchyPath==nil)
        return;
    
    char * tPath[2]={(char *) inFileHierarchyPath.fileSystemRepresentation,NULL};
    
    FTS * ftsp = fts_open(tPath, FTS_PHYSICAL, 0);
    
    if (ftsp == NULL)
        return;
    
    FTSENT * tFile;
    
    while ((tFile = fts_read(ftsp)) != NULL)
    {
        switch (tFile->fts_info)
        {
            case FTS_DC:
            case FTS_DNR:
            case FTS_ERR:
            case FTS_NS:
                fts_close(ftsp);
                
                return;
                
            case FTS_F:
                
                if (S_ISREG(tFile->fts_statp->st_mode))
                {
                    [self _processRegularFile:tFile->fts_path];
                }
                
                break;
            default:
                break;
        }
    }
    
    fts_close(ftsp);
}

- (BOOL)accumulateBundleVersionsAndHostArchitecturesInFileHierarchyAtPath:(NSString *)inFileHierarchyPath forPackageUUID:(NSString *)inPackageUUID
{
    if (inFileHierarchyPath==nil || inPackageUUID==nil)
        return NO;
    
    char * tPath[2]={(char *) [inFileHierarchyPath fileSystemRepresentation],NULL};
    
    FTS * ftsp = fts_open(tPath, FTS_PHYSICAL, 0);
    
    if (ftsp == NULL)
        return YES;
    
    NSMutableArray * tLevelsArray=[NSMutableArray array];
    
    NSMutableArray * tParentsChildrenArray=[NSMutableArray array];
    NSMutableArray * tMutableArray=[NSMutableArray array];
    
    short tCurrentBundleLevel=-100;
    
    NSUInteger tLength=[inFileHierarchyPath length];
    
    FTSENT * tFile;
    
    while ((tFile = fts_read(ftsp)) != NULL)
    {
        switch (tFile->fts_info)
        {
            case FTS_DC:
            case FTS_DNR:
            case FTS_ERR:
            case FTS_NS:
                fts_close(ftsp);
                
                return NO;
            case FTS_D:
            {
                NSString * tBundlePath=nil;
                NSString * tAbsolutePath=nil;
                
                if (!strncmp(tFile->fts_name,"Contents",8))
                {
                    tAbsolutePath=[NSString stringWithUTF8String:tFile->fts_path];
                    
                    tBundlePath=[tAbsolutePath stringByDeletingLastPathComponent];
                }
                else if (strstr(tFile->fts_name,".framework")!=NULL)
                {
                    tBundlePath=[NSString stringWithUTF8String:tFile->fts_path];
                    
                    tAbsolutePath=[tBundlePath stringByAppendingPathComponent:@"Resources"];
                }
                
                if (tBundlePath!=nil && tAbsolutePath!=nil)
                {
                    NSBundle * tBundle=[NSBundle bundleWithPath:tBundlePath];
                    
                    if (tBundle==nil)
                        continue;
                    
                    NSDictionary * tInfoDictionary=[tBundle infoDictionary];
                    
                    if (tInfoDictionary!=nil)
                    {
                        tCurrentBundleLevel=tFile->fts_level;
                        
                        NSString * tStringPath=[tBundlePath substringFromIndex:tLength];
                        
                        NSMutableDictionary * tMutableBundleVersionDictionary=[NSMutableDictionary dictionary];
                        
                        tMutableBundleVersionDictionary[@"path"]=tStringPath;
                        
                        // Get Information from the Info.plist file
                        
                        // CFBundleShortVersionString
                        
                        id tObject=tInfoDictionary[@"CFBundleShortVersionString"];
                        
                        if (tObject!=nil)
                            tMutableBundleVersionDictionary[@"CFBundleShortVersionString"]=tObject;
                        
                        // CFBundleVersion
                        
                        tObject=tInfoDictionary[@"CFBundleVersion"];
                        
                        if (tObject!=nil)
                            tMutableBundleVersionDictionary[@"CFBundleVersion"]=tObject;
                        
                        // CFBundleIdentifier
                        
                        tObject=tInfoDictionary[@"CFBundleIdentifier"];
                        
                        if (tObject!=nil)
                        {
                            tMutableBundleVersionDictionary[@"CFBundleIdentifier"]=tObject;
                            
                            tMutableBundleVersionDictionary[@"id"]=tObject;
                        }
                        
                        
                        // Look for a version.plist file
                        
                        NSString * tVersionFilePath=[tAbsolutePath stringByAppendingPathComponent:@"version.plist"];
                        
                        NSDictionary * tVersionDictionary=[NSDictionary dictionaryWithContentsOfFile:tVersionFilePath];
                        
                        if (tVersionDictionary!=nil)
                        {
                            // BuildVersion
                            
                            tObject=tVersionDictionary[@"BuildVersion"];
                            
                            if (tObject!=nil)
                                tMutableBundleVersionDictionary[@"BuildVersion"]=tObject;
                            
                            // ProjectName
                            
                            tObject=tVersionDictionary[@"ProjectName"];
                            
                            if (tObject!=nil)
                                tMutableBundleVersionDictionary[@"ProjectName"]=tObject;
                            
                            // SourceVersion
                            
                            tObject=tVersionDictionary[@"SourceVersion"];
                            
                            if (tObject!=nil)
                                tMutableBundleVersionDictionary[@"SourceVersion"]=tObject;
                            
                            // CFBundleShortVersionString
                            
                            tObject=tVersionDictionary[@"CFBundleShortVersionString"];
                            
                            if (tObject!=nil && tMutableBundleVersionDictionary[@"CFBundleShortVersionString"]==nil)
                                tMutableBundleVersionDictionary[@"CFBundleShortVersionString"]=tObject;
                            
                            // CFBundleVersion
                            
                            tObject=tVersionDictionary[@"CFBundleVersion"];
                            
                            if (tObject!=nil && tMutableBundleVersionDictionary[@"CFBundleShortVersionString"]==nil)
                                tMutableBundleVersionDictionary[@"CFBundleVersion"]=tObject;
                        }
                        
                        NSMutableArray * tChildrenArray=[tParentsChildrenArray lastObject];
                        
                        if (tChildrenArray!=nil)
                            [tChildrenArray addObject:tMutableBundleVersionDictionary];
                        else
                            [tMutableArray addObject:tMutableBundleVersionDictionary];
                        
                        [tLevelsArray addObject:@(tFile->fts_level)];
                        
                        tChildrenArray=[NSMutableArray array];
                        
                        tMutableBundleVersionDictionary[@"Children"]=tChildrenArray;
                        
                        [tParentsChildrenArray addObject:tChildrenArray];
                    }
                }
                
                break;
            }
                
            case FTS_DP:
                
                if (tCurrentBundleLevel==tFile->fts_level)
                {
                    [tParentsChildrenArray removeLastObject];
                    
                    [tLevelsArray removeLastObject];
                    
                    NSNumber * tNumber=[tLevelsArray lastObject];
                    
                    tCurrentBundleLevel=(tNumber!=nil) ? [tNumber shortValue] : -100;
                }
                
                break;
            case FTS_SL:
            case FTS_SLNONE:
                continue;
                
            case FTS_F:
                
                if (S_ISREG(tFile->fts_statp->st_mode))
                {
                    [self _processRegularFile:tFile->fts_path];
                }
                
                continue;
            default:
                break;
        }
    }
    
    if (tMutableArray.count>0)
    {
        PKGBuildPackageAttributes * tBuildPackageAttributes=self.packagesAttributes[inPackageUUID];
        
        [tBuildPackageAttributes.bundlesVersions addObjectsFromArray:tMutableArray];
    }
    
    fts_close(ftsp);
    
    return YES;
}

@end

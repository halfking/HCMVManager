//
//  HCFileManager.m
//  hccoren
//
//  Created by HUANGXUTAO on 16/4/30.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "HCFileManager.h"
#import "HCBase.h"
#import "RegexKitLite.h"
#import "JSON.h"
#import <HCMinizip/ZipFile.h>
#import "CommonUtil.h"
#include <sys/param.h>
#include <sys/mount.h>

@interface HCFileManager()
{
    NSString * applicationRoot_;
    NSString * rootPath_;
    NSString * rootPathMatchString_;

    NSString * tempFileRoot_;
    NSArray * reservedFileNames_; // 需要保留的文件
}
@end
@implementation HCFileManager
static HCFileManager * hcFileManager = nil;
+(id)defaultManager
{
    if(hcFileManager==nil)
    {
        @synchronized(self)
        {
            if (hcFileManager==nil)
            {
                hcFileManager = [[HCFileManager alloc]init];
            }
        }
    }
    return hcFileManager;
}
+(HCFileManager *)manager
{
    return (HCFileManager *)[self defaultManager];
}
#pragma mark - dir

+ (void)createFileDirectory:(NSString *)dirFullPath
{
    
    // 判断存放音频、视频的文件夹是否存在，不存在则创建对应文件夹
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL isDir = FALSE;
    
    BOOL isDirExist = [fileManager fileExistsAtPath:dirFullPath
                                        isDirectory:&isDir];
    
    if(!(isDirExist && isDir))
    {
        NSError * error = nil;
        if(isDirExist)
        {
            [fileManager removeItemAtPath:dirFullPath error:&error];
            if(error)
            {
                NSLog(@" remove path:%@ failure:%@",dirFullPath,[error description]);
            }
        }
        BOOL bCreateDir = [fileManager createDirectoryAtPath:dirFullPath
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:&error];
        
        if(!bCreateDir){
            
            NSLog(@"Create dir:%@ Failed.%@",dirFullPath,[error description]);
            
        }
        
    }
}
+ (BOOL)createFileDirectories:(NSString * )path
{
    if(!path || path.length==0) return NO;
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString *  parentPath = [path stringByDeletingLastPathComponent];
    if(![fm fileExistsAtPath:parentPath])
    {
        if(![self createFileDirectories:parentPath])
            return NO;
    }
    [fm changeCurrentDirectoryPath:parentPath];
    path = [path substringFromIndex:parentPath.length+1];
    
    
    //    [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    //    if(error)
    //    {
    //        NSLog(@" create path:%@",path);
    //        NSLog(@" create failure:%@",[error localizedDescription]);
    //        return NO;
    //    }
    
    BOOL isDir = FALSE;
    
    BOOL isDirExist = [fm fileExistsAtPath:path
                               isDirectory:&isDir];
    
    if(!(isDirExist && isDir))
    {
        NSError * error = nil;
        if(isDirExist)
        {
            [fm removeItemAtPath:path error:&error];
            if(error)
            {
                NSLog(@" remove path:%@ failure:%@",path,[error description]);
                return NO;
            }
        }
        BOOL bCreateDir = [fm createDirectoryAtPath:path
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:&error];
        
        if(!bCreateDir){
            
            NSLog(@"Create dir:%@ Failed.%@",path,[error description]);
            return NO;
            
        }
        
    }
    
    return YES;
}

+ (void)movePath:(NSString *)sourcePath target:(NSString *)targetPath overwrite:(BOOL)overwriter
{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError * error = nil;
    
    if((!overwriter) && ( ![fileManager fileExistsAtPath:targetPath]))
    {
        [self createFileDirectories:targetPath];
    }
    else
    {
        [self createFileDirectories:targetPath];
    }
    
    NSArray * fileList = [fileManager contentsOfDirectoryAtPath:sourcePath error:&error];
    if(error)
    {
        NSLog(@"** get dir files failure:%@",[error description]);
    }
    
    
    
    for (NSString * fileName in fileList) {
        
        NSString * targetFile = [targetPath stringByAppendingPathComponent:fileName];
        NSString * sourceFile = [sourcePath stringByAppendingPathComponent:fileName];
        NSError * errorMove = nil;
        BOOL exists = [fileManager fileExistsAtPath:targetFile];
        if( exists && overwriter)
        {
            [fileManager removeItemAtPath:targetFile error:&error];
            if(error)
            {
                NSLog(@"** remove exists file:%@ failure:%@",targetFile,[error description]);
            }
        }
        if(!exists || overwriter)
        {
            NSDictionary * attr = [fileManager attributesOfItemAtPath:sourceFile error:&errorMove];
            if(errorMove)
            {
                NSLog(@"** get file attributes failure: %@",[errorMove description]);
            }
            if([[attr objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
            {
                [self movePath:sourceFile target:targetFile overwrite:overwriter];
            }
            else
            {
                [fileManager moveItemAtPath:sourceFile toPath:targetFile error:&errorMove];
                if(errorMove)
                {
                    NSLog(@"** move file failure: %@",[errorMove description]);
                }
                else
                {
                    NSLog(@"** move file:%@ OK",sourceFile);
                }
            }
            
        }
    }
}
+ (void)copyFile:(NSString *)sourceFile target:(NSString *)targetFile overwrite:(BOOL)overwriter
{
    if(!targetFile || targetFile.length==0)
    {
        NSLog(@" empty target file.error....");
        return;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError * error = nil;
    
    NSString * targetPath = [targetFile stringByDeletingLastPathComponent];
    if((!overwriter) && ([fileManager fileExistsAtPath:targetPath]))
    {
        //        [self createFileDirectories:targetPath];
    }
    else
    {
        [self createFileDirectories:targetPath];
    }
    
    NSError * errorMove = nil;
    BOOL exists = [fileManager fileExistsAtPath:targetFile];
    if( exists && overwriter)
    {
        [fileManager removeItemAtPath:targetFile error:&error];
        if(error)
        {
            NSLog(@"** remove exists file:%@ failure:%@",targetFile,[error description]);
        }
    }
    else if(exists)
    {
        error = nil;
        UInt64 sizeTemp =  [[fileManager attributesOfItemAtPath:targetFile error:&error] fileSize];
        if(error)
        {
            NSLog(@" get file [%@] size failure:%@",targetFile,[error description]);
        }
        if(sizeTemp>0)
        {
            NSLog(@" file %@ exists,cannot copy.",targetFile);
            return;
        }
        else
        {
            error = nil;
            [fileManager removeItemAtPath:targetFile error:&error];
            if(error)
            {
                NSLog(@"** remove exists file:%@ failure:%@",targetFile,[error description]);
            }
        }
    }
    
    [fileManager copyItemAtPath:sourceFile toPath:targetFile error:&errorMove];
    if(errorMove)
    {
        NSLog(@"** copy file failure: %@",[errorMove description]);
    }
    else
    {
        NSLog(@"** copy file:%@ OK",sourceFile);
    }
    
    
}
+ (void)copyPath:(NSString *)sourcePath target:(NSString *)targetPath overwrite:(BOOL)overwriter
{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError * error = nil;
    NSArray * fileList = [fileManager contentsOfDirectoryAtPath:sourcePath error:&error];
    if(error)
    {
        NSLog(@"** get dir files failure:%@",[error description]);
    }
    
    if((!overwriter) && ( ![fileManager fileExistsAtPath:targetPath]))
    {
        [self createFileDirectories:targetPath];
    }
    else
    {
        [self createFileDirectories:targetPath];
    }
    
    for (NSString * fileName in fileList) {
        
        NSString * targetFile = [targetPath stringByAppendingPathComponent:fileName];
        NSString * sourceFile = [sourcePath stringByAppendingPathComponent:fileName];
        NSError * errorMove = nil;
        BOOL exists = [fileManager fileExistsAtPath:targetFile];
        if( exists && overwriter)
        {
            [fileManager removeItemAtPath:targetFile error:&error];
            if(error)
            {
                NSLog(@"** remove exists file:%@ failure:%@",targetFile,[error description]);
            }
        }
        if(!exists || overwriter)
        {
            NSDictionary * attr = [fileManager attributesOfItemAtPath:sourceFile error:&error];
            if(error)
            {
                NSLog(@"** get file attributes failure: %@",[error description]);
            }
            if([[attr objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
            {
                [self copyPath:sourceFile target:targetFile overwrite:overwriter];
            }
            else
            {
                [fileManager copyItemAtPath:sourceFile toPath:targetFile error:&errorMove];
                if(errorMove)
                {
                    NSLog(@"** move file failure: %@",[errorMove description]);
                }
                else
                {
                    NSLog(@"** move file:%@ OK",sourceFile);
                }
            }
        }
    }
}
#pragma mark - remove files
- (UInt64) getSizeFreeForDevice
{
    struct statfs buf;
    long long freespace = -1;
    if(statfs("/var", &buf) >= 0){
        freespace = (long long)(buf.f_bsize * buf.f_bfree);
    }
    return freespace;
    //    return [NSString stringWithFormat:@"手机剩余存储空间为：%qi MB" ,freespace/1024/1024];
}
//单个文件的大小
- (long long) fileSizeAtPath:(NSString*) filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([manager fileExistsAtPath:filePath isDirectory:&isDir] ){
        if(isDir)
        {
            return [self folderSizeAtPath:filePath];
        }
        else
        {
            NSError * error = nil;
            long long size =  [[manager attributesOfItemAtPath:filePath error:&error] fileSize];
            if(error)
            {
                NSLog(@" get file [%@] size failure:%@",filePath,[error description]);
            }
            return size;
        }
    }
    return 0;
}
//遍历文件夹获得文件夹大小，返回多少M
- (CGFloat ) folderSizeAtPath:(NSString*) folderPath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    return folderSize/(1024.0*1024.0);
}
- (BOOL) removeFilesAtPath:(NSString * )folderPath
{
    BOOL ret = YES;
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return 0;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        if([self removeFileAtPath:fileAbsolutePath]==NO)
        {
            ret = NO;
        }
    }
    return ret;
}
- (BOOL) removeFilesAtPath:(NSString * )folderPath matchRegex:(NSString *)regexString
{
    BOOL ret = YES;
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return NO;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        if([fileName isMatchedByRegex:regexString])
        {
            // 去除保留视频音频的内存
            BOOL equal = NO;
            for (NSString *file in reservedFileNames_) {
                if ([fileName isEqualToString:file]) {
                    equal = YES;
                    break;
                }
            }
            if (equal) continue;
            
            NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
            NSError * error = nil;
            [manager removeItemAtPath:fileAbsolutePath error:&error];
            if(error)
            {
                NSLog(@" remove file [%@] error:%@",fileAbsolutePath,[error description]);
                ret = NO;
            }
        }
    }
    return ret;
}
- (BOOL) removeFilesAtPath:(NSString * )folderPath matchRegex:(NSString *)regexString withoutPrefixList:(NSArray *)prefixList
{
    BOOL ret = YES;
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return NO;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        if([fileName isMatchedByRegex:regexString])
        {
            NSLog(@"%@",fileName);
            // 去除保留视频音频的内存
            BOOL equal = NO;
            for (NSString *file in reservedFileNames_) {
                if ([fileName isEqualToString:file]) {
                    equal = YES;
                }
            }
            if (equal) continue;
            
            BOOL has = NO;
            for (NSString *prefix in prefixList) {
                if ([fileName hasPrefix:prefix]) {
                    has = YES;
                }
            }
            if (has) continue;
            
            NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
            NSError * error = nil;
            [manager removeItemAtPath:fileAbsolutePath error:&error];
            if(error)
            {
                NSLog(@" remove file [%@] error:%@",fileAbsolutePath,[error description]);
                ret = NO;
            }
        }
    }
    return ret;
}
- (BOOL) removeFilesAtPath:(NSString * )folderPath withoutPrefixList:(NSArray *)prefixList
{
    BOOL ret = YES;
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return NO;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil)
    {
        // 去除保留视频音频的内存
        BOOL equal = NO;
        for (NSString *file in reservedFileNames_) {
            if ([fileName isEqualToString:file]) {
                equal = YES;
            }
        }
        if (equal) continue;
        
        BOOL has = NO;
        for (NSString *prefix in prefixList) {
            if ([fileName hasPrefix:prefix]) {
                has = YES;
            }
        }
        if (has) continue;
        
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        NSError * error = nil;
        [manager removeItemAtPath:fileAbsolutePath error:&error];
        if(error)
        {
            NSLog(@" remove file [%@] error:%@",fileAbsolutePath,[error description]);
            ret = NO;
        }
    }
    return ret;
}
- (BOOL) removeFilesAtPath:(NSString * )folderPath withoutRegex:(NSString *)regexString
{
    BOOL ret = YES;
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return NO;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        if(![fileName isMatchedByRegex:regexString])
        {
            // 去除保留视频音频的内存
            BOOL equal = NO;
            for (NSString *file in reservedFileNames_) {
                if ([fileName isEqualToString:file]) {
                    equal = YES;
                }
            }
            if (equal) continue;
            
            NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
            NSError * error = nil;
            [manager removeItemAtPath:fileAbsolutePath error:&error];
            if(error)
            {
                NSLog(@" remove file [%@] error:%@",fileAbsolutePath,[error description]);
                ret = NO;
            }
        }
    }
    return ret;
}
- (BOOL) removeFileAtPath:(NSString*) filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL ret  = YES;
    if ([manager fileExistsAtPath:filePath isDirectory:&isDir] ){
        if(isDir)
        {
            return [self removeFilesAtPath:filePath];
        }
        else
        {
            NSError * error = nil;
            ret = [manager removeItemAtPath:filePath error:&error];
            if(error)
            {
                NSLog(@" remove file [%@] error:%@",filePath,[error description]);
            }
            return ret;
        }
    }
    return NO;
}
- (BOOL)existFileAtPath:(NSString *)path
{
    NSFileManager* manager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL ret  = NO;
    if ([manager fileExistsAtPath:path isDirectory:&isDir] ){
        ret = YES;
    }
    return ret;
}

#pragma mark - common path
//获取本地文件的全路径
- (NSString *) localFileFullPath:(NSString *)fileUrl
{
    NSString * localPath = [self localFileDir];
    if(fileUrl && fileUrl.length>0)
    {
        if([self isFullFilePath:fileUrl])
            return fileUrl;
        
        //lowercaseString];
        //    fileUrl = [fileUrl lowercaseString];
        
        NSString * fileName = [self getFileName:fileUrl];
        localPath =  [localPath stringByAppendingPathComponent:fileName];
    }
    return [self getFilePath:localPath];
}
- (NSString *) tempFileFullPath:(NSString *)fileUrl
{
    NSString * localPath = [self tempFileDir];
    if(fileUrl && fileUrl.length>0)
    {
        if([self isFullFilePath:fileUrl])
            return fileUrl;
        
        //lowercaseString];
        //    fileUrl = [fileUrl lowercaseString];
        
        NSString * fileName = [self getFileName:fileUrl];
        localPath =  [localPath stringByAppendingPathComponent:fileName];
    }
    return [self getFilePath:localPath];
}
- (NSString *) localFileDir
{
    return @"localfiles";
}
- (NSString *) webRootFileDir
{
    return @"docroot";
}
- (NSString *) tempFileDir
{
    if(!tempFileRoot_ || tempFileRoot_.length==0)
    {
        tempFileRoot_ = @"tempfiles";
    }
    return tempFileRoot_;
}

#pragma mark - filename & filePath转换
- (NSString *)getRootPath
{
    if(!rootPath_ || rootPath_.length==0)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString * regex = @"/Application/[^/]+|/Applications/[^/]+";
        NSRange range = [documentsDirectory rangeOfRegex:regex];
        if(range.location!=NSNotFound)
        {
            rootPathMatchString_  = PP_RETAIN([documentsDirectory substringFromIndex:range.location]);
        }
        else
        {
            NSLog(@"不可能的事发生了!.....");
            rootPathMatchString_ = nil;
        }
        rootPath_ = PP_RETAIN(documentsDirectory);
    }
    return rootPath_;
}
- (BOOL) isFullFilePath:(NSString *)filePath
{
    NSString * rootPath = [self getRootPath];
    NSUInteger len = rootPath.length;
    
    if(filePath.length>len) //如果是绝对路径，则肯定会超过ApplicationPath的长度
    {
        NSRange range = [filePath rangeOfString:rootPathMatchString_];
        if(range.location!=NSNotFound)
        {
            return YES;
        }
        return NO;
    }
    else
    {
        return NO;
    }
}
- (NSString *) getFileName:(NSString*)filePath
{
    if(!filePath||filePath.length==0) return filePath;
    
    NSString * rootPath = [self getRootPath];
    NSUInteger len = rootPath.length;
    
    if(filePath.length>len) //如果是绝对路径，则肯定会超过ApplicationPath的长度
    {
        NSRange range = [filePath rangeOfString:rootPathMatchString_];
        if(range.location!=NSNotFound)
        {
            filePath = [filePath substringFromIndex:range.location + range.length+1];
            return filePath;
        }
        else
        {
            return [filePath substringFromIndex:len+1];
        }
    }
    else
    {
        return filePath;
    }
}
- (NSString *) getFilePath:(NSString *)fileName
{
    if(!fileName||fileName.length==0) return fileName;
    
    if([self isFullFilePath:fileName])
    {
        return [self checkPathForApplicationPathChanged:fileName isExists:nil];
    }
    else
    {
        NSString * rootPath = [self getRootPath];
        return [rootPath stringByAppendingPathComponent:fileName];
    }
}
- (NSString *)checkPathForApplicationPathChanged:(NSString *)orgPath isExists:(BOOL*)isExists
{
    if(!orgPath)
    {
        if(isExists) *isExists = NO;
        return nil;
    }
    
    orgPath = [HCFileManager checkPath:orgPath];
    NSFileManager * fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:orgPath])
    {
        if(isExists)
        {
            *isExists = YES;
        }
        return orgPath;
    }
    
    NSString * regex = @"/Application/[^/]+|/Applications/[^/]+";
    NSString * localApplication = [self getApplicationPath];
    if(localApplication)
    {
        NSString * newPath = [orgPath stringByReplacingOccurrencesOfRegex:regex withString:localApplication];
        if([fm fileExistsAtPath:newPath])
        {
            if(isExists) *isExists = YES;
            NSLog(@"path changed ?:\n orgPath: %@ --> \n newPath: %@",orgPath,newPath);
            return newPath;
        }
        else
        {
            if(isExists) *isExists = NO;
            return newPath;
        }
    }
    else
    {
        if(isExists) *isExists = NO;
    }
    return orgPath;
}
- (NSString *)getApplicationPath
{
    if(!applicationRoot_ || applicationRoot_.length==0)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString * regex = @"/Application/[^/]+|/Applications/[^/]+";
        applicationRoot_  = PP_RETAIN([documentsDirectory stringByMatching:regex]);
    }
    return applicationRoot_;
}
#pragma mark - helper

+ (BOOL) isQiniuServer:(NSString *)urlString
{
    return [urlString rangeOfString:@"qiniucdn.com"].length>0 || [urlString rangeOfString:@"qiniu.seenvoice.com"].length>0
    ||[urlString rangeOfString:@"img.seenvoice.com"].length>0 || [urlString rangeOfString:@"media.seenvoice.com"].length>0
    || [urlString rangeOfString:@"chat.seenvoice.com"].length>0;
}
+ (BOOL) isUrlOK:(NSString *)urlString
{
    if(!urlString || urlString.length<2) return NO;
    NSRange range = [urlString rangeOfRegex:@"http://|https://|file://|ftp://|rstp://|mstp://"];
    if(range.location==NSNotFound||range.location>5)
        return NO;
    else
        return YES;
}
+ (BOOL) isLocalFile:(NSString *)urlString
{
    if(!urlString||urlString.length==0) return YES;
    if([urlString hasPrefix:@"http://"]||[urlString hasPrefix:@"https://"]||[urlString hasPrefix:@"https://"]||[urlString hasPrefix:@"rtsp://"]||[urlString hasPrefix:@"rtp://"]||[urlString hasPrefix:@"rtcp://"]||[urlString hasPrefix:@"rtmp://"]||[urlString hasPrefix:@"stream://"])
    {
        return NO;
    }
    return YES;
}
+ (BOOL)isExistsFile:(NSString *)filePath
{
    NSFileManager * fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:[self checkPath:filePath]])
    {
        return YES;
    }
    return NO;
}
+ (BOOL)isFileExistAndNotEmpty:(NSString *)filePath size:(UInt64 *)size
{
    if(!filePath || filePath.length==0) return NO;
    NSFileManager * fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:[self checkPath:filePath]])
    {
        return NO;
    }
    NSError * error = nil;
    UInt64 sizeTemp =  [[fm attributesOfItemAtPath:filePath error:&error] fileSize];
    if(error)
    {
        NSLog(@" get file [%@] size failure:%@",filePath,[error description]);
    }
    if(size)
    {
        *size = sizeTemp;
    }
    if(sizeTemp > 0)
        return YES;
    else
        return NO;
}
+ (BOOL)isInAblum:(NSString *)path
{
    if([path hasPrefix:@"assets-library://"])
    {
        return YES;
    }
    return NO;
}
+ (NSString *)checkPath:(NSString *)path
{
    if(!path) return nil;
    if([path hasPrefix:@"file://"])
    {
        path = [path substringFromIndex:7];
    }
    return path;
}
+ (BOOL) isVideoFile:(NSString *)filePath
{
    if(!filePath) return NO;
    
    NSString * ext = [filePath pathExtension];
    ext = [ext lowercaseString];
    
    if([ext isEqualToString:@"mp4"]
       || [ext isEqualToString:@"mpeg"]
       || [ext isEqualToString:@"mpg"]
       || [ext isEqualToString:@"avi"]
       || [ext isEqualToString:@"asf"]
       || [ext isEqualToString:@"m4v"]
       || [ext isEqualToString:@"mov"])
    {
        return YES;
    }
    return NO;
}
+ (BOOL) isImageFile:(NSString *)filePath
{
    if(!filePath) return NO;
    
    NSString * ext = [filePath pathExtension];
    ext = [ext lowercaseString];
    
    if([ext isEqualToString:@"jpg"]
       || [ext isEqualToString:@"png"]
       || [ext isEqualToString:@"gif"]
       || [ext isEqualToString:@"bmp"]
       || [ext isEqualToString:@"jpeg"]
       || [ext isEqualToString:@"wmf"])
    {
        return YES;
    }
    return NO;
}
+ (NSString *)getFileExtensionName:(NSString *)orgPath  defaultExt:(NSString *)defaultExt
{
    if(!orgPath||orgPath.length==0) return defaultExt;
    NSString * ext = defaultExt;
    NSString * lastComponent = [orgPath lastPathComponent];
    NSRange  r = [lastComponent rangeOfString:@"."];
    NSInteger lastPos = -1;
    while (r.length>0) {
        lastPos = r.location;
        r = [lastComponent rangeOfString:@"." options:NSCaseInsensitiveSearch range:NSMakeRange(r.location +1, lastComponent.length - r.length - r.location-1)];
    }
    if(lastPos>0)
    {
        ext = [lastComponent substringFromIndex:lastPos +1];
        if(ext.length==0 && defaultExt)
        {
            ext = defaultExt;
        }
    }
    if(ext.length>5 && [ext rangeOfString:@"?"].length>0)
    {
        ext = [ext substringFromIndex:ext.length-3];
    }
    return [ext lowercaseString];
}
+ (NSString *)getMD5FileNameKeepExt:(NSString *)orgPath defaultExt:(NSString *)defaultExt
{
    if(!orgPath||orgPath.length==0) return nil;
    NSString * ext = [self getFileExtensionName:orgPath defaultExt:defaultExt];
    return [NSString stringWithFormat:@"%@.%@",[CommonUtil md5Hash:orgPath],ext];
}
+ (BOOL) checkUrlIsExists:(NSString *)urlString contengLength:(UInt64*)contentLength level:(int *)level
{
    if(!urlString || urlString.length<3) return NO;
    if(level)
    {
        (*level) ++;
        //跳转超过2次，则不算
        if(*level >3) return NO;
    }
    if([self isLocalFile:urlString])
    {
        return [self isFileExistAndNotEmpty:urlString size:contentLength];
    }
    //    urlString = @"http://218.58.206.34/7xjw4n.media2.z0.glb.qiniucdn.com/E2YAEEeGssJ8zk8e11I_P82w1AI=/lhjWlG_lFMcYzrdHl6F2Sm6jcgls?wsiphost=local";
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15];
    request.HTTPMethod = @"HEAD";
    //    [request addValue:@"bytes=0-1" forHTTPHeaderField:@"Range"];
    NSError *error = nil;
    
    NSHTTPURLResponse * response = nil;
#ifndef __OPTIMIZE__
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
#else
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
#endif
    
    if(error)
    {
        NSLog(@"error:%@",error);
        return NO;
    }
    else
    {
        NSLog(@"response:%@",[response.allHeaderFields JSONRepresentationEx]);
        if(response.statusCode==404)
        {
            if(contentLength)
                *contentLength = -1;
            return NO;
        }
        else if(response.statusCode==302)
        {
#ifndef __OPTIMIZE__
            NSLog(@"302:%@",PP_AUTORELEASE([[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]));
#endif
        }
        else
        {
            if(contentLength)
            {
                
                NSString * cr = [response.allHeaderFields objectForKey:@"Content-Range"];
                if(cr){
                    NSString * cl = [cr stringByMatching:@"\\d+$"];
                    if(cl)
                    {
                        *contentLength = (NSInteger)[cl longLongValue];
                    }
                }
                else
                {
                    cr = [response.allHeaderFields objectForKey:@"Content-Length"];
                    if(cr)
                    {
                        *contentLength = (NSInteger)[cr longLongValue];
                    }
                }
                
                if(*contentLength<=0)
                {
                    *contentLength = response.expectedContentLength;
                }
            }
        }
        return YES;
    }
    return NO;
}
+ (void)SaveImageFile:(NSString *)filePath image:(UIImage *)image
{
    //先把图片转成NSData
    NSData *data;
    if (UIImagePNGRepresentation(image) == nil)
    {
        data = UIImageJPEGRepresentation(image, 1.0);
    }
    else
    {
        data = UIImagePNGRepresentation(image);
    }
    //图片保存的路径
    //这里将图片放在沙盒的documents文件夹中
    //    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    
    NSLog(@"filePath>>>>%@",filePath);
    
    
    NSFileManager * fm = [NSFileManager defaultManager];
    
    NSString * path = [filePath stringByDeletingLastPathComponent];
    //    NSLog(@"path:%@",path);
    
    if(![self createFileDirectories:path])
    {
        return ;
    }
    
    NSError * error = nil;
    if([fm fileExistsAtPath:filePath])
    {
        
        [fm removeItemAtPath:filePath error:&error];
        if(error)
        {
            NSLog(@" create file:%@",path);
            NSLog(@" create failure:%@",[error localizedDescription]);
        }
        
    }
    
    [fm createFileAtPath:filePath contents:data attributes:nil];
    
}

#pragma mark - unzio
+ (BOOL)unZipFileFrom:(NSString *)source to:(NSString *)destination
{
    if (nil == source || nil == destination || [source isEqualToString:@""] || [destination isEqualToString:@""]) {
        return NO;
    }
    
    BOOL returnState = NO;
    
    ZipFile *zipFile = [[ZipFile alloc] initWithResourcePath:source];
    returnState = [zipFile UnzipFileTo:destination];
    PP_RELEASE(zipFile);
    //    [zipFile release];
    return returnState;
}

@end

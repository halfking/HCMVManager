//
//  VDCManager(Helper).m
//  maiba
//
//  Created by HUANGXUTAO on 15/9/14.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import "VDCManager(Helper).h"
#import <hccoren/base.h>
#import <hccoren/json.h>
#import <hccoren/Reachability.h>

#import "UDManager(Helper).h"
#import "VDCManager(LocalFiles).h"


@implementation VDCManager(Helper)
//获取已下载的文件大小
- (unsigned long long)fileSizeForPath:(NSString *)path {
    signed long long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager new]; // default is not thread safe
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileSize = [fileDict fileSize];
        }
    }
    return fileSize;
}
- (NSString *)getRemoteFileCacheKey:(NSString *)urlString
{
    if(!urlString) return nil;
    NSString * key = [CommonUtil md5Hash:urlString];
    return key;
}

- (NSString *)getLocalVideoPathForRemoveUrl:(NSString*)remoteUrlString
{
    NSString * key = [self getRemoteFileCacheKey:remoteUrlString];
    NSString * fileName = [NSString stringWithFormat:@"%@.mp4",key];
    return [[UDManager sharedUDManager]localFileFullPath:fileName];
}
- (NSString *)getLocalAudioPathForRemoveUrl:(NSString*)remoteUrlString
{
    NSString * key = [self getRemoteFileCacheKey:remoteUrlString];
    NSString * fileName = [NSString stringWithFormat:@"%@.m4a",key];
    return [[UDManager sharedUDManager]localFileFullPath:fileName];
}

- (NSString *)getLocalWebUrl:(NSString *)key
{
    if(!key) return nil;
    
    NSString * localUrl = [NSString stringWithFormat:@"http://127.0.0.1:%ld/%@.mp4",(long)[DeviceConfig config].LOCALHOST_PORT,key];
    return localUrl;
}
-(NSString * )getKeyFromLocalPath:(NSString *)filePath
{
    return [[filePath lastPathComponent] stringByMatching:@"[a-f0-9]{16,64}"];
}
-(NSString * )getKeyFromLocalUrl:(NSString *)localUrl
{
    return [localUrl stringByMatching:@"[a-f0-9]{16,64}"];
}
- (NSString *)getFilePathForLocalUrl:(NSString *)localUrl
{
    NSString * key = [self getKeyFromLocalUrl:localUrl];
    NSString * fileName = [NSString stringWithFormat:@"%@.mp4",key];
    //for test
    return [[UDManager sharedUDManager]localFileFullPath:fileName];
}
- (NSString *)getTempFilePathForLocalUrl:(NSString *)localUrl
{
    NSString * key = [self getKeyFromLocalUrl:localUrl];
    NSString * fileName = [NSString stringWithFormat:@"%@.mp4",key];
    //for test
    return [[UDManager sharedUDManager]tempFileFullPath:fileName];
}
#pragma mark - contentlength
- (NSInteger) getContentLengthByUrl:(NSString *)urlString
{
    if([Reachability networkAvailable])
    {
        UInt64 length = 0;
        if([HCFileManager checkUrlIsExists:urlString contengLength:&length level:nil])
        {
            return (NSInteger)length;
        }
        else
        {
            return 0;
        }
    }
    else
        return -1;
}
- (UInt64) getContentLengthForlocalUrl:(NSString *)localUrlString
{
    NSString * key = [self getKeyFromLocalUrl:localUrlString];
    VDCItem * item = [self getVDCItem:key];
    if(item) return item.contentLength;
    
    NSString * localFilePath = [self getFilePathForLocalUrl:localUrlString];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:localFilePath])
    {
        return [self fileSizeForPath:localFilePath];
    }
    localFilePath = [self getTempFilePathForLocalUrl:localUrlString];
    if([fileManager fileExistsAtPath:localFilePath])
    {
        return [self fileSizeForPath:localFilePath];
    }
    return 0;
}
- (UInt64) getContentLengthForlocalFilePath:(NSString *)filePath
{
    
    NSString * key = [self getKeyFromLocalUrl:filePath];
    UInt64 contentLength = [self fileSizeForPath:filePath];
    
    for (int i = 0;i<itemList_.count;i++) {
        VDCItem * item = itemList_[i];
        if([item.key isEqualToString:key])
        {
            if(contentLength < item.contentLength)
                contentLength = item.contentLength;
            return contentLength;
        }
    }
    return contentLength;
    //    NSFileManager * fileManager = [NSFileManager defaultManager];
    //    if([fileManager fileExistsAtPath:filePath])
    //    {
    //        return [self fileSizeForPath:filePath];
    //    }
    //    return 0;
}

#pragma mark - download url get set
- (void)removeDownloadUrlFromFile:(NSString *)filePath
{
    if(!filePath || filePath.length==0) return;
    NSString * chkFilePath = [filePath stringByAppendingPathExtension:@"mbd"];
    NSFileManager * fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:chkFilePath])
    {
        NSError * error = nil;
        [fm removeItemAtPath:chkFilePath error:&error];
        if(error)
        {
            NSLog(@"read file:%@ error:%@",chkFilePath,[error localizedDescription]);
        }
    }
    
}
- (VDCItem *)getDownloadItemFromFile:(NSString *)filePath
{
    if(!filePath || filePath.length==0) return nil;
    NSString *chkFilePath = filePath;
    if (![filePath hasSuffix:@".mbd"])
    {
        chkFilePath = [filePath stringByAppendingPathExtension:@"mbd"];
    }
    NSFileManager * fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:chkFilePath])
    {
        NSError * error = nil;
        NSString * fileContent = [NSString stringWithContentsOfFile:chkFilePath encoding:NSUTF8StringEncoding error:&error];
        if(error)
        {
            NSLog(@"read file:%@ error:%@",chkFilePath,[error localizedDescription]);
            fileContent = nil;
        }
        if([fileContent hasPrefix:@"{"]==NO)
        {
            return nil;
        }
        else
        {
            VDCItem * item = [[VDCItem alloc]initWithJSON:fileContent];
            BOOL needParse = NO;
            if(item.tempFileList && item.tempFileList.count>0)
            {
                id firstItem = item.tempFileList[0];
                if([firstItem isKindOfClass:[VDCTempFileInfo class]])
                {
                    
                }
                else if([firstItem isKindOfClass:[NSDictionary class]])
                {
                    needParse = YES;
                }
                else //类型不对，不如数据不要
                {
                    [item.tempFileList removeAllObjects];
                }
            }
            if(needParse)
            {
                NSMutableArray * result = [NSMutableArray new];
                for(int i = 0;i<item.tempFileList.count;i++)
                {
                    VDCTempFileInfo * fi = [[VDCTempFileInfo alloc]initWithDictionary:item.tempFileList[i]];
                    fi.parentItem = item;
                    fi.isDownloading = NO;
                    [result addObject:fi];
                }
                item.tempFileList = result;
                PP_RELEASE(result);
            }
            
//            item.tempFilePath = [self checkAppliationPath:item.tempFilePath];
//            item.localFilePath = [self checkAppliationPath:item.localFilePath];
//            item.AudioPath = [self checkAppliationPath:item.AudioPath];
            item.isDownloading = NO;
            item.needStop = NO;
            return item;
        }
    }
    return nil;
}
- (NSString *)checkAppliationPath:(NSString *)path
{
    if(!path ||path.length <10) return path;
    //check files
    NSString * regex = @"/Application/[^/]+|/Applications/[^/]+";
    NSString * localApplication = [[HCFileManager manager] getApplicationPath];
    if(localApplication)
    {
        return  [path stringByReplacingOccurrencesOfRegex:regex withString:localApplication];
    }
    return path;
}
- (BOOL)removeDownloadItemFile:(VDCItem *)item tempPath:(NSString *)tempPath
{
    if(!tempPath || tempPath.length==0 || !item) return NO;
    NSError * error = nil;
    NSString * chkFilePath = [tempPath stringByAppendingPathExtension:@"mbd"];
    NSFileManager * fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:chkFilePath])
    {
        
        [fm removeItemAtPath:chkFilePath error:&error];
        if(error)
        {
            NSLog(@"remove file:%@ error:%@",chkFilePath,[error localizedDescription]);
            return NO;
        }
    }
    return YES;
}
- (void)rememberDownloadUrl:(VDCItem *)item tempPath:(NSString *)tempPath
{
    if(!tempPath || tempPath.length==0 || !item) return ;
    if (!item.title || item.title.length == 0) {
        NSLog(@"tempfile(%ld)里的mbd文件没有title",item.SampleID);
    }else
    {
        NSLog(@"mbd文件(%ld)的title %@",item.SampleID,item.title);
    }
    NSError * error = nil;
    NSString * chkFilePath = [tempPath stringByAppendingPathExtension:@"mbd"];
    NSFileManager * fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:chkFilePath])
    {
        
        [fm removeItemAtPath:chkFilePath error:&error];
        if(error)
        {
            NSLog(@"remove file:%@ error:%@",chkFilePath,[error localizedDescription]);
        }
    }
    item.lastDownloadTime = [CommonUtil getDateText:[NSDate date] format:@"yyyy-MM-dd HH:mm:ss"];
    error = nil;
    NSString * content = [item toJson];
    if(![content writeToFile:chkFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error])
    {
        if(error)
        {
            NSLog(@"read file:%@ error:%@",chkFilePath,[error localizedDescription]);
        }
    }
}
- (void)rememberContentLength:(UInt64)length tempPath:(NSString *)tempPath
{
    if(!tempPath || tempPath.length==0) return ;
    NSError * error = nil;
    NSString * chkFilePath = [tempPath stringByAppendingPathExtension:@"clen"];
    NSFileManager * fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:chkFilePath])
    {
        
        [fm removeItemAtPath:chkFilePath error:&error];
        if(error)
        {
            NSLog(@"write file:%@ error:%@",chkFilePath,[error localizedDescription]);
        }
    }
    [[NSString stringWithFormat:@"%llu",length] writeToFile:chkFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    {
        if(error)
        {
            NSLog(@"write file:%@ error:%@",chkFilePath,[error localizedDescription]);
        }
    }
}
- (UInt64)getContentLengthByFile:(NSString *)filePath
{
    if(!filePath || filePath.length==0) return 0;
    NSString * chkFilePath = [filePath stringByAppendingPathExtension:@"clen"];
    NSFileManager * fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:chkFilePath])
    {
        NSError * error = nil;
        NSString * fileContent = [NSString stringWithContentsOfFile:chkFilePath encoding:NSUTF8StringEncoding error:&error];
        if(error)
        {
            NSLog(@"read file:%@ error:%@",chkFilePath,[error localizedDescription]);
            fileContent = nil;
        }
        return (UInt64)[fileContent longLongValue];
    }
    return 0;
}

#pragma mark - remove clear....
//清除与URL相关的请求及文件数据
- (BOOL) removeUrlCahche:(NSString *)urlString
{
    NSString * key = [self getRemoteFileCacheKey:urlString];
    {
        NSString * filePath = [self getTempFilePathForLocalUrl:[self getLocalWebUrl:key]];
        if([[UDManager sharedUDManager]existFileAtPath:filePath])
        {
            [[HCFileManager manager]removeFileAtPath:filePath];
        }
        [self removeDownloadUrlFromFile:filePath];
        [self removeTempFiles:filePath
                contentlength:0
                  checkLength:NO
                    matchSize:0];
    }
    {
        NSString * filePath = [self getFilePathForLocalUrl:[self getLocalWebUrl:key]];
        if([[UDManager sharedUDManager]existFileAtPath:filePath])
        {
            [self removeDownloadUrlFromFile:filePath];
            
            return [[HCFileManager manager]removeFileAtPath:filePath];
        }
    }
    return NO;
}
- (void)clear
{
    NSMutableArray * removeList = [NSMutableArray new];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    for (int i = 0;i<itemList_.count;i++) {
        VDCItem * item = itemList_[i];
        if([fileManager fileExistsAtPath:item.localFilePath])
        {
            [removeList addObject:item];
        }
    }
    [itemList_ removeObjectsInArray:removeList];
    PP_RELEASE(removeList);
}
#pragma mark - create temp files
- (VDCTempFileInfo *)addNewTempFileAtLast:(VDCItem *)item
{
    VDCTempFileInfo * currentFi = nil;
    UInt64 offsetx = 0;
    for (int i = 0;i<item.tempFileList.count; i++) {
        VDCTempFileInfo * fi = item.tempFileList[i];
        offsetx = MAX(fi.offset + fi.lengthFull,offsetx);
    }
    currentFi = [self createTempFileByOffset:offsetx item:item];
    if(currentFi)
    {
        [item.tempFileList addObject:currentFi];
    }
    return currentFi;
}
- (VDCTempFileInfo *)createTempFileByOffset:(UInt64)offset item:(VDCItem *)item
{
    VDCTempFileInfo *    fi = [[VDCTempFileInfo alloc]init];
    
    fi.offset = offset;
    fi.length = 0;
    fi.lengthFull = item.contentLength>0?MIN(item.contentLength - offset,DEFAULT_PKSIZE):DEFAULT_PKSIZE;
    //    fi.filePath = [NSString stringWithFormat:@"%@_%llu-%llu",item.tempFilePath,fi.offset,fi.lengthFull];
    //    fi.fileName = [fi.filePath lastPathComponent];
    fi.fileName = [NSString stringWithFormat:@"%@_%llu-%llu",[item.tempFilePath lastPathComponent],fi.offset,fi.lengthFull];
    fi.parentItem = item;
    if(fi.lengthFull>0)
    {
        return PP_AUTORELEASE(fi);
    }
    else
    {
        PP_RELEASE(fi);
        return nil;
    }
}
- (VDCTempFileInfo *)addTempFileIntoList:(VDCItem *)item file:(VDCTempFileInfo *)file
{
    int index = 0;
    BOOL isFind = NO;
    if(!item.tempFileList)
    {
        item.tempFileList = [NSMutableArray new];
    }
    VDCTempFileInfo * itemInserted = file;
    for (int i = 0;i<item.tempFileList.count; i++) {
        VDCTempFileInfo * fi = item.tempFileList[i];
        if(fi.offset > file.offset)
        {
            break;
        }
        else if(fi.offset == file.offset)
        {
            isFind = YES;
            itemInserted = fi;
            break;
        }
        index ++;
    }
    if(isFind) return itemInserted;
    if(index < item.tempFileList.count)
    {
        [item.tempFileList insertObject:file atIndex:index];
    }
    else
    {
        [item.tempFileList addObject:file];
    }
    return itemInserted;
}
#pragma mark - helper 3
//获取当前下载完的量，值可能为-1，0，或大于0的值。-1表示完整
- (CGFloat)   getSecondsDownloaded:(VDCItem *)item  totalSeconds:(CGFloat)totalSeconds
{
    if(item.downloadBytes >= item.contentLength) return -1;
    
    if(totalSeconds>0)
    {
        if(item.contentLength>0)
        {
            return totalSeconds * item.downloadBytes/item.contentLength;
        }
    }
    
    return -1;
}

@end

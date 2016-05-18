//
//  VDCManager(LocalFiles).m
//  maiba
//
//  Created by HUANGXUTAO on 15/10/10.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import "VDCManager(LocalFiles).h"
#import "VDCManager(Helper).h"
#import "UDManager.h"
#import "UDManager(Helper).h"
#import <hccoren/base.h>
#import <hccoren/RegexKitLite.h>

#import "VDCManager.h"

@implementation VDCManager(LocalFiles)
- (void)checkItemFile:(VDCItem *)item removePartFile:(BOOL)removePartFile
{
    [self setPostMsg:@"正在检查本地缓存文件" bytesRead:-2];
    
    //如果文件已经下载完成，并合并成文件，则移除临时文件，并且不需要下载
    UInt64  size = 0;
    
    //    if(item.remoteUrl && item.remoteUrl.length>0)
    //    {
    //        [self rememberDownloadUrl:item tempPath:item.tempFilePath];
    //    }
    if(!item.remoteUrl || item.remoteUrl.length==0)
    {
        VDCItem * orgItem = [self getDownloadItemFromFile:item.tempFilePath];
        if(orgItem && orgItem.remoteUrl && orgItem.remoteUrl.length>0 && [HCFileManager isLocalFile:orgItem.remoteUrl]==NO)
            item.remoteUrl = orgItem.remoteUrl;
    }
    if(item.contentLength <=DEFAULT_PKSIZE * 2)
    {
        item.contentLength = [self getContentLengthByFile:item.tempFilePath];
        
        if(item.contentLength <=0 && item.remoteUrl && item.remoteUrl.length>0)
        {
            if([HCFileManager isLocalFile:item.remoteUrl])
            {
                UInt64 fileSize = 0;
                if([HCFileManager isFileExistAndNotEmpty:item.remoteUrl size:&fileSize])
                {
                    item.contentLength = fileSize;
                }
                else
                {
                    item.contentLength = 0;
                }
            }
            else
            {
                NSInteger len = [self getContentLengthByUrl:item.remoteUrl];
                if(len>=0)
                    item.contentLength = (UInt64)len;
                else
                {
                    NSLog(@"contentlength error:%ld",(long)len);
                }
            }
        }
    }
    if(item.AudioUrl && item.AudioUrl.length>2)
    {
        [self checkAudioPath:item];
    }
    NSString * newPath = nil;
    if([[UDManager sharedUDManager] isFileExistAndNotEmpty:item.localFilePath size:&size pathAlter:&newPath ])
    {
        if(newPath)
        {
            item.localFileName = [[HCFileManager manager]getFileName:newPath];
//            item.localFilePath = newPath;
        }
        item.downloadBytes = size;
        if(item.contentLength <=0 && item.downloadBytes>0)
        {
            item.contentLength = item.downloadBytes;
        }
        if(item.contentLength <= item.downloadBytes)
        {
            [self rememberDownloadUrl:item tempPath:item.tempFilePath];
            item.isCheckedFiles = YES;
            return;
        }
        else
        {
            NSLog(@"长度不对(%llu)<-->(%llu)",item.contentLength,item.downloadBytes);
        }
    }
    else
    {
        if (removePartFile) {
            //移除本地没有下完的临时文件，检查标准为：文件大小小于标准包大小的
            NSMutableArray * removeList = [self removeTempFiles:item.tempFilePath
                                                  contentlength:item.contentLength
                                                    checkLength:YES
                                                      matchSize:DEFAULT_PKSIZE];
            if(removeList && item.tempFileList)
            {
                //sort removelist
                {
                    NSComparator listCompare = ^NSComparisonResult(id obj1,id obj2)
                    {
                        NSString * item1 = (NSString*)obj1;
                        NSString * item2 = (NSString *)obj2;
                        return [item1 compare:item2];
                    };
                    [removeList sortUsingComparator:listCompare];
                }
                int lastJ = 0;
                int itemCount = 0;
                NSMutableArray * duplicateItems = [NSMutableArray new];
                for (int i = 0; i<removeList.count; i++) {
                    itemCount = 0;
                    for (int j = lastJ; j<item.tempFileList.count; j ++) {
                        VDCTempFileInfo * fi = item.tempFileList[j];
                        if([fi.filePath isEqualToString:removeList[i]])
                        {
                            item.downloadBytes -= fi.length;
                            fi.length = 0;
                            
                            [fi cancelOperation];
                            
                            lastJ = j+1;
                            if(itemCount >0)
                            {
                                [duplicateItems addObject:fi];
                            }
                            itemCount ++;
                        }
                    }
                }
                [item.tempFileList removeObjectsInArray:duplicateItems];
                PP_RELEASE(duplicateItems);
            }
        }
        //check file,并创建所有的文件数据....
        {
            item.downloadBytes  =  [self getTemFileList:item justCheckDownloading:NO];
        }
    }
    
    [self rememberDownloadUrl:item tempPath:item.tempFilePath];
    
    item.isCheckedFiles = YES;
}

#pragma mark - gettemplist combinate files
//用于每个文件下载完成后的检查，看是否已经将全部文件下载完成了
//1、如果总下载长度等于ConentLength，则完成
//2、前题是没有文件还在下载
- (UInt64)getTemFileList:(VDCItem *)item justCheckDownloading:(BOOL)justCheckDownloading
{
    UInt64 totalContentLength = 0;
    
    if(item.contentLength >0)
    {
        if(!item.tempFileList)
            item.tempFileList = PP_AUTORELEASE([NSMutableArray new]);
        else
            [self sortFiles:item.tempFileList];
        
        //增加没有放进去的文件
        VDCTempFileInfo * lastFile = item.tempFileList.count>0?[item.tempFileList lastObject]:nil;
        
        UInt64 offset = lastFile?lastFile.offset + lastFile.lengthFull:0;
        
        while (offset < item.contentLength) {
            VDCTempFileInfo * fi = [self createTempFileByOffset:offset item:item];
            [item.tempFileList addObject:fi];
            offset += fi.lengthFull;
        }
        //移除原来放多的
        for (int index = (int)item.tempFileList.count-1;index>=0;index --) {
            VDCTempFileInfo * fi = [item.tempFileList objectAtIndex:index];
            if(fi.offset > item.contentLength)
            {
                [item.tempFileList removeObject:fi];
            }
            else //因为有排序，所以直接可以退出
            {
                break;
            }
        }
        
    }
    else //如果仍然无法取到长度，则默认放4个长度
    {
        UInt64 offset = 0;
        while (offset <= prevCacheSize_) {
            VDCTempFileInfo * fi = [self createTempFileByOffset:offset item:item];
            [item.tempFileList addObject:fi];
            offset += fi.lengthFull;
        }
    }
    
    totalContentLength = [self checkTempitemLengthByFile:item.tempFilePath tempList:item.tempFileList];// justCheckDownloading:justCheckDownloading];
    
    if(totalContentLength >= item.contentLength && item.contentLength>0 && [self isDataReady:item])
    {
        if([self combinateTempFiles:item tempFilePath:item.tempFilePath targetFilePath:item.localFilePath])
        {
            //            [self setPostMsg:@"MV下载完成" bytesRead:-1];
            //            dwnMsgTimer_.fireDate = [NSDate distantFuture];
            //            [self setPostMsg:@"MV下载完成" bytesRead:-1];
            //            [self postCaching:nil];
        }
        else
        {
            totalContentLength = item.contentLength - DEFAULT_PKSIZE;
        }
    }
    else
    {
    }
    return totalContentLength;
}
//static bool makeError = NO;
- (BOOL)combinateTempFiles:(VDCItem*)item tempFilePath:(NSString *)tempFilePath targetFilePath:(NSString *)targetFilePath
{
    NSError * errorTemp = nil;
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSLog(@"file %@ downloaded moveto %@",[tempFilePath lastPathComponent],targetFilePath);
    if([fileManager fileExistsAtPath:targetFilePath])
    {
        //        [fileManager removeItemAtPath:targetFilePath error:&errorTemp];
        //        if(errorTemp)
        //        {
        //            NSLog(@"remove file %@ failure:%@",targetFilePath,[errorTemp localizedDescription]);
        //            return NO;
        //        }
        return YES;
    }
    if(!item.tempFileList||item.tempFileList.count==0)
    {
        [fileManager copyItemAtPath:tempFilePath toPath:targetFilePath error:&errorTemp];
        if(errorTemp)
        {
            NSLog(@"copy file:%@ to %@ error:%@",tempFilePath,targetFilePath,[errorTemp localizedDescription]);
        }
    }
    else
    {
        [fileManager createFileAtPath:targetFilePath contents:nil attributes:nil];
        
        NSFileHandle * handle = [NSFileHandle fileHandleForWritingAtPath:targetFilePath];
        if(handle)
        {
            for (int i = 0; i<item.tempFileList.count; i++) {
                VDCTempFileInfo * fi = item.tempFileList[i];
                //                fi.length = 0;
                //            }
                //            for (VDCTempFileInfo * fi in item.tempFileList) {
                //#ifndef __OPTIMIZE__
                //#warning 测试失败的情况，在文件中部写入错误的数据
                //                if(i==20 && !makeError)
                //                {
                //                    makeError = YES;
                //                    continue;
                //                }
                //#endif
                if([fi.filePath isEqual:item.tempFilePath]) continue;
                
                NSData * data = [NSData dataWithContentsOfFile:fi.filePath];
                if(data && data.length>0)
                {
                    //            [data writeToFile:targetFilePath options:NSDataWritingAtomic error:&errorTemp];
                    [handle writeData:data];
                }
                else
                {
                    [handle closeFile];
                    PP_RELEASE(handle);
                    [fileManager removeItemAtPath:targetFilePath error:&errorTemp];
                    if(errorTemp)
                    {
                        NSLog(@"remove file:%@ for exists empty tempfile. error:%@",targetFilePath,[errorTemp localizedDescription]);
                    }
                    fi.length = 0;
                    [fileManager removeItemAtPath:fi.filePath error:&errorTemp];
                    if(errorTemp)
                    {
                        NSLog(@"remove file:%@ for exists empty tempfile. error:%@",targetFilePath,[errorTemp localizedDescription]);
                    }
                    return NO;
                }
            }
            [handle closeFile];
            PP_RELEASE(handle);
        }
        else
        {
            NSLog(@"write file:%@ to %@ error:%@",@"tempfilelist",targetFilePath,[errorTemp localizedDescription]);
        }
        //#ifndef __OPTIMIZE__
        //#warning 测试失败的情况，在文件中部写入错误的数据
        //        handle = [NSFileHandle fileHandleForWritingAtPath:targetFilePath];
        //        if(handle)
        //        {
        //            [handle seekToFileOffset:1024*2 + 456];
        //            NSString * str = @"sdafasdfasfsadfakjfdlafdjalkdflkafakjfdlafdjalkdflkfakjfdlafdjalkdflkfakjfdlafdjalkdflkfakjfdlafdjalkdflkfakjfdlafdjalkdflkfakjfdlafdjalkdflkfakjfdlafdjalkdflkfakjfdlafdjalkdflkfakjfdlafdjalkdflkfakjfdlafdjalkdflkfakjfdlafdjalkdflkfakjfdlafdjalkdflkfakjfdlafdjalkdflkfakjfdlafdjalkdflkfakjfdlafdjalkdflkfakjfdlafdjalkdflkfakjfdlafdjalkdflksjdlsldfjka";
        //
        //            [handle writeData:[str dataUsingEncoding:NSUTF8StringEncoding]];
        //
        //            [handle closeFile];
        //            PP_RELEASE(handle);
        //        }
        //#endif
    }
    //check Hash
    {
        
    }
    
    return YES;
}

#pragma mark - temp files
- (UInt64)checkTempitemLengthByFile:(NSString *)path tempList:(NSMutableArray *)tempList // justCheckDownloading:(BOOL)justCheckDownloading
{
    NSFileManager* fm = [NSFileManager defaultManager];
    UInt64 totalLength = 0;
    
    if(!tempList)
    {
        NSLog(@"No list for temp files....");
        return 0;
    }
    
    for (int i = 0;i<tempList.count; i++) {
        VDCTempFileInfo * fi = tempList[i];
        if([fi isDownloadWithOperation])//正在下载可能不准
        {
            totalLength += fi.length;
        }
        else
        {
            if([fm fileExistsAtPath:fi.filePath])
            {
                NSError *error = nil;
                NSDictionary *fileDict = [fm attributesOfItemAtPath:fi.filePath error:&error];
                if (!error && fileDict) {
                    fi.length = [fileDict fileSize];
                }
                else
                {
                    NSLog(@"get file %@ size error:%@",fi.fileName,error);
                    fi.length = 0;
                }
                //如果文件超长，截短
                if(fi.length > fi.lengthFull && fi.lengthFull>0)
                {
                    NSFileHandle * handler = [NSFileHandle fileHandleForWritingAtPath:fi.filePath];
                    [handler truncateFileAtOffset:fi.length];
                    [handler closeFile];
                }
                //                else if(fi.length==0)
                //                {
                //                    [fm removeItemAtPath:fi.filePath error:nil];
                //                }
            }
            else
            {
                fi.length = 0;
            }
        }
        totalLength += fi.length;
    }
    return totalLength;
}
- (void)sortFiles:(NSMutableArray *)array
{
    NSComparator listCompare = ^NSComparisonResult(id obj1,id obj2)
    {
        VDCTempFileInfo * item1 = (VDCTempFileInfo*)obj1;
        VDCTempFileInfo * item2 = (VDCTempFileInfo *)obj2;
        if(item1.offset < item2.offset)
        {
            return NSOrderedAscending;
        }
        else if(item1.offset == item2.offset)
        {
            return NSOrderedSame;
        }
        else
        {
            return NSOrderedDescending;
        }
    };
    [array sortUsingComparator:listCompare];
}
- (void)getTemplateFiles:(VDCItem *)item
{
    NSString * regEx = nil;
    regEx = [NSString stringWithFormat:@"%@_(\\d+)\\-(\\d+)$",[item.tempFilePath lastPathComponent]];
    
    NSString * dir = [[UDManager sharedUDManager] tempFileFullPath:nil];
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:dir]) return;
    
    NSMutableArray * fileList = [NSMutableArray new];
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:dir] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        if([fileName isMatchedByRegex:regEx])
        {
            NSString* fileAbsolutePath = [dir stringByAppendingPathComponent:fileName];
            
            [fileList addObject:fileAbsolutePath];
            
        }
    }
    NSMutableArray * removeList = [NSMutableArray new];
    if(!item.tempFileList) item.tempFileList = PP_AUTORELEASE([NSMutableArray new]);
    for (int i = 0; i<item.tempFileList.count; i++) {
        VDCTempFileInfo * fi = item.tempFileList[i];
        BOOL isFind = NO;
        
        for (NSString * filePath in fileList) {
            if([filePath isEqualToString:fi.filePath])
            {
                isFind = YES;
                [removeList addObject:filePath];
                break;
            }
        }
    }
    if(removeList && removeList.count>0)
    {
        [fileList removeObjectsInArray:removeList];
    }
    
    for (NSString * filePath in fileList) {
        VDCTempFileInfo * fi = [self getTempDataFromFile:filePath checkSize:YES];
        //        @synchronized(self) {
        [item.tempFileList addObject:fi];
        //        }
    }
    
    PP_RELEASE(removeList);
    PP_RELEASE(fileList);
    
    [self sortFiles:item.tempFileList];
}
- (VDCTempFileInfo *)getTempDataFromFile:(NSString *)filePath checkSize:(BOOL)checkSize
{
    NSString * regEx = nil;
    regEx = [NSString stringWithFormat:@"%@_(\\d+)\\-(\\d+)$",@"(\\.mp4|\\.m4a)"];
    NSArray * groups = [filePath arrayOfCaptureComponentsMatchedByRegex:regEx];
    NSString * offsetStr = groups[0][1];
    NSString * lengthStr = groups[0][2];
    UInt64 offset = [offsetStr longLongValue];
    VDCTempFileInfo * fi = [[VDCTempFileInfo alloc]init];
    fi.offset = offset;
    //    fi.filePath = filePath;
    fi.fileName = [filePath lastPathComponent];
    fi.lengthFull = [lengthStr longLongValue];
    fi.length = 0;
    if(checkSize)
    {
        NSFileManager * fm = [NSFileManager defaultManager];
        NSError *error = nil;
        NSDictionary *fileDict = [fm attributesOfItemAtPath:fi.filePath error:&error];
        if (!error && fileDict) {
            fi.length = [fileDict fileSize];
        }
    }
    return PP_AUTORELEASE(fi);
}
//暂进不考虑最后一个包不是标准长度的情况
-(NSMutableArray *)removeTempFiles:(NSString *)filePath contentlength:(UInt64)contentLength
                       checkLength:(BOOL)checkLength matchSize:(UInt64)fileSize
{
    if(!filePath) return nil;
    
    [NSThread sleepForTimeInterval:0.1];//等待时间，待所有文件相关写入
    
    NSString * regEx = nil;
    regEx = [NSString stringWithFormat:@"%@_(\\d+)\\-(\\d+)$",[filePath lastPathComponent]];
    
    NSString * dir = [[UDManager sharedUDManager] tempFileFullPath:nil];
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:dir]) return nil;
    
    NSMutableArray * fileList = [NSMutableArray new];
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:dir] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        if([fileName isMatchedByRegex:regEx])
        {
            NSString* fileAbsolutePath = [dir stringByAppendingPathComponent:fileName];
            
            [fileList addObject:fileAbsolutePath];
            
        }
    }
    NSMutableArray * array = [NSMutableArray new];
    NSError * error = nil;
    for (NSString * fullPath in fileList) {
        BOOL needRemove = YES;
        if(checkLength && fileSize>0)
        {
            UInt64 currentSize = [self fileSizeForPath:fullPath];
            //有可能刚写完，但系统还读不到长度
            if(currentSize == fileSize||currentSize==0)
            {
                needRemove = NO;
            }
            else if(contentLength>0)
            {
                NSLog(@"file size:%llu real size:%llu",fileSize,currentSize);
                //最后一个文件
                VDCTempFileInfo * fi = [self getTempDataFromFile:fullPath checkSize:YES];
                if(fi.offset + fi.length >=contentLength-1)
                {
                    needRemove = NO;
                }
            }
        }
        if(needRemove)
        {
            [manager removeItemAtPath:fullPath error:&error];
            if(error)
            {
                NSLog(@"delete file:%@ failure:%@",fullPath,[error localizedDescription]);
            }
            else
            {
                [array addObject:fullPath];
                NSLog(@"delete file:%@ OK",[fullPath lastPathComponent]);
            }
        }
        
    }
    if([manager fileExistsAtPath:filePath])
    {
        [manager removeItemAtPath:filePath error:&error];
        if(error)
        {
            NSLog(@"delete file:%@ failure:%@",filePath,[error localizedDescription]);
        }
        else
        {
            [array addObject:filePath];
            NSLog(@"delete file:%@ OK",[filePath lastPathComponent]);
        }
    }
    
    PP_RELEASE(fileList);
    return PP_AUTORELEASE(array);
}

- (VDCTempFileInfo *)getNextTempfile:(UInt64)offset item:(VDCItem *)item
{
    if(!item) return nil;
    @synchronized(item) {
        VDCTempFileInfo * target = nil;
        for (int i = 0; i< (int)item.tempFileList.count; i++) {
            VDCTempFileInfo * fi = item.tempFileList[i];
            if(fi.offset >= offset)
            {
                target = fi;
                break;
            }
        }
        return target;
    }
}
#pragma mark - get vdcitems via files

- (NSMutableArray *) getVDCItemsFromDir
{
    NSString * regEx = nil;
    regEx = @".*\\.mp4\\.mbd$|.*\\.m4a\\.mbd$";
    
    NSString * dir = [[UDManager sharedUDManager] tempFileFullPath:nil];
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:dir]) return nil;
    
    NSMutableArray * fileList = [NSMutableArray new];
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:dir] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        if([fileName isMatchedByRegex:regEx])
        {
            NSString* fileAbsolutePath = [dir stringByAppendingPathComponent:fileName];
            
            [fileList addObject:fileAbsolutePath];
            
        }
    }
    NSMutableArray * orgItemList = [NSMutableArray new];
    for (NSString * filePath in fileList) {
        VDCItem * item = nil;
        NSString *key = [self getKeyFromLocalPath:filePath];
        item = [self getVDCItem:key];
        if (!item) {
            item = [self getDownloadItemFromFile:filePath];
        }
        if(!item)
        {
            [manager removeItemAtPath:filePath error:nil];
        }
        else
        {
            [self checkItemFile:item removePartFile:NO];
            CGFloat size = [self getItemCacheSize:item];
            // 删除无效的mbd文件
            if (!item.title || size < 0.1) {
                [manager removeItemAtPath:filePath error:nil];
            } else {
                [orgItemList addObject:item];
            }
        }
        [self addVDCItemToList:item];
    }
    PP_RELEASE(fileList);
    
    return orgItemList;
}
- (void) resetLastDownloadTime:(VDCItem *)item
{
    item.lastDownloadTime =  [CommonUtil getDateText:[NSDate date] format:@"yyyy-MM-dd HH:mm:ss"];
}
- (void)removeVDCItemsExpired
{
    NSString * expirtDate = [CommonUtil getDateText:[NSDate dateWithTimeIntervalSinceNow:0 - 12*60*60] format:@"yyyy-MM-dd HH:mm:ss"];
    NSString * expirtDateForSample = [CommonUtil getDateText:[NSDate dateWithTimeIntervalSinceNow:0 - 24*60*60] format:@"yyyy-MM-dd HH:mm:ss"];
    NSMutableArray * removeList = [NSMutableArray new];
    for (int i = (int)itemList_.count-1; i>=0; i--) {
        VDCItem * item = itemList_[i];
        if(item.lastDownloadTime && item.lastDownloadTime.length>0 && [item.lastDownloadTime compare:expirtDate]==NSOrderedAscending)
        {
            [removeList addObject:item];
        }
    }
    for (VDCItem * item in removeList) {
        if(item.MTVID >0)
        {
            [self removeItem:item withTempFiles:YES includeLocal:YES];
            [self removeDownloadItemFile:item tempPath:item.tempFilePath];
        }
        else if([item.lastDownloadTime compare:expirtDateForSample]==NSOrderedAscending)
        {
            [self removeItem:item withTempFiles:YES includeLocal:YES];
            [self removeDownloadItemFile:item tempPath:item.tempFilePath];
        }
        [itemList_ removeObject:item];
    }
}

- (CGFloat)getItemCacheSize:(VDCItem *)item
{
    if (!item.isCheckedFiles) {
        [[VDCManager shareObject] checkItemFile:item removePartFile:NO];
    }
    long long size = 0;
    if (item.localFileName && item.localFileName.length>0) {
//        item.localFilePath = [[UDManager sharedUDManager] checkPathForApplicationPathChanged:item.localFilePath mtvID:0 filetype:1 isExists:nil];
        long long tempSize = [[UDManager sharedUDManager] fileSizeAtPath:item.localFilePath];
        size += tempSize;
    }
    if (item.tempFileName && item.tempFileName.length>0) {
//        item.tempFilePath = [[UDManager sharedUDManager] checkPathForApplicationPathChanged:item.tempFilePath mtvID:0 filetype:1 isExists:nil];
        long long tempSize = [[UDManager sharedUDManager] fileSizeAtPath:item.tempFilePath];
        size += tempSize;
    }
    if(item.tempFileList && item.tempFileList.count>0)
    {
        BOOL needParse = NO;
        
        id firstItem = item.tempFileList[0];
        if([firstItem isKindOfClass:[VDCTempFileInfo class]])
        {
            
        } else if([firstItem isKindOfClass:[NSDictionary class]])
        {
            needParse = YES;
        } else { //类型不对，不如数据不要
            [item.tempFileList removeAllObjects];
        }
        
        if(needParse)
        {
            NSMutableArray * result = [NSMutableArray new];
            for(int i = 0;i<item.tempFileList.count;i++)
            {
                VDCTempFileInfo * fi = [[VDCTempFileInfo alloc]initWithDictionary:item.tempFileList[i]];
                fi.parentItem = item;
                [result addObject:fi];
            }
            item.tempFileList = result;
            PP_RELEASE(result);
        }
        
        for (VDCTempFileInfo *info in item.tempFileList) {
            long long tempSize = 0;
            if (info.length > 0) {
                tempSize = info.length;
            } else {
                tempSize = [[UDManager sharedUDManager] fileSizeAtPath:info.filePath];
            }
            size += tempSize;
        }
    }
    if (item.AudioFileName && item.AudioFileName.length>2) {
//        item.AudioPath = [[UDManager sharedUDManager] checkPathForApplicationPathChanged:item.AudioPath mtvID:0 filetype:1 isExists:nil];
        long long tempSize = [[UDManager sharedUDManager] fileSizeAtPath:item.AudioPath];
        size += tempSize;
    }
    
    CGFloat totalSize = size/(1024.0*1024.0);
    return totalSize;
}

// 删除没用的mbd文件 mbd文件太多 会导致查找缓存时间太长
- (void) removeMbdFileNoNeed
{
    NSString * regEx = nil;
    regEx = @".*\\.mp4\\.mbd$|.*\\.m4a\\.mbd$";
    
    NSString * dir = [[UDManager sharedUDManager] tempFileFullPath:nil];
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:dir]) return;
    
    NSMutableArray * fileList = [NSMutableArray new];
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:dir] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        if([fileName isMatchedByRegex:regEx])
        {
            NSString* fileAbsolutePath = [dir stringByAppendingPathComponent:fileName];
            
            [fileList addObject:fileAbsolutePath];
            
        }
    }
    for (NSString * filePath in fileList) {
        VDCItem * item = [self getDownloadItemFromFile:filePath];
        if(!item || !item.title || [self getItemCacheSize:item] < 0.1)
        {
            [manager removeItemAtPath:filePath error:nil];
        }
    }
    PP_RELEASE(fileList);
}
- (void)setItemsRemovedFlag
{
    for (NSInteger i = itemList_.count-1;i>=0;i--) {
        VDCItem * item = itemList_[i];
        item.isCheckedFiles = NO;
        @synchronized(item) {
            for(int i = (int)item.tempFileList.count-1;i>=0;i--)
            {
                VDCTempFileInfo * fi = item.tempFileList[i];
                fi.length = 0;
            }
            [self rememberDownloadUrl:item tempPath:item.tempFilePath];
        }
    }
    NSLog(@"remove all items cached.");
}
@end

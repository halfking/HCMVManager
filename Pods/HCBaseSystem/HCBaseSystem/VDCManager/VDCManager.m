//
//  VDCManager.m
//  maiba
//
//  Created by HUANGXUTAO on 15/9/14.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import "VDCManager.h"
#import <hccoren/base.h>
#import <hccoren/json.h>
#import "VDCManager(Helper).h"
#import "UDManager.h"
#import "UDManager(Helper).h"
#import "HttpVideoFileResponse.h"
#import "VDCTempFileInfo.h"
#import "HXNetwork.h"
#import "VDCManager(LocalFiles).h"
//#import "MTVUploader.h"
#import "VDCItem.h"
#import "VDCTempFileInfo.h"
#import "config.h"
#import "AFNetworking.h"

@class AFHTTPRequestOperation;

typedef void(^requestCompletedBlock) (AFHTTPRequestOperation *operation, id responseObject);
typedef void(^requestCompletedfailure) (AFHTTPRequestOperation *operation, NSError *error);
typedef void(^requestProgressBlock) (NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead);
#ifndef __OPTIMIZE__
//static NSURLRequest * AFNetworkRequestFromNotification(NSNotification *notification)
//{
//    if ([[notification object] isKindOfClass:[AFURLConnectionOperation class]])
//    {
//        return [(AFURLConnectionOperation *)[notification object] request];
//    }
//    return nil;
//}
static long mainQueueItemCount = 0;
static long childQueueItemCount = 0;
#endif

@implementation VDCManager
{
    dispatch_queue_t    downloadQueue_;
    dispatch_queue_t    downloadItemQueue_;
    
    DeviceConfig * config_;
    
    NSMutableArray * proirDownloadList_;
}
+(id)Instance
{
    static dispatch_once_t pred = 0;
    static VDCManager *intanceVDC_ = nil;
    dispatch_once(&pred,^
                  {
                      intanceVDC_ = [[VDCManager alloc] init];
                  });
    return intanceVDC_;
}
+(VDCManager *)shareObject
{
    return (VDCManager *)[self Instance];
}
- (instancetype)init
{
    if(self = [super init])
    {
        config_ = [DeviceConfig config];
        
        itemList_ = [NSMutableArray new];
        downloadList_ = [NSMutableArray new];
        proirDownloadList_ = [NSMutableArray new];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(willDownload:) name:@"DOWNLOADDO" object:nil];
        
        downloadQueue_  = dispatch_queue_create("com.seenvoice.downloadqueue", DISPATCH_QUEUE_SERIAL);
        downloadItemQueue_  = dispatch_queue_create("com.seenvoice.downloaditemqueue", DISPATCH_QUEUE_SERIAL);
        //        downloadItemQueue_  = dispatch_queue_create("downloaditemqueue", DISPATCH_QUEUE_CONCURRENT);
        
        dwnMsgTimer_  = PP_RETAIN([NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(postCaching:) userInfo:nil repeats:YES]);
        dwnMsgTimer_.fireDate = [NSDate distantFuture];
        downloadFile_ = nil;
        downloadCountForSpeed_ = 0;
        downloadBytesForSpeed_ = 0;
        threadCount_ = 2;
        prevCacheSize_ = 4 * DEFAULT_PKSIZE;
#ifndef __OPTIMIZE__
        //        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
        //        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidFinish:) name:AFNetworkingOperationDidFinishNotification object:nil];
#endif
        //        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(retryUrlDownload:) name:@"DOWNLOADERROR" object:nil];
        //获取当前目录下的所有下载数据
        NSLog(@"获取当前目录下的所有下载数据");
//        if([NSThread isMainThread])
//        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void)
                           {
                               NSArray * itemList = [self getVDCItemsFromDir];
                               for (VDCItem * item in itemList) {
//                                   [self addVDCItemToList:item];
                                   NSLog(@"parse item :%@",item.title?item.title:@"nil");
                               }
                               [self removeVDCItemsExpired];
                           });
//        }
//        else
//        {
//            NSArray * itemList = [self getVDCItemsFromDir];
//            for (VDCItem * item in itemList) {
//                [self addVDCItemToList:item];
//                NSLog(@"parse item :%@",item.title?item.title:@"nil");
//            }
//            [self removeVDCItemsExpired];
//        }
    }
    return self;
}
//- (void)dealloc
//{
//    dispatch_release(downloadItemQueue_);
//    dispatch_release(downloadQueue_);
//
//}
#pragma mark - 单下载对像的处理操作
- (VDCItem *) getSampleVDCItem:(long)sampleID
{
    VDCItem * currentItem = nil;
    @synchronized(itemList_) {
        for (int i = (int)itemList_.count-1; i>=0; i --) {
            VDCItem * item = itemList_[i];
            if(item.SampleID == sampleID && item.MTVID==0)
            {
                currentItem = item;
                break;
            }
        }
    }
    
    return currentItem;
}
- (VDCItem *) getMTVVDCItem:(long)sampleID userID:(int)userID
{
    VDCItem * currentItem = nil;
    //    @synchronized(self) {
    //        for (int i = (int)itemList_.count-1; i>=0; i --) {
    //            VDCItem * item = itemList_[i];
    //            if(item.SampleID == sampleID && item.userid==userID)
    //            {
    //                currentItem = item;
    //                break;
    //            }
    //        }
    //    }
    
    return currentItem;
}

- (VDCItem *) getVDCItemByLocalFile:(NSString *)path
{
    return [self getVDCItemForResponse:path];
}
- (VDCItem *) getVDCItem:(NSString *)key
{
    VDCItem * currentItem = nil;
    @synchronized(itemList_) {
        for (int i = (int)itemList_.count-1; i>=0; i --) {
            VDCItem * item = itemList_[i];
            if([item.key isEqualToString:key])
            {
                currentItem = item;
                break;
            }
        }
    }
    if(currentItem)
    {
        @synchronized(itemList_) {
            [itemList_ removeObject:currentItem];
            [itemList_ insertObject:currentItem atIndex:0];
        }
    }
    return currentItem;
}
- (VDCItem *)addVDCItemToList:(VDCItem *)vdcitem
{
    if(!vdcitem)
        return nil;
    VDCItem * currentItem = [self getVDCItem:vdcitem.key];
    if(currentItem) return currentItem;
    else
    {
        @synchronized(itemList_) {
            [itemList_ insertObject:vdcitem atIndex:0];
        }
        return vdcitem;
    }
}
- (BOOL)checkMVPath:(VDCItem *)item
{
    
    BOOL isCompleted = NO;
    if(item.localFilePath)
    {
        NSString * path = nil;
        BOOL isExists = NO;
        UInt64 size = 0;
        isExists = [[UDManager sharedUDManager]isFileExistAndNotEmpty:item.localFilePath size:&size pathAlter:&path];
        if(isExists && size>0)
        {
            item.localFileName = [[HCFileManager manager] getFileName:path];
//            item.localFilePath = path;
            item.downloadBytes = size;
            item.contentLength = size;
            isCompleted = YES;
        }
    }
    else if(item.contentLength <= item.downloadBytes && item.contentLength>0)
    {
        isCompleted = YES;
    }
    return isCompleted;
}
- (BOOL)checkAudioPath:(VDCItem *)item
{
    if(!item || !item.AudioUrl || item.AudioUrl.length<2) return NO;
    //创建地址
    //    item.AudioTempPath = [item.tempFilePath stringByAppendingPathExtension:@"guide.m4a"];
//    NSString * newPath = nil;
    UInt64 size = 0;
    
    if(item.AudioPath && item.AudioPath.length>2)
    {
        BOOL hasFile = [[UDManager sharedUDManager]isFileExistAndNotEmpty:item.AudioPath
                                                                     size:&size];
        if(!hasFile || size==0)
        {
            item.AudioFileName = nil;
        }
    }
    if(!item.AudioPath || item.AudioPath.length<=2)
    {
        NSString * path = nil;
        if(item.MTVID>0)
        {
            path = [item.localFilePath stringByAppendingPathExtension:@"m4a"];
        }
        else
        {
            path = [item.localFilePath stringByAppendingPathExtension:@"guide.m4a"];
        }
        
        BOOL hasFile = [[UDManager sharedUDManager]isFileExistAndNotEmpty:path
                                                                     size:&size];
        if(hasFile && size>0)
        {
            item.AudioFileName = [[HCFileManager manager]getFileName:path];
        }
        else
        {
            item.AudioFileName = nil;
        }
    }
    return item.AudioFileName && item.AudioFileName.length>2?YES:NO;
}
- (void)buildAudioPath:(VDCItem*)item audioUrlString:(NSString *)urlString key:(NSString *)key
{
    if(!item || !urlString || urlString.length==0) return;
    if([item.AudioUrl isEqualToString:urlString])
    {
        if(item.AudioPath && item.AudioPath.length>0) return;
    }
    
    //创建地址
    //    item.AudioTempPath = [item.tempFilePath stringByAppendingPathExtension:@"guide.m4a"];
    if(item.MTVID>0)
    {
        item.AudioFileName = [item.localFileName stringByAppendingPathExtension:@"m4a"];
    }
    else
    {
        item.AudioFileName = [item.localFileName stringByAppendingPathExtension:@"guide.m4a"];
    }
    
}
- (NSString *)replaceForAudioPath:(NSString*)path
{
    if([path hasSuffix:@".mp4"]||[path hasSuffix:@".MP4"])
    {
        return [[path substringToIndex:path.length-4] stringByAppendingPathExtension:@"m4a"];
    }
    return path;
}
- (VDCItem *)getAudioItemByUrl:(NSString *)audioUrl title:(NSString*)title
{
    NSString * key = [self getRemoteFileCacheKey:audioUrl];
    VDCItem * audioItem = [self getVDCItem:key];
    if(!audioItem)
    {
        audioItem = [self createVDCItem:audioUrl key:key];
        audioItem.isAudioItem = YES;
        [self addVDCItemToList:audioItem];
    }
    audioItem.title = title;
    //    if(title && title.length>0)
    //    {
    //        audioItem.title = [NSString stringWithFormat:@"%@(导唱)",title];
    //    }
    if(!audioItem.title || audioItem.title.length==0)
    {
        audioItem.title = [NSString stringWithFormat:@"%@(导唱)",[audioItem.tempFilePath lastPathComponent]];
    }
    audioItem.localFileName = [self replaceForAudioPath:audioItem.localFileName];
    audioItem.tempFileName = [self replaceForAudioPath:audioItem.tempFileName];
    return audioItem;
}
- (VDCItem *)createVDCItem:(NSString *)urlString key:(NSString *)key
{
    if(!key) return nil;
    
    
    NSString * localWebUrl = [self getLocalWebUrl:key];
    NSString * localFilePath = [self getFilePathForLocalUrl:localWebUrl];
    NSString * tempFilePath = [self getTempFilePathForLocalUrl:localWebUrl];
    
    VDCItem * item = [self getDownloadItemFromFile:tempFilePath];
    if(!item)
    {
        item = [VDCItem new];
    }
    
    item.key = key;
    item.localFileName = [[HCFileManager manager]getFileName:localFilePath];
    item.tempFileName = [[HCFileManager manager]getFileName:tempFilePath];
//    item.localFilePath = localFilePath;
//    item.tempFilePath = tempFilePath;
    item.localWebUrl = localWebUrl;
    item.isCheckedFiles = NO;
    item.readyCall = nil;
    item.downloadedCall = nil;
    item.progressCall = nil;
    if(urlString && ![HCFileManager isLocalFile:urlString])
    {
//        NSLog(@"参数错误:%@(需要URL)",urlString);
//        BOOL isExists = NO;
//        NSString * path = [[UDManager sharedUDManager]checkPathForApplicationPathChanged:urlString mtvID:0 filetype:1 isExists:&isExists];
//        if(isExists && path)
//        {
//            item.localFilePath = path;
//        }
//    }
//    else if(urlString)
//    {
        item.remoteUrl = urlString;
    }
    return PP_AUTORELEASE(item);
}
- (VDCItem *) getVDCItemForResponse:(NSString *)filePath
{
    if(!filePath) return nil;
    NSString * key = [self getKeyFromLocalUrl:filePath];
    if(!key || key.length==0) return nil;
    
    VDCItem * item = [self getVDCItem:key];
    if(!item)
    {
        item = [self createVDCItem:nil key:key];
        item = [self addVDCItemToList:item];
        if([HCFileManager isLocalFile:filePath])
        {
            item.localFileName = [[HCFileManager manager]getFileName:filePath];
            UInt64 size = [[UDManager sharedUDManager]fileSizeAtPath:item.localFilePath];
            item.contentLength = size;
            item.downloadBytes = size;
        }
    }
    else if(item.contentLength<=0)
    {
        if([HCFileManager isLocalFile:filePath])
        {
            item.localFileName = [[HCFileManager manager]getFileName:filePath];
            UInt64 size = [[UDManager sharedUDManager]fileSizeAtPath:item.localFilePath];
            item.contentLength = size;
            item.downloadBytes = size;
        }
    }
    [self isItemFileChecked:item];
    if(!item.isCheckedFiles)
    {
        [self checkItemFile:item removePartFile:NO];
    }
    
    [self removeItemsNoNeed:item];
    [self resetLastDownloadTime:item];
    
    return item;
}
- (void)removeItemsNoNeed:(VDCItem *)item
{
    @synchronized(itemList_) {
        //移除当前不用的Items
        if(itemList_.count>50)
        {
            for (int i = (int)itemList_.count-1;i>=40;i--)
            {
                if(itemList_[i]!=item)
                {
                    [itemList_ removeObjectAtIndex:i];
                }
            }
        }
    }
}
- (VDCItem *) getVDCItemByLoaderURL:(NSString *)urlString checkFiles:(BOOL)checkFiles
{
    NSString * httpUrl  = [urlString stringByReplacingOccurrencesOfRegex:@"streaming://" withString:@"http://"];
    return [self getVDCItemByURL:httpUrl checkFiles:checkFiles];
}
- (VDCItem *) getVDCItemByURL:(NSString *)urlString checkFiles:(BOOL)checkFiles
{
    NSString * key = nil;
    if([HCFileManager isLocalFile:urlString])
    {
        key = [self getKeyFromLocalPath:urlString];
    }
    else
    {
        key = [self getRemoteFileCacheKey:urlString];
    }
    VDCItem * item = [self getVDCItem:key];
    if(!item)
    {
        item = [self createVDCItem:urlString key:key];
        item = [self addVDCItemToList:item];
    }
    else
    {
        if(checkFiles && !item.isCheckedFiles)
            item.downloadBytes = 0;
    }
    if (!item.remoteUrl) {
        item.remoteUrl = urlString;
    }
    item.needStop = NO;
    if(!item.isCheckedFiles && checkFiles)
    {
        [self checkItemFile:item removePartFile:NO];
    }
    
    
    item.ticks = [CommonUtil getDateTicks:[NSDate date]];
    
    //        if([CommonUtil isFileExistAndNotEmpty:item.localFilePath size:nil])
    //        {
    //            item.tempFileList = nil;
    //        }
    return item;
}

#pragma mark - get set
- (VDCTempFileInfo *)getNextTempSlideToDown:(VDCItem *)item offset:(UInt64)offset minOffsetDownloading:(UInt64 *)minOffset
{
    if(!item ||!item.tempFileList) return nil;
    
    NSArray * tempFileList = item.tempFileList;
    
    VDCTempFileInfo * currentFi = nil;
    if(minOffset) *minOffset = UINT64_MAX;
    if(proirDownloadList_ && proirDownloadList_.count>0)
    {
        for (int i = 0; i< (int)proirDownloadList_.count; i ++) {
            VDCTempFileInfo * fi = proirDownloadList_[i];
            if(fi.lengthFull > fi.length && fi.lengthFull>0 && (fi.isDownloading==NO))
            {
                currentFi = fi;
                break;
            }
        }
    }
    if(!currentFi.parentItem || ![currentFi.parentItem.key isEqualToString:item.key] )
    {
        currentFi = nil;
        if(proirDownloadList_)
        {
        @synchronized(proirDownloadList_) {
            [proirDownloadList_ removeAllObjects];
        }
        }
    }
    if(!currentFi)
    {
        for(NSInteger i = 0;i<tempFileList.count;i++)
        {
            VDCTempFileInfo * fi = [tempFileList objectAtIndex:i];
            if(fi.offset >= offset && fi.lengthFull > fi.length && fi.lengthFull>0 && (fi.isDownloading==NO))
            {
                currentFi = fi;
                
                break;
            }
            else
            {
                if(minOffset)
                {
                    if(fi.isDownloading && fi.offset < * minOffset)
                    {
                        *minOffset = fi.offset;
                    }
                }
            }
            
        }
        //        //如果不是从中间开始，并且没有数据，则需要重头再走一遍
        //        if(offset>0 && !currentFi)
        //        {
        //            offset = 0;
        //            for(NSInteger i = 0;i<tempFileList.count;i++)
        //            {
        //                VDCTempFileInfo * fi = [tempFileList objectAtIndex:i];
        //                if(fi.offset >= offset && fi.lengthFull > fi.length && fi.lengthFull>0 && (fi.isDownloading==NO))
        //                {
        //                    currentFi = fi;
        //                    break;
        //                }
        //                else
        //                {
        //                    if(minOffset)
        //                    {
        //                        if(fi.isDownloading && fi.offset < * minOffset)
        //                        {
        //                            *minOffset = fi.offset;
        //                        }
        //                    }
        //                }
        //
        //            }
        //        }
    }
    if (currentFi && !currentFi.parentItem) {
        currentFi.parentItem = item;
    }
    return currentFi;
}

#pragma mark - stop fun
- (void)stopItemsInList
{
    @synchronized(itemList_) {
        for (int i = (int)itemList_.count-1; i>=0; i --) {
            VDCItem * item = itemList_[i];
            item.readyCall = nil;
            item.progressCall = nil;
            item.downloadedCall = nil;
            item.needStop = YES;
        }
    }
}
- (void)stopCache:(VDCItem *)item
{
    [self clearPriorDownloadList:item];
    item.needStop = YES;
}
- (void)stopDownload:(NSString *)urlString
{
    [self stopItemsInList];
    
    if(urlString && urlString.length>0)
    {
        [self cancelReqeustes:[NSArray arrayWithObject:urlString] excludeItem:nil removeFiles:NO];
    }
    else
    {
        [self cancelReqeustes:nil excludeItem:nil removeFiles:NO];
    }
}
//清除文件缓存，重新开始下载
- (void) removeCache:(NSArray*)urlStringList completed:(removeCacheFinished)completed
{
    [self cancelReqeustes:urlStringList excludeItem:nil removeFiles:YES];
    
    [NSThread sleepForTimeInterval:0.3];
    if(completed)
    {
        completed(TRUE);
    }
}
- (void)beginCheckPoint:(VDCItem *)excludeItem
{
    //刹车优先
    isSomeOneDownloading = threadCount_+10;
    [self setNeedCancelLocalRequest];
    
    [self cancelItemsInDownloadList:excludeItem];
}
- (void)waitingCompletedCheck
{
    NSLog(@"waiting completed check...");
    int i = 0;
    while (isSomeOneDownloading > threadCount_ + 10) {
        [NSThread sleepForTimeInterval:0.1];
        i ++;
        if(i>20) break;
    }
    [self didStopLocalWebRequest:nil];
    if(needCancelLocalWebRequest)
    {
        i = 0;
        while([self needStopLocalWebRequest:nil] && i < 3)
        {
            [NSThread sleepForTimeInterval:0.1];
            i ++;
        }
        needCancelLocalWebRequest = NO;
    }
    for (int i = (int)itemList_.count-1; i>=0; i--) {
        VDCItem * item = itemList_[i];
        if(item.needStop)
        {
            item.isDownloading = NO;
        }
    }
    //    for (VDCItem * item in itemList_) {
    //        if(item.needStop)
    //        {
    //            item.isDownloading = NO;
    //        }
    //    }
    isSomeOneDownloading = 0;
#ifndef __OPTIMIZE__
    NSLog(@"main queue count:%ld",mainQueueItemCount);
    NSLog(@"child queue count:%ld",childQueueItemCount);
#endif
}
- (void)removeCacheViaVDCItem:(VDCItem *)item
{
    if(!item) return;
    
    [self beginCheckPoint:nil];
    
    if(!item.isAudioItem && item.AudioUrl && item.AudioUrl.length>10)
    {
        NSString * title = nil;
        if(item.title && item.title.length>0)
        {
            if(item.MTVID>0)
            {
                title = [NSString stringWithFormat:@"%@(录音)",item.title];
            }
            else
            {
                title = [NSString stringWithFormat:@"%@(导唱)",item.title];
            }
        }
        VDCItem * audioItem = [self getAudioItemByUrl:item.AudioUrl title:title];
        dispatch_async(downloadQueue_, ^(void)
                       {
                           [self cancelReqeustesInQueue:audioItem excludeItem:nil withFlags:YES];
                       });
    }
    dispatch_async(downloadQueue_, ^(void)
                   {
                       [self cancelReqeustesInQueue:item excludeItem:nil withFlags:YES];
                   });
    
    [self waitingCompletedCheck];
}
- (void)cancelReqeustes:(NSArray *)urlStringList excludeItem:(VDCItem *)excludeItem removeFiles:(BOOL)removeFiles
{
    //    @synchronized(self) {
    
    [self beginCheckPoint:excludeItem];
    
    [self clearPriorDownloadList:nil];
    
    if(urlStringList)
    {
        for (NSString * urlString in urlStringList) {
            NSString * key = [self getRemoteFileCacheKey:urlString];
            
            VDCItem * item = [self getVDCItem:key];
            if(!item)
            {
                item = [self createVDCItem:urlString key:key];
                item = [self addVDCItemToList:item];
            }
            item.needStop = YES;
            if(removeFiles)
            {
                if(!item.isAudioItem && item.AudioUrl && item.AudioUrl.length>10)
                {
                    NSString * title = nil;
                    if(item.title && item.title.length>0)
                    {
                        if(item.MTVID>0)
                        {
                            title = [NSString stringWithFormat:@"%@(录音)",item.title];
                        }
                        else
                        {
                            title = [NSString stringWithFormat:@"%@(导唱)",item.title];
                        }
                    }
                    VDCItem * audioItem = [self getAudioItemByUrl:item.AudioUrl title:title];
                    dispatch_async(downloadQueue_, ^(void)
                                   {
                                       [self cancelReqeustesInQueue:audioItem excludeItem:excludeItem withFlags:NO];
                                   });
                }
                dispatch_async(downloadQueue_, ^(void)
                               {
                                   [self cancelReqeustesInQueue:item excludeItem:excludeItem withFlags:NO];
                               });
            }
            for (int i = 0; i<item.tempFileList.count; i++) {
                VDCTempFileInfo * fi = item.tempFileList[i];
                fi.isDownloading = NO;
            }
            item.isDownloading = NO;
            [self rememberDownloadUrl:item tempPath:item.tempFilePath];
        }
    }
    else
    {
        for (int i = (int)itemList_.count-1; i>=0; i --) {
            VDCItem * item = itemList_[i];
            item.needStop = YES;
            if(item.isDownloading)
            {
                if(removeFiles)
                {
                    if(!item.isAudioItem && item.AudioUrl && item.AudioUrl.length>10)
                    {
                        NSString * title = nil;
                        if(item.title && item.title.length>0)
                        {
                            if(item.MTVID>0)
                            {
                                title = [NSString stringWithFormat:@"%@(录音)",item.title];
                            }
                            else
                            {
                                title = [NSString stringWithFormat:@"%@(导唱)",item.title];
                            }
                        }
                        VDCItem * audioItem = [self getAudioItemByUrl:item.AudioUrl title:title];
                        dispatch_async(downloadQueue_, ^(void)
                                       {
                                           [self cancelReqeustesInQueue:audioItem excludeItem:excludeItem withFlags:NO];
                                       });
                    }
                    dispatch_async(downloadQueue_, ^(void)
                                   {
                                       [self cancelReqeustesInQueue:item excludeItem:excludeItem withFlags:NO];
                                   });
                }
                for (int i = 0; i<item.tempFileList.count; i++) {
                    VDCTempFileInfo * fi = item.tempFileList[i];
                    fi.isDownloading = NO;
                }
                item.isDownloading = NO;
                [self rememberDownloadUrl:item tempPath:item.tempFilePath];
            }
        }
    }
    [self waitingCompletedCheck];
}

//当合成时，有可能发现某个文件下载得并不完整，因此需要移除某个位置的文件，就算下载完成了，也需要将完成的数据去掉
- (void)    removeCache:(NSString *)urlString atProgress:(CGFloat)progress
{
    [self beginCheckPoint:nil];
    
    NSString * key = [self getRemoteFileCacheKey:urlString];
    
    VDCItem * item = [self getVDCItem:key];
    if(!item)
    {
        item = [self createVDCItem:urlString key:key];
    }
    dispatch_async(downloadQueue_, ^(void)
                   {
                       [self removeCacheInQueue:item atProgress:progress];
                   });
    
    [self waitingCompletedCheck];
}
//主要在视频编译时使用，移除缓存文件
- (void)removeTemplateFilesByUrl:(NSString *)urlString
{
    NSString * key = [self getRemoteFileCacheKey:urlString];
    
    VDCItem * item = [self getVDCItem:key];
    if(!item)
    {
        item = [self createVDCItem:urlString key:key];
    }
    
    if(item.isDownloading)
    {
        item.needStop = YES;
    }
    
    if(!item.isAudioItem && item.AudioUrl && item.AudioUrl.length>10)
    {
        NSString * title = nil;
        if(item.title && item.title.length>0)
        {
            if(item.MTVID>0)
            {
                title = [NSString stringWithFormat:@"%@(录音)",item.title];
            }
            else
            {
                title = [NSString stringWithFormat:@"%@(导唱)",item.title];
            }
        }
        VDCItem * audioItem = [self getAudioItemByUrl:item.AudioUrl title:title];
        dispatch_async(downloadQueue_, ^(void)
                       {
                           [self removeTemplateFilesViaItemInQueue:audioItem];
                       });
    }
    dispatch_async(downloadQueue_, ^(void)
                   {
                       [self removeTemplateFilesViaItemInQueue:item];
                   });
    [NSThread sleepForTimeInterval:0.2];
}
#pragma mark - stop remove...core...
- (void)cancelReqeustesInQueue:(VDCItem *)item excludeItem:(VDCItem *)excludeItem withFlags:(BOOL)withFlags
{
#ifndef __OPTIMIZE__
    mainQueueItemCount ++;
#endif
    isSomeOneDownloading ++;
    if(!excludeItem || (excludeItem && excludeItem!=item && [excludeItem.key isEqualToString:item.key]==NO))
    {
        [self removeItem:item withTempFiles:YES includeLocal:YES];
        [self removeItemAudioFile:item];
        
        
        if(withFlags)
        {
            NSString * filePath = item.tempFilePath;
            if(filePath && filePath.length>0)
            {
                [self removeDownloadUrlFromFile:filePath];
            }
            [self removeItemWithFlags:item excludeItem:nil];
        }
        item.isDownloading = NO;
    }
    isSomeOneDownloading --;
#ifndef __OPTIMIZE__
    mainQueueItemCount --;
#endif
}
- (void)    removeCacheInQueue:(VDCItem *)item atProgress:(CGFloat)progress
{
#ifndef __OPTIMIZE__
    mainQueueItemCount +=100;
#endif
    //强置，防止新的下载进入
    isSomeOneDownloading ++;
    
    //等待Web服务的进程结束HttpVideoFileResponse
    int i = 0;
    while([self needStopLocalWebRequest:nil] && i < 3)
    {
        [NSThread sleepForTimeInterval:0.1];
        i ++;
    }
    if(item)
    {
        UInt64 contentLength = 0;
        [HCFileManager checkUrlIsExists:item.remoteUrl contengLength:&contentLength level:nil];
        if(contentLength>0)
            item.contentLength = contentLength;
        
        [self removeItem:item withTempFiles:NO includeLocal:YES];
        
        //移除特定位置的文件,一般为当前位置及其后的三个包，共4个包。
        UInt64 offset = item.contentLength * progress;
        //        VDCTempFileInfo * fileInfo = nil;
        
        NSMutableArray * removeFileList = [NSMutableArray new];
        BOOL hasMatched = NO;
        
        for(NSInteger i = 0;i<item.tempFileList.count;i++)
        {
            VDCTempFileInfo * fi = [item.tempFileList objectAtIndex:i];
            if(hasMatched || (fi.offset <= offset && fi.offset + fi.lengthFull > offset))
            {
                hasMatched = YES;
                [removeFileList addObject:fi];
                if(removeFileList.count>=8) break;
            }
        }
        for (VDCTempFileInfo * fileInfo in removeFileList) {
            item.downloadBytes -= fileInfo.length;
            fileInfo.length = 0;
            fileInfo.isDownloading = NO;
            [[HCFileManager manager]removeFileAtPath:fileInfo.filePath];
        }
        PP_RELEASE(removeFileList);
        
        if(item.AudioPath&& item.AudioPath.length>0)
        {
            [[HCFileManager manager]removeFileAtPath:item.AudioPath];
        }
        //        if(item.AudioTempPath&& item.AudioTempPath.length>0)
        //        {
        //            [[UDManager sharedUDManager]removeFileAtPath:item.AudioTempPath];
        //        }
        item.isDownloading = NO;
        [self rememberDownloadUrl:item tempPath:item.tempFilePath];
    }
    else
    {
        [self stopItemsInList];
    }
    
    isSomeOneDownloading --;
#ifndef __OPTIMIZE__
    mainQueueItemCount -=100;
#endif
}
- (void)removeTemplateFilesViaItemInQueue:(VDCItem *)item
{
    if(!item) return;
#ifndef __OPTIMIZE__
    mainQueueItemCount +=10000;
#endif
    [self removeItem:item withTempFiles:YES includeLocal:NO];
    
    [self rememberDownloadUrl:item tempPath:item.tempFilePath];
#ifndef __OPTIMIZE__
    mainQueueItemCount -=10000;
#endif
}

#pragma mark - remove item core

- (void)removeItemWithFlags:(VDCItem *)item excludeItem:(VDCItem*)excludeItem
{
    if(!item) return;
    @synchronized(item) {
        item.readyCall = nil;
        item.progressCall = nil;
        item.downloadedCall = nil;
        item.needStop = YES;
        
    }
    [self removeItemsNoNeed:excludeItem];
}

- (void)removeItem:(VDCItem *)item withTempFiles:(BOOL)withTempfiles includeLocal:(BOOL)includeLocal
{
    if(!item) return;
    
    if (item.isDownloading)
    {
        item.needStop = YES;
    }
    @synchronized(item) {
        item.readyCall = nil;
        item.progressCall = nil;
        item.downloadedCall = nil;
    }
    
    if(!item.isCheckedFiles)
    {
        [self checkItemFile:item removePartFile:NO];
    }
    if(includeLocal)
    {
        if (item.localFilePath) {
            [[HCFileManager manager]removeFileAtPath:item.localFilePath];
        }
        if (item.AudioPath) {
            [[HCFileManager manager]removeFileAtPath:item.AudioPath];
        }
    }
    [self removeTempFiles:item.tempFilePath
            contentlength:item.contentLength
              checkLength:!withTempfiles
                matchSize:withTempfiles?0:DEFAULT_PKSIZE];
    
    if(withTempfiles)
    {
        //        if(itemList_.count>20)
        //        {
        //            [itemList_ removeObject:item];
        //        }
        //        [itemList_ removeObject:item];
        item.isCheckedFiles = NO;
        //        item.downloadBytes = 0;
        for (int i = 0; i<item.tempFileList.count; i++) {
            VDCTempFileInfo * fi = item.tempFileList[i];
            fi.length = 0;
        }
    }
    
    [self removeItemsNoNeed:item];
    
    [self rememberDownloadUrl:item tempPath:item.tempFilePath];
}

- (void)removeItemAudioFile:(VDCItem *)item
{
    if(item.isAudioItem) return;
    //    if(item.AudioTempPath && item.AudioTempPath.length>0)
    //    {
    //        [[UDManager sharedUDManager]removeFileAtPath:item.AudioTempPath];
    //    }
    if(item.AudioPath && item.AudioPath.length>0)
    {
        [[HCFileManager manager]removeFileAtPath:item.AudioPath];
    }
}
- (void)removeItemList
{
    [itemList_ removeAllObjects];
}
#pragma mark - cache download
- (void)checkItemAudioFile:(VDCItem *)item audioUrl:(NSString*)audioUrl
{
    if(item.isAudioItem) return;
    if(audioUrl)
    {
        item.AudioUrl = audioUrl;
    }
    if(!item.AudioUrl ||item.AudioUrl.length<=10) return;
    
    NSString * title = nil;
    if(item.title && item.title.length>0)
    {
        if(item.MTVID>0)
        {
            title = [NSString stringWithFormat:@"%@(录音)",item.title];
        }
        else
        {
            title = [NSString stringWithFormat:@"%@(导唱)",item.title];
        }
    }
    VDCItem * audioItem = [self getAudioItemByUrl:item.AudioUrl title:title];
    NSString * newPath = nil;
    if([[UDManager sharedUDManager] isFileExistAndNotEmpty:audioItem.localFilePath size:nil pathAlter:&newPath])
    {
        if(!item.AudioPath || item.AudioPath.length<3)
        {
            [self buildAudioPath:item audioUrlString:item.AudioUrl key:nil];
        }
        if(newPath && item.AudioPath)
        {
            [HCFileManager copyFile:newPath target:item.AudioPath overwrite:NO];
            NSLog(@"copy audiopath %@ to %@",newPath,item.AudioPath);
        }
    }
}
- (BOOL)checkRemoteUrl:(VDCItem*)item
{
    if(!item.remoteUrl || item.remoteUrl.length<=3) return NO;
    if([HCFileManager isLocalFile:item.remoteUrl])
    {
        item.localFileName = [[HCFileManager manager]getFileName:item.remoteUrl];
        
        UInt64 size = [[UDManager sharedUDManager] fileSizeAtPath:item.localFilePath];
        if(size>0){
            if(item.contentLength<=0)
            {
                item.contentLength = size;
            }
            item.downloadBytes = item.contentLength;
            item.remoteUrl = nil;
//            item.localFilePath = item.remoteUrl;
        }
        else
        {
            return NO;
        }
    }
    if(!item.localFileName || item.localFileName.length<2)
    {
        NSString * localWebUrl = [self getLocalWebUrl:item.key];
        item.localFileName = [self getFilePathForLocalUrl:localWebUrl];
    }
    NSString * filePath = item.localFilePath;
    if([HCFileManager isLocalFile:filePath])
    {
        UInt64 size = [[UDManager sharedUDManager] fileSizeAtPath:filePath];
        if(size>0){
            if(item.contentLength<=0)
            {
                item.contentLength = size;
            }
            item.downloadBytes = item.contentLength;
        }
    }
    if(item.contentLength<=DEFAULT_PKSIZE)
    {
        UInt64 size = 0;
        if([HCFileManager checkUrlIsExists:item.remoteUrl contengLength:&size level:nil])
        {
            item.contentLength = size;
        }
    }
    return YES;
}
- (VDCItem *) addUrlCache:(NSString *)urlString title:(NSString *)title urlReady:(videoUrlReady)urlReady completed:(downloadCompleted)dcompleted
{
    return [self addUrlCache:urlString audioUrl:nil title:title urlReady:urlReady completed:dcompleted];
}
- (BOOL)isItemFileChecked:(VDCItem *)item
{
    //获取本地文件信息
    if(item.isCheckedFiles)
    {
        if(item.localFileName && item.localFileName.length>2)
        {
            NSString * newPath = item.localFilePath;
            UInt64 size = [[UDManager sharedUDManager]fileSizeAtPath:newPath];
           if(size>0)
           {
           }
            else
            {
                //抽样三个文件
                if(item.tempFileList && item.tempFileList.count>0)
                {
                    int index = (int)item.tempFileList.count-1;
                    VDCTempFileInfo * fi = item.tempFileList[index];
                    if(item.isCheckedFiles && fi.length>0)
                    {
                        if([[UDManager sharedUDManager]isFileExistAndNotEmpty:item.localFilePath size:&size pathAlter:&newPath])
                        {
                            if(fi.length>size)
                            {
                                item.isCheckedFiles = NO;
                            }
                        }
                        else
                        {
                            item.isCheckedFiles = NO;
                        }
                        
                    }
                    
                    index = 0;
                    fi = item.tempFileList[index];
                    if(item.isCheckedFiles && fi.length>0)
                    {
                        if([[UDManager sharedUDManager]isFileExistAndNotEmpty:item.localFilePath size:&size pathAlter:&newPath])
                        {
                            if(fi.length>size)
                            {
                                item.isCheckedFiles = NO;
                            }
                        }
                        else
                        {
                            item.isCheckedFiles = NO;
                        }
                        
                    }
                    index = (int)item.tempFileList.count/2 ;
                    fi = item.tempFileList[index];
                    if(item.isCheckedFiles && fi.length>0)
                    {
                        if([[UDManager sharedUDManager]isFileExistAndNotEmpty:item.localFilePath size:&size pathAlter:&newPath])
                        {
                            if(fi.length>size)
                            {
                                item.isCheckedFiles = NO;
                            }
                        }
                        else
                        {
                            item.isCheckedFiles = NO;
                        }
                        
                    }
                }
                else
                {
                    item.isCheckedFiles = NO;
                }
            }
        }
    }
    return item.isCheckedFiles;
}
- (VDCItem *) addUrlCache:(NSString *)urlString audioUrl:(NSString*)audioUrl title:(NSString *)title urlReady:(videoUrlReady)urlReady completed:(downloadCompleted)dcompleted
{
    if(!urlString)
    {
        NSLog(@" parameter cannot be nil ;");
    }
    else if([HCFileManager isLocalFile:urlString]) //如果是本地文件，则只需要检查音频是否正确
    {
        NSString * newPath = nil;
        BOOL isExist = NO;
        newPath = [[UDManager sharedUDManager]checkPathForApplicationPathChanged:urlString isExists:&isExist];
        if(isExist && newPath)
        {
            urlString = newPath;
            VDCItem * item = [self getVDCItemByLocalFile:urlString];
            if(item.AudioFileName && item.AudioFileName.length>0)
            {
                if(![[UDManager sharedUDManager]isFileExistAndNotEmpty:item.AudioPath size:nil])
                {
                    item.AudioFileName = nil;
                }
            }
            
            if(item.AudioUrl && item.AudioUrl.length>0 && (!item.AudioPath || item.AudioPath.length>0))
            {
                [self addUrlCacheInThread:item urlReady:urlReady completed:dcompleted];
            }
            else
            {
                if(urlReady)
                {
                    urlReady(item,[NSURL fileURLWithPath:newPath]);
                }
            }
            return item;
        }
        else
        {
            NSLog(@"parameter error..(%@)...not exists.",urlString?urlString:@"nil");
            return nil;
        }
    }
    
    
    if ([[DeviceConfig config]platformType]==UIDevice6iPhone ||
        [[DeviceConfig config]platformType] == UIDevice6PiPhone ||
        [[DeviceConfig config]platformType] == UIDevice6PSiPhone ||
        [[DeviceConfig config]platformType] == UIDevice6SiPhone ||
        [[DeviceConfig config]platformType] == UIDeviceUnknowniPhone) {
        threadCount_ = 2;
        prevCacheSize_ =  4 * DEFAULT_PKSIZE;
    }
    else
    {
        threadCount_ = 1;
        prevCacheSize_ = 4 * DEFAULT_PKSIZE; //防卡
    }
    if([DeviceConfig IOSVersion]>7.0)
    {
        prevCacheSize_ = 0;
    }
    
    NSString * key = [self getRemoteFileCacheKey:urlString];
    VDCItem * item = [self getVDCItem:key];
    if(item)
    {
        //如果正在下载，不允许重入
        if(item.isDownloading && !item.needStop)
        {
            if([self isDataReady:item] && urlReady)
            {
                [self callReadyBlock:item videoUrlReady:urlReady];
                urlReady = nil;
            }
            item.readyCall = urlReady;
            item.downloadedCall = dcompleted;
            return item;
        }
        item.downloadBytes = 0;
    }
    else if(!item)
    {
        item = [self createVDCItem:urlString key:key];
        item = [self addVDCItemToList:item];
    }
    if(audioUrl && audioUrl.length>5)
    {
        item.AudioUrl = audioUrl;
    }
    else
    {
        item.AudioUrl = nil;
    }
    //取消当前正在下载的操作
    [self cancelReqeustes:nil excludeItem:item removeFiles:NO];
    
    item.needStop = NO;
    
    if(![self checkRemoteUrl:item])
    {
        NSLog(@" ****** parameter error..(%@)...",urlString?urlString:@"nil");
        return nil;
    }
    
    [self isItemFileChecked:item];
    
    if(!item.isCheckedFiles)
    {
        [self checkItemFile:item removePartFile:YES];
    }
    //    [self checkItemAudioFile:item audioUrl:audioUrl];
    
    item.ticks = [CommonUtil getDateTicks:[NSDate date]];
    
    NSFileManager * fm = [NSFileManager defaultManager];
    
    __weak VDCItem * weakItem = item;
    
    if(title && title.length>0)
        item.title = title;
    
    BOOL isCompleted = [self checkMVPath:item];
    BOOL isAudioCompleted  = [self checkAudioPath:item];
    
    //下载全部完成
    if(isCompleted && isAudioCompleted)
    {
        if(urlReady)
        {
            NSLog(@"change to local item:%@",item.localFilePath);
            if([fm fileExistsAtPath:item.localFilePath])
            {
                item.tempFileList = nil;
                urlReady(weakItem,[NSURL fileURLWithPath:item.localFilePath]);
            }
            else
            {
                //文件下完了，但数据不在了，重构文件列表数据
                if(!item.tempFileList||item.tempFileList.count==0)
                    [self getTemplateFiles:item];
                urlReady(weakItem,[NSURL URLWithString:item.localWebUrl]);
            }
        }
        if(dcompleted)
        {
            dcompleted(weakItem,YES,nil);
        }
        urlReady = nil;
        dcompleted = nil;
        return item;
    }
    //    else
    //    {
    //                #warning change 测试使用LoadRunner，缓存视频文件信息
    //                if(urlReady)
    //                {
    //                    NSLog(@"change to local item:%@",item.localFilePath);
    //                    if([fm fileExistsAtPath:item.localFilePath])
    //                    {
    //                        item.tempFileList = nil;
    //                        urlReady(weakItem,[NSURL fileURLWithPath:item.localFilePath]);
    //                    }
    //                    else
    //                    {
    //                        //文件下完了，但数据不在了，重构文件列表数据
    //                        if(!item.tempFileList||item.tempFileList.count==0)
    //                            [self getTemplateFiles:item];
    //
    //                        //IOS 7 以上使用LoadRunner，缓存视频文件信息
    //                        if([DeviceConfig IOSVersion] < 7.0)
    //                        {
    //                            //urlReady(item,[NSURL URLWithString:item.localWebUrl]);
    //                        }
    //                        else
    //                        {
    //                            urlReady(item,[NSURL URLWithString:item.remoteUrl]);
    //
    //                            //下载导唱
    //                            if(item.SampleID>0 && item.AudioUrl && item.AudioUrl.length>0)
    //                            {
    //
    //                            }
    //
    //                            return item;
    //                        }
    //
    //                    }
    //                }
    //    }
    
    if(title && title.length>0)
        item.title = title;
    
    dispatch_async(downloadQueue_, ^(void)
                   {
                       [self addUrlCacheInThread:weakItem urlReady:urlReady completed:dcompleted];
                   });
#ifndef __OPTIMIZE__
    NSLog(@" add main queue count:%ld",mainQueueItemCount);
    NSLog(@"add child queue count:%ld",childQueueItemCount);
#endif
    return item;
}
- (void)downloadUrl:(NSString *)urlString title:(NSString *)title urlReady:(videoUrlReady)urlReady progress:(downloadProgress)progress completed:(downloadCompleted)completed
{
    [self downloadUrl:urlString audioUrl:nil title:title isAudio:NO urlReady:urlReady progress:progress completed:completed];
}
- (void)downloadUrl:(NSString *)urlString audioUrl:(NSString*)audioUrl title:(NSString *)title
            isAudio:(BOOL)isAudio
           urlReady:(videoUrlReady)urlReady progress:(downloadProgress)progress completed:(downloadCompleted)completed
{
    if ([[DeviceConfig config]platformType]==UIDevice6iPhone ||
        [[DeviceConfig config]platformType] == UIDevice6PiPhone ||
        [[DeviceConfig config]platformType] == UIDevice6PSiPhone ||
        [[DeviceConfig config]platformType] == UIDevice6SiPhone ||
        [[DeviceConfig config]platformType] == UIDeviceUnknowniPhone) {
        threadCount_ = 2;
        prevCacheSize_ =  4 * DEFAULT_PKSIZE;
    }
    else
    {
        threadCount_ = 1;
        prevCacheSize_ = 4 * DEFAULT_PKSIZE; //防卡
    }
    
    
    NSString * key = [self getRemoteFileCacheKey:urlString];
    VDCItem * item = [self getVDCItem:key];
    
    BOOL hasCompleted = NO;
    
    if(item)
    {
        //如果正在下载，不允许重入
        if(item.isDownloading && !item.needStop)
        {
            __weak VDCItem * weakItem = item;
            
            if(urlReady)
            {
                NSString * newPath = item.localFilePath;
                
                if([[UDManager sharedUDManager]existFileAtPath:newPath])
                {
                    hasCompleted = YES;
                    urlReady(weakItem,[NSURL fileURLWithPath:newPath]);
                }
                else
                {
                    urlReady(weakItem,nil);
                }
            }
            if(progress)
                item.progressCall = progress;
            if(completed)
                item.downloadedCall = completed;
            
            return;
        }
        //        item.downloadBytes = 0;
    }
    else if(!item)
    {
        item = [self createVDCItem:urlString key:key];
        item = [self addVDCItemToList:item];
    }
    if(audioUrl && audioUrl.length>10)
    {
        item.AudioUrl = audioUrl;
    }
    if(isAudio) item.isAudioItem = YES;
    
    if(title && title.length>0)
        item.title = title;
    
    [self cancelReqeustes:nil excludeItem:item removeFiles:NO];
    
    item.needStop = NO;
    if(![self checkRemoteUrl:item])
    {
        NSLog(@"parameter error..(%@)...",item.remoteUrl?item.remoteUrl:@"nil");
        
        if (completed) {
            completed(item,NO,nil);
        }
        return;
    }
    if(!item.isCheckedFiles)
    {
        [self checkItemFile:item removePartFile:YES];
    }
    //    [self checkItemAudioFile:item audioUrl:audioUrl];
    
    item.ticks = [CommonUtil getDateTicks:[NSDate date]];
    
    __weak VDCItem * weakItem = item;
    
    if(urlReady)
    {
        NSString * newPath = item.localFilePath;
        if([[UDManager sharedUDManager] isFileExistAndNotEmpty:newPath size:nil])
        {
            hasCompleted = YES;
            item.tempFileList = nil;
            
            urlReady(weakItem,[NSURL fileURLWithPath:newPath]);
        }
        else
        {
            urlReady(weakItem,nil);
        }
        urlReady = nil;
    }
    
    if(item.contentLength <= item.downloadBytes && item.contentLength>0)
    {
        if(!hasCompleted)
        {
            NSString * newPath = item.localFilePath;
            if([[UDManager sharedUDManager] isFileExistAndNotEmpty:newPath size:nil])
            {
                hasCompleted = YES;
            }
            else
            {
                hasCompleted = NO;
            }
        }
        //check audio
        if(hasCompleted && audioUrl && audioUrl.length>0)
        {
            NSString * audioKey = [self getRemoteFileCacheKey:audioUrl];
            VDCItem * audioItem = [self getVDCItem:audioKey];
            if(audioItem && audioItem.localFileName && audioItem.localFileName.length>0)
            {
                if(![[UDManager sharedUDManager] isFileExistAndNotEmpty:audioItem.localFilePath size:nil])
                {
                    hasCompleted = NO;
                }
            }
            else
            {
                hasCompleted = NO;
            }
        }
        if(hasCompleted)
        {
            if(progress)
            {
                progress(weakItem);
            }
            if(completed)
            {
                completed(weakItem,hasCompleted,nil);
            }
            NSLog(@"download completed:(%@)-->(%@)",weakItem.remoteUrl,[weakItem.localFilePath lastPathComponent]);
            return;
        }
    }
    
    [self downloadItem:item urlReady:urlReady progress:progress completed:completed];
}
- (void)downloadItem:(VDCItem *)item urlReady:(videoUrlReady)urlReady progress:(downloadProgress)progress completed:(downloadCompleted)completed
{
    item.needStop = NO;
    if(![self checkRemoteUrl:item])
    {
        NSLog(@"parameter error..(%@)...",item.remoteUrl?item.remoteUrl:@"nil");
        
        if (completed) {
            completed(item,NO,nil);
        }
        return;
    }
    if(!item.isCheckedFiles)
    {
        [self checkItemFile:item removePartFile:YES];
    }
    
     __weak VDCItem * weakItem = item;
    dispatch_async(downloadQueue_, ^(void)
                   {
                       [self downloadUrlInQueue:weakItem urlReady:urlReady progress:progress completed:completed];
                   });
    
#ifndef __OPTIMIZE__
    NSLog(@" add main queue count:%ld",mainQueueItemCount);
    NSLog(@" add child queue count:%ld",childQueueItemCount);
#endif
}
//有可能跳跃式向后下载，即用户在拖动进度时
//问题在于：如何判断是由于播放器自已快速加载，还是人工拖动的？
- (void)downloadNextSlide:(VDCItem *)item offset:(UInt64)offset immediate:(BOOL)immediate
{
    if(offset==0) return;
    NSLog(@"proir list:%llu",offset);
    if(!immediate)
    {
        if(!item.isDownloading)
        {
            dispatch_async(downloadItemQueue_, ^(void)
                           {
                               [self startDownload:item urlReady:nil progress:nil completed:nil];
                           });
        }
        return;
    }
    else
    {
        @synchronized(self) {
            //将此对像提到最前面
            if(!proirDownloadList_)
            {
                proirDownloadList_ = [NSMutableArray new];
            }
        }
        @synchronized(proirDownloadList_) {
            //            NSMutableArray * removeList = [NSMutableArray new];
            VDCTempFileInfo * currentFile = nil;
            for(int i = 0;i<(int)proirDownloadList_.count;i++)
            {
                VDCTempFileInfo * fi  = proirDownloadList_[i];
                if(fi.offset <= offset && fi.lengthFull + fi.offset > offset)
                {
                    currentFile = fi;
                    break;
                }
                //                else if(fi.isDownloading==NO)
                //                {
                //                    [removeList addObject:fi];
                //                }
            }
            //            [proirDownloadList_ removeObjectsInArray:removeList];
            //            PP_RELEASE(removeList);
            if(currentFile)
            {
                //                [proirDownloadList_ removeObject:currentFile];
                //                [proirDownloadList_ insertObject:currentFile atIndex:0];
                return;
            }
            for (int i = 0; i<item.tempFileList.count; i++) {
                VDCTempFileInfo * fi = item.tempFileList[i];
                if(fi.offset <= offset && fi.offset + fi.lengthFull > offset && !fi.isDownloading)
                {
                    currentFile = fi;
                    break;
                }
            }
            
            if(!currentFile && offset < item.contentLength)
            {
                offset = [self getCorrectOffset:offset];
                
                UInt64 firstOffsetNeedCreate = 0;
                for (int j  = 0; j<(int)item.tempFileList.count; j++) {
                    VDCTempFileInfo * fi = item.tempFileList[j];
                    
                    UInt64 nextOffset = fi.offset + fi.length;
                    if(nextOffset > firstOffsetNeedCreate)
                    {
                        firstOffsetNeedCreate = nextOffset;
                    }
                }
                
                UInt64 maxOffset = MIN(item.contentLength,offset + prevCacheSize_);
                
                for (UInt64 itemOffset = firstOffsetNeedCreate; itemOffset < maxOffset; itemOffset += DEFAULT_PKSIZE) {
                    VDCTempFileInfo * fileToDownload = [self createTempFileByOffset:itemOffset item:item];
                    
                    if(fileToDownload && fileToDownload.lengthFull>0)
                    {
                        fileToDownload = [self addTempFileIntoList:item file:fileToDownload];
                        currentFile  = fileToDownload;
                    }
                }
            }
            if(currentFile)
            {
                //如果是边续的，则不能加在最前面
                if(proirDownloadList_.count>0)
                {
                    VDCTempFileInfo * existFile = [proirDownloadList_ firstObject];
                    VDCTempFileInfo * lastFile =[proirDownloadList_ lastObject];
                    //如果相邻
                    if(existFile.offset + existFile.lengthFull == currentFile.offset
                       ||
                       currentFile.offset + currentFile.lengthFull == existFile.offset)
                    {
                        [proirDownloadList_ addObject:existFile];
                    }
                    else if(lastFile.offset + lastFile.lengthFull == currentFile.offset
                            ||
                            currentFile.offset + currentFile.lengthFull == lastFile.offset)
                    {
                        [proirDownloadList_ addObject:existFile];
                    }
                    else
                    {
                        [proirDownloadList_ insertObject:currentFile atIndex:0];
                    }
                }
                else
                {
                    [proirDownloadList_ addObject:currentFile];
                }
            }
        }
        
        if(!item.isDownloading)
        {
            dispatch_async(downloadItemQueue_, ^(void)
                           {
                               [self startDownload:item urlReady:nil progress:nil completed:nil];
                           });
        }
    }
#ifndef __OPTIMIZE__
    NSLog(@" add main queue count:%ld",mainQueueItemCount);
    NSLog(@" add child queue count:%ld",childQueueItemCount);
#endif
}
- (void)checkProirDownloadList:(VDCItem *)item
{
    if(item.isAudioItem) return; //音频下载不受管理
    if(!proirDownloadList_) return;
    
    @synchronized(proirDownloadList_) {
        if(proirDownloadList_.count>0)
        {
            VDCTempFileInfo * fi = proirDownloadList_[0];
            if(![fi.parentItem.key isEqualToString:item.key])
            {
                [proirDownloadList_ removeAllObjects];
            }
            else
            {
                //#warning 测试一段时间后，如果没有问题，则移除此段 代码
                //#ifndef __OPTIMIZE__
                //                //将两者的对像统一，原则上不应该出现这种情况
                //                for (int i =0; i<(int)proirDownloadList_.count; i++) {
                //                    VDCTempFileInfo * fi = proirDownloadList_[i];
                //                    VDCTempFileInfo * tFi= nil;
                //                    BOOL hasFind = NO;
                //                    for (int j = 0; j<(int)item.tempFileList.count; j++) {
                //                        VDCTempFileInfo * cFi = item.tempFileList[j];
                //                        if(cFi.offset == fi.offset)
                //                        {
                //                            tFi = cFi;
                //                            hasFind = YES;
                //                            break;
                //                        }
                //                    }
                //                    if(hasFind && tFi)
                //                    {
                //                        if(tFi!=fi)
                //                        {
                //                            NSLog(@"proir downlist not match:%@ <--> %@",fi.fileName,tFi.fileName);
                //                            [proirDownloadList_ replaceObjectAtIndex:i withObject:tFi];
                //                        }
                //                    }
                //                }
                //#endif
            }
        }
    }
}
- (void)clearPriorDownloadList:(VDCItem *)item
{
    //    if(item && item.isAudioItem) return; //音频下载不受管理
    if(!proirDownloadList_) return;
    @synchronized(proirDownloadList_) {
        [proirDownloadList_ removeAllObjects];
    }
}
#pragma mark - download core
- (BOOL)downloadTempFile:(VDCTempFileInfo *)fileToDownload  urlReady:(videoUrlReady)urlready
                progress:(downloadProgress)progress
               completed:(downloadCompleted)completed
{
    if(!fileToDownload.parentItem) return NO;
    VDCItem * item = fileToDownload.parentItem;
    if(!item.tempFileList||item.tempFileList.count==0)
    {
        [self getTemFileList:item justCheckDownloading:NO];
    }
    VDCTempFileInfo * currentFile = nil;
    for (int i = 0; i<item.tempFileList.count; i++) {
        VDCTempFileInfo * fi = item.tempFileList[i];
        if(fi==fileToDownload || fi.offset == fileToDownload.offset)
        {
            currentFile = fi;
            break;
        }
    }
    if(currentFile && !currentFile.isDownloading)
    {
        [[HCFileManager manager]removeFileAtPath:currentFile.filePath];
        currentFile.length = 0;
        dispatch_async(downloadItemQueue_, ^(void)
                       {
                           if(currentFile.offset >prevCacheSize_)
                           {
                               [self downloadTempFileInThread:currentFile progress:nil];
                           }
                           else
                           {
                               [self startDownload:item urlReady:urlready progress:progress completed:completed];
                           }
                       });
        return YES;
    }
    return NO;
}
//第一次请求时，获取本地的URL，建立缓存数据
- (VDCItem *) addUrlCacheInThread:(VDCItem *)item urlReady:(videoUrlReady)urlReady completed:(downloadCompleted)dcompleted
{
#ifndef __OPTIMIZE__
    mainQueueItemCount +=1000000;
#endif
    
    dwnMsgTimer_.fireDate = [NSDate distantPast];
    [self rememberDownloadUrl:item tempPath:item.tempFilePath];
    
    __block BOOL isCalled = NO;
    
    VDCTempFileInfo * fi = [self getNextTempSlideToDown:item offset:0 minOffsetDownloading:nil];
    if(!fi)
    {
        //有可能创建的文件数不够
        fi = [self addNewTempFileAtLast:item];
    }
    
    __weak VDCItem * weakVDCItem = item;
    if([self isDataReady:item])
    {
        isCalled = YES;
        if(urlReady)
        {
            NSLog(@"change to local item:%@",item.localFilePath);
            item.readyCall = nil;
            [self callReadyBlock:item videoUrlReady:urlReady];
        }
        urlReady = nil;
    }
    
    videoUrlReady ready= nil;
    if(urlReady && !isCalled) ready = ^(VDCItem * vdcItem,NSURL * url)
    {
        if(urlReady && [self isDataReady:vdcItem])
        {
            isCalled = YES;
            NSLog(@"download call urlready ....OK");
            
            urlReady(vdcItem,url);
            vdcItem.readyCall = nil;
        }
        
    };
    
    downloadCompleted dc = ^(VDCItem * vdcItem,BOOL completed,VDCTempFileInfo * tempFile)
    {
        [self checkItemAudioFile:vdcItem audioUrl:nil];
        if(!isCalled)
        {
            //            NSLog(@"ready call ....%llu >= %llu",item.downloadBytes,PREV_CACHESIZE);
            if( urlReady && [self isDataReady:vdcItem])
            {
                isCalled = YES;
                NSLog(@"download call completed ....OK");
                [self callReadyBlock:vdcItem videoUrlReady:urlReady];
            }
        }
        
        if(dcompleted)
        {
            dcompleted(vdcItem,completed,tempFile);
        }
        vdcItem.downloadedCall = nil;
    };
    
    item.readyCall = ready;
    item.downloadedCall = dc;
    
    beginDateForSpeed_ = [NSDate date];
    
    //下载伴奏
    BOOL downloadAudio = !item.isAudioItem && item.AudioUrl && item.AudioUrl.length>10;
    if(downloadAudio)
    {
        if(item.AudioPath && item.AudioPath.length>2 && [[UDManager sharedUDManager]existFileAtPath:item.AudioPath])
        {
            downloadAudio = NO;
        }
    }
    if(downloadAudio)
    {
        NSLog(@"beginDownload audio....dispatch_async");
        dispatch_async(downloadItemQueue_, ^(void)
                       {
                           __strong VDCItem * strongItem = weakVDCItem;
                           downloadProgress progress = ^(VDCItem *vdcItem) {
                               [[NSNotificationCenter defaultCenter]postNotificationName:NT_CACHEPROGRESS object:vdcItem];
                           };
                           NSLog(@"beginDownload audio....called");
                           [self startDownloadAudio:strongItem urlReady:nil progress:progress completed:^(VDCItem * cItem,BOOL finished,VDCTempFileInfo * tempFile)
                            {
                                if(cItem.contentLength<=0 && strongItem.readyCall)
                                {
                                    //需要检查视频是否下载成功,
                                    NSString * audioUrl = item.AudioUrl;
                                    NSString * audioPath = item.AudioFileName;
                                    strongItem.AudioUrl = nil;
                                    strongItem.AudioFileName = nil;
                                    
                                    if([self isDataReady:item] && item.readyCall)
                                    {
                                        [self callReadyBlock:strongItem videoUrlReady:nil];
                                        item.readyCall = nil;
                                    }
                                    strongItem.AudioFileName = audioPath;
                                    strongItem.AudioUrl = audioUrl;
                                    
                                }
                            }];
                           strongItem =nil;
                       });
    }
    
    NSLog(@"beginDownload item....dispatch_async");
    dispatch_async(downloadItemQueue_, ^(void)
                   {
                       __strong VDCItem * strongItem = weakVDCItem;
                       NSLog(@"beginDownload item....called");
                       if(!strongItem.isAudioItem && strongItem.AudioUrl && strongItem.AudioUrl.length>10)
                       {
                           [self checkItemAudioFile:strongItem audioUrl:strongItem.AudioUrl];
                       }
                       
                       //如果已经下载完成，或者使用Loader管理器来下载
                       if(strongItem.downloadBytes >=strongItem.contentLength || [DeviceConfig IOSVersion]>=7.0)
                       {
                           
                           [self callReadyBlock:strongItem videoUrlReady:nil];
                           
                           if(strongItem.downloadBytes >=strongItem.contentLength && strongItem.downloadedCall)
                           {
                               strongItem.downloadedCall(weakVDCItem,YES,nil);
                           }
                       }
                       else
                       {
                           downloadProgress progress = ^(VDCItem *vdcItem) {
                               [[NSNotificationCenter defaultCenter]postNotificationName:NT_CACHEPROGRESS object:vdcItem];
                           };
                           [self startDownload:strongItem urlReady:nil progress:progress completed:nil];
                       }
                   });
    //    }
#ifndef __OPTIMIZE__
    mainQueueItemCount -=1000000;
#endif
    return item;
}
- (BOOL)callReadyBlock:(VDCItem *)item videoUrlReady:(videoUrlReady)ready
{
    NSURL * localUrl =  [NSURL URLWithString: item.localWebUrl];
    NSURL * remoteUrl = [NSURL URLWithString:item.remoteUrl];
    if(item.localFilePath && [HCFileManager isFileExistAndNotEmpty:item.localFilePath size:nil])
    {
        localUrl = [NSURL fileURLWithPath:item.localFilePath];
        remoteUrl = localUrl;
    }
    if(ready)
    {
        if([DeviceConfig IOSVersion]<7.0)
        {
            ready(item,localUrl);
        }
        else
        {
            ready(item,remoteUrl);
        }
        return YES;
    }
    else if(item.readyCall)
    {
        if([DeviceConfig IOSVersion]<7.0)
        {
            item.readyCall(item,localUrl);
        }
        else
        {
            //使用LoadRunner来处理
            item.readyCall(item,remoteUrl);
        }
        item.readyCall = nil;
        return YES;
    }
    
    return NO;
}
- (void)downloadUrlInQueue:(VDCItem *)item urlReady:(videoUrlReady)urlReady progress:(downloadProgress)progress completed:(downloadCompleted)completed
{
#ifndef __OPTIMIZE__
    mainQueueItemCount +=100000000;
#endif
    dwnMsgTimer_.fireDate = [NSDate distantPast];
    [self resetLastDownloadTime:item];
    [self rememberDownloadUrl:item tempPath:item.tempFilePath];
    
    VDCTempFileInfo * fi = [self getNextTempSlideToDown:item offset:0 minOffsetDownloading:nil];
    if(!fi)
    {
        //有可能创建的文件数不够
        fi = [self addNewTempFileAtLast:item];
    }
    
    downloadCompleted dc = ^(VDCItem * vdcItem,BOOL isCompleted,VDCTempFileInfo * tempFile)
    {
        [self checkItemAudioFile:vdcItem audioUrl:nil];
        if(vdcItem.downloadBytes >= vdcItem.contentLength && vdcItem.contentLength>0)
        {
            if(completed)
            {
                completed(vdcItem,isCompleted,tempFile);
            }
        }
        else if(completed)
        {
            completed(vdcItem,isCompleted,tempFile);
        }
    };
    
    //      //已经在前面调用了
    //        item.readyCall = urlReady;
    item.downloadedCall = dc;
    item.progressCall = progress;
    
    beginDateForSpeed_ = [NSDate date];
    
    __weak VDCItem * weakVDCItem = item;
    //下载伴奏
    if(!item.isAudioItem && item.AudioUrl && item.AudioUrl.length>10)
    {
        dispatch_async(downloadItemQueue_, ^(void)
                       {
                           [self startDownloadAudio:weakVDCItem urlReady:nil progress:nil completed:nil];
                       });
    }
    dispatch_async(downloadItemQueue_, ^(void)
                   {
                       if(!weakVDCItem.isAudioItem && weakVDCItem.AudioUrl && weakVDCItem.AudioUrl.length>10)
                       {
                           [self checkItemAudioFile:weakVDCItem audioUrl:weakVDCItem.AudioUrl];
                       }
                       [self startDownload:weakVDCItem urlReady:nil progress:nil completed:nil];
                   });
#ifndef __OPTIMIZE__
    mainQueueItemCount -=100000000;
#endif
}
#pragma mark - download one file
- (BOOL)hasFileDownload:(VDCItem *)item
{
    BOOL ret = NO;
    if(item && item.tempFileList)
    {
        @synchronized(item) {
            for (int i = 0;i<item.tempFileList.count;i++){
                VDCTempFileInfo * fi = item.tempFileList[i];
                if(fi.isDownloading)
                {
                    ret = YES;
                    break;
                }
            }
        }
    }
    return ret;
}
- (BOOL)hasFileNeedDownload:(VDCItem *)item
{
    BOOL ret = NO;
    if(item && item.tempFileList)
    {
        @synchronized(item) {
            for (int i = 0;i<item.tempFileList.count;i++){
                VDCTempFileInfo * fi = item.tempFileList[i];
                if(fi.lengthFull > fi.length)
                {
                    ret = YES;
                    break;
                }
            }
        }
    }
    return ret;
}
- (void)startDownloadAudio:(VDCItem *)item urlReady:(videoUrlReady)urlReady progress:(downloadProgress)progress
                 completed:(downloadCompleted)dcompleted
{
    if(!item) return;
    NSString * key = [self getRemoteFileCacheKey:item.AudioUrl];
    VDCItem * audioItem = nil;
    if([item.key isEqualToString:key])
    {
        audioItem = item;
    }
    else
    {
        NSString * title = nil;
        if(item.title && item.title.length>0)
        {
            if(item.MTVID>0)
            {
                title = [NSString stringWithFormat:@"%@(录音)",item.title];
            }
            else
            {
                title = [NSString stringWithFormat:@"%@(导唱)",item.title];
            }
        }
        
        audioItem = [self getAudioItemByUrl:item.AudioUrl title:title];
    }
    audioItem.isAudioItem = YES;
    audioItem.needStop = NO;
    NSLog(@"DOWN %@ .....",item.title);
    if(!audioItem.isCheckedFiles || audioItem.contentLength<=0)
        [self checkItemFile:audioItem removePartFile:YES];
    
    if(audioItem.contentLength <=0)
    {
        if(dcompleted)
        {
            dcompleted(audioItem,NO,nil);
        }
    }
    else
    {
        [self startDownload:audioItem urlReady:urlReady progress:progress completed:dcompleted];
    }
}
- (void)startDownload:(VDCItem *)item urlReady:(videoUrlReady)urlReady
             progress:(downloadProgress)progress
            completed:(downloadCompleted)dcompleted
{
    if(!item) return;
    
    //检查优先下载队列
    //    [self checkProirDownloadList:item];
    
#ifndef __OPTIMIZE__
    mainQueueItemCount +=10000000000;
#endif
    BOOL isDownloadCompleted = NO;
    if(item.isDownloading == YES)
    {
        if([self ensureDownloading:item]>0)
        {
            NSLog(@"DOWN not entry twice.");
#ifndef __OPTIMIZE__
            mainQueueItemCount -=10000000000;
#endif
            return;
        }
        else
        {
            item.isDownloading = NO;
        }
    }
    else
    {
        VDCItem * testItem = [self getVDCItem:item.key];
        if(testItem && testItem!=item && testItem.isDownloading)
        {
            if([self ensureDownloading:testItem]>0)
            {
                NSLog(@"DOWN not entry twice.");
#ifndef __OPTIMIZE__
                mainQueueItemCount -=10000000000;
#endif
                return;
            }
            else
            {
                testItem.isDownloading = NO;
            }
        }
        else
        {
            if ([self isItemDownloadCompleted:testItem]) {
                if(testItem.downloadedCall)
                {
                    testItem.downloadedCall(testItem,YES,nil);
                }
                else if(dcompleted)
                {
                    dcompleted(testItem,YES,nil);
                }
                
                return;
            }
        }
    }
    if(item.contentLength<500)
    {
        item.contentLength = 0;
        item.downloadBytes = 0;
        
        if(item.tempFilePath && item.tempFilePath.length>3)
            item.contentLength = [self getContentLengthByFile:item.tempFilePath];
        
        if(item.contentLength <=0 && item.remoteUrl && item.remoteUrl.length>0)
        {
            NSInteger len = [self getContentLengthByUrl:item.remoteUrl];
            if(len >= 0)
                item.contentLength = len;
        }
        if(item.contentLength<=0)
        {
            if(item.downloadedCall)
            {
                item.downloadedCall(item,NO,nil);
            }
            else if(dcompleted)
            {
                dcompleted(item,NO,nil);
            }
            return;
        }
    }
    [self clearPriorDownloadList:item];
    
    if(needCancelLocalWebRequest)
    {
#ifndef __OPTIMIZE__
        mainQueueItemCount -=10000000000;
        NSLog(@"downloading.(%@)...broken.",[item.localFilePath lastPathComponent]);
#endif
        if(item.downloadedCall)
        {
            item.downloadedCall(item,NO,nil);
        }
        else if(dcompleted)
        {
            dcompleted(item,NO,nil);
        }
        return;
    }
    NSLog(@"DOWN %@ .....",item.title);
    NSLog(@"DOWN BG... %@",[item.localFilePath lastPathComponent]);
    item.isDownloading = YES;
    BOOL isCalled = NO;
    BOOL needBreakall = NO;
    //第一次将ticks置为0
    item.ticks = 0;
    UInt64 lastoffset = 0;
    while (!needBreakall) {
        while (!isDownloadCompleted) {
            if(needCancelLocalWebRequest || item.needStop)
            {
                NSLog(@"DOWN (%@)...broken.",[item.localFilePath lastPathComponent]);
                needBreakall = YES;
                break;
            }
            //当前几个节的数据没有拿到时，只使用双线程，而后再使用多线程
            //            @synchronized(self) {
            if(isSomeOneDownloading >= threadCount_)
            {
                [NSThread sleepForTimeInterval:0.1];
                if(needCancelLocalWebRequest)
                {
                    needBreakall = YES;
                    break;
                }
                continue;
            }
            //            }
            
            //表明有一个已经下载完成了
            if(!isCalled && [self isDataReady:item])
            {
                isCalled = YES;
                if(item.readyCall)
                {
                    item.readyCall(item,[NSURL URLWithString:item.localWebUrl]);
                    item.readyCall = nil;
                }
            }
            //        while (isSomeOneDownloading>=threadCount_) {
            //            [NSThread sleepForTimeInterval:0.1];
            //            if(needCancelLocalWebRequest) break;
            //            continue;
            //        }
            NSLog(@"DOWN (%@)...in queue.",[item.localFilePath lastPathComponent]);
            if ([DeviceConfig config].networkStatus == ReachableNone) {
                [NSThread sleepForTimeInterval:0.5];
                if(needCancelLocalWebRequest)
                {
                    needBreakall = YES;
                    break;
                }
                continue;
            }
            if(needCancelLocalWebRequest)
            {
                needBreakall = YES;
                break;
            }
            //download next item
            UInt64 miniOffset =UINT64_MAX;
            VDCTempFileInfo * fileToDownload = [self getNextTempSlideToDown:item offset:lastoffset minOffsetDownloading:&miniOffset];
            
            //如果没有找到需要下载的数据
            if(!fileToDownload && item.downloadBytes < item.contentLength && item.contentLength>0)
            {
                if(!fileToDownload)
                {
                    lastoffset = 0;
                }
                //添加一个新的下载对像
                fileToDownload = [self createTempFileByOffset:[self getNextOffsetNotDownload:item maxOffset:lastoffset] item:item];
                if(fileToDownload && fileToDownload.lengthFull>0)
                {
                    fileToDownload = [self addTempFileIntoList:item file:fileToDownload];
                }
                else if(!fileToDownload) //往后找没有了，那么从头开始，看有没有
                {
                    fileToDownload = [self getNextTempSlideToDown:item offset:0 minOffsetDownloading:&miniOffset];
                }
            }
            if(fileToDownload)
                lastoffset = fileToDownload.offset;
            
            //前面的包没有下载完成时，不允许下载后面的包
            if(!isCalled &&fileToDownload && fileToDownload.offset > prevCacheSize_*2)
            {
                NSLog(@"DOWN  WAIT FOR FP,CANL :%@",fileToDownload.fileName);
                [NSThread sleepForTimeInterval:0.2];
                continue;
            }
            if(!fileToDownload)
            {
                NSLog(@"DOWN.(%@)...no files to download.",[item.localFilePath lastPathComponent]);
                //check is download completed
                if(![self hasFileDownload:item])
                {
                    [self clearPriorDownloadList:item];
                    
                    if([self hasFileNeedDownload:item])
                    {
                        isDownloadCompleted = NO;
                    }
                    else
                    {
                        isDownloadCompleted = YES;
                        break;
                    }
                }
            }
            else
            {
                NSLog(@"**** DOWN..(%@)",fileToDownload.fileName);
                //检查，不允许中间有包没有下载完成，就拼命下载后面的包，距离差距为最小缓冲区
                long long diff = fileToDownload.offset <= prevCacheSize_ *4 ?0: fileToDownload.offset - prevCacheSize_ *4;
                if(miniOffset >0 && miniOffset < diff)
                {
                    NSLog(@"DOWN. tooo,cancel item:%@",fileToDownload.fileName);
                    NSLog(@"%llu < %llu - %d = %llu",miniOffset,fileToDownload.offset,prevCacheSize_ * 4,diff);
                    [NSThread sleepForTimeInterval:0.2];
                    continue;
                }
            }
            if(fileToDownload.parentItem.needStop)
            {
                NSLog(@"DOWN.(%@)...broken.",[item.localFilePath lastPathComponent]);
                needBreakall = YES;
                break;
            }
            if(needCancelLocalWebRequest)
            {
                needBreakall = YES;
                break;
            }
            if(item.downloadBytes==0 && fileToDownload.offset > 0)
            {
                for (int i = 0;i<item.tempFileList.count; i++) {
                    VDCTempFileInfo * fi = item.tempFileList[i];
                    item.downloadBytes += fi.length;
                }
                //            for (VDCTempFileInfo * fi in item.tempFileList) {
                //                item.downloadBytes += fi.length;
                //            }
            }
            if(fileToDownload.lengthFull>0 && (fileToDownload.offset < item.contentLength || item.contentLength<=0))
            {
                [self downloadTempFileInThread:fileToDownload
                 //                                  urlReady:nil
                                      progress:progress
                 //                                 completed:nil
                 ];
            }
            else
            {
                [NSThread sleepForTimeInterval:0.2];
            }
        }
        item.isDownloading = NO;
        if(item.downloadBytes < item.contentLength && !needCancelLocalWebRequest && !item.needStop)
        {
            item.downloadBytes = 0;
            for (int i = 0; i<item.tempFileList.count; i++) {
                VDCTempFileInfo * fi = item.tempFileList[i];
                item.downloadBytes += fi.length;
            }
            //        for (VDCTempFileInfo * fi in item.tempFileList) {
            //            item.downloadBytes += fi.length;
            //        }
        }
        if(item.downloadBytes>=item.contentLength && item.contentLength > 0)
        {
            BOOL ret = NO;
            if(item.tempFileList && item.tempFileList.count>0)
            {
                ret = [self combinateTempFiles:item tempFilePath:item.tempFilePath targetFilePath:item.localFilePath];
            }
            else
            {
//                NSString * newPath = nil;
//                ret = [[UDManager sharedUDManager]isFileExistAndNotEmpty:item.localFilePath size:nil pathAlter:&newPath];
//                if(ret && newPath && newPath.length>0)
//                {
//                    item.localFilePath = newPath;
//                }
            }
            if(ret)
            {
                UInt64 size = 0;
                if([[UDManager sharedUDManager]isFileExistAndNotEmpty:item.localFilePath size:&size pathAlter:nil])
                {
                    if(size != item.contentLength) //文件有问题
                    {
                        NSLog(@"DOWN size not match(%llu-----%llu)",size,item.contentLength);
                        [[HCFileManager manager]removeFileAtPath:item.localFilePath];
                        item.isCheckedFiles = NO;
                        
                        [self checkItemFile:item removePartFile:YES];
                        [self rememberDownloadUrl:item tempPath:item.tempFilePath];
                        
                        isDownloadCompleted = NO;
                        item.isDownloading = YES;
                        ret = NO;
                        continue;
                    }
                }
                else
                {
                    ret = NO;
                }
            }
            if(!ret)
            {
                item.downloadBytes = 0;
                for (int i = 0;i<item.tempFileList.count;i++) {
                    VDCTempFileInfo * fi = item.tempFileList[i];
                    item.downloadBytes += fi.length;
                }
                isSomeOneDownloading = 0;
                item.isDownloading = NO;
                [self rememberDownloadUrl:item tempPath:item.tempFilePath];
                continue;
            }
            if(item.downloadedCall)
            {
                item.downloadedCall(item,TRUE,nil);
            }
            else if(dcompleted)
            {
                dcompleted(item,TRUE,nil);
            }
            needBreakall = YES;
            break;
        }
        else
        {
            
            if(item.downloadedCall)
            {
                item.downloadedCall(item,NO,nil);
            }
            else if(dcompleted)
            {
                dcompleted(item,NO,nil);
            }
            needBreakall = YES;
            break;
        }
    }
    isSomeOneDownloading = 0;
    item.isDownloading = NO;
    [self rememberDownloadUrl:item tempPath:item.tempFilePath];
    NSLog(@"**--- DOWN %@ ---- OK(%@)",item.title?item.title:item.remoteUrl,item.contentLength <= item.downloadBytes?@"Completed":@"break");
#ifndef __OPTIMIZE__
    mainQueueItemCount -=10000000000;
#endif
}

- (BOOL)isItemDownloadCompleted:(VDCItem *)item
{
    if(!item) return NO;
    @synchronized(item) {
        if (item.downloadBytes >= item.contentLength)
        {
//            NSString * newPath = nil;
            UInt64 size = 0;
            BOOL ret = [[UDManager sharedUDManager]isFileExistAndNotEmpty:item.localFilePath size:&size];
            if(ret)
            {
                if(size== item.contentLength && item.contentLength>0)
                {
//                    if(newPath && newPath!=item.localFilePath)
//                    {
//                        item.localFilePath = newPath;
//                    }
                    return YES;
                }
            }
        }
        return NO;
    }
}
- (UInt64) getCorrectOffset:(UInt64)offset
{
    if(offset % DEFAULT_PKSIZE !=0)
    {
        UInt64 multiX = offset /DEFAULT_PKSIZE;
        offset = multiX * DEFAULT_PKSIZE;
    }
    return offset;
}
- (UInt64)getNextOffsetNotDownload:(VDCItem *)item maxOffset:(UInt64)maxOffset
{
    //    UInt64 maxOffset = 0;
    //纠正Offset
    
    //    if(proirDownloadList_ && proirDownloadList_.count>0)
    //    {
    //        for (int i = 0; i< (int)proirDownloadList_.count; i ++) {
    //            VDCTempFileInfo * fi = proirDownloadList_[i];
    //            if(fi.offset >= maxOffset && fi.lengthFull > fi.length && fi.lengthFull>0 && (fi.isDownloading==NO))
    //            {
    //                maxOffset = fi.offset;
    //                break;
    //            }
    //        }
    //    }
    //    if(maxOffset==0)
    //    {
    
    for (int i = 0; i<item.tempFileList.count; i++) {
        VDCTempFileInfo * fi = [item.tempFileList objectAtIndex:i];
        if(fi.offset + fi.lengthFull > maxOffset && fi.length < fi.lengthFull)
        {
            //            maxOffset = fi.offset + fi.lengthFull;
            break;
        }
        else
        {
            maxOffset = fi.offset + fi.lengthFull;
        }
    }
    //    }
    return maxOffset;
}



//- (void)downloadTempFileInThreadN:(VDCTempFileInfo *)fileToDownload
////                        urlReady:(videoUrlReady)urlready
//                         progress:(downloadProgress)progress
////                       completed:(downloadCompleted)completed
//{
//    //    __block BOOL isCalled = NO; //是否调用了Completed
//
//    if(!fileToDownload || !fileToDownload.parentItem)
//    {
//        NSLog(@"downloading VDCTempFileInfo data error:%@",fileToDownload.fileName);
//        return;
//    }
//    if(needCancelLocalWebRequest)
//    {
//        NSLog(@"downloading :%@(%llu-%llu) cancelled by user",fileToDownload.fileName,fileToDownload.offset,fileToDownload.lengthFull);
//        return;
//    }
//    BOOL needReturn = (([fileToDownload isDownloadWithOperation]) || (fileToDownload.length>=fileToDownload.lengthFull));
//    NSLog(@"downloading :%@(%llu-%llu(%llu)) ready to down needreturn:%d",fileToDownload.fileName,fileToDownload.offset,fileToDownload.lengthFull,fileToDownload.length,needReturn);
//    if(needReturn) return;
//    @synchronized(self) {
//        if(isSomeOneDownloading>=threadCount_)
//        {
//            //        dispatch_time_t nextTime = dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC);// 页面刷新的时间基数
//            //        dispatch_after(nextTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
//            //                       {
//            //                            NSLog(@"fetch 0.2s next to download:%@(%llu-%llu)",fileToDownload.fileName,fileToDownload.offset,fileToDownload.lengthFull);
//            //                           [self downloadTempFileInThread:fileToDownload urlReady:urlready completed:completed];
//            //                       });
//            return;
//        }
//
//        isSomeOneDownloading ++;
//    }
//    if(fileToDownload.length> fileToDownload.offset)
//    {
//        NSLog(@"downloading :%llu get the content more....",fileToDownload.offset);
//    }
//
//    __weak VDCItem * weakVDCItem = fileToDownload.parentItem;
//
//    __block UInt64 length = fileToDownload.lengthFull - fileToDownload.length;
//
//
//    NSString * requestRange = [self getRequestRange:fileToDownload];
//
//
//    NSString * urlString = [weakVDCItem.remoteUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
//    //    NSString * urlString = [weakVDCItem.remoteUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//
//    if(config_.SysVersion >=8 && fileToDownload.changeUrlTicks==NO)
//    {
//        urlString  = [NSString stringWithFormat:@"%@?t=%li",urlString,weakVDCItem.ticks];
//    }
//    else
//    {
//        weakVDCItem.ticks = [CommonUtil getDateTicks:[NSDate date]];
//        urlString  = [NSString stringWithFormat:@"%@?t=%li",urlString,weakVDCItem.ticks];
//        fileToDownload.changeUrlTicks = NO;
//    }
//    fileToDownload.changeUrlTicks = NO;
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
//    [request setValue:requestRange forHTTPHeaderField:@"Range"];
//    [request setValue:@"http://maiba.seenvoice.com" forHTTPHeaderField:@"Referer"];
//    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;//不使用缓存
//    request.timeoutInterval = 20;
//    //    AFHTTPSessionManager
//    //    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    //    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
//
//    //    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:completedBlock failure:failureBlock];
//
//    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:[request copy]];
//    operation.inputStream =  [NSInputStream inputStreamWithURL:request.URL];
//    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:fileToDownload.filePath append:YES];
//    operation.responseSerializer = [[AFHTTPResponseSerializer alloc]init];
//
//    //如果正在下载，则返回
//    if([fileToDownload isDownloadWithOperation]) return;
//
//    NSLog(@"downloading file:%@,range:%@",[weakVDCItem.remoteUrl lastPathComponent],requestRange);
//
//    fileToDownload.operation = operation;
//    fileToDownload.isDownloading = YES;
//
//    //如果文件存在，需检查大小对不
//    if([self checkIsDownloadOK:fileToDownload])
//    {
//        [fileToDownload cancelOperation];
//
//        isSomeOneDownloading --;
//        //        if(completed)
//        //       {
//        //           completed(weakVDCItem,TRUE,fileToDownload);
//        //       }
//        return;
//    }
//
//    [self addToDownloadList:fileToDownload];
//
//    //下载进度回调
//    __weak typeof(operation) weakOp = operation;
//
//    requestProgressBlock progressBlock = ^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
//
//        fileToDownload.isDownloading = YES;
//
//        if(weakVDCItem.contentLength <=0)
//        {
//            [self parseContentLengthFromResponse:weakVDCItem headerFields:weakOp.response.allHeaderFields];
//            if(weakVDCItem.contentLength>0)
//            {
//                length = DEFAULT_PKSIZE;
//            }
//            NSLog(@"downloading contentlength:%llu",weakVDCItem.contentLength);
//        }
//
//        //下载进度
//        fileToDownload.length += bytesRead;
//        fileToDownload.parentItem.downloadBytes += bytesRead;
//        if(fileToDownload.length < bytesRead+1000)
//        {
//            NSLog(@"downloading file (%@) -- (%d/%d)",[fileToDownload.fileName lastPathComponent],fileToDownload.length,fileToDownload.lengthFull);
//        }
//        if(progress)
//        {
//            progress(weakVDCItem);
//        }
//        else if(weakVDCItem.progressCall)
//        {
//            weakVDCItem.progressCall(weakVDCItem);
//        }
//        [self setPostMsg:@"正在下载MTV" bytesRead:bytesRead];
//
//
//        //人工移除下载
//        if([self needStopLocalWebRequest:nil])
//        {
//            [weakOp cancel];
//        }
//    };
//    requestCompletedBlock completedBlock = ^(AFHTTPRequestOperation *operation, id responseObject) {
//        if(![self checkIsDownloadOK:fileToDownload])
//        {
//            NSLog(@"downloading why part(%@) (%@)(%llu)） of data:%d<-->%d",weakVDCItem.remoteUrl,requestRange,
//                  fileToDownload.offset,
//                  fileToDownload.length,fileToDownload.lengthFull)
//
//            [self setPostMsg:@"MTV缓存时长度错误" bytesRead:-1];
//
//            [self postCaching:nil];
//
//            if(operation.isCancelled==NO)
//            {
//                [[UDManager sharedUDManager]removeFileAtPath:fileToDownload.filePath];
//                fileToDownload.length=0;
//                fileToDownload.changeUrlTicks = YES;
//
//                //                [[NSNotificationCenter defaultCenter]postNotificationName:@"DOWNLOADERROR" object:[fileToDownload.parentItem.removeUrl copy]];
//            }
//        }
//        else
//        {
//            NSLog(@"downloading file:%@ download completed. operation:%p",fileToDownload.fileName,fileToDownload.operation);
//        }
//
//        [fileToDownload cancelOperation];
//
//        [self removeFromDownloadList:fileToDownload];
//
//        isSomeOneDownloading --;
//    };
//
//    requestCompletedfailure failureBlock =^(AFHTTPRequestOperation *operation, NSError *error) {
//
//        //        [self getTemFileList:weakVDCItem justCheckDownloading:YES];
//
//        [fileToDownload cancelOperation];
//
//        [self removeFromDownloadList:fileToDownload];
//        if(operation.isCancelled==NO)
//        {
//            [[UDManager sharedUDManager]removeFileAtPath:fileToDownload.filePath];
//            fileToDownload.length=0;
//            fileToDownload.changeUrlTicks = YES;
//            //                [[NSNotificationCenter defaultCenter]postNotificationName:@"DOWNLOADERROR" object:[fileToDownload.parentItem.removeUrl copy]];
//        }
//        NSLog(@"downloading file %@ download failure code:[%ld]:%@ operation:%p",fileToDownload.fileName,operation.response.statusCode,[error description],fileToDownload.operation);
//
//        if(error.code == -1009) //no network
//        {
//            [self setPostMsg:@"网络联接中断" bytesRead:-4];
//        }
//        else
//        {
//            [self setPostMsg:@"MTV缓存下载时发生错误"bytesRead:-4];
//        }
//        //        if(completed)
//        //        {
//        //            completed(weakVDCItem,NO,fileToDownload);
//        //        }
//        isSomeOneDownloading --;
//    };
//
//    [operation setDownloadProgressBlock:progressBlock];
//    [operation setCompletionBlockWithSuccess:completedBlock failure:failureBlock];
//    [operation start];
//}

- (void)downloadTempFileInThread:(VDCTempFileInfo *)fileToDownload
//                        urlReady:(videoUrlReady)urlready
                        progress:(downloadProgress)progress
//                       completed:(downloadCompleted)completed
{
    //    __block BOOL isCalled = NO; //是否调用了Completed
    
    if(!fileToDownload || !fileToDownload.parentItem)
    {
        NSLog(@"downloading VDCTempFileInfo data error:%@",fileToDownload.fileName);
        return;
    }
    if(needCancelLocalWebRequest)
    {
        NSLog(@"downloading :%@(%llu-%llu) cancelled by user",fileToDownload.fileName,fileToDownload.offset,fileToDownload.lengthFull);
        return;
    }
    BOOL needReturn = (([fileToDownload isDownloadWithOperation]) || (fileToDownload.length>=fileToDownload.lengthFull));
    NSLog(@"downloading :%@(%llu-%llu(%llu)) ready to down needreturn:%d",fileToDownload.fileName,fileToDownload.offset,fileToDownload.lengthFull,fileToDownload.length,needReturn);
    if(needReturn) return;
    
    @synchronized(self) {
        if(isSomeOneDownloading>=threadCount_)
        {
            return;
        }
        
        isSomeOneDownloading ++;
    }
#ifndef __OPTIMIZE__
    childQueueItemCount ++;
    NSLog(@" add child queue count:%ld",childQueueItemCount);
#endif
    //    if(fileToDownload.length> fileToDownload.offset)
    //    {
    //        NSLog(@"downloading :%llu get the content more....",fileToDownload.offset);
    //    }
    
    __weak VDCItem * weakVDCItem = fileToDownload.parentItem;
    
    __block UInt64 length = fileToDownload.lengthFull - fileToDownload.length;
    
    
    NSString * requestRange = [self getRequestRange:fileToDownload];
    
    
    NSString * urlString = [weakVDCItem.remoteUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    //    NSString * urlString = [weakVDCItem.remoteUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    if(/*config_.SysVersion >=8 &&*/ fileToDownload.changeUrlTicks==NO)
    {
        if(weakVDCItem.ticks>0)
        {
            urlString  = [NSString stringWithFormat:@"%@?t=%li",urlString,weakVDCItem.ticks];
        }
    }
    else
    {
        weakVDCItem.ticks = [CommonUtil getDateTicks:[NSDate date]];
        urlString  = [NSString stringWithFormat:@"%@?t=%li",urlString,weakVDCItem.ticks];
        fileToDownload.changeUrlTicks = NO;
    }
    fileToDownload.changeUrlTicks = NO;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setValue:requestRange forHTTPHeaderField:@"Range"];
    [request setValue:@"http://maiba.seenvoice.com" forHTTPHeaderField:@"Referer"];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;//不使用缓存
    request.timeoutInterval = 20;
    
    //如果正在下载，则返回
    if([fileToDownload isDownloadWithOperation])
    {
        PP_RELEASE(request);
#ifndef __OPTIMIZE__
        childQueueItemCount --;
        NSLog(@" dec child queue count:%ld",childQueueItemCount);
#endif
        return;
    }
    
    HXNetwork * operation = [[HXNetwork alloc]initWithRequest:request outputfile:fileToDownload.filePath];
    
    NSLog(@"DOWN:%@,range:%@",[weakVDCItem.remoteUrl lastPathComponent],requestRange);
    
    fileToDownload.operationNew = operation;
    fileToDownload.isDownloading = YES;
    
    //如果文件存在，需检查大小对不
    if([self checkIsDownloadOK:fileToDownload])
    {
        [fileToDownload cancelOperation];
        isSomeOneDownloading --;
        //        if(completed)
        //       {
        //           completed(weakVDCItem,TRUE,fileToDownload);
        //       }
#ifndef __OPTIMIZE__
        childQueueItemCount --;
        NSLog(@" dec child queue count:%ld",childQueueItemCount);
#endif
        return;
    }
    
    [self addToDownloadList:fileToDownload];
    
    //下载进度回调
    __weak typeof(operation) weakOp = operation;
    
    downloadProgressBlock_t progressBlock = ^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        
        fileToDownload.isDownloading = YES;
        
        if(weakVDCItem.contentLength <=0)
        {
            [self parseContentLengthFromResponse:weakVDCItem headerFields:weakOp.response.allHeaderFields];
            if(weakVDCItem.contentLength>0)
            {
                length = DEFAULT_PKSIZE;
            }
            NSLog(@"DOWN contentlength:%llu",weakVDCItem.contentLength);
        }
        
        //下载进度
        fileToDownload.length += bytesRead;
        fileToDownload.parentItem.downloadBytes += bytesRead;
        if(fileToDownload.length < bytesRead+1000)
        {
            NSLog(@"DOWN (%@) -- (%llu/%llu)",[fileToDownload.fileName lastPathComponent],fileToDownload.length,fileToDownload.lengthFull);
        }
        if(progress)
        {
            progress(weakVDCItem);
        }
        else if(weakVDCItem.progressCall)
        {
            weakVDCItem.progressCall(weakVDCItem);
        }
        else
        {
            [[NSNotificationCenter defaultCenter]postNotificationName:NT_CACHEPROGRESS object:weakVDCItem];
        }
        [self setPostMsg:@"正在下载MTV" bytesRead:bytesRead];
        
        
        //人工移除下载
        if([self needStopLocalWebRequest:nil])
        {
            [weakOp cancel];
        }
    };
    completionDataBlock_t completedBlock = ^(HXNetwork *operation, id responseObject) {
        if(![self checkIsDownloadOK:fileToDownload])
        {
            NSLog(@"downloading why part(%@) (%@)(%llu)） of data:%llu<-->%llu",weakVDCItem.remoteUrl,requestRange,
                  fileToDownload.offset,
                  fileToDownload.length,fileToDownload.lengthFull);
            
            [self setPostMsg:@"MTV缓存时长度错误" bytesRead:-1];
            
            [self postCaching:nil];
            
            //            if(operation.isCancelled==NO)
            //            {
            [[HCFileManager manager]removeFileAtPath:fileToDownload.filePath];
            fileToDownload.length=0;
            fileToDownload.changeUrlTicks = YES;
            
            //            }
        }
        else
        {
            NSLog(@"DOWN:%@ download completed. operation:%p",fileToDownload.fileName,fileToDownload.operationNew);
        }
        
        [fileToDownload cancelOperation];
        
        [self removeFromDownloadList:fileToDownload];
        isSomeOneDownloading --;
    };
    
    completionWithError_t failureBlock =^(HXNetwork *operation, NSError *error) {
        
        //        [self getTemFileList:weakVDCItem justCheckDownloading:YES];
        
        [fileToDownload cancelOperation];
        
        [self removeFromDownloadList:fileToDownload];
        //        if(operation.isCancelled==NO)
        //        {
        [[HCFileManager manager]removeFileAtPath:fileToDownload.filePath];
        fileToDownload.length=0;
        fileToDownload.changeUrlTicks = YES;
        //                [[NSNotificationCenter defaultCenter]postNotificationName:@"DOWNLOADERROR" object:[fileToDownload.parentItem.removeUrl copy]];
        //        }
        NSLog(@"DOWN %@ FAIL:[%ld]:%@ operation:%p",fileToDownload.fileName,(long)operation.response.statusCode,[error description],fileToDownload.operationNew);
        
        if(error.code == -1009) //no network
        {
            [self setPostMsg:@"网络联接中断" bytesRead:-4];
        }
        else if(error.code == -1000)
        {
            [self setPostMsg:@"用户停止缓存" bytesRead:-4];
        }
        else
        {
            [self setPostMsg:@"MTV缓存下载时发生错误"bytesRead:-4];
        }
        //        if(completed)
        //        {
        //            completed(weakVDCItem,NO,fileToDownload);
        //        }
        isSomeOneDownloading --;
    };
    
    [operation setDownloadProgressBlock:progressBlock];
    [operation setCompletionDataBlock:completedBlock];
    [operation setCompletionWithError:failureBlock];
    //    [operation setCompletionBlockWithSuccess:completedBlock failure:failureBlock];
    [operation start];
#ifndef __OPTIMIZE__
    childQueueItemCount --;
    NSLog(@" dec child queue count:%ld",childQueueItemCount);
#endif
}
#pragma mark - helper
- (void)parseContentLengthFromResponse:(VDCItem *)item headerFields:(NSDictionary*)allHeaderFields
{
    NSString * cr = [allHeaderFields objectForKey:@"Content-Range"];
    if(cr){
        NSString * cl = [cr stringByMatching:@"\\d+$"];
        if(cl)
        {
            item.contentLength = (NSInteger)[cl longLongValue];
        }
    }
    else
    {
        cr = [allHeaderFields objectForKey:@"Content-Length"];
        if(cr)
        {
            item.contentLength = (NSInteger)[cr longLongValue];
        }
    }
    
    if(item.contentLength>0)
    {
        [self rememberContentLength:item.contentLength tempPath:item.tempFilePath];
    }
    NSLog(@"current item contentlength:%llu",item.contentLength);
}

- (NSString *)getRequestRange:(VDCTempFileInfo *)file
{
    NSString *requestRange = nil;
    VDCItem * item = file.parentItem;
    UInt64 offset = file.offset + file.length;
    UInt64 length = MAX(file.lengthFull - file.length,0);
    
    if(item.contentLength <=0)
    {
        
        //        UInt64 end = MAX(offset + length-1,0); //要减去1个边界，不然，个数不对‘
        UInt64 end = offset + DEFAULT_PKSIZE -1;
        if(end > offset)
        {
            requestRange = [NSString stringWithFormat:@"bytes=%llu-%llu", offset,end];
        }
        else
        {
            requestRange = [NSString stringWithFormat:@"bytes=%llu-", offset];
        }
        length = 0;
        
    }
    else
    {
        UInt64 end = MIN(item.contentLength  -1, offset+length -1);
        if(end>=offset)
        {
            requestRange = [NSString stringWithFormat:@"bytes=%llu-%llu", offset,end]; //要减去1个边界，不然，个数不对
        }
        else
        {
            requestRange = [NSString stringWithFormat:@"bytes=%llu-", offset];
            length = 0;
        }
    }
    //    requestRange = [NSString stringWithFormat:@"bytes=%llu-", offset];
    return requestRange;
}
- (BOOL)checkIsDownloadOK:(VDCTempFileInfo *)fileToDownload
{
    //    @synchronized(self) {
    //        如果文件长度不对，但显示完成了，说明是CDN服务器发出了错误的数据，该如何处理？
    if(fileToDownload.length==0 || fileToDownload.isDownloading == NO)
    {
        NSFileManager * fm = [NSFileManager defaultManager];
        if(![fm fileExistsAtPath:fileToDownload.filePath])
        {
            fileToDownload.length = 0;
            return NO;
        }
        
        NSError *error = nil;
        NSDictionary *fileDict = [fm attributesOfItemAtPath:fileToDownload.filePath error:&error];
        if (!error && fileDict) {
            fileToDownload.length = [fileDict fileSize];
        }
    }
    if(fileToDownload.lengthFull > fileToDownload.length)
    {
        if(fileToDownload.offset + fileToDownload.length >= fileToDownload.parentItem.contentLength-1 && fileToDownload.parentItem.contentLength>0)
        {
            fileToDownload.lengthFull = fileToDownload.length;
        }
        else
        {
            return NO;
        }
    }
    return YES;
    //    }
}
- (BOOL)isExistsLocalFile:(NSString *)webUrl
{
    NSString * key = [self getRemoteFileCacheKey:webUrl];
    NSString * localWebUrl = [self getLocalWebUrl:key];
    NSString * localFilePath = [self getFilePathForLocalUrl:localWebUrl];
    if([[UDManager sharedUDManager]existFileAtPath:localFilePath])
    {
        return YES;
    }
    return NO;
}
- (BOOL)isDataReady:(VDCItem *)item
{
    if(item.AudioUrl && item.AudioUrl.length>=2)
    {
        
        if(![self checkAudioPath:item])
        {
            return NO;
        }
    }
    
    UInt64 downloadBytes = 0;
    if(item.localFileName && item.localFileName.length>0)
    {
//        NSString * newPath = nil;
        if([[UDManager sharedUDManager] isFileExistAndNotEmpty:item.localFilePath size:nil])
        {
//            if(newPath) item.localFilePath = newPath;
            return YES;
        }
    }
    for (int i = 0; i<item.tempFileList.count; i++) {
        VDCTempFileInfo * fi = item.tempFileList[i];
        if(fi.length>= fi.lengthFull && fi.isDownloading==NO)
        {
            downloadBytes += fi.lengthFull;
        }
        else
        {
            break;
        }
        if(downloadBytes >= prevCacheSize_)
        {
            break;
        }
    }
    if(downloadBytes>=prevCacheSize_)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

#pragma mark - stop local web reqeust
- (void)setNeedCancelLocalRequest
{
    needCancelLocalWebRequest = YES;
}
- (BOOL)needStopLocalWebRequest:(VDCItem *)item
{
    return  needCancelLocalWebRequest||(item && item.needStop && item.downloadBytes < item.contentLength);
    //    return localWebRequestRef2Stop >0;
    //    return item.needStop;
}
- (BOOL)didStopLocalWebRequest:(VDCItem *)item
{
    @synchronized(self) {
        localWebRequestRef2Stop --;
    }
    if(localWebRequestRef2Stop<=0)
    {
        localWebRequestRef2Stop = 0;
        needCancelLocalWebRequest = NO;
    }
    return localWebRequestRef2Stop>0;
    //    item.needStop = YES;
}
- (void)regStopLocalWebRequest:(VDCItem *)item
{
    @synchronized(self) {
        localWebRequestRef2Stop ++;
    }
}

#ifndef __OPTIMIZE__
//- (void)networkRequestDidStart:(NSNotification *)notification {
//    NSURLRequest * request = AFNetworkRequestFromNotification(notification);
//    NSLog(@"%@,----- %@",[request.URL absoluteString],request.allHTTPHeaderFields);
//    if ([AFNetworkRequestFromNotification(notification) URL]) {
//
//    }
//}
//
//- (void)networkRequestDidFinish:(NSNotification *)notification {
//    NSURLRequest * request = AFNetworkRequestFromNotification(notification);
//    NSLog(@"%@,----- %@",[request.URL absoluteString],request.allHTTPHeaderFields);
//
//    if ([AFNetworkRequestFromNotification(notification) URL]) {
//
//    }
//}
#endif
#pragma mark - status post
- (void)setPostMsg:(NSString*)message bytesRead:(NSInteger)bytesRead
{
    if(message)
    {
        PP_RELEASE(downloadFile_);
        downloadFile_ = PP_RETAIN(message);
    }
    //check speed
    {
        if(bytesRead <0)
            downloadBytesForSpeed_ = bytesRead;
        else
            downloadBytesForSpeed_ += bytesRead;
        downloadCountForSpeed_ ++;
    }
}
- (void)postCaching:(NSTimer *)timer
{
    //check 是否下载完
    if(downloadBytesForSpeed_==0 && downloadList_.count==0)
    {
        downloadBytesForSpeed_ = -3;
    }
    CGFloat downloadSpeed = 0;
    
    if(downloadBytesForSpeed_==0 && downloadCountForSpeed_==0)
    {
        //        return;
        downloadBytesForSpeed_ = -1;
        PP_RELEASE(downloadFile_);
    }
    
    NSDate * endDate = [NSDate date];
    NSTimeInterval pastSeconds = [endDate timeIntervalSinceDate:beginDateForSpeed_];
    {
        downloadSpeed = downloadBytesForSpeed_ <0?downloadBytesForSpeed_:
        (downloadCountForSpeed_>0?downloadBytesForSpeed_/(pastSeconds * 1024):0);
    }
    
    //    NSLog(@"download:%llu count:%d in seconds:%f speed:%.1fKB/S",downloadBytesForSpeed_,downloadCountForSpeed_,pastSeconds,downloadSpeed);
    
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:downloadSpeed],@"speed",
                          downloadFile_?downloadFile_:@"",@"file",
                          nil];
    [[NSNotificationCenter defaultCenter]postNotificationName:NT_CACHINGMESSAGE object:nil userInfo:dic];
    
    downloadBytesForSpeed_ = 0;
    downloadCountForSpeed_ = 0;
    beginDateForSpeed_ = endDate;
    PP_RELEASE(downloadFile_);
}
- (BOOL)canHandleUrl:(NSString *)urlString
{
    
    NSString* fullpath = urlString;
    NSLog(@"local url:%@",fullpath);
    if([fullpath isMatchedByRegex:@"/[a-f0-9]{16,64}(\\.mp4|\\.m3u8)?"])
        return  YES;
    else
        return NO;
}
#pragma mark - downloadList operate
- (void)willDownload:(NSNotification*)notification
{
    if(notification && notification.object)
    {
        VDCTempFileInfo * fi = (VDCTempFileInfo *)notification.object;
        if(!fi.parentItem) return;
        dispatch_async(downloadItemQueue_, ^(void)
                       {
                           [self startDownload:fi.parentItem urlReady:nil progress:nil completed:nil];
                       });
    }
}

//将正在下载的对像加到队列中
- (void)addToDownloadList:(VDCTempFileInfo *)fileToDownload
{
    @synchronized(downloadList_) {
        //检查是否在下载队列中
        BOOL isFind = NO;
        for (NSInteger i = 0;i<downloadList_.count;i++) {
            VDCTempFileInfo * fi = downloadList_[i];
            if(fi == fileToDownload || [fi.fileName isEqualToString:fileToDownload.fileName])
            {
                isFind = YES;
                break;
            }
        }
        if(!isFind)
        {
            [downloadList_ addObject:fileToDownload];
        }
    }
}
//将对像从队列中移除
- (void)removeFromDownloadList:(VDCTempFileInfo *)fileToDownload
{
    @synchronized(downloadList_) {
        [downloadList_ removeObject:fileToDownload];
    }
}
//将队列中的所有对像移除
- (void)cancelItemsInDownloadList:(VDCItem *)excludeItem
{
    @synchronized(downloadList_) {
        NSMutableArray * removeList = [NSMutableArray new];
        for (int i = (int)downloadList_.count-1; i>=0; i --) {
            VDCTempFileInfo * fi = downloadList_[i];
            if(excludeItem && excludeItem == fi.parentItem)
            {
                continue;
            }
            else
            {
                [fi cancelOperation];
                NSLog(@"DOWN:%@ cancelled by ..",fi.fileName);
                fi.parentItem.needStop = YES;
                [removeList addObject:fi];
            }
        }
        [downloadList_ removeObjectsInArray:removeList];
        PP_RELEASE(removeList);
        //        [downloadList_ removeAllObjects];
        //#ifdef USE_QUEUE
        //        isSomeOneDownloading = 0;
        //#endif
    }
}
//检查队列，将已经完成的移除，未完成的发重下指令
- (void)checkDownloadList
{
    @synchronized(downloadList_) {
        VDCTempFileInfo * fi = nil;
        NSMutableArray * array = [NSMutableArray new];
        for (NSInteger i = 0; i < downloadList_.count-1; i --) {
            VDCTempFileInfo * tempFi = [downloadList_ objectAtIndex:i];
            if(tempFi.length < tempFi.lengthFull)
            {
                if(!fi)
                    fi = tempFi;
            }
            else
            {
                [array addObject:tempFi];
            }
        }
        
        if(array.count>0)
        {
            [downloadList_ removeObjectsInArray:array];
        }
        if(fi && !fi.isDownloading)
        {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"DOWNLOADDO" object:fi];
        }
    }
}
//获取队列中的个数
- (NSInteger)getDownloadingCount
{
    @synchronized(downloadList_) {
        return downloadList_.count;
    }
}
- (int)ensureDownloading:(VDCItem*)item
{
    int count = 0;
    if(!item) return count;
    @synchronized(item) {
        for (int i = (int)item.tempFileList.count-1; i>=0; i--) {
            VDCTempFileInfo * fi = item.tempFileList[i];
            if(fi.isDownloading)
            {
                count++;
            }
        }
        return count;
    }
}
- (void)showDownloadList:(VDCItem *)item
{
    return;
#ifndef  __OPTIMIZE__
    NSLog(@"****************************************");
    for (NSInteger i = 0;i < item.tempFileList.count; i++) {
        VDCTempFileInfo * fi = item.tempFileList[i];
        if(fi.length >= fi.lengthFull)
        {
            
        }
        else
        {
            NSLog(@"file %@ downing:%d completed:%d",fi.fileName,fi.isDownloading,fi.lengthFull<=fi.length);
        }
    }
    NSLog(@"****************************************");
#endif
}
#pragma mark -  background in /out
- (void)pauseDownloads
{
    NSLog(@"not impliment.");
}
- (void)resumseDownloads
{
    NSLog(@"not impliment.");
}
@end

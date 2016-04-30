//
//  VDCManager.h
//  maiba
//  视频下载缓冲管理器
//  Created by HUANGXUTAO on 15/9/14.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <hccoren/base.h>
#import <UIKit/UIKit.h>
#import <CFNetwork/CFHTTPMessage.h>

//@class MTV;

#define USE_QUEUE       //下载使用队列逐个下载

#define NT_CACHINGMESSAGE @"NT_CACHINGFILE"



#define DEFAULT_PKSIZE (512*1024)
//#define PREV_CACHESIZE (4 * DEFAULT_PKSIZE)
@class VDCItem;
@class VDCTempFileInfo;

typedef void (^removeCacheFinished) (BOOL finished);
typedef void (^videoUrlReady)(VDCItem * vdcItem,NSURL * videoUrl);
typedef void (^downloadProgress)(VDCItem * vdcItem);
typedef void (^downloadCompleted)(VDCItem * vdcItem,BOOL completed,VDCTempFileInfo * tempFile);

//static bool cancelHttpVideoResponse = NO;
static bool needCancelLocalWebRequest = NO;
static int isSomeOneDownloading = 0;
static int localWebRequestRef2Stop = 0; //由于边下边播，本地的Reqeust不会因为没有文件而停止，而是会无限循环，等待文件下载成功。因此，停止时需要人工给一个标志

@interface VDCManager : NSObject
{
    CGFloat secondsCached_; //缓冲队列中数据缓存多长时间
    NSMutableArray * itemList_;//需要下载的队列
    NSMutableArray * downloadList_;//需要下载的文件
    
    
    NSTimer * dwnMsgTimer_;//用于定时通知前端，下载速度的计时器
    NSInteger downloadBytesForSpeed_;
    int     downloadCountForSpeed_;
    NSDate * beginDateForSpeed_;
    NSString * downloadFile_;
    int prevCacheSize_;
    int threadCount_;
}
+(id)Instance;
+(VDCManager *)shareObject;

//此链接是否由本地文件响应
- (BOOL)   canHandleUrl:(NSString *)urlString;
//第一次请求时，获取本地的URL，建立缓存数据
- (VDCItem *) getVDCItem:(NSString *)key;
- (VDCItem *) getSampleVDCItem:(long)sampleID;
- (VDCItem *) getMTVVDCItem:(long)sampleID userID:(int)userID;

- (VDCItem *) getVDCItemByLocalFile:(NSString *)path;
- (VDCItem *) getVDCItemForResponse:(NSString *)filePath;
- (VDCItem *) getVDCItemByURL:(NSString *)urlString  checkFiles:(BOOL)checkFiles;
- (VDCItem *) getVDCItemByLoaderURL:(NSString *)urlString checkFiles:(BOOL)checkFiles;

- (VDCItem *)createVDCItem:(NSString *)urlString key:(NSString *)key;
- (void)buildAudioPath:(VDCItem*)item audioUrlString:(NSString *)urlString key:(NSString *)key;
//开始缓存一个链接
- (VDCItem *)    addUrlCache:(NSString *)urlString title:(NSString *)title urlReady:(videoUrlReady)urlReady completed:(downloadCompleted)completed;
- (VDCItem *)    addUrlCache:(NSString *)urlString audioUrl:(NSString*)audioUrl title:(NSString *)title urlReady:(videoUrlReady)urlReady completed:(downloadCompleted)dcompleted;

//取消一线URL对应的下载链接
- (void)    cancelReqeustes:(NSArray *)urlStringList  excludeItem:(VDCItem *)excludeItem removeFiles:(BOOL)removeFiles;
//清理Cache
- (void)    removeCache:(NSArray*)urlString completed:(removeCacheFinished)completed;

//当合成时，有可能发现某个文件下载得并不完整，因此需要移除某个位置的文件，就算下载完成了，也需要将完成的数据去掉
- (void)    removeCache:(NSString *)urlString atProgress:(CGFloat)progress;
- (void)    removeCacheViaVDCItem:(VDCItem *)item;

- (void)downloadItem:(VDCItem *)item urlReady:(videoUrlReady)urlReady progress:(downloadProgress)progress completed:(downloadCompleted)completed;
- (void)    downloadUrl:(NSString *)urlString title:(NSString *)title urlReady:(videoUrlReady)urlReady progress:(downloadProgress)progress completed:(downloadCompleted)completed;
- (void)downloadUrl:(NSString *)urlString audioUrl:(NSString*)audioUrl title:(NSString *)title isAudio:(BOOL)isAudio urlReady:(videoUrlReady)urlReady progress:(downloadProgress)progress completed:(downloadCompleted)completed;

- (void)    stopDownload:(NSString*)urlString;
- (void)    stopCache:(VDCItem *)item;
- (VDCTempFileInfo *)getNextTempSlideToDown:(VDCItem *)item offset:(UInt64)offset minOffsetDownloading:(UInt64 *)minOffset;
- (void)downloadNextSlide:(VDCItem *)item offset:(UInt64)offset immediate:(BOOL)immediate;

- (BOOL)downloadTempFile:(VDCTempFileInfo *)fileToDownload
                urlReady:(videoUrlReady)urlready
                progress:(downloadProgress)progress
               completed:(downloadCompleted)completed;

- (void)setPostMsg:(NSString*)message bytesRead:(NSInteger)bytesRead;
- (void)postCaching:(NSTimer *)timer;

- (BOOL)checkIsDownloadOK:(VDCTempFileInfo *)fileToDownload;
- (void)checkDownloadList;
- (NSInteger) getDownloadingCount;

- (BOOL)isItemDownloadCompleted:(VDCItem *)item;
- (void)removeTemplateFilesByUrl:(NSString *)urlString;
- (void)removeItem:(VDCItem *)item withTempFiles:(BOOL)withTempfiles includeLocal:(BOOL)includeLocal;
- (void)removeItemList;

- (BOOL) needStopLocalWebRequest:(VDCItem *)item;
- (BOOL) didStopLocalWebRequest:(VDCItem *)item;
- (void) regStopLocalWebRequest:(VDCItem *)item;
- (BOOL) isExistsLocalFile:(NSString *)webUrl;
- (BOOL)isDataReady:(VDCItem *)item;
#pragma mark -  background in /out
- (void)pauseDownloads;
- (void)resumseDownloads;
- (BOOL)checkAudioPath:(VDCItem *)item;

- (VDCItem *)addVDCItemToList:(VDCItem *)vdcitem;
@end

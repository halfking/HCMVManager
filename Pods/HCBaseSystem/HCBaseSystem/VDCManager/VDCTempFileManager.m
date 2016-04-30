//
//  VDCManager(RequestTask).m
//  maiba
//
//  Created by HUANGXUTAO on 16/3/13.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "VDCManager(LocalFiles).h"
#import "VDCManager(Helper).h"
#import "VDCManager.h"
#import "VDCItem.h"
#import "VDCTempFileManager.h"
#import "VDCTempFileManager(readwriter).h"
#import "UDManager.h"

@interface VDCTempFileManager () <NSURLConnectionDataDelegate, AVAssetResourceLoaderDelegate>

@property (nonatomic, strong) NSString           *urlStr;
@property (nonatomic, strong) NSString        *mimeType;
@property (nonatomic, strong) NSMutableArray  *taskArr;
@property (nonatomic, assign) int            retryCount;

@end

@implementation VDCTempFileManager //(RequestTask)
{
    //    VDCTempFileManager * fileManager_;
}
@synthesize offsetOfItem= offsetOfItem_;
@synthesize urlStr = urlStr_;
@synthesize lastRequestRange = lastRequestRange_;
- (instancetype)init
{
    self = [super init];
    if (self) {
        _taskArr = [NSMutableArray array];
        udManager_ = [UDManager sharedUDManager];
        lastRequestRange_ = NSMakeRange(0, 0);
    }
    return self;
}

- (void)setUrl:(NSString *)urlStr offset:(long long)offset
{
    NSLog(@"******* begin request:%llu  ",offset);
    _retryCount = 0;
    //清理上次的信息，原则上一次只有一个播放器
    if(urlStr_ && currentItem_ && [urlStr_ isEqualToString:urlStr]==NO)
    {
        NSLog(@"关闭上次未完文件");
        [self close];
    }
    
    NSLog(@"构建缓存对像，准备重新开始缓存剩余部分:%lld",offset);
    //构建VDCItem，获取文件的长度等信息
    currentItem_ = [[VDCManager shareObject] getVDCItemByLoaderURL:urlStr checkFiles:YES];
    
    _downLoadingOffset = 0;
    
    //校正偏移量，与文件中未下完部分对接
    if(offset>0)
    {
        offset = [self alignOffsetWithFileDownloaded:currentItem_ offset:offset];
    }
    
    urlStr_ = urlStr;
    offsetOfItem_ = offset;
    
    if(currentItem_.downloadBytes >= currentItem_.contentLength && currentItem_.contentLength>0)
    {
        VDCTempFileInfo * fi = [self getCurrentTempFileInfo:currentItem_ offset:offsetOfItem_];
        if(fi.length>0)
        {
            _downLoadingOffset = (NSUInteger)(currentItem_.contentLength - offsetOfItem_);
            //告诉后方，数据已经到了
            [self.delegate didReceiveVideoDataWithTask:self];
            return;
        }
        else
        {
            NSLog(@"oops....what fuck happend? need download again!!!!!!");
        }
    }
    
    {
        NSURL * url = [NSURL URLWithString:urlStr_];
        NSRange rangeToDownload;
        BOOL ret = [self getNextRangeToDownload:currentItem_ offset:offset range:&rangeToDownload];
        
        NSLog(@"QURY(%d): %@",ret,NSStringFromRange(rangeToDownload));
        
        [self downloadWithOffset:url range:rangeToDownload];
    }
}

- (void)resumeLoading:(NSUInteger)offset
{
    return ;
}
- (void)cancel
{
    [self.connection cancel];
    [self finishedWriting];
}


#pragma mark -  NSURLConnection Delegate Methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _isFinishLoad = NO;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    
    NSDictionary *dic = (NSDictionary *)[httpResponse allHeaderFields] ;
    
    NSString *content = [dic valueForKey:@"Content-Range"];
    NSArray *array = [content componentsSeparatedByString:@"/"];
    NSString *length = array.lastObject;
    
    NSUInteger videoLength;
    
    if ([length integerValue] == 0) {
        videoLength = (NSUInteger)httpResponse.expectedContentLength;
    } else {
        videoLength = [length integerValue];
    }
    if(currentItem_.contentLength<videoLength)
    {
        currentItem_.contentLength = videoLength;
    }
    
    self.mimeType = @"video/mp4";
    
    
    if ([self.delegate respondsToSelector:@selector(task:didReceiveVideoLength:mimeType:)]) {
        [self.delegate task:self didReceiveVideoLength:(long long)currentItem_.contentLength mimeType:self.mimeType];
    }
    
    [self.taskArr addObject:connection];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self writeContentToFile:offsetOfItem_ + _downLoadingOffset content:data];
    
    _downLoadingOffset += data.length;
    NSLog(@"RECV DATA:%llu",offsetOfItem_ + _downLoadingOffset);
    if ([self.delegate respondsToSelector:@selector(didReceiveVideoDataWithTask:)]) {
        [self.delegate didReceiveVideoDataWithTask:self];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (self.taskArr.count < 2) {
        _isFinishLoad = YES;
        
        [self finishedWriting];
    }
    else
    {
        [self.taskArr removeAllObjects];
    }
    
    NSRange range ;
    BOOL ret = [self getNextRangeToDownload:currentItem_ offset:0 range:&range];
    
    if(!ret || range.length==0)
    {
        lastRequestRange_ = NSMakeRange(lastRequestRange_.location, 0);
        self.connection = nil;
        if ([self.delegate respondsToSelector:@selector(didFinishLoadingWithTask:)]) {
            [self.delegate didFinishLoadingWithTask:self];
        }
    }
    else
    {
        [self downloadWithOffset:[NSURL URLWithString:urlStr_] range:range];
    }
    
}

//网络中断：-1005
//无网络连接：-1009
//请求超时：-1001
//服务器内部错误：-1004
//找不到服务器：-1003
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (error.code == -1001 && _retryCount < 5) {      //网络超时，重连一次
        NSLog(@"请求媒体文件超时，重试第%d次",_retryCount);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self continueLoading];
        });
    }
    if ([self.delegate respondsToSelector:@selector(didFailLoadingWithTask:WithError:)]) {
        [self.delegate didFailLoadingWithTask:self WithError:error.code];
    }
    if (error.code == -1009) {
        NSLog(@"播放时，无网络连接");
    }
    self.connection = nil;
}


- (void)continueLoading
{
    _retryCount ++;
    
    NSRange rangeToDownload = lastRequestRange_;
    if(rangeToDownload.length ==0)
    {
        [self getNextRangeToDownload:currentItem_ offset:offsetOfItem_ range:&rangeToDownload];
    }
    
    if(rangeToDownload.length>0)
    {
        [self downloadWithOffset:[NSURL URLWithString:urlStr_] range:rangeToDownload];
    }
}

- (void)clearData
{
    [self.connection cancel];
    [self.taskArr removeAllObjects];
    [self close];
}
- (void)downloadWithOffset:(NSURL *)url range:(NSRange)rangeToDownload
{
    NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    actualURLComponents.scheme = @"http";
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[actualURLComponents URL]
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];
    
    _downLoadingOffset = rangeToDownload.location - offsetOfItem_;
    [request addValue:[NSString stringWithFormat:@"bytes=%ld-%ld",
                       (unsigned long)rangeToDownload.location,
                       (unsigned long)(rangeToDownload.location + rangeToDownload.length - 1)]
   forHTTPHeaderField:@"Range"];
    NSLog(@"QURY(): %@  lastRange:%@",NSStringFromRange(rangeToDownload),NSStringFromRange(lastRequestRange_));
    [self.connection cancel];
    
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [self.connection setDelegateQueue:[NSOperationQueue mainQueue]];
    [self.connection start];
    
    lastRequestRange_ = rangeToDownload;
}
- (long long)contentLength
{
    if(currentItem_)
    {
        return currentItem_.contentLength;
    }
    return 0;
}
//当前面停住后，再次检查是否下载完成，然后再次触发播放器处理
- (NSInteger)checkDownloadStatus
{
    if(!self.connection)
    {
        NSLog(@"check loader download status");
        NSRange rangeToDownload = lastRequestRange_;
        if(rangeToDownload.length ==0)
        {
            [self getNextRangeToDownload:currentItem_ offset:offsetOfItem_ range:&rangeToDownload];
        }
        
        if(rangeToDownload.length>0)
        {
            [self downloadWithOffset:[NSURL URLWithString:urlStr_] range:rangeToDownload];
            return 1;
        }
        else
        {
            [self.delegate didReceiveVideoDataWithTask:self];
            if ([self.delegate respondsToSelector:@selector(didFinishLoadingWithTask:)]) {
                [self.delegate didFinishLoadingWithTask:self];
            }
        }
    }
    return 0;
}
@end

//
//  HXNetwork.m
//  maiba
//
//  Created by HUANGXUTAO on 15/9/30.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import "HXNetwork.h"
#import <hccoren/base.h>
@interface HXNetwork ()<NSURLConnectionDelegate, NSURLConnectionDataDelegate>

{
    long long  _expectedLength;                                 // 期望最大的数据长度
}

@property (nonatomic, strong) NSString   *filePath;       // 存储下载的数据
@property (nonatomic, strong) NSURLConnection *dataConncetion;  // 网络链接对象
@property (nonatomic, strong) NSDictionary    *responseHeaders; // 该网络链接所有头信息
@property (nonatomic,assign) UInt64 totalBytesRead;
@end
@implementation HXNetwork
@synthesize isCancelled;
#ifndef __OPTIMIZE__
static int downloadThreadCount = 0;
#endif
- (instancetype)initWithRequest:(NSURLRequest *)request outputfile:(NSString *)filePath
{
#ifndef __OPTIMIZE__
    downloadThreadCount ++;
    NSLog(@"download thread count:%d",downloadThreadCount);
#endif
    self = [super init];
    if (self)
    {
        isCancelled = YES;
        self.filePath = filePath;

        self.dataConncetion = \
        [[NSURLConnection alloc] initWithRequest:request
                                        delegate:self
                                startImmediately:NO];
        
    }
    
    return self;
}

- (void)start
{
    isCancelled = NO;
//    if([NSThread isMainThread])
//    {
//        [self.dataConncetion start];
//    }
//    else
//    {
//        dispatch_async(dispatch_get_main_queue(), ^(void){
//            [self.dataConncetion start];
//        });
//    }
    [self.dataConncetion start];
    CFRunLoopRun();
}
- (void)cancel
{
    isCancelled = YES;
    [self.dataConncetion cancel];
    if(_completionWithError)
    {
        _completionWithError(self,[NSError errorWithDomain:@"com.seenvoice.maiba" code:-1000 userInfo:@{NSLocalizedDescriptionKey : @"cancelled by user"}]);
    }
    [self readyToRelease];
    CFRunLoopStop(CFRunLoopGetCurrent());

}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse *r = (NSHTTPURLResponse *)response;
        
        // 如果能获取到期望的数据长度就执行括号中的方法
        if ([r expectedContentLength] != NSURLResponseUnknownLength)
        {
            _expectedLength  = [r expectedContentLength];
            _responseHeaders = PP_RETAIN([r allHeaderFields]);
        }
        else
        {
            _expectedLength = 0;
        }
        _response = PP_RETAIN((NSHTTPURLResponse*)response);
    }
    else
    {
        NSLog(@"unkown response type:%@",NSStringFromClass([response class]));
        [self cancel];
        isCancelled = YES;
    }
    self.totalBytesRead = 0;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)theData
{
    self.totalBytesRead += theData.length;
    NSFileManager  * fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:self.filePath])
    {
        [fm createFileAtPath:self.filePath contents:theData attributes:nil];
    }
    else
    {
        NSFileHandle * handle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
        if(handle)
        {
            [handle seekToEndOfFile];
            [handle writeData:theData];
            [handle closeFile];
            handle = nil;
        }
        else
        {
            NSLog(@"open file %@ failure.",self.filePath);
            [self cancel];
            return;
        }
    }
    //    [theData writeToFile:self.filePath atomically:YES];
    
    // 如果指定了block
    if (_downloadProgressBlock)
    {
        _downloadProgressBlock(theData.length, self.totalBytesRead, _expectedLength);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    isCancelled = YES;
    // 如果指定了block
    if (_completionDataBlock)
    {
        _completionDataBlock(self,self.response);
    }
    [self readyToRelease];
    CFRunLoopStop(CFRunLoopGetCurrent());
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    isCancelled = YES;
    if(_completionWithError)
    {
        _completionWithError(self,error);
    }
    [self readyToRelease];
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(nullable NSURLResponse *)response
{
    NSLog(@"will send request:%@",request.URL.absoluteString);
    return  request;
}
- (void)readyToRelease
{
    self.downloadProgressBlock = nil;
    self.completionDataBlock = nil;
    self.completionWithError = nil;
    self.dataConncetion = nil;
    self.filePath = nil;
    PP_RELEASE(_response);
    PP_RELEASE(_responseHeaders);
}
- (void)dealloc
{
    [self readyToRelease];
#ifndef __OPTIMIZE__
    downloadThreadCount --;
    NSLog(@"download thread count:%d",downloadThreadCount);
#endif
    PP_SUPERDEALLOC;
}
//NS_INLINE NSURLRequest *netURLRequest(NSString *netPath)
//{
//    //创建简单的网络请求
//    return [NSURLRequest requestWithURL:[NSURL URLWithString:netPath]];
//}

/*
 #ifndef USE_AFN
 HXNetwork * operation = [[HXNetwork alloc]initWithUrlString:request outputfile:fileToDownload.filePath];
 //下载进度回调
 __weak typeof(operation) weakOp = operation;
 
 [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
 
 fileToDownload.isDownloading = YES;
 //        NSLog(@"response head:%@",weakOp.response.allHeaderFields);
 //此处仅当Range右侧为空时有效
 
 if(weakVDCItem.contentLength <=0)
 {
 //            NSLog(@"response range:%@",[weakOp.response.allHeaderFields objectForKey:@"Content-Range"]);
 //            NSLog(@"response length:%@",[weakOp.response.allHeaderFields objectForKey:@"Content-Length"]);
 NSString * cr = [weakOp.response.allHeaderFields objectForKey:@"Content-Range"];
 if(cr){
 NSString * cl = [cr stringByMatching:@"\\d+$"];
 if(cl)
 {
 weakVDCItem.contentLength = (NSInteger)[cl longLongValue];
 }
 }
 else
 {
 cr = [weakOp.response.allHeaderFields objectForKey:@"Content-Length"];
 if(cr)
 {
 weakVDCItem.contentLength = (NSInteger)[cr longLongValue];
 }
 }
 if(weakVDCItem.contentLength<=0)
 {
 weakVDCItem.contentLength = (NSInteger)(totalBytesRead + totalBytesExpectedToRead + offset);
 }
 if(weakVDCItem.contentLength>0)
 {
 #ifdef   USE_DOWNLOADMAP
 length = DEFAULT_PKSIZE;
 #else
 length = item.contentLength - offset;
 #endif
 [self rememberContentLength:weakVDCItem.contentLength tempPath:weakVDCItem.tempFilePath];
 }
 NSLog(@"current item contentlength:%llu",weakVDCItem.contentLength);
 }
 
 //下载进度
 fileToDownload.length += bytesRead;
 fileToDownload.parentItem.downloadBytes += bytesRead;
 PP_RELEASE(downloadFile_);
 downloadFile_ = PP_RETAIN(fileToDownload.fileName);
 
 
 //#endif
 //check speed
 {
 
 downloadBytesForSpeed_ += bytesRead;
 downloadCountForSpeed_ ++;
 
 #ifndef __OPTIMIZE__
 NSDate * endDate = [NSDate date];
 NSTimeInterval pastSeconds = [endDate timeIntervalSinceDate:beginDateForSpeed_];
 CGFloat downloadSpeed =     downloadBytesForSpeed_/(pastSeconds * 1024);
 NSLog(@"download:%llu count:%d in seconds:%f speed:%.1fKB/S",downloadBytesForSpeed_,downloadCountForSpeed_,pastSeconds,downloadSpeed);
 #endif
 }
 
 if(!isCalled &&  fileToDownload.length >= DEFAULT_PKSIZE/2)
 {
 isCalled = YES;
 if(urlready)
 {
 urlready(weakVDCItem,[NSURL URLWithString:weakVDCItem.localWebUrl]);
 }
 }
 }];
 
 //成功和失败回调
 [operation setCompletionDataBlock:^(HXNetwork *operation, id responseObject) {
 fileToDownload.operation = nil;
 [downloadList_ removeObject:fileToDownload];
 
 [self getTemFileList:weakVDCItem justCheckDownloading:YES];
 fileToDownload.isDownloading = NO;
 
 //        如果文件长度不对，但显示完成了，说明是CDN服务器发出了错误的数据，该如何处理？
 if(fileToDownload.lengthFull > fileToDownload.length)
 {
 NSLog(@"why part(%@) (%@)(%llu)） of data:%d<-->%d",weakVDCItem.removeUrl,requestRange,
 fileToDownload.offset,
 fileToDownload.length,fileToDownload.lengthFull)
 }
 
 if(!isCalled)
 {
 isCalled = YES;
 if(urlready)
 {
 urlready(weakVDCItem,[NSURL URLWithString:weakVDCItem.localWebUrl]);
 }
 }
 if(completed)
 {
 completed(weakVDCItem,TRUE,fileToDownload);
 }
 
 PP_RELEASE(downloadFile_);
 
 }];
 [operation setCompletionWithError:^(HXNetwork *operation, NSError *error) {
 fileToDownload.operation = nil;
 [downloadList_ removeObject:fileToDownload];
 
 [self getTemFileList:weakVDCItem justCheckDownloading:YES];
 fileToDownload.isDownloading = NO;
 
 downloadBytesForSpeed_ = -4;
 PP_RELEASE(downloadFile_);
 downloadFile_ = PP_RETAIN(@"MV下载时发生错误");
 
 if(!isCalled)
 {
 isCalled = YES;
 if(urlready)
 {
 urlready(weakVDCItem,[NSURL URLWithString:weakVDCItem.localWebUrl]);
 }
 }
 //        [HttpVideoFileResponse checkFileLengthAndSlide:item];
 NSLog(@"file %@ download failure code:[%ld]:%@",fileToDownload.fileName,operation.response.statusCode,[error description]);
 
 if(completed)
 {
 completed(weakVDCItem,NO,fileToDownload);
 }
 }];
 
 [operation start];
 
 #else
 */
@end

//
//  VDCLoaderConnection.m
//  maiba
//
//  Created by HUANGXUTAO on 16/3/13.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//
/*
 self.resouerLoader          = [[VDCLoaderConnection alloc] init];
 self.resouerLoader.delegate = self;
 NSURL *playUrl              = [_resouerLoader getSchemeVideoURL:url];
 self.videoURLAsset             = [AVURLAsset URLAssetWithURL:playUrl options:nil];
 [_videoURLAsset.resourceLoader setDelegate:_resouerLoader queue:dispatch_get_main_queue()];
 self.currentPlayerItem          = [AVPlayerItem playerItemWithAsset:_videoURLAsset];

 */
#import "VDCLoaderConnection.h"
#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "VDCTempFileManager.h"
#import "VDCTempFileManager(readwriter).h"

#import "VDCTempFileInfo.h"

@interface VDCLoaderConnection ()<VDCManagerRequestTaskDelegate>

@property (nonatomic, strong) NSMutableArray *pendingRequests;
@property (nonatomic, copy  ) NSString       *videoPath;

@end


@implementation VDCLoaderConnection

- (instancetype)init
{
    self = [super init];
    if (self) {
        _pendingRequests = [NSMutableArray array];
    }
    return self;
}

- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest
{
    NSString *mimeType = self.task.mimeType;
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = [self.task contentLength];
}
- (void)cancel
{
    [super cancel];
}
- (void)cancelWithClose
{
    NSLog(@"ready to cancel request and close files.");
    [super cancel];
    
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self.task close];
                   });
}
- (void)dealloc
{
    [_pendingRequests removeAllObjects];
    if(_task)
    {
        [_task close];
        PP_RELEASE(_task);
    }
    PP_RELEASE(_pendingRequests);
    PP_SUPERDEALLOC;
}
#pragma mark - AVURLAsset resource loader methods

- (void)processPendingRequests
{
    NSMutableArray *requestsCompleted = [NSMutableArray array];  //请求完成的数组
    //每次下载一块数据都是一次请求，把这些请求放到数组，遍历数组
    for (AVAssetResourceLoadingRequest *loadingRequest in self.pendingRequests)
    {
        [self fillInContentInformation:loadingRequest.contentInformationRequest]; //对每次请求加上长度，文件类型等信息
        
        //用于判断是否连续下载
        BOOL didRespondCompletely = [self respondWithDataForRequest:loadingRequest.dataRequest]; //判断此次请求的数据是否处理完全
        NSLog(@"load request:%llu(%ld) complted:%d",loadingRequest.dataRequest.currentOffset,(long)loadingRequest.dataRequest.requestedLength,didRespondCompletely);
        if (didRespondCompletely) {
            
            [requestsCompleted addObject:loadingRequest];  //如果完整，把此次请求放进 请求完成的数组
            [loadingRequest finishLoading];
        }
    }
    
    [self.pendingRequests removeObjectsInArray:requestsCompleted];   //在所有请求的数组中移除已经完成的
    
}

- (BOOL)respondWithDataForRequest:(AVAssetResourceLoadingDataRequest *)dataRequest
{
    long long startOffset = dataRequest.requestedOffset;
    //    long long requestLength = dataRequest.requestedLength;
    if (dataRequest.currentOffset != 0) {
        startOffset = dataRequest.currentOffset;
    }
//    NSLog(@"read QQ:%llu(%llu)<--> %llu",startOffset,dataRequest.requestedLength,dataRequest.requestedOffset);
    NSData * segData = [self.task readContentFromFile:startOffset length:dataRequest.requestedLength];
    if(segData.length==0)
    {
        return NO;
    }
    else
    {
        [dataRequest respondWithData:segData];
        return segData.length >= dataRequest.requestedLength;
    }
}


/**
 *  必须返回Yes，如果返回NO，则resourceLoader将会加载出现故障的数据
 *  这里会出现很多个loadingRequest请求， 需要为每一次请求作出处理
 *  @param resourceLoader 资源管理器
 *  @param loadingRequest 每一小块数据的请求
 *
 */
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"loading request:%llu -- %ld",loadingRequest.dataRequest.requestedOffset,(long)loadingRequest.dataRequest.requestedLength);
    [self.pendingRequests addObject:loadingRequest];
    [self dealWithLoadingRequest:loadingRequest];
    
    return YES;
}


- (void)dealWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSURL *interceptedURL = [loadingRequest.request URL];
    NSRange range = NSMakeRange((NSUInteger)loadingRequest.dataRequest.currentOffset, NSUIntegerMax);
    
    if (self.task.downLoadingOffset > 0) {
        [self processPendingRequests];
    }
    
    if (!self.task) {
        self.task = [[VDCTempFileManager alloc] init];
        self.task.delegate = self;
        [self.task setUrl:[interceptedURL absoluteString] offset:0];
    } else {
        //1、往后拖
        //2、如果往回拖也重新请求,如果当前缓冲是从0开始则不需要处理
        if (self.task.offsetOfItem + self.task.downLoadingOffset + DEFAULT_PKSIZE < range.location ||
            range.location < self.task.offsetOfItem) {
            NSLog(@"需要重新加载中:%ld",(long)range.location);
            [self.task setUrl:[interceptedURL absoluteString] offset:range.location];
        }
    }
}


- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"cancel request loading:%llu-%ld",loadingRequest.dataRequest.currentOffset,(long)loadingRequest.dataRequest.requestedLength);
    UInt64 loadOffset = loadingRequest.dataRequest.currentOffset;
    
    [self.pendingRequests removeObject:loadingRequest];
    [self.task cancel];
    //有时候视频会奇怪的取消所有请求，导致停住，这里再检查一次
    if(loadOffset < DEFAULT_PKSIZE)
    {
        [self recheckLoad];
        return;
    }
   
}

- (NSURL *)getSchemeVideoURL:(NSURL *)url
{
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = @"streaming";
    return [components URL];
}

- (NSInteger)recheckLoad
{
    return [self.task checkDownloadStatus];
}

#pragma mark - VDCManagerRequestTaskDelegate

- (void)task:(VDCTempFileManager *)task didReceiveVideoLength:(long long)videoLength mimeType:(NSString *)mimeType
{
    
}

- (void)didReceiveVideoDataWithTask:(VDCTempFileManager *)task
{
    [self processPendingRequests];
    
}

- (void)didFinishLoadingWithTask:(VDCTempFileManager *)task
{
    if ([self.delegate respondsToSelector:@selector(didFinishLoadingWithTask:)]) {
        [self.delegate didFinishLoadingWithTask:task];
    }
}

- (void)didFailLoadingWithTask:(VDCTempFileManager *)task WithError:(NSInteger)errorCode
{
    if ([self.delegate respondsToSelector:@selector(didFailLoadingWithTask:WithError:)]) {
        [self.delegate didFailLoadingWithTask:task WithError:errorCode];
    }
}
@end

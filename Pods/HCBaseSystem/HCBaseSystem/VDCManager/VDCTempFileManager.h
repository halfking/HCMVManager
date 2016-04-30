//
//  VDCManager(RequestTask).h
//  maiba
//
//  Created by HUANGXUTAO on 16/3/13.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//  这个task的功能是从网络请求数据，并把数据保存到本地的一个临时文件，网络请求结束的时候，如果数据完整，则把数据缓存到指定的路径，不完整就删除

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <hccoren/base.h>

#import "VDCManager.h"
#import "VDCItem.h"
#import "UDManager(Helper).h"

@class VDCTempFileManager;
@protocol VDCManagerRequestTaskDelegate <NSObject>
@optional
- (void)task:(VDCTempFileManager *)task didReceiveVideoLength:(long long)ideoLength mimeType:(NSString *)mimeType;
- (void)didReceiveVideoDataWithTask:(VDCTempFileManager *)task;
- (void)didFinishLoadingWithTask:(VDCTempFileManager *)task;
- (void)didFailLoadingWithTask:(VDCTempFileManager *)task WithError:(NSInteger )errorCode;
@end

@interface VDCTempFileManager:NSObject
{
    NSFileHandle *fileHandleForRead_;
    NSFileHandle * fileHandleForWrite_;
    
    VDCTempFileInfo * currentTempFileInfoWrite_;
    VDCTempFileInfo * currentTempFileInfoRead_;
    
//    NSString * key_;
    VDCItem * currentItem_;
//    UInt64  offsetOfItem_;  //整体的偏移量
//    UInt64 offsetInCurrentFile_; //当前文件内的偏移量
    
    UDManager * udManager_;
}
@property (nonatomic, readonly        ) long long                 offsetOfItem;//本对像最初缓冲开始的时间，一般是从0开始，当大幅拖动时，有可能不从0开始。
@property (nonatomic, readonly        ) long long                 downLoadingOffset;  //本次缓存的数据量
@property (nonatomic, strong, readonly) NSString                   * mimeType;
@property (nonatomic, assign)           BOOL                       isFinishLoad;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, weak            ) id <VDCManagerRequestTaskDelegate> delegate;
@property (nonatomic,assign,readonly) NSRange    lastRequestRange;

- (void)setUrl:(NSString *)urlStr offset:(long long)offset;

- (void)cancel;

- (void)continueLoading;

- (void)clearData;

//- (void)resumeLoading:(NSUInteger)offset;
- (void)downloadWithOffset:(NSURL *)url range:(NSRange)rangeToDownload ;
- (NSInteger)checkDownloadStatus;
- (long long)contentLength;
@end

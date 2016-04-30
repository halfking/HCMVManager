//
//  VDCLoaderConnection.h
//  maiba
//
//  Created by HUANGXUTAO on 16/3/13.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//
/// 这个connenction的功能是把task缓存到本地的临时数据根据播放器需要的 offset和length去取数据并返回给播放器
/// 如果视频文件比较小，就没有必要存到本地，直接用一个变量存储即可

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class VDCTempFileManager;

@protocol VDCLoaderConnectionDelegate <NSObject>
- (void)didFinishLoadingWithTask:(VDCTempFileManager *)task;
- (void)didFailLoadingWithTask:(VDCTempFileManager *)task WithError:(NSInteger )errorCode;
@end

@interface VDCLoaderConnection :  NSURLConnection <AVAssetResourceLoaderDelegate>

@property (nonatomic, strong) VDCTempFileManager *task;
@property (nonatomic, weak  ) id<VDCLoaderConnectionDelegate> delegate;
- (NSURL *)getSchemeVideoURL:(NSURL *)url;
- (void)cancel;
- (void)cancelWithClose;
- (NSInteger)recheckLoad;
@end

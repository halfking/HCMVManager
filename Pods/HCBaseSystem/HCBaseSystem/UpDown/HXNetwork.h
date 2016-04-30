//
//  HXNetwork.h
//  maiba
//
//  Created by HUANGXUTAO on 15/9/30.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HXNetwork;
// block的相关定义
typedef void (^downloadProgressBlock_t)(NSUInteger bytesRead,long long totalBytesReceived, long long totalBytesExpectedToReceive);
typedef void (^completionDataBlock_t)(HXNetwork *operation, id responseObject);
typedef void (^completionWithError_t) (HXNetwork *operation,NSError *error);

@interface HXNetwork : NSObject
// 将block定义成属性
@property (nonatomic, copy) downloadProgressBlock_t  downloadProgressBlock;
@property (nonatomic, copy) completionDataBlock_t    completionDataBlock;
@property (nonatomic, copy) completionWithError_t     completionWithError;

@property (nonatomic,strong,readonly) NSHTTPURLResponse * response;
@property (nonatomic,assign,readonly) BOOL isCancelled;
// 初始化方法
- (instancetype)initWithRequest:(NSURLRequest *)request outputfile:(NSString*)filePath;
// 开始网络下载
- (void)start;
- (void)cancel;
@end


//
//  CLVideoAddFilter.h
//  tiaooo
//
//  Created by ClaudeLi on 15/12/25.
//  Copyright © 2015年 dali. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

/* 视频添加水印、滤镜 协议*/
@protocol CLVideoAddFilterDelegate <NSObject>

// 视频完成处理
- (void)didFinishVideoDeal:(NSURL *)videoUrl;

// 滤镜处理进度
- (void)filterDealProgress:(CGFloat)progress;

// 操作中断
- (void)operationFailure:(NSString *)failure;

@end

@interface CLVideoAddFilter : NSObject

@property (nonatomic, weak) id<CLVideoAddFilterDelegate>delegate;

/**
 *  添加滤镜处理
 *
 *  @param videoUrl      需要处理视频的url
 *  @param tempVideoPath 处理完成视频临时存放地址
 *  @param index         选择的第几个滤镜
 */
- (void)addVideoFilter:(NSURL *)videoUrl tempVideoPath:(NSString *)tempVideoPath index:(NSInteger)index;

@end

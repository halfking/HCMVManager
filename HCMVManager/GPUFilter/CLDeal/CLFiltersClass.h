//
//  CLFiltersClass.h
//  tiaooo
//
//  Created by ClaudeLi on 15/12/27.
//  Copyright © 2015年 dali. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GPUImage.h>

@interface CLFiltersClass : NSObject

// 图片加滤镜
+ (UIImage *)imageAddFilter:(UIImage *)image index:(NSInteger)index;

// 实时切换滤镜预览
+ (void)addFilterLayer:(GPUImageMovie *)movieFile filters:(GPUImageOutput<GPUImageInput> *)filters filterView:(GPUImageView *)filterView index:(NSInteger)index;

// 滤镜处理
+ (GPUImageOutput<GPUImageInput> *)addVideoFilter:(GPUImageMovie *)movieFile index:(NSInteger)index;
+ (NSArray *)filters;
@end

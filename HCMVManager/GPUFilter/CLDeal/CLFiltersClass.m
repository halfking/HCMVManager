//
//  CLFiltersClass.m
//  tiaooo
//
//  Created by ClaudeLi on 15/12/27.
//  Copyright © 2015年 dali. All rights reserved.
//

#import "CLFiltersClass.h"

#import "TBSoftEleganceFilter.h"
#import "TBAmatorkaFilter.h"
#import "TBFreeFilter.h"
#import "TBLOMOFilter.h"
#import "TBSoftEleganceFilter.h"
#import "TBSexyFilter.h"
#import "TBBlackWhiteFiter.h"

#define VignetteStart 0.45
#define VignetteEnd 0.85

#define LVignetteStart 0.4
#define LVignetteEnd 0.8

@implementation CLFiltersClass
#pragma mark - 可用的滤镜
+ (NSArray *)filters
{
    return nil;
}
#pragma mark - 图片滤镜
+ (UIImage *)imageAddFilter:(UIImage *)image index:(NSInteger)index
{
    UIImage *filterImage;
    struct GPUVector3  color;
    color.one = 38/255;
    color.two = 38/255;
    color.three = 38/255;
    switch (index) {
        case 0:
        {
            // 原图
            filterImage = image;
        }
            break;
        case 1:
        {
            //Girl style
            GPUImageMissEtikateFilter *filter = [[GPUImageMissEtikateFilter alloc]init];
            filterImage = [filter imageByFilteringImage:image];
        }
            break;
        case 2:
        {
            //TBSoftEleganceFilter
            TBSoftEleganceFilter *filt = [[TBSoftEleganceFilter alloc]init];
            filterImage = [filt imageByFilteringImage:image];
        }
            break;
        case 3:
        {
            //Funky
            TBSexyFilter *filter = [[TBSexyFilter alloc]init];
            filterImage = [filter imageByFilteringImage:image];
        }
            break;
        case 4:
        {
            //Waltz
            TBLOMOFilter *filter = [[TBLOMOFilter alloc] init];
            filterImage = [filter imageByFilteringImage:image];
        }
            break;
        case 5:
        {
            //黑白M.J
            TBBlackWhiteFiter *filter = [[TBBlackWhiteFiter alloc]init];
            filterImage = [filter imageByFilteringImage:image];
        }
            break;
            
        case 6:
        {
            // TBAmatorkaFilter
            TBAmatorkaFilter *filt = [[TBAmatorkaFilter alloc]init];
            filterImage = [filt imageByFilteringImage:image];
        }
            break;
        case 7:
        {
            //Old school
            GPUImageSepiaFilter *filter = [[GPUImageSepiaFilter alloc]init];
            filterImage = [filter imageByFilteringImage:image];
        }
            break;
        case 8:
        {
            //#import "GPUImageVignetteFilter.h" //晕影，形成黑色圆形边缘，突出中间图像的效果
            GPUImageVignetteFilter *filt = [[GPUImageVignetteFilter alloc]init];
            filt.vignetteColor = color;
            filt.vignetteStart = 0.5;
            filt.vignetteEnd = 0.75;
            filterImage = [filt imageByFilteringImage:image];
        }
            break;
        case 9:
        {
            //锐化
            GPUImageSharpenFilter *filt = [[GPUImageSharpenFilter alloc]init];
            filt.sharpness = 4;
            filterImage = [filt imageByFilteringImage:image];
        }
            break;
        case 10:
        {
            //#import "GPUImageGaussianSelectiveBlurFilter.h" //高斯模糊，选择部分清晰
            GPUImageGaussianSelectiveBlurFilter *filt = [[GPUImageGaussianSelectiveBlurFilter alloc]init];
            filt.excludeCircleRadius = 0.8;
            filt.blurRadiusInPixels = 10;
            filterImage = [filt imageByFilteringImage:image];
        }
            break;
        case 11:
        {
            //#import "GPUImageLowPassFilter.h" //用于图像加亮
            GPUImageLowPassFilter *filt = [[GPUImageLowPassFilter alloc]init];
            filterImage = [filt imageByFilteringImage:image];
        }
            break;
        case 12:
        {
            //"GPUImageBulgeDistortionFilter.h" //凸起失真，鱼眼效果 #import "GPUImagePinchDistortionFilter.h" //收缩失真，凹面镜 #import
            // #import "GPUImageSwirlFilter.h" //漩涡，中间形成卷曲的画面 #import"GPUImageStretchDistortionFilter.h" //伸展失真，哈哈镜
            //#import "GPUImageGlassSphereFilter.h" //水晶球效果 #import "GPUImageSphereRefractionFilter.h" //球形折射，图形倒立
            GPUImageBulgeDistortionFilter *filt = [[GPUImageBulgeDistortionFilter alloc]init];
            filt.radius = 0.5; // 失真半径
            filt.scale = 0.2; // 变形量
            filterImage = [filt imageByFilteringImage:image];
        }
            break;
        case 13:
        {
            //GPUImageSketchFilter.h" //素描
            GPUImageSketchFilter *filt = [[GPUImageSketchFilter alloc]init];
            filterImage = [filt imageByFilteringImage:image];
        }
            break;
        default:
            break;
    }
    return filterImage;
}

#pragma mark - 实时切换滤镜
+ (void)addFilterLayer:(GPUImageMovie *)movieFile filters:(GPUImageOutput<GPUImageInput> *)filters filterView:(GPUImageView *)filterView index:(NSInteger)index
{
//    [movieFile cancelProcessing];
    [movieFile removeAllTargets];
    [filters removeAllTargets];
    struct GPUVector3  color;
    color.one = 38/255;
    color.two = 38/255;
    color.three = 38/255;
    switch (index) {
        case 0:
        {
            // 原
            GPUImageFilter *filt = [[GPUImageFilter alloc]init];
            filters = filt;
            [movieFile addTarget:filters];
        }
            break;
        case 1:
        {
            //Girl style
            GPUImageFilter *filter = [[GPUImageFilter alloc]init];
            filters = filter;
            GPUImageMissEtikateFilter *filt = [[GPUImageMissEtikateFilter alloc]init];
            GPUImageVignetteFilter *filt1 = [[GPUImageVignetteFilter alloc]init];
            filt1.vignetteColor = color;
            filt1.vignetteStart = VignetteStart;
            filt1.vignetteEnd = VignetteEnd;
            [movieFile addTarget:filt];
            [filt addTarget:filt1];
            [filt1 addTarget:filters];
        }
            break;
        case 2:
        {
            GPUImageFilter *filter = [[GPUImageFilter alloc]init];
            filters = filter;
            TBSoftEleganceFilter *filt= [[TBSoftEleganceFilter alloc] init];
            GPUImageVignetteFilter *filt1 = [[GPUImageVignetteFilter alloc]init];
            filt1.vignetteColor = color;
            filt1.vignetteStart = VignetteStart;
            filt1.vignetteEnd = VignetteEnd;
            [movieFile addTarget:filt];
            [filt addTarget:filt1];
            [filt1 addTarget:filters];
        }
            break;
        case 3:
        {
            //Funky
            GPUImageFilter *filter = [[GPUImageFilter alloc]init];
            filters = filter;
            TBSexyFilter *filt = [[TBSexyFilter alloc]init];
            GPUImageVignetteFilter *filt1 = [[GPUImageVignetteFilter alloc]init];
            filt1.vignetteColor = color;
            filt1.vignetteStart = VignetteStart;
            filt1.vignetteEnd = VignetteEnd;
            [movieFile addTarget:filt];
            [filt addTarget:filt1];
            [filt1 addTarget:filters];
        }
            break;
        case 4:
        {
            //Waltz
            GPUImageFilter *filter = [[GPUImageFilter alloc]init];
            filters = filter;
            TBLOMOFilter *filt = [[TBLOMOFilter alloc] init];
            GPUImageVignetteFilter *filt1 = [[GPUImageVignetteFilter alloc]init];
            filt1.vignetteColor = color;
            filt1.vignetteStart = VignetteStart;
            filt1.vignetteEnd = VignetteEnd;
            [movieFile addTarget:filt];
            [filt addTarget:filt1];
            [filt1 addTarget:filters];
        }
            break;
        case 5:
        {
            //黑白M.J
            GPUImageFilter *filter = [[GPUImageFilter alloc]init];
            filters = filter;
            TBBlackWhiteFiter *filt = [[TBBlackWhiteFiter alloc]init];
            GPUImageVignetteFilter *filt1 = [[GPUImageVignetteFilter alloc]init];
            filt1.vignetteColor = color;
            filt1.vignetteStart = LVignetteStart;
            filt1.vignetteEnd = LVignetteEnd;
            [movieFile addTarget:filt];
            [filt addTarget:filt1];
            [filt1 addTarget:filters];
        }
            break;
        case 6:
        {
            GPUImageFilter *filter = [[GPUImageFilter alloc]init];
            filters = filter;
            TBAmatorkaFilter *filt= [[TBAmatorkaFilter alloc] init];
            GPUImageVignetteFilter *filt1 = [[GPUImageVignetteFilter alloc]init];
            filt1.vignetteColor = color;
            filt1.vignetteStart = VignetteStart;
            filt1.vignetteEnd = VignetteEnd;
            [movieFile addTarget:filt];
            [filt addTarget:filt1];
            [filt1 addTarget:filters];
        }
            break;
        case 7:
        {
            //Old school
            GPUImageFilter *filter = [[GPUImageFilter alloc]init];
            filters = filter;
            GPUImageSepiaFilter *filt = [[GPUImageSepiaFilter alloc]init];
            GPUImageVignetteFilter *filt1 = [[GPUImageVignetteFilter alloc]init];
            filt1.vignetteColor = color;
            filt1.vignetteStart = LVignetteStart;
            filt1.vignetteEnd = LVignetteEnd;
            [movieFile addTarget:filt];
            [filt addTarget:filt1];
            [filt1 addTarget:filters];
        }
            break;
        case 8:
        {
            //#import "GPUImageVignetteFilter.h" //晕影，形成黑色圆形边缘，突出中间图像的效果
            GPUImageVignetteFilter *filt = [[GPUImageVignetteFilter alloc]init];
            struct GPUVector3  color;
            color.one = 1;
            color.two = 1;
            color.three = 1;
            filt.vignetteColor = color;
            filt.vignetteStart = 0.5;
            filt.vignetteEnd = 0.75;
            filters = filt;
            [movieFile addTarget:filters];
        }
            break;
        case 9:
        {
            //锐化
            GPUImageSharpenFilter *filt = [[GPUImageSharpenFilter alloc]init];
            filt.sharpness = 4;
            filters = filt;
            [movieFile addTarget:filters];
        }
            break;
        case 10:
        {
            //#import "GPUImageGaussianSelectiveBlurFilter.h" //高斯模糊，选择部分清晰
            GPUImageGaussianSelectiveBlurFilter *filt = [[GPUImageGaussianSelectiveBlurFilter alloc]init];
            filt.excludeCircleRadius = 0.8;
            filt.blurRadiusInPixels = 10;
            filters = filt;
            [movieFile addTarget:filters];
        }
            break;
        case 11:
        {
            //#import "GPUImageLowPassFilter.h" //用于图像加亮
            GPUImageLowPassFilter *filt = [[GPUImageLowPassFilter alloc]init];
            filters = filt;
            [movieFile addTarget:filters];
        }
            break;
        case 12:
        {
            //"GPUImageBulgeDistortionFilter.h" //凸起失真，鱼眼效果 #import "GPUImagePinchDistortionFilter.h" //收缩失真，凹面镜 #import
            // #import "GPUImageSwirlFilter.h" //漩涡，中间形成卷曲的画面 #import"GPUImageStretchDistortionFilter.h" //伸展失真，哈哈镜
            //#import "GPUImageGlassSphereFilter.h" //水晶球效果
            //#import "GPUImageSphereRefractionFilter.h" //球形折射，图形倒立
            GPUImageBulgeDistortionFilter *filt = [[GPUImageBulgeDistortionFilter alloc]init];
            filt.radius = 0.5; // 失真半径
            filt.scale = 0.15; // 变形量
            filters = filt;
            [movieFile addTarget:filters];
        }
            break;
        case 13:
        {
            //GPUImageSketchFilter.h" //素描
            GPUImageSketchFilter *filt = [[GPUImageSketchFilter alloc]init];
            filters = filt;
            [movieFile addTarget:filters];
        }
            break;
        default:
            break;
    }
    
    [filters addTarget:filterView];
}


#pragma mark - 视频滤镜处理
+ (GPUImageOutput<GPUImageInput> *)addVideoFilter:(GPUImageMovie *)movieFile index:(NSInteger)index
{
    GPUImageOutput<GPUImageInput> *filterCurrent;
    struct GPUVector3  color;
    color.one = 38/255;
    color.two = 38/255;
    color.three = 38/255;
    switch (index) {
        case 0:
        {
            // 原
            GPUImageFilter *filt = [[GPUImageFilter alloc]init];
            filterCurrent = filt;
            [movieFile addTarget:filterCurrent];
        }
            break;
        case 1:
        {
            //Girl style
            GPUImageFilter *filter = [[GPUImageFilter alloc]init];
            GPUImageMissEtikateFilter *filt = [[GPUImageMissEtikateFilter alloc]init];
            GPUImageVignetteFilter *filt1 = [[GPUImageVignetteFilter alloc]init];
            filt1.vignetteColor = color;
            filt1.vignetteStart = VignetteStart;
            filt1.vignetteEnd = VignetteEnd;
            [movieFile addTarget:filt];
            [filt addTarget:filt1];
            [filt1 addTarget:filter];
            filterCurrent = filt1;
        }
            break;
        case 2:
        {
            // TBSoftEleganceFilter
            GPUImageFilter *filter = [[GPUImageFilter alloc]init];
            TBSoftEleganceFilter *filt = [[TBSoftEleganceFilter alloc]init];
            GPUImageVignetteFilter *filt1 = [[GPUImageVignetteFilter alloc]init];
            filt1.vignetteColor = color;
            filt1.vignetteStart = VignetteStart;
            filt1.vignetteEnd = VignetteEnd;
            [movieFile addTarget:filt];
            [filt addTarget:filt1];
            [filt1 addTarget:filter];
            filterCurrent = filt1;
        }
            break;
        case 3:
        {
            //Funky
            GPUImageFilter *filter = [[GPUImageFilter alloc]init];
            TBSexyFilter *filt = [[TBSexyFilter alloc]init];
            GPUImageVignetteFilter *filt1 = [[GPUImageVignetteFilter alloc]init];
            filt1.vignetteColor = color;
            filt1.vignetteStart = VignetteStart;
            filt1.vignetteEnd = VignetteEnd;
            [movieFile addTarget:filt];
            [filt addTarget:filt1];
            [filt1 addTarget:filter];
            filterCurrent = filt1;
        }
            break;
        case 4:
        {
            //Waltz
            GPUImageFilter *filter = [[GPUImageFilter alloc]init];
            TBLOMOFilter *filt = [[TBLOMOFilter alloc] init];
            GPUImageVignetteFilter *filt1 = [[GPUImageVignetteFilter alloc]init];
            filt1.vignetteColor = color;
            filt1.vignetteStart = VignetteStart;
            filt1.vignetteEnd = VignetteEnd;
            [movieFile addTarget:filt];
            [filt addTarget:filt1];
            [filt1 addTarget:filter];
            filterCurrent = filt1;
        }
            break;
        case 5:
        {
            //黑白M.J
            GPUImageFilter *filter = [[GPUImageFilter alloc]init];
            TBBlackWhiteFiter *filt = [[TBBlackWhiteFiter alloc]init];
            GPUImageVignetteFilter *filt1 = [[GPUImageVignetteFilter alloc]init];
            filt1.vignetteColor = color;
            filt1.vignetteStart = LVignetteStart;
            filt1.vignetteEnd = LVignetteEnd;
            [movieFile addTarget:filt];
            [filt addTarget:filt1];
            [filt1 addTarget:filter];
            filterCurrent = filt1;
        }
            break;
        case 6:
        {
            // TBAmatorkaFilter
            GPUImageFilter *filter = [[GPUImageFilter alloc]init];
            TBAmatorkaFilter *filt = [[TBAmatorkaFilter alloc]init];
            GPUImageVignetteFilter *filt1 = [[GPUImageVignetteFilter alloc]init];
            filt1.vignetteColor = color;
            filt1.vignetteStart = VignetteStart;
            filt1.vignetteEnd = VignetteEnd;
            [movieFile addTarget:filt];
            [filt addTarget:filt1];
            [filt1 addTarget:filter];
            filterCurrent = filt1;
        }
            break;
        case 7:
        {
            //Old school
            GPUImageFilter *filter = [[GPUImageFilter alloc]init];
            GPUImageSepiaFilter *filt = [[GPUImageSepiaFilter alloc]init];
            GPUImageVignetteFilter *filt1 = [[GPUImageVignetteFilter alloc]init];
            filt1.vignetteColor = color;
            filt1.vignetteStart = LVignetteStart;
            filt1.vignetteEnd = LVignetteEnd;
            [movieFile addTarget:filt];
            [filt addTarget:filt1];
            [filt1 addTarget:filter];
            filterCurrent = filt1;
        }
            break;
        case 8:
        {
            //#import "GPUImageVignetteFilter.h" //晕影，形成黑色圆形边缘，突出中间图像的效果
            GPUImageVignetteFilter *filt = [[GPUImageVignetteFilter alloc]init];
            struct GPUVector3  color;
            color.one = 1;
            color.two = 1;
            color.three = 1;
            filt.vignetteColor = color;
            filt.vignetteStart = 0.5;
            filt.vignetteEnd = 0.75;
            filterCurrent = filt;
            [movieFile addTarget:filterCurrent];
        }
            break;
        case 9:
        {
            // A
            //锐化
            GPUImageSharpenFilter *filt = [[GPUImageSharpenFilter alloc]init];
            filt.sharpness = 4;
            filterCurrent = filt;
            [movieFile addTarget:filterCurrent];
        }
            break;
        case 10:
        {
            //#import "GPUImageGaussianSelectiveBlurFilter.h" //高斯模糊，选择部分清晰
            GPUImageGaussianSelectiveBlurFilter *filt = [[GPUImageGaussianSelectiveBlurFilter alloc]init];
            filt.excludeCircleRadius = 0.8;
            filt.blurRadiusInPixels = 10;
            filterCurrent = filt;
            [movieFile addTarget:filterCurrent];
        }
            break;
        case 11:
        {
            //#import "GPUImageLowPassFilter.h" //用于图像加亮
            GPUImageLowPassFilter *filt = [[GPUImageLowPassFilter alloc]init];
            filterCurrent = filt;
            [movieFile addTarget:filterCurrent];
        }
            break;
        case 12:
        {
            //"GPUImageBulgeDistortionFilter.h" //凸起失真，鱼眼效果 #import "GPUImagePinchDistortionFilter.h" //收缩失真，凹面镜 #import
            // #import "GPUImageSwirlFilter.h" //漩涡，中间形成卷曲的画面 #import"GPUImageStretchDistortionFilter.h" //伸展失真，哈哈镜
            GPUImageBulgeDistortionFilter *filt = [[GPUImageBulgeDistortionFilter alloc]init];
            filt.radius = 0.5; // 失真半径
            filt.scale = 0.15; // 变形量
            filterCurrent = filt;
            [movieFile addTarget:filterCurrent];
        }
            break;
        case 13:
        {
            //GPUImageSketchFilter.h" //素描
            GPUImageSketchFilter *filt = [[GPUImageSketchFilter alloc]init];
            filterCurrent = filt;
            [movieFile addTarget:filterCurrent];
        }
            break;
        default:
            break;
    }
    
    return filterCurrent;
}


@end

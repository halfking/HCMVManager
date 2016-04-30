//
//  ImageToVideo.m
//  editor
//
//  Created by Matthew on 15/8/31.
//  Copyright (c) 2015年 SeenVoice. All rights reserved.
//

#import "ImageToVideo.h"
//#import "UIKit/UIImagePickerController.h"
#import "UIKit/UIImage.h"
#import <hccoren/RegexKitLite.h>
#import <hccoren/base.h>
#import <hcbasesystem/publicenum.h>
#import <hccoren/images.h>

//#import "DDAudioLRCParser.h"
#import "LyricItem.h"
#import "LyricLayerAnimation.h"
#import "LyricHelper.h"
#import "mvconfig.h"

CGSize const DefaultFrameSize                             = (CGSize){480, 320};
NSInteger const DefaultFrameRate                          = 1;
NSInteger const TransitionFrameCount                      = 50;
NSInteger const FramesToWaitBeforeTransition              = 40;

BOOL const DefaultTransitionShouldAnimate = YES;

@implementation ImagesToVideo
//图片大小必须为16的倍数，生成视频不花
+ (CGSize)correctSize:(CGSize)orgSize
{
    int width = orgSize.width;
    int height = orgSize.height;
    int diff = width%16;
    if(diff!=0)
    {
        if(diff >= 8)
        {
            width += 16 - diff;
        }
        else
        {
            width -= diff;
        }
    }
    diff = height%16;
    if(diff!=0)
    {
        if(diff >= 8)
        {
            height += 16 - diff;
        }
        else
        {
            height -= diff;
        }
    }
    return CGSizeMake(width, height);
}
+ (CGSize) correctSizeWithoutOrientation:(CGSize)targetSize sourceSize:(CGSize)sourceSize
{
    CGSize renderSize = targetSize;
    if(renderSize.width ==0||renderSize.height==0)
    {
        renderSize = CGSizeMake(1280, 720);
    }
    CGFloat rateSource = sourceSize.width/sourceSize.height;
    CGFloat rateTarget = renderSize.width/renderSize.height;
    
    if((rateSource >=1 && rateTarget>=1) ||(rateSource < 1 && rateTarget<1 ))
    {
        if(sourceSize.width> renderSize.width||sourceSize.height> renderSize.height)
        {
            renderSize = [ImagesToVideo correctSize:renderSize sourceSize:sourceSize keep16:NO];
        }
        else
        {
            renderSize = sourceSize;
        }
    }
    else
    {
        if(sourceSize.width> renderSize.height||sourceSize.height> renderSize.width)
        {
            renderSize = [ImagesToVideo correctSize:CGSizeMake(renderSize.height, renderSize.width) sourceSize:sourceSize keep16:NO];
        }
        else
        {
            renderSize = sourceSize;
        }
    }
    return renderSize;
}
+ (CGSize) correctSize:(CGSize)targetSize sourceSize:(CGSize)sourceSize keep16:(BOOL)keep16
{
    CGSize imgSize = sourceSize;
    CGSize videoOutputSize;// = imgSize;
    //计算比例,ratio>1表示比预期宽的图片 <1 表示比预期高的图片
    float ratio = targetSize.width * imgSize.height / targetSize.height / imgSize.width;
    float scale = 1;
    float maxRatio = 3;
    float minRatio = 1/maxRatio;
    
    NSLog(@"deviceheight:%f version:%f",[DeviceConfig config].Height * [DeviceConfig config].Scale,[DeviceConfig config].SysVersion);
    //暂时不清楚一些不显示的原因，因此，将其归为代版本再来处理
    if ([DeviceConfig config].Height * [DeviceConfig config].Scale <= 1136||[DeviceConfig config].SysVersion <9) {
        //
        maxRatio = 2;
        minRatio = 1/maxRatio;
    }
    
    //寻找最匹配的展示
    if (ratio <= maxRatio && ratio >= minRatio) {
        scale = MIN(imgSize.width/targetSize.width, imgSize.height/targetSize.height);
    } else {
        scale = MAX(imgSize.width/targetSize.width, imgSize.height/targetSize.height);
    }
    
    videoOutputSize = CGSizeMake(round(imgSize.width/scale), round(imgSize.height/scale));
    if(keep16)
        return [self correctSize:videoOutputSize];
    else
        return videoOutputSize;
}
//+ (void)saveVideoToPhotosWithImage:(UIImage *)image
//                              item:(VideoItem *)item
//                 withCallbackBlock:(SuccessBlock)callbackBlock
//{
//    image = [image normalizedImage:UIImageOrientationLeft];
//
//    CGSize imgSize = CGSizeMake(CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage));
//    //    CGSize videoOutputSize;// = imgSize;
//    //    //计算比例,ratio>1表示比预期宽的图片 <1 表示比预期高的图片
//    //    float ratio = item.renderSize.width * imgSize.height / item.renderSize.height / imgSize.width;
//    //    float scale = 1;
//    //    float maxRatio = 3;
//    //    float minRatio = 1/maxRatio;
//    //
//    //    NSLog(@"deviceheight:%f version:%f",[DeviceConfig config].Height * [DeviceConfig config].Scale,[DeviceConfig config].SysVersion);
//    //    //暂时不清楚一些不显示的原因，因此，将其归为代版本再来处理
//    //    if ([DeviceConfig config].Height * [DeviceConfig config].Scale <= 1136||[DeviceConfig config].SysVersion <9) {
//    //        //
//    //        maxRatio = 2;
//    //        minRatio = 1/maxRatio;
//    //    }
//    //
//    //    //寻找最匹配的展示
//    //    if (ratio <= maxRatio && ratio >= minRatio) {
//    //        scale = MIN(imgSize.width/item.renderSize.width, imgSize.height/item.renderSize.height);
//    //    } else {
//    //        scale = MAX(imgSize.width/item.renderSize.width, imgSize.height/item.renderSize.height);
//    //    }
//    //
//    //    videoOutputSize = CGSizeMake(round(imgSize.width/scale), round(imgSize.height/scale));
//    //
//    //    //    //  因为我们是横屏，照片一般竖屏拍时，比较高
//    //    //    if (videoOutputSize.width != item.renderSize.width && videoOutputSize.height == item.renderSize.height) {
//    //    ////    if (videoOutputSize.width < videoOutputSize.height) {
//    //    //        //横向的image   height=720 则将图片旋转过来
//    //    ////        image = [[UIImage alloc] initWithCGImage:image.CGImage scale:image.scale orientation:UIImageOrientationLeft];
//    //    //        image = [image normalizedImage:UIImageOrientationLeft];
//    //    //        videoOutputSize = CGSizeMake(videoOutputSize.height, videoOutputSize.width);
//    //    //    }
//    //
//    //    videoOutputSize = [self correctSize:videoOutputSize];
////    CGRect rect = [CommonUtil rectFitWithScale:imgSize rectMask:item.renderSize];
//
//    CGSize videoOutputSize = [self correctSize:item.renderSize sourceSize:imgSize keep16:YES];
//
//    NSLog(@"image2video :ouputSize.Width = %f, Height=%f", videoOutputSize.width, videoOutputSize.height);
//    UIImage * outImage = [ImagesToVideo OriginImage:image scaleToSize:videoOutputSize];
//
//    [ImagesToVideo writeImageToMovie:outImage
//                              toPath:item.path
//                                size:videoOutputSize
//                                 fps:item.duration.timescale
//                  animateTransitions:YES
//                          repeatTime:CMTimeGetSeconds(item.duration)
//                   withCallbackBlock:^(BOOL success,CGFloat progress) {
//                       item.generateProgress = progress;
//                       if(success && progress>=1)
//                       {
//                           item.status = YES;
//                       }
//                       else if(success)
//                       {
//                           item.lastGenerateInterval = [CommonUtil getDateTicks:[NSDate date]];
//                           //UISaveVideoAtPathToSavedPhotosAlbum([[NSURL fileURLWithPath:item.path] path], self, nil, nil);
//
//                       }
//                       if (callbackBlock) {
//                           callbackBlock(success,progress);
//                       }
//                   }];
//}

+ (void)generateVideoByImage:(UIImage *)image
                        item:(MediaItem *)item
           withCallbackBlock:(SuccessBlock)callbackBlock
{
    image = [image normalizedImage:UIImageOrientationLeft];
    
    CGSize imgSize = CGSizeMake(CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage));
    
    CGSize videoOutputSize = [self correctSize:item.renderSize sourceSize:imgSize keep16:YES];
    
    NSLog(@"image2video :ouputSize.Width = %f, Height=%f", videoOutputSize.width, videoOutputSize.height);
    UIImage * outImage = [ImagesToVideo OriginImage:image scaleToSize:videoOutputSize];
    
    [ImagesToVideo writeImageToMovie:outImage
                              toPath:item.fileName
                                size:videoOutputSize
                                 fps:item.duration.timescale
                  animateTransitions:YES
                          repeatTime:item.secondsDuration
                   withCallbackBlock:^(BOOL success,CGFloat progress) {
                       item.generateProgress = progress;
                       if(success && progress>=1)
                       {
                           item.status = YES;
                       }
                       else if(success)
                       {
                           item.lastGenerateInterval = [CommonUtil getDateTicks:[NSDate date]];
                       }
                       if (callbackBlock) {
                           callbackBlock(success,progress);
                       }
                   }];
}


+(UIImage*) OriginImage:(UIImage *)image scaleToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);  //size 为CGSize类型，即你所需要的图片尺寸
    
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;   //返回的就是已经改变的图片
}
+ (void)writeImageToMovie:(UIImage *)image
                   toPath:(NSString*)path
                     size:(CGSize)size
                      fps:(int)fps
       animateTransitions:(BOOL)shouldAnimateTransitions
               repeatTime:(CGFloat)repeatTime
        withCallbackBlock:(SuccessBlock)callbackBlock
{
    
    NSLog(@"image2video :ready to write video: %@(%@)", [path lastPathComponent],NSStringFromCGSize(size));
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"image2video :删除同名文件！！！%@",[path lastPathComponent]);
        if ([[NSFileManager defaultManager] removeItemAtPath:path error:&error])
        {
            //            NSLog(@"删除文件成功！！！");
        } else {
            NSLog(@"image2video :删除文件失败！！！%@",[error description]);
        }
    }
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                           fileType:AVFileTypeMPEG4
                                                              error:&error];
    if (error) {
        NSLog(@"image2video :创建文件%@失败！！！%@",[path lastPathComponent],[error description]);
        if (callbackBlock) {
            callbackBlock(NO,0);
        }
        return;
    }
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = @{AVVideoCodecKey: AVVideoCodecH264,
                                    AVVideoWidthKey: [NSNumber numberWithInt:size.width],
                                    AVVideoHeightKey: [NSNumber numberWithInt:size.height]};
    
    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                         outputSettings:videoSettings];
    NSLog(@"image2video: ready 1");
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                                                                                     sourcePixelBufferAttributes:nil];
    [videoWriter addInput:writerInput];
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    NSLog(@"image2video: ready 2");
    CVPixelBufferRef buffer;
    //    CVPixelBufferPoolCreatePixelBuffer(NULL, adaptor.pixelBufferPool, &buffer);
    //
    //    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CMTime presentTime;// = CMTimeMake(0, fps);
    NSLog(@"image2video: ready 3");
    int i = 0;
    
    while (1) {
        if(writerInput.readyForMoreMediaData){
            
            presentTime = CMTimeMake(i, fps);
            
            //有可能不为整
            if (i >= 1) {
                buffer = NULL;
            } else {
                buffer = [ImagesToVideo pixelBufferFromCGImage2:image.CGImage size:size];
                NSLog(@"image2video: ready 4");
            }
            
            if (buffer) {
                //append buffer
                
                BOOL appendSuccess = [ImagesToVideo append2Adapter:adaptor
                                                       pixelBuffer:buffer
                                                            atTime:presentTime
                                                         withInput:writerInput];
                NSLog(@"image2video: ready 5");
                i++;
                CVPixelBufferRelease(buffer);
                if (!appendSuccess) {
                    callbackBlock(NO,1);
                }
                else
                {
                    callbackBlock(YES,(CGFloat)i/1);
                }
            } else {
                
                //Finish the session:
                [writerInput markAsFinished];
                
                [videoWriter finishWritingWithCompletionHandler:^{
                    NSLog (@"image2video : %@ write done ",[path lastPathComponent]);
                    //NSLog(@"Successfully closed video writer");
                    if (videoWriter.status == AVAssetWriterStatusCompleted) {
                        
                        //                        [self writeCompletedFlagFile:path];
                        
                        if (callbackBlock) {
                            callbackBlock(YES,1);
                        }
                    } else {
                        if (callbackBlock) {
                            callbackBlock(NO,1);
                        }
                    }
                }];
                NSLog(@"image2video: ready 6");
                CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
                break;
            }
        }
        
    }
}
+ (void)writeImageToMovieN:(UIImage *)image
                    toPath:(NSString*)path
                      size:(CGSize)size
                       fps:(CGFloat)fps
                   seconds:(CGFloat)seconds
               orientation:(UIDeviceOrientation)orientation
         withCallbackBlock:(SuccessBlock)callbackBlock
{
    CGSize videoOutputSize = size;
    //    image = [image normalizedImage:UIImageOrientationLeft];
    //
    //    CGSize imgSize = CGSizeMake(CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage));
    //    CGSize videoOutputSize = [self correctSize:size sourceSize:imgSize keep16:YES];
    //
    //    NSLog(@"image2video :ouputSize.Width = %f, Height=%f", videoOutputSize.width, videoOutputSize.height);
    //    UIImage * outImage = [ImagesToVideo OriginImage:image scaleToSize:videoOutputSize];
    
    NSLog(@"image2video :ready to write video: %@(%@)", [path lastPathComponent],NSStringFromCGSize(size));
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if ([[NSFileManager defaultManager] removeItemAtPath:path error:&error])
        {
        } else {
            NSLog(@"image2video :删除文件失败！！！%@",[error description]);
        }
    }
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                           fileType:AVFileTypeMPEG4
                                                              error:&error];
    if (error) {
        NSLog(@"image2video :创建文件%@失败！！！%@",[path lastPathComponent],[error description]);
        if (callbackBlock) {
            callbackBlock(NO,0);
        }
        return;
    }
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = @{AVVideoCodecKey: AVVideoCodecH264,
                                    AVVideoWidthKey: [NSNumber numberWithInt:size.width],
                                    AVVideoHeightKey: [NSNumber numberWithInt:size.height]};
    
    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                         outputSettings:videoSettings];
    
    //加了的话，合成背景要能有问题。暂不处理
    //    if(orientation == UIDeviceOrientationPortrait)
    //        writerInput.transform = CGAffineTransformMakeRotation( M_PI * 90 / 180);
    //    else
    //        writerInput.transform = CGAffineTransformIdentity;
    
    NSLog(@"image2video: ready 1");
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                                                                                     sourcePixelBufferAttributes:nil];
    [videoWriter addInput:writerInput];
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    NSLog(@"image2video: ready 2");
    CVPixelBufferRef buffer;
    
    CMTime presentTime;// = CMTimeMake(0, fps);
    NSLog(@"image2video: ready 3");
    int i = 0;
    int step = 1;
    int frames = MAX(1,seconds * fps);
    if(fps<1 && fps>0)
    {
        step =  frames/3;
        fps = 1;
    }
    
    while (1) {
        if(writerInput.readyForMoreMediaData){
            
            presentTime = CMTimeMake(i, fps);
            
            //有可能不为整
            if (i >= frames) {
                buffer = NULL;
            } else {
                buffer = [ImagesToVideo pixelBufferFromCGImage2:image.CGImage size:videoOutputSize];
                NSLog(@"image2video: ready 4");
            }
            
            if (buffer) {
                //append buffer
                
                BOOL appendSuccess = [ImagesToVideo append2Adapter:adaptor
                                                       pixelBuffer:buffer
                                                            atTime:presentTime
                                                         withInput:writerInput];
                NSLog(@"image2video: ready 5");
                i+= step;
                CVPixelBufferRelease(buffer);
                if (!appendSuccess) {
                    callbackBlock(NO,1);
                }
                else
                {
                    CGFloat percent = (CGFloat)i/frames;
                    if(percent>=1.0)
                        percent = 0.999;
                    callbackBlock(YES,percent);
                }
            } else {
                
                //Finish the session:
                [writerInput markAsFinished];
                
                [videoWriter finishWritingWithCompletionHandler:^{
                    NSLog (@"image2video : %@ write done ",[path lastPathComponent]);
                    if (videoWriter.status == AVAssetWriterStatusCompleted) {
                        if (callbackBlock) {
                            callbackBlock(YES,1);
                        }
                    } else {
                        if (callbackBlock) {
                            callbackBlock(NO,1);
                        }
                    }
                }];
                NSLog(@"image2video: ready 6");
                CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
                break;
            }
        }
    }
}
+ (void)writeCompletedFlagFile:(NSString *)videoFilePath
{
    NSString * keyPath = [videoFilePath stringByAppendingPathExtension:@"chk"];
    NSFileManager * fm  = [NSFileManager defaultManager];
    NSString * string = [CommonUtil stringFromDate:[NSDate date]];
    
    NSData * data = [string dataUsingEncoding:NSUTF8StringEncoding];
    if([fm fileExistsAtPath:keyPath])
    {
        NSFileHandle * fh = [NSFileHandle fileHandleForUpdatingAtPath:keyPath];
        [fh seekToEndOfFile];
        [fh writeData:data];
        [fh closeFile];
        return;
    }
    else
    {
        [data writeToFile:keyPath atomically:YES];
    }
}
+ (CVPixelBufferRef)pixelBufferFromCGImage2:(CGImageRef)image
                                       size:(CGSize)imageSize
{
    NSLog(@"image2video : ready buffer :%@",NSStringFromCGSize(imageSize));
    
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES,
                              (id)kCVPixelBufferWidthKey:[NSNumber numberWithInt:imageSize.width],
                              (id)kCVPixelBufferHeightKey:[NSNumber numberWithInt:imageSize.height]};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, imageSize.width,
                                          imageSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    if(status!=kCVReturnSuccess)
    {
        NSLog(@"image2video : ready buffer failure:%d",status);
    }
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    //真正的输出宽高是这里的两个数值
    CGContextRef context = CGBitmapContextCreate(pxdata, imageSize.width,
                                                 imageSize.height, 8, 4*imageSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    //图片视频静止
    CGRect rec = CGRectMake(0,0,CGImageGetWidth(image),CGImageGetHeight(image));
    
    CGContextDrawImage(context, rec, image);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (BOOL)append2Adapter:(AVAssetWriterInputPixelBufferAdaptor*)adaptor
           pixelBuffer:(CVPixelBufferRef)buffer
                atTime:(CMTime)presentTime
             withInput:(AVAssetWriterInput*)writerInput
{
    while (!writerInput.readyForMoreMediaData) {
        [NSThread sleepForTimeInterval:5];
    }
    BOOL result = [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
    return result;
    
}
#pragma mark - get lpresentTime	CMTime	yric animates
+ (CALayer *)buildWaterMarkerLayer:(NSString *)imageFilePath renderSize:(CGSize)renderSize
{
    UIImage * image = [UIImage imageNamed:imageFilePath];
    if(!image)
    {
        image = [UIImage imageWithContentsOfFile:imageFilePath];
    }
    if(image){
        
        CGSize imgSize = image.size;
        
        //放在一点，看清楚
#ifndef __OPTIMIZE__
        imgSize.width *=2;
        imgSize.height *=2;
#endif
        CALayer *backgroundLayer = [CALayer layer];
        CGRect frame = CGRectMake(renderSize.width - imgSize.width - 20,renderSize.height - imgSize.height-20,imgSize.width,imgSize.height);
        backgroundLayer.frame = frame;
        
        [backgroundLayer setContents:(id)[image CGImage]];
        return backgroundLayer;
    }
    return nil;
}
+ (CALayer *)buildTitleLayer:(NSString *)title singer:(NSString*)singer renderSize:(CGSize)renderSize
{
    if(title && title.length>0)
    {
        CALayer * lrcTextLayer = [CALayer layer];
        lrcTextLayer.frame = CGRectMake((renderSize.width - 200)/2.0f,(renderSize.height - 100)/2.0f, 200, 100);
        
//        CGFloat endTime = beginTime + videoDuration;
//        if(videoDuration <0) endTime = -1;
//        NSArray * lyricItemsFiltered = [ImagesToVideo filterLyricItems:lrcList beginTime:beginTime endTime:endTime];
//        
//        CAAnimationGroup * animation  = [LyricLayerAnimation animationWithLyrics:lyricItemsFiltered  witAniType:Scale size:lrcTextLayer.frame.size font:FONT_TITLES];
//        
//        [lrcTextLayer addAnimation:animation forKey:nil];
        return lrcTextLayer;
    }
    return nil;
}
+ (CALayer *)getLrcAnimationLayer:(CGFloat)beginTime duration:(CGFloat)videoDuration
                              lrc:(NSArray *)lrcList orientation:(int)orientation
                       renderSize:(CGSize) renderSize rate:(CGFloat)rate filterLyrics:(NSArray **)filterLyrics
{
        if(renderSize.width < renderSize.height)
        {
            CGFloat w = renderSize.width;
            renderSize.width = renderSize.height;
            renderSize.height = w;
        }
    CALayer * OptLrcLayer = [CALayer layer];
    {
        switch (orientation) {
            case UIDeviceOrientationLandscapeLeft:
            case UIDeviceOrientationLandscapeRight:
                OptLrcLayer.frame = CGRectMake(0, 0, renderSize.width, renderSize.height);
                break;
            case UIDeviceOrientationPortraitUpsideDown:
            default:
                OptLrcLayer.frame = CGRectMake(0, 0, renderSize.height, renderSize.width);
                break;
        }
        OptLrcLayer.opacity = 1;
    }
    
    
    
    if(lrcList && lrcList.count>0)
    {
        CALayer * lrcTextLayer = [CALayer layer];
        lrcTextLayer.frame = CGRectMake(0, 0, OptLrcLayer.frame.size.width, 120);
        
        CGFloat endTime = beginTime + videoDuration;
        if(videoDuration <0) endTime = -1;
        NSArray * lyricItemsFiltered = [ImagesToVideo filterLyricItems:lrcList beginTime:beginTime endTime:endTime];
        if(filterLyrics)
        {
            * filterLyrics = lyricItemsFiltered;
        }
        
        //       CAKeyframeAnimation * animation =  [LyricLayerAnimation scaleLyricsN:lyricItemsFiltered size:lrcTextLayer.frame.size font:FONT_TITLES];
        CAAnimationGroup * animation  = [LyricLayerAnimation animationWithLyrics:lyricItemsFiltered  witAniType:Scale size:lrcTextLayer.frame.size font:FONT_LYRIC rate:rate];
        
        [lrcTextLayer addAnimation:animation forKey:nil];
        return lrcTextLayer;
    }
    return OptLrcLayer;
}
+ (NSArray *)parseLyricItems:(NSArray *)lrcItems beginTime:(CGFloat)beginTime endTime:(CGFloat)endTime
{
    NSMutableArray * temLyricItems = [NSMutableArray new];
    if(!lrcItems || lrcItems.count==0) return temLyricItems;
    if(endTime<0) endTime = 10000000000;
    for (int i = 0; i <lrcItems.count ; i ++) {
        LyricItem * curUnit = [lrcItems objectAtIndex:i];
        //        DDAudioLRCUnit * curUnit = [lrcFile.units objectAtIndex:i];
        if (curUnit.begin < beginTime || curUnit.begin > endTime) {
            continue;
        }
        LyricItem * item = [[LyricItem alloc] init];
        item.begin = curUnit.begin - beginTime;
        item.text = curUnit.text;
        if (i >= lrcItems.count - 1 ) { //最后1个
            item.duration = endTime - curUnit.begin;
        } else {
            LyricItem * nextUnit = [lrcItems objectAtIndex:i+1];
            //            DDAudioLRCUnit * nextUnit = [lrcFile.units objectAtIndex:i + 1];
            if (nextUnit.begin <= endTime) {
                item.duration = nextUnit.begin - curUnit.begin - 0.2;
            } else {
                item.duration = endTime - curUnit.begin - 0.2;
            }
        }
        if (item.duration < 0.5) {
            //剔除开始唱和结尾出现截取一半歌词的问题
            continue;
        }
        [temLyricItems addObject:item];
    }
    return temLyricItems;
}
+ (NSArray *)filterLyricItems:(NSArray *)lrcItems beginTime:(CGFloat)beginTime endTime:(CGFloat)endTime
{
    NSMutableArray * temLyricItems = [NSMutableArray new];
    if(!lrcItems ||  lrcItems.count==0) return temLyricItems;
    if(endTime <0) endTime = 10000000;
    
    for (int i = 0; i <lrcItems.count ; i ++) {
        LyricItem * orgItem = [lrcItems objectAtIndex:i];
        if (orgItem.begin < beginTime || orgItem.begin > endTime) {
            continue;
        }
        //create new items
        LyricItem * item = [[LyricItem alloc] init];
        item.begin = orgItem.begin - beginTime;
        item.text = orgItem.text;
        if (i >= lrcItems.count - 1 ) { //最后1个
            item.duration = endTime - orgItem.begin;
        } else {
            LyricItem * nextUnit = [lrcItems objectAtIndex:i + 1];
            if (nextUnit.begin <= endTime) {
                item.duration = nextUnit.begin - orgItem.begin - 0.2;
            } else {
                item.duration = endTime - orgItem.begin - 0.2;
            }
        }
        if (item.duration < 0.5) {
            //剔除开始唱和结尾出现截取一半歌词的问题
            continue;
        }
        [temLyricItems addObject:item];
    }
    return temLyricItems;
}
@end
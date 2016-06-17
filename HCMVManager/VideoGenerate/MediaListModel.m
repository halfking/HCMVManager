//
//  MediaItem2Video.m
//  maiba
//
//  Created by HUANGXUTAO on 16/4/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "MediaListModel.h"
#import <hccoren/base.h>
#import <hccoren/RegexKitLite.h>
#import <hcbasesystem/UDManager(Helper).h>
#import <hccoren/images.h>
#import "MediaItem.h"
#import "ImageToVideo.h"

@interface MediaListModel()
{
    dispatch_queue_t    img2VideoThread_;
    NSMutableArray *    mediaList_;
    UDManager *         udManager_;
    
    BOOL isImage2VideoDoing_;
    
    BOOL isGenerateMVByCover_;//正在根据封面合成视频
}
@end

@implementation MediaListModel
+(id)shareObject
{
    static dispatch_once_t pred = 0;
    static MediaListModel *instance_ = nil;
    dispatch_once(&pred,^
                  {
                      instance_ = [[MediaListModel alloc] init];
                  });
    return instance_;
}
- (id)init
{
    if(self = [super init])
    {
        mediaList_ = [NSMutableArray new];
        img2VideoThread_  = dispatch_queue_create("com.seenvoice.ImageToVideo", DISPATCH_QUEUE_SERIAL);
        udManager_ = [UDManager sharedUDManager];
    }
    return self;
}
- (NSArray *)getMediaList
{
    return mediaList_;
}
//检查队列中的视频数据，如果在设定的时间范围外的，排除，并且重新计算相对于设定的时间的起止位置
//resetBegin 是否以新视频的起点位置作为0 点？否，则以原视频的位置作为原点计算位置。比如从原视频10秒开始，那么10秒的位置在新视频中为0
- (NSMutableArray *)checkMediaTimeLine:(CMTime)beginTime
                               endTime:(CMTime)endTime
                            resetBegin:(BOOL)resetBegin
{
    //重新生成chooseQueue
    NSLog(@" add items to choose queue");
    //    [chooseQueue removeAllObjects];
    
    NSMutableArray * videoSegments = [NSMutableArray new];
    if(mediaList_ && mediaList_.count>0)
    {
        for (MediaItem * item in mediaList_) {
            [self checkImgToVideoQueue:item atIndex:-1];
        }
        
        [videoSegments addObjectsFromArray:mediaList_];
        
        NSMutableArray * removeList = [NSMutableArray new];
        
        //检查开始与结束时间的代码
        //        [removeList removeAllObjects];
        if(videoSegments && videoSegments.count>0 && CMTimeCompare(endTime, kCMTimeZero)>0)
        {
            for (MediaItem * item in videoSegments) {
                NSLog(@"item:%.1f(%.1f-%.1f)  begin:%.1f end:%.1f",CMTimeGetSeconds(item.timeInArray),
                      CMTimeGetSeconds(item.begin),CMTimeGetSeconds(item.end),
                      CMTimeGetSeconds(beginTime),CMTimeGetSeconds(endTime));
                
                CMTime duration = CMTimeSubtract(item.end, item.begin);
                CMTime endInQueue = CMTimeAdd(item.timeInArray, duration);
                NSLog(@"duration:%.1f endIn:%.1f",CMTimeGetSeconds(duration),CMTimeGetSeconds(endInQueue));
                if(CMTimeCompare(endInQueue, beginTime)<=0 || CMTimeCompare(item.timeInArray, endTime)>=0)
                {
                    [removeList addObject:item];
                    continue;
                }
                else
                {
                    CMTime durationChanged = kCMTimeZero;
                    if(CMTimeCompare(item.timeInArray, beginTime)<0)
                    {
                        durationChanged = CMTimeSubtract(beginTime,item.timeInArray);
                        item.timeInArray = beginTime;
                        item.begin = CMTimeAdd(item.begin, durationChanged);
                        endInQueue = CMTimeSubtract(endInQueue, durationChanged);
                    }
                    if(CMTimeCompare(endInQueue, endTime)>0)
                    {
                        durationChanged = CMTimeSubtract(endInQueue, endTime);
                        item.end = CMTimeSubtract(item.end, durationChanged);
                    }
                    //重置起点的时间计数
                    if(resetBegin)
                    {
                        item.timeInArray = CMTimeSubtract(item.timeInArray, beginTime);
                    }
                }
                NSLog(@"item:%.1f(%.1f-%.1f)  begin:%.1f end:%.1f",CMTimeGetSeconds(item.timeInArray),
                      CMTimeGetSeconds(item.begin),CMTimeGetSeconds(item.end),
                      CMTimeGetSeconds(beginTime),CMTimeGetSeconds(endTime));
            }
        }
        if(removeList.count>0)
        {
            [videoSegments removeObjectsInArray:removeList];
        }
        
        PP_RELEASE(removeList);
    }
    return PP_AUTORELEASE(videoSegments);
}
//
//- (NSArray *)exportPlayItemArray:(MediaItem*)bgVideo fillWithTrans:(BOOL)fillTrans
//{
//    NSMutableArray * exportArray = [NSMutableArray new];
//    NSInteger index = 0;
//    MediaItem * prevItem = nil;
//    PlayerMediaItem * prevItemNew = nil;
//    //    CGFloat transSeconds_half = SECONDS_TRANS/2.0f;
//    
//    NSLog(@"export items for video....");
//    //根据所有的对像，建立一个没有转场的队列
//    NSArray * fullMedialList = [self getFullMediaList:bgVideo fillEmptyWithBgVideo:NO];
//    
//    //将且要将中断的部分用原视频放出来
//    for (MediaItem * originItem in fullMedialList) {
//        //媒体本身,注意去除前后的转场时间
//        {
//            PlayerMediaItem * pItem = [self toPlayerMediaItem:originItem];
//            
//            [exportArray addObject:pItem];
//            
//            prevItemNew.nextItem = pItem;
//            
//            prevItemNew = pItem;
//            
//        }
//        
//        prevItem = originItem;
//        index ++;
//    }
//    playItemList_ = PP_RETAIN(exportArray);
//    //检查重叠情况，调整精度
//    if(!fillTrans)
//    {
//        NSMutableArray * removeList = [NSMutableArray new];
//        PlayerMediaItem * lastItem = nil;
//        for (PlayerMediaItem * item in playItemList_) {
//            item.prevSecondsInArray = round(item.prevSecondsInArray * 10)/10.0f;
//            item.begin = CMTimeMakeWithSeconds(round(CMTimeGetSeconds(item.begin)*10)/10.0f,item.begin.timescale);
//            item.end = CMTimeMakeWithSeconds(round(CMTimeGetSeconds(item.end)*10)/10.0f,item.end.timescale);
//            CGFloat seconds = CMTimeGetSeconds(item.end) - CMTimeGetSeconds(item.begin);
//            
//            BOOL isOK = NO;
//            if(!lastItem)
//            {
//                if(item.prevSecondsInArray >=0 && item.prevSecondsInArray + seconds <= totalSecondsDuration_)
//                {
//                    isOK = YES;
//                }
//                else
//                {
//                    if(item.prevSecondsInArray<0)
//                        item.prevSecondsInArray =0;
//                    if(item.prevSecondsInArray + seconds> totalSecondsDuration_)
//                    {
//                        item.end = CMTimeMakeWithSeconds(round((totalSecondsDuration_ - item.prevSecondsInArray)*10)/10.0f,item.end.timescale);
//                    }
//                }
//            }
//            else
//            {
//                if(lastItem.prevSecondsInArray + CMTimeGetSeconds(lastItem.end) - CMTimeGetSeconds(lastItem.begin) > item.prevSecondsInArray)
//                {
//                    item.prevSecondsInArray = lastItem.prevSecondsInArray + CMTimeGetSeconds(lastItem.end) - CMTimeGetSeconds(lastItem.begin);
//                }
//                
//                if(item.prevSecondsInArray + seconds <= totalSecondsDuration_)
//                {
//                    isOK = YES;
//                }
//                else
//                {
//                    if(item.prevSecondsInArray + seconds> totalSecondsDuration_)
//                    {
//                        item.end = CMTimeMakeWithSeconds(round((totalSecondsDuration_ - item.prevSecondsInArray)*10/10.0f),item.end.timescale);
//                    }
//                    if(item.prevSecondsInArray>=totalSecondsDuration_)
//                    {
//                        [removeList addObject:item];
//                    }
//                }
//                
//            }
//            lastItem = item;
//            if(!isOK)
//            {
//                NSLog(@"prevItem:%@",[lastItem JSONRepresentationEx]);
//                NSLog(@"currentItem:%@",[item JSONRepresentationEx]);
//                NSLog(@"totalDuration:%f",totalSecondsDuration_);
//            }
//        }
//        if(removeList.count>0)
//        {
//            [exportArray removeObjectsInArray:removeList];
//        }
//        PP_RELEASE(removeList);
//    }
//    NSLog(@"export item to video ok...");
//#ifndef __OPTIMIZE__
//    for (PlayerMediaItem * item in exportArray) {
//        NSLog(@"item:%d prev:%f,begin:%f end:%f",[item.path lastPathComponent],item.prevSecondsInArray,CMTimeGetSeconds(item.begin),CMTimeGetSeconds(item.end));
//    }
//#endif
//    return PP_AUTORELEASE(exportArray);
//}
//获取完整的视频列表，即将背景视频也加入到队列中
//- (NSArray *)getFullMediaList:(MediaItem *)bgVideo fillEmptyWithBgVideo:(BOOL)fill
//{
//    if(!bgVideo.key ||bgVideo.key.length==0)
//    {
//        bgVideo.key = [self getKeyOfItem:bgVideo];
//    }
//    //根据所有的对像，建立一个没有转场的队列
//    NSMutableArray * fullMedialList = [NSMutableArray new];
//    CGFloat lastSeconds = 0;
//    if(coverMedialItem_)
//    {
//        if(!self.NotAddCover)
//        {
//            [fullMedialList addObject:coverMedialItem_];
//        }
//        lastSeconds += coverMedialItem_.secondsDuration;
//    }
//    else
//    {
//        lastSeconds += COVER_SECONDS;
//    }
//    for (MediaItem * item in mediaList_) {
//        if(item.secondsInArray >= totalSecondsDuration_) continue;
//        if(item.secondsDurationInArray >= MINVIDEO_SECONDS)
//        {
//            [fullMedialList addObject:item];
//        }
//        if(item.renderSize.width <10)
//        {
//            item.renderSize = bgVideo.renderSize;
//        }
//        
//        if(item.isImg)
//        {
//            [self checkRenderSize:item];
//        }
//        lastSeconds = item.secondsInArray + item.secondsDurationInArray;
//    }
//    return PP_AUTORELEASE(fullMedialList);
//}

//检查是否可以开始合成了。
-(BOOL) checkTempAVStatus
{
    BOOL status = YES;
    
    for (int i=0; i<mediaList_.count; i++) {
        MediaItem * item = [mediaList_ objectAtIndex:i];
        if ( !item.status ) {
            if([self checkIsExistsVideo:item.filePath isOrgImage:item.isImg])
            {
                item.status =  YES;
            }
            else
            {
                status = NO;
                
                dispatch_async(img2VideoThread_, ^{
                    [self imageToVideo:item fullPath:item.filePath videoIndex:-1 force:NO];
                });
                //                break;
            }
        }
    }
    return status;
}
- (NSString *) generateImage2Video:(MediaItem *)item
{
    //item.filePath =
    [self getVideoPath:item];
    [self checkImgToVideoQueue:item atIndex:-1];
    return item.filePath;
    //    VideoItem * tVideoItem = [self transMediaToVideoItem:item];
    //    [self checkImgToVideoQueue:tVideoItem atIndex:-1];
    //    return tVideoItem.path;
    
}
#pragma mark - list manager
- (void) addMediaItem:(MediaItem *)item atIndex:(NSInteger)index
{
    //可能有多个同样的文件在队列中，则不需要再添加生成事件
    [mediaList_ insertObject:item atIndex:index];
    if(item.isImg)
    {
        if(![self findItemsWithSameMediaFile:item existList:nil])
        {
            [self generateImage2Video:item];
        }
    }
//    else if(item.playRate <0 && [item.filePath rangeOfString:@"reverse_"].location==NSNotFound)
//    {
//        item.status = NO;
//        
//    }
}
- (void) removeMediaItem:(MediaItem *)item
{
    //    BOOL isFind = NO;
    MediaItem * existItem = nil;
    int sameCount = 0;
    for (MediaItem * cItem in mediaList_) {
        if(cItem == item ||
           ([cItem.url.absoluteString isEqualToString:item.url.absoluteString]
            && cItem.secondsInArray == item.secondsInArray
            ))
        {
            existItem = cItem;
            //            isFind = YES;
            sameCount ++;
        }
        else if([cItem.fileName isEqualToString:item.fileName])
        {
            sameCount ++;
        }
    }
    if(sameCount>0 && existItem)
    {
        [mediaList_ removeObject:existItem];
        
        if(sameCount<=1)
        {
            [self removeFileAssociateWithPath:existItem.filePath];
        }
    }
}

//- (void)addToImageGenerateQueue:(MediaItem *)item needCheckExists:(BOOL)checkExists
//{
//    BOOL isFind = NO;
//    if(checkExists)
//    {
//        isFind = [self findItemInImageToGenerate:item existList:nil];
//    }
//    if(!isFind)
//    {
//        [mediaList_ addObject:item];
//    }
//}

-(MediaItem *)checkImgToVideoQueue:(MediaItem *) tVideoItem atIndex:(NSInteger)targetIndex
{
    if(tVideoItem.isImg)
    {
        NSMutableArray * existList = [NSMutableArray new];
        
        BOOL isFind = [self findItemsWithSameMediaFile:tVideoItem existList:&existList];
        if(isFind)   //i如果已经有同一个媒体
        {
            //可能有多个同样的文件在队列中，因此只要有一个已经完成，就认为它完成了
            for (MediaItem * item in existList) {
                if(item.status)
                {
                    tVideoItem.status = YES;
                    break;
                }
            }
        }
        else
        {
            //检查文件中是否已经有现成的视频
            tVideoItem.status = [self checkIsExistsVideo:tVideoItem.filePath
                                              isOrgImage:tVideoItem.isImg];
        }
        //异步生成视频
        if(!tVideoItem.status)
        {
            NSLog(@"generate image to video:%@",[tVideoItem.fileName lastPathComponent]);
            __weak typeof(self) weakSelf = self;
            dispatch_async(img2VideoThread_, ^{
                [weakSelf imageToVideo:tVideoItem
                              fullPath:tVideoItem.filePath
                            videoIndex:targetIndex
                                 force:NO];
            });
            
        }
        
        return tVideoItem;
        
    } else {
        //基于相册内视频重新生成结构
        tVideoItem.status = YES;
        if(!tVideoItem.key || tVideoItem.key.length<2)
        {
            tVideoItem.key = [self getItemKey:tVideoItem];
        }
        //        [tVideoItem setStatus:2];
        //        tVideoItem.ItemKey = [self getItemKey:tVideoItem];
        //        [tVideoItem setItemKey:[self getItemKey:tVideoItem]];
        return tVideoItem;
    }
}

- (void) imageToVideo: (MediaItem *)imageItem fullPath:(NSString *)fullPath videoIndex:(NSInteger)index force:(BOOL)force
{
    if(!imageItem.isImg) return;
    
    //    BOOL isFind = NO;
    if(isImage2VideoDoing_)
    {
        dispatch_time_t nextTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);// 页面刷新的时间基数
        dispatch_after(nextTime,img2VideoThread_, ^(void)
                       {
                           NSLog(@"image2video : waiting for next time.");
                           [self imageToVideo:imageItem fullPath:fullPath videoIndex:index force:force];
                       });
        return;
    }
    isImage2VideoDoing_ = YES;
    //如果不是强刷，则检查是否有生成超时的
    if(!force)
    {
        NSMutableArray * existList = [NSMutableArray new];
        
        BOOL isFind = [self findItemsWithSameMediaFile:imageItem existList:&existList];
        if(isFind)   //i如果已经有同一个媒体
        {
            //可能有多个同样的文件在队列中，因此只要有一个已经完成，就认为它完成了
            for (MediaItem * item in existList) {
                if(item.status)
                {
                    imageItem.status = YES;
                    imageItem.fileName = item.fileName;
                    break;
                }
            }
        }
        existList = nil;
        if(imageItem.status)
        {
            isImage2VideoDoing_ = NO;
            return;
        }
    }
    
    SuccessBlock sblock = ^(BOOL success,CGFloat progress)
    {
        if (success && progress>=1) {
            
            NSURL *url = [NSURL fileURLWithPath:fullPath];
            imageItem.url = url;
            imageItem.fileName = [[HCFileManager manager] getFileName:fullPath];
            
            imageItem.status = YES;
            //将文件路径保存
            BOOL isFind = NO;
            NSMutableArray * existList = [NSMutableArray new];
            isFind = [self findItemsWithSameMediaFile:imageItem existList: &existList];
            
            for (MediaItem * item in existList)
            {
                item.status = YES;
                item.lastGenerateInterval = imageItem.lastGenerateInterval;
            }
            
#ifndef __OPTIMIZE__
            NSInteger notCompletedCount = existList.count;
            int notCompletedCount2 = 0;
            for (MediaItem * item in mediaList_) {
                if(item.status==NO)
                {
                    notCompletedCount ++;
                }
            }
            for (MediaItem * item in mediaList_) {
                if(item.status==NO)
                {
                    notCompletedCount2 ++;
                }
            }
            NSLog(@"image2video : queue remain:%d image2video remain:%d",(int)notCompletedCount2,(int)notCompletedCount);
#endif
            
            //更新同名的文件，一个文件可以加多次的
            for (MediaItem * item in mediaList_) {
                if([item.fileName isEqualToString:imageItem.fileName] && item.status==NO)
                {
                    item.status = YES;
                }
            }
            NSLog(@"image2video: generate (%@) ok.",[fullPath lastPathComponent]);
        }
        else
        {
            if(!success)
            {
                NSLog(@"image2video: generate (%@) failure.",[fullPath lastPathComponent]);
            }
            else
            {
            }
        }
        isImage2VideoDoing_ = NO;
    };
    
    UIImage * image = nil;
    if(imageItem.cover && imageItem.cover.length>0)
    {
        image = [UIImage imageWithContentsOfFile:imageItem.cover];
    }
    else if(imageItem.alAsset)
    {
        image = [UIImage imageWithCGImage:[[imageItem.alAsset defaultRepresentation] fullScreenImage]];
    }
    
    imageItem.lastGenerateInterval = [CommonUtil getDateTicks:[NSDate date]];
    if(image)
    {
        [ImagesToVideo generateVideoByImage:image item:imageItem withCallbackBlock:sblock];
    }
    else
    {
        NSLog(@"image2video: file:(%@) not find.",imageItem.filePath);
        isImage2VideoDoing_ = NO;
    }
}
#pragma mark - image list op
- (NSString *) getVideoPath:(MediaItem *)item
{
    if(item.isImg)
    {
        NSAssert(item.fileName != NULL, @"媒体文件必须有路径");
        if(!item.cover || item.cover.length<2)
        {
            item.cover = item.filePath;
        }
        if(![HCFileManager isVideoFile:item.fileName])
        {
            if(item.alAsset && !item.url)
            {
                item.url = (NSURL *)[item.alAsset valueForProperty:ALAssetPropertyAssetURL];
            }
            else if(!item.url)
            {
                item.url = [NSURL fileURLWithPath:item.filePath];
            }
            item.fileName = [[udManager_ tempFileDir]stringByAppendingPathComponent:[self getNewVideoFileName:item]];
        }
    }
    if(!item.key || item.key.length<2)
    {
        item.key = [self getItemKey:item];
    }
    return item.filePath;
}
-(NSString *)getItemKey:(MediaItem *)item
{
    NSAssert(item.fileName != NULL, @"在获取Key之前，需要获取路径");
    return [NSString stringWithFormat:@"%@-%.4f-%.4f-%u",
            item.fileName,
            item.secondsInArray,
            item.secondsDurationInArray,
            item.cutInMode];
    
}
- (NSString *) getNewVideoFileName:(MediaItem *)item
{
    //以时间戳作为Item的名称
    //    NSDate *date = [NSDate date];
    //    NSTimeInterval aInterval =[date timeIntervalSince1970];
    NSString *videoName = nil;
    if(item)
    {
        NSURL * url = item.alAsset ? [item.alAsset valueForProperty:ALAssetPropertyAssetURL]:item.url;
        videoName = [[NSString stringWithFormat:@"%@-%.0f-%.0f",
                      [CommonUtil md5Hash:url.absoluteString],
                      item.secondsBegin * 100,
                      item.secondsDuration * 100]
                     //                      CMTimeGetSeconds(item.begin)*100,
                     //                      CMTimeGetSeconds(item.duration)*100]
                     stringByAppendingString:@".mp4"];
    }
    else
    {
        NSTimeInterval aInterval =[[NSDate date] timeIntervalSince1970];
        videoName = [[NSString stringWithFormat:@"%.0f",aInterval * 1000]
                     stringByAppendingString:@".mp4"];
        
    }
    return videoName;
}

//find item in image2video list
- (BOOL)findItemsWithSameMediaFile:(MediaItem *)imageItem existList:(NSMutableArray **)existList
{
    BOOL isFind = NO;
    if(existList && !(*existList))
    {
        *existList = PP_AUTORELEASE([NSMutableArray new]);
    }
    for (MediaItem * item in mediaList_) {
        if(item != imageItem && [item.fileName isEqualToString:imageItem.fileName])
        {
            isFind = YES;
            if(existList)
            {
                [(*existList) addObject:item];
            }
            else break;
        }
    }
    return isFind;
}

//检查文件是否存在，如果有.chk，才表明该文件是完整的，否则有文件也认为是不完整的
//因为现在生成视频非常快，因此，不需要检查CHK文件，简化处理
- (BOOL)checkIsExistsVideo:(NSString *)fullPath isOrgImage:(BOOL)isOrgImage
{
    NSFileManager * fm = [NSFileManager defaultManager];
    return [fm fileExistsAtPath:fullPath];
    //    if ([CommonUtil isExistsFile:fullPath]) {
    //        if([udManager_ fileSizeAtPath:fullPath]>10)
    //        {
    //            return YES;
    //        }
    //    }
    //    return NO;
}
- (CGSize) getSizeByOrientation:(CGSize)size orientation:(UIDeviceOrientation)orientation
{
    if(UIDeviceOrientationIsPortrait(orientation) && size.width>size.height)
    {
        CGFloat w = size.width;
        size.width = size.height;
        size.height = w;
    }
    else if(UIDeviceOrientationIsLandscape(orientation) && size.width<size.height)
    {
        CGFloat w = size.width;
        size.width = size.height;
        size.height = w;
    }
    return size;
}

#pragma mark - generate mtv for cover
-(BOOL)generateMVByCover:(NSString *)imagePath
              targetPath:(NSString *)targetPath
                duration:(CGFloat)seconds
                     fps:(int)fps
                    size:(CGSize)size
             orientation:(UIDeviceOrientation)orientation
                progress:(mvGenerateCompleted)callbackBlock
{
    if(!imagePath || ![[NSFileManager defaultManager]fileExistsAtPath:imagePath]) return NO;
    if(isGenerateMVByCover_) return NO;
    isGenerateMVByCover_ = YES;
    
    NSString * filePath = targetPath?targetPath:[imagePath stringByAppendingString:@".bg.mp4"];
    
    UIImage * image = [UIImage imageWithContentsOfFile:imagePath];
    
    NSLog(@"generate0:%@ image size:%@,targetSize:%@",filePath,NSStringFromCGSize(image.size),NSStringFromCGSize(size));
    
    image = [image fixOrientation];
    
    size = [self getSizeByOrientation:size orientation:orientation];
    if(image.size.width != size.width || image.size.height != size.height)
    {
        image = [image imageByScalingProportionallyToSize:size];
    }
    image = [image normalizedImage:UIImageOrientationLeft];
    
    size = [ImagesToVideo correctSize:size sourceSize:image.size keep16:YES];
    
    NSLog(@"generate1:%@ image size:%@,targetSize:%@",filePath,NSStringFromCGSize(image.size),NSStringFromCGSize(size));
    [ImagesToVideo writeImageToMovieN:image toPath:filePath
                                 size:size
                                  fps:1
                              seconds:roundf(seconds+1)
                          orientation:orientation
                    withCallbackBlock:^(BOOL success, CGFloat progress) {
                        if(!success)
                        {
                            isGenerateMVByCover_ = NO;
                        }
                        if(progress>=1.0 && callbackBlock)
                        {
                            isGenerateMVByCover_ = NO;
                            callbackBlock(filePath,nil);
                        }
                    }];
    return YES;
}
#pragma mark - clear remove
- (void)removeFileAssociateWithPath:(NSString *)path
{
    if(!path|| ![HCFileManager isLocalFile:path]) return;
    //    [udManager_ removeFileAtPath:path];
    //
    //    [udManager_ removeThumnates:path  size:CGSizeZero];
    //    [udManager_ removeThumnates:path  size:CGSizeMake(144, 120)];
    //
    NSString *   orgFileName = [path lastPathComponent];
    NSString * regEx = nil;
    
    regEx = [NSString stringWithFormat:@"%@_\\d+\\..*\\.jpg|%@_\\d+\\.\\{\\d+,\\d+\\}\\.jpg",orgFileName,orgFileName];
    
    NSString * dir = [udManager_ tempFileFullPath:nil];
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:dir]) return;
    
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:dir] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        if([fileName isMatchedByRegex:regEx])
        {
            NSError * error = nil;
            NSString* fileAbsolutePath = [dir stringByAppendingPathComponent:fileName];
            [manager removeItemAtPath:fileAbsolutePath error:&error];
            if(error)
            {
                NSLog(@"remove file %@ failure:%@",fileAbsolutePath,[error localizedDescription]);
            }
        }
    }
    {
        NSError * error = nil;
        [manager removeItemAtPath:path error:&error];
        if(error)
        {
            NSLog(@"remove file %@ failure:%@",path,[error localizedDescription]);
        }
    }
}
- (void)clearFiles
{
    NSLog(@"model list  clear files...");
    
    for(MediaItem * item in mediaList_)
    {
        [self removeFileAssociateWithPath:item.filePath];
    }
    
    [udManager_ removeTempVideos];
}
- (void)clear
{
    [self clearFiles];
    
    [mediaList_ removeAllObjects];
    
}
@end

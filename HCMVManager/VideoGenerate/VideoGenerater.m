//
//  VideoGenerater.m
//  maiba
//
//  Created by HUANGXUTAO on 16/4/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "VideoGenerater.h"
//#import "PlayerMediaItem.h"
//#import "VideoItem.h"

#import "MediaItem.h"
#import "SDAVAssetExportSession.h"
#import "ImageToVideo.h"
#import <hccoren/RegexKitLite.h>
#import <hccoren/base.h>
#import <hcbasesystem/UDManager(Helper).h>

#import "MediaListModel.h"
#import "AudioGenerater.h"
#import "MediaEditManager.h"

@interface VideoGenerater()
{
}
@end
@implementation VideoGenerater
{
    dispatch_queue_t    _dispatchJoinVideo;
    
    AVMutableVideoComposition * _videoComposition;
    AVMutableComposition * _mixComposition;
    AVMutableAudioMix * _audioMixOnce;
    NSTimer * timerForExport_;
    
    UDManager * udManager_;
}
@synthesize previewAVPlayItem;
@synthesize previewAVassetIsReady;
@synthesize joinVideoUrl;
@synthesize joinAudioUrl;
@synthesize bgvUrl,bgmUrl;
@synthesize renderSize = renderSize_;
@synthesize totalEndTime = totalEndTime_;
@synthesize totalBeginTime = totalBeginTime_;
@synthesize totalEndTimeForAudio = totalEndTimeForAudio_;
@synthesize totalBeginTimeForAudio = totalBeginTimeForAudio_;
#pragma mark - init
- (instancetype)init
{
    if(self = [super init])
    {
        [self createDefault];
    }
    return self;
}

- (void)setJoinAudioUrlWithDraft:(NSURL *)mixedAudioUrl
{
    if(!joinAudioUrl || joinAudioUrl!=mixedAudioUrl)
    {
        PP_RELEASE(joinAudioUrl);
        joinAudioUrl = PP_RETAIN(mixedAudioUrl);
    }
}
- (void)createDefault
{
    _dispatchJoinVideo = dispatch_queue_create("com.seenvoice.JoinVideo", DISPATCH_QUEUE_SERIAL);
    
    [self resetParameters];
    
    _compositeLyric = YES;
    bgAudioVolume_ = 1.0;
    singVolume_ = 1.0;
    //    defaultAudioScale_ = 44100;
    
    udManager_ = [UDManager sharedUDManager];
    DeviceConfig * config = [DeviceConfig config];
    _volRampSeconds = 0;
    
    if(config.Height < 500)
    {
        [self setRenderSize:CGSizeMake(config.Height * config.Scale, config.Width * config.Scale) orientation:self.orientation withFontCamera:self.useFontCamera];
        //        self.renderSize = CGSizeMake(config.Height * config.Scale, config.Width * config.Scale);
    }
    else
    {
        [self setRenderSize:CGSizeMake(1280, 720) orientation:self.orientation withFontCamera:self.useFontCamera];
        //        self.renderSize = CGSizeMake(1280, 720);
    }
    
    [self clearFiles];
}
- (void)resetParameters
{
    progressBlock_ = nil;
    itemReadyBlock_ = nil;
    completedBlock_ = nil;
    failureBlock_ = nil;
    totalBeginTime_ = kCMTimeZero;
    totalEndTime_ = kCMTimeZero;
    //    [chooseQueue removeAllObjects];
}
- (void)setRenderSize:(CGSize)size orientation:(int)orient withFontCamera:(BOOL)useFontCamera
{
    self.orientation = orient;
    self.useFontCamera = useFontCamera;
    renderSize_ = [self getSizeByOrientation:size];
}
- (CGSize) getSizeByTransform:(CGSize)size transform:(CGAffineTransform )transform
{
    int degree = 0;
    CGAffineTransform t = transform;
    if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
        // Portrait
        degree = 90;
    }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
        // PortraitUpsideDown
        degree = 270;
    }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
        // LandscapeRight
        degree = 0;
    }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
        // LandscapeLeft
        degree = 180;
    }
    if((degree==90 ||degree==270) && size.width>size.height)
    {
        CGFloat w = size.width;
        size.width = size.height;
        size.height = w;
    }
    else if((degree==0 ||degree==180) && size.width<size.height)
    {
        CGFloat w = size.width;
        size.width = size.height;
        size.height = w;
    }
    return size;
}
- (CGSize) getSizeByOrientation:(CGSize)size
{
    if(UIDeviceOrientationIsPortrait(self.orientation) && size.width>size.height)
    {
        CGFloat w = size.width;
        size.width = size.height;
        size.height = w;
    }
    else if(UIDeviceOrientationIsLandscape(self.orientation) && size.width<size.height)
    {
        CGFloat w = size.width;
        size.width = size.height;
        size.height = w;
    }
    return size;
}
- (void)setTimeForMerge:(CGFloat)secondsBegin end:(CGFloat)secondsEnd
{
    if(secondsBegin<=0)
    {
        totalBeginTime_ = kCMTimeZero;
    }
    else
    {
        totalBeginTime_ = CMTimeMakeWithSeconds(secondsBegin, VIDEO_CTTIMESCALE);
    }
    if(secondsEnd<=0)
    {
        totalEndTime_ = kCMTimeZero;
    }
    else
    {
        totalEndTime_ = CMTimeMakeWithSeconds(secondsEnd, VIDEO_CTTIMESCALE);
    }
}
- (void)setTimeForAudioMerge:(CGFloat)secondsBegin end:(CGFloat)secondsEnd
{
    if(secondsBegin<=0)
    {
        totalBeginTimeForAudio_ = kCMTimeZero;
    }
    else
    {
        totalBeginTimeForAudio_ = CMTimeMakeWithSeconds(secondsBegin, AUDIO_CTTIMESCALE);
    }
    if(secondsEnd<=0)
    {
        totalEndTimeForAudio_ = kCMTimeZero;
    }
    else
    {
        totalEndTimeForAudio_ = CMTimeMakeWithSeconds(secondsEnd, AUDIO_CTTIMESCALE);
    }
}
#pragma mark - join
#pragma mark - join audio and mv
////用于编辑或全本时
//-(void) updateChooseQueueWithPlayerMedia:(NSArray *)mediaItemQueue bgAudioVolume:(CGFloat)volume singVolume:(CGFloat)singVolume
//{
//    [self resetParameters];
//
//    bgAudioVolume_ = volume;
//    singVolume_ = singVolume;
//
////    VideoGenerater * vgen = [VideoGenerater new];
////
////    NSArray * items = [vgen checkMediaQueue:mediaItemQueue beginTime:kCMTimeZero endTime:kCMTimeZero resetBegin:NO];
////    vgen = nil;
////    //    NSArray * items = [self checkMediaQueue:mediaItemQueue beginTime:kCMTimeZero endTime:kCMTimeZero resetBegin:NO];
////    [chooseQueue addObjectsFromArray:items];
//
//    //调用preview相关函数来确认assetIsReady
//    [self generatePreviewAVasset:nil];
//}
//// 用于最终合成
//- (void) updateChooseQueue:(NSArray *)mediaItemQueue completed:(void (^)(BOOL finished)) completion
//{
////    [chooseQueue removeAllObjects];
////    VideoGenerater * vgen = [VideoGenerater new];
////    NSArray * items = [vgen checkMediaQueue:mediaItemQueue beginTime:totalBeginTime_ endTime:totalEndTime_ resetBegin:YES];
////    vgen = nil;
////
////    //    NSArray * items = [self checkMediaQueue:mediaItemQueue beginTime:totalBeginTime_ endTime:totalEndTime_ resetBegin:YES];
////    [chooseQueue addObjectsFromArray:items];
//
//    //调用preview相关函数来确认assetIsReady
//    [self generatePreviewAVasset:completion];
//}

- (BOOL)needRebuildPreviewMV:(NSArray *)mediaList bgVol:(CGFloat)bgVol singVol:(CGFloat)singVol
{
    singVolume_ = singVol;
    bgAudioVolume_ = bgVol;
    
    if(!lastGenerateKey_) return YES;
    
    NSString * key = [self getKeyForMediaList:mediaList];
    if([lastGenerateKey_ isEqualToString:key])
    {
        if(_mixComposition && _audioMixOnce && _videoComposition)
        {
            return NO;
        }
    }
    return YES;
    
    //    lastGenerateKey_ = [self getKeyForMediaList:mediaList];
    //    //比较开始与结束时间，如果有变化则重新合成，否则不需要处理
    //    if(CMTimeCompare(totalEndTime_, kCMTimeZero)!=0)
    //    {
    //        if(_videoComposition)
    //        {
    //            AVMutableVideoCompositionInstruction * instructs = (AVMutableVideoCompositionInstruction*)[_videoComposition.instructions lastObject];
    //            CGFloat secondsIN = CMTimeGetSeconds(instructs.timeRange.duration);
    //            CGFloat secondsBegin = CMTimeGetSeconds(instructs.timeRange.start);
    //
    //            CGFloat secondsOrg = CMTimeGetSeconds(totalEndTime_) - CMTimeGetSeconds(totalBeginTime_);
    //            CGFloat secondsBeginOrg = CMTimeGetSeconds(totalBeginTime_);
    //
    //            if(secondsIN >= secondsOrg - 0.1 && secondsIN <= secondsOrg + 0.1
    //               && secondsBegin >= secondsBeginOrg - 0.1 && secondsBegin <= secondsBeginOrg + 0.1)
    //            {
    //
    //            }
    //            else
    //            {
    //                PP_RELEASE(_videoComposition);
    //                return YES;
    //            }
    //        }
    //        else
    //        {
    //            return YES;
    //        }
    //    }
    //    return NO;
}
#pragma mark - PlayerItem
#pragma mark - generate player item
- (void)sendPlayerItemToFront:(NSTimer *)timer
{
    if(itemReadyBlock_)
    {
        AVPlayerItem * playerItem = [self buildPreviewPlayerItem];
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            NSLog(@"readyToPlay!!!");
            itemReadyBlock_(self,playerItem);
        } else {
            if (playerItem.status == AVPlayerStatusUnknown) {
                NSLog(@"previewPlauItem is NOT ready");
                itemReadyBlock_(self,playerItem);
            } else {
                NSLog(@"error");
            }
        }
        PP_RELEASE(playerItem);
        PP_RELEASE(previewAVPlayItem);
        
        itemReadyBlock_ = nil;
    }
    else if(self.delegate && [self.delegate respondsToSelector:@selector(VideoGenerater:didPlayerItemReady:)])
    {
        AVPlayerItem * playerItem = [self buildPreviewPlayerItem];
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            NSLog(@"readyToPlay!!!");
            [self.delegate VideoGenerater:self didPlayerItemReady:playerItem];
        } else {
            if (playerItem.status == AVPlayerStatusUnknown) {
                NSLog(@"previewPlauItem is NOT ready");
                [self.delegate VideoGenerater:self didPlayerItemReady:playerItem];
            } else {
                NSLog(@"error");
            }
        }
        PP_RELEASE(playerItem);
        PP_RELEASE(previewAVPlayItem);
        
    }
}
-(AVPlayerItem *)buildPreviewPlayerItem
{
    if (_videoComposition && _mixComposition) {
        AVMutableVideoComposition * copyVideoComposition = nil;//[AVMutableVideoComposition videoComposition];
        copyVideoComposition = [_videoComposition copy];
        copyVideoComposition.animationTool = nil;
        //        AVVideoCompositionCoreAnimationTool * animatesTools = _videoComposition.animationTool;
        //        //_videoComposition.animationTool = nil;
        previewAVPlayItem = [[AVPlayerItem alloc] initWithAsset:_mixComposition];
        previewAVPlayItem.videoComposition = copyVideoComposition;
        previewAVPlayItem.audioMix = _audioMixOnce;
        
        NSLog(@"playeritemstatus:%d",previewAVPlayItem.status);
        if(previewAVPlayItem.error)
        {
            NSLog(@"playeritem error:%@",[previewAVPlayItem.error localizedDescription]);
        }
        AVPlayerItem * newItem = [previewAVPlayItem copy];
        //        _videoComposition.animationTool = animatesTools;
        return newItem;
    }
    return nil;
}
- (void) resetGenerateInfo
{
    previewAVassetIsReady = NO;
    PP_RELEASE(_mixComposition);
    PP_RELEASE(_videoComposition);
    PP_RELEASE(_audioMixOnce);
    PP_RELEASE(lastGenerateKey_);
}
#pragma mark - join for preview
-(void) generatePreviewAsset:(NSArray *)mediaList
                    bgVolume:(CGFloat)volume
                  singVolume:(CGFloat)singVolume
                  completion:(void (^)(BOOL finished)) completion
{
    previewAVassetIsReady = NO;
    //    NSArray * chooseQueue = [[MediaListModel shareObject]getMediaList];
    singVolume_ = singVolume;
    bgAudioVolume_ = volume;
    
    if(mediaList && mediaList.count>0)
    {
        [self generatePreviewAVasset:mediaList checked:NO completion:completion];
    }
    else
    {
        [self generatePreviewAVasset:mediaList checked:YES completion:completion];
    }
}

-(void) generatePreviewAVasset:(NSArray *)mediaList checked:(BOOL)checked completion:(void (^ __nullable)(BOOL finished)) completion
{
    if (!checked) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC);// 页面刷新的时间基数
        dispatch_after(popTime, _dispatchJoinVideo, ^(void){
            BOOL isAVSegmentCompleted = YES;
            NSFileManager * fm = [NSFileManager defaultManager];
            for (MediaItem * item in mediaList) {
                if(!item.status)
                {
                    if([fm fileExistsAtPath:item.filePath])
                    {
                        item.status = YES;
                        continue;
                    }
                    else
                    {
                        isAVSegmentCompleted = NO;
                        break;
                    }
                }
            }
            //            BOOL canComposite = [[MediaListModel shareObject]canComposite];
            [self generatePreviewAVasset:mediaList checked:isAVSegmentCompleted completion:completion];
        });
        
    } else {
        [self generatePlayerItem:mediaList size:self.renderSize];
        if(completion)
        {
            completion(YES);
        }
    }
}


#pragma mark - join
-(BOOL)generateMVFile:(NSArray *)mediaList retryCount:(int)retryCount// bgAudioVolume:(CGFloat)volume singVolume:(CGFloat)singVolume
{
    //
    //    bgAudioVolume_ = volume;
    //    singVolume_ = singVolume;
    
    NSURL * pathForFinalVideo = [self finalVideoUrl];
    
    //比较开始与结束时间，如果有变化则重新合成，否则不需要处理
    //    if(CMTimeCompare(totalEndTime_, kCMTimeZero)!=0)
    //    {
    //        if(_videoComposition)
    //        {
    //            AVMutableVideoCompositionInstruction * instructs = (AVMutableVideoCompositionInstruction*)[_videoComposition.instructions lastObject];
    //            CGFloat secondsIN = CMTimeGetSeconds(instructs.timeRange.duration);
    //            CGFloat secondsOrg = CMTimeGetSeconds(totalEndTime_) - CMTimeGetSeconds(totalBeginTime_);
    //
    //            if(secondsIN >= secondsOrg - 0.1 && secondsIN <= secondsOrg + 0.1)
    //            {
    //
    //            }
    //            else
    //            {
    //                PP_RELEASE(_videoComposition);
    //            }
    //        }
    //    }
    
    if (!previewAVassetIsReady) {
        [self generatePreviewAVasset:mediaList checked:NO completion:nil];
        return NO;
    }
    else if(!_videoComposition)
    {
        [self generatePlayerItem:mediaList size:self.renderSize];
        return NO;
    }
    
    if(self.title)
    {
        //        _videoComposition.animationTool = self r
    }
    
    
    joinVideoExporter = [SDAVAssetExportSession exportSessionWithAsset:_mixComposition];
    joinVideoExporter.outputURL = pathForFinalVideo;
    
    [[UDManager sharedUDManager]removeFileAtPath:[pathForFinalVideo path]];
    
    joinVideoExporter.outputFileType = AVFileTypeMPEG4;
    
    joinVideoExporter.shouldOptimizeForNetworkUse = YES;
    joinVideoExporter.videoComposition = _videoComposition;
    joinVideoExporter.audioMix = _audioMixOnce;
    
    CGSize renderSize = [self getRenderSize];
    NSNumber *width =  [NSNumber numberWithFloat:renderSize.width];
    NSNumber *height=  [NSNumber numberWithFloat:renderSize.height];
    
    joinVideoExporter.videoSettings= @{
                                       AVVideoCodecKey: AVVideoCodecH264,
                                       AVVideoWidthKey: width,
                                       AVVideoHeightKey: height,
                                       AVVideoCompressionPropertiesKey: @
                                           {
                                           AVVideoAverageBitRateKey:@697000,
                                               //                                          AVVideoProfileLevelKey: AVVideoProfileLevelH264Baseline30,
                                           },
                                       };
    
    joinVideoExporter.audioSettings = @{
                                        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                                        AVNumberOfChannelsKey: @2,
                                        AVSampleRateKey: @44100,
                                        AVEncoderBitRateKey: @160000,
                                        };
    
    
    if (_mixComposition && _videoComposition) {
        
        timerForExport_ = PP_RETAIN([NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkProgress:) userInfo:nil repeats:YES]);
        
        __weak SDAVAssetExportSession * weakJoin = joinVideoExporter;
        [joinVideoExporter exportAsynchronouslyWithCompletionHandler:^{
            
            __strong SDAVAssetExportSession * strongJoin = weakJoin;
            [timerForExport_ invalidate];
            PP_RELEASE(timerForExport_);
            
            //            dispatch_async(dispatch_get_main_queue(), ^{
            [self exportDidFinish:strongJoin];
            //            });
        }];
        if(joinVideoExporter.error)
        {
            NSLog(@"export error:%@",[joinVideoExporter.error localizedDescription]);
            return NO;
        }
        NSLog(@"export status:%d",joinVideoExporter.status);
    }
    else
    {
        if(failureBlock_)
        {
            failureBlock_(self,@"没有合成的视频层信息",[self buildError:@"没有合成的视频层信息"]);
        }
        else if(self.delegate && [self.delegate respondsToSelector:@selector(VideoGenerater:didGenerateFailure:error:)])
        {
            [self.delegate VideoGenerater:self didGenerateFailure:@"没有合成的视频层信息" error:[self buildError:@"没有合成的视频层信息"]];
        }
    }
    return NO;
}
//-(BOOL) generateFianlAudio:(NSArray *)audioItemQueue completed:(audioGenerateCompleted)completeHandler
//{
//    audioGenerateCompleted completed = ^(NSURL *audioUrl, NSError *error)
//    {
//        if(!joinAudioUrl || joinAudioUrl != audioUrl)
//        {
//            PP_RELEASE(joinAudioUrl);
//            joinAudioUrl = PP_RETAIN(audioUrl);
//        }
//        if(completeHandler)
//        {
//            completeHandler(audioUrl,error);
//        }
//    };
//    AudioGenerater * gen = [AudioGenerater new];
//
//    //合成文件存放到本地目录，而不是临时目录
//    NSString * tempFileName = [gen getAudioFileNameByQueue:audioItemQueue];
//    NSString * tempPath = [udManager_ localFileFullPath:tempFileName];
//
//    return [gen generateAudioWithAccompany:audioItemQueue filePath:tempPath beginSeconds:CMTimeGetSeconds(totalBeginTime_) endSeconds:CMTimeGetSeconds(totalEndTime_) overwrite:NO completed:completed];
//    //    return [self generateAudioWithAccompany:audioItemQueue Accompany:bgvUrl overwrite:NO completed:completed];
//}
#pragma mark - new functions for generate
- (BOOL) generateMV:(NSArray *)mediaList
        accompanyMV:(NSURL*)accompanyMV
             audios:(NSArray*)audios
              begin:(CMTime)beginTime end:(CMTime) endTime
      bgAudioVolume:(CGFloat)volume singVolume:(CGFloat)singVolume
           progress:(MEProgress)progress
              ready:(MEPlayerItemReady)itemReady
          completed:(MECompleted)complted
            failure:(MEFailure)failure
{
    if(!audios || !audios.count || ! accompanyMV) return NO;
    
    progressBlock_ = progress;
    itemReadyBlock_ = itemReady;
    completedBlock_ = complted;
    failureBlock_ = failure;
    totalBeginTime_ = beginTime;
    totalEndTime_ = endTime;
    bgAudioVolume_ = volume;
    singVolume_ = singVolume;
    
    AudioGenerater * gen = [AudioGenerater new];
    
    //合成文件存放到本地目录，而不是临时目录
    NSString * tempFileName =   [gen getAudioFileNameByQueue:audios];
    NSString * tempPath = [udManager_ localFileFullPath:tempFileName];
    
    return [gen generateAudioWithAccompany:audios
                                  filePath:tempPath
                              beginSeconds:CMTimeGetSeconds(totalBeginTime_)
                                endSeconds:CMTimeGetSeconds(totalEndTime_)
                                 overwrite:YES
                                 completed:^(NSURL *audioUrl, NSError *error) {
                                     [self setJoinAudioUrlWithDraft:audioUrl];
                                     
                                     [self generatePreviewAsset:mediaList bgVolume:bgAudioVolume_ singVolume:singVolume_ completion:^(BOOL finished)
                                      {
                                          //                                          [self generatePlayerItem:mediaList size:self.renderSize];
                                          [self generateMVFile:mediaList retryCount:0]; // bgAudioVolume:bgAudioVolume_ singVolume:singVolume_];
                                      }];
                                 }];
}



////检查队列中的视频数据，如果在设定的时间范围外的，排除，并且重新计算相对于设定的时间的起止位置
////resetBegin 是否以新视频的起点位置作为0 点？否，则以原视频的位置作为原点计算位置。比如从原视频10秒开始，那么10秒的位置在新视频中为0
//- (NSMutableArray *)checkMediaQueue:(NSArray*)mediaItemQueue beginTime:(CMTime)beginTime endTime:(CMTime)endTime resetBegin:(BOOL)resetBegin
//{
//    //重新生成chooseQueue
//    previewAVassetIsReady = NO;
//    NSLog(@" add items to choose queue");
//    //    [chooseQueue removeAllObjects];
//
//    NSMutableArray * videoSegments = [NSMutableArray new];
//    if(mediaItemQueue && mediaItemQueue.count>0)
//    {
//        for (PlayerMediaItem * item in mediaItemQueue) {
//            VideoItem * vitem = [self transMediaToVideoItem:item];
//            [videoSegments addObject:vitem];
//        }
//        //check items,and remove the items not need any more.
//        NSMutableArray * removeList = [NSMutableArray new];
//        for (VideoItem * gItem in ImgToVideoQueue) {
//            BOOL isFind = NO;
//            for (VideoItem * item in videoSegments) {
//                if([item.path isEqualToString:gItem.path])
//                {
//                    item.status = gItem.status;
//                    item.lastGenerateInterval = gItem.lastGenerateInterval;
//                    isFind = YES;
//                }
//            }
//            if(!isFind)
//            {
//                [removeList addObject:gItem];
//            }
//        }
//        for (VideoItem * item in removeList) {
//            [ImgToVideoQueue removeObject:item];
//            [self removeFileAssociateWithPath:item.path];
//        }
//
//        //check image2video
//        for (VideoItem * item in videoSegments) {
//            [self checkImgToVideoQueue:item atIndex:-1];
//        }
//
//        //检查开始与结束时间的代码
//        [removeList removeAllObjects];
//        if(videoSegments && videoSegments.count>0 && CMTimeCompare(endTime, kCMTimeZero)>0)
//        {
//            for (VideoItem * item in videoSegments) {
//                NSLog(@"item:%.1f(%.1f-%.1f)  begin:%.1f end:%.1f",CMTimeGetSeconds(item.stInQueue),
//                      CMTimeGetSeconds(item.startTime),CMTimeGetSeconds(item.endTime),
//                      CMTimeGetSeconds(beginTime),CMTimeGetSeconds(endTime));
//
//                CMTime duration = CMTimeSubtract(item.endTime, item.startTime);
//                CMTime endInQueue = CMTimeAdd(item.stInQueue, duration);
//                NSLog(@"duration:%.1f endIn:%.1f",CMTimeGetSeconds(duration),CMTimeGetSeconds(endInQueue));
//                if(CMTimeCompare(endInQueue, beginTime)<=0 || CMTimeCompare(item.stInQueue, endTime)>=0)
//                {
//                    [removeList addObject:item];
//                    continue;
//                }
//                else
//                {
//                    CMTime durationChanged = kCMTimeZero;
//                    if(CMTimeCompare(item.stInQueue, beginTime)<0)
//                    {
//                        durationChanged = CMTimeSubtract(beginTime,item.stInQueue);
//                        item.stInQueue = beginTime;
//                        item.startTime = CMTimeAdd(item.startTime, durationChanged);
//                        endInQueue = CMTimeSubtract(endInQueue, durationChanged);
//                    }
//                    if(CMTimeCompare(endInQueue, endTime)>0)
//                    {
//                        durationChanged = CMTimeSubtract(endInQueue, endTime);
//                        item.endTime = CMTimeSubtract(item.endTime, durationChanged);
//                    }
//                    //重置起点的时间计数
//                    if(resetBegin)
//                    {
//                        item.stInQueue = CMTimeSubtract(item.stInQueue, beginTime);
//                    }
//                }
//                NSLog(@"item:%.1f(%.1f-%.1f)  begin:%.1f end:%.1f",CMTimeGetSeconds(item.stInQueue),
//                      CMTimeGetSeconds(item.startTime),CMTimeGetSeconds(item.endTime),
//                      CMTimeGetSeconds(beginTime),CMTimeGetSeconds(endTime));
//            }
//        }
//        if(removeList.count>0)
//        {
//            [videoSegments removeObjectsInArray:removeList];
//        }
//
//        PP_RELEASE(removeList);
//    }
//    return PP_AUTORELEASE(videoSegments);
//}



-(void) generatePlayerItem:(NSArray *)mediaList size:(CGSize)size
{
    //    return [self generatePlayItemNew];
    
    CMTime totalDuration = bgmUrl?[self getTotalDuration:bgmUrl]:[self getTotalDuration:bgvUrl];
    
    PP_RELEASE(_mixComposition);
    PP_RELEASE(_videoComposition);
    PP_RELEASE(_audioMixOnce);
    
    size = [self getSizeByOrientation:size];
    renderSize_ = size;
    
    lastGenerateKey_ = [self getKeyForMediaList:mediaList];
    
    AVMutableVideoComposition *mainComposition;
    AVMutableComposition *mixComposition;
    
    mixComposition = [[AVMutableComposition alloc] init];
    
    CMTime curTimeCnt = kCMTimeZero;
    NSMutableArray *layers  = [[NSMutableArray alloc] init];
    
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    CGFloat rate = self.mergeRate>0 ?self.mergeRate :1.0;
    if(rate!=1.0)
    {
        totalDuration.value /= rate;
    }
    //    NSArray * chooseQueue = [[MediaListModel shareObject]getMediaList];
    if (mediaList && mediaList.count>0) {
        //选择的素材>1
        AVMutableCompositionTrack * imageTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableCompositionTrack * videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVMutableVideoCompositionLayerInstruction *imageLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:imageTrack];
        AVMutableVideoCompositionLayerInstruction *videoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        NSInteger imageCnt = 0;
        NSInteger videoCnt = 0;
        CMTimeValue lastTimeValue = 0;
        
        for (int i = 0 ; i < mediaList.count ; i ++ ) {
            
            MediaItem * curItem = [mediaList objectAtIndex:i];
            
            CMTime modalOffEtInQueue = [self compsiteOneItem:curItem
                                                       index:i
                                               lastTimeValue:lastTimeValue
                                               totalDuration:totalDuration
                                                  imageTrack:imageTrack
                                                 imagelayers:imageLayerInstruction
                                                  videoTrack:videoTrack
                                                 videoLayers:videoLayerInstruction rate:rate];
            
            if(CMTimeCompare(modalOffEtInQueue, kCMTimeZero)==0) continue;
            
            if(curItem.originType == MediaItemTypeIMAGE)
                imageCnt ++;
            else
                videoCnt ++;
            
            if (CMTimeGetSeconds(modalOffEtInQueue) > CMTimeGetSeconds(curTimeCnt) ) {
                curTimeCnt = modalOffEtInQueue;
            }
            lastTimeValue = modalOffEtInQueue.value ;
            
        }
        
        if (imageCnt) {
            [layers addObject:imageLayerInstruction];
        }
        if (videoCnt) {
            [layers addObject:videoLayerInstruction];
        }
    }
    if(CMTimeCompare(curTimeCnt, totalDuration)<0)
    {
        curTimeCnt = CMTimeMakeWithSeconds(CMTimeGetSeconds(totalDuration), (totalDuration.timescale>curTimeCnt.timescale?totalDuration.timescale:curTimeCnt.timescale));
    }
    curTimeCnt = [self compositeBGVideo:mixComposition layers:layers maxTime:curTimeCnt size:size rate:rate];
    
    //音频混入
    NSMutableArray * audioMixParams = [self compositeAudioArray:mixComposition maxTime:curTimeCnt rate:rate];
    AVMutableAudioMix *bgmMix = [AVMutableAudioMix audioMix];
    bgmMix.inputParameters = audioMixParams;
    
    //对最终合成视频asset的设置
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero,curTimeCnt); //时间长度必须设置  不然会出错（黑屏）
    mainInstruction.layerInstructions = layers;
    
    CMTime time =  CMTimeMake(1, 30);
    
    mainComposition = [AVMutableVideoComposition videoComposition];
    mainComposition.instructions = [NSArray arrayWithObjects:mainInstruction,nil];
    mainComposition.frameDuration = time;
    mainComposition.renderSize =  size;//CGSizeMake(640, 480);//
    
    if(self.compositeLyric)
    {
        CMTime lyricDuration = curTimeCnt;
        if(rate!=1)
        {
            lyricDuration.value *= rate;
        }
        
        mainComposition.animationTool = [self compositeTitleAndLyric:nil duration:lyricDuration size:size rate:rate];
    }
    
    NSLog(@"prejoin:%@",NSStringFromCGSize(size));
    
    _mixComposition = PP_RETAIN((AVMutableComposition*)mixComposition);
    _videoComposition = PP_RETAIN((AVMutableVideoComposition*)mainComposition);
    _audioMixOnce = PP_RETAIN((AVMutableAudioMix*)bgmMix);
    
    previewAVassetIsReady = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(sendPlayerItemToFront:) userInfo:nil repeats:NO];
    });
}
- (void) generatePlayItemNew
{
    AVAsset * videoAsset = [AVURLAsset assetWithURL:self.bgvUrl];
    
    // 2 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    // 3 - Video track
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                         atTime:kCMTimeZero error:nil];
    
    // 3.1 - Create AVMutableVideoCompositionInstruction
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    
    // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
    BOOL isVideoAssetPortrait_  = NO;
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        videoAssetOrientation_ = UIImageOrientationRight;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        videoAssetOrientation_ =  UIImageOrientationLeft;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
        videoAssetOrientation_ =  UIImageOrientationUp;
    }
    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
        videoAssetOrientation_ = UIImageOrientationDown;
    }
    [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
    [videolayerInstruction setOpacity:0.0 atTime:videoAsset.duration];
    
    // 3.3 - Add instructions
    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    
    CGSize naturalSize;
    if(isVideoAssetPortrait_){
        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
    } else {
        naturalSize = videoAssetTrack.naturalSize;
    }
    
    float renderWidth, renderHeight;
    renderWidth = naturalSize.width;
    renderHeight = naturalSize.height;
    
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    
    //    [self applyVideoEffectsToComposition:mainCompositionInst size:naturalSize];
    mainCompositionInst.animationTool = [self compositeTitleAndLyric:nil duration:videoAsset.duration size:naturalSize rate:1];
    
    _mixComposition = PP_RETAIN((AVMutableComposition*)mixComposition);
    _videoComposition = PP_RETAIN((AVMutableVideoComposition*)mainCompositionInst);
    _audioMixOnce = nil;
    
    previewAVassetIsReady = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(sendPlayerItemToFront:) userInfo:nil repeats:NO];
    });
    
}
- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size
{
    UIImage *borderImage = nil;
    
    
    borderImage = [self imageWithColor:[UIColor blueColor] rectSize:CGRectMake(0, 0, size.width, size.height)];
    
    
    CALayer *backgroundLayer = [CALayer layer];
    [backgroundLayer setContents:(id)[borderImage CGImage]];
    backgroundLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [backgroundLayer setMasksToBounds:YES];
    
    CALayer *videoLayer = [CALayer layer];
    videoLayer.frame = CGRectMake(40, 40,
                                  size.width-(40*2), size.height-(40*2));
    CALayer *parentLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:backgroundLayer];
    [parentLayer addSublayer:videoLayer];
    
    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}
#pragma mark - 合成标题
- (AVVideoCompositionCoreAnimationTool *)compositeTitleAndLyric:(NSArray*)lyricItems duration:(CMTime)duration size:(CGSize)size rate:(CGFloat)rate
{
    //        BOOL hasTitle = NO;
    ////        AVMutableCompositionTrack *titleTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeSubtitle
    ////                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
    //        self.title = @"sfasdfafasdf";
    //        if(self.title && self.title.length>0 )
    //        {
    //            hasTitle = YES;
    //            NSString * fontName = @"Helvetica";
    //            CATextLayer *titleLayer = [CATextLayer layer];
    //            titleLayer.string = @"麦爸";
    //            titleLayer.font = (__bridge CFTypeRef)fontName;
    //            titleLayer.fontSize = 16;
    //    //        titleLayer.shadowOpacity = 0.5;
    //
    //            titleLayer.alignmentMode = kCAAlignmentLeft;
    //            CGSize textsize = [titleLayer.string sizeWithAttributes:@{NSFontAttributeName:[UIFont fontWithName:fontName size:titleLayer.fontSize]}];
    //            titleLayer.frame = CGRectMake(size.width - textsize.width - 10, textsize.height + 10, textsize.width, textsize.height);
    //
    //            CALayer *optionalLayer=[CALayer layer];
    //            [optionalLayer addSublayer:titleLayer];
    //            optionalLayer.frame=CGRectMake(0, 0, size.width, size.height);
    //            [optionalLayer setMasksToBounds:YES];
    //
    //
    //            CALayer *parentLayer=[CALayer layer];
    //            CALayer *videoLayer=[CALayer layer];
    //            parentLayer.frame=CGRectMake(0, 0, size.width, size.height);
    //            videoLayer.frame=CGRectMake(0, 0, size.width, size.height);
    //
    //            [parentLayer addSublayer:videoLayer];
    //            [parentLayer addSublayer:optionalLayer];
    //
    //
    //            AVVideoCompositionCoreAnimationTool * tools =[AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    //
    //            return tools;
    //        }
    //    return nil;
    
    if((self.lrcList && self.lrcList.count>0)||(self.waterMarkFile&&self.waterMarkFile.length>0))
    {
        CALayer *parentLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0, 0, size.width,size.height);
        
        CALayer *videoLayer = [CALayer layer];
        videoLayer.frame = CGRectMake(0, 0, size.width,size.height);
        [parentLayer addSublayer:videoLayer];
        
        
        //        歌词开始时间为：开始录制时（视频开始时）的歌词时间（有可能不从开始拍摄）+ 视频剪辑的位置（从视频开头的位置）
        NSArray * filterLyrics = nil;
        CALayer * lrcLayer = [ImagesToVideo getLrcAnimationLayer:self.lrcBeginTime + CMTimeGetSeconds(totalBeginTime_)
                                                        duration:CMTimeGetSeconds(duration)
                                                             lrc:self.lrcList
                                                     orientation:_orientation
                                                      renderSize:size
                                                            rate:rate
                                                    filterLyrics:&filterLyrics];
        
        [parentLayer addSublayer:lrcLayer];
        
        if(filterLyrics)
        {
            self.filterLrcList = [NSArray arrayWithArray:filterLyrics];
        }
        else
        {
            self.filterLrcList = nil;
        }
        if(self.waterMarkFile && self.waterMarkFile.length>2)
        {
            CALayer * wmLayer = [ImagesToVideo buildWaterMarkerLayer:self.waterMarkFile renderSize:size];
            if(wmLayer)
                [parentLayer addSublayer:wmLayer];
        }
        
        //指定哪个层用来承载视频的显示
        
        return [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
                                                                                                            inLayer:parentLayer];
        
    }
    else
    {
        return nil;
    }
}

- (UIImage *)imageWithColor:(UIColor *)color rectSize:(CGRect)imageSize {
    CGRect rect = imageSize;
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);   // Fill it with your color
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark  - composite Audio and video of background
- (CMTime) getTotalDuration:(NSURL *)accompanyUrl
{
    CMTime totalDuration = kCMTimeZero;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[accompanyUrl path]]) {
        
        AVURLAsset * bgvAsset = [[AVURLAsset alloc] initWithURL:accompanyUrl options:nil];
        totalDuration = bgvAsset.duration;
        
        PP_RELEASE(bgvAsset);
    }
    if(CMTimeGetSeconds(totalDuration)<2)
    {
        NSLog(@"bgvideo too small.%f",CMTimeGetSeconds(totalDuration));
    }
    //如果从中间取的话，则需要处理
    if(CMTimeCompare(totalEndTime_,kCMTimeZero)>0)
    {
        CGFloat seconds = CMTimeGetSeconds(totalEndTime_)- CMTimeGetSeconds(totalBeginTime_);
        //        CMTimeRange range = CMTimeRangeFromTimeToTime(totalBeginTime_, totalEndTime_);
        //        if(CMTIME_IS_VALID(range.duration) && range.duration.value>0)
        if(!isnan(seconds) && seconds>0)
        {
            totalDuration = CMTimeMakeWithSeconds(seconds, totalDuration.timescale);
        }
    }
    return totalDuration;
}
//
//- (CMTime)getVideoItemDurationInJoin:(CMTime *)begin end:(CMTime *)end timeInArray:(CMTime )timeInArray
//{
////    if(CMTimeCompare(totalBeginTime_,kCMTimeZero)>0)
////    {
////        if(CMTimeCompare(timeInArray, totalBeginTime_)<0)
////        {
////
////        }
////    }
//    return CMTimeSubtract(*begin, *end);
//}
- (CMTime) compsiteOneItem:(MediaItem*)curItem index:(int)index
             lastTimeValue:(CMTimeValue)lastTimeValue totalDuration:(CMTime)totalDuration
                imageTrack:(AVMutableCompositionTrack*)imageTrack
               imagelayers:(AVMutableVideoCompositionLayerInstruction*)imageLayerInstruction
                videoTrack:(AVMutableCompositionTrack*)videoTrack
               videoLayers:(AVMutableVideoCompositionLayerInstruction*)videoLayerInstruction
                      rate:(CGFloat)rate
{
    AVAsset *curAsset = [self getVideoItemAsset:curItem];
    if(!curAsset || CMTimeGetSeconds(curAsset.duration)<0.01)
    {
        NSLog(@"join video: %@ duration:%.1f skipped",curItem.fileName,CMTimeGetSeconds(curAsset.duration));
        return kCMTimeZero;
    }
    
    CMTime selfSt = curItem.begin;
    CMTime selfEt = curItem.end;
    CMTime duration = CMTimeSubtract(selfEt, selfSt);
    
    //比较是否在可以处理的范围内
    //    CMTime  duration = [self getVideoItemDurationInJoin:&selfSt end:&selfEt timeInArray:curItem.stInQueue];
    
    if(CMTimeGetSeconds(duration)<0.2)
    {
        NSLog(@"join video: duration:%f error.",CMTimeGetSeconds(duration));
        //        duration = curItem.duration;
        return kCMTimeZero;
    }
    //切入时间与切出时间
    CMTime modalInStInQueue = curItem.timeInArray; //切入时间
    CMTime modalOffEtInQueue = CMTimeAdd(modalInStInQueue, duration); //最后消失时间
    
    if(rate>0 && rate!=1.0)
    {
        modalInStInQueue.value = round(modalInStInQueue.value/rate +0.5);
        modalOffEtInQueue.value = round(modalOffEtInQueue.value/rate + 0.5);
    }
    
    //修正数据计算中的小误差
    if(modalInStInQueue.value < lastTimeValue)
    {
        modalOffEtInQueue.value += lastTimeValue - modalInStInQueue.value;
        modalInStInQueue.value = lastTimeValue;
    }
    
    if(CMTimeGetSeconds(modalInStInQueue) >= CMTimeGetSeconds(totalDuration))
    {
        return kCMTimeZero;
    }
    //不能超过最后的长度
    if(CMTimeGetSeconds(modalOffEtInQueue) > CMTimeGetSeconds(totalDuration))
    {
        modalOffEtInQueue = totalDuration;// CMTimeMake(totalDuration.value - totalDuration.timescale/10,totalDuration.timescale);
        duration = CMTimeSubtract(modalOffEtInQueue, modalInStInQueue);
    }
    
    CMTime modalOffStInQueue = CMTimeMakeWithSeconds(CMTimeGetSeconds(modalOffEtInQueue) - 1.0f/rate, selfSt.timescale); //开始切出的时间
    
#ifndef __OPTIMIZE__
    NSLog(@"join video: %@ duration:%.1f",[curItem.fileName lastPathComponent],CMTimeGetSeconds(curAsset.duration)
          );
    NSLog(@"join video: start=%lld, end=%lld",modalInStInQueue.value,modalOffEtInQueue.value);
#endif
    
    if(lastTimeValue >= modalOffEtInQueue.value)
    {
        return kCMTimeZero;
    }
    
    //    *lastTimeValue = modalOffEtInQueue.value;
    
    AVAssetTrack * curTrack = [[curAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    if (curItem.isImg) {
        
        //layer不依赖track的时基,当切入时间在整个时间轨之前时,将原切入时间后移至于当前起始边界一致
        //???
        if (CMTimeGetSeconds(modalInStInQueue) < CMTimeGetSeconds(imageTrack.timeRange.duration)) {
            NSLog(@"join video: next st = %f, last range = %f", 1.0f * modalInStInQueue.value/modalInStInQueue.timescale,
                  1.0f * imageTrack.timeRange.duration.value/ imageTrack.timeRange.duration.timescale);
            
            CMTime diff = CMTimeMakeWithSeconds(- CMTimeGetSeconds(modalInStInQueue) + CMTimeGetSeconds(imageTrack.timeRange.duration),
                                                imageTrack.timeRange.duration.timescale);
            modalInStInQueue = imageTrack.timeRange.duration;
            modalOffEtInQueue = CMTimeAdd(diff, modalOffEtInQueue);
            modalOffStInQueue = CMTimeAdd(diff, modalOffStInQueue);
        }
        
        CMTime realDuration = curAsset.duration;
        
        NSError * error = nil;
        
        [imageTrack insertTimeRange:CMTimeRangeMake(selfSt, realDuration)
                            ofTrack:curTrack
                             atTime:CMTimeMake(modalInStInQueue.value, modalInStInQueue.timescale)
                              error:&error];
        if(error)
        {
            NSLog(@"join video:(insert image) %@",[error localizedDescription]);
            return kCMTimeZero;
        }
        
        [imageTrack scaleTimeRange:CMTimeRangeMake(modalInStInQueue, realDuration)
                        toDuration: CMTimeMake(duration.value/rate,duration.timescale)];
        
        CGSize  curItemSize = curTrack.naturalSize;
        
        CMTimeRange drange = CMTimeRangeMake(modalInStInQueue, duration);
        
        CGAffineTransform transSt = [self getTransSt:curItemSize];
        CGAffineTransform transEd = [self getTransEd:curItemSize];
        
        NSLog(@"timerange:(%f--%f)",CMTimeGetSeconds(drange.start),CMTimeGetSeconds(drange.duration));
        
        //        if((self.orientation>0 && self.orientation <= UIDeviceOrientationFaceUp ) || self.useFontCamera)
        //        {
        //            [imageLayerInstruction setTransform:[self layerTrans:curAsset withTargetSize:self.renderSize orientation:self.orientation withFontCamera:self.useFontCamera isCreateByCover:NO]
        //                                         atTime:curItem.stInQueue];
        //        }
        //        else
        //        {
        //            [imageLayerInstruction setTransform:[self layerTrans:curAsset withTargetSize:self.renderSize] atTime:curItem.stInQueue];
        //        }
        
        //设置切入与切出风格及时间
        [imageLayerInstruction setTransformRampFromStartTransform:transSt
                                                   toEndTransform:transEd
                                                        timeRange:drange];
        //                [imageLayerInstruction setOpacity:0.0f atTime:kCMTimeZero];
        if(CMTimeGetSeconds(drange.duration)>2.0f)
        {
            [imageLayerInstruction setOpacityRampFromStartOpacity:0.0
                                                     toEndOpacity:1.0
                                                        timeRange:CMTimeRangeMake(modalInStInQueue,CMTimeMakeWithSeconds(1.0f/rate, modalInStInQueue.timescale))];
            [imageLayerInstruction setOpacityRampFromStartOpacity:1.0
                                                     toEndOpacity:0.0
                                                        timeRange:CMTimeRangeMake(modalOffStInQueue,CMTimeMakeWithSeconds(1.0f/rate, modalInStInQueue.timescale))];
        }
        else
        {
            if(index==0 && CMTimeGetSeconds(modalInStInQueue)<=0.01) // 第一个，而且短，一般是封面，需要淡出，防止闪烁
            {
                CMTimeRange cutoffRange = kCMTimeRangeZero;
                if(CMTimeGetSeconds(duration)<1.0)
                {
                    modalOffStInQueue = CMTimeMakeWithSeconds(0.1, selfSt.timescale);
                    CMTime cutoffDuration = CMTimeMake(modalOffEtInQueue.value - modalOffStInQueue.value, modalOffStInQueue.timescale);
                    cutoffRange = CMTimeRangeMake(modalOffStInQueue, cutoffDuration);
                }
                else
                {
                    cutoffRange = CMTimeRangeMake(modalOffStInQueue,CMTimeMakeWithSeconds(1.0f, modalInStInQueue.timescale));
                }
                [imageLayerInstruction setOpacity:1.0 atTime:modalInStInQueue];
                [imageLayerInstruction setOpacityRampFromStartOpacity:1.0
                                                         toEndOpacity:0.0
                                                            timeRange:cutoffRange];
            }
            else
            {
                [imageLayerInstruction setOpacity:1.0 atTime:modalInStInQueue];
                [imageLayerInstruction setOpacity:0.0 atTime:modalOffEtInQueue];
            }
        }
    } else {
        NSError * error = nil;
        [videoTrack insertTimeRange:CMTimeRangeMake(selfSt, duration)
                            ofTrack:curTrack
                             atTime:modalInStInQueue
                              error:&error];
        if(error)
        {
            NSLog(@"join video:(insert video) %@",[error localizedDescription]);
            return kCMTimeZero;
        }
        
        if(rate>0 && rate!=1.0)
        {
            CMTime durationScaled = CMTimeMake(duration.value/rate, duration.timescale);
            
            [videoTrack scaleTimeRange:CMTimeRangeMake(modalInStInQueue, duration)
                            toDuration:durationScaled];
        }
        
        //        [videoLayerInstruction setTransform:curAsset.preferredTransform atTime:curItem.timeInArray];
        
        if((self.orientation>0 && self.orientation <= UIDeviceOrientationFaceUp ) || self.useFontCamera)
        {
            [videoLayerInstruction setTransform:[self layerTrans:curAsset withTargetSize:self.renderSize orientation:self.orientation withFontCamera:self.useFontCamera isCreateByCover:NO]
                                         atTime:curItem.timeInArray];
        }
        else
        {
            [videoLayerInstruction setTransform:[self layerTrans:curAsset withTargetSize:self.renderSize] atTime:curItem.timeInArray];
        }
        //        [videoLayerInstruction setTransform:[self layerTrans:curAsset withTargetSize:self.renderSize] atTime:curItem.stInQueue];
        
        //现调整为3秒，3秒内没有切入切出效果
        //        if (CMTimeGetSeconds(duration) >= 3.0f){
        //            if(curItem.modalInType==CutInOutModeFadeIn)
        //            {
        //                [videoLayerInstruction setOpacityRampFromStartOpacity:0.0
        //                                                         toEndOpacity:1.0
        //                                                            timeRange:CMTimeRangeMake(modalInStInQueue,CMTimeMakeWithSeconds(1.0f/rate, modalInStInQueue.timescale))];
        //            }
        //            if(curItem.modalOffType==CutInOutModeFadeOut)
        //            {
        //                [videoLayerInstruction setOpacityRampFromStartOpacity:1.0
        //                                                         toEndOpacity:0.0
        //                                                            timeRange:CMTimeRangeMake(modalOffStInQueue,CMTimeMakeWithSeconds(1.0f/rate, modalInStInQueue.timescale))];
        //            }
        //        } else {
        [videoLayerInstruction setOpacity:1.0 atTime:modalInStInQueue];
        [videoLayerInstruction setOpacity:0.0 atTime:modalOffEtInQueue];
    }
    //    }
    return modalOffEtInQueue;
}
- (CMTime )compositeBGVideo:(AVMutableComposition *)mixComposition layers:(NSMutableArray *)layers maxTime:(CMTime)curTimeCnt size:(CGSize)size rate:(CGFloat)rate
{
    //将背景视频和背景音乐合成进去
    //因为如果背景视频长度一定要大于当前的长度。即整体视频长度不能大于背景长度
    //    CMTime curTimeCnt = kCMTimeZero;
    if (bgvUrl && [[NSFileManager defaultManager] fileExistsAtPath:[bgvUrl path]]) {
        
        BOOL isGenerateByCover = NO;
        if( [[bgvUrl path]isMatchedByRegex:@"\\.jpg.bg\\.mp4$"])
        {
            isGenerateByCover = YES;
        }
        
        AVURLAsset * bgvAsset = [[AVURLAsset alloc] initWithURL:bgvUrl options:nil];
        
        CMTime totalDuration = bgvAsset.duration;
        
        NSArray * tracklist = [bgvAsset tracksWithMediaType:AVMediaTypeVideo];
        if(tracklist.count>0)
        {
            TimeScale bgScale = IMAGE_TIMESCALE;
            if(bgvAsset.duration.timescale > curTimeCnt.timescale)
                bgScale = bgvAsset.duration.timescale;
            else
                bgScale= curTimeCnt.timescale;
            
            CMTime startTime = CMTimeMake(0, bgScale);
            
            CGFloat sourceDurationSeconds = CMTimeGetSeconds(totalDuration);
            CMTime targetDuration = kCMTimeZero;
            CGFloat startSeconds = 0;
            CGFloat endSeconds = sourceDurationSeconds;
            if(totalBeginTime_.value >0)
            {
                startSeconds = CMTimeGetSeconds(totalBeginTime_);
            }
            if(totalEndTime_.value >0)
            {
                endSeconds = CMTimeGetSeconds(totalEndTime_);
            }
            
            if(startSeconds>0)
                startTime = CMTimeMakeWithSeconds(startSeconds, bgScale);
            
            targetDuration = CMTimeMakeWithSeconds(endSeconds - startSeconds, bgScale);
            
            AVMutableCompositionTrack *bgvTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                              preferredTrackID:kCMPersistentTrackID_Invalid];
            
            NSError * error = nil;
            [bgvTrack insertTimeRange:CMTimeRangeMake(startTime, targetDuration)
                              ofTrack:[tracklist objectAtIndex:0]
                               atTime:kCMTimeZero
                                error:&error];
            if(error)
            {
                NSLog(@"join video:(mix bgvideo) %@",[error localizedDescription]);
            }
            
            if((rate >0 && rate!=1.0))
            {
                [bgvTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, targetDuration)
                              toDuration:CMTimeMake(targetDuration.value/rate, targetDuration.timescale)];
                targetDuration.value /= rate;
            }
            curTimeCnt = targetDuration;
            
            AVMutableVideoCompositionLayerInstruction *bgvLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:bgvTrack];
            
            [bgvLayerInstruction setOpacity:1.0f atTime:kCMTimeZero];
            
            //            [bgvLayerInstruction setTransform:bgvAsset.preferredTransform atTime:kCMTimeZero];
            [bgvLayerInstruction setOpacity:0.0 atTime:curTimeCnt];
            
            if((self.orientation>0 && self.orientation <= UIDeviceOrientationFaceUp ) || self.useFontCamera)
            {
                CGAffineTransform trans = [self layerTrans:bgvAsset withTargetSize:size orientation:self.orientation withFontCamera:self.useFontCamera isCreateByCover:isGenerateByCover];
                //                if(!CGAffineTransformEqualToTransform(trans, bgvAsset.preferredTransform))
                //                {
                [bgvLayerInstruction setTransform:trans
                                           atTime:kCMTimeZero];
                //                }
                //                else
                //                {
                //                    trans = bgvAsset.preferredTransform;
                ////                    trans = CGAffineTransformConcat(trans,CGAffineTransformMakeRotation(90 * M_PI / 180));
                //                     trans = CGAffineTransformConcat(trans, CGAffineTransformMakeTranslation(size.width/2, 0-size.height/2));
                //                    [bgvLayerInstruction setTransform:trans
                //                                               atTime:kCMTimeZero];
                //                }
            }
            else
            {
                [bgvLayerInstruction setTransform:[self layerTrans:bgvAsset withTargetSize:size] atTime:kCMTimeZero];
            }
            
            [layers addObject:bgvLayerInstruction];
            return curTimeCnt;
        }
        else
        {
            NSLog(@"video %@ not track of video.",bgvUrl.absoluteString);
        }
    }
    return curTimeCnt;
}

//一定要注意码率，码率最好一致，否则可能会导致失败
- (NSMutableArray *)compositeAudioArray:(AVMutableComposition *)mixComposition maxTime:(CMTime)curTimeCnt rate:(CGFloat)rate
{
    NSMutableArray * audioMixParams = [[NSMutableArray alloc] init];
    
    AVURLAsset * bgmAsset = nil;
    BOOL useAudioInVideo = NO;
    BOOL hasAudioJoined = NO;
    BOOL useAudioBackground = NO;
    if (bgmUrl && [[NSFileManager defaultManager] fileExistsAtPath:[bgmUrl path]]) {
        bgmAsset = [[AVURLAsset alloc] initWithURL:bgmUrl options:nil];
        useAudioBackground = YES;
    }
    else if(bgvUrl && [[NSFileManager defaultManager] fileExistsAtPath:[bgvUrl path]])
    {
        bgmAsset = [[AVURLAsset alloc] initWithURL:bgvUrl options:nil];
        useAudioInVideo = YES;
    }
    hasAudioJoined = joinAudioUrl && [HCFileManager isExistsFile:[joinAudioUrl path]];
    
    //需要判断是否已经将人声与背景合成了
    int justUseBgAudio =!hasAudioJoined || ( bgmAsset && hasAudioJoined && [[bgmAsset.URL path]isEqualToString:[joinAudioUrl path]])?1:0;
    //是否已经合成的，然后下载过来的。根据文件所在的目录可以判断
    BOOL isCapture =  [[udManager_ getFileName:[bgvUrl path]] hasPrefix:[udManager_ localFileDir]]?NO:YES;
    if((bgmAsset && justUseBgAudio==1) || isCapture)
    {
        AVMutableAudioMixInputParameters * trackMix = [self addAudioTrackWithUrl:bgmAsset.URL composite:mixComposition maxTime:curTimeCnt rate:rate needScaleIfRateNotZero:!useAudioInVideo vol:(hasAudioJoined?bgAudioVolume_:1)];
        if(trackMix)
            [audioMixParams addObject:trackMix];
    }
    
    if(justUseBgAudio==0 && hasAudioJoined)
    {
        AVMutableAudioMixInputParameters * trackMix = [self addAudioTrackWithUrl:joinAudioUrl composite:mixComposition maxTime:curTimeCnt rate:rate needScaleIfRateNotZero:YES vol:(!bgmAsset)?1:singVolume_];
        if(trackMix)
            [audioMixParams addObject:trackMix];
    }
    
    return audioMixParams;
}
- (AVMutableAudioMixInputParameters*)addAudioTrackWithUrl:(NSURL *)url composite:(AVMutableComposition *)mixComposition maxTime:(CMTime)curTimeCnt rate:(CGFloat)rate needScaleIfRateNotZero:(BOOL)needScale vol:(CGFloat)vol
{
    //将背景视频和背景音乐合成进去

    AVURLAsset * asset = nil;
    
    asset = [AVURLAsset assetWithURL:url];
    if(!asset) return nil;
    NSArray * trackList = [asset tracksWithMediaType:AVMediaTypeAudio];
    if(trackList.count==0) return nil;
    
    
    CMTime bgAudioTime = asset.duration;
    
    TimeScale bgScale = AUDIO_CTTIMESCALE;
    if(asset && asset.duration.timescale>0)
    {
        bgScale = asset.duration.timescale;
    }
    
    CMTime startTime = CMTimeMake(0, bgScale);
    CMTime duration =  asset.duration;
    //因为背景音乐是完整的，所以如果截取一部分时，要注意重新定位开始的时间
    if(CMTimeCompare(totalBeginTimeForAudio_,kCMTimeZero)>0)
    {
        startTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(totalBeginTimeForAudio_), bgScale);
    }
    if(CMTimeCompare(totalEndTimeForAudio_, kCMTimeZero)>0)
    {
        duration = CMTimeMakeWithSeconds(CMTimeGetSeconds(totalEndTimeForAudio_) - CMTimeGetSeconds(totalBeginTimeForAudio_), bgScale);
        bgAudioTime = duration;
    }
    
    //因为合成的音乐应该小于等于视频长度，否则会黑屏
    
    //使用视频中的原因，因此不需要处理
    if(!needScale)
    {
        
    }
    else
    {
        NSLog(@"video seconds:%f",CMTimeGetSeconds(curTimeCnt));
        //变调第一次进入，则先还原长
        if(rate!=1)
        {
            curTimeCnt.value *= rate;
        }
        //二次编辑时，如果有变调，则合成的音频长度与视频长度对比，就是Rate
        else
        {
            rate = CMTimeGetSeconds(bgAudioTime)/CMTimeGetSeconds(curTimeCnt);
            if(rate >=1.01 || rate <=0.99)
            {
                NSString * filePath = [[AudioGenerater new]scaleAudio:asset withRate:rate beginSeconds:0 endSeconds:-1];
                
                bgmUrl = [NSURL fileURLWithPath:filePath];
                asset = [AVURLAsset assetWithURL:bgmUrl];
                rate = 1;
                bgAudioTime = asset.duration;
            }
            else
            {
                rate = 1;
            }
        }
    }
    
    NSLog(@"bgaudio:%f video:%f",CMTimeGetSeconds(bgAudioTime),CMTimeGetSeconds(curTimeCnt));
    
    //    //因为背景音乐是完整的，所以如果截取一部分时，要注意重新定位开始的时间
    //    if(CMTimeCompare(totalBeginTimeForAudio_,kCMTimeZero)>0)
    //    {
    //        startTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(totalBeginTimeForAudio_), bgScale);
    //    }
    //    if(CMTimeCompare(totalEndTimeForAudio_, kCMTimeZero)>0)
    //    {
    //        duration = CMTimeMakeWithSeconds(CMTimeGetSeconds(totalEndTimeForAudio_) - CMTimeGetSeconds(totalBeginTimeForAudio_), bgScale);
    //        bgAudioTime = duration;
    //    }
    if(CMTimeCompare(bgAudioTime,curTimeCnt)>0)
    {
        bgAudioTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(curTimeCnt), bgAudioTime.timescale);
        duration = bgAudioTime;
    }
    AVMutableCompositionTrack *track = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
    
    if(_volRampSeconds>0 && needScale)
    {
        //音量渐变大
        CMTime rampDuration = CMTimeMakeWithSeconds(_volRampSeconds, bgScale);
        CMTime endRampTime = CMTimeSubtract(duration, rampDuration);
        [trackMix setVolumeRampFromStartVolume:0 toEndVolume:vol timeRange:CMTimeRangeMake(kCMTimeZero, rampDuration)];
        
        [trackMix setVolumeRampFromStartVolume:vol toEndVolume:0 timeRange:CMTimeRangeMake(endRampTime, rampDuration)];
    }
    else
    {
        [trackMix setVolume:bgAudioVolume_ atTime:kCMTimeZero];
    }
    NSError * error = nil;
    //默认视频长度大于音频长度
    [track insertTimeRange:CMTimeRangeMake(startTime, duration)
                   ofTrack:[trackList objectAtIndex:0]
                    atTime:kCMTimeZero
                     error:&error];
    if(error)
    {
        NSLog(@"join video:(mix bgaudio) %@",[error localizedDescription]);
    }
    NSLog(@"join video:(bg audio) %ld/%d (%ld)",duration.value,bgScale,duration.timescale);
    
    if(rate >0 && rate!=1.0)
    {
        [track scaleTimeRange:CMTimeRangeMake(kCMTimeZero, duration)
                   toDuration:CMTimeMake(duration.value/rate, duration.timescale)];
        duration.value /= rate;
        NSLog(@"scale audio  to %f",CMTimeGetSeconds(duration));
    }
    return trackMix;
}
#pragma mark - layertrans
-(CGAffineTransform) layerTrans : (AVAsset *)testAsset  withTargetSize:(CGSize) tsize
{
    AVAssetTrack *vTrack = [[testAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    //    if(!vTrack) return nil;
    
    CGSize inputSize = vTrack.naturalSize;
    CGAffineTransform transform = testAsset.preferredTransform;
    if (inputSize.height > inputSize.width) {
        //以最大可能地填满屏幕为主，有可能会剪切视频
        float scale  = MAX(tsize.width/inputSize.height , tsize.height/inputSize.width);
        transform = CGAffineTransformScale(transform, scale, scale);
        transform = CGAffineTransformRotate(transform,  M_PI / 2.0);
        CGSize newSzie = CGSizeMake(inputSize.height * scale, inputSize.width * scale);
        transform = CGAffineTransformTranslate(transform, (- newSzie.width + tsize.width)/2, (- newSzie.height + tsize.height)/2);
    } else {
        float scale  = MAX(tsize.width/inputSize.width , tsize.height/inputSize.height);
        transform = CGAffineTransformScale(transform, scale, scale);
        CGSize newSzie = CGSizeMake(inputSize.width * scale, inputSize.height * scale);
        transform = CGAffineTransformTranslate(transform, (- newSzie.width + tsize.width)/2, (- newSzie.height + tsize.height)/2);
    }
    return transform;
    
}
- (CGSize)getRealSize:(AVAsset *)testAsset renderSize:(CGSize)rsize orientation:(UIDeviceOrientation)orientation withFontCamera:(BOOL) useFontCamera
{
    AVAssetTrack *curTrack = [[testAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize originSize = curTrack.naturalSize;
    
    CGSize renderSize = rsize;
    //以最大可能地显示完整的视频内容为主，屏幕可能无法填满
    
    CGFloat rate1 = 1;//现需要设置的
    CGFloat rate2 = 1;//原尺寸
    
    switch (orientation) {
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
        {
            rate1 = renderSize.width/renderSize.height;
            rate2 = originSize.width/originSize.height;
        }
            break;
        case UIDeviceOrientationPortraitUpsideDown:
        default:
        {
            rate1 = renderSize.width/renderSize.height;
            rate2 = originSize.height/originSize.width;
        }
            break;
    }
    
    if(rate2>rate1)//原尺寸宽高比较大
    {
        renderSize.height *= rate1/rate2;
    }
    else if(rate2< rate1)
    {
        renderSize.width *= rate2/rate1;
    }
    return renderSize;
}
-(CGAffineTransform)layerTrans:(AVAsset *)testAsset withTargetSize:(CGSize)tsize orientation:(UIDeviceOrientation)orientation withFontCamera:(BOOL) useFontCamera isCreateByCover:(BOOL)isCreateByCover
{
    AVAssetTrack *curTrack = [[testAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize originSize = curTrack.naturalSize;
    CGAffineTransform videoTransform = curTrack.preferredTransform;
    //根据setting的方向来设置这个videotransform
    //如果是横向的还需要修改rendersize
    CGSize renderSize = tsize;
    float scale  = 1;
    
    BOOL isRecord = [self isFromRecordDir:testAsset];
    
    //    originSize = [self getSizeByTransform:originSize transform:videoTransform];
    //以最大可能地显示完整的视频内容为主，屏幕可能无法填满
    
    CGFloat rate1 = renderSize.width/renderSize.height;
    CGFloat rate2 = originSize.width/originSize.height;
    if((rate2>=1 && rate1 >=1) ||(rate2<=1 && rate1<=1))
    {
        scale  = MIN(tsize.width/originSize.width , tsize.height/originSize.height);
    }
    else
    {
        scale  = MIN(tsize.width/originSize.height , tsize.height/originSize.width);
    }
    
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    if(scale!=1)
    {
        transform = CGAffineTransformScale(transform, scale, scale);
    }
    if (!useFontCamera) {
        if(isCreateByCover)
        {
            return videoTransform;
        }
        switch (orientation) {
            case UIDeviceOrientationLandscapeLeft:
            {
                renderSize = CGSizeMake(tsize.height, tsize.width);
                
                transform = CGAffineTransformConcat(transform, videoTransform);
            }
                break;
            case UIDeviceOrientationLandscapeRight:
            {
                renderSize = CGSizeMake(tsize.height, tsize.width);
                videoTransform = CGAffineTransformMakeRotation( M_PI * 180 / 180);
                transform = CGAffineTransformConcat(transform, videoTransform);
                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(renderSize.height, renderSize.width));
            }
                break;
            case UIDeviceOrientationPortraitUpsideDown:
            {
                videoTransform = CGAffineTransformMakeRotation(  M_PI * 270 / 180);
                transform = CGAffineTransformConcat(transform, videoTransform);
                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(0, renderSize.height));
            }
                break;
            default:
            {
                if(isCreateByCover)
                {
                }
                else
                {
                    if(isRecord)
                    {
                        videoTransform = CGAffineTransformMakeRotation( M_PI * 90 / 180);
                        transform = CGAffineTransformConcat(transform, videoTransform);
                        //为什么拍摄的视频需要偏移？
                        transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(renderSize.width, 0));
                    }
                    else
                    {
                        //                        return CGAffineTransformConcat(transform, videoTransform);
                        return videoTransform;
                    }
                }
                
                break;
            }
        }
    } else {
        transform = CGAffineTransformIdentity;
        switch (orientation) {
            case UIDeviceOrientationLandscapeLeft:
            {
                renderSize = CGSizeMake(tsize.height, tsize.width);
                transform = CGAffineTransformScale(transform, scale, scale);
                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(1, -1));
                videoTransform = CGAffineTransformMakeRotation(0 * M_PI / 180);
                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(0, tsize.height));
            }
                break;
            case UIDeviceOrientationLandscapeRight:
            {
                renderSize = CGSizeMake(tsize.height, tsize.width);
                transform = CGAffineTransformScale(transform, scale, scale);
                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(-1, 1));
                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(tsize.width, 0));
            }
                break;
            case UIDeviceOrientationPortraitUpsideDown:
            {
                //                videoTransform = CGAffineTransformMakeRotation( 270 * M_PI / 180);
                transform = CGAffineTransformScale(transform, scale, scale);
                videoTransform = CGAffineTransformMakeRotation(-90 * M_PI / 180);
                transform = CGAffineTransformConcat(transform, videoTransform);
                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(0, renderSize.height));
                //必须先把坐标对与原点对齐才能镜像变换
                transform  = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(-1, 1));
                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(renderSize.width, 0));
            }
                break;
            default:
            {
                transform = CGAffineTransformScale(transform, scale, scale);
                videoTransform = CGAffineTransformMakeRotation(90 * M_PI / 180);
                transform = CGAffineTransformConcat(transform, videoTransform);
                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(renderSize.width, 0));
                transform  = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(-1, 1));
                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(renderSize.width, 0));
            }
                break;
        }
    }
    return transform;
    
}
- (BOOL)isFromRecordDir:(AVAsset *)asset
{
    BOOL isRecord = NO;
    if([asset isKindOfClass:[AVURLAsset class]])
    {
        AVURLAsset * ta = (AVURLAsset *)asset;
        NSString * path = [ta.URL path];
        if([path containsString:[[UDManager sharedUDManager]mtvPlusFileDir]])
        {
            isRecord = YES;
        }
    }
    return isRecord;
}
- (CGAffineTransform)fixTransform:(CGAffineTransform)trans
{
    //    trans.a = roundf(<#float#>)
    return trans;
}
+ (CGAffineTransform) getPlayerTrans:(UIDeviceOrientation)orientation defaultTrans:(CGAffineTransform)defaultTrans
{
    CGAffineTransform videoTransform = defaultTrans;
    switch (orientation) {
        case UIDeviceOrientationLandscapeLeft:
        {
            videoTransform = CGAffineTransformMakeRotation(90 * M_PI / 180);
        }
            break;
        case UIDeviceOrientationLandscapeRight:
        {
            videoTransform = CGAffineTransformMakeRotation( M_PI * 270 / 180);
            //                transform = CGAffineTransformConcat(transform, videoTransform);
            //                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(renderSize.height, renderSize.width));
        }
            break;
        case UIDeviceOrientationPortraitUpsideDown:
        {
            videoTransform = CGAffineTransformMakeRotation(  M_PI * 180 / 180);
            //                transform = CGAffineTransformConcat(transform, videoTransform);
            //                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(0, renderSize.height));
        }
            break;
        default:
        {
            videoTransform = CGAffineTransformMakeRotation( M_PI * 0 / 180);
            //                transform = CGAffineTransformConcat(transform, videoTransform);
            //                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(renderSize.width, 0));
        }
            break;
    }
    return videoTransform;
}
-(CGAffineTransform)getTransSt:(CGSize) size {
    
    CGSize tsize = self.renderSize;
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    CGRect sourceSizenew = [CommonUtil rectFitWithScale:size rectMask:tsize];
    CGFloat scale = 1.0;
    if(sourceSizenew.origin.x >0)
    {
        //         transform = CGAffineTransformTranslate(transform, sourceSizenew.origin.x, 0);
        scale = tsize.height / size.height;
    }
    else
    {
        //        transform = CGAffineTransformTranslate(transform,0, sourceSizenew.origin.y);
        scale = tsize.width / size.width;
    }
    if(scale!=1)
    {
        transform = CGAffineTransformScale (transform,scale,scale);
        //        if(sourceSizenew.origin.x >0)
        //        {
        //            transform = CGAffineTransformTranslate(transform, sourceSizenew.origin.x, 0);
        //        }
        //        else
        //        {
        //            transform = CGAffineTransformTranslate(transform,0, sourceSizenew.origin.y);
        //        }
    }
    
    
    //    if (size.width != tsize.width && size.width == tsize.height) {
    //        transform = CGAffineTransformTranslate(transform, size.height, 0);
    //            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
    //    }
    return transform;
    
}

-(CGAffineTransform)getTransEd:(CGSize) size {
    CGSize tsize = self.renderSize;
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    CGRect sourceSizenew = [CommonUtil rectFitWithScale:size rectMask:tsize];
    CGFloat scale = 1.0;
    if(sourceSizenew.origin.x >0)
    {
        scale = tsize.height/size.height;
        transform = CGAffineTransformTranslate(transform, 0 - sourceSizenew.origin.x * 2 * scale , 0);
        
    }
    else
    {
        scale = tsize.width/ size.width;
        transform = CGAffineTransformTranslate(transform,0, 0 - sourceSizenew.origin.y * 2 * scale );
    }
    if(scale!=1)
    {
        transform = CGAffineTransformScale (transform,scale,scale);
    }
    //
    //    if (size.width != tsize.width && size.width == tsize.height) {
    //        transform = CGAffineTransformTranslate(transform, tsize.width, 0);
    //        if(size.width>size.height)
    //        {
    //            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
    //        }
    //    } else {
    //        if (tsize.width == size.width) {
    //            //宽为1280
    //            transform = CGAffineTransformTranslate(transform, 0, - size.height + tsize.height);
    //
    //        } else {
    //            //高为720
    //            transform = CGAffineTransformTranslate(transform, - size.width + tsize.width,0);
    //        }
    //
    //    }
    
    return transform;
    
}
- (CGSize)getRenderSize
{
    CGFloat width,height;
    UIDevicePlatform platform = [[DeviceConfig config]platformType];
    if ((self.renderSize.width<=1080 && self.renderSize.height<=1080) ||
        (self.renderSize.width && self.renderSize.height && (platform==UIDevice6iPhone ||
                                                             platform == UIDevice6PiPhone ||
                                                             platform == UIDevice6PSiPhone ||
                                                             platform == UIDevice6SiPhone ||
                                                             platform == UIDeviceUnknowniPhone))
        ) {
        width = self.renderSize.width;
        height = self.renderSize.height;
    }
    else if(platform == UIDevice4iPhone || platform==UIDevice4SiPhone)
    {
        //        CGFloat rate1 = 480/320;
        //        CGFloat rate2 = self.renderSize.height/self.renderSize.width;
        //        if(rate2>rate1)
        //        {
        //
        //        }
        //        self.renderSize.width
        width = 480;
        height = 320;
    }
    else{
        width = 568;
        height = 320;
    }
    CGSize size = CGSizeMake(width, height);
    
    return [self getSizeByOrientation:size];
}

- (void)buildMetaData:(AVAssetExportSession *)output
{
    //暂时先不处理，稍后再来 2015-11-02
    //    NSMutableArray * metaList = [joinVideoExporter.metadata mutableCopy];
    //    AVMutableMetadataItem * item = [[AVMutableMetadataItem alloc] init];
    //    item.keySpace = @"";
    //    item.key = @"";
    //    item.value = @"";
    //    [metaList addObject:item];
    //    joinVideoExporter.metadata = metaList;
}
- (void)cancelExporter
{
    if(timerForExport_)
    {
        [timerForExport_ invalidate];
        PP_RELEASE(timerForExport_);
    }
    
    if(joinVideoExporter)
        [joinVideoExporter cancelExport];
    PP_RELEASE(joinVideoExporter);
}
- (void)checkProgress:(NSTimer *)timer
{
    if(progressBlock_)
    {
        progressBlock_(self,joinVideoExporter.progress);
    }
    else if(self.delegate && [self.delegate respondsToSelector:@selector(VideoGenerater:generateProgress:)])
    {
        [self.delegate VideoGenerater:self generateProgress:joinVideoExporter.progress];
    }
}

-(void)exportDidFinish:(SDAVAssetExportSession*)session{
    
    NSLog(@"exportDidFinish");
    
    NSLog(@"session = %d",(int)session.status);
    if (session.status == AVAssetExportSessionStatusCompleted) {
        
        NSLog(@"generate completed:%@",[[session outputURL]absoluteString]);
        if(completedBlock_)
        {
            completedBlock_(self,[session outputURL],nil);
            completedBlock_ = nil;
        }
        else if(self.delegate && [self.delegate respondsToSelector:@selector(VideoGenerater:didGenerateCompleted:cover:)])
        {
            [self.delegate VideoGenerater:self didGenerateCompleted:[session outputURL] cover:nil];
        }
        
    }else {
        if(session.status == AVAssetExportSessionStatusCancelled)
        {
            NSLog(@"generate AVAssetExportSessionStatusCancelled");
            if(failureBlock_)
            {
                failureBlock_(self,@"生成被取消",[self buildError:@"生成被取消"]);
                failureBlock_ = nil;
            }
            return;
        }
        else
        {
            if(failureBlock_)
            {
                failureBlock_(self,[[session error]localizedDescription],[session error]);
                failureBlock_ = nil;
            }
            else if(self.delegate && [self.delegate respondsToSelector:@selector(VideoGenerater:didGenerateFailure:error:)])
            {
                [self.delegate VideoGenerater:self didGenerateFailure:[[session error]localizedDescription] error:[session error]];
            }
            NSLog(@"generate failure:%@",[session error]);
        }
        //        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
        //                                                        message:@"存档失败"
        //                                                       delegate:nil
        //                                              cancelButtonTitle:@"OK"
        //                                              otherButtonTitles:nil];
        //        [alert show];
    }
    
}

#pragma mark - properties data covert
-(AVAsset *) getVideoItemAsset:(MediaItem *)item
{
    NSAssert(item!=nil, @"get video item cannot be nil;");
    if (item.isImg) {
        if([[NSFileManager defaultManager]fileExistsAtPath:item.filePath])
        {
            return [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:item.filePath] options:nil];
        } else {
            NSLog(@"JoinVideo:IMG2Video文件不完整PATH===%@",item.fileName);
            return nil;
        }
    } else  {
        AVAsset *testAvasset = [[AVURLAsset alloc] initWithURL:item.url options:nil];
        return testAvasset;
    }
    return nil;
    
}
- (NSString *)getKeyForMediaList:(NSArray *)mediaList
{
    //如果文件存在，则检查是否匹配，如果匹配，则不需要再生成
    NSMutableString * keyString = [NSMutableString new];
    
    for (MediaItem * item in mediaList) {
        [keyString appendFormat:@"%@-%.1f-%.1f-%.1f",item.fileName,item.secondsInArray,item.secondsBegin,item.secondsDurationInArray ];
    }
    
    [keyString appendFormat:@"time:%.1f/%.1f-vol:%.4f/%.4f",CMTimeGetSeconds(totalBeginTime_),CMTimeGetSeconds(totalEndTime_),bgAudioVolume_,singVolume_];
    
    NSString *key = [NSString stringWithFormat:@"%@.mp4",[CommonUtil md5Hash:keyString]];
    return key;
}
#pragma mark - helper
-(NSURL *)finalVideoUrl
{
    
    if (joinVideoUrl) {
        return joinVideoUrl;
    }
    
    NSString *newVideoName = [[MediaListModel shareObject] getNewVideoFileName:nil];
    NSString *myPathDocs =  [udManager_ localFileFullPath:newVideoName];
    
    joinVideoUrl = PP_RETAIN([NSURL fileURLWithPath:myPathDocs]);
    
    return joinVideoUrl;
}

#pragma mark - remove clear
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
    NSLog(@"seenvoice queue clear files...");
    
    //remove other files match temp file
    [udManager_ removeTempVideos];
    
    if(joinAudioUrl)
    {
        NSString * path = [joinAudioUrl absoluteString];
        if(![path hasSuffix:@"mp4.m4a"] && ![path hasSuffix:@"mp4.mp3"])
            [udManager_ removeFileAtPath:[HCFileManager checkPath:path]];
    }
    if(joinVideoUrl)
    {
        [udManager_ removeFileAtPath:[HCFileManager checkPath:joinVideoUrl.absoluteString]];
    }
}
- (void)clear
{
    progressBlock_ = nil;
    itemReadyBlock_ = nil;
    completedBlock_ = nil;
    failureBlock_ = nil;
    
    totalBeginTime_ = kCMTimeZero;
    totalEndTime_ = kCMTimeZero;
    
    self.mergeRate = 1.0;
    self.lrcBeginTime = 0;
    self.lrcList = nil;
    self.waterMarkFile = nil;
    self.filterLrcList = nil;
    renderSize_ = CGSizeMake(1280,720);
    _orientation = 0;
    
    [self clearFiles];
    
    //    [chooseQueue removeAllObjects];
    //    [finalQueue removeAllObjects];
    //    [ImgToVideoQueue removeAllObjects];
    //    [TransQueeu removeAllObjects];
    
    PP_RELEASE(_mixComposition);
    PP_RELEASE(_videoComposition);
    
    PP_RELEASE(joinVideoUrl);
    PP_RELEASE(joinAudioUrl);
    
}

- (NSError *)buildError:(NSString *)msg
{
    if(!msg) return nil;
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:msg
                                                         forKey:NSLocalizedDescriptionKey];
    NSError *aError = [NSError errorWithDomain:@"com.seenvoice.maiba" code:-1000 userInfo:userInfo];
    return aError;
}
#pragma mark - dealloc
- (void)dealloc
{
    [self clear];
    
    PP_RELEASE(_mixComposition);
    PP_RELEASE(_videoComposition);
    PP_RELEASE(_audioMixOnce);
    PP_RELEASE(lastGenerateKey_);
    
    PP_SUPERDEALLOC;
}
- (void)didReceiveMemoryWarning
{
    //    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"memorywaring===========");
}
@end

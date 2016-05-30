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
#import "AVAssetReverseSession.h"

@interface VideoGenerater()
{
    AVAssetReverseSession * currentReverseSession_;
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
    BOOL isGenerating_;
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
        
        NSLog(@"playeritemstatus:%d",(int)previewAVPlayItem.status);
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
    if(timerForExport_)
    {
        timerForExport_.fireDate = [NSDate distantFuture];
        [timerForExport_ invalidate];
        PP_RELEASE(timerForExport_);
    }
    PP_RELEASE(_waterMarkFile);
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
    }
    
    
    joinVideoExporter = [SDAVAssetExportSession exportSessionWithAsset:_mixComposition];
    joinVideoExporter.outputURL = pathForFinalVideo;
    
    //    AVMutableVideoCompositionInstruction * instructs = (AVMutableVideoCompositionInstruction*)[_videoComposition.instructions firstObject];
    //    joinVideoExporter.timeRange = instructs.timeRange;
    
    [[HCFileManager manager]removeFileAtPath:[pathForFinalVideo path]];
    
    joinVideoExporter.outputFileType = AVFileTypeMPEG4;
    
    joinVideoExporter.shouldOptimizeForNetworkUse = YES;
    joinVideoExporter.videoComposition = _videoComposition;
    joinVideoExporter.audioMix = _audioMixOnce;
    
    if(joinTimeRange_.duration.value>0)
        joinVideoExporter.timeRange = joinTimeRange_;
    
    CGSize renderSize = _videoComposition.renderSize;// [self getRenderSize];
    if(renderSize.width==0||renderSize.height==0)
    {
        renderSize = [self getRenderSize];
    }
    NSNumber *width =  [NSNumber numberWithFloat:renderSize.width];
    NSNumber *height=  [NSNumber numberWithFloat:renderSize.height];
    
    joinVideoExporter.videoSettings= @{
                                       AVVideoCodecKey: AVVideoCodecH264,
                                       AVVideoWidthKey: width,
                                       AVVideoHeightKey: height,
                                       AVVideoCompressionPropertiesKey: @
                                           {
                                           AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
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
        
        if(!timerForExport_)
        {
            timerForExport_ = PP_RETAIN([NSTimer timerWithTimeInterval:0.1
                                                                target:self
                                                              selector:@selector(checkProgress:)
                                                              userInfo:nil
                                                               repeats:YES]);
            
            [[NSRunLoop mainRunLoop] addTimer:timerForExport_ forMode:NSDefaultRunLoopMode];
        }
        timerForExport_.fireDate = [NSDate distantPast];
//        timerForExport_ = PP_RETAIN([NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkProgress:) userInfo:nil repeats:YES]);
        
        __weak SDAVAssetExportSession * weakJoin = joinVideoExporter;
        [joinVideoExporter exportAsynchronouslyWithCompletionHandler:^{
            
            __strong SDAVAssetExportSession * strongJoin = weakJoin;
//            [timerForExport_ invalidate];
//            PP_RELEASE(timerForExport_);
            timerForExport_.fireDate = [NSDate distantFuture];
            
            //            dispatch_async(dispatch_get_main_queue(), ^{
            [self exportDidFinish:strongJoin];
            //            });
        }];
        if(joinVideoExporter.error)
        {
            timerForExport_.fireDate = [NSDate distantFuture];
            NSLog(@"export error:%@",[joinVideoExporter.error localizedDescription]);
            return NO;
        }
        NSLog(@"export status:%d",(int)joinVideoExporter.status);
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
- (BOOL) generateMVSegmentsViaFile:(NSString *)filePath begin:(CGFloat) begin end:(CGFloat)end
{
    return [self generateMVSegmentsViaFile:filePath begin:begin end:end targetSize:CGSizeZero];
}
- (BOOL) generateMVSegmentsViaFile:(NSString *)filePath begin:(CGFloat) begin end:(CGFloat)end  targetSize:(CGSize)targetSize
{
    AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:filePath]];
    if(!asset||asset.tracks.count==0)
    {
        NSLog(@"not media file content");
        return NO;
    }
    return [self generateMVSegments:asset begin:begin end:end targetSize:targetSize];
}
- (BOOL) generateMVSegmentsViaPhAsset:(PHAsset *)asset begin:(CGFloat) begin end:(CGFloat)end  targetSize:(CGSize)targetSize
{
    return NO;
}
- (BOOL) generateMVSegments:(AVAsset *)asset begin:(CGFloat) begin end:(CGFloat)end  targetSize:(CGSize)targetSize
{
    if(!asset||asset.tracks.count==0)
    {
        NSLog(@"not media file content");
        return NO;
    }
    
    if(isGenerating_)
    {
        NSLog(@"正在生成过程中，不能重入....");
        return NO;
    }
    isGenerating_ = YES;
    
    CMTime totalDuration = asset.duration;
    
    PP_RELEASE(_mixComposition);
    PP_RELEASE(_videoComposition);
    PP_RELEASE(_audioMixOnce);
    
    CGSize size = targetSize;
    CGFloat scale = 1;
    
    NSArray * tracklist = [asset tracksWithMediaType:AVMediaTypeVideo];
    if(tracklist.count<=0)
    {
        return NO;
    }
    
    AVAssetTrack * track = [tracklist firstObject];
    CGSize natureSize = track.naturalSize;
    if(size.width<=0||size.height<=0)
    {
        size = natureSize;
    }
    else
    {
        size = [self getSizeByTransform:size transform:track.preferredTransform];
        scale = MIN(size.width/natureSize.width,size.height/natureSize.height);
        size = CGSizeMake(roundf(natureSize.width * scale), roundf(natureSize.height *scale));
    }
    AVMutableVideoComposition * mainComposition =  [AVMutableVideoComposition videoComposition];
    AVMutableComposition * mixComposition = [[AVMutableComposition alloc] init];
    AVMutableAudioMix * bgmMix = [AVMutableAudioMix audioMix];
    
    
    NSMutableArray *layers  = [[NSMutableArray alloc] init];
    
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    UInt32 bgScale = totalDuration.timescale;
    
    CMTime startTime = CMTimeMakeWithSeconds(MAX(begin,0), bgScale);
    
    CGFloat sourceDurationSeconds = CMTimeGetSeconds(totalDuration);
    
    if(end<=0 || end >sourceDurationSeconds)
    {
        end = sourceDurationSeconds;
    }
    
    CMTime targetDuration = CMTimeMakeWithSeconds(end - begin, bgScale);
    
    {
        AVMutableCompositionTrack *bgvTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                          preferredTrackID:kCMPersistentTrackID_Invalid];
        
        NSError * error = nil;
        [bgvTrack insertTimeRange:CMTimeRangeMake(startTime, targetDuration)
                          ofTrack:track
                           atTime:kCMTimeZero
                            error:&error];
        if(error)
        {
            NSLog(@"join video:(mix bgvideo) %@",[error localizedDescription]);
        }
        
        CGAffineTransform  transfer = track.preferredTransform;
        
        [bgvTrack setPreferredTransform:transfer];
        
        AVMutableVideoCompositionLayerInstruction *bgvLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:bgvTrack];
        
        [bgvLayerInstruction setOpacity:1.0f atTime:kCMTimeZero];
        
        [bgvLayerInstruction setOpacity:0.0 atTime:targetDuration];
        
        CGAffineTransform  transfer2 = CGAffineTransformIdentity;
        if(scale!=1)
        {
            transfer2 = CGAffineTransformScale(transfer2, scale, scale);
        }
        [bgvLayerInstruction setTransform:transfer2 atTime:kCMTimeZero];
        
        [layers addObject:bgvLayerInstruction];
    }
    
    //音频混入
    
    {
        NSArray * audioTrackList = [asset tracksWithMediaType:AVMediaTypeAudio];
        if(audioTrackList.count>0)
        {
            AVAssetTrack * trackSource = [audioTrackList firstObject];
            NSMutableArray * audioMixParams = [[NSMutableArray alloc] init];
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                preferredTrackID:kCMPersistentTrackID_Invalid];
            AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
            
            
            [trackMix setVolume:1 atTime:kCMTimeZero];
            
            NSError * error = nil;
            //默认视频长度大于音频长度
            [audioTrack insertTimeRange:CMTimeRangeMake(startTime, targetDuration)
                                ofTrack:trackSource
                                 atTime:kCMTimeZero
                                  error:&error];
            
            [audioMixParams addObject:trackMix];
            bgmMix.inputParameters = audioMixParams;
        }
        
    }
    
    //对最终合成视频asset的设置
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero,targetDuration); //时间长度必须设置  不然会出错（黑屏）
    mainInstruction.layerInstructions = layers;
    
    CMTime time =  CMTimeMake(1, 30);
    
    mainComposition.instructions = [NSArray arrayWithObjects:mainInstruction,nil];
    mainComposition.frameDuration = time;
    mainComposition.renderSize =  size;//CGSizeMake(640, 480);//
    
    NSLog(@"prejoin:%@",NSStringFromCGSize(size));
    
    _mixComposition = PP_RETAIN((AVMutableComposition*)mixComposition);
    _videoComposition = PP_RETAIN((AVMutableVideoComposition*)mainComposition);
    _audioMixOnce = PP_RETAIN((AVMutableAudioMix*)bgmMix);
    
    previewAVassetIsReady = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(sendPlayerItemToFront:) userInfo:nil repeats:NO];
        isGenerating_ = NO;
    });
    
    return YES;
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

//- (BOOL)generatePreviewWithActions:(NSArray *)mediaWithActions
//                             audio:(NSString *)audioPath
//                             begin:(CMTime)beginTime
//                               end:(CMTime)endTime
//                     bgAudioVolume:(CGFloat)volume
//                        singVolume:(CGFloat)singVolume
//                          progress:(MEProgress)progress
//                             ready:(MEPlayerItemReady)itemReady
//{
//    if (joinVideoExporter) {
//        [joinVideoExporter cancelExport];
//        joinVideoExporter = nil;
//    }
//
////    mixComposition = [[AVMutableComposition alloc] init];
////    NSMutableArray *layers  = [[NSMutableArray alloc] init];
////    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
////    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
////    AVMutableVideoCompositionLayerInstruction *curLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
////    //将当前层保存到音频层管理器中
////
////    AVAsset *curAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path_]];
////    AVAsset *rAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:rPath_]];
//
//
//    //    for (int i = 0; i< items_.count; i ++) {
//    //        SItem * tem = (SItem *)[items_ objectAtIndex:i];
//    //        int32_t timeScale = curAsset.duration.timescale;
//    //        CMTime start = CMTimeMakeWithSeconds(lastTime_, timeScale);
//    //        CMTime diff;
//    //        CMTime trackDur = videoTrack.timeRange.duration;
//    //        if (isnan(CMTimeGetSeconds(trackDur))) {
//    //            trackDur = kCMTimeZero;
//    //        }
//    //        NSLog(@"videotrack dur = %.3f", CMTimeGetSeconds(trackDur));
//    //        AVAssetTrack * cTrack = [[curAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//    //        AVAssetTrack * rTrack = [[rAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//    //        switch (tem.type) {
//    //            case SFast:
//    //            {
//    //                if (tem.sTime > lastTime_) {
//    //                    //插入原视频片段<lasttime, tem.st>
//    //                    diff = CMTimeMakeWithSeconds(tem.sTime - lastTime_, timeScale);
//    //                    [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//    //                    trackDur = videoTrack.timeRange.duration;
//    //                    NSLog(@"videotrack dur = %.3f", CMTimeGetSeconds(trackDur));
//    //                }
//    //                //插入原视频片段<tem.st,tem.ed>，压缩range,使播放加速
//    //                diff = CMTimeMakeWithSeconds(tem.eTime - tem.sTime, timeScale);
//    //                start = CMTimeMakeWithSeconds(tem.sTime, timeScale);
//    //                [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//    //                [videoTrack scaleTimeRange:CMTimeRangeMake(trackDur, diff) toDuration:CMTimeMakeWithSeconds((tem.eTime- tem.sTime) / 2, timeScale)];
//    //                lastTime_ = tem.eTime;
//    //            }
//    //                break;
//    //            case SSlow:
//    //            {
//    //                if (tem.sTime > lastTime_) {
//    //                    //插入原视频片段<lasttime, tem.st>
//    //                    diff = CMTimeMakeWithSeconds(tem.sTime - lastTime_, timeScale);
//    //                    [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//    //                    trackDur = videoTrack.timeRange.duration;
//    //                    NSLog(@"videotrack dur = %.3f", CMTimeGetSeconds(trackDur));
//    //                }
//    //                //插入原视频片段<tem.st,tem.ed>，延展range,使播放减速
//    //                diff = CMTimeMakeWithSeconds(tem.eTime - tem.sTime, timeScale);
//    //                start = CMTimeMakeWithSeconds(tem.sTime, timeScale);
//    //                [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//    //                [videoTrack scaleTimeRange:CMTimeRangeMake(trackDur, diff) toDuration:CMTimeMakeWithSeconds((tem.eTime- tem.sTime) * 2, timeScale)];
//    //                lastTime_ = tem.eTime;
//    //            }
//    //                break;
//    //            case SRepeat:
//    //            {
//    //                if (tem.sTime > lastTime_) {
//    //                    //插入片段
//    //                    diff = CMTimeMakeWithSeconds(tem.sTime - lastTime_, timeScale);
//    //                    [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//    //                    trackDur = videoTrack.timeRange.duration;
//    //                    NSLog(@"videotrack dur = %.3f", CMTimeGetSeconds(trackDur));
//    //                }
//    //                //回退0.5s并反复插入
//    //                diff = CMTimeMakeWithSeconds(0.5, timeScale);
//    //                start = CMTimeMakeWithSeconds(tem.sTime - 0.5, timeScale);
//    //                [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//    //                trackDur = videoTrack.timeRange.duration;
//    //                [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//    //                trackDur = videoTrack.timeRange.duration;
//    //                [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//    //                trackDur = videoTrack.timeRange.duration;
//    //                lastTime_ = tem.sTime;
//    //            }
//    //                break;
//    //            case SReverse:
//    //            {
//    //                CGFloat stInOrigin = CMTimeGetSeconds(curAsset.duration) - tem.sTime;
//    //                if (stInOrigin > lastTime_) {
//    //                    //插入正向片段
//    //                    diff = CMTimeMakeWithSeconds(tem.sTime - lastTime_, timeScale);
//    //                    [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//    //                    trackDur = videoTrack.timeRange.duration;
//    //                    NSLog(@"videotrack dur = %.3f", CMTimeGetSeconds(trackDur));
//    //                }
//    //                //插入反向片段 rAsset<sTime, eTime>
//    //                diff = CMTimeMakeWithSeconds(tem.eTime - tem.sTime, timeScale);
//    //                start = CMTimeMakeWithSeconds(tem.sTime, timeScale);
//    //                [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:rTrack atTime:trackDur error:nil];
//    //                lastTime_ = CMTimeGetSeconds(curAsset.duration) - tem.eTime;
//    //            }
//    //                break;
//    //            default:
//    //            {
//    //                NSLog(@"finish mark");
//    //                if (tem.eTime && tem.eTime > lastTime_) {
//    //                    diff = CMTimeMakeWithSeconds(tem.eTime - lastTime_, timeScale);
//    //                    [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//    //                    trackDur = videoTrack.timeRange.duration;
//    //                    NSLog(@"videotrack dur = %.3f", CMTimeGetSeconds(trackDur));
//    //                }
//    //            }
//    //                break;
//    //        }
//    //    }
//    //
//    //    [layers addObject:curLayerInstruction];
//    //    mainInstruction.timeRange = videoTrack.timeRange;
//    //    mainInstruction.layerInstructions = [[NSArray alloc] initWithArray:layers];
//    //    mainComposition = [AVMutableVideoComposition videoComposition];
//    //    mainComposition.instructions = [NSArray arrayWithObjects:mainInstruction,nil];
//    //    mainComposition.frameDuration = CMTimeMake(1, 30);
//    //    _RenderSize = [[curAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0].naturalSize;
//    //    mainComposition.renderSize = _RenderSize;
//    return NO;
//}

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
    if(isGenerating_)
    {
        NSLog(@"正在生成过程中，不能重入....");
        return;
    }
    isGenerating_ = YES;
    BOOL isOverlap = YES; //在背景视频上添加视频
    //注意此处需要处理是否根据一张图和一个音乐来合成视频。现在的检查不支持这种情况
    CMTime totalDuration = bgvUrl?[self getTotalDuration:bgvUrl]:kCMTimeZero;
    
    PP_RELEASE(_mixComposition);
    PP_RELEASE(_videoComposition);
    PP_RELEASE(_audioMixOnce);
    
    size = CGSizeZero;
    if(totalDuration.value ==0)
    {
        isOverlap = NO; //多个视频分段相加
        totalDuration = [self getTotalDurationByList:mediaList];
    }
    
    CGFloat rate = self.mergeRate>0 ?self.mergeRate :1.0;
    if(rate!=1.0)
    {
        totalDuration.value /= rate;
    }
    //    if(!isOverlap)
    //    {
    //        size = CGSizeZero; //准备从素材中获取
    //    }
    //    else
    //    {
    //        size = [self getSizeByOrientation:size];
    //    }
    
    lastGenerateKey_ = [self getKeyForMediaList:mediaList];
    
    
    AVMutableVideoComposition * mainComposition  = [AVMutableVideoComposition videoComposition];;
    AVMutableComposition * mixComposition = [[AVMutableComposition alloc] init];
    AVMutableAudioMix *bgmMix = [AVMutableAudioMix audioMix];
    
    NSMutableArray *layers  = [[NSMutableArray alloc] init];
    NSMutableArray * audioMixParams = [NSMutableArray new];
    
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    CMTimeRange range = kCMTimeRangeZero;
    CMTime curTimeCnt = kCMTimeZero;
    
    if (mediaList && mediaList.count>0) {
        //选择的素材>1
        AVMutableCompositionTrack * imageTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                             preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVMutableCompositionTrack * videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                             preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVMutableCompositionTrack * audioTrack = nil;
        //如果有背景视频，这里就是合并了，所以就不需要这个过程中的声音。
        if(!bgvUrl && singVolume_>0)
        {
            audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                     preferredTrackID:kCMPersistentTrackID_Invalid];
        }
        AVMutableVideoCompositionLayerInstruction *imageLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:imageTrack];
        AVMutableVideoCompositionLayerInstruction *videoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        
        
        NSInteger imageCnt = 0;
        NSInteger videoCnt = 0;
        CMTimeValue lastTimeValue = 0;
        BOOL hasAudioTrack = NO;
        for (int i = 0 ; i < mediaList.count ; i ++ ) {
            MediaItem * curItem = [mediaList objectAtIndex:i];
            
            if(curItem.secondsDurationInArray <=0) continue;
            
            if(!isOverlap)
            {
                curItem.timeInArray = CMTimeMake(lastTimeValue, totalDuration.timescale);
            }
            
            CMTime modalOffEtInQueue = [self compsiteOneItem:curItem
                                                       index:i
                                               lastTimeValue:lastTimeValue
                                               totalDuration:totalDuration
                                                  imageTrack:imageTrack
                                                 imagelayers:imageLayerInstruction
                                                  videoTrack:videoTrack
                                                 videoLayers:videoLayerInstruction
                                                  audioTrack:audioTrack
                                                        rate:rate
                                                        size:&size
                                               hasAudioTrack:&hasAudioTrack];
            
            if(CMTimeCompare(modalOffEtInQueue, kCMTimeZero)==0) continue;
            
            if(curItem.originType == MediaItemTypeIMAGE)
                imageCnt ++;
            else
                videoCnt ++;
            
            if (CMTimeGetSeconds(modalOffEtInQueue) > CMTimeGetSeconds(curTimeCnt) ) {
                curTimeCnt = modalOffEtInQueue;
            }
            
            NSLog(@"current total duration:%.2f,this (%.2f-->%.2f)(%.2f) rate:%.2f",
                  CMTimeGetSeconds(curTimeCnt),
                  (float)lastTimeValue/modalOffEtInQueue.timescale,
                  CMTimeGetSeconds(modalOffEtInQueue),
                  curItem.secondsDurationInArray,
                  curItem.playRate);
            
            lastTimeValue = modalOffEtInQueue.value ;
            
        }
        
        if (imageCnt) {
            [layers addObject:imageLayerInstruction];
        }
        if (videoCnt) {
            [layers addObject:videoLayerInstruction];
        }
        range = videoTrack.timeRange;
        
        if(audioTrack && hasAudioTrack)
        {
            AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
            [trackMix setVolume:singVolume_ atTime:kCMTimeZero];
            [audioMixParams addObject:trackMix];
        }
    }
    //有背景视频时，才比较总长度。因为多段视频合成时，可能有长度误差。
    if(CMTimeCompare(curTimeCnt, totalDuration)<0 && (bgmUrl || bgvUrl))
    {
        curTimeCnt = CMTimeMakeWithSeconds(CMTimeGetSeconds(totalDuration), (totalDuration.timescale>curTimeCnt.timescale?totalDuration.timescale:curTimeCnt.timescale));
    }
    
    if(isOverlap)
    {
        curTimeCnt = [self compositeBGVideo:mixComposition layers:layers maxTime:curTimeCnt size:&size rate:rate];
        range = CMTimeRangeMake(kCMTimeZero,curTimeCnt);
    }
    NSLog(@"track range :%.2f",CMTimeGetSeconds(range.duration));
    
    
    //音频混入
    if(bgmUrl || bgvUrl || joinAudioUrl)
    {
        NSMutableArray * audioParamters = [self compositeAudioArray:mixComposition maxTime:curTimeCnt rate:rate];
        [audioMixParams addObjectsFromArray:audioParamters];
    }
    
    joinTimeRange_ = range;
    //set values
    {
        bgmMix.inputParameters = audioMixParams;
        
        //对最终合成视频asset的设置
        mainInstruction.timeRange = range; //时间长度必须设置  不然会出错（黑屏）
        mainInstruction.layerInstructions = layers;
        
        mainComposition.instructions = [NSArray arrayWithObjects:mainInstruction,nil];
        mainComposition.frameDuration = CMTimeMake(1, 30); //30 f/s
        mainComposition.renderSize =  size;//CGSizeMake(640, 480);//
        
        mixComposition.naturalSize = size;//[self getSizeByOrientation:size];
        
    }
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
        isGenerating_ = NO;
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
- (BOOL)generateMVReverse:(NSString *)sourcePath target:(NSString *)targetPath complted:(void (^)(NSString * filePath))complted
{
    if(![HCFileManager isExistsFile:sourcePath])
    {
        NSLog(@"file not exists:%@",sourcePath);
        return NO;
    }
    if(!targetPath||targetPath.length<2)
    {
        NSLog(@"target file name is nil");
        return NO;
    }
    if([HCFileManager isExistsFile:targetPath])
    {
        [[HCFileManager manager] removeFileAtPath:targetPath];
    }
    
    AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:sourcePath]];
    AVAssetReverseSession *session = [[AVAssetReverseSession alloc] initWithAsset:asset];
    currentReverseSession_ = session;
    NSURL *outputURL = [NSURL fileURLWithPath:targetPath];
    
    session.outputFileType = AVFileTypeMPEG4;
    session.outputURL = outputURL;
    
    [session reverseAsynchronouslyWithCompletionHandler:^{
        currentReverseSession_ = nil;
        if (session.status == AVAssetReverseSessionStatusCompleted) {
            NSURL *outputURL = session.outputURL;
            NSLog(@"reverse mv file finished:%@",[outputURL path]);
            if(complted)
            {
                complted([outputURL path]);
            }
        } else {
            
            NSLog(@"rever failed");
            if(complted)
            {
                complted(nil);
            }
        }
    }];
    return YES;
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
- (CMTime) getTotalDurationByList:(NSArray *)mediaList
{
    CGFloat seconds = 0;
    CMTimeScale timescale = DEFAULT_TIMESCALE;
    for (MediaItem * item in mediaList) {
        seconds += roundf(item.secondsDurationInArray/item.playRate * 100)/100;
        timescale = item.begin.timescale;
    }
    return CMTimeMakeWithSeconds(seconds, timescale);
}
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

- (CMTime) compsiteOneItem:(MediaItem*)curItem index:(int)index
             lastTimeValue:(CMTimeValue)lastTimeValue totalDuration:(CMTime)totalDuration
                imageTrack:(AVMutableCompositionTrack*)imageTrack
               imagelayers:(AVMutableVideoCompositionLayerInstruction*)imageLayerInstruction
                videoTrack:(AVMutableCompositionTrack*)videoTrack
               videoLayers:(AVMutableVideoCompositionLayerInstruction*)videoLayerInstruction
                audioTrack:(AVMutableCompositionTrack *)audioTrack
                      rate:(CGFloat)rate
                      size:(CGSize *)size
             hasAudioTrack:(BOOL *) hasAudioTrack
{
    AVAsset *curAsset = [self getVideoItemAsset:curItem];
    if(hasAudioTrack)
        *hasAudioTrack = NO;
    if(!curAsset || CMTimeGetSeconds(curAsset.duration)<0.01)
    {
        NSLog(@"join video: %@ duration:%.1f skipped",curItem.fileName,CMTimeGetSeconds(curAsset.duration));
        return kCMTimeZero;
    }
    
    CMTime duration = CMTimeMakeWithSeconds(curItem.secondsDurationInArray, totalDuration.timescale);
    
    if(CMTimeGetSeconds(duration)<0.034) //一帧的时间
    {
        NSLog(@"join video: duration:%f error.",CMTimeGetSeconds(duration));
        return kCMTimeZero;
    }
    //切入时间与切出时间
    CMTime modalInStInQueue = (curItem.timeInArray.timescale != totalDuration.timescale)
    ? CMTimeMakeWithSeconds(curItem.secondsInArray,totalDuration.timescale)
    : curItem.timeInArray; //切入时间
    
    CMTime modalOffEtInQueue = CMTimeAdd(modalInStInQueue, duration); //最后消失时间
    NSLog(@"out seconds:%.2f",CMTimeGetSeconds(modalOffEtInQueue));
    
    //全轨处理
    if(rate>0 && rate!=1.0)
    {
        modalInStInQueue.value = round(modalInStInQueue.value/rate +0.5);
        modalOffEtInQueue.value = round(modalOffEtInQueue.value/rate + 0.5);
    }
    
    //单个对像处理
    if(curItem.playRate!=1 && curItem.playRate>0)
    {
        CMTime diff = CMTimeSubtract(modalOffEtInQueue, modalInStInQueue);
        modalOffEtInQueue.value = (CMTimeValue)(diff.value /curItem.playRate) + modalInStInQueue.value;
        //        modalOffEtInQueue.value = round(modalOffEtInQueue.value/curItem.playRate + 0.5);
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
    //    if(CMTimeGetSeconds(modalOffEtInQueue) > CMTimeGetSeconds(totalDuration))
    //    {
    //        modalOffEtInQueue = totalDuration;// CMTimeMake(totalDuration.value - totalDuration.timescale/10,totalDuration.timescale);
    //        duration = CMTimeSubtract(modalOffEtInQueue, modalInStInQueue);
    //    }
    
    if(lastTimeValue >= modalOffEtInQueue.value)
    {
        return kCMTimeZero;
    }
    
    NSLog(@"*** media at:%.2f(%.2f/%.2f) f:(%.2f->%.2f ) t:(%.2f -> %.2f) len:%.2f ",
          curItem.secondsInArray,
          curItem.secondsDurationInArray,
          CMTimeGetSeconds(duration),
          curItem.secondsBegin,
          curItem.secondsEnd,
          CMTimeGetSeconds(modalInStInQueue),
          CMTimeGetSeconds(modalOffEtInQueue),
          CMTimeGetSeconds(CMTimeSubtract(modalOffEtInQueue,modalInStInQueue)));
    
    AVAssetTrack * curTrack = [[curAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    if (curItem.isImg) {
        
        CMTime modalOffStInQueue = CMTimeMakeWithSeconds(CMTimeGetSeconds(modalOffEtInQueue) - 1.0f/rate, totalDuration.timescale); //开始切出的时间
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
        
        [videoTrack setPreferredTransform:curTrack.preferredTransform];
        NSError * error = nil;
        
        [imageTrack insertTimeRange:CMTimeRangeMake(curItem.begin, realDuration)
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
        if(size && ((*size).width ==0 || (*size).height ==0 ))
        {
            *size = [self getSizeByOrientation:curItemSize];
        }
        
        CMTimeRange drange = CMTimeRangeMake(modalInStInQueue, duration);
        
        CGAffineTransform transSt = [self getTransSt:curItemSize];
        CGAffineTransform transEd = [self getTransEd:curItemSize];
        
        NSLog(@"timerange:(%f--%f)",CMTimeGetSeconds(drange.start),CMTimeGetSeconds(drange.duration));
        
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
                    modalOffStInQueue = CMTimeMakeWithSeconds(0.1, totalDuration.timescale);
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
        
        AVAssetTrack * curAudioTrack = nil;
        if(audioTrack)
        {
            NSArray * audioTracks = [curAsset tracksWithMediaType:AVMediaTypeAudio];
            if(audioTracks.count>0)
            {
                curAudioTrack = [audioTracks firstObject];
            }
        }
        {
            NSError * error = nil;
            [videoTrack insertTimeRange:CMTimeRangeMake(curItem.begin, duration)
                                ofTrack:curTrack
                                 atTime:modalInStInQueue
                                  error:&error];
            if(error)
            {
                NSLog(@"join video:(insert video) %@",[error localizedDescription]);
                return kCMTimeZero;
            }
            if(size && ((*size).width ==0 || (*size).height ==0 ))
            {
                *size = videoTrack.naturalSize;
                //            *size = [self getSizeByOrientation:videoTrack.naturalSize];
            }
            [videoTrack setPreferredTransform:curTrack.preferredTransform];
            NSLog(@"videoTrack\t\t:trans:%.1f-%.1f-%.1f-%.1f-----%.1f-%.1f",videoTrack.preferredTransform.a,videoTrack.preferredTransform.b,videoTrack.preferredTransform.c,videoTrack.preferredTransform.d,videoTrack.preferredTransform.tx,videoTrack.preferredTransform.ty);
        }
        if(curAudioTrack && audioTrack){
            NSError * error = nil;
            [audioTrack insertTimeRange:CMTimeRangeMake(curItem.begin, duration)
                                ofTrack:curAudioTrack
                                 atTime:modalInStInQueue
                                  error:&error];
            if(error)
            {
                NSLog(@"join video:(insert audio) error: %@",[error localizedDescription]);
                //                return kCMTimeZero;
            }
            if(hasAudioTrack)
                *hasAudioTrack = YES;
        }
        
        if((rate>0 && rate!=1.0)||(curItem.playRate!=1 && curItem.playRate>0))
        {
            CMTime durationScaled = CMTimeMake(duration.value/(rate * curItem.playRate), duration.timescale);
            
            [videoTrack scaleTimeRange:CMTimeRangeMake(modalInStInQueue, duration)
                            toDuration:durationScaled];
            
            if(curAudioTrack && audioTrack)
            {
                [audioTrack scaleTimeRange:CMTimeRangeMake(modalInStInQueue, duration)
                                toDuration:durationScaled];
            }
        }
        //        NSLog(@"track range2 :%.2f",CMTimeGetSeconds(videoTrack.timeRange.duration));
        //        if((self.orientation>0 && self.orientation <= UIDeviceOrientationFaceUp ) || self.useFontCamera)
        //        {
        //            [videoLayerInstruction setTransform:[self layerTrans:curAsset withTargetSize:self.renderSize orientation:self.orientation withFontCamera:self.useFontCamera isCreateByCover:NO]
        //                                         atTime:curItem.timeInArray];
        //        }
        //        else
        //        {
        //            [videoLayerInstruction setTransform:[self layerTrans:curAsset withTargetSize:self.renderSize] atTime:curItem.timeInArray];
        //        }
        
        //        [videoLayerInstruction setTransform:curTrack.preferredTransform  atTime:curItem.timeInArray];
        
        [videoLayerInstruction setOpacity:1.0 atTime:modalInStInQueue];
        [videoLayerInstruction setOpacity:0.0 atTime:modalOffEtInQueue];
    }
    
    return modalOffEtInQueue;
}
//此函数暂时未用
- (BOOL)compositeOneAudioItem:(MediaItem *)curAudioItem composition:(AVMutableComposition*)composition audioMixParams:(NSMutableArray *) audioMixParams audioTimeScale:(CMTimeScale)audioTimeScale
{
    NSURL * curAdudioUrl = [NSURL fileURLWithPath:curAudioItem.filePath];
    AVURLAsset * curAsset = [[AVURLAsset alloc]initWithURL:curAdudioUrl options:nil];
    //    if(curAsset.duration.value==0 ||curAsset.duration.timescale < 1000)
    //    {
    //        NSLog(@"joinaudio:(%d) skip:(%.2f-- %.2f) intrack:(%.2f---%.2f)(%d)",i,curAudioItem.secondsInArray,curAudioItem.secondsDurationInArray,curAudioItem.secondsBegin,curAudioItem.secondsEnd,curAsset.duration.timescale);
    //        CMTimeValue curEnd = (curAudioItem.secondsInArray + curAudioItem.secondsDurationInArray) * defaultAudioScale_;
    //        if(curEnd> lastTimeValue)
    //            lastTimeValue = curEnd;
    //        continue;
    //    }
    
    NSLog(@"%ld,%ld",(long)curAsset.duration.timescale,(long)curAsset.duration.value);
    UInt32 curAudioTimescale =  curAsset.duration.timescale;
    if(curAudioTimescale>0 && curAudioTimescale>audioTimeScale) //需要统一码流
    {
        audioTimeScale = curAudioTimescale;
    }
    //        CMTime stInQ = CMTimeMakeWithSeconds(curAudioItem.secondsInArray, curAudioTimescale);
    //        CMTime edInQ = CMTimeMakeWithSeconds(curAudioItem.secondsInArray + curAudioItem.secondsDurationInArray, curAudioTimescale);
    
    
    CMTime stInQ = CMTimeMakeWithSeconds(curAudioItem.secondsInArray, audioTimeScale);
    CMTime edInQ = CMTimeMakeWithSeconds(curAudioItem.secondsInArray + curAudioItem.secondsDurationInArray, audioTimeScale);
    
    //    //接好
    //    edInQ.value = edInQ.value + lastTimeValue - stInQ.value;
    //    stInQ.value = lastTimeValue;
    //    lastTimeValue = edInQ.value;
    
    
    CMTime beginInFile = CMTimeMakeWithSeconds(curAudioItem.secondsBegin, audioTimeScale);
    CMTime durationInFile = CMTimeMakeWithSeconds(curAudioItem.secondsDurationInArray, audioTimeScale);
    //    NSLog(@"joinaudio:(%d) timeline:(%.2f-- %.2f) intrack:(%.2f---%.2f)(%d)",i,curAudioItem.secondsInArray,curAudioItem.secondsDurationInArray,curAudioItem.secondsBegin,curAudioItem.secondsEnd,(unsigned int)curAudioTimescale);
    
    //构建参数
    AVMutableCompositionTrack *curTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                   preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableAudioMixInputParameters *curTrackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:curTrack];
    NSError * error = nil;
    if(![curTrack insertTimeRange:CMTimeRangeMake(beginInFile, durationInFile)
                          ofTrack:[[curAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                           atTime:stInQ
                            error:&error])
    {
        NSLog(@"join audio failure:%@",[error localizedDescription]);
    }
    
    [audioMixParams addObject:curTrackMix];
    return YES;
}
- (CMTime )compositeBGVideo:(AVMutableComposition *)mixComposition layers:(NSMutableArray *)layers maxTime:(CMTime)curTimeCnt size:(CGSize *)size rate:(CGFloat)rate
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
            if(size && ((*size).width ==0 || (*size).height ==0 ))
            {
                *size = ((AVAssetTrack *)[tracklist objectAtIndex:0]).naturalSize;
                //                *size = [self getSizeByOrientation:((AVAssetTrack *)[tracklist objectAtIndex:0]).naturalSize];
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
                CGAffineTransform trans = [self layerTrans:bgvAsset withTargetSize: *size orientation:self.orientation withFontCamera:self.useFontCamera isCreateByCover:isGenerateByCover];
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
                [bgvLayerInstruction setTransform:[self layerTrans:bgvAsset withTargetSize: *size] atTime:kCMTimeZero];
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
    BOOL isCapture =  !bgvUrl
    || [[[HCFileManager manager] getFileName:[bgvUrl path]] hasPrefix:[udManager_ localFileDir]]
    ?NO:YES;
    
    //混合背景音乐
    if((bgmAsset && justUseBgAudio==1) || isCapture)
    {
        AVMutableAudioMixInputParameters * trackMix =
        [self addAudioTrackWithUrl:bgmAsset.URL
                         composite:mixComposition
                           maxTime:curTimeCnt
                              rate:rate
            needScaleIfRateNotZero:!useAudioInVideo && self.bgAudioCanScale
                               vol:(hasAudioJoined?bgAudioVolume_:1)];
        if(trackMix)
            [audioMixParams addObject:trackMix];
    }
    
    if(justUseBgAudio==0 && hasAudioJoined)
    {
        AVMutableAudioMixInputParameters * trackMix =
        [self addAudioTrackWithUrl:joinAudioUrl
                         composite:mixComposition
                           maxTime:curTimeCnt
                              rate:rate
            needScaleIfRateNotZero:YES && self.bgAudioCanScale
                               vol:(!bgmAsset)?1:singVolume_];
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
        if(CMTimeGetSeconds(duration)>CMTimeGetSeconds(curTimeCnt))
        {
            duration = CMTimeMakeWithSeconds(CMTimeGetSeconds(curTimeCnt), duration.timescale);
        }
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
            if((rate >=1.01 && rate <= 10) || (rate >=0.1 && rate <=0.99))//限制范围
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
    NSLog(@"join video:(bg audio) %ld/%d (%ld)",(long)duration.value,(int)bgScale,(long)duration.timescale);
    
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
    isGenerating_ = NO;
    if(timerForExport_)
    {
        [timerForExport_ invalidate];
        PP_RELEASE(timerForExport_);
    }
    
    if(joinVideoExporter)
        [joinVideoExporter cancelExport];
    PP_RELEASE(joinVideoExporter);
    if(currentReverseSession_)
    {
        [currentReverseSession_ cancelReverse];
    }
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
- (void) setBlock:(MEProgress)progress
            ready:(MEPlayerItemReady)itemReady
        completed:(MECompleted)complted
          failure:(MEFailure)failure
{
    progressBlock_ = progress;
    itemReadyBlock_ = itemReady;
    completedBlock_ = complted;
    failureBlock_ = failure;
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
            [[HCFileManager manager] removeFileAtPath:[HCFileManager checkPath:path]];
    }
    if(joinVideoUrl)
    {
        [[HCFileManager manager] removeFileAtPath:[HCFileManager checkPath:joinVideoUrl.absoluteString]];
    }
}
- (void)clear
{
    if(timerForExport_)
    {
        timerForExport_.fireDate = [NSDate distantFuture];
        [timerForExport_ invalidate];
        PP_RELEASE(timerForExport_);
    }
    
    isGenerating_ = NO;
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
- (void) showMediaInfo:(NSString *)filePath
{
    if(!filePath || ![[HCFileManager manager]existFileAtPath:filePath])
    {
        NSLog(@" not find file:%@",filePath);
        return ;
    }
    AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:filePath]];
    CGAffineTransform transAsset = asset.preferredTransform;
    AVAssetTrack * track = [[asset tracksWithMediaType:AVMediaTypeVideo]firstObject];
    CGSize size = track.naturalSize;
    CGAffineTransform transTrack = track.preferredTransform;
    NSLog(@"asset\t\t:%@",filePath);
    NSLog(@"asset\t\t:trans:%.1f-%.1f-%.1f-%.1f-----%.1f-%.1f",transAsset.a,transAsset.b,transAsset.c,transAsset.d,transAsset.tx,transAsset.ty);
    NSLog(@"asset\t\t:trans:%.1f-%.1f-%.1f-%.1f-----%.1f-%.1f",transTrack.a,transTrack.b,transTrack.c,transTrack.d,transTrack.tx,transTrack.ty);
    NSLog(@"asset\t\t:size:%@",NSStringFromCGSize(size));
    NSLog(@"asset\t\t-------- end -------------");
    
    asset = nil;
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

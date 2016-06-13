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
#ifndef __OPTIMIZE__
    NSMutableArray * mediaTrackList_;
#endif
}
@end
@implementation VideoGenerater
{
    dispatch_queue_t    _dispatchJoinVideo;
    
    AVMutableVideoComposition * _videoComposition;
    AVMutableComposition * _mixComposition;
    AVMutableAudioMix * _audioMixOnce;
    NSTimer * timerForExport_;
    NSTimer * timerForReverseExport_;
    
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
@synthesize bitRate = bitRate_;
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
    
    bitRate_ = (long)(540 *960 * 10);
    //    defaultAudioScale_ = 44100;
    
    udManager_ = [UDManager sharedUDManager];
    DeviceConfig * config = [DeviceConfig config];
    _volRampSeconds = 0;
    _waterMarkerPosition = MP_RightTop;
    if(config.Height < 500)
    {
        [self setRenderSize:CGSizeMake(config.Height * config.Scale, config.Width * config.Scale) orientation:self.orientation withFontCamera:self.useFontCamera];
        //        self.renderSize = CGSizeMake(config.Height * config.Scale, config.Width * config.Scale);
    }
    else
    {
        [self setRenderSize:CGSizeMake(540, 960) orientation:UIInterfaceOrientationPortrait withFontCamera:self.useFontCamera];
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
    _waterMarkerPosition = MP_RightTop;
    //    [chooseQueue removeAllObjects];
}
- (void)setRenderSize:(CGSize)size orientation:(int)orient withFontCamera:(BOOL)useFontCamera
{
    if(orient>=0)
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
    if(self.orientation<=0) return size;
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
- (void)setBgmUrl:(NSURL *)bgmUrlA
{
    bgmUrl = bgmUrlA;
    _bgAudio = nil;
    if(bgmUrl)
    {
        AVURLAsset * asset = [AVURLAsset assetWithURL:bgmUrl];
        if(asset)
        {
            _bgAudio = [[MediaItem alloc]init];
            _bgAudio.url = bgmUrl;
            _bgAudio.fileName = [bgmUrl path];
            _bgAudio.duration = asset.duration;
            _bgAudio.begin = CMTimeMakeWithSeconds(0, _bgAudio.duration.timescale);
            _bgAudio.end = asset.duration;
            _bgAudio.timeInArray = kCMTimeZero;
        }
    }
}
- (void)setBgAudio:(MediaItem *)bgAudio
{
    _bgAudio = bgAudio;
    if(_bgAudio)
    {
        if(_bgAudio.url)
        {
            bgmUrl = _bgAudio.url;
        }
        else if(_bgAudio.fileName)
        {
            bgmUrl = [NSURL fileURLWithPath:_bgAudio.filePath];
        }
    }
}
#pragma mark - join
#pragma mark - join audio and mv
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
}
- (BOOL) canMerge
{
    if(_videoComposition && _mixComposition && previewAVassetIsReady)
    {
        return YES;
    }
    return NO;
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
#ifndef __OPTIMIZE__
    PP_RELEASE(mediaTrackList_);
#endif
    [self cancelExporter];
    if(timerForExport_)
    {
        timerForExport_.fireDate = [NSDate distantFuture];
        [timerForExport_ invalidate];
        PP_RELEASE(timerForExport_);
    }
    if(timerForReverseExport_)
    {
        timerForReverseExport_.fireDate = [NSDate distantFuture];
        [timerForReverseExport_ invalidate];
        PP_RELEASE(timerForReverseExport_);
    }
    _waterMarkerPosition = MP_RightTop;
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

-(BOOL)generateMVFile:(NSArray *)mediaList retryCount:(int)retryCount
{
    if (!previewAVassetIsReady) {
        [self generatePreviewAVasset:mediaList checked:NO completion:nil];
        return NO;
    }
    else if(!_videoComposition)
    {
        [self generatePlayerItem:mediaList size:self.renderSize];
        return NO;
    }
    
    return [self generateMVFile:_videoComposition
                       composte:_mixComposition
                       audioMix:_audioMixOnce
                          range:joinTimeRange_
                     retryCount:retryCount];
}
-(BOOL)generateMVFile:(AVMutableVideoComposition *) videoComposition
             composte:(AVMutableComposition *) mixComposition
             audioMix:(AVMutableAudioMix *) audioMixOnce
                range:(CMTimeRange) joinTimeRange
           retryCount:(int)retryCount

{
    
    NSURL * pathForFinalVideo = [self finalVideoUrl];
    
    joinVideoExporter = [SDAVAssetExportSession exportSessionWithAsset:_mixComposition];
    joinVideoExporter.outputURL = pathForFinalVideo;
    
    [[HCFileManager manager]removeFileAtPath:[pathForFinalVideo path]];
    
    joinVideoExporter.outputFileType = AVFileTypeMPEG4;
    
    joinVideoExporter.shouldOptimizeForNetworkUse = YES;
    joinVideoExporter.videoComposition = videoComposition;
    joinVideoExporter.audioMix = audioMixOnce;
    
    if(joinTimeRange.duration.value>0)
        joinVideoExporter.timeRange = joinTimeRange;
    
    CGSize renderSize = videoComposition.renderSize;// [self getRenderSize];
    if(renderSize.width==0||renderSize.height==0)
    {
        renderSize = [self getRenderSize];
    }
    NSNumber *width =  [NSNumber numberWithFloat:renderSize.width];
    NSNumber *height=  [NSNumber numberWithFloat:renderSize.height];
    
    NSNumber * bitRate = [NSNumber numberWithInt:(int)bitRate_];
    joinVideoExporter.videoSettings= @{
                                       AVVideoCodecKey: AVVideoCodecH264,
                                       AVVideoWidthKey: width,
                                       AVVideoHeightKey: height,
                                       AVVideoCompressionPropertiesKey: @
                                           {
                                           AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                                           AVVideoAverageBitRateKey:bitRate,
                                           AVVideoMaxKeyFrameIntervalKey:@(30)
                                               //                                          AVVideoProfileLevelKey: AVVideoProfileLevelH264Baseline30,
                                           },
                                       };
    
    joinVideoExporter.audioSettings = @{
                                        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                                        AVNumberOfChannelsKey: @2,
                                        AVSampleRateKey: @44100,
                                        AVEncoderBitRateKey: @160000,
                                        };
    
    
    if (mixComposition && videoComposition) {
        
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
#pragma mark - 从视频中截取一部分
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
    
    __weak VideoGenerater * weakSelf = self;
    
    return [gen generateAudioWithAccompany:audios
                                  filePath:tempPath
                              beginSeconds:CMTimeGetSeconds(totalBeginTime_)
                                endSeconds:CMTimeGetSeconds(totalEndTime_)
                                 overwrite:YES
                                 completed:^(NSURL *audioUrl, NSError *error) {
                                     __strong VideoGenerater * strongSelf = weakSelf;
                                     [strongSelf setJoinAudioUrlWithDraft:audioUrl];
                                     
                                     [strongSelf generatePreviewAsset:mediaList bgVolume:bgAudioVolume_ singVolume:singVolume_ completion:^(BOOL finished)
                                      {
                                          //                                          [self generatePlayerItem:mediaList size:self.renderSize];
                                          [self generateMVFile:mediaList retryCount:0]; // bgAudioVolume:bgAudioVolume_ singVolume:singVolume_];
                                      }];
                                 }];
}

//根据素材信息，构建预监的PlayerItem，并且为合成文件作准备
-(void) generatePlayerItem:(NSArray *)mediaList size:(CGSize)size
{
    if(isGenerating_)
    {
        NSLog(@"AG : 正在生成过程中，不能重入....");
        return;
    }
#ifndef __OPTIMIZE__
    mediaTrackList_ = [NSMutableArray new];
#endif
    isGenerating_ = YES;
    //将传入的Size进行方向上纠正
//    size = [self getSizeByOrientation:size];
//    size = CGSizeMake(540, 960);
    CGSize natureSize = CGSizeZero;
    BOOL isOverlap = YES; //在背景视频上添加视频，素材不需要是相联的
    //注意此处需要处理是否根据一张图和一个音乐来合成视频。现在的检查不支持这种情况
    CMTime totalDuration = bgvUrl?[self getTotalDuration:bgvUrl]:kCMTimeZero;
    
    PP_RELEASE(_mixComposition);
    PP_RELEASE(_videoComposition);
    PP_RELEASE(_audioMixOnce);
    
    //    size = CGSizeZero;
    
    //没有背景视频，则设置几个参数，并且重新根据素材总长获取合成后的总长度
    if(totalDuration.value ==0)
    {
        isOverlap = NO; //多个视频分段相加
        totalDuration = [self getTotalDurationByList:mediaList];
    }
    NSLog(@"AG : 合成总长%.2f",CMTimeGetSeconds(totalDuration));
    
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
    
    
    //逐段处理素材
    //如果没有背景视频，素材则是自动联接在一起，不能重叠也不能分开
    //如果有背景视频，则素材是贴在背景视频的不同的位置，素材可能重叠也可能分开
    if (mediaList && mediaList.count>0) {
        //图片生成的视频轨
        AVMutableCompositionTrack * imageTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                             preferredTrackID:kCMPersistentTrackID_Invalid];
        //视频轨
        AVMutableCompositionTrack * videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                             preferredTrackID:kCMPersistentTrackID_Invalid];
        //音频轨
        AVMutableCompositionTrack * audioTrack = nil;
        
        //假定不需要素材中的音频
        BOOL needAudioTrack = NO;
        
        //检查当前素材中是否有音频信息
        AVAsset * testAsset = [self getVideoItemAsset:[mediaList objectAtIndex:0]];
        NSArray * testTracks = [testAsset tracksWithMediaType:AVMediaTypeAudio];
        if(testTracks.count>0)
            needAudioTrack = YES;
        
        //如果没有背景视频，并且素材中声音不被禁止，则需要初始化音频轨
        if(!bgvUrl && singVolume_>0 && needAudioTrack)
        {
            audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                     preferredTrackID:kCMPersistentTrackID_Invalid];
        }
        
        //初始化层相关的信息
        AVMutableVideoCompositionLayerInstruction *imageLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:imageTrack];
        AVMutableVideoCompositionLayerInstruction *videoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        
        //图片与视频轨的计数
        NSInteger imageCnt = 0;
        NSInteger videoCnt = 0;
        //前一段素材的最后位置，也是下一段素材的开始位置(当相联时）
        //如果素材重叠，而且没有放到不同的层中，可能导致合成失败
        CMTimeValue lastTimeValue = 0;
        BOOL hasAudioTrack = NO;
        
        //逐段处理素材
        for (int i = 0 ; i < mediaList.count ; i ++ ) {
            MediaItem * curItem = [mediaList objectAtIndex:i];
            
            if(curItem.secondsDurationInArray <=0.001) continue;
            
            //如果没有背景视频，则素材需要紧接在一起
            if(!isOverlap)
            {
                curItem.timeInArray = CMTimeMake(lastTimeValue, totalDuration.timescale);
            }
            
            //合成一段素材，并且获得素材结束的时间
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
                                                        size:size
                                                  natureSize:&natureSize
                                               hasAudioTrack:&hasAudioTrack];
            
            if(CMTimeCompare(modalOffEtInQueue, kCMTimeZero)==0) continue;
            
            if(curItem.originType == MediaItemTypeIMAGE)
                imageCnt ++;
            else
                videoCnt ++;
            
            if (CMTimeGetSeconds(modalOffEtInQueue) > CMTimeGetSeconds(curTimeCnt) ) {
                curTimeCnt = modalOffEtInQueue;
            }
            
            NSLog(@"index %d total duration:%.2f,this (%.2f-->%.2f)(%.2f) rate:%.2f",
                  i,
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
        
        //如果有声音，加上声音。如果没有声音，加上声音会导致合成时报:最后帧时间错误
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
    
    //合成背景视频，如果没有，则不合成
    if(isOverlap)
    {
        curTimeCnt = [self compositeBGVideo:mixComposition layers:layers maxTime:curTimeCnt size:&size rate:rate];
        range = CMTimeRangeMake(kCMTimeZero,curTimeCnt);
    }
    
    NSLog(@"track range :%.2f",CMTimeGetSeconds(range.duration));
    
    
    //背景音频混入
    if(bgmUrl || bgvUrl || joinAudioUrl)
    {
        NSMutableArray * audioParamters = [self compositeAudioArray:mixComposition maxTime:curTimeCnt rate:rate];
        [audioMixParams addObjectsFromArray:audioParamters];
    }
    
    joinTimeRange_ = range;
    //    size = natureSize;
    //        size = [self scaleSize:natureSize WithTarget:size];
    
    size = [self getSize:size withMedialList:mediaList];
    
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
    CMTime lyricDuration = curTimeCnt;
    if(rate!=1)
    {
        lyricDuration.value *= rate;
    }
    
    mainComposition.animationTool = [self compositeTitleAndLyric:nil duration:lyricDuration size:size rate:rate];
    
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
- (CGSize) getSize:(CGSize)size withMedialList:(NSArray *)mediaList
{
    AVAssetTrack * sourceTrack = nil;
    if(bgvUrl)
    {
        AVURLAsset * asset = [AVURLAsset assetWithURL:bgvUrl];
        if(asset && [asset tracksWithMediaType:AVMediaTypeVideo].count>0)
        {
            sourceTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]firstObject];
        }
    }
    if(!sourceTrack && mediaList.count>0)
    {
        MediaItem * item = [mediaList firstObject];
        
        AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:item.filePath]];
        if(asset && [asset tracksWithMediaType:AVMediaTypeVideo].count>0)
        {
            sourceTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]firstObject];
        }
    }
    CGSize natureSize = sourceTrack.naturalSize;
    int degree = [self degressFromVideoFileWithTrack:sourceTrack];
    //将Size的方向转成一致，因为Nature默认是横屏，因此Size也要默认转成横屏
    switch (degree) {
        case 90:
        case 270:
//            if(self.orientation>=0 && UIInterfaceOrientationIsPortrait(self.orientation))
            if(natureSize.width < natureSize.height)
                natureSize = CGSizeMake(natureSize.height, natureSize.width);
            if(size.width < size.height)
                size = CGSizeMake(size.height, size.width);
            break;
        default:
//            if(self.orientation>=0 && UIInterfaceOrientationIsLandscape(self.orientation))
            if(natureSize.width < natureSize.height)
                natureSize = CGSizeMake(natureSize.height, natureSize.width);
            if(size.width < size.height)
                size = CGSizeMake(size.height, size.width);
            break;
    }
    CGFloat rate1 = natureSize.width /natureSize.height;
    CGFloat rate2 = size.width / size.height;
    if(rate1>=rate2)
    {
        return CGSizeMake(size.width, size.width / rate1);
    }
    else
    {
        return CGSizeMake(size.height * rate1, size.height);
    }
}
- (CGFloat) getRate:(CGSize)size widthTrack:(AVAssetTrack *)sourceTrack
{
    if(!sourceTrack) return 1;
    CGSize natureSize = sourceTrack.naturalSize;
    int degree = [self degressFromVideoFileWithTrack:sourceTrack];
    //将Size的方向转成一致，因为Nature默认是横屏，因此Size也要默认转成横屏
    switch (degree) {
        case 90:
        case 270:
            //            if(self.orientation>=0 && UIInterfaceOrientationIsPortrait(self.orientation))
            if(natureSize.width < natureSize.height)
                natureSize = CGSizeMake(natureSize.height, natureSize.width);
            if(size.width < size.height)
                size = CGSizeMake(size.height, size.width);
            break;
        default:
            //            if(self.orientation>=0 && UIInterfaceOrientationIsLandscape(self.orientation))
            if(natureSize.width < natureSize.height)
                natureSize = CGSizeMake(natureSize.height, natureSize.width);
            if(size.width < size.height)
                size = CGSizeMake(size.height, size.width);
            break;
    }
    CGFloat rate1 = natureSize.width /natureSize.height;
    CGFloat rate2 = size.width / size.height;
    if(rate1>=rate2)
    {
        return size.width/natureSize.width;
    }
    else
    {
        return size.height / natureSize.height;
    }
}
////将Size最大可能地进行匹配
//- (CGSize)scaleSize:(CGSize)natureSize WithTarget:(CGSize)targetSize
//{
//    if(natureSize.width >0&&natureSize.height >0 && targetSize.width>0 && targetSize.height>0)
//    {
//        CGFloat rate1 = natureSize.width /natureSize.height;
//        CGFloat rate2 = targetSize.width / targetSize.height;
//        if(rate1 >=1 && rate2>=1)
//        {
//            if(rate1>=rate2)
//            {
//                return CGSizeMake(targetSize.width, targetSize.width / rate1);
//            }
//            else
//            {
//                return CGSizeMake(targetSize.height * rate1, targetSize.height);
//            }
//        }
//        else
//        {
//            if(rate1>=rate2)
//            {
//                return CGSizeMake(targetSize.height * rate1, targetSize.height);
//            }
//            else
//            {
//                return CGSizeMake(targetSize.width, targetSize.width / rate1);
//            }
//        }
//
//    }
//    else if(natureSize.width>0 && natureSize.height >0)
//    {
//        return natureSize;
//    }
//    else
//    {
//        return targetSize;
//    }
//}
//- (CGFloat)scaleRateSize:(CGSize)natureSize withTargetSize:(CGSize)targetSize
//{
//    if(natureSize.width >0&&natureSize.height >0 && targetSize.width>0 && targetSize.height>0)
//    {
//        CGFloat rate1 = natureSize.width /natureSize.height;
//        CGFloat rate2 = targetSize.width / targetSize.height;
//        if(rate1 >=1 && rate2>=1)
//        {
//            if(rate1>=rate2)
//            {
//                return targetSize.width/natureSize.width;
//            }
//            else
//            {
//                return targetSize.height /natureSize.height;
//            }
//        }
//        else
//        {
//            if(rate1>=rate2)
//            {
//                return targetSize.width /natureSize.height;
//            }
//            else
//            {
//                return targetSize.height/natureSize.width;
//            }
//        }
//
//    }
//    else if(natureSize.width>0 && natureSize.height >0)
//    {
//        return 1;
//    }
//    else
//    {
//        return 1;
//    }
//}
//- (void) generatePlayItemNew
//{
//    AVAsset * videoAsset = [AVURLAsset assetWithURL:self.bgvUrl];
//
//    // 2 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
//    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
//
//    // 3 - Video track
//    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
//                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
//    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
//                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
//                         atTime:kCMTimeZero error:nil];
//
//    // 3.1 - Create AVMutableVideoCompositionInstruction
//    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
//
//    // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
//    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
//    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//    UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
//    BOOL isVideoAssetPortrait_  = NO;
//    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
//    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
//        videoAssetOrientation_ = UIImageOrientationRight;
//        isVideoAssetPortrait_ = YES;
//    }
//    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
//        videoAssetOrientation_ =  UIImageOrientationLeft;
//        isVideoAssetPortrait_ = YES;
//    }
//    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
//        videoAssetOrientation_ =  UIImageOrientationUp;
//    }
//    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
//        videoAssetOrientation_ = UIImageOrientationDown;
//    }
//    [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
//    [videolayerInstruction setOpacity:0.0 atTime:videoAsset.duration];
//
//    // 3.3 - Add instructions
//    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
//
//    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
//
//    CGSize naturalSize;
//    if(isVideoAssetPortrait_){
//        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
//    } else {
//        naturalSize = videoAssetTrack.naturalSize;
//    }
//
//    float renderWidth, renderHeight;
//    renderWidth = naturalSize.width;
//    renderHeight = naturalSize.height;
//
//    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
//    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
//    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
//
//    //    [self applyVideoEffectsToComposition:mainCompositionInst size:naturalSize];
//    mainCompositionInst.animationTool = [self compositeTitleAndLyric:nil duration:videoAsset.duration size:naturalSize rate:1];
//
//    _mixComposition = PP_RETAIN((AVMutableComposition*)mixComposition);
//    _videoComposition = PP_RETAIN((AVMutableVideoComposition*)mainCompositionInst);
//    _audioMixOnce = nil;
//
//    previewAVassetIsReady = YES;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(sendPlayerItemToFront:) userInfo:nil repeats:NO];
//    });
//
//}
//- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size
//{
//    UIImage *borderImage = nil;
//
//
//    borderImage = [self imageWithColor:[UIColor blueColor] rectSize:CGRectMake(0, 0, size.width, size.height)];
//
//
//    CALayer *backgroundLayer = [CALayer layer];
//    [backgroundLayer setContents:(id)[borderImage CGImage]];
//    backgroundLayer.frame = CGRectMake(0, 0, size.width, size.height);
//    [backgroundLayer setMasksToBounds:YES];
//
//    CALayer *videoLayer = [CALayer layer];
//    videoLayer.frame = CGRectMake(40, 40,
//                                  size.width-(40*2), size.height-(40*2));
//    CALayer *parentLayer = [CALayer layer];
//    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
//    [parentLayer addSublayer:backgroundLayer];
//    [parentLayer addSublayer:videoLayer];
//
//    composition.animationTool = [AVVideoCompositionCoreAnimationTool
//                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
//}
#pragma mark - 生成反向视频
- (BOOL)generateMVReverse:(NSString *)sourcePath
                   target:(NSString *)targetPath
                    begin:(CGFloat)sourceBegin
                      end:(CGFloat)sourceEnd
                audioFile:(NSString *)audioFilePath
               audioBegin:(CGFloat)audioBegin
                 complted:(void (^)(NSString * filePath))complted
{
    if(![HCFileManager isExistsFile:sourcePath])
    {
        NSLog(@"AG : reverse source file not exists:%@",sourcePath);
        return NO;
    }
    if(!targetPath||targetPath.length<2)
    {
        NSLog(@"AG : reverse target file name is nil");
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
    CGFloat durationSeconds= CMTimeGetSeconds(asset.duration);
    if(sourceBegin<0) sourceBegin = 0;
    else if(sourceBegin > durationSeconds) sourceBegin = durationSeconds;
    
    if(sourceEnd > durationSeconds) sourceEnd = durationSeconds;
    else if(sourceEnd<0) sourceEnd = 0;
    
    durationSeconds = fabs(sourceEnd - sourceBegin);
    
    // 计算开始时间与结束时间
    if(durationSeconds>0)
    {
        if(sourceEnd>sourceBegin)
            [session setTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(sourceBegin, asset.duration.timescale), CMTimeMakeWithSeconds(durationSeconds, asset.duration.timescale))];
        else
            [session setTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(sourceEnd, asset.duration.timescale), CMTimeMakeWithSeconds(durationSeconds, asset.duration.timescale))];
    }
    NSLog(@"AG : 生成反向视频 %f->%f 时长:%f",sourceBegin,sourceEnd,durationSeconds);
    
    //小于最小值，倒放没有意义
    if(durationSeconds < 0.01)
    {
        currentReverseSession_ = nil;
        session = nil;
        return NO;
    }
    if(!timerForReverseExport_)
    {
        timerForReverseExport_ = PP_RETAIN([NSTimer timerWithTimeInterval:0.1
                                                                   target:self
                                                                 selector:@selector(checkReverseProgress:)
                                                                 userInfo:nil
                                                                  repeats:YES]);
        
        [[NSRunLoop mainRunLoop] addTimer:timerForReverseExport_ forMode:NSDefaultRunLoopMode];
    }
    timerForReverseExport_.fireDate = [NSDate distantPast];
    __weak VideoGenerater * weakSelf = self;
    [session reverseAsynchronouslyWithCompletionHandler:^{
        currentReverseSession_ = nil;
        timerForReverseExport_.fireDate = [NSDate distantFuture];
        if (session.status == AVAssetReverseSessionStatusCompleted) {
            NSURL *outputURL = session.outputURL;
            NSLog(@"AG : 反向视频完成:%@",[outputURL path]);
            if(audioFilePath && audioFilePath.length>0 && weakSelf)
            {
                __strong VideoGenerater * strongSelf = weakSelf;
                BOOL ret = [strongSelf combinateFileWithAudio:[outputURL path]
                                                audioFilePath:audioFilePath secondsBegin:audioBegin
                                                     complted:^(NSString *filePath) {
                                                         if(complted)
                                                         {
                                                             complted(filePath);
                                                         }
                                                     }];
                if(!ret && complted)
                {
                    complted(nil);
                }
            }
            else
            {
                if(complted)
                {
                    complted([outputURL path]);
                }
            }
        } else {
            
            NSLog(@"AG : 生成反向视频失败");
            if(complted)
            {
                complted(nil);
            }
        }
    }];
    return YES;
}
//合并视频
- (BOOL)combinateFileWithAudio:(NSString *)sourceFilePath
                 audioFilePath:(NSString *)audioFilePath
                  secondsBegin:(CGFloat)secondsBegin
                      complted:(void (^)(NSString * filePath))complted
{
    if(!sourceFilePath || !audioFilePath)
    {
        NSLog(@"file parameter cannot be nil;");
        if(complted)
        {
            complted(sourceFilePath);
        }
        return NO;
    }
    
    AVURLAsset * videoAsset = [[ AVURLAsset alloc ] initWithURL :[ NSURL fileURLWithPath:sourceFilePath] options : nil ];
    AVURLAsset * audioAsset =[[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:audioFilePath] options:nil];
    if([videoAsset tracksWithMediaType : AVMediaTypeVideo].count==0 ||
       [audioAsset tracksWithMediaType:AVMediaTypeAudio].count==0)
    {
        NSLog(@"AG : 文件中没有需要操作的数据");
        if(complted)
        {
            complted(sourceFilePath);
        }
        return NO;
    }
    CGFloat audioDurationSeconds = CMTimeGetSeconds(audioAsset.duration);
    
    if(secondsBegin<0 || secondsBegin >= audioDurationSeconds)
    {
        secondsBegin = 0;
    }
    CMTime audioBegin = CMTimeMakeWithSeconds(secondsBegin, audioAsset.duration.timescale);
    CMTime audioDuration = CMTimeMakeWithSeconds(MIN(audioDurationSeconds - secondsBegin,CMTimeGetSeconds(videoAsset.duration))
                                                 , audioAsset.duration.timescale);
    // 下面就是合成的过程了。
    
    AVMutableComposition * mixComposition = [ AVMutableComposition composition ];
    
    if(CMTimeGetSeconds(audioDuration)>0)
    {
        AVMutableCompositionTrack *compositionCommentaryTrack = [mixComposition addMutableTrackWithMediaType : AVMediaTypeAudio
                                                                                            preferredTrackID : kCMPersistentTrackID_Invalid ];
        [compositionCommentaryTrack insertTimeRange : CMTimeRangeMake(audioBegin,audioDuration)
                                            ofTrack :[[audioAsset tracksWithMediaType:AVMediaTypeAudio ] objectAtIndex:0]
                                             atTime : kCMTimeZero
                                              error : nil ];
    }
    {
        AVAssetTrack * curTrack = [[videoAsset tracksWithMediaType : AVMediaTypeVideo ] objectAtIndex:0];
        AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType : AVMediaTypeVideo
                                                                                       preferredTrackID : kCMPersistentTrackID_Invalid ];
        [compositionVideoTrack insertTimeRange :CMTimeRangeMake(kCMTimeZero , videoAsset. duration )
                                       ofTrack :curTrack
                                        atTime : kCMTimeZero
                                          error:nil ];
        
        [compositionVideoTrack setPreferredTransform:curTrack.preferredTransform];
    }
    AVAssetExportSession * assetExport = [[ AVAssetExportSession alloc ] initWithAsset :mixComposition
                                                                            presetName : AVAssetExportPresetPassthrough ];
    
    NSString *exportPath = [[HCFileManager manager]getFileNameByTicks:@"action_media.mp4"];
    exportPath = [[HCFileManager manager]tempFileFullPath:exportPath];
    
    if ([[ NSFileManager defaultManager ] fileExistsAtPath :exportPath])
        [[ NSFileManager defaultManager ] removeItemAtPath :exportPath error : nil ];
    
    assetExport.outputFileType = @"com.apple.quicktime-movie" ;
    assetExport.outputURL = [NSURL fileURLWithPath:exportPath];
    assetExport.shouldOptimizeForNetworkUse = YES ;
    
    // 下面是按照上面的要求合成视频的过程。
    [assetExport exportAsynchronouslyWithCompletionHandler :
     ^(void) {
         if(assetExport.status == AVAssetExportSessionStatusCompleted)
         {
#ifndef __OPTIMIZE__
             [self showMediaInfo:[assetExport.outputURL path]];
#endif
             if(complted)
             {
                 complted([assetExport.outputURL path]);
             }
         }
         else
         {
             NSLog(@"VG :export failure:%@",[assetExport.error localizedDescription]);
             if(complted)
             {
                 complted(sourceFilePath);
             }
         }
     }
     ];
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
        CGRect layerFrame = CGRectMake(0, 0, size.width, size.height);
        
        CALayer *parentLayer = [CALayer layer];
        parentLayer.frame = layerFrame;// CGRectMake(0, 0, size.width,size.height);
        
        CALayer *videoLayer = [CALayer layer];
        videoLayer.frame = layerFrame;// CGRectMake(0, 0, size.width,size.height);
        [parentLayer addSublayer:videoLayer];
        
        if(self.compositeLyric)
        {
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
        }
        if(self.waterMarkFile && self.waterMarkFile.length>2)
        {
            CALayer * wmLayer = [ImagesToVideo buildWaterMarkerLayer:self.waterMarkFile
                                                          renderSize:size
                                                         orientation:self.orientation
                                                            position:self.waterMarkerPosition];
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
        seconds += roundf(fabs(item.secondsDurationInArray/item.playRate) * 100)/100;
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

- (CMTime) compsiteOneItem:(MediaItem*)curItem
                     index:(int)index
             lastTimeValue:(CMTimeValue)lastTimeValue totalDuration:(CMTime)totalDuration
                imageTrack:(AVMutableCompositionTrack*)imageTrack
               imagelayers:(AVMutableVideoCompositionLayerInstruction*)imageLayerInstruction
                videoTrack:(AVMutableCompositionTrack*)videoTrack
               videoLayers:(AVMutableVideoCompositionLayerInstruction*)videoLayerInstruction
                audioTrack:(AVMutableCompositionTrack *)audioTrack
                      rate:(CGFloat)rate
                      size:(CGSize) size
                natureSize:(CGSize *)natureSize
             hasAudioTrack:(BOOL *) hasAudioTrack
{
#ifndef __OPTIMIZE__
    NSMutableDictionary * trackInfo = [NSMutableDictionary new];
    [trackInfo setObject:@(0) forKey:@"type"];
    [trackInfo setObject:@(trackInfo.count) forKey:@"index"];
    [trackInfo setObject:curItem.fileName forKey:@"filename"];
#endif
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
    else if(rate <0 && rate!=-1.0)
    {
        modalInStInQueue.value = round(0 - modalInStInQueue.value/rate +0.5);
        modalOffEtInQueue.value = round(0 - modalOffEtInQueue.value/rate + 0.5);
    }
    
    //单个对像处理
    if(curItem.playRate!=1 && curItem.playRate>0)
    {
        CMTime diff = CMTimeSubtract(modalOffEtInQueue, modalInStInQueue);
        modalOffEtInQueue.value = (CMTimeValue)(diff.value /curItem.playRate) + modalInStInQueue.value;
        //        modalOffEtInQueue.value = round(modalOffEtInQueue.value/curItem.playRate + 0.5);
    }
    else if(curItem.playRate!=-1 && curItem.playRate<0)
    {
        CMTime diff = CMTimeSubtract(modalOffEtInQueue, modalInStInQueue);
        modalOffEtInQueue.value = (CMTimeValue)(0 - diff.value /curItem.playRate) + modalInStInQueue.value;
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
        if(natureSize && ((*natureSize).width ==0 || (*natureSize).height ==0 ))
        {
            *natureSize = [self getSizeByOrientation:curItemSize];
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
#ifndef __OPTIMIZE__
            [trackInfo setObject:[NSNumber numberWithFloat:curItem.secondsBegin] forKey:@"beginInFile"];
            [trackInfo setObject:[NSNumber numberWithFloat:curItem.secondsEnd] forKey:@"endInFile"];
            [trackInfo setObject:[NSNumber numberWithFloat:CMTimeGetSeconds(duration)] forKey:@"secondsDurationInArray"];
            [trackInfo setObject:[NSNumber numberWithFloat:CMTimeGetSeconds(modalInStInQueue)] forKey:@"secondsInTrack"];
#endif
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
            if(natureSize && ((*natureSize).width ==0 || (*natureSize).height ==0 ))
            {
                *natureSize = curTrack.naturalSize;
            }
            if(size.width==0||size.height==0)
            {
                [videoTrack setPreferredTransform:curTrack.preferredTransform];
            }
            else
            {
                if(size.width != curTrack.naturalSize.width || size.height != curTrack.naturalSize.height)
                {
                    CGFloat scaleRate = [self getRate:size widthTrack:curTrack];
                    CGAffineTransform transfer = CGAffineTransformIdentity;
                    transfer = CGAffineTransformScale(transfer, scaleRate, scaleRate);
                    [videoLayerInstruction setTransform:transfer atTime:modalInStInQueue];
                }
                [videoTrack setPreferredTransform:curTrack.preferredTransform];
            }
            
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
                NSLog(@"AG : join video:(insert audio) error: %@",[error localizedDescription]);
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
#ifndef __OPTIMIZE__
            [trackInfo setObject:[NSNumber numberWithFloat:CMTimeGetSeconds(durationScaled)] forKey:@"scaleDuration"];
#endif
            if(curAudioTrack && audioTrack)
            {
                [audioTrack scaleTimeRange:CMTimeRangeMake(modalInStInQueue, duration)
                                toDuration:durationScaled];
            }
        }
        else if((rate>0 && rate!=1.0)||(curItem.playRate!=-1 && curItem.playRate<0))
        {
            CMTime durationScaled = CMTimeMake(duration.value/(0 - rate * curItem.playRate), duration.timescale);
            
            [videoTrack scaleTimeRange:CMTimeRangeMake(modalInStInQueue, duration)
                            toDuration:durationScaled];
#ifndef __OPTIMIZE__
            [trackInfo setObject:[NSNumber numberWithFloat:CMTimeGetSeconds(durationScaled)] forKey:@"scaleDuration"];
#endif
            if(curAudioTrack && audioTrack)
            {
                [audioTrack scaleTimeRange:CMTimeRangeMake(modalInStInQueue, duration)
                                toDuration:durationScaled];
            }
        }
        
        [videoLayerInstruction setOpacity:1.0 atTime:modalInStInQueue];
        [videoLayerInstruction setOpacity:0.0 atTime:modalOffEtInQueue];
#ifndef __OPTIMIZE__
        [trackInfo setObject:[NSNumber numberWithFloat:CMTimeGetSeconds(modalOffEtInQueue)] forKey:@"endInTrack"];
#endif
    }
#ifndef __OPTIMIZE__
    [mediaTrackList_ addObject:trackInfo];
#endif
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
    //    CMTime edInQ = CMTimeMakeWithSeconds(curAudioItem.secondsInArray + curAudioItem.secondsDurationInArray, audioTimeScale);
    
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
        AVMutableAudioMixInputParameters * trackMix = nil;
        //如果用背景音乐，而不是原视频中的音乐
        if(bgmUrl)
        {
            trackMix =
            [self addAudioTrackWithUrl:bgmAsset.URL
                             composite:mixComposition
                               maxTime:curTimeCnt
                                  rate:rate
                needScaleIfRateNotZero:!useAudioInVideo && self.bgAudioCanScale
                                   vol:(hasAudioJoined?bgAudioVolume_:1)
                           timeInArray:_bgAudio.timeInArray
                            mediaBegin:_bgAudio.begin
                              mediaEnd:_bgAudio.end
                        volRampSeconds:_volRampSeconds];
            
        }
        else
        {
            trackMix =
            [self addAudioTrackWithUrl:bgmAsset.URL
                             composite:mixComposition
                               maxTime:curTimeCnt
                                  rate:rate
                needScaleIfRateNotZero:!useAudioInVideo && self.bgAudioCanScale
                                   vol:(hasAudioJoined?bgAudioVolume_:1)
                           timeInArray:kCMTimeZero
                            mediaBegin:totalBeginTimeForAudio_
                              mediaEnd:totalEndTimeForAudio_
                        volRampSeconds:_volRampSeconds
             ];
            
        }
        
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
                               vol:(!bgmAsset)?1:singVolume_
                       timeInArray:kCMTimeZero
                        mediaBegin:totalBeginTimeForAudio_
                          mediaEnd:totalEndTimeForAudio_
                    volRampSeconds:_volRampSeconds];
        if(trackMix)
            [audioMixParams addObject:trackMix];
    }
    
    return audioMixParams;
}
- (AVMutableAudioMixInputParameters*)addAudioTrackWithUrl:(NSURL *)url
                                                composite:(AVMutableComposition *)mixComposition
                                                  maxTime:(CMTime)curTimeCnt
                                                     rate:(CGFloat)rate
                                   needScaleIfRateNotZero:(BOOL)needScale
                                                      vol:(CGFloat)vol
                                              timeInArray:(CMTime)timeInArray
                                               mediaBegin:(CMTime)mediaBegin //音乐在音乐素材中的开始时间，负值表示，不是从Track的0开始。
                                                 mediaEnd:(CMTime)mediaEnd //音乐在素材中的结束时间,kCMTimeZero表示为空
                                           volRampSeconds:(CGFloat)volRampSeconds //渐变音量的时间
{
    //将背景视频和背景音乐合成进去
#ifndef __OPTIMIZE__
    NSMutableDictionary * trackInfo = [NSMutableDictionary new];
#endif
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
    
    CMTime startTime = mediaBegin;
    CMTime duration =  asset.duration;
    
    //    CMTime timeInArray = CMTimeMake(0, bgScale);
    //因为背景音乐是完整的，所以如果截取一部分时，要注意重新定位开始的时间
    //    if(CMTimeCompare(mediaBegin,kCMTimeZero)>0.0001)
    //    {
    //        startTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(mediaBegin), bgScale);
    //    }
    //    else if(CMTimeCompare(mediaBegin,kCMTimeZero)<0.0001)  //不从开始的位置加音乐
    //    {
    //        timeInArray = CMTimeMakeWithSeconds(0 - CMTimeGetSeconds(mediaBegin), bgScale);
    //    }
    if(CMTimeCompare(mediaEnd, kCMTimeZero)>0)
    {
        duration = CMTimeMakeWithSeconds(CMTimeGetSeconds(mediaEnd) - CMTimeGetSeconds(mediaBegin), bgScale);
    }
    bgAudioTime = duration;
    
    //因为合成的音乐应该小于等于视频长度，否则会黑屏
    
    //使用视频中的原因，因此不需要处理
    if(!needScale)
    {
        if(CMTimeGetSeconds(duration)+CMTimeGetSeconds(timeInArray)>CMTimeGetSeconds(curTimeCnt))
        {
            duration = CMTimeMakeWithSeconds(MIN(CMTimeGetSeconds(curTimeCnt)-CMTimeGetSeconds(timeInArray),CMTimeGetSeconds(duration)), duration.timescale);
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
    
    
    if(CMTimeCompare(bgAudioTime,curTimeCnt)>0)
    {
        bgAudioTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(curTimeCnt), bgAudioTime.timescale);
        duration = bgAudioTime;
    }
    
    AVMutableCompositionTrack *track = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                   preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters
                                                  audioMixInputParametersWithTrack:track];
    
    if(volRampSeconds>0 && needScale)
    {
        //音量渐变大
        CMTime rampDuration = CMTimeMakeWithSeconds(volRampSeconds, bgScale);
        CMTime endRampTime = CMTimeSubtract(CMTimeAdd(timeInArray, duration), rampDuration);
        
        [trackMix setVolumeRampFromStartVolume:0 toEndVolume:vol
                                     timeRange:CMTimeRangeMake(timeInArray, rampDuration)];
        
        [trackMix setVolumeRampFromStartVolume:vol toEndVolume:0
                                     timeRange:CMTimeRangeMake(endRampTime, rampDuration)];
    }
    else
    {
        [trackMix setVolume:bgAudioVolume_ atTime:timeInArray];
    }
    NSError * error = nil;
    //默认视频长度大于音频长度
    [track insertTimeRange:CMTimeRangeMake(startTime, duration)
                   ofTrack:[trackList objectAtIndex:0]
                    atTime:timeInArray
                     error:&error];
    if(error)
    {
        NSLog(@"join video:(mix bgaudio) %@",[error localizedDescription]);
    }
#ifndef __OPTIMIZE__
    [trackInfo setObject:@(1) forKey:@"type"];
    [trackInfo setObject:@(mediaTrackList_.count) forKey:@"index"];
    [trackInfo setObject:[[url absoluteString]lastPathComponent] forKey:@"filename"];
    [trackInfo setObject:[NSNumber numberWithFloat:CMTimeGetSeconds(startTime)] forKey:@"beginInFile"];
    [trackInfo setObject:[NSNumber numberWithFloat:0] forKey:@"secondsInTrack"];
#endif
    NSLog(@"join video:(bg audio) %ld/%d (%ld)",(long)duration.value,(int)bgScale,(long)duration.timescale);
    
    if(rate >0 && rate!=1.0)
    {
        [track scaleTimeRange:CMTimeRangeMake(timeInArray, duration)
                   toDuration:CMTimeMake(duration.value/rate, duration.timescale)];
        duration.value /= rate;
        NSLog(@"scale audio  to %f",CMTimeGetSeconds(duration));
#ifndef __OPTIMIZE__
        [trackInfo setObject:[NSNumber numberWithFloat:CMTimeGetSeconds(duration)] forKey:@"scaleDuration"];
#endif
    }
#ifndef __OPTIMIZE__
    [mediaTrackList_ addObject:trackInfo];
#endif
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
//将所有的方向转成标准方向，即角度为0
-(CGAffineTransform)layerTransfterWithTrack:(AVAssetTrack *)track
                             withTargetSize:(CGSize)targetSize
                               outputDegree:(int)outputDegreen
{
    CGSize natureSize = track.naturalSize;
    CGSize renderSize = CGSizeZero;
    
    float scale  = 1;
    int degree = [self degressFromVideoFileWithTrack:track];
    
    
    CGFloat rate1 = targetSize.width/targetSize.height;
    CGFloat rate2 = natureSize.width/natureSize.height;
    if((rate2>=1 && rate1 >=1) ||(rate2<=1 && rate1<=1))
    {
        scale  = MIN(targetSize.width/natureSize.width , targetSize.height/natureSize.height);
    }
    else
    {
        scale  = MIN(targetSize.width/natureSize.height , targetSize.height/natureSize.width);
    }
    
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    if(scale!=1)
    {
        transform = CGAffineTransformScale(transform, scale, scale);
    }
    switch (degree) {
        case 0:
        {
            renderSize = CGSizeMake(targetSize.height, targetSize.width);
            CGAffineTransform CGAffineTransform = CGAffineTransformIdentity;
            transform = CGAffineTransformConcat(transform, CGAffineTransform);
        }
            break;
        case 180:
        {
            renderSize = CGSizeMake(targetSize.height, targetSize.width);
            CGAffineTransform videoTransform = CGAffineTransformMakeRotation( M_PI * 180 / 180);
            transform = CGAffineTransformConcat(transform, videoTransform);
            transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(renderSize.height, renderSize.width));
        }
            break;
        case 270:
        {
            CGAffineTransform videoTransform = CGAffineTransformMakeRotation(  M_PI * 270 / 180);
            transform = CGAffineTransformConcat(transform, videoTransform);
            transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(0, renderSize.height));
        }
            break;
        default:
        {
            CGAffineTransform videoTransform = CGAffineTransformMakeRotation(- M_PI * 90 / 180);
            transform = CGAffineTransformConcat(transform, videoTransform);
            transform = CGAffineTransformMakeTranslation(0 - renderSize.width, renderSize.height);
            //            transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(renderSize.width, 0-renderSize.width));
            
            break;
        }
    }
    return transform;
}
- (int)degressFromVideoFileWithTrack:(AVAssetTrack *)videoTrack
{
    int degress = -1;
    if(videoTrack)
    {
        CGAffineTransform t = videoTrack.preferredTransform;
        
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 90;
        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 270;
        }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0;
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = 180;
        }
    }
    
    return degress;
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
    if(timerForReverseExport_)
    {
        timerForReverseExport_.fireDate = [NSDate distantFuture];
        [timerForReverseExport_ invalidate];
        PP_RELEASE(timerForReverseExport_);
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
- (void)checkReverseProgress:(NSTimer *)timer
{
    
    if(progressBlock_)
    {
        progressBlock_(self,currentReverseSession_.progress);
    }
    else if(self.delegate && [self.delegate respondsToSelector:@selector(VideoGenerater:generateReverseProgress:)])
    {
        [self.delegate VideoGenerater:self generateReverseProgress:currentReverseSession_.progress];
    }
}
-(void)exportDidFinish:(SDAVAssetExportSession*)session{
    
    NSLog(@"VG  :exportDidFinish state:%d",(int)session.status);
    dispatch_async(dispatch_get_main_queue(), ^{
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
    });
    
    
    
    
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
    if(timerForReverseExport_)
    {
        timerForReverseExport_.fireDate = [NSDate distantFuture];
        [timerForReverseExport_ invalidate];
        PP_RELEASE(timerForReverseExport_);
    }
#ifndef __OPTIMIZE__
    PP_RELEASE(mediaTrackList_);
#endif
    _waterMarkerPosition = MP_RightTop;
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
    NSLog(@"asset\t\t:duration:%f size:%ld",CMTimeGetSeconds(asset.duration),[[HCFileManager manager]fileSizeAtPath:filePath]);
    NSLog(@"asset\t\t-------- end -------------");
    
    asset = nil;
}
#pragma mark - dealloc
- (NSMutableArray *)getMediaTrackList
{
#ifndef __OPTIMIZE__
    return mediaTrackList_;
#else
    return nil;
#endif
    
}
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

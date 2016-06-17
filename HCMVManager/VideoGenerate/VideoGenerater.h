//
//  VideoGenerater.h
//  maiba
//
//  Created by HUANGXUTAO on 16/4/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "SDAVAssetExportSession.h"
#import <hccoren/base.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/ALAssetsLibrary.h>
#import "mvconfig.h"
#define DEFAULT_VIDEOWIDTH  540
#define DEFAULT_VIDEOHEIGHT 960
@class MediaItem;

@class VideoGenerater;

@protocol VideoGeneraterDelegate <NSObject>
- (void)VideoGenerater:(VideoGenerater*)queue didPlayerItemReady:(AVPlayerItem *)playerItem;
- (void)VideoGenerater:(VideoGenerater *)queue didItemsChanged:(BOOL)finished;
- (void)VideoGenerater:(VideoGenerater *)queue generateProgress:(CGFloat)progress;
- (void)VideoGenerater:(VideoGenerater *)queue didGenerateFailure:(NSString *)msg error:(NSError *)error;
- (void)VideoGenerater:(VideoGenerater *)queue didGenerateCompleted:(NSURL *)fileUrl cover:(NSString *)cover;

- (void)VideoGenerater:(VideoGenerater *)queue generateReverseProgress:(CGFloat)progress;

@end

typedef void (^MEPlayerItemReady)(VideoGenerater *queue,AVPlayerItem * playerItem);
typedef void (^MEProgress)(VideoGenerater *queue,CGFloat progress);
typedef void (^MECompleted)(VideoGenerater *queue,NSURL * mvUrl,NSString * coverPath);
typedef void (^MEFailure)(VideoGenerater *queue,NSString * msg,NSError * error);

@interface VideoGenerater : NSObject
{
    //为了即时合成音视频
    MEPlayerItemReady itemReadyBlock_;
    MEProgress  progressBlock_;
    MECompleted completedBlock_;
    MEFailure failureBlock_;
    
    
    float joinVideoProgress;
    
    NSString * lastGenerateKey_;
    
    SDAVAssetExportSession *joinVideoExporter;
    
    CMTimeRange joinTimeRange_;
    CGFloat bgAudioVolume_;//伴奏音乐音量,0-1
    CGFloat singVolume_;//人声 0-1
}
@property (nonatomic, assign) long bitRate;//码流，默认为-1
@property (nonatomic, PP_WEAK) id<VideoGeneraterDelegate> delegate;
@property (nonatomic, assign) int orientation;
@property (nonatomic, assign) BOOL useFontCamera;   //当前视频是否用前置摄像头拍摄？
@property (nonatomic, assign) BOOL bgAudioCanScale;//背景音乐是否要根据视频拉伸或加速？

@property (nonatomic, assign,readonly) CMTime totalBeginTime; //合成结果位于整个伴奏的起始时间
@property (nonatomic, assign,readonly) CMTime totalEndTime;   //合成结果位于整个伴奏的终止时间
@property (nonatomic, assign,readonly) CMTime totalBeginTimeForAudio; //音频合成结果位于整个音频伴奏的起始时间
@property (nonatomic, assign,readonly) CMTime totalEndTimeForAudio;   //音频合成结果位于整个音频伴奏的终止时间

@property (nonatomic, PP_STRONG,readwrite) NSURL * joinVideoUrl;// 可以对最终的导出路径进行设置
@property (nonatomic, PP_STRONG,readonly) NSURL * joinAudioUrl; //可对最终的合成音频的路径进行设置
@property (nonatomic, assign) BOOL  compositeLyric;   //是否合成歌词
@property (nonatomic, PP_STRONG)    NSURL * bgvUrl; //背景视频
@property (nonatomic, PP_STRONG)    NSURL * bgmUrl; //背景音乐
@property (nonatomic, PP_STRONG)    MediaItem * bgAudio;//背景音乐对像
@property (nonatomic, PP_STRONG)    NSArray * lrcList; //歌词
@property (nonatomic, PP_STRONG)    NSArray * filterLrcList;//截取后的歌词(可能起始时间不为0)
@property (nonatomic, assign)       CGFloat lrcBeginTime;//从歌词哪个的位置开始
@property (nonatomic, PP_STRONG)    NSString * waterMarkFile;//水印
@property (nonatomic, assign)       WaterMarkerPosition waterMarkerPosition;//水印位置
@property (nonatomic, PP_STRONG)    NSString * title; //标题
@property (nonatomic, PP_STRONG)    NSString * author;//作者
@property (nonatomic, PP_STRONG)    NSString * singer;//演唱者

@property (nonatomic, assign)        CGFloat mergeRate;//合成的速度
@property (nonatomic, assign)        CGFloat volRampSeconds;//声音渐变时长（变大，变小）

@property (nonatomic, readwrite)      AVPlayerItem *previewAVPlayItem;
@property (nonatomic, readonly) BOOL  previewAVassetIsReady;
@property (nonatomic, assign,readonly) CGSize renderSize;
@property (nonatomic, assign)       int TagID; //增加Tag标志，用于一个模块中有多个Generator时，区别是哪个Generator

- (void) setJoinAudioUrlWithDraft:(NSURL *)mixedAudioUrl;   //设置合成的音频文件路径，有可能是音频已经生成，直接设置即可
- (void) setRenderSize:(CGSize)size
           orientation:(int)orient
        withFontCamera:(BOOL)useFontCamera; //设置输出大小及方向问题。自己拍摄的视频需要液晶
- (void) setTimeForMerge:(CGFloat)secondsBegin
                     end:(CGFloat)secondsEnd;     //设置合成的时间范围,end为zero时，表示到末尾
- (void) setTimeForAudioMerge:(CGFloat)secondsBegin
                          end:(CGFloat)secondsEnd;     //设置合成的时间范围,end为zero时，表示到末尾
- (void) resetGenerateInfo;                 //重置合成对像，准备重新生成
- (void) setBlock:(MEProgress)progress
            ready:(MEPlayerItemReady)itemReady
        completed:(MECompleted)complted
          failure:(MEFailure)failure;

#pragma mark - 合成
- (BOOL) canMerge;
- (BOOL) needRebuildPreviewMV:(NSArray *)mediaList
                        bgVol:(CGFloat)bgVol
                      singVol:(CGFloat)singVol;              //根据起始时间来判断是否需要重新生成

//生成预览的PlayerItem
- (void) generatePreviewAsset:(NSArray *)mediaList
                     bgVolume:(CGFloat)volume
                   singVolume:(CGFloat)singVolume
                   completion:(void (^)(BOOL finished)) completion;

- (BOOL) generateMVFile:(NSArray *)mediaList
             retryCount:(int)retryCount;// bgAudioVolume:(CGFloat)volume singVolume:(CGFloat)singVolume;

- (BOOL) generateMVFile:(AVMutableVideoComposition *) videoComposition
               composte:(AVMutableComposition *) mixComposition
               audioMix:(AVMutableAudioMix *) audioMixOnce
                  range:(CMTimeRange) joinTimeRange
             retryCount:(int)retryCount;


//从伴奏与背景视频中截取一段合成完整视频
//音频文件在前面合成时，已经保存在本地，所以不需要再传音频文件
- (BOOL) generateMV:(NSArray *)mediaItemQueue
        accompanyMV:(NSURL*)accompanyMV
             audios:(NSArray *)audios
              begin:(CMTime)beginTime
                end:(CMTime) endTime
      bgAudioVolume:(CGFloat)volume
         singVolume:(CGFloat)singVolume
           progress:(MEProgress)progress
              ready:(MEPlayerItemReady)itemReady
          completed:(MECompleted)complted
            failure:(MEFailure)failure;


-(CGAffineTransform)layerTrans:(AVAsset *)testAsset
                withTargetSize:(CGSize)tsize
                   orientation:(UIDeviceOrientation)orientation
                withFontCamera:(BOOL) useFontCamera
               isCreateByCover:(BOOL)isCreateByCover;
//将视频倒序来放
- (BOOL) generateMVReverse:(NSString *)sourcePath
                    target:(NSString *)targetPath
                     begin:(CGFloat)sourceBegin
                       end:(CGFloat)sourceEnd
                 audioFile:(NSString *)audioFilePath
                audioBegin:(CGFloat)audioBegin
                  complted:(void (^)(NSString * filePath))complted;
#pragma mark - 截取一段视频
//  ALAsset可以转成asset再处理
//  NSURL * url = nil;
//  // url = [NSURL fileURLWithPath:_filePath];
//  url = [_asset valueForProperty:ALAssetPropertyAssetURL];
//  AVAsset *asset = [AVAsset assetWithURL:url];
- (BOOL) generateMVSegments:(AVAsset *)asset begin:(CGFloat) begin end:(CGFloat)end  targetSize:(CGSize)targetSize;
- (BOOL) generateMVSegmentsViaFile:(NSString *)filePath begin:(CGFloat) begin end:(CGFloat)end;
- (BOOL) generateMVSegmentsViaFile:(NSString *)filePath begin:(CGFloat) begin end:(CGFloat)end targetSize:(CGSize)targetSize;
- (BOOL) generateMVSegmentsViaPhAsset:(PHAsset *)asset begin:(CGFloat) begin end:(CGFloat)end  targetSize:(CGSize)targetSize;

#pragma mark - 取消事件
/*
 中止合成进程
 */
- (void) cancelExporter;
//清除所有数据，请在清除前将生成的文件拷贝到指定目录，否则该文件会被删除
- (void) clear;
//清除文件，请在清除前将生成的文件拷贝到指定目录，否则该文件会被删除
- (void) clearFiles;

#pragma mark - new functions for generate
- (void) showMediaInfo:(NSString *)filePath;
- (UIDeviceOrientation) checkOrieataionForTrack:(AVAssetTrack *)track filePath:(NSString *)filePath;
- (int)degressFromVideoFileWithTrack:(AVAssetTrack *)videoTrack filePath:(NSString*)filePath;
- (NSMutableArray *) getMediaTrackList;
+ (CGAffineTransform) getPlayerTrans:(UIDeviceOrientation)orientation
                        defaultTrans:(CGAffineTransform)defaultTrans;
@end

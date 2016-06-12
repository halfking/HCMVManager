//
//  MediaEditManager.m
//  maiba
//
//  Created by HUANGXUTAO on 15/8/18.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import "MediaEditManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import <hccoren/base.h>
#import <hccoren/RegexKitLite.h>
#import <hccoren/images.h>
#import <hccoren/json.h>
#import <hcbasesystem/config.h>
#import <hcbasesystem/UDManager(Helper).h>
#import <hcbasesystem/user_wt.h>
//#import "UIWebImageViewN.h"
#import <hcbasesystem/VDCManager.h>
#import <hcbasesystem/imagecontrols.h>
#import "mvconfig.h"
#import "WTPlayerResource.h"
#import "ImageToVideo.h"

#import "MediaEditManager(Draft).h"
#import "LyricItem.h"

#import "AudioGenerater.h"
#import "MediaListModel.h"
#import "LyricHelper.h"
#import "mvconfig.h"

#define MIN_AUDIOSPACE 0.05
@implementation MediaEditManager
@synthesize totalDuration,renderSize;
@synthesize backgroundAudio,backgroundVideo,accompanyDownKey,userAudioDownKey;
@synthesize SampleID,MTVID,MBMTVID;
//,dataList,myMTVList;
@synthesize MTVTitle;
@synthesize coverImageUrl;
@synthesize Sample = sampleMTV_;//,UserMTV;
@synthesize prevCompletedSeconds,stepIndex,mergeFilePath,mergeMTVItem;
//@synthesize WaterMarkLayer;
@synthesize DeviceOrietation = deviceOrietation_;
@synthesize TempTotalSeconds = tempTotalSeconds_;
@synthesize VolRampSeconds = volRampSeconds_;
+(id)Instance
{
    static dispatch_once_t pred = 0;
    static MediaEditManager *instance_ = nil;
    dispatch_once(&pred,^
                  {
                      instance_ = [[MediaEditManager alloc] init];
                      [instance_ setIsFragment:NO];
                  });
    return instance_;
}
+(id)InstanceSecond
{
    static dispatch_once_t predSecond = 0;
    static MediaEditManager *secondInstance_ = nil;
    dispatch_once(&predSecond,^
                  {
                      secondInstance_ = [[MediaEditManager alloc] init];
                      [secondInstance_ setIsFragment:YES];
                  });
    return secondInstance_;
}
+(MediaEditManager *)shareObject
{
    return (MediaEditManager *)[self Instance];
}
+ (MediaEditManager *)secondObject
{
    return (MediaEditManager *)[self InstanceSecond];
}
- (void)setIsFragment:(BOOL)pIsFragement
{
    _isFragment = pIsFragement;
}
- (id)init
{
    if(self = [super init])
    {
        //        DeviceConfig * config = [DeviceConfig config];
        mediaList_ = [NSMutableArray new];
        audioList_ = [NSMutableArray new];
        totalDuration = CMTimeMakeWithSeconds(TOTALSECONDS_DEFAULT, VIDEO_CTTIMESCALE);
        totalSecondsDuration_ = TOTALSECONDS_DEFAULT;
        //        renderSize = CGSizeMake(config.Height*config.Scale,config.Width*config.Scale);
        renderSize = CGSizeMake(540,960);
        itemHeight_ = 60;
        itemWidth_ = MIN(IMAGE_DURATION * 12, 100);
        
        playVolumeWhenRecord_ = 0.6; //假定用户默认使用60%的音量播放伴奏
        singVolume_ = 1;
        mergeRate_ = 1.0;
        volRampSeconds_ = 0.5;
        
        videoGenerater_ = [VideoGenerater new];
        
        //        generateQueue_ = [[SeenVideoQueue alloc]init];
        videoGenerater_.delegate = self;
        videoGenerater_.mergeRate = mergeRate_;
        videoGenerater_.volRampSeconds = volRampSeconds_;
        if(self.mergeMTVItem.MTVID>0)
        {
            videoGenerater_.compositeLyric = NO;
        }
        else
        {
            videoGenerater_.compositeLyric = YES;
        }
        [videoGenerater_ setRenderSize:self.renderSize orientation:UIDeviceOrientationPortrait withFontCamera:NO];
        
        self.NotAddCover = NO;
        //        dispatch_JoinVideo_ = dispatch_queue_create("JoinVideoNew", DISPATCH_QUEUE_SERIAL);
        
        needRegenerate_ = NO;
        
        self.addLyricLayer = YES;
        self.addWaterMark = YES;
        
        orgBgVolume_ = playVolumeWhenRecord_;
        orgSingVolumne_ = singVolume_;
        
        prevCompletedSeconds = -1;
        stepIndex = -1;
        mergeFilePath = nil;
        mergeMTVItem = nil;
        
        isDraftSaving_ = NO;
        
        lyricDuration_ = -1;
        lyricBegin_ = 0;
        secondsEndForMerge_ = 0;
        secondsBeginForMerge_ = 0;
        deviceOrietation_ = -1;
        waterMarkFile_ = PP_RETAIN(CT_WATERMARKFILE);
        
        tempTotalSeconds_ = 60 * 60;
    }
    return self;
}
//检查是否合并完成，将完成后的临时文件删除
- (void)removeSampleInfo:(MTV *)sampleMTV
{
    // 后面传来的sampleMTV会替换掉前一个sampleMTV
    if(sampleMTV && sampleMTV.SampleID>0)
    {
        NSString * urlString = [sampleMTV getDownloadUrlOpeated:[DeviceConfig config].networkStatus userID:[UserManager sharedUserManager].userID];
        if(urlString && urlString.length>0)
        {
            [[VDCManager shareObject]removeTemplateFilesByUrl:urlString];
            if(sampleMTV.AudioRemoteUrl && sampleMTV.AudioRemoteUrl.length>0)
            {
                [[VDCManager shareObject]removeTemplateFilesByUrl:sampleMTV.AudioRemoteUrl];
            }
        }
    }
    PP_RELEASE(sampleMTV_);
    PP_RELEASE(_CurrentSample);
}
- (void)setSampleInfo:(Samples *)samples
{
    // 后面传来的sampleMTV会替换掉前一个sampleMTV
    //    if(sampleMTV_ && sampleMTV_.SampleID>0)
    //    {
    //        NSString * urlString = [sampleMTV_ getDownloadUrlOpeated:[DeviceConfig config].networkStatus userID:[UserManager sharedUserManager].userID];
    //        if(urlString && urlString.length>0)
    //        {
    //            [[VDCManager shareObject]removeTemplateFilesByUrl:urlString];
    //            if(sampleMTV.AudioRemoteUrl && sampleMTV.AudioRemoteUrl.length>0)
    //            {
    //                [[VDCManager shareObject]removeTemplateFilesByUrl:sampleMTV.AudioRemoteUrl];
    //            }
    //        }
    //    }
    if(samples != _CurrentSample)
    {
        PP_RELEASE(_CurrentSample);
        _CurrentSample = PP_RETAIN(samples);
        
        PP_RELEASE(sampleMTV_);
        sampleMTV_ = [samples toMTV];
        if(sampleMTV_ && sampleMTV_.SampleID>0)
        {
            self.SampleID = sampleMTV_.SampleID;
        }
    }
}
//添加歌词
- (void) setLyricArray:(NSArray *)lyricList atTime:(CGFloat)begin duration:(CGFloat)duration watermarkFile:(NSString *)waterMarkFile
{
    if(lyricList && lyricList.count>0)
    {
        PP_RELEASE(lyricList_);
        lyricList_ = PP_RETAIN(lyricList);
        
        lyricBegin_ = begin;
        
        lyricDuration_ = duration;
    }
    else
    {
        PP_RELEASE(lyricList_);
        lyricBegin_ = 0;
        lyricDuration_ = -1;
    }
    //    if(!waterMarkFile) waterMarkFile = CT_WATERMARKFILE;
    if(waterMarkFile && [waterMarkFile_ isEqualToString:waterMarkFile]==NO)
    {
        PP_RELEASE(waterMarkFile_);
        if(waterMarkFile && waterMarkFile.length>0)
            waterMarkFile_ = PP_RETAIN(waterMarkFile);
    }
    if(videoGenerater_)
    {
        videoGenerater_.lrcList = lyricList_;
        videoGenerater_.lrcBeginTime = lyricBegin_;
        videoGenerater_.waterMarkFile = waterMarkFile_;
    }
}
- (void)setVideoOrietation:(UIDeviceOrientation)orientation renderSize:(CGSize)size withFontCamera:(BOOL)useFontCamera
{
    deviceOrietation_ = orientation; //-1或0表示不处理，涉及视频旋转
    videoGenerater_.orientation = orientation;
    useFontCamera_ = useFontCamera;
    if(size.width>50 && size.height>50)
    {
        renderSize = size;
    }
    else
    {
        size = renderSize;
    }
    //    else if(size.width<0 || size.width<0)  //重设置
    //    {
    //        renderSize = CGSizeMake(1280,720);
    //    }
    [videoGenerater_ setRenderSize:size orientation:orientation withFontCamera:useFontCamera_];
    renderSize = videoGenerater_.renderSize;
    
}
//合成时播放速度处理
- (void)setMergeRate:(CGFloat)rate
{
    mergeRate_ = rate;
    videoGenerater_.mergeRate = rate;
    NSLog(@"mediaedit: rate:%.2f",rate);
}
- (void)setMTVLyric:(NSString *)lyric times:(int)times
{
    if(times>2) return;
    if(lyric && lyric.length>0)
    {
        if([HCFileManager isUrlOK:lyric])
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
                           {
                               NSString * content = [[UDManager sharedUDManager]getContentCachedByUrl:lyric ext:@"lrc"];
                               NSLog(@"query lyric:%@",lyric);
                               NSLog(@"lyric:%@",content);
                               [self setMTVLyric:content times:times +1];
                               
                           });
        }
        else
        {
            NSArray * array = [lyric JSONValueEx];
            //偿试另一种方式解析
            if(!array)
            {
                array = [[LyricHelper sharedObject]getSongLrcWithStr:lyric metas:nil];
            }
            PARSEDATAARRAY(filterLyricItems,array,LyricItem);
            videoGenerater_.filterLrcList = filterLyricItems;
            [self setLyricArray:filterLyricItems atTime:0 duration:-1 watermarkFile:CT_WATERMARKFILE];
        }
    }
    else
    {
        videoGenerater_.filterLrcList = nil;
    }
}
- (void)setMergeMTVItem:(MTV *)pMergeMTVItem
{
    mergeMTVItem = PP_RETAIN(pMergeMTVItem);
    if(pMergeMTVItem.MTVID>0)
    {
        [self setMTVLyric:pMergeMTVItem.Lyric times:0];
    }
}
//-(void)setWaterMarkLayer:(CALayer *)watermarkLayer
//{
//    WaterMarkLayer = watermarkLayer;
//    generateQueue_.WaterMarkLayer = watermarkLayer;
//}
- (void)setPlayVolumeWhenRecording:(CGFloat)volume
{
    playVolumeWhenRecord_ = volume<0?playVolumeWhenRecord_:volume>1?playVolumeWhenRecord_:volume;
}
- (void)setSingVolume:(CGFloat)volume
{
    singVolume_ = volume<0?singVolume_:volume>1?singVolume_:volume;
}
- (CGFloat)getSingVolumn
{
    return singVolume_;
}
- (CGFloat)getPlayVolumn
{
    return playVolumeWhenRecord_;
}

- (MediaItem *)getMediaItem:(NSURL *)videoUrl
{
    if(videoUrl)
    {
        //文件全部当作本地的，不考虑远程文件
        MediaItem * item = [[MediaItem alloc]init];
        item.fileName = [[HCFileManager manager]getFileName:[videoUrl path]];
        //        item.filePath = [CommonUtil checkPath:videoUrl.absoluteString];
        item.url = videoUrl;
        AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:videoUrl options:nil];
        NSArray * array = [asset tracksWithMediaType:AVMediaTypeVideo];
        if(array.count>0)
        {
            AVAssetTrack *vTrack = [array objectAtIndex:0];
            if(vTrack)
            {
                item.renderSize =   vTrack.naturalSize;
            }
            item.duration = asset.duration;
            item.begin = CMTimeMakeWithSeconds(0, item.duration.timescale);
            item.end = item.duration;
            item.degree = [self degressFromVideoFileWithTrack:vTrack];
//            item.degree = [self degressFromVideoFileWithAsset:asset];
            item.orientation = [self orientationFromDegree:item.degree];
            item.isOnlyAudio = NO;
            item.originType = MediaItemTypeVIDEO;
            needCreateBGVideo_ = NO;
        }
        else
        {
            //如果只是音乐，则需要动态生成背景视频
            array = [asset tracksWithMediaType:AVMediaTypeAudio];
            if(array.count>0)
            {
                //                AVAssetTrack *vTrack = [array objectAtIndex:0];
                item.duration = asset.duration;
                item.begin = CMTimeMakeWithSeconds(0, item.duration.timescale);
                item.end = item.duration;
                
                needCreateBGVideo_ = YES;
                if(UIDeviceOrientationIsLandscape(self.DeviceOrietation))
                {
                    item.degree = 0;
                    item.orientation = UIDeviceOrientationLandscapeLeft;
                    item.renderSize =   CGSizeMake(1280, 720);
                }
                else
                {
                    item.degree = 90;
                    item.orientation = UIDeviceOrientationPortrait;
                    item.renderSize =   CGSizeMake(720, 1280);
                }
                item.isOnlyAudio = YES;
                item.originType = MediaItemTypeAUDIO;
            }
            else
            {
                item.duration = kCMTimeZero;
                item.begin = kCMTimeZero;
                item.end = kCMTimeZero;
            }
        }
        return PP_AUTORELEASE(item);
    }
    return nil;
}
- (NSArray *) getFilterLyricItems
{
    if(videoGenerater_)
    {
        return videoGenerater_.filterLrcList;
    }
    else
    {
        return nil;
    }
}
- (int)degressFromVideoFileWithAsset:(AVAsset *)videoTrack
{
    int degress = -1;
    if(videoTrack)
    {
        //    AVAsset *asset = [AVAsset assetWithURL:url];
        //    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        //    if([tracks count] > 0) {
        //        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
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
- (int)degressFromVideoFileWithTrack:(AVAssetTrack *)videoTrack
{
    int degress = -1;
    if(videoTrack)
    {
        //    AVAsset *asset = [AVAsset assetWithURL:url];
        //    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        //    if([tracks count] > 0) {
        //        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
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
-(UIDeviceOrientation)orientationFromDegree:(int)degrees
{
//    int degrees = [self degressFromVideoFileWithTrack:videoTrack];
    if(degrees ==0)
        return UIDeviceOrientationLandscapeLeft;
    else if(degrees==90)
        return UIDeviceOrientationPortrait;
    else if(degrees==180)
        return UIDeviceOrientationLandscapeRight;
    else if(degrees==270)
        return UIDeviceOrientationPortraitUpsideDown;
    else
        return UIDeviceOrientationPortrait;
}
-(UIDeviceOrientation)orientationFromVideo:(AVAssetTrack *)videoTrack
{
    int degrees = [self degressFromVideoFileWithTrack:videoTrack];
    return [self orientationFromDegree:degrees];
//    if(degrees ==0)
//        return UIDeviceOrientationLandscapeLeft;
//    else if(degrees==90)
//        return UIDeviceOrientationPortrait;
//    else if(degrees==180)
//        return UIDeviceOrientationLandscapeRight;
//    else if(degrees==270)
//        return UIDeviceOrientationPortraitUpsideDown;
//    else
//        return UIDeviceOrientationPortrait;
}
- (BOOL)isBgVideoLandsccape
{
    if(backgroundVideo)
    {
        if(backgroundVideo.degree ==0 || backgroundVideo.degree == 180)
            return YES;
        else
            return NO;
    }
    return NO;
}
- (void)setVideoProperties:(MediaItem *)item
{
    if(deviceOrietation_ <=0)
    {
        deviceOrietation_ = item.orientation;
    }
    if(item.renderSize.height>0&&item.renderSize.width>0)
    {
        renderSize = [ImagesToVideo correctSizeWithoutOrientation:renderSize sourceSize:item.renderSize];
    }
    NSLog(@"bgvideo degree:%d orietation:%d rendersize:%@",item.degree,(int)item.orientation,NSStringFromCGSize(renderSize));
    //设置合成视频的Size
    [videoGenerater_ setRenderSize:renderSize orientation:deviceOrietation_ withFontCamera:useFontCamera_];
    if(item.isOnlyAudio)
    {
        videoGenerater_.bgmUrl = item.url;
        videoGenerater_.bgvUrl = nil;
        self.NotAddCover = YES;
    }
    else
    {
        videoGenerater_.bgvUrl = item.url;
        videoGenerater_.bgmUrl = nil;
    }
    isGenerating_ = NO;
    isGenerateAudioing_=NO;
}
- (void)didCreateBGVideo:(NSString *)path
{
    [self setVideoProperties:backgroundVideo];
    backgroundVideo.url = [NSURL fileURLWithPath:[HCFileManager checkPath:path]];
    backgroundVideo.isOnlyAudio = NO;
    videoGenerater_.bgvUrl = backgroundVideo.url;
    needCreateBGVideo_ = NO;
    
#ifndef __OPTIMIZE__
    AVURLAsset * asset = [AVURLAsset assetWithURL:backgroundVideo.url];
    AVAssetTrack * track = [[asset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];
    CGFloat degree = [self degressFromVideoFileWithTrack:track];
    NSLog(@"bg rotation:%.0f,file:%@",degree,[backgroundVideo.url path]);
#endif
}
- (void)setTotalDuration:(CMTime)totalDurationA
{
    if(backgroundVideo && backgroundVideo.secondsDuration>0 && backgroundVideo.secondsDuration <= CMTimeGetSeconds(totalDurationA))
    {
        NSLog(@"已经有全局素材，不允许再赋值.");
        return;
    }
    totalDuration = totalDurationA;
    totalSecondsDuration_ = CMTimeGetSeconds(totalDuration);
    totalSecondsDurationByFullItems_ = totalSecondsDuration_;
}
- (void)setBackgroundVideo:(NSURL *)video andAudio:(NSURL *)audio cover:(NSString *)coverUrl coverImage:(UIImage *)image
{
    if(video)
    {
        //文件全部当作本地的，不考虑远程文件
        MediaItem * item = [self getMediaItem:video];
        if(item.secondsDuration>0)
        {
            totalDuration = item.duration;
            totalSecondsDuration_ = CMTimeGetSeconds(totalDuration);
            totalSecondsDurationByFullItems_ = totalSecondsDuration_;
            //            backgroundAudio = PP_RETAIN(item);
            backgroundVideo = PP_RETAIN(item);
            
            if(!needCreateBGVideo_)
            {
                [self setVideoProperties:item];
            }
            isGenerating_ = NO;
            isGenerateAudioing_=NO;
        }
#ifndef __OPTIMIZE__
        AVURLAsset * asset = [AVURLAsset assetWithURL:video];
        NSArray * tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if(tracks.count>0)
        {
            AVAssetTrack * track = [tracks objectAtIndex:0];
            NSLog(@"track size:%@ transfer:%@",NSStringFromCGSize(track.naturalSize),NSStringFromCGAffineTransform(asset.preferredTransform));
        }
#endif
    }
    else
    {
        PP_RELEASE(backgroundVideo);
        videoGenerater_.bgvUrl = nil;
    }
    if(audio)
    {
        AudioItem * item = [[AudioItem alloc]init];
        item.fileName = [[HCFileManager manager]getFileName:[audio path]];
        item.url = audio;
        
        AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:video options:nil];
        
        item.secondsDuration = CMTimeGetSeconds(asset.duration);
        item.secondsBegin = 0;
        item.secondsEnd = item.secondsDuration;
        
        backgroundAudio = PP_RETAIN(item);
        PP_RELEASE(item);
        
        videoGenerater_.bgmUrl = audio;
    }
    else
    {
        PP_RELEASE(backgroundAudio);
        videoGenerater_.bgmUrl = nil;
    }
    if(image)
    {
        NSString * path  = PP_RETAIN([self getCoverImageFileName]);
        if([UIImagePNGRepresentation(image) writeToFile: path atomically:YES])
        {
            PP_RELEASE(coverImageUrl);
            coverImageUrl = PP_RETAIN(path);
        }
    }
    else if(coverUrl)
    {
        [self getImageDataFromUrl:coverUrl size:self.renderSize];
    }
    else
    {
        PP_RELEASE(coverImageUrl);
    }
    
}
- (void)setCoverImageUrl:(NSString *)aCoverImageUrl
{
    if(aCoverImageUrl)
    {
        [self getImageDataFromUrl:aCoverImageUrl size:self.renderSize];
    }
    else
    {
        PP_RELEASE(coverImageUrl);
    }
}
- (void)getImageDataFromUrl:(NSString *)urlString size:(CGSize)size
{
//    NSString * imgUrl = [HCImageItem urlWithWH:urlString width:size.width height:size.height mode:2];
    
    if([HCFileManager isLocalFile:urlString])
    {
        urlString = [HCImageItem urlWithWH:urlString width:size.width height:size.height mode:2];
        if(urlString == coverImageUrl || [urlString isEqualToString:coverImageUrl])
        {
            if(needCreateBGVideo_)
            {
                NSString * filePath = [self getCoverVideoFilePath];
                if([[UDManager sharedUDManager]existFileAtPath:filePath])
                {
                    [self didCreateBGVideo:filePath];
                    return;
                }
            }
        }
        if([HCFileManager isExistsFile:urlString])
        {
            PP_RELEASE(coverImageUrl);
            UIImage * image = [UIImage imageWithContentsOfFile:urlString];
            [self checkImageSizeAndSave:image isCover:YES path:nil];
            //            coverImageUrl = PP_RETAIN(imgUrl);
            NSLog(@"get cover image for merge ok2.");
            [self generateCoverItem];
            //            if(self.mergeMTVItem)
            //            {
            //                self.mergeMTVItem.CoverUrl = coverImageUrl;
            //            }
        }
    }
    else
    {
        __weak MediaEditManager * weakSelf = self;
        [[UDManager sharedUDManager]getImageDataFromUrl:urlString size:size completed:^(UIImage *image, NSError *error) {
            PP_RELEASE(coverImageUrl);
            //             NSString * path  = PP_RETAIN([self getCoverImageFileName]);
            if(image)
            {
                image = [weakSelf checkImageSizeAndSave:image isCover:YES path:nil];
                [weakSelf generateCoverItem];
                //                 if([UIImagePNGRepresentation(image) writeToFile: path atomically:YES])
                //                 {
                //                     coverImageUrl = PP_RETAIN(path);
                //                     [self generateCoverItem];
                //                     if(self.mergeMTVItem)
                //                     {
                //                         self.mergeMTVItem.CoverUrl = coverImageUrl;
                //                     }
                //                 }
                NSLog(@"get cover image for merge ok.");
            }
            else
            {
                NSLog(@"get cover image %@ for merge failure.",urlString);
            }
            
        }];
    }
}

- (UIImage *)checkImageSizeAndSave:(UIImage *)image isCover:(BOOL)isCover path:(NSString *)filePath
{
    NSLog(@"imagesize:%@",NSStringFromCGSize(image.size));
    CGSize targetSize = CGSizeMake(720, 1280);
    if(UIDeviceOrientationIsPortrait(self.DeviceOrietation))
    {
        if(image.size.width> image.size.height)
            targetSize = CGSizeMake(1280, 720);
    }
    else
    {
        targetSize = CGSizeMake(1280, 720);
        if(image.size.width< image.size.height)
            targetSize = CGSizeMake(720, 1280);
    }
    
    if(isCover)
    {
        filePath = [self getCoverImageFileName];
    }
    else
    {
        if(!filePath||filePath.length==0)
        {
            filePath = [NSString stringWithFormat:@"%ld.jpg",[CommonUtil getDateTicks:[NSDate date]]];
        }
    }
    //    if((int)image.size.width % 1334 == 0 && (int)image.size.height %1000 == 0)
    //    {
    //        CGRect rect = [CommonUtil rectFitWithScale:image.size rectMask:targetSize];
    //        image = [image imageAtRect:rect];
    //        NSLog(@"image scale:%f size:%@",image.scale,NSStringFromCGSize(image.size));
    //    }
    NSLog(@"0 image scale:%f size:%@",image.scale,NSStringFromCGSize(image.size));
    BOOL needResize = NO;
    //如果是IP拍摄的
    if((int)image.size.width % 1334 == 0 && (int)image.size.height %1000 == 0)
    {
        needResize = YES;
    }
    else if((int)image.size.height % 1334 == 0 && (int)image.size.width %1000 == 0)
    {
        needResize = YES;
    }
    if(!needResize && !isCover)
    {
        //        image = [image imageByScalingProportionallyToSize:targetSize];
    }
    else
    {
        image = [self cropImageWithScale:image targetSize:targetSize];
    }
    NSLog(@"1 image scale:%f size:%@",image.scale,NSStringFromCGSize(image.size));
    
    NSData * data = UIImageJPEGRepresentation(image,1);
    if(data.length > 300 * 1024)
    {
        data = UIImageJPEGRepresentation(image,0.8);
        
        image = [UIImage imageWithData:data];
    }
    if([HCFileManager isExistsFile:filePath])
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError * error = nil;
        [fileManager removeItemAtPath:filePath error:&error];
        if(error)
        {
            NSLog(@"delete file:%@ error:%@",filePath,[error localizedDescription]);
        }
    }
    [data writeToFile:filePath atomically:YES];
    
    if(isCover)
    {
        coverImageUrl = PP_RETAIN(filePath);
        
        coverMedialItem_.fileName = [[HCFileManager manager]getFileName:filePath];
        //        coverMedialItem_.filePath = filePath;
        
        if(self.mergeMTVItem)
        {
            self.mergeMTVItem.CoverUrl = filePath;
        }
    }
    return image;
}
- (void)generateCoverItem
{
    PP_RELEASE(coverMedialItem_);
    
    if(!coverImageUrl || ![HCFileManager isExistsFile:coverImageUrl]) return;
    //    if(self.NotAddCover) return;
    
    MediaItem * item = [[MediaItem alloc]init];
    item.originType = MediaItemTypeIMAGE;
    //    item.duration = CMTimeMakeWithSeconds(MINVIDEO_SECONDS*2, IMAGE_TIMESCALE);
    item.duration = CMTimeMakeWithSeconds(COVER_SECONDS, IMAGE_TIMESCALE);
    item.begin = CMTimeMakeWithSeconds(0, IMAGE_TIMESCALE);
    item.end = item.duration;
    
    item.url = [NSURL fileURLWithPath:coverImageUrl];
    //这里的Url是一个可能的Http类似的东东
    item.fileName = coverImageUrl;
    item.cover = coverImageUrl;
    item.key = [self getKeyOfItem:item];// [self getKeyForFile:item.filePath];
    item.cutInMode = CutInOutModeFadeIn;
    item.cutOutMode = CutInOutModeFadeOut;
    
    item.renderSize = self.renderSize;
    //    if(!self.NotAddCover)
    //    {
    item.fileName =  [[MediaListModel shareObject]getVideoPath:item]; // [generateQueue_ generateImage2Video:[self toPlayerMediaItem:item]];
    //    }
    if(needCreateBGVideo_)
    {
        __weak MediaEditManager * weakSelf = self;
        NSString * targetPath = [self getCoverVideoFilePath];
        [[MediaListModel shareObject] generateMVByCover:coverImageUrl
                                             targetPath:targetPath
                                               duration:totalSecondsDuration_
                                                    fps:1 size:item.renderSize
                                            orientation:self.DeviceOrietation
                                               progress:^(NSString *filePath, NSError *error) {
                                                   [weakSelf didCreateBGVideo:filePath];
                                               }];
    }
    coverMedialItem_ = PP_RETAIN(item);
}
- (NSString*)getCoverImageFileName
{
    NSTimeInterval aInterval =[[NSDate date] timeIntervalSince1970];
    NSString * path = [[NSString stringWithFormat:@"%.0f_cover",aInterval * 1000]
                       stringByAppendingString:@".jpg"];
    return [[UDManager sharedUDManager] tempFileFullPath:path];
    
}
- (NSString *)getCoverVideoFilePath
{
    if(coverImageUrl)
    {
        return [coverImageUrl stringByAppendingString:@".bg.mp4"];
    }
    else
    {
        return nil;
    }
}
//获取当前唱完的量，值可能为-1，0，或大于0的值。-1表示完整
- (CGFloat)     getSecondsSinged:(long)sampleID
{
    if(self.SampleID>0 && SampleID>0 && self.SampleID != SampleID) return -1;
    if(stepIndex>=0||stepIndex<-1) return -1;
    
    CGFloat maxSeconds = -1;
    for (int i = 0; i<(int)audioList_.count; i++) {
        AudioItem * item = audioList_[i];
        if(item.secondsInArray + item.secondsDurationInArray > maxSeconds)
        {
            maxSeconds = item.secondsInArray + item.secondsDurationInArray;
        }
    }
    return maxSeconds;
}
- (CGFloat) totalAudioDuration
{
    CGFloat maxSeconds = 0;
    [self resortAudioes];
    for (int i = 0; i<(int)audioList_.count; i++) {
        AudioItem * item = audioList_[i];
        maxSeconds += item.secondsDurationInArray;
    }
    return maxSeconds;
}
//是否有用户自己的远程音频，主要用于与导唱区分
- (BOOL) hasRemoteUserAudioUrl
{
    if(!self.mergeMTVItem || !self.mergeMTVItem.AudioRemoteUrl || self.mergeMTVItem.AudioRemoteUrl.length<2)
        return NO;
    if(!self.Sample) return NO;
    if(!self.Sample.AudioRemoteUrl && self.Sample.AudioRemoteUrl.length>=2 &&
       [self.mergeMTVItem.AudioRemoteUrl isEqualToString:self.Sample.AudioRemoteUrl]==YES)
        return NO;
    return self.mergeMTVItem.AudioRemoteUrl.length >= 2;
}
//判断此链接是否为导唱的音频链接
- (BOOL) isAudioGuide:(NSString *)remoteAudioUrl
{
    if(!remoteAudioUrl || remoteAudioUrl.length<=2) return NO;
    if(!self.Sample) return NO;
    if(!self.Sample.AudioRemoteUrl || self.Sample.AudioRemoteUrl.length<2 ||
       [remoteAudioUrl isEqualToString:self.Sample.AudioRemoteUrl]==NO)
        return NO;
    return YES;
}
#pragma mark - add remove voice
- (void)setVolRampSeconds:(CGFloat)VolRampSeconds
{
    volRampSeconds_ = VolRampSeconds;
    if(videoGenerater_)
    {
        videoGenerater_.volRampSeconds = volRampSeconds_;
    }
}
- (AudioItem *)addVoiceItem:(AudioItem *)item
{
    //主要是排除重复的东东
    [self removeVoiceItemAtTime:item.secondsInArray duration:item.secondsDurationInArray ];
    NSInteger  index = [self getVoiceItemIndexBySeconds:item.secondsInArray];
    if(index >=0 && index < audioList_.count)
    {
        [audioList_ insertObject:item atIndex:index];
    }
    else
    {
        [audioList_ addObject:item];
    }
    item.index = index;
    [self resortAudioes];
    return item;
}

// recordBeginSeconds:指本音频文件，应该处于整个轨中的位置，如果为负数，则位置为0，但需要去除本音频文件的开头部分
// delayseconds:指与相关的开始时间的误差，有可能因为硬件，启动时间比计划时间晚。
- (AudioItem*)addVoiceItemByFile:(NSString *)filePath atTime:(CGFloat)recordBeginSeconds delaySeconds:(CGFloat)delaySeconds // delaySeconds 延迟的废弃的时间
{
    if([HCFileManager isExistsFile:filePath]==NO) return nil;
    
    filePath = [HCFileManager checkPath:filePath];
    
    //    EZAudioFile * audioFile = [EZAudioFile audioFileWithURL:[NSURL fileURLWithPath:filePath]];
    AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:filePath]];
    AudioItem * item = [AudioItem new];
    item.fileName = filePath;
    item.secondsDuration = CMTimeGetSeconds(asset.duration);// audioFile.duration;
#ifndef __OPTIMIZE__
    long size = (long)[[UDManager sharedUDManager]fileSizeAtPath:filePath];
    NSLog(@"file size:%ld",size);
#endif
    
    ///----------
    /*  正常情况 :视频作为背景，录制音频
     bg         |--------------------------------|      (背景轨)
     audio        |-----------------------------------| (录音轨)
     recb       |<---->|            (计划开始录的时间点)
     delay        |<-->|            (录音为了解决延迟，提前启动的时间,前段为无效时间)
     begin             |            (真实开始播放的时间点)
     
     */
    
    if(recordBeginSeconds>=0)
    {
        if(delaySeconds<0)
        {
            recordBeginSeconds -= delaySeconds;
            delaySeconds = 0;
        }
    }
    else if(recordBeginSeconds<0)
    {
        if(delaySeconds>=0)
        {
            recordBeginSeconds = 0;
            delaySeconds -= recordBeginSeconds;
        }
        else
        {
            if(delaySeconds >= recordBeginSeconds)
            {
                recordBeginSeconds = 0;
                delaySeconds -= recordBeginSeconds;
            }
            else
            {
                recordBeginSeconds -= delaySeconds;
                delaySeconds = 0;
            }
        }
    }
    item.secondsInArray = recordBeginSeconds;
    item.secondsBegin = delaySeconds;
    
    
    CGFloat totalSeconds = CMTimeGetSeconds(totalDuration);
    if(totalSeconds<=0)
    {
        item.secondsEnd = MIN(item.secondsDuration, tempTotalSeconds_ - item.secondsInArray+item.secondsBegin);
    }
    else
    {
        item.secondsEnd = MIN(item.secondsDuration, totalSeconds - item.secondsInArray+item.secondsBegin);
    }
    
    //太小，不放在队列中
    if(item.secondsDurationInArray <MIN_AUDIOSPACE)
    {
        return item;
    }
    AudioItem *temp = [self addVoiceItem:item];
#ifndef __OPTIMIZE__
    NSLog(@"joinaudio:(add) timeline:(%.2f--%.2f) intrack:(%.2f,%.2f) add:(%.2f) delay:(%.2f)",
          temp.secondsInArray,temp.secondsInArray + temp.secondsDurationInArray,temp.secondsBegin,temp.secondsEnd,recordBeginSeconds,delaySeconds);
    @synchronized(self) {
        for (AudioItem *item in audioList_) {
            NSLog(@"joinaudio:(list) timeline:(%.2f--%.2f) intrack:(%.2f,%.2f)",
                  item.secondsInArray,item.secondsInArray + item.secondsDurationInArray,item.secondsBegin,item.secondsEnd);
            //        NSLog(@"--(b %.2f e %.2f)->d:%.2f in:(s %.2f s %.2f)",item.secondsBegin,item.secondsEnd,item.secondsDuration,item.secondsInArray,item.secondsDurationInArray)
            //        NSLog(@"current secondsBegin is:%f------------------",item_.secondsBegin);
            //        NSLog(@"current secondsDuration is:%f------------",item_.secondsDuration);
            //        NSLog(@"current secondsDurationInArray is:%f",item_.secondsDurationInArray);
            //        NSLog(@"current secondsEnd is:%f",item_.secondsEnd);
            //        NSLog(@"current secondsInArray is:%f",item_.secondsInArray);
        }
    }
    
#endif
    return temp;
}
- (void)resortAudioes
{
    if(audioList_.count<=1) return;
    @synchronized(self) {
        //校正时间
        for (AudioItem * item in audioList_) {
            if(item.secondsDuration < 1)
            {
                AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:item.filePath]];
                item.secondsDuration = CMTimeGetSeconds(asset.duration);
            }
        }
    }
    
    [audioList_ sortUsingComparator:[self getListCompareForAudio]];
    
    NSMutableArray * removeList = [NSMutableArray new];
    
    NSInteger index = 0;
    CGFloat totalSeconds = CMTimeGetSeconds(totalDuration);
    CGFloat prevSeconds = 0;
    
    if(totalSeconds<=0)
    {
        totalSeconds = tempTotalSeconds_;
    }
    
    AudioItem * lastitem = nil;
    for (AudioItem * cItem in audioList_) {
        
        //去除被完合覆盖的音频，考虑0.05的误差
        if(lastitem
           && cItem.secondsInArray+MIN_AUDIOSPACE >= lastitem.secondsInArray
           && cItem.secondsInArray + cItem.secondsDurationInArray <= lastitem.secondsInArray + lastitem.secondsDurationInArray+MIN_AUDIOSPACE)
        {
            [removeList addObject:cItem];
            continue;
        }
        //如果被部分覆盖
        if(lastitem && lastitem.secondsInArray+lastitem.secondsDuration > cItem.secondsInArray)
        {
            lastitem.secondsEnd = lastitem.secondsBegin + cItem.secondsInArray - lastitem.secondsInArray;
            if(lastitem.secondsDurationInArray < MIN_AUDIOSPACE)
            {
                [removeList addObject:lastitem];
            }
        }
        //没有被覆盖的，才正确处理
        cItem.index = index;
        if(cItem.secondsInArray < prevSeconds)
        {
            cItem.secondsInArray = prevSeconds;
        }
        if(cItem.secondsDurationInArray + cItem.secondsInArray > totalSeconds )
        {
            cItem.secondsEnd = cItem.secondsBegin + (totalSeconds - cItem.secondsInArray);
        }
        if(cItem.secondsDurationInArray < MIN_AUDIOSPACE)
        {
            [removeList addObject:cItem];
        }
        else
        {
            prevSeconds += cItem.secondsDurationInArray;
            lastitem = cItem;
        }
        index ++;
    }
    if(removeList.count>0)
    {
//        UDManager * um = [UDManager sharedUDManager];
        for (AudioItem * item in removeList) {
            if(item.filePath && item.filePath.length>0)
            {
                if(![HCFileManager isInAblum:item.filePath])
                {
                    [[HCFileManager manager] removeFileAtPath:item.filePath];
                }
            }
        }
        [audioList_ removeObjectsInArray:removeList];
    }
    PP_RELEASE(removeList);
}
- (NSInteger) getVoiceItemIndexBySeconds:(CGFloat)seconds
{
    NSInteger  index = 0;
    for (AudioItem * cItem in audioList_) {
        if((cItem.secondsInArray <= seconds
            && cItem.secondsInArray + cItem.secondsDurationInArray > seconds)
           ||cItem.secondsInArray > seconds)
        {
            break;
        }
        index ++;
    }
    return index;
}
- (AudioItem *)removeVoiceItem:(AudioItem *)item
{
    if(item)
    {
        [audioList_ removeObject:item];
        [self resortAudioes];
    }
    return item;
}
- (AudioItem *)removeVoiceItemAtTime:(CGFloat)seconds
{
    AudioItem * item = nil;
    for (AudioItem * cItem in audioList_) {
        if(cItem.secondsInArray <= seconds
           && cItem.secondsInArray + cItem.secondsEnd - cItem.secondsBegin > seconds)
        {
            item = cItem;
            break;
        }
    }
    if(item)
    {
        item.secondsEnd = item.secondsBegin + seconds - item.secondsInArray;
    }
    if(item.secondsDurationInArray <MIN_AUDIOSPACE)//设定一个1秒的缓冲区，防止精度的问题
    {
        [audioList_ removeObject:item];
    }
    [self resortAudioes];
    return item;
}
- (NSArray *)removeVoiceItemAtTime:(CGFloat)secondsInArray duration:(CGFloat)durationInArray
{
    NSMutableArray * items = [NSMutableArray new];
    
    for (AudioItem * cItem in audioList_) {
        if(cItem.secondsInArray <= secondsInArray+durationInArray
           && cItem.secondsInArray + cItem.secondsDurationInArray > secondsInArray)
        {
            [items addObject:cItem];
        }
    }
    for (AudioItem * item in items) {
        if(item.secondsInArray < secondsInArray)
        {
            item.secondsEnd = item.secondsBegin + secondsInArray - item.secondsInArray;
        }
        else if(item.secondsInArray >=secondsInArray && item.secondsInArray + item.secondsDurationInArray > secondsInArray + durationInArray)
        {
            item.secondsBegin = item.secondsEnd - (secondsInArray + durationInArray - item.secondsInArray);
        }
        else
        {
            item.secondsEnd = item.secondsBegin;
        }
        if(item.secondsDurationInArray <MIN_AUDIOSPACE)//设定一个1秒的缓冲区，防止精度的问题
        {
            [audioList_ removeObject:item];
        }
    }
    [self resortAudioes];
    return PP_AUTORELEASE(items);
}

- (NSArray *)audioList
{
    return audioList_;
}
- (void)clearAudioList
{
    [audioList_ removeAllObjects];
    [self resortAudioes];
    needRegenerate_ = YES;
}

#pragma mark - add remove media
- (MediaItem *)addMediaItem:(MediaItem *)item indicatorPos:(CGFloat)posSeconds
{
    if(!item.key || item.key.length==0)
    {
        item.key = [self getKeyOfItem:item];
    }
    //    if(item.filePath && (!item.key))
    //    {
    //        item.key = [self getKeyForFile:item.filePath];
    //    }
    //    if(!item.url)
    //    {
    //        if([CommonUtil isLocalFile:item.filePath])
    //        {
    //            item.url = [NSURL fileURLWithPath:item.filePath];
    //        }
    //        else
    //            item.url = [NSURL URLWithString:item.filePath];
    //    }
    if(item.secondsDuration <=0 || item.cover==nil||item.cover.length==0)
    {
        __weak MediaEditManager * weakSelf = self;
        [self checkMedia:item thumnateSize:CGSizeMake(itemWidth_, itemHeight_) completed:^(MediaItem * mItem)
         {
             [weakSelf checkMediaDurationAndInsert:item index:-1 indicatorPos:posSeconds];
         }];
    }
    else
    {
        [self checkMediaDurationAndInsert:item index:-1 indicatorPos:posSeconds];
    }
    needRegenerate_ = YES;
    return item;
}

- (MediaItem *)insertMedia:(MediaItem *)item atIndex:(NSInteger)index indicatorPos:(CGFloat)posSeconds
{
    if(!item.key || item.key.length==0)
    {
        item.key = [self getKeyOfItem:item];
    }
    //
    //    if(item.filePath && (!item.key))
    //    {
    //        item.key = [self getKeyForFile:item.filePath];
    //    }
    //    if(!item.url)
    //    {
    //        if([CommonUtil isLocalFile:item.filePath])
    //        {
    //            item.url = [NSURL fileURLWithPath:item.filePath];
    //        }
    //        else
    //            item.url = [NSURL URLWithString:item.filePath];
    //    }
    if(item.secondsDuration <=0 || item.cover==nil||item.cover.length==0)
    {
        __weak MediaEditManager * weakSelf = self;
        [self checkMedia:item thumnateSize:CGSizeMake(itemWidth_, itemHeight_) completed:^(MediaItem * mItem)
         {
             [weakSelf checkMediaDurationAndInsert:item index:index indicatorPos:posSeconds];
         }];
    }
    else
    {
        [self checkMediaDurationAndInsert:item index:index indicatorPos:posSeconds];
    }
    needRegenerate_ = YES;
    return item;
    //    return nil;
}
- (MediaItem *)addMediaItemWithUrl:(NSURL *)url atIndex:(NSInteger)index indicatorPos:(CGFloat)posSeconds
{
    MediaItem * item = [MediaItem new];
    item.url = url;
    item.fileName = [url path];
    item.key = [self getKeyOfItem:item];
    item.cutInMode = CutInOutModeFadeIn;
    item.cutOutMode = CutInOutModeFadeOut;
    
    __weak MediaEditManager * weakSelf = self;
    [self checkMedia:item thumnateSize:CGSizeMake(itemWidth_, itemHeight_) completed:^(MediaItem * mItem)
     {
         [weakSelf checkMediaDurationAndInsert:item index:index indicatorPos:posSeconds];
     }];
    needRegenerate_ = YES;
    return PP_AUTORELEASE(item);
}
- (MediaItem *)addMediaItemWithAlAsset:(ALAsset *)alAsset atIndex:(NSInteger)index indicatorPos:(CGFloat)posSeconds
{
    if(!alAsset) return nil;
    MediaItem * item = [[MediaItem alloc]init];
    
    __weak MediaEditManager * weakSelf = self;
    [self parseItemWithALLib:alAsset mediaItem:item completed:^{
        item.cutInMode = CutInOutModeFadeIn;
        item.cutOutMode = CutInOutModeFadeOut;
        
        [weakSelf checkMedia:item thumnateSize:CGSizeMake(itemWidth_, itemHeight_) completed:^(MediaItem * mItem)
         {
             [weakSelf checkMediaDurationAndInsert:item index:index indicatorPos:posSeconds];
         }];
    }];
    
    needRegenerate_ = YES;
    return PP_AUTORELEASE(item);
}
- (NSString*)getFileNameFromALAssetUrl:(NSString *)urlString
{
    if(!urlString) return nil;
    
    NSArray * groups = [urlString arrayOfCaptureComponentsMatchedByRegex:@"id=([^&]*)&ext=([^&].*)"];
    NSLog(@"%@",[groups JSONRepresentationEx]);
    if(groups.count>0 && ((NSArray*)groups[0]).count>=2)
    {
        return [NSString stringWithFormat:@"%@.%@",groups[0][1],groups[0][2]];
    }
    else
        return urlString;
}
- (BOOL)parseItemWithALLib:(ALAsset *)alasset mediaItem:(MediaItem *)item completed:(void(^)(void))completed
{
    if(!alasset) return NO;
    if(!item)
    {
        item = [[MediaItem alloc]init];
    }
    item.alAsset = alasset;
    
    NSString * type = [alasset valueForProperty:ALAssetPropertyType];
    if([type isEqual:ALAssetTypePhoto])
    {
        item.originType = MediaItemTypeIMAGE;
        item.duration = CMTimeMakeWithSeconds(IMAGE_DURATION, IMAGE_TIMESCALE);
        item.begin = CMTimeMakeWithSeconds(0, IMAGE_TIMESCALE);
        item.end = item.duration;
        
        item.url = [alasset defaultRepresentation].url;
        //这里的Url是一个可能的Http类似的东东
        //        item.filePath = [item.url absoluteString];
        NSString * path = [self getFileNameFromALAssetUrl:[item.url absoluteString]];
        NSString * localFile = [self getTempFileName:path];
        
        CGImageRef ref = [[alasset  defaultRepresentation]fullScreenImage];
        UIImage *img = [[UIImage alloc]initWithCGImage:ref];
        
        img = [img fixOrientation];
        img = [self checkImageSizeAndSave:img isCover:NO path:localFile];
        
        
        if(localFile)
        {
            //            if([CommonUtil isExistsFile:localFile])
            //            {
            //                NSFileManager *fileManager = [NSFileManager defaultManager];
            //                NSError * error = nil;
            //                [fileManager removeItemAtPath:localFile error:&error];
            //                if(error)
            //                {
            //                    NSLog(@"delete file:%@ error:%@",localFile,[error localizedDescription]);
            //                }
            //            }
            //
            //            [UIImageJPEGRepresentation(img,1.0f) writeToFile:localFile atomically:YES];
            
            item.fileName = localFile;
            item.url = [NSURL fileURLWithPath:localFile];
            item.cover = localFile;
            //            if(!item.key||item.key.length==0)
            //            {
            //                item.key = [self getKeyOfItem:item];
            //            }
            //            item.key = [self getKeyForFile:item.filePath];
        }
        else
        {
            item.fileName = [[HCFileManager manager]getFileName:localFile];
        }
        if(!item.key||item.key.length==0)
        {
            item.key = [self getKeyOfItem:item];
        }
        if(self.backgroundVideo)
            item.renderSize  = self.backgroundVideo.renderSize;
        dispatch_async(dispatch_get_main_queue(), ^{
            if(completed)
            {
                completed();
            }
        });
        
    }
    else if([type isEqual:ALAssetTypeVideo])
    {
        item.originType = MediaItemTypeVIDEO;
        item.url = [alasset defaultRepresentation].url;
        item.fileName = [item.url path];
        NSString * nsALAssetPropertyDuration = [alasset valueForProperty:ALAssetPropertyDuration];
        item.duration = CMTimeMakeWithSeconds([nsALAssetPropertyDuration doubleValue], IMAGE_TIMESCALE);
        item.begin = CMTimeMakeWithSeconds(0, IMAGE_TIMESCALE);
        item.end = item.duration;
        
        //        NSString * localFile = [self getTempFileName:[NSString stringWithFormat:@"%@.jpg",item.filePath]];
        //        if(localFile)
        //        {
        //            if([CommonUtil isExistsFile:localFile])
        //            {
        //                NSFileManager *fileManager = [NSFileManager defaultManager];
        //                NSError * error = nil;
        //                [fileManager removeItemAtPath:localFile error:&error];
        //                if(error)
        //                {
        //                    NSLog(@"delete file:%@ error:%@",localFile,[error localizedDescription]);
        //                }
        //            }
        //            UIImage *img = [[UIImage alloc]initWithCGImage:alasset.thumbnail];
        //            [UIImageJPEGRepresentation(img,1.0f) writeToFile:localFile atomically:YES];
        //            item.cover = localFile;
        //        }
        if(!item.key || item.key.length==0)
            item.key = [self getKeyOfItem:item];
        
        [self copyMTVFromAlbum:item.url extInfo:[item.fileName pathExtension] completed:^(BOOL finished, NSString *localFile, NSString *coverPath) {
            [item setFileName:localFile];
            item.cover = coverPath;
            item.url = [NSURL fileURLWithPath:localFile];
            if(completed)
            {
                completed();
            }
        }];
    }
    return YES;
}
- (MediaItem *)addMediaItemWithFile:(NSString *)filePath atIndex:(NSInteger)index indicatorPos:(CGFloat)posSeconds
{
    if(![HCFileManager isExistsFile:filePath]) return nil;
    
    MediaItem * item = [MediaItem new];
    item.fileName = filePath;
    
    item.key = [self getKeyOfItem:item];
    __weak MediaEditManager * weakSelf = self;
    [self checkMedia:item thumnateSize:CGSizeMake(itemWidth_, itemHeight_) completed:^(MediaItem * mItem)
     {
         [weakSelf checkMediaDurationAndInsert:item index:index indicatorPos:posSeconds];
     }];
    
    //
    //    if([CommonUtil isImageFile:filePath])
    //    {
    //        item.duration = CMTimeMake(6, 1);
    //        item.isImg = YES;
    //        item.cover = filePath;
    //    }
    //    else
    //    {
    //        AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:filePath] options:nil];
    //        item.duration = asset.duration;
    //    }
    //    if(index<0||index >= mediaList_.count)
    //    {
    //        [self addMediaItem:item];
    //    }
    //    else
    //    {
    //        [self insertMedia:item atIndex:index];
    //    }
    return PP_AUTORELEASE(item);
}
- (void)checkMediaDurationAndInsert:(MediaItem *)item index:(NSInteger)index indicatorPos:(CGFloat)posSeconds
{
    if(!item) return;
    CGFloat secondsBegin = 0;
    CGFloat secondsDuration = 0;
    //插入对像必须同步，否则会有冲突
    @synchronized(self) {
        secondsBegin = [self getIndexScope:index itemDuration:(CGFloat)item.secondsDuration indicatorPos:posSeconds duration:&secondsDuration];
        if(secondsDuration>0)
        {
            item.timeInArray = CMTimeMakeWithSeconds(secondsBegin, item.duration.timescale);
            
            //必须与原文件等长，所以这里注释了根据空间大小来添加对像时长的代码
            //        if(secondsDuration < item.secondsDuration)
            //        {
            //            item.begin = CMTimeMakeWithSeconds(0, item.duration.timescale);
            //            item.end = CMTimeMakeWithSeconds(secondsDuration, item.duration.timescale);
            //        }
            //        else
            //        {
            item.begin = CMTimeMakeWithSeconds(0, item.duration.timescale);
            if(secondsDuration >= item.secondsDuration)
                item.end = item.duration;
            else
                item.end = CMTimeMakeWithSeconds(secondsDuration, item.duration.timescale);
            //        }
            
        }
        else    //超过边界了，则加在边界右侧
        {
            item.timeInArray = CMTimeMakeWithSeconds(secondsBegin, item.duration.timescale);
            item.begin= CMTimeMakeWithSeconds(0, item.duration.timescale);
            item.end = item.duration;
            totalSecondsDurationByFullItems_ += item.secondsDurationInArray;
        }
        
        //插入到合适的位置
        {
            int insertIndex = 0;
            for (MediaItem * cItem in mediaList_) {
                if(cItem.secondsInArray >= item.secondsInArray)
                {
                    break;
                }
                insertIndex ++;
            }
            [mediaList_ insertObject:item atIndex:insertIndex];
            
            [[MediaListModel shareObject]addMediaItem:item atIndex:insertIndex];
        }
        [self resort];
    }
    //    if(item.isImg)
    //    {
    //        [[MediaListModel shareObject]generateImage2Video:item];
    ////        [generateQueue_ generateImage2Video:[self toPlayerMediaItem:item]];
    //    }
    needRegenerate_ = YES;
}

- (BOOL)getDurationAndThumnateTimes:(MediaItem *)item completed:(GenerateThumnates)completed
{
    WTPlayerResource * wtp = [WTPlayerResource sharedWTPlayerResource];
    item.originType = MediaItemTypeVIDEO;
    if(item.secondsDuration <=0)
    {
        item.duration = [wtp getDuration:item.url];
    }
    CGFloat totalSeconds = CMTimeGetSeconds(totalDuration);
    if(totalSeconds <=0)
    {
        //        totalSeconds = TOTALSECONDS_DEFAULT;
        NSLog(@"operation error,not set totalduration");
        return NO;
    }
    
    CGFloat width = 0;
    if(contentWidth_<=0)
        width = item.secondsDurationInArray * CONTENTWIDTH_PERSECOND;
    else
        width = item.secondsDurationInArray/totalSeconds * contentWidth_;
    int count = MAX(1,width/itemWidth_);
    
    CGFloat step = item.secondsDurationInArray/count;
    
    if(width - count * itemWidth_ >0) count ++;
    if(item.videoThumnateFilePaths.count>=count)
    {
        item.videoThumnateFilesCount = (int)item.videoThumnateFilePaths.count;
        if(!item.cover || item.cover.length==0)
        {
            item.cover = [item.videoThumnateFilePaths objectAtIndex:0];
        }
        if(completed)
        {
            completed(item,YES);
        }
    }
    else
    {
        item.videoThumnateFilesCount = 0;
        [item.videoThumnateFilePaths removeAllObjects];
    }
    item.isGenerating = YES;
    CGFloat begin = CMTimeGetSeconds(item.begin);
    CGFloat end = CMTimeGetSeconds(item.end);
    CGFloat scale = [DeviceConfig config].Scale;
    BOOL ret = [wtp getVideoThumbs:item.url
//                           alAsset:item.alAsset
            targetThumnateFileName:item.key
                             begin:begin andEnd:end andStep:step andCount:count
                           andSize:CGSizeMake(itemWidth_* scale, itemHeight_*scale)
                          callback:^(CMTime requestTime,NSString* path,NSInteger index)
                {
                    if(item)
                    {
                        if((index==0 || index==1) && (item.cover==nil||item.cover.length==0))
                        {
                            item.cover = path;
                        }
                        if(!item.videoThumnateFilePaths)
                        {
                            item.videoThumnateFilePaths = PP_AUTORELEASE([NSMutableArray new]);
                        }
                        [item.videoThumnateFilePaths addObject:path];
                        item.videoThumnateFilesCount ++;
                    }
                }
                         completed:^(CMTime requestTime,NSString* path,NSInteger index)
                {
                    //排序，让显示的时候按顺序
                    if(item)
                    {
                        if((!item.cover || item.cover.length==0) && item.videoThumnateFilePaths.count>0)
                        {
                            item.cover = [item.videoThumnateFilePaths objectAtIndex:0];
                        }
                        [item.videoThumnateFilePaths sortUsingComparator:^NSComparisonResult(id obj1,id obj2)
                         {
                             NSString * file1 = (NSString*)obj1;
                             NSString * file2 = (NSString *)obj2;
                             return [file1 compare:file2 options:NSCaseInsensitiveSearch];
                         }];
                    }
                    item.isGenerating = NO;
                    if(completed)
                    {
                        completed(item,YES);
                    }
                }
                           failure:^(CMTime requestTime,NSError *error,NSString *filePath)
                {
                    if((!item.cover || item.cover.length==0) && item.videoThumnateFilePaths.count>0)
                    {
                        item.cover = [item.videoThumnateFilePaths objectAtIndex:0];
                    }
                    [item.videoThumnateFilePaths sortUsingComparator:^NSComparisonResult(id obj1,id obj2)
                     {
                         NSString * file1 = (NSString*)obj1;
                         NSString * file2 = (NSString *)obj2;
                         return [file1 compare:file2 options:NSCaseInsensitiveSearch];
                     }];
                    item.isGenerating = NO;
                    if(completed)
                        completed(item,NO);
                }
                ];
    if(!ret)
    {
        return NO;
    }
    return YES;
}
//删除超过边界的对像
- (NSArray *)removeMediaItemsOverflow
{
    NSMutableArray * removedList = [NSMutableArray new];
    for (int i = 0; i<mediaList_.count; i++) {
        MediaItem * item = [mediaList_ objectAtIndex:i];
        if(item.secondsInArray < totalSecondsDuration_)
        {
            
        }
        else
        {
            [removedList addObject:item];
        }
    }
    for (MediaItem * item in removedList) {
        [mediaList_ removeObject:item];
        [[MediaListModel shareObject]removeMediaItem:item];
    }
    return PP_AUTORELEASE(removedList);
}

- (void)checkRemoveImageVideoFiles:(MediaItem *)item
{
    BOOL isfind = NO;
    for (MediaItem * cItem in mediaList_) {
        if(cItem == item || cItem.url.absoluteString==item.url.absoluteString)
        {
            isfind = YES;
            break;
        }
    }
    if(!isfind)
    {
        [[MediaListModel shareObject]removeMediaItem:item];
        //        [generateQueue_ removeImageVideo:[self toPlayerMediaItem:item]];
    }
}
- (MediaItem *)removeMediaItem:(MediaItem *)item
{
    if(item)
    {
        [mediaList_ removeObject:item];
        [self resort];
        [self checkRemoveImageVideoFiles:item];
    }
    needRegenerate_ = YES;
    return item;
}
- (MediaItem *)removeMediaItemByTagID:(NSInteger)tagID
{
    MediaItem * item = [self getMediaItemByTagID:tagID];
    if(item)
    {
        [self removeMediaItem:item];
        [self syncSecondsByFrame];
    }
    needRegenerate_ = YES;
    return item;
}
- (NSArray *)removeMediaItemsAtTime:(CMTime)time duration:(CGFloat)vduration
{
    CGFloat seconds = CMTimeGetSeconds(time);
    NSArray * items = [self getMediaItemsAtTime:time duration:vduration];
    if(items && items.count>0)
    {
        NSMutableArray * removeList = [NSMutableArray new];
        for (MediaItem * item in items) {
            if(item.secondsInArray < seconds)
            {
                item.end = CMTimeMakeWithSeconds(item.secondsBegin + seconds - item.secondsInArray, item.duration.timescale) ;
            }
            else if(item.secondsInArray >=seconds && item.secondsInArray + item.secondsEnd - item.secondsBegin > seconds + vduration)
            {
                item.begin = CMTimeMakeWithSeconds(item.secondsEnd - (seconds + vduration - item.secondsInArray),item.duration.timescale);
            }
            else
            {
                item.end = item.end;
            }
            if(item.secondsDurationInArray < 1) //设定一个1秒的缓冲区，防止精度的问题
            {
                [removeList addObject:item];
                //                [mediaList_ removeObject:item];
            }
        }
        [mediaList_ removeObjectsInArray:removeList];
        
        [self resort];
        
        for (MediaItem * item  in items) {
            [self checkRemoveImageVideoFiles:item];
        }
        removeList = nil;
        needRegenerate_ = YES;
    }
    
    return items;
}
- (NSArray *)getMediaItemsAtTime:(CMTime)time duration:(CGFloat)vduration
{
    NSMutableArray * items = [NSMutableArray new];
    CGFloat seconds = CMTimeGetSeconds(time);
    
    for (MediaItem * cItem in mediaList_) {
        
        if(cItem.secondsInArray <= seconds+vduration
           && cItem.secondsInArray + cItem.secondsEnd - cItem.secondsBegin > seconds)
        {
            [items addObject:cItem];
        }
    }
    //    for (MediaItem * item in items) {
    //        if(item.secondsInArray < seconds)
    //        {
    //            item.end = CMTimeMakeWithSeconds(item.secondsBegin + seconds - item.secondsInArray, item.duration.timescale) ;
    //        }
    //        else if(item.secondsInArray >=seconds && item.secondsInArray + item.secondsEnd - item.secondsBegin > seconds + vduration)
    //        {
    //            item.begin = CMTimeMakeWithSeconds(item.secondsEnd - (seconds + vduration - item.secondsInArray),item.duration.timescale);
    //        }
    //        else
    //        {
    //            item.end = item.end;
    //        }
    //        if(item.secondsDurationInArray < 1) //设定一个1秒的缓冲区，防止精度的问题
    //        {
    //            [mediaList_ removeObject:item];
    //        }
    //    }
    return PP_AUTORELEASE(items);
}

//获取指定空隙的大小及位置
- (CGFloat)getEmptyScope:(NSInteger )index itemDuration:(CGFloat)itemDuration duration:(CGFloat *)duration
{
    BOOL isFound = NO;
    NSInteger tempIndex = 0;
    CGFloat prevSeconds = 0;
    CGFloat secondsBegin = -1;
    (* duration) = 0;
    
    for (MediaItem * cItem in mediaList_) {
        
        //如果有空隙
        if(cItem.secondsInArray > prevSeconds)
        {
            secondsBegin = prevSeconds;
            *duration = cItem.secondsInArray - prevSeconds;
            if(*duration >1)
            {
                
                if(tempIndex >= index)
                {
                    isFound = YES;
                    break;
                }
                tempIndex ++;
                prevSeconds += *duration;
            }
        }
        prevSeconds = cItem.secondsBegin + cItem.secondsDurationInArray;
    }
    if(!isFound)
    {
        CGFloat totalSeconds = CMTimeGetSeconds(totalDuration);
        if(prevSeconds < totalSeconds)
        {
            secondsBegin = prevSeconds;
            * duration = totalSeconds -  prevSeconds;
        }
        else
        {
            *duration = 0;
            secondsBegin = totalSeconds;
        }
    }
    return secondsBegin;
}
- (NSArray *)getSpaceBetweenMediaItems
{
    NSMutableArray * spaceList = [NSMutableArray new];
    CGFloat prevSeconds = 0;
    NSInteger tempIndex = 0;
    for (MediaItem * cItem in mediaList_) {
        //如果有空隙
        if(cItem.secondsInArray > prevSeconds)
        {
            CGFloat secondsBegin = prevSeconds;
            CGFloat duration = cItem.secondsInArray - prevSeconds;
            if(duration >1)
            {
                [spaceList addObject:[
                                      NSDictionary dictionaryWithObjectsAndKeys:@(tempIndex),@"index",
                                      @(secondsBegin),@"begin",
                                      @(duration),@"duration",nil
                                      ]];
            }
        }
        prevSeconds = cItem.secondsInArray + cItem.secondsDurationInArray;
        tempIndex ++;
    }
    CGFloat td =CMTimeGetSeconds(totalDuration);
    if(prevSeconds < td-1 )
    {
        [spaceList addObject:[
                              NSDictionary dictionaryWithObjectsAndKeys:@(tempIndex),@"index",
                              @(prevSeconds),@"begin",
                              @(td - prevSeconds),@"duration",nil
                              ]];
    }
    return PP_AUTORELEASE(spaceList);
}
//获取指定位置的大小及位置（包含空隙）
- (CGFloat)getIndexScope:(NSInteger )index itemDuration:(CGFloat)itemDuration indicatorPos:(CGFloat)posSeconds duration:(CGFloat *)duration
{
    BOOL isFound = NO;
    //    NSInteger tempIndex = 0;
    CGFloat prevSeconds = 0;
    CGFloat secondsBegin = -1;
    (* duration) = 0;
    
    CGFloat totalSeconds = CMTimeGetSeconds(totalDuration);
    NSArray * spaceList = [self getSpaceBetweenMediaItems];
    
    //如果索引值有效，则根据索引值，寻找可用的空格，作为加入位置
    if(index>=0 )
    {
        for (NSDictionary * dic in spaceList) {
            if([[dic objectForKey:@"index"]integerValue]==index)
            {
                isFound = YES;
                prevSeconds = [[dic objectForKey:@"begin"]floatValue];
                *duration = [[dic objectForKey:@"duration"]floatValue];
            }
        }
    }
    
    if(!isFound)
    {
        CGFloat lastSpaceDuration = 99999999;
        NSDictionary * lastSpaceItem = nil;
        if(itemDuration>0)
        {
            //没有指定加入的位置
            if(posSeconds<0 && posSeconds <totalSeconds)
            {
                for (NSDictionary * dic in spaceList) {
                    CGFloat dicDuration = [[dic objectForKey:@"duration"] floatValue];
                    if( dicDuration > itemDuration && dicDuration < lastSpaceDuration)
                    {
                        lastSpaceDuration = dicDuration;
                        lastSpaceItem = dic;
                    }
                }
                if(lastSpaceItem)
                {
                    isFound = YES;
                    secondsBegin = [[lastSpaceItem objectForKey:@"begin"]floatValue];
                    *duration = [[lastSpaceItem objectForKey:@"duration"]floatValue];
                }
            }
            //指定了加入的位置，则需要将对像强行加入
            else
            {
                secondsBegin = posSeconds;
                *duration = MIN(itemDuration,totalSeconds - posSeconds);
                //如果与之前的对像交叉，则需要修改前一个对像的长度
                //                BOOL before = YES;
                CGFloat prevSecondsBegin = secondsBegin;
                for (int i = 0; i<mediaList_.count; i++) {
                    MediaItem * item = mediaList_[i];
                    //有交叉
                    if(item.secondsInArray < prevSecondsBegin && item.secondsInArray + item.secondsDurationInArray >prevSecondsBegin)
                    {
                        //同时加入，还没有生成
                        if(!item.contentView)
                        {
                            prevSecondsBegin = item.secondsInArray + item.secondsDurationInArray;
                        }
                        else
                        {
                            item.end = CMTimeMakeWithSeconds(prevSecondsBegin - item.secondsInArray + item.secondsBegin, item.end.timescale);
                        }
                    }
                    else if(item.secondsInArray >= prevSecondsBegin)
                    {
                        break;
                    }
                    
                }
                isFound = YES;
            }
            
        }
        
        if(!isFound)
        {
            if(spaceList.count>0)
            {
                isFound = YES;
                NSDictionary * dic = [spaceList firstObject];
                
                secondsBegin = [[dic objectForKey:@"begin"]floatValue];
                *duration = [[dic objectForKey:@"duration"]floatValue];
            }
        }
    }
    
    if(!isFound)
    {
        *duration = 0 - itemDuration;
        if(totalSecondsDurationByFullItems_ < totalSeconds)
        {
            totalSecondsDurationByFullItems_ = totalSeconds;
        }
        secondsBegin = totalSecondsDurationByFullItems_;
        //        }
    }
    //    //长度不够，则需要检查在此对像之后，是否还有空间，从尾部逐一缩减空白区域，直至能完整地放下整个视频
    //    if(*duration < itemDuration)
    //    {
    //    }
    return secondsBegin;
}
- (MediaItem *)getMediaItemAtTime:(CMTime)time
{
    MediaItem * item = nil;
    CGFloat currentSeconds = CMTimeGetSeconds(time);
    for (MediaItem * cItem in mediaList_) {
        if(currentSeconds >=cItem.secondsInArray
           && currentSeconds <=cItem.secondsInArray+cItem.secondsDurationInArray)
        {
            item = cItem;
            break;
        }
    }
    return item;
}
//根据Frame重新设定对像的时间
- (void) syncSecondsByFrame
{
    if(contentWidth_<=0) return;
    CGFloat totalSeconds = CMTimeGetSeconds(totalDuration);
    
    for (MediaItem * item in mediaList_) {
        CGFloat pos = item.targetFrame.origin.x / contentWidth_;
        CGFloat duration = item.targetFrame.size.width /contentWidth_;
        
        CGFloat secondsInArray = round(pos * totalSeconds * 100)/100;
        CGFloat secondsDuration = round(duration * totalSeconds * 100)/100;
        
        CGFloat orgSecondsInArray = CMTimeGetSeconds(item.timeInArray);
        if(orgSecondsInArray - secondsInArray >0.04 || orgSecondsInArray - secondsInArray <0.04)
        {
            item.timeInArray = CMTimeMakeWithSeconds(secondsInArray, item.timeInArray.timescale);
        }
        
        CGFloat orgDurationInArray = item.secondsDurationInArray;
        
        //移动一定位置
        if(orgDurationInArray - secondsDuration >0.04 || orgDurationInArray - secondsDuration <0.04)
        {
            CGFloat begin = CMTimeGetSeconds(item.begin);
            //长度够
            if(item.secondsDuration >= secondsDuration)
            {
                //尾部未用区间够
                if(begin + secondsDuration <= item.secondsDuration)
                {
                    item.end = CMTimeMakeWithSeconds(begin + secondsDuration, item.duration.timescale);
                }
                //尾部未用区间不够，将开始前移
                else
                {
                    item.end = item.duration;
                    item.begin = CMTimeMakeWithSeconds(MAX(0,item.secondsDuration - secondsDuration), item.duration.timescale);
                }
            }
            //整体长度不够
            else
            {
                item.begin = CMTimeMakeWithSeconds(0, item.duration.timescale);
                //图片可以变长度
                if(item.isImg)
                {
                    item.duration = CMTimeMakeWithSeconds(secondsDuration, item.duration.timescale);
                    item.end = item.duration;
                }
            }
        }
    }
    needRegenerate_ = YES;
}
#pragma mark - clear,tojson...
- (NSURL*)getAudioUrl
{
    return videoGenerater_.joinAudioUrl;
}
- (NSURL *)getAuMixed
{
    return audioMixUrl_;
}
- (void)setNeedRegenerate
{
    needRegenerate_ = YES;
}
- (BOOL)needRegenerate
{
    if(needRegenerate_) return YES;
    if(fabs(singVolume_ - orgSingVolumne_)>=0.05
       ||
       fabs(playVolumeWhenRecord_ - orgBgVolume_)>=0.05)
    {
        needRegenerate_ = YES;
    }
    if(!needRegenerate_)
    {
        AVPlayerItem * item = [self getPlayerItem];
        if(item && item.status==AVPlayerItemStatusReadyToPlay)
        {
            return NO;
        }
    }
    return YES;
}

//获取当前资源文件的Key，因为在整个管理中，可能同一个文件出现两次或多次，因此不能简单地用文件名来处理
- (NSString *)getKeyForFile:(NSString *)filePath
{
    if(!filePath) return  nil;
    return [HCFileManager getMD5FileNameKeepExt:[filePath lastPathComponent] defaultExt:nil];
    //    NSInteger index = 0;
    //    for (MediaItem * item in mediaList_) {
    //        if([item.filePath isEqualToString:filePath])
    //        {
    //            index ++;
    //        }
    //    }
    //    return [CommonUtil md5Hash:[NSString stringWithFormat:@"%@-%d",filePath,(int)index]];
}

- (NSString *)getKeyOfItem:(MediaItem *)item
{
    if(!item) return @"";
    NSString * key = nil;
    if(item.filePath)
    {
        key =   [self getKeyForFile:item.filePath];
    }
    else
    {
        if([HCFileManager isInAblum:item.url.absoluteString])
        {
            key = [self getFileNameFromALAssetUrl:item.url.absoluteString];
        }
        key =  [self getKeyForFile:item.url.absoluteString];
    }
    //加上生成序号，防止多个同样的文件出现问题
    return [NSString stringWithFormat:@"%@-%ld",key?key:@"",[CommonUtil getDateTicks:[NSDate date]]];
}
- (void)resort
{
    NSInteger index = 0;
    //    CGFloat totalSeconds = CMTimeGetSeconds(totalDuration);
    CGFloat prevSeconds = 0;
    NSMutableArray *removeList = [NSMutableArray new];
    for (MediaItem * cItem in mediaList_) {
        //        cItem.key = [NSString stringWithFormat:@"%i",(int)index];
        CGFloat diff = cItem.secondsInArray - prevSeconds;
        //对齐，逐个后延
        if(diff < MIN_AUDIOSPACE)
        {
            cItem.timeInArray = CMTimeMakeWithSeconds(prevSeconds, cItem.duration.timescale);
        }
        //在显示范围内的调整，之外不处理
        if(cItem.secondsInArray < totalSecondsDuration_ && cItem.secondsDurationInArray + cItem.secondsInArray > totalSecondsDuration_ && totalSecondsDuration_>0)
        {
            cItem.end = CMTimeMakeWithSeconds(cItem.secondsBegin + (totalSecondsDuration_ - cItem.secondsInArray), cItem.duration.timescale);
            ;
        }
        else if(cItem.secondsInArray >= totalSecondsDuration_ && totalSecondsDuration_>0)
        {
            totalSecondsDurationByFullItems_ = MAX(totalSecondsDurationByFullItems_,cItem.secondsDurationInArray + cItem.secondsInArray);
            [removeList addObject:cItem];
        }
        
        if(!cItem.key || cItem.key.length==0)
        {
            cItem.key = [self getKeyOfItem:cItem];
        }
        prevSeconds = cItem.secondsInArray + cItem.secondsDurationInArray;
        index ++;
    }
    if(removeList.count>0)
    {
        [mediaList_ removeObjectsInArray:removeList];
        totalSecondsDurationByFullItems_ = totalSecondsDuration_;
    }
    PP_RELEASE(removeList);
}
- (NSString *)toJson
{
    [self resortAudioes];
    [self resort];
    
    
    NSMutableDictionary * dic =[NSMutableDictionary new];
    [dic setObject:mediaList_ forKey:@"media"];
    [dic setObject:audioList_ forKey:@"audio"];
    [dic setObject:[NSNumber numberWithLongLong:SampleID]forKey:@"sampleid"];
    [dic setObject:[NSNumber numberWithLongLong:MTVID]forKey:@"mtvid"];
    [dic setObject:[NSNumber numberWithLongLong:MBMTVID]forKey:@"mbmtvid"];
    if(MTVTitle)
        [dic setObject:MTVTitle forKey:@"mtvtitle"];
    
    [dic setObject:[NSNumber numberWithLongLong:totalDuration.value]forKey:@"totaldurationvalue"];
    [dic setObject:[NSNumber numberWithInteger:totalDuration.timescale] forKey:@"totaldurationtimescale"];
    [dic setObject:NSStringFromCGSize(renderSize) forKey:@"rendersize"];
    if(backgroundVideo)
        [dic setObject:backgroundVideo forKey:@"backgroundvideo"];
    if(backgroundAudio)
        [dic setObject:backgroundAudio forKey:@"backgroundaudio"];
    if(coverImageUrl)
    {
        [dic setObject:coverImageUrl forKey:@"coverimageurl"];
    }
    //关于视频方向及大小
    //    int deviceOrietation_;//视频方向
    //
    //    NSArray * lyricList_;   //解析好的歌词列表
    //    CGFloat lyricBegin_;    //视频开始时，歌词对应的位置
    //    CGFloat lyricDuration_; //歌词总共显示多少时间
    //    NSString * waterMarkFile_;//水印图标
    //    CGFloat mergeRate_;     //合成Rate，可以加速合成
    [dic setObject:[NSNumber numberWithInt:deviceOrietation_] forKey:@"deviceorientation"];
    [dic setObject:[NSNumber numberWithFloat:lyricDuration_] forKey:@"lyricduration"];
    
    [dic setObject:[NSNumber numberWithFloat:lyricBegin_] forKey:@"lyricbegin"];
    if(lyricList_ && lyricList_.count>0)
    {
        [dic setObject:lyricList_ forKey:@"lyriclist"];
    }
    [dic setObject:[NSNumber numberWithFloat:mergeRate_] forKey:@"mergerate"];
    if(waterMarkFile_)
    {
        [dic setObject:waterMarkFile_ forKey:@"watermarkfile"];
    }
    
    NSString * json = [dic JSONRepresentationEx];
    PP_RELEASE(dic);
    return json;
}
- (void)parseJson:(NSString *)json
{
    if(!json ||json.length==0) return;
    
    NSDictionary * dic = [json JSONValueEx];
    if(!dic || dic.allKeys.count==0) return;
    
    //    [self clear];
    
    id item = [dic objectForKey:@"totaldurationvalue"];
    if (item ) {
        totalDuration = CMTimeMake([item integerValue], (int32_t)[[dic objectForKey:@"totaldurationtimescale"]integerValue]);
    }
    item = [dic objectForKey:@"rendersize"];
    if(item)
    {
        renderSize =CGSizeFromString(item);
    }
    if([dic objectForKey:@"sampleid"])
    {
        SampleID = (long)[[dic objectForKey:@"sampleid"]longLongValue];
    }
    if([dic objectForKey:@"mtvid"])
    {
        MTVID = (long)[[dic objectForKey:@"mtvid"]longLongValue];
    }
    if([dic objectForKey:@"mbmtvid"])
    {
        MBMTVID = (long)[[dic objectForKey:@"mbmtvid"]longLongValue];
    }
    if([dic objectForKey:@"mtvtitle"])
    {
        MTVTitle = PP_RETAIN([dic objectForKey:@"mtvtitle"]);
    }
    
    if([dic objectForKey:@"media"])
    {
        NSArray * array = [dic objectForKey:@"media"];
        for (NSDictionary * itemDic in array) {
            MediaItem * media = [[MediaItem alloc]initWithDictionary:itemDic];
            [mediaList_ addObject:media];
        }
    }
    if([dic objectForKey:@"audio"])
    {
        NSArray * array = [dic objectForKey:@"audio"];
        for (NSDictionary * itemDic in array) {
            AudioItem * media = [[AudioItem alloc]initWithDictionary:itemDic];
            [audioList_ addObject:media];
        }
    }
    if([dic objectForKey:@"backgroundaudio"])
    {
        AudioItem * media = [[AudioItem alloc]initWithDictionary:[dic objectForKey:@"backgroundaudio"]];
        backgroundAudio = media;
        
    }
    if([dic objectForKey:@"backgroundvideo"])
    {
        MediaItem * media = [[MediaItem alloc]initWithDictionary:[dic objectForKey:@"backgroundvideo"]];
        backgroundVideo = media;
    }
    if([dic objectForKey:@"coverimageurl"])
    {
        PP_RELEASE(coverImageUrl);
        coverImageUrl = PP_RETAIN([dic objectForKey:@"coverimageurl"]);
    }
    
    if([dic objectForKey:@"deviceorientation"])
    {
        deviceOrietation_ = [[dic objectForKey:@"deviceorientation"]intValue];
    }
    
    if([dic objectForKey:@"lyricduration"])
    {
        lyricDuration_ = [[dic objectForKey:@"lyricduration"]floatValue];
    }
    if([dic objectForKey:@"lyricbegin"])
    {
        lyricBegin_ = [[dic objectForKey:@"lyricbegin"]floatValue];
    }
    if([dic objectForKey:@"mergerate"])
    {
        mergeRate_ = [[dic objectForKey:@"mergerate"]floatValue];
    }
    if([dic objectForKey:@"watermarkfile"])
    {
        waterMarkFile_ = [dic objectForKey:@"watermarkfile"];
    }
    if([dic objectForKey:@"lyriclist"])
    {
        NSMutableArray * lyricList = [NSMutableArray new];
        NSArray * array = [dic objectForKey:@"lyriclist"];
        for (NSDictionary * itemDic in array) {
            LyricItem * lyricItem = [[LyricItem alloc]initWithDictionary:itemDic];
            [lyricList addObject:lyricItem];
        }
        lyricList_ = lyricList;
    }
    
    [self resortAudioes];
    [self resort];
}
- (void)clearMediaList
{
    [mediaList_ removeAllObjects];
    [self resort];
    [[MediaListModel shareObject]clear];
    needRegenerate_ = YES;
}
#pragma mark - check point
- (void)checkPoint
{
    NSError * error = nil;
    NSString * fileName = [[UDManager sharedUDManager]tempFileFullPath:@"mediacheckpoint.txt"];
    NSFileManager * fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:fileName])
    {
        
        if(![fm removeItemAtPath:fileName error:&error])
        {
            NSLog(@"error:%@",[error localizedDescription]);
            return;
        }
    }
    NSString * json = [self toJson];
    if(![json writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:&error])
    {
        NSLog(@"wite json error:%@",[error localizedDescription]);
    }
}
- (NSArray *)getMediaItemsLastCheckPoint
{
    NSString * json = [self getLastCheckpointString];
    NSDictionary * dic = [json JSONValueEx];
    if(!dic || dic.allKeys.count==0)
    {
        return [NSArray array];
        //        return nil;
    }
    NSMutableArray * mediaList = [NSMutableArray new];
    if([dic objectForKey:@"media"])
    {
        NSArray * array = [dic objectForKey:@"media"];
        for (NSDictionary * itemDic in array) {
            MediaItem * media = [[MediaItem alloc]initWithDictionary:itemDic];
            [mediaList addObject:media];
        }
    }
    return PP_AUTORELEASE(mediaList);
}
- (NSString *)getLastCheckpointString
{
    NSError * error = nil;
    NSString * fileName = [[UDManager sharedUDManager]tempFileFullPath:@"mediacheckpoint.txt"];
    NSFileManager * fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:fileName])
    {
        NSLog(@"file %@ not exists",fileName);
        return nil;
    }
    NSStringEncoding encoding = NSUTF8StringEncoding;
    NSString * json = [NSString stringWithContentsOfFile:fileName usedEncoding:&encoding error:&error];
    if(error)
    {
        NSLog(@"read file failure:%@",[error localizedDescription]);
        return nil;
    }
    return json;
}
- (void)restoreLastCheckPoint
{
    NSString * json = [self getLastCheckpointString];
    if(json)
    {
        [self parseJson:json];
    }
}
- (NSString * )getTempFileName:(NSString *)filePath
{
    if(!filePath) return nil;
    NSString * lastName = [HCFileManager getMD5FileNameKeepExt:[filePath lastPathComponent] defaultExt:nil];;
    NSString * localFile = [[UDManager sharedUDManager]tempFileFullPath:lastName];
    return localFile;
}
- (BOOL) isInTempDir:(NSString *)filePath
{
    NSString * tempDir = [[UDManager sharedUDManager]localFileFullPath:nil];
    if([filePath rangeOfString:tempDir].length >0)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}
- (void)checkMedia:(MediaItem *)mItem thumnateSize:(CGSize)tSize completed:(CheckMedia)completed
{
    if(!mItem.url && mItem.filePath)
    {
        if([HCFileManager isLocalFile:mItem.filePath])
        {
            mItem.url = [NSURL fileURLWithPath:[HCFileManager checkPath:mItem.filePath]];
        }
        else
        {
            mItem.url = [NSURL URLWithString:mItem.filePath];
        }
    }
    if(!mItem.url)
    {
        NSLog(@"**** no url,cannot continue ****");
        return;
    }
    else if(!mItem.fileName)
    {
        mItem.fileName = [mItem.url path];
    }
    if(!mItem.key || mItem.key.length==0)
    {
        mItem.key = [self getKeyOfItem:mItem];
    }
    if(!mItem.isImg || CGSizeEqualToSize(mItem.renderSize,CGSizeZero))
    {
        mItem.renderSize = self.renderSize;
    }
    __weak typeof (mItem) weakItem = mItem;
    if([HCFileManager isInAblum:weakItem.filePath])
    {
        if(weakItem.alAsset && weakItem.isImg == NO)
        {
            //            if(CMTimeGetSeconds(weakItem.duration)==0)
            __weak MediaEditManager * weakSelf = self;
            [self getDurationAndThumnateTimes:weakItem completed:^(MediaItem * item,BOOL isSuccess)
             {
                 if(item && item.contentView)
                 {
                     CGFloat itemWidth = item.lastFrame.size.width;
                     if(itemWidth<=0) itemWidth = item.contentView.frame.size.width;
                     dispatch_async(dispatch_get_main_queue(), ^(void) {
                         [weakSelf buildSnapeImageViews:item snapWidth:itemWidth_ itemViewWidth:itemWidth];
                     });
                 }
                 if(completed)
                     completed(item);
             }];
        }
        else if(!weakItem.alAsset)
        {
            NSLog(@"**** error ****:alasset cannot be null");
        }
        else
        {
            NSString * path = [self getFileNameFromALAssetUrl:[weakItem.url absoluteString]];
            NSString * localFile = [self getTempFileName:path];;
            [self copyPhotoFromAlbum:weakItem.url withFilePath:localFile completed:^(BOOL finisehd)
             {
                 completed(weakItem);
             }];
        }
    }
    else if([HCFileManager isImageFile:mItem.filePath])
    {
        mItem.duration = CMTimeMakeWithSeconds(IMAGE_DURATION, IMAGE_TIMESCALE);
        mItem.originType = MediaItemTypeIMAGE;
        mItem.cover = mItem.filePath;
        completed(weakItem);
    }
    else
    {
        BOOL ret = [self getDurationAndThumnateTimes:mItem completed:^(MediaItem * item,BOOL isSuccess)
                    {
                        if(item && item.contentView && item.cover)
                        {
                            CGFloat itemWidth = item.lastFrame.size.width;
                            if(itemWidth<=0) itemWidth = item.contentView.frame.size.width;
                            dispatch_async(dispatch_get_main_queue(), ^(void) {
                                [self buildSnapeImageViews:item snapWidth:itemWidth_ itemViewWidth:itemWidth];
                            });
                        }
                        if(completed)
                            completed(item);
                    }];
        
        if(!ret)
        {
            completed(mItem);
        }
    }
    
    //    if(mItem.isImg)
    //    {
    //        __weak typeof (mItem) weakItem = mItem;
    //        completed(weakItem);
    //        return;
    //    }
    //    if((!mItem.cover || mItem.cover.length==0) && mItem.filePath && mItem.filePath.length>0)
    //    {
    //        __weak typeof (mItem) weakItem = mItem;
    //        [[WTPlayerResource sharedWTPlayerResource]
    //         getVideoThumbs:mItem.url targetThumnateFileName:@""
    //         begin:0 andEnd:-1 andStep:1 andCount:1
    //         andSize:CGSizeMake(itemWidth_, itemHeight_)
    //         callback:^(CMTime requestTime,NSString* path,NSInteger index)
    //         {
    //             if(index==0)
    //             {
    //                 weakItem.cover = path;
    //                 if(completed)
    //                 {
    //                     completed(weakItem);
    //                 }
    //             }
    //         }
    //         failure:^(CMTime requestTime,NSError *error,NSString *filePath)
    //         {
    //
    //         }];
    //    }
}
#pragma mark - views
- (NSInteger)getMaxTagID
{
    NSInteger tagID = MEDIAITEMVIEW_MINTAGID;
    for (MediaItem * item in mediaList_) {
        if(item.tagID > tagID)
        {
            tagID = item.tagID;
        }
    }
    return tagID;
}
- (UIView *)getSnapViewByTagID:(NSInteger)tagID
{
    MediaItem *cItem = nil;
    for (MediaItem * item in mediaList_) {
        if(item.tagID == tagID || item.tagID + 10000 == tagID)
        {
            cItem = item;
            break;
        }
    }
    if(cItem)
    {
        if(cItem.snapView.tag<=MEDIAITEMVIEW_MINTAGID)
        {
            cItem.snapView.tag = tagID + 10000;
        }
        return cItem.snapView;
    }
    return nil;
}
- (UIView *)getContentViewByTagID:(NSInteger)tagID
{
    MediaItem *cItem = nil;
    for (MediaItem * item in mediaList_) {
        if(item.tagID == tagID || item.tagID + 10000 == tagID)
        {
            cItem = item;
            break;
        }
    }
    if(cItem)
    {
        return cItem.contentView;
    }
    return nil;
}
- (void) setContentItemPosistion:(CGFloat)top height:(CGFloat)height
{
    itemTop_ = top;
    itemHeight_ = height;
    itemWidth_ = IMAGE_DURATION * contentWidhtPerSecond_;//,round(itemHeight_ * 10)/6.0f;
}
//将Rect规整成为轨中的标准大小
- (CGRect)refrectRect:(CGRect)rect tagID:(NSInteger)tagID;
{
    rect.origin.y = itemTop_;
    rect.size.height = itemHeight_;
    if(tagID>0)
    {
        //如果与后面一个对像重叠了，则需要调整
        MediaItem * item = [self getMediaItemByTagID:tagID];
        if(item && item.contentView)
        {
            MediaItem * nextItem = [self getNextMediaItem:item];
            if(nextItem)
            {
                CGFloat distance = nextItem.contentView.frame.origin.x - (rect.origin.x + rect.size.width);
                if(distance <0)
                {
                    rect.origin.x += distance;
                }
            }
            else if(rect.origin.x + rect.size.width >contentWidth_)
            {
                rect.origin.x = contentWidth_ - rect.size.width;
            }
            rect.size.width = item.lastFrame.size.width;
        }
    }
    if(rect.origin.x <0) rect.origin.x = 0;
    return rect;
}
- (CGRect) getItemFrame:(MediaItem *)mItem
{
    CGFloat totalSeconds = CMTimeGetSeconds(totalDuration);
    CGFloat x = contentWidth_ * CMTimeGetSeconds(mItem.timeInArray)/(totalSeconds>0?totalSeconds:TOTALSECONDS_DEFAULT);
    
    totalSeconds = (totalSeconds>0?totalSeconds:TOTALSECONDS_DEFAULT);
    CGFloat itemWidth = contentWidth_
    * (CMTimeGetSeconds(mItem.end)- CMTimeGetSeconds(mItem.begin))/totalSeconds;
    
    itemWidth = round(itemWidth *10)/10.0f;
    CGRect itemFrame = CGRectMake(x, itemTop_, itemWidth, itemHeight_);
    return itemFrame;
}
- (UIView *) buildMediaView:(MediaItem *)mItem
{
    CGFloat totalSeconds = CMTimeGetSeconds(totalDuration);
    CGFloat x = contentWidth_ * CMTimeGetSeconds(mItem.timeInArray)/(totalSeconds>0?totalSeconds:TOTALSECONDS_DEFAULT);
    
    totalSeconds = (totalSeconds>0?totalSeconds:TOTALSECONDS_DEFAULT);
    CGFloat itemWidth = contentWidth_
    * (CMTimeGetSeconds(mItem.end)- CMTimeGetSeconds(mItem.begin))/totalSeconds;
    
    itemWidth = round(itemWidth *10)/10.0f;
    CGRect itemFrame = CGRectMake(x, itemTop_, itemWidth, itemHeight_);
    
    UIView * itemView = [[UIView alloc]initWithFrame:itemFrame];
    itemView.backgroundColor = [UIColor clearColor];
    itemView.layer.borderColor = [[UIColor blackColor]CGColor];
    itemView.layer.borderWidth = 1;
    mItem.contentView = itemView;
    
    itemView.layer.borderColor = [COLOR_MV_BF CGColor];
    itemView.layer.borderWidth = 2;
    itemView.layer.masksToBounds = YES;
    
    mItem.lastFrame = itemFrame;
    mItem.targetFrame = itemFrame;
    
    if(mItem.cover && mItem.cover.length>0)
    {
        [self buildSnapeImageViews:mItem snapWidth:itemWidth_ itemViewWidth:itemFrame.size.width];
    }
    //        此处不要处理，因为添加对像时就有生成缩略图的指令，等该指令的结果
    //        else
    //        {
    //            [self checkMedia:mItem thumnateSize:CGSizeMake(snapViewWidth, itemHeight_) completed:^(MediaItem * cItem)
    //             {
    //                 mediaCompleted(cItem);
    //             }];
    //        }
    //    }
    if(!mItem.cover || mItem.cover.length==0 ||(!mItem.isImg && mItem.videoThumnateFilesCount ==0))
    {
        __weak MediaEditManager * weakSelf = self;
        BOOL ret = [self getDurationAndThumnateTimes:mItem completed:^(MediaItem * item,BOOL isSuccess)
                    {
                        if(item && item.contentView && item.cover)
                        {
                            dispatch_async(dispatch_get_main_queue(), ^(void) {
                                [weakSelf buildSnapeImageViews:item snapWidth:itemWidth_ itemViewWidth:itemFrame.size.width];
                            });
                        }
                    }];
        if(!ret)
        {
            NSLog(@"**** generate thumnate failure. *****");
        }
    }
    return PP_AUTORELEASE(itemView);
}
- (void)buildSnapeImageViews:(MediaItem *)cItem snapWidth:(CGFloat)snapViewWidth itemViewWidth:(CGFloat)itemViewWidth
{
    UIWebImageViewN * imageView  = (UIWebImageViewN *)[cItem.contentView viewWithTag:cItem.tagID + 20000];
    if(imageView)
    {
        [imageView setImageWithURLString:cItem.cover width:snapViewWidth height:itemHeight_ mode:1 placeholderImage:nil];
    }
    else
    {
        imageView = [[UIWebImageViewN alloc]initWithFrame:CGRectMake(0, 0, snapViewWidth, itemHeight_)];
        imageView.isFill_ = YES;
        imageView.keepScale_ = YES;
        [imageView setImageWithURLString:cItem.cover width:snapViewWidth height:itemHeight_ mode:1 placeholderImage:nil];
        imageView.tag = cItem.tagID + 20000;
        [cItem.contentView addSubview:imageView];
        PP_RELEASE(imageView);
    }
    {
        UIWebImageViewN * snapImageView  = (UIWebImageViewN *)[cItem.contentView viewWithTag:cItem.tagID + 5000];
        if(snapImageView)
        {
            [snapImageView setImageWithURLString:cItem.cover width:snapViewWidth height:itemHeight_ mode:1 placeholderImage:nil];
        }
        else
        {
            snapImageView = [[UIWebImageViewN alloc]initWithFrame:CGRectMake(0, 0, snapViewWidth, itemHeight_)];
            [snapImageView setImageWithURLString:cItem.cover width:snapViewWidth height:itemHeight_ mode:1 placeholderImage:nil];
            cItem.snapView = snapImageView;
            
            if(cItem.tagID > 0)
            {
                cItem.snapView.tag = cItem.tagID + 5000;
            }
            else
            {
                NSLog(@"****************tagid不能为空*****");
            }
            PP_RELEASE(snapImageView);
        }
    }
    
    
    
    //如果长度较长，则需要重复填充缩略图
    if(itemViewWidth > snapViewWidth)
    {
        //因为Cover占用一个位置，所以这里从1开始
        NSInteger imageIndex = 1;
        //获取多个缩略图填充
        CGFloat pos  = snapViewWidth;
        while (pos < itemViewWidth) {
            CGFloat itemWidth = MIN(itemViewWidth - pos,snapViewWidth);
            NSString * filePath = cItem.cover;
            if(!cItem.isImg  && (cItem.videoThumnateFilesCount> imageIndex && cItem.videoThumnateFilePaths.count > imageIndex))
            {
                filePath = [cItem.videoThumnateFilePaths objectAtIndex:imageIndex];
            }
            
            UIWebImageViewN * snapImageView  = (UIWebImageViewN *)[cItem.contentView viewWithTag:cItem.tagID + 20000 + imageIndex];
            if(snapImageView)
            {
                
                [snapImageView setImageWithURLString:filePath
                                               width:snapViewWidth
                                              height:itemHeight_
                                                mode:1
                                    placeholderImage:nil];
            }
            else
            {
                UIWebImageViewN * snapImageView = [[UIWebImageViewN alloc]initWithFrame:CGRectMake(pos, 0, itemWidth, itemHeight_)];
                snapImageView.isFill_ = YES;
                snapImageView.keepScale_ = YES;
                [snapImageView setImageWithURLString:filePath
                                               width:snapViewWidth
                                              height:itemHeight_
                                                mode:1
                                    placeholderImage:nil];
                
                
                snapImageView.tag = cItem.tagID + 20000 + imageIndex;
                [cItem.contentView addSubview:snapImageView];
                
                PP_RELEASE(snapImageView);
            }
            pos += snapViewWidth;
            imageIndex ++;
        }
        
        //如果是视频，需要再去截图
        //这里不处理，在当截图到时，通过检查视图是否已经画出来再处理
        //                if(!cItem.isImg)
        //                {
        //
        //                }
        
    }
}
- (CGFloat)contentViewWidth:(CGFloat)widthPerSecond contentWidth:(CGFloat)contentWidth
{
    if(totalSecondsDuration_<=0)
        totalSecondsDuration_ = CMTimeGetSeconds(totalDuration);
    
    contentWidhtPerSecond_ = widthPerSecond;
    
    itemWidth_ = MIN(IMAGE_DURATION * 12, 100);
    
    CGFloat totalSeconds =  totalSecondsDuration_;
    //    contentWidth_ = contentWidth;
    contentWidth_ = MAX(roundf(widthPerSecond * totalSeconds *10)/10,contentWidth);
    return contentWidth_;
}
- (CGFloat)secondsWithPos:(CGFloat)xPos
{
    CGFloat seconds = xPos/contentWidth_ * totalSecondsDuration_;
    return seconds;
}
- (NSArray *)mediaList
{
    return mediaList_;
}
//与CheckPoint保存的值进行比较，判断发生变化的列表
- (NSArray *)mediaChangedList
{
    NSMutableArray * mediaChanged = [NSMutableArray new];
    NSArray * lastMediaList = [self getMediaItemsLastCheckPoint];
    
    NSLog(@"item compare -------------------");
    for (MediaItem * item in lastMediaList) {
        BOOL isFind = NO;
        for (MediaItem * nowItem in mediaList_) {
            //            NSLog(@"item compare:%f<->%f,%f<->%f,%f<->%f",item.secondsInArray,nowItem.secondsInArray,item.secondsBegin,nowItem.secondsBegin,item.secondsEnd,nowItem.secondsEnd);
            if([item.key isEqualToString:nowItem.key])//同一个对像
            {
                isFind = YES;
                if([item isEqual:nowItem])
                {
                }
                else
                {
                    nowItem.changeType = 0;
                    [mediaChanged addObject:nowItem];
                    
                }
                NSLog(@"find break");
                break;
            }
        }
        if(!isFind)
        {
            item.changeType = 2; //delete
            [mediaChanged addObject:item];
        }
    }
    //反向对比
    for (MediaItem * item in mediaList_) {
        BOOL isFind = NO;
        for (MediaItem * nowItem in lastMediaList) {
            //            NSLog(@"item compare:%f<->%f,%f<->%f,%f<->%f",item.secondsInArray,nowItem.secondsInArray,item.secondsBegin,nowItem.secondsBegin,item.secondsEnd,nowItem.secondsEnd);
            if([item.key isEqualToString:nowItem.key])//同一个对像
            {
                isFind = YES;
                //                if([item isEqual:nowItem])
                //                {
                break;
                //                }
                //                else
                //                {
                //                    item.changeType = 0;
                //                    [mediaChanged addObject:item];
                //                    break;
                //                }
            }
        }
        if(!isFind)
        {
            item.changeType = 1; //new item
            [mediaChanged addObject:item];
        }
    }
    return PP_AUTORELEASE(mediaChanged);
}
- (void)logLastFrame
{
    //比较器
    NSComparator listCompare = ^NSComparisonResult(id obj1,id obj2)
    {
        MediaItem * item1 = (MediaItem*)obj1;
        MediaItem * item2 = (MediaItem *)obj2;
        if(!item1.contentView)
        {
            return NSOrderedAscending;
        }
        else if(!item2.contentView)
        {
            return NSOrderedDescending;
        }
        else if(item1.contentView.frame.origin.x < item2.contentView.frame.origin.x)
        {
            return NSOrderedAscending;
        }
        else if(item1.contentView.frame.origin.x == item2.contentView.frame.origin.x)
        {
            return NSOrderedSame;
        }
        else
        {
            return NSOrderedDescending;
        }
    };
    [mediaList_ sortUsingComparator:listCompare];
    
    for (MediaItem * item  in mediaList_) {
        if(item.contentView)
        {
            item.lastFrame = item.contentView.frame;
            item.targetFrame = item.lastFrame;
        }
    }
}
- (void)restorelastFrame
{
    for (MediaItem * item  in mediaList_) {
        if(item.contentView)
        {
            item.contentView.frame = item.lastFrame;
            item.contentView.alpha = 1;
            item.targetFrame = item.lastFrame;
#ifndef __OPTIMIZE__
            if(item.targetFrame.origin.y <0||item.targetFrame.origin.x <0)
            {
                NSLog(@"xxxx");
            }
#endif
        }
    }
}
- (MediaItem *)getMediaItemByTagID:(NSInteger)tagID
{
    MediaItem * target = nil;
    for (MediaItem * item in mediaList_) {
        if(item.tagID == tagID)
        {
            target = item;
            break;
        }
    }
    return target;
}
- (MediaItem *)getNextMediaItem:(MediaItem *)item
{
    MediaItem * target = nil;
    CGFloat distance = 0;
    for (MediaItem * cItem in mediaList_) {
        if(!cItem.contentView) continue;
        if(cItem!=item && cItem.contentView.frame.origin.x > item.contentView.frame.origin.x)
        {
            CGFloat disTemp = cItem.contentView.frame.origin.x - item.contentView.frame.origin.x;
            if(distance > disTemp)
            {
                disTemp = disTemp;
                target = cItem;
            }
        }
    }
    return target;
}
////获取当前对像的前一个对像及前前一个对像。并可以只返回相交的对像
//- (MediaItem *)getPrevMediaItem:(MediaItem *)item interSect:(BOOL)interSect isLeft:(BOOL)isLeft prevPrevItem:(MediaItem **)prevprevItem
//{
//    CGFloat prevX = -1,prevPrevX = -1;
//    NSInteger prevIndex,prevPrevIndex,itemIndex;
//    prevIndex = prevPrevIndex = -1;
//
//    itemIndex = -1;
//    for (MediaItem * cItem in mediaList_)
//    {
//        itemIndex ++;
//        if(cItem.tagID< MEDIAITEMVIEW_MINTAGID || cItem.tagID>= MEDIAITEMVIEW_MINTAGID+5000 || cItem.contentView==nil)
//        {
//            continue;
//        }
//        //        当前Item必须用TargetFrame，不能用ContentView的Frame，因为针对的RootView不一样
//        NSLog(@"--- getCNM-- get %d check intersect:%d %.1f <=%.1f ",item.tagID,cItem.tagID,cItem.contentView.frame.origin.x,item.targetFrame.origin.x);
//        if(isLeft ==NO && cItem.pointForRoot.x <= item.pointForRoot.x && cItem!=item)
//        {
//            if(cItem.pointForRoot.x > prevPrevX)
//            {
//                prevPrevX = prevX;
//                prevPrevIndex = prevIndex;
//
//                prevX = cItem.pointForRoot.x;
//                prevIndex = itemIndex;
//
//            }
//        }
//        else if(isLeft  && cItem.pointForRoot.x >= item.pointForRoot.x && cItem!=item)
//        {
//            if(cItem.pointForRoot.x < prevPrevX)
//            {
//                prevPrevX = prevX;
//                prevPrevIndex = prevIndex;
//
//                prevX = cItem.pointForRoot.x;
//                prevIndex = itemIndex;
//
//            }
//        }
//    }
//    //需要检查是否有交叉重叠
//    MediaItem * prevItem = nil;
//    MediaItem * prevPrevItemTemp = nil;
//    if(prevIndex>=0 && prevIndex < mediaList_.count)
//    {
//        prevItem = [mediaList_ objectAtIndex:prevIndex];
//    }
//    if(prevPrevIndex>=0 && prevPrevIndex < mediaList_.count)
//    {
//        prevPrevItemTemp = [mediaList_ objectAtIndex:prevPrevIndex];
//    }
//
//    if(interSect)
//    {
//        if(isLeft)
//        {
//            if(prevItem.pointForRoot.x >= item.pointForRoot.x +1
//               && item.pointForRoot.x + item.contentView.frame.size.width < prevItem.pointForRoot.x +1)
//            {
//                NSLog(@"--- getCNM-- get %d intersect:%d ",item.tagID,prevItem.tagID);
//            }
//            else
//            {
//                prevItem = nil;
//            }
//        }
//        else
//        {
//            if(prevItem.pointForRoot.x <= item.pointForRoot.x +1
//               && prevItem.pointForRoot.x + prevItem.contentView.frame.size.width > item.pointForRoot.x +1)
//            {
//                NSLog(@"--- getCNM-- get %d intersect:%d ",item.tagID,prevItem.tagID);
//            }
//            else
//            {
//                prevItem = nil;
//            }
//        }
//    }
//    if(prevprevItem)
//    {
//        if(prevPrevItemTemp)
//        {
//            NSLog(@"--- getCNM-- get %d prev prev:%d ",item.tagID,prevPrevItemTemp.tagID);
//        }
//        *prevprevItem = prevPrevItemTemp;
//    }
//    return prevItem;
//}
//- (MediaItem *)GetMediaNeabyWithList:(BOOL)isLeft targetItem:(MediaItem *)targetItem targetRect:(CGRect) targetRect
//                           rightList:(NSMutableArray *)rightList prevPrevItem:(MediaItem **)prevPrevItem
//{
//    MediaItem * leftSectTemp = [self getPrevMediaItem:targetItem interSect:YES isLeft:isLeft prevPrevItem:prevPrevItem];
//
//
//    //    if(rightViewList)
//    {
//        for (MediaItem * item in mediaList_) {
//            if(item.tagID >= MEDIAITEMVIEW_MINTAGID && item.tagID!=targetItem.tagID && item!= leftSectTemp && item.contentView)
//            {
//                //                NSLog(@"add to right:%d syntax:%f>%f",item.tagID,item.contentView.frame.origin.x ,targetRect.origin.x);
//                if(isLeft)
//                {
//                    if(item.targetFrame.origin.x <= targetRect.origin.x)
//                    {
//                        [rightList addObject:item];
//                        NSLog(@"--- getCNM-- add to right %d (%@) ",item.tagID,NSStringFromCGRect(item.contentView.frame));
//                    }
//                    else
//                    {
//                        NSLog(@"--- getCNM-- ignore  right %d (%@) ",item.tagID,NSStringFromCGRect(item.contentView.frame));
//                    }
//                }
//                else
//                {
//                    if(item.targetFrame.origin.x >= targetRect.origin.x)
//                    {
//                        [rightList addObject:item];
//                        NSLog(@"--- getCNM-- add to right %d (%@) ",item.tagID,NSStringFromCGRect(item.contentView.frame));
//                    }
//                    else
//                    {
//                        NSLog(@"--- getCNM-- ignore  right %d (%@) ",item.tagID,NSStringFromCGRect(item.contentView.frame));
//                    }
//                }
//            }
//        }
//        //        [rightList sortUsingComparator:listCompare];
//    }
//    return leftSectTemp;
//}

//测算一个视频或图片从轨中移出或移入，需要处理的对像及其座标
- (CGRect)getContentViewsNeedMoved:(CGRect)targetRect
                      excludeTagID:(NSInteger)tagID
                         direction:(BOOL)isLeft
                            isDone:(BOOL)isDone //是否最后放下时，在移动时有些事情不好处理
                        targetItem:(MediaItem **)currentItem
                      leftSectItem:(MediaItem **)leftSectitem
                     rightItemList:(NSMutableArray **)rightViewList
{
    NSLog(@"--- getCNM-- begin-----");
    CGRect targetFrame;
    BOOL marginOverlow = NO;
    
    NSMutableArray * rightList = [NSMutableArray new];
    MediaItem * targetItem = [self getMediaItemByTagID:tagID];
    if(currentItem) *currentItem = targetItem;
    
    
    targetFrame = targetRect;//targetItem.lastFrame;
    
    targetItem.targetFrame = targetFrame;
    
    //    NSLog(@"--- getCNM-- tf %@",NSStringFromCGRect(targetFrame));
    //    NSLog(@"--- getCNM--    lastframe:%@ ",NSStringFromCGRect(targetItem.lastFrame));
    
    //    NSLog(@"--- getCNM-- check intersect--");
    CGFloat leftMoveX,rightMoveX = 0;
    NSLog(@"***************** before insert ************");
    NSInteger itemIndex = [self getTargetIndexInArray:targetFrame targetItem:targetItem leftMoveX:&leftMoveX rightMoveX:&rightMoveX];
    NSLog(@"--- getCNM1 %d is current index,left:%.1f right:%.1f",(int)itemIndex,leftMoveX,rightMoveX);
#ifndef __OPTIMIZE__
    for (MediaItem * aitem in  mediaList_) {
        NSLog(@"--- getCNM1 %d %@(root:%@)",(int)aitem.tagID,NSStringFromCGRect(aitem.targetFrame),NSStringFromCGPoint(aitem.pointForRoot));
    }
#endif
    for (int i =0;i<mediaList_.count;i++) {
        MediaItem * cItem = [mediaList_ objectAtIndex:i];
        if(i<itemIndex)
        {
            CGRect tar = cItem.targetFrame;
            tar.origin.x -= leftMoveX;
            if(!marginOverlow && (tar.origin.x <0||tar.origin.x + tar.size.width > contentWidth_))
            {
                marginOverlow = YES;
            }
            cItem.targetFrame = tar;
        }
        else if(i>itemIndex)
        {
            CGRect tar = cItem.targetFrame;
            tar.origin.x += rightMoveX;
            if(!marginOverlow && (tar.origin.x + tar.size.width > contentWidth_||tar.origin.x <0))
            {
                marginOverlow = YES;
            }
            cItem.targetFrame = tar;
        }
        else
        {
            cItem.targetFrame = targetFrame;
            if(!marginOverlow && (targetFrame.origin.x + targetFrame.size.width > contentWidth_||targetFrame.origin.x <0))
            {
                marginOverlow = YES;
            }
        }
        //        NSLog(@"--- getCNM-- 第一次Frame:%d %@",cItem.tagID,NSStringFromCGRect(cItem.targetFrame));
    }
#ifndef __OPTIMIZE__
    for (MediaItem * aitem in  mediaList_) {
        NSLog(@"--- getCNM2 %d %@(root:%@)",(int)aitem.tagID,NSStringFromCGRect(aitem.targetFrame),NSStringFromCGPoint(aitem.pointForRoot));
    }
#endif
    //检查左右边界越界的情况
    if((isDone && marginOverlow) && mediaList_.count>0)
    {
        [self checkMarginAndChanged:&targetFrame targetItem:targetItem changeList:rightList];
    }
    else
    {
        [rightList addObjectsFromArray:mediaList_];
    }
#ifndef __OPTIMIZE__
    for (MediaItem * aitem in  mediaList_) {
        NSLog(@"--- getCNM3 %d %@(root:%@)",(int)aitem.tagID,NSStringFromCGRect(aitem.targetFrame),NSStringFromCGPoint(aitem.pointForRoot));
    }
#endif
    //清除位置没有发生变化的数据
    [self clearItemsNotChanged:rightList targetTagID:tagID];
    
    if(rightViewList)    *rightViewList = rightList;
    
    PP_RELEASE(rightList);
    NSLog(@"--------- getContentViewsNeedMoved-- end-----");
    
    return targetFrame;
}
//计算一个对像应该位于的位置，并且返回左右两侧需要移动的位置
- (NSInteger)getTargetIndexInArray:(CGRect)targetFrame
                        targetItem:(MediaItem *)targetItem
                         leftMoveX:(CGFloat *)leftMoveX
                        rightMoveX:(CGFloat *)rightMoveX
{
    NSInteger index = 0;
    
    [mediaList_ sortUsingComparator:[self getListCompareByContentView]];
    
    MediaItem * leftItem = nil;
    MediaItem * rightItem = nil;
    for (MediaItem * item in mediaList_) {
        if(item == targetItem)
        {
            break;
        }
        leftItem = item;
        index ++;
    }
    if(index < mediaList_.count -1)
    {
        rightItem = [mediaList_ objectAtIndex:index +1];
    }
    if(leftMoveX)
    {
        if(leftItem)
        {
            CGFloat left = leftItem.pointForRoot.x + leftItem.lastFrame.size.width -targetItem.pointForRoot.x;
            if(left > 0)
                *leftMoveX = left;
        }
        else
        {
            *leftMoveX = 0;
        }
    }
    if(rightMoveX)
    {
        if(rightItem)
        {
            CGFloat right = targetItem.pointForRoot.x + targetItem.lastFrame.size.width - rightItem.pointForRoot.x;
            if(right>0)
                *rightMoveX = right;
            NSLog(@"%@ -->%@",NSStringFromCGPoint(rightItem.pointForRoot),NSStringFromCGPoint(targetItem.pointForRoot));
        }
        else
        {
            *rightMoveX = 0;
            NSLog(@"not right");
        }
    }
    return index;
}
- (void)checkMarginAndChanged:(CGRect *) targetFrame
                   targetItem:(MediaItem *)targetItem
                   changeList:(NSMutableArray*)changeList
{
    if(mediaList_.count==0) return;
    
    //排序后计算所有的对像的位置需要左移的量
    targetItem.targetFrame = *targetFrame;
    
    [mediaList_ sortUsingComparator:[self getListCompareByContentView]];
    
    CGFloat leftMoveChanged = 0;
    
    MediaItem * lastItem = (MediaItem *)[mediaList_ lastObject];
    leftMoveChanged = lastItem.targetFrame.origin.x + lastItem.targetFrame.size.width - contentWidth_;
    if(leftMoveChanged >0)
    {
        [changeList removeAllObjects];
        
        CGFloat lastPos = contentWidth_;
        
        for (NSInteger i = mediaList_.count-1; i>=0; i--) {
            MediaItem * item  = [mediaList_ objectAtIndex:i];
            if(!item.contentView) continue;
            //因为RightsList原来与MedaiList引用的是同样的对像。因此，在前一部分，对右侧的进行修改时的值应该会保留下来
            //这时，如果补齐了右侧多余的东东，还需要检查，前面是否有需要处理的对像
            //            if(leftMoveChanged>0)
            //            {
            CGRect tar1 = item.targetFrame;
            if(item == lastItem) // last one
            {
                tar1.origin.x -= leftMoveChanged;
            }
            else
            {
                CGFloat lastSpace = lastPos - (tar1.origin.x + tar1.size.width);
                
                if(lastSpace >= leftMoveChanged)
                {
                    leftMoveChanged = 0;
                }
                else
                {
                    if(lastSpace<0)
                    {
                        leftMoveChanged = 0 - lastSpace;
                        tar1.origin.x -= leftMoveChanged;
                    }
                }
                
                
                //                    NSLog(@"****** %d space:%.1f leftmove:%.1f originx:%.1f",item.tagID,lastSpace,leftMoveChanged,tar1.origin.x)
            }
            item.targetFrame =  tar1;
            lastPos = item.targetFrame.origin.x;
            
            [changeList insertObject:item atIndex:0];
            //            }
        }
    }
    //检查左边是否出界
    MediaItem * firstItem = [mediaList_ firstObject];
    if(firstItem == lastItem) return;
    
    leftMoveChanged = 0 - firstItem.targetFrame.origin.x;
    if(leftMoveChanged >0)
    {
        //        [changeList removeAllObjects];
        
        for (NSInteger i = 0; i<mediaList_.count; i++) {
            MediaItem * item  = [mediaList_ objectAtIndex:i];
            if(!item.contentView) continue;
            //因为RightsList原来与MedaiList引用的是同样的对像。因此，在前一部分，对右侧的进行修改时的值应该会保留下来
            //这时，如果补齐了右侧多余的东东，还需要检查，前面是否有需要处理的对像
            if(leftMoveChanged>0)
            {
                CGRect tar1 = item.targetFrame;
                tar1.origin.x += leftMoveChanged;
                item.targetFrame =  tar1;
                
                if(i < mediaList_.count-1)
                {
                    MediaItem * nextItem = [mediaList_ objectAtIndex:i +1];
                    CGFloat lastSpace = nextItem.targetFrame.origin.x - (tar1.origin.x + tar1.size.width);
                    if(lastSpace <0)
                    {
                        leftMoveChanged = 0 - lastSpace;
                    }
                    else
                    {
                        leftMoveChanged = 0;
                    }
                }
            }
            if([changeList containsObject:item]==NO)
                [changeList insertObject:item atIndex:0];
        }
    }
    *targetFrame = targetItem.targetFrame;
}

#pragma mark - helper
- (void)clearItemsNotChanged:(NSMutableArray *)list targetTagID:(NSInteger)tagID
{
    //        去除不需要移动的对像
    for (NSInteger i = list.count-1; i>=0; i--) {
        MediaItem * item  = [list objectAtIndex:i];
        if(item.contentView && CGRectEqualToRect(item.contentView.frame, item.targetFrame))
        {
            //            NSLog(@"-- list: frame not changed ,remove it:%d",item.tagID);
            [list removeObjectAtIndex:i];
        }
        else if(item.tagID == tagID)
        {
            //            NSLog(@"-- list: same as current ,remove it:%d",item.tagID);
            [list removeObjectAtIndex:i];
        }
    }
}
- (NSComparator) getListCompareByContentView
{
    NSComparator listCompare = ^NSComparisonResult(id obj1,id obj2)
    {
        MediaItem * item1 = (MediaItem*)obj1;
        MediaItem * item2 = (MediaItem *)obj2;
        if(!item1.contentView)
        {
            return NSOrderedAscending;
        }
        else if(!item2.contentView)
        {
            return NSOrderedDescending;
        }
        else
        {
            if(item1.pointForRoot.x < item2.pointForRoot.x)
            {
                return NSOrderedAscending;
            }
            else if(fabs(item1.pointForRoot.x - item2.pointForRoot.x)<MIN_AUDIOSPACE)
            {
                return NSOrderedSame;
            }
            else
            {
                return NSOrderedDescending;
            }
        }
        
    };
    return listCompare;
}
- (NSComparator) getListCompareForAudio
{
    NSComparator listCompare = ^NSComparisonResult(id obj1,id obj2)
    {
        AudioItem * item1 = (AudioItem*)obj1;
        AudioItem * item2 = (AudioItem *)obj2;
        
        if(item1.secondsInArray < item2.secondsInArray)
        {
            return NSOrderedAscending;
        }
        else if(fabs(item1.secondsInArray - item2.secondsInArray)<MIN_AUDIOSPACE)
        {
            return NSOrderedSame;
        }
        else
        {
            return NSOrderedDescending;
        }
    };
    return listCompare;
}
- (NSComparator) getListCompareForVideo
{
    NSComparator listCompare = ^NSComparisonResult(id obj1,id obj2)
    {
        MediaItem * item1 = (MediaItem*)obj1;
        MediaItem * item2 = (MediaItem *)obj2;
        
        if(item1.secondsInArray < item2.secondsInArray)
        {
            return NSOrderedAscending;
        }
        else if(fabs(item1.secondsInArray - item2.secondsInArray)<MIN_AUDIOSPACE)
        {
            return NSOrderedSame;
        }
        else
        {
            return NSOrderedDescending;
        }
    };
    return listCompare;
}
#pragma mark - playitem
////获取完整的视频列表，即将背景视频也加入到队列中
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
//- (NSArray *)getFullMediaList:(MediaItem *)bgVideo fillEmptyWithBgVideo:(BOOL)fill
//{
//    if(!bgVideo.key ||bgVideo.key.length==0)
//    {
//        bgVideo.key = [self getKeyOfItem:bgVideo];
//    }
//    //根据所有的对像，建立一个没有转场的队列
//    NSMutableArray * fullMedialList = [NSMutableArray new];
//    CGFloat lastSeconds = 0;
//    for (MediaItem * item in mediaList_) {
//        if(item.secondsInArray >= totalSecondsDuration_) continue;
//        //        //之前有没有空隙
//        //        if(fill && item.secondsInArray > lastSeconds + MINVIDEO_SECONDS)
//        //        {
//        //            MediaItem * newItem = [MediaItem new];
//        //            newItem.rect = bgVideo.rect;
//        //            newItem.key = bgVideo.key;
//        //            newItem.isImg = bgVideo.isImg;
//        //            newItem.filePath = bgVideo.filePath;
//        //            newItem.title = bgVideo.title;
//        //            newItem.cover = bgVideo.cover;
//        //            newItem.url = bgVideo.url;
//        //            newItem.duration = bgVideo.duration;
//        //            newItem.begin = CMTimeMakeWithSeconds(lastSeconds, bgVideo.duration.timescale); //因为背景视频默认是全长的，即完整的长度
//        //            newItem.end = CMTimeMakeWithSeconds(item.secondsInArray - lastSeconds, bgVideo.duration.timescale);
//        //            newItem.cutInMode = CutInOutModeFadeIn;
//        //            newItem.cutOutMode = CutInOutModeFadeOut;
//        //            newItem.timeInArray = CMTimeMakeWithSeconds(lastSeconds, bgVideo.duration.timescale);
//        //            newItem.playRate = 1.0;
//        //            newItem.renderSize = bgVideo.renderSize;
//        //
//        //            [fullMedialList addObject:newItem];
//        //
//        //            lastSeconds =  item.secondsInArray;
//        //        }
//        if(item.secondsDurationInArray >= MINVIDEO_SECONDS)
//        {
//            [fullMedialList addObject:item];
//        }
//        if(fill)
//        {
//            item.timeInArray = CMTimeMakeWithSeconds(lastSeconds, item.duration.timescale); //校正时间
//            item.renderSize = bgVideo.renderSize;
//        }
//        else
//        {
//            if(item.renderSize.width <10)
//            {
//                item.renderSize = bgVideo.renderSize;
//            }
//        }
//        if(item.isImg)
//        {
//            [self checkRenderSize:item];
//        }
//        lastSeconds = item.secondsInArray + item.secondsDurationInArray;
//    }
//
//    if(fill && lastSeconds < totalSecondsDuration_ - MINVIDEO_SECONDS)
//    {
//        MediaItem * newItem = [MediaItem new];
//        newItem.rect = bgVideo.rect;
//        newItem.key = bgVideo.key;
//        newItem.isImg = bgVideo.isImg;
//        newItem.filePath = bgVideo.filePath;
//        newItem.title = bgVideo.title;
//        newItem.cover = bgVideo.cover;
//        newItem.url = bgVideo.url;
//        newItem.duration = bgVideo.duration;
//        newItem.begin = CMTimeMakeWithSeconds(lastSeconds, bgVideo.duration.timescale); //因为背景视频默认是全长的，即完整的长度
//        newItem.end = CMTimeMakeWithSeconds(totalSecondsDuration_, bgVideo.duration.timescale);
//        newItem.cutInMode = CutInOutModeFadeIn;
//        newItem.cutOutMode = CutInOutModeFadeIn;
//        newItem.timeInArray = CMTimeMakeWithSeconds(lastSeconds, bgVideo.duration.timescale);
//        newItem.playRate = 1.0;
//        newItem.renderSize = bgVideo.renderSize;
//
//        [fullMedialList addObject:newItem];
//    }
//    return PP_AUTORELEASE(fullMedialList);
//}

- (void)checkRenderSize:(MediaItem * )item
{
    //    DeviceConfig * config = [DeviceConfig config];
    //    //4s
    //    if(config.Height < 500)
    //    {
    //        item.renderSize = CGSizeMake(config.Height * config.Scale, config.Width * config.Scale);
    //    }
}
//- (PlayerMediaItem *)toPlayerMediaItem:(MediaItem *)originItem
//{
//    PlayerMediaItem * pItem = [[PlayerMediaItem alloc]init];
//    pItem.originAsset = originItem.alAsset;
//    pItem.url = originItem.url;
//    pItem.path =originItem.filePath;
//    pItem.cover = originItem.cover;
//    pItem.duration = originItem.duration;
//
//    pItem.prevSecondsInArray = originItem.secondsInArray;
//    pItem.begin = originItem.begin;
//    pItem.end = originItem.end;
//
//    pItem.playRate = 1.0;
//    pItem.renderSize = originItem.renderSize;
//    pItem.isTrans = originItem.isImg?MediaItemTypeIMAGE:MediaItemTypeVIDEO;
//
//    pItem.transEnd = originItem.end;
//    pItem.transBegin = originItem.begin;
//
//
//    pItem.modalInType = originItem.cutInMode;
//    pItem.modalOffType = originItem.cutOutMode;;
//    pItem.modalOnType = originItem.cutInMode;
//    pItem.modalType = originItem.cutInMode;
//    pItem.originType = originItem.isImg?MediaItemTypeIMAGE:MediaItemTypeVIDEO;
//
//    return PP_AUTORELEASE(pItem);
//}
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

- (AVPlayerItem *)getPlayerItem
{
    return currentPlayerItem_;
}

#pragma mark - audios media export
- (NSArray *)exportAudioItemsArray
{
    [self resortAudioes];
    
    NSMutableArray * exportList = [NSMutableArray new];
    [exportList addObjectsFromArray:audioList_];
    
    if(exportList.count>0)
    {
        //校正第一个，如果第一个不是从0开始，补一个空音频
        AudioItem * firstItem = [exportList firstObject];
        if(firstItem.secondsInArray>0)
        {
            AudioItem * newItem = [self getEmptyAudioItem:0 duration:firstItem.secondsInArray];
            [exportList insertObject:newItem atIndex:0];
        }
    }
#ifndef __OPTIMIZE__
    for (AudioItem *item in exportList) {
        NSLog(@"exportaudio:(list) timeline:(%.2f--%.2f) intrack:(%.2f,%.2f)",
              item.secondsInArray,item.secondsInArray + item.secondsDurationInArray,item.secondsBegin,item.secondsEnd);
    }
#endif
    return PP_AUTORELEASE(exportList);
}
- (AudioItem *) getEmptyAudioItem:(CGFloat)startInSeconds duration:(CGFloat)durationInSeconds
{
    AudioItem * newItem = [[AudioItem alloc]init];
    newItem.fileName = [[UDManager sharedUDManager]localFileFullPath:@"empty.mp3"];
    newItem.index = 0;
    newItem.secondsInArray = startInSeconds;
    newItem.secondsBegin = 0;
    newItem.secondsEnd = durationInSeconds;
    return PP_AUTORELEASE(newItem);
}
static BOOL isGenerateAudioing_ = NO;
- (BOOL)    generateAudio:(audioGenerateCompleted)completed
{
    if(videoGenerater_)
    {
        return [self generateAudio:videoGenerater_.totalBeginTime end:videoGenerater_.totalEndTime completed:completed];
    }
    else
    {
        return [self generateAudio:kCMTimeZero end:CMTimeMakeWithSeconds([self totalAudioDuration], 44100) completed:completed];
    }
}
- (BOOL)    generateAudio:(CMTime)begin end:(CMTime)end completed:(audioGenerateCompleted)completed
{
    if(isGenerateAudioing_) return NO;
    isGenerateAudioing_ = YES;
    NSArray * audioList = [self exportAudioItemsArray];
    
#ifndef __OPTIMIZE__
    NSLog(@"录音队列：%d",(int)audioList.count);
    if(self.mergeMTVItem)
    {
        NSLog(@"对像数据中音频文件:%@",self.mergeMTVItem.AudioFileName?self.mergeMTVItem.AudioFileName:@" null ");
    }
#endif
    
    //如果保存后台操作失败，有可能导到数据中不正确
    if(self.Sample)
    {
        if([self.mergeMTVItem.AudioRemoteUrl isEqualToString:self.Sample.AudioRemoteUrl])
        {
            if([self totalAudioDuration]>10)
            {
                [self.mergeMTVItem setAudioPathN:nil];
            }
        }
    }
    if([self checkAudioPath:self.mergeMTVItem])
    {
        if(completed)
        {
            NSString * path = [HCFileManager checkPath:[self.mergeMTVItem getAudioPathN]];
            NSURL * audioUrl = [NSURL fileURLWithPath:path];
            NSLog(@"使用外部传入的MTV的AudioPath");
            [self setMixedAudio:path];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if(completed)
                {
                    completed(audioUrl,nil);
                }
            });
            isGenerateAudioing_ = NO;
        }
        return YES;
    }
    //没有需要合成的文件
    if(!audioList||audioList.count==0)
    {
        isGenerateAudioing_ = NO;
        if(completed)
        {
            completed(nil,nil);
        }
        return YES;
    }
    //    dispatch_async(dispatch_JoinVideo_, ^{
    
    audioGenerateCompleted completedNew = ^(NSURL *audioUrl, NSError *error)
    {
        
        
        PP_RELEASE(audioMixUrl_);
        if(!error)
        {
            audioMixUrl_ = PP_RETAIN(audioUrl);
            NSLog(@"export audio:%@ ok",[audioUrl absoluteString]);
        }
        else
        {
            NSLog(@"export audio failure:%@",[error localizedDescription]);
        }
        
        if(audioMixUrl_ && (!videoGenerater_.joinAudioUrl || videoGenerater_.joinAudioUrl!=audioUrl))
        {
            [videoGenerater_ setJoinAudioUrlWithDraft:audioMixUrl_];
        }
        if(completed)
        {
            completed(audioUrl,error);
        }
        isGenerateAudioing_ = NO;
    };
    
    AudioGenerater * gen = [AudioGenerater new];
    
    //合成文件存放到本地目录，而不是临时目录
    NSString * tempFileName = [gen getAudioFileNameByQueue:audioList];
    NSString * tempPath = [[UDManager sharedUDManager] localFileFullPath:tempFileName];
    
    
    BOOL ret = [gen generateAudioWithAccompany:audioList
                                      filePath:tempPath
                                  beginSeconds:CMTimeGetSeconds(begin)
                                    endSeconds:CMTimeGetSeconds(end)
                                     overwrite:NO completed:completedNew];
    
    if(!ret)
    {
        isGenerateAudioing_ = NO;
    }
    return ret;
}
- (BOOL)recheckGenerateQueue
{
    if(isGenerating_) return NO;
    if(needCreateBGVideo_)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self recheckGenerateQueue];
        });
        return YES;
    }
    NSLog(@"generating.....or:%d size:%@",self.DeviceOrietation,NSStringFromCGSize(renderSize));
    
    isGenerating_ = YES;
    @try {
        if(![self needRegenerate])
        {
            AVPlayerItem * item = [self getPlayerItem];
            if(item && item.status==AVPlayerItemStatusReadyToPlay)
            {
                [self VideoGenerater:videoGenerater_ didPlayerItemReady:item];
                isGenerating_ = NO;
                return NO;
            }
        }
        else
        {
            [videoGenerater_ resetGenerateInfo];
        }
        
        if(self.addLyricLayer)
        {
            videoGenerater_.compositeLyric = YES;
            [self checkLyricInfo:lyricList_ begin:lyricBegin_ duration:lyricDuration_];
        }
        else
        {
            videoGenerater_.compositeLyric = NO;
        }
        if(self.addWaterMark)
        {
            videoGenerater_.waterMarkFile = waterMarkFile_;
        }
        else
        {
            videoGenerater_.waterMarkFile = nil;
        }
        videoGenerater_.mergeRate = mergeRate_;
        videoGenerater_.volRampSeconds = volRampSeconds_;
        
        [videoGenerater_ setTimeForMerge:secondsBeginForMerge_ end:secondsEndForMerge_];
        [videoGenerater_ setTimeForAudioMerge:secondsBeginForMerge_ end:secondsEndForMerge_];
        
//        if(self.mergeMTVItem.MTVID>0 || !self.addLyricLayer)
//        {
//            videoGenerater_.compositeLyric = NO;
//        }
//        else
//        {
//            videoGenerater_.compositeLyric = YES;
//        }
        
        
        NSArray * exportItemList = [[MediaListModel shareObject]checkMediaTimeLine:videoGenerater_.totalBeginTime endTime:videoGenerater_.totalEndTime resetBegin:YES];
        NSLog(@"export lits:%@",exportItemList);
        [[MediaListModel shareObject]checkTempAVStatus];
        
        BOOL needGenerateAudio = (audioList_ && audioList_.count>0);
        if(audioMixUrl_)
        {
            NSString * filePath = [HCFileManager checkPath:[audioMixUrl_ path]];
            if(filePath.length>5)
            {
                NSString * newPath = nil;
                [[UDManager sharedUDManager]isFileExistAndNotEmpty:filePath size:nil pathAlter:&newPath];
                if(newPath && newPath.length>5)
                {
                    PP_RELEASE(audioMixUrl_);
                    audioMixUrl_ = [NSURL fileURLWithPath:newPath];
                    needGenerateAudio = NO;
                }
            }
        }
       
        if (needGenerateAudio) {
            BOOL ret = [self generateAudio:videoGenerater_.totalBeginTime
                                       end:videoGenerater_.totalEndTime
                                 completed:^(NSURL * audioUrl,NSError * error)
                        {
                            [videoGenerater_ generatePreviewAsset:exportItemList bgVolume:playVolumeWhenRecord_ singVolume:singVolume_ completion:^(BOOL finished) {
                                isGenerating_ = NO;
                            }];
                            //                            [videoGenerater_ updateChooseQueueWithPlayerMedia:[self exportPlayItemArray:self.backgroundVideo fillWithTrans:NO] bgAudioVolume:playVolumeWhenRecord_ singVolume:singVolume_];
                            
                        }
                        ];
            if(!ret)
            {
                isGenerating_ = NO;
            }
        }
        else
        {
            [videoGenerater_ generatePreviewAsset:exportItemList bgVolume:playVolumeWhenRecord_ singVolume:singVolume_ completion:^(BOOL finished) {
                isGenerating_ = NO;
            }];
            //            [videoGenerater_ updateChooseQueueWithPlayerMedia:[self exportPlayItemArray:self.backgroundVideo fillWithTrans:NO] bgAudioVolume:playVolumeWhenRecord_ singVolume:singVolume_];
            //            isGenerating_ = NO;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception :%@",exception);
    }
    @finally {
        isGenerateAudioing_ = NO;
        isGenerating_ = NO;
    }
    return YES;
}
- (void)checkLyricInfo:(NSArray*)lyricList begin:(CGFloat)lyricBegin duration:(CGFloat)lyricDuration
{
    if(!lyricList || lyricList.count==0)
    {
        if(self.CurrentSample && self.CurrentSample.Lyric && self.CurrentSample.Lyric.length>2 && ( !lyricList_||lyricList_.count==0))
        {
            lyricList = [[LyricHelper sharedObject]getSongLrcWithUrl:self.CurrentSample.Lyric metas:nil];
            //歌词的时间应该是分两种情况：1、录相的 2、只唱的。其时间应该是录相的基准时间+开始合成的时间
            //        lyricBegin_ = secondsBeginForMerge_;
            //        lyricDuration_ = secondsEndForMerge_ - secondsBeginForMerge_;
        }
    }
    if(lyricList == lyricList_ && lyricBegin_ == lyricBegin) return;
    [self setLyricArray:lyricList atTime:lyricBegin duration:lyricDuration watermarkFile:CT_WATERMARKFILE];
}
- (void)joinMedias:(int)retryCount
{
    if([videoGenerater_ canMerge])
    {
        [videoGenerater_ generateMVFile:nil retryCount:retryCount];
        return;
    }
    
    [self checkLyricInfo:lyricList_ begin:lyricBegin_ duration:lyricDuration_];
    
    videoGenerater_.mergeRate = mergeRate_;
    videoGenerater_.volRampSeconds = volRampSeconds_;
    
    //调置合成的时间
    [videoGenerater_ setTimeForMerge:secondsBeginForMerge_ end:secondsEndForMerge_];
    [videoGenerater_ setTimeForAudioMerge:secondsBeginForMerge_ end:secondsEndForMerge_];
    
    
    
    NSArray * exportItemList = [[MediaListModel shareObject]checkMediaTimeLine:videoGenerater_.totalBeginTime
                                                                       endTime:videoGenerater_.totalEndTime
                                                                    resetBegin:YES];
    
    if([videoGenerater_ needRebuildPreviewMV:exportItemList bgVol:playVolumeWhenRecord_ singVol:singVolume_])
    {
        if(isGenerating_) return;
        isGenerating_ = YES;
        [videoGenerater_ resetGenerateInfo];
        
        if(self.mergeMTVItem.MTVID>0)
        {
            videoGenerater_.compositeLyric = NO;
        }
        else
            videoGenerater_.compositeLyric = YES;
        
        [videoGenerater_ generatePreviewAsset:exportItemList bgVolume:playVolumeWhenRecord_ singVolume:singVolume_ completion:^(BOOL finished) {
            [videoGenerater_ generateMVFile:exportItemList retryCount:retryCount];
            isGenerating_ = NO;
        }];
        //        [videoGenerater_ updateChooseQueue:[self exportPlayItemArray:self.backgroundVideo fillWithTrans:NO]
        //                                completed:^(BOOL finished)
        //         {
        //             [videoGenerater_ joinCurrentVideosWithAudios:retryCount bgAudioVolume:playVolumeWhenRecord_ singVolume:singVolume_];
        //         }];
    }
    else
    {
        [videoGenerater_ generateMVFile:exportItemList retryCount:retryCount];
        //        [videoGenerater_ joinCurrentVideosWithAudios:retryCount bgAudioVolume:playVolumeWhenRecord_ singVolume:singVolume_];
    }
}
- (void)cancelExporter
{
    [videoGenerater_ cancelExporter];
}
- (void)regenerateItems
{
    if(isGenerating_) return;
    isGenerating_ = YES;
    if(self.mergeMTVItem.MTVID>0)
    {
        videoGenerater_.compositeLyric = NO;
    }
    else
    {
        videoGenerater_.compositeLyric = YES;
    }
    [videoGenerater_ generatePreviewAsset:mediaList_ bgVolume:playVolumeWhenRecord_ singVolume:singVolume_ completion:^(BOOL finished) {
        isGenerating_ = NO;
    }];
    //    [videoGenerater_ generatePreviewAVasset:nil];
}
#pragma mark - seenvideoqueue deleate
- (void)VideoGenerater:(VideoGenerater *)queue generateReverseProgress:(CGFloat)progress
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(VideoGenerater:generateReverseProgress:)])
    {
        [self.delegate VideoGenerater:queue generateReverseProgress:progress];
    }
}
- (void)VideoGenerater:(VideoGenerater *)queue didItemsChanged:(BOOL)finished
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(VideoGenerater:didItemsChanged:)])
    {
        [self.delegate VideoGenerater:queue didItemsChanged:finished];
    }
}
- (void)VideoGenerater:(VideoGenerater*)queue didPlayerItemReady:(AVPlayerItem *)playerItem
{
    PP_RELEASE(currentPlayerItem_);
    currentPlayerItem_ = PP_RETAIN(playerItem);
    needRegenerate_ = NO;
    orgSingVolumne_ = singVolume_;
    orgBgVolume_ = playVolumeWhenRecord_;
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(VideoGenerater:didPlayerItemReady:)])
    {
        [self.delegate VideoGenerater:queue didPlayerItemReady:playerItem];
    }
}
- (void)VideoGenerater:(VideoGenerater *)queue generateProgress:(CGFloat)progress
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(VideoGenerater:generateProgress:)])
    {
        [self.delegate VideoGenerater:queue generateProgress:progress];
    }
    
}
- (void)VideoGenerater:(VideoGenerater *)queue didGenerateCompleted:(NSURL *)fileUrl cover:(NSString *)cover
{
    //重置起止时间
    [videoGenerater_ setTimeForMerge:0 end:0];
    [videoGenerater_ setTimeForAudioMerge:0 end:0];
    needRegenerate_ = NO;
    orgSingVolumne_ = singVolume_;
    orgBgVolume_ = playVolumeWhenRecord_;
    
    
    //    重命名声音文件
    NSString * filePath = [self copyVideoFileToTarget:[fileUrl path]
                                            audioPath:[[queue joinAudioUrl] path]
                                             sampleID:(int)SampleID
                                               userID:[UserManager sharedUserManager].userID
                                                begin:kCMTimeZero
                                                  end:kCMTimeZero];
    if(filePath && filePath.length>0)
    {
        fileUrl = [NSURL fileURLWithPath:filePath];
    }
    
    //    if([self hasAlassetRights])
    //    {
    //        [self copyUploadedMTV2Album:filePath
    //                              mtvID:0
    //                               item:nil
    //                            showMsg:@"保存到相册失败"];
    //    }
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(VideoGenerater:didGenerateCompleted:cover:)])
    {
        [self.delegate VideoGenerater:queue didGenerateCompleted:fileUrl cover:cover];
    }
}
- (void)VideoGenerater:(VideoGenerater *)queue didGenerateFailure:(NSString *)msg error:(NSError *)error
{
    [videoGenerater_ setTimeForMerge:0 end:0];
    [videoGenerater_ setTimeForAudioMerge:0 end:0];
    needRegenerate_ = YES;
    PP_RELEASE(currentPlayerItem_);
    if(self.delegate && [self.delegate respondsToSelector:@selector(VideoGenerater:didGenerateFailure:error:)])
    {
        [self.delegate VideoGenerater:queue didGenerateFailure:msg error:error];
    }
}
#pragma mark - alasset
//typedef enum {
//    kCLAuthorizationStatusNotDetermined = 0, // 用户尚未做出选择这个应用程序的问候
//    kCLAuthorizationStatusRestricted,        // 此应用程序没有被授权访问的照片数据。可能是家长控制权限
//    kCLAuthorizationStatusDenied,            // 用户已经明确否认了这一照片数据的应用程序访问
//    kCLAuthorizationStatusAuthorized         // 用户已经授权应用访问照片数据} CLAuthorizationStatus;
//}

#pragma mark - dealloc
- (void)clearFiles
{
    UDManager * um = [UDManager sharedUDManager];
    BOOL hasDraft = NO;
    if(self.SampleID>0)
    {
        hasDraft = [self hasDraft:self.SampleID copyToCurrent:NO];
    }
    NSLog(@"Sample:%ld hasdraft:%d",self.SampleID,hasDraft);
    if(hasDraft) return;
    
    //清理缓存的图片
    for (int i = (int)mediaList_.count-1;i>=0;i--) {
        MediaItem * item = mediaList_[i];
        NSString * fileName = item.filePath;
        [um removeThumnates:fileName size:CGSizeMake(0, 0)];
        
        //相册中的东东不可删除
        if(![HCFileManager isInAblum:fileName])
        {
            [[HCFileManager manager] removeFileAtPath:fileName];
        }
    }
    //    if(playItemList_)
    //    {
    //        for (int i = (int)playItemList_.count-1;i>=0;i--) {
    //            PlayerMediaItem * item = playItemList_[i];
    //            NSString * fileName = item.path;
    //            if(fileName && fileName.length>0)
    //            {
    //                [um removeThumnates:fileName size:CGSizeMake(0, 0)];
    //                if(![CommonUtil isInAblum:fileName])
    //                {
    //                    [um removeFileAtPath:fileName];
    //                }
    //            }
    //        }
    //    }
    for (int i = (int) audioList_.count-1;i>=0;i--) {
        AudioItem * item = audioList_[i];
        [[HCFileManager manager] removeFileAtPath:item.filePath];
    }
    //    if(coverMedialItem_)
    //    {
    //        [um removeFilesAtPath:coverMedialItem_.filePath];
    //        [um removeFilesAtPath:coverMedialItem_.cover];
    //    }
    //    //remove audiofiles
    //    NSString * regEx = @"\\.m4a$|_\\d+\\.\\{\\d+\\,\\d+\\}\\.jpg$|[a-f0-9]+\\-\\d+\\-\\d+\\.(mp4|chk)$";
    //
    //    NSString * dir = [[UDManager sharedUDManager] tempFileDir];
    //
    //    [[UDManager sharedUDManager]removeFilesAtPath:dir matchRegex:regEx];
    
    [videoGenerater_ clear];
    
}
#pragma mark - export media core list

#pragma mark - target file check/move
- (BOOL)checkAudioPath:(MTV *)mtv
{
    if(!mtv) return NO;
    if(!mtv.FileName && !mtv.AudioFileName) return NO;
    if(mtv.MTVID==0 && !mtv.AudioFileName) return NO;
    BOOL hasFile = NO;
    
    NSString * filePath = [mtv getAudioPathN];
    
    if(filePath && filePath.length>0)
    {
        if([[UDManager sharedUDManager]isFileExistAndNotEmpty:filePath size:nil])
        {
            NSLog(@"从临时文件中找到音频文件:%@",mtv.AudioFileName);
            hasFile = YES;
        }
    }
    
    if (!hasFile && mtv.FileName && mtv.FileName.length>0) {
        filePath = [[mtv getFilePathN] stringByAppendingPathExtension:@"m4a"];
        
        {
            if([[UDManager sharedUDManager]isFileExistAndNotEmpty:filePath size:nil])
            {
                [mtv setAudioPathN:filePath];
                NSLog(@"从临时文件中找到音频文件:%@",mtv.FileName);
                hasFile = YES;
            }
        }
        if(!hasFile)
        {
            [mtv setAudioPathN:nil];
            //            NSString * regex = @"/Application/[^/]+|/Applications/[^/]+";
            //            NSString * localApplication = [[UDManager sharedUDManager] getApplicationPath];
            //            mtv.AudioPath = [filePath stringByReplacingOccurrencesOfRegex:regex withString:localApplication];
        }
    }
    return hasFile;
}
- (NSString *)getVideoFileByTicks
{
    NSTimeInterval aInterval =[[NSDate date] timeIntervalSince1970];
    NSString * videoName = [[NSString stringWithFormat:@"%.0f",aInterval * 1000]
                            stringByAppendingString:@".mp4"];
    return videoName;
}
//- (BOOL)copyAudioFileToTarget:(MTV*)mtv
//{
//    if(!mtv.AudioPath || mtv.AudioPath.length==0) return NO;
//    if([self checkAudioPath:mtv])
//    {
//        NSString * ext = [CommonUtil getFileExtensionName:mtv.AudioPath defaultExt:@"m4a"];
//        NSString * audioFile = nil;
//        if(mtv.FilePath && mtv.FilePath.length>0)
//        {
//            audioFile = [NSString stringWithFormat:@"%@.%@",[mtv.FilePath lastPathComponent],ext];
//        }
//        else
//        {
//            audioFile = [NSString stringWithFormat:@"%@.%@",[[self getVideoFileByTicks] lastPathComponent],ext];
//        }
//        NSString * newFilePath = [[UDManager sharedUDManager]localFileFullPath:audioFile];
//        if(![newFilePath isEqualToString:mtv.AudioPath])
//        {
//            [CommonUtil copyFile:mtv.AudioPath target:newFilePath overwrite:YES];
//            [[UDManager sharedUDManager]removeFileAtPath:mtv.AudioPath];
//            [self setMixedAudio:newFilePath];
//            mtv.AudioPath = newFilePath;
//        }
//        return YES;
//    }
//    else
//    {
//        NSLog(@"audio file:%@ not exists.",mtv.AudioPath);
//    }
//    return NO;
//}
//- (BOOL) copyVideoFileToTarget:(MTV *)mtv
//{
//    NSString * videoPath = [CommonUtil checkPath:mtv.FilePath];
//    NSLog(@"video file:%@ exists.",mtv.FilePath);
//    NSString * path = [NSString stringWithFormat:@"%d-%d-%@",mtv.SampleID,mtv.UserID,videoPath.lastPathComponent];
//    NSString * newFilePath = [[UDManager sharedUDManager]localFileFullPath:[path lastPathComponent]];
//    if(![newFilePath isEqualToString:videoPath])
//    {
//        [CommonUtil copyFile:videoPath target:newFilePath overwrite:YES];
//        [[UDManager sharedUDManager]removeFileAtPath:videoPath];
//
//    }
//    NSLog(@"new videofile:%@",newFilePath);
//    mtv.FilePath = newFilePath;
//    return YES;
//}
- (NSString *) copyVideoFileToTarget:(NSString *)videoPath audioPath:(NSString*)audioPath sampleID:(long)sampleID userID:(long)userID
                               begin:(CMTime)begin end:(CMTime)end
{
    videoPath = [HCFileManager checkPath:videoPath];
    
    NSString * path = [videoPath lastPathComponent];
    NSInteger index = [path rangeOfString:@"."].location;
    if(index >=0 && index !=NSNotFound)
    {
        path = [path substringToIndex:index];
    }
    if(CMTimeCompare(end, kCMTimeZero)==0)
    {
        path = [NSString stringWithFormat:@"%ld-%ld-%@.mp4",sampleID,userID,path];
    }
    else
    {
        path = [NSString stringWithFormat:@"%ld-%ld-%@-%d-%d.mp4",sampleID,userID,path,(int)(CMTimeGetSeconds(begin)*10),(int)(CMTimeGetSeconds(end)*10)];
    }
    NSString * newFilePath = [[UDManager sharedUDManager]localFileFullPath:[path lastPathComponent]];
    if(![newFilePath isEqualToString:videoPath])
    {
        [HCFileManager copyFile:videoPath target:newFilePath overwrite:YES];
        [[HCFileManager manager]removeFileAtPath:videoPath];
        
    }
    if(audioPath && audioPath.length>0)
    {
        NSString * ext = [HCFileManager getFileExtensionName:audioPath defaultExt:@"m4a"];
        NSString * newAudioPath = [newFilePath stringByAppendingPathExtension:ext];
        if(![newAudioPath isEqualToString:audioPath])
        {
            [HCFileManager copyFile:audioPath target:newAudioPath overwrite:YES];
            [self setMixedAudio:newAudioPath];
            [[HCFileManager manager]removeFileAtPath:audioPath];
            if(self.mergeMTVItem && self.mergeMTVItem.AudioFileName && [[self.mergeMTVItem getAudioPathN] isEqualToString:audioPath])
            {
                [self.mergeMTVItem setAudioPathN: newAudioPath];
            }
        }
    }
    NSLog(@"new videofile:%@",newFilePath);
    return newFilePath;
}

#pragma mark - preview
- (void)setTimeForMerge:(CGFloat)secondsBegin end:(CGFloat)secondsEnd
{
    secondsBeginForMerge_ = secondsBegin;
    if(secondsEnd<0)
    {
        secondsEndForMerge_ = totalSecondsDuration_;
    }
    else
    {
        secondsEndForMerge_ = secondsEnd;
    }
}
- (CGFloat)secondsBeginForMerge
{
    return secondsBeginForMerge_;
}
- (CGFloat)secondsEndForMerge
{
    return secondsEndForMerge_;
}
- (void)copyContent:(MediaEditManager *)orgManager
{
    [audioList_ removeAllObjects];
    [mediaList_ removeAllObjects];
    [audioList_ addObjectsFromArray:orgManager.audioList];
    [mediaList_ addObjectsFromArray:orgManager.mediaList];
    totalDuration = orgManager.totalDuration;
    totalSecondsDuration_ = CMTimeGetSeconds(totalDuration);
    
    
    if(orgManager.backgroundVideo)
    {
        //文件全部当作本地的，不考虑远程文件
        MediaItem * item = orgManager.backgroundVideo;
        if(item.secondsDuration>0)
        {
            totalDuration = item.duration;
            totalSecondsDuration_ = CMTimeGetSeconds(totalDuration);
            totalSecondsDurationByFullItems_ = totalSecondsDuration_;
            backgroundVideo = PP_RETAIN(item);
            
            //设置合成视频的Size
            [videoGenerater_ setRenderSize:item.renderSize orientation:deviceOrietation_ withFontCamera:useFontCamera_];
            //            generateQueue_.renderSize = item.renderSize;
            videoGenerater_.bgvUrl = item.url;
            videoGenerater_.orientation = deviceOrietation_;
            videoGenerater_.mergeRate = mergeRate_;
            renderSize = item.renderSize;
        }
    }
    if(orgManager.backgroundAudio)
    {
        AudioItem * item = orgManager.backgroundAudio;
        
        backgroundAudio = PP_RETAIN(item);
        videoGenerater_.bgmUrl = item.url;
    }
    
    if(orgManager.coverImageUrl)
    {
        [self getImageDataFromUrl:orgManager.coverImageUrl size:self.renderSize];
    }
    
    self.NotAddCover = orgManager.NotAddCover;
    [self setSampleID:orgManager.SampleID];
    [self setSampleInfo:orgManager.CurrentSample];
    self.MTVID = orgManager.MTVID;
    self.MTVTitle = orgManager.MTVTitle;
    self.MBMTVID = orgManager.MBMTVID;
    
    [self setSingVolume:[orgManager getSingVolumn]];
    [self setPlayVolumeWhenRecording:[orgManager getPlayVolumn]];
    
}
- (void)removeAudioItemAfterSecondsInArray:(float)second
{
    [self removeVoiceItemAtTime:second duration:50*60];
    
    //    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:audioList_];
    //
    //    [self removeVoiceItemAtTime:second duration:50*60];
    //    for (AudioItem *item in tempArray) {
    //        if (item.secondsInArray >= second) {
    //            NSError *error = nil;
    //            [[NSFileManager defaultManager]removeItemAtPath:item.filePath error:&error];
    //            NSLog(@"record file delete error:%@", error.localizedDescription);
    //            [audioList_ removeObject:item];
    //        }
    //    }
}
//记录预览时生成的Audio文件
- (void)addPreviewAudioUrl:(NSURL *)url ForSampleID:(NSInteger)sampleID
{
    if(!url)
    {
        NSLog(@"addPreviewAudioUrl invalid parameter:url is null");
        return;
    }
    
    if (!previewAudio_) {
        previewAudio_ = [NSMutableDictionary new];
    }
    NSNumber *key = [NSNumber numberWithInteger:sampleID];
    NSURL *lastUrl = [previewAudio_ objectForKey:key];
    if (lastUrl && lastUrl.absoluteString.length && ![lastUrl.absoluteString isEqualToString:url.absoluteString]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:lastUrl error:&error];
        if (error) {
            NSLog(@"delete last generated audio file error: %@", error.localizedDescription);
        }
    }
    [previewAudio_ setObject:url forKey:key];
}
//删除预览时生成的Audio文件
- (void)deletePreviewAudioUrlForSampleID:(NSInteger)sampleID
{
    if (!previewAudio_) {
        previewAudio_ = [NSMutableDictionary new];
    }
    NSNumber *key = [NSNumber numberWithInteger:sampleID];
    NSURL *lastUrl = [previewAudio_ objectForKey:key];
    if (lastUrl) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:lastUrl error:nil];
        [previewAudio_ removeObjectForKey:key];
        if (error) {
            NSLog(@"delete last generated audio file error: %@", error.localizedDescription);
        }
    }
}
//即时合成，录一小段，马上合成
//从当前视频中截取一段，与音乐合成在一起。
- (BOOL)generateMVSegment:(CMTime)beginTime end:(CMTime) endTime
                   userID:(NSInteger)userID sampleID:(NSInteger)sampleID
                 progress:(MEProgress)progress
                    ready:(MEPlayerItemReady)itemReady
                completed:(MECompleted)complted
                  failure:(MEFailure)failure
{
    return [self generateMVSegment:backgroundVideo.url audios:nil
                             begin:beginTime end:endTime
                            userID:userID sampleID:sampleID
                      accompnayVol:playVolumeWhenRecord_
                           singVol:singVolume_
                          progress:progress
                             ready:itemReady
                         completed:complted failure:failure];
}

- (BOOL)generateMVSegment:(NSURL *)accompnayUrl audios:(NSArray*)audios
                    begin:(CMTime)beginTime end:(CMTime) endTime
                   userID:(NSInteger)userID sampleID:(NSInteger)sampleID
             accompnayVol:(CGFloat)accompanyVol singVol:(CGFloat)singVol
                 progress:(MEProgress)progress
                    ready:(MEPlayerItemReady)itemReady
                completed:(MECompleted)complted
                  failure:(MEFailure)failure
{
    if (!accompnayUrl) {
        accompnayUrl = backgroundVideo.url;
    }
    if (!audios) {
        audios = [self exportAudioItemsArray];;
    }
    if(isGenerating_)
    {
        [self cancelExporter];
    }
    NSLog(@"generating.....");
    isGenerating_ = YES;
    @try {
        VideoGenerater * generate = [VideoGenerater new];
        generate.waterMarkFile = waterMarkFile_;
        generate.lrcList = lyricList_;
        generate.lrcBeginTime = lyricBegin_;
        generate.mergeRate = mergeRate_;
        [generate setRenderSize:self.renderSize orientation:deviceOrietation_ withFontCamera:useFontCamera_];
        //        generate.renderSize = self.renderSize;
        generate.orientation = deviceOrietation_;
        //        generate.bgvUrl = accompnayUrl;
        //        NSArray * audioList = [self exportAudioItemsArray];
        //
        //        __weak SeenVideoQueue * weakGenerate = generate;
        //
        //        BOOL ret = [generate  generateFianlAudio:audioList completed:^(NSURL * audioUrl,NSError * error)
        //                    {
        //                        isGenerateAudioing_ = NO;
        //                        PP_RELEASE(audioMixUrl_);
        //                        __strong SeenVideoQueue * genStrong = weakGenerate;
        //                        if(!error)
        //                        {
        //                            audioMixUrl_ = PP_RETAIN(audioUrl);
        //                            NSLog(@"export audio:%@ ok",[audioUrl absoluteString]);
        //                            [genStrong setJoinAudioUrlWithDraft:audioUrl];
        //                        }
        //                        else
        //                        {
        //                            if(failure)
        //                            {
        //                                failure(weakGenerate,[NSString stringWithFormat:@"export audio failure:%@",[error localizedDescription]],error);
        //                            }
        //                            NSLog(@"export audio failure:%@",[error localizedDescription]);
        //                            isGenerating_ = NO;
        //                            return;
        //                        }
        
        
        MECompleted completed2 = ^(VideoGenerater *queue,NSURL * mvUrl,NSString * coverPath)
        {
            //重命名声音文件
            NSString * filePath = [self copyVideoFileToTarget:[mvUrl path]
                                                    audioPath:[[queue joinAudioUrl] path]
                                                     sampleID:sampleID
                                                       userID:userID
                                                        begin:beginTime
                                                          end:endTime];
            if(filePath && filePath.length>0)
            {
                mvUrl = [NSURL fileURLWithPath:filePath];
            }
            
            //            if([self hasAlassetRights])
            //            {
            //                [self copyUploadedMTV2Album:filePath
            //                                      mtvID:0
            //                                       item:nil
            //                                    showMsg:@"保存到相册失败"];
            //            }
            
            if(complted)
            {
                complted(queue,mvUrl,coverPath);
            }
            isGenerating_ = NO;
        };
        
        MEFailure failure2 = ^(VideoGenerater *queue,NSString * msg,NSError * error)
        {
            if(failure)
            {
                failure(queue,msg,error);
            }
            isGenerating_ = NO;
        };
        
        //        MediaItem * bgVideoItem = [self getMediaItem:accompnayUrl];
        
        NSArray * videoItems = [[MediaListModel shareObject]checkMediaTimeLine:generate.totalBeginTime
                                                                       endTime:generate.totalEndTime
                                                                    resetBegin:YES];// exportPlayItemArray:bgVideoItem fillWithTrans:NO];
        
        BOOL ret = [generate generateMV:videoItems
                            accompanyMV:accompnayUrl
                                 audios:audios
                                  begin:beginTime
                                    end:endTime
                          bgAudioVolume:accompanyVol
                             singVolume:singVol
                               progress:progress
                                  ready:itemReady
                              completed:completed2
                                failure:failure2];
        if(!ret)
        {
            if(failure)
            {
                NSString * msg = @"合成视频失败，函数返回值:失败";
                NSError * error = [self buildError:msg];
                failure(generate,msg,error);
            }
            isGenerating_ = NO;
        }
        return ret;
        
    }
    @catch (NSException *exception) {
        NSLog(@"exception :%@",exception);
    }
    @finally {
        isGenerateAudioing_ = NO;
        isGenerating_ = NO;
    }
    return YES;
}
#pragma mark - move to album
//将完成的视频移到相册，让用户管理。暂不考虑播放时用相册缓存的问题
- (void)copyUploadedMTV2Album:(NSString *)filePath mtvID:(long)mtvID item:(MTV*)mtvItem showMsg:(NSString *)msg
{
    NSURL * url = [NSURL fileURLWithPath:filePath];
    [self saveVideo2Album:url handler:^(NSURL *assetURL, NSError *error) {
        if (error || (!assetURL)) {
            NSLog(@"Save video fail:%@",error);
            if(msg && msg.length>0)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:msg
                                                                message:[error localizedDescription]
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        } else {
            NSLog(@"Save video succeed.%@",[assetURL absoluteString]);
        }
    }];
}
- (BOOL)isInAblum:(NSURL *)url
{
    NSString * urlString = [url absoluteString];
    if([urlString hasPrefix:@"assets-library://"])
    {
        return YES;
    }
    return NO;
}
- (void)saveVideo2Album:(NSURL *)url handler:(ALAssetsLibraryWriteVideoCompletionBlock)completionBlock
{
    if([self isInAblum:url])
    {
        if(completionBlock)
        {
            NSError * error = [NSError errorWithDomain:@"seenvoice" code:-1
                                              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        [NSString stringWithFormat:@"file: %@ is exist in album",[url absoluteString]],
                                                        NSLocalizedDescriptionKey, nil]];
            completionBlock(nil,error);
        }
        return;
    }
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    if(![library videoAtPathIsCompatibleWithSavedPhotosAlbum:url])
    {
        NSLog(@"Save video to ablum fail:not compatible %@",[url absoluteString]);
        
        if(completionBlock)
        {
            NSError * error = [NSError errorWithDomain:@"seenvoice" code:-1
                                              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        [NSString stringWithFormat:@"ablum file type incompatible %@",[url absoluteString]],
                                                        NSLocalizedDescriptionKey, nil]];
            completionBlock(nil,error);
            
        }
        return;
    }
    [library writeVideoAtPathToSavedPhotosAlbum:url
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    if(completionBlock!=nil)
                                    {
                                        completionBlock(assetURL,error);
                                    }
                                    else
                                    {
                                        if (error) {
                                            NSLog(@"Save video fail:%@",error);
                                        }
                                        else
                                        {
                                            NSLog(@"Save video succeed.%@",[assetURL absoluteString]);
                                            //                                            NSFileManager * fm = [NSFileManager defaultManager];
                                            //                                            NSError * error = nil;
                                            //                                            [fm removeItemAtURL:url error:&error];
                                            //                                            if(error)
                                            //                                            {
                                            //                                                NSLog(@"remove old file:%@ failure:%@",[url absoluteString],[error description]);
                                            //                                            }
                                        }
                                    }
                                }];
}
#pragma mark -
// 将原始图片的URL转化为NSData数据,写入沙盒
- (void)copyPhotoFromAlbum:(NSURL *)assetUrl withFilePath:(NSString *)filePath completed:(void(^)(BOOL finished))completed
{
    // 进这个方法的时候也应该加判断,如果已经转化了的就不要调用这个方法了
    // 如何判断已经转化了,通过是否存在文件路径
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (assetUrl) {
            // 主要方法
            [assetLibrary assetForURL:assetUrl resultBlock:^(ALAsset *asset) {
                ALAssetRepresentation *rep = [asset defaultRepresentation];
                
                UIImage * image = [UIImage imageWithCGImage:rep.fullScreenImage];
                
                //                Byte *buffer = (Byte*)malloc((unsigned long)rep.size);
                //                NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:((unsigned long)rep.size) error:nil];
                //                NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                //                UIImage * image = [UIImage imageWithData:data scale:1];
                
                [image fixOrientation];
                
                NSData * data =  UIImageJPEGRepresentation(image, 1);
                
                [data writeToFile:filePath atomically:YES];
                
                if(completed)
                {
                    completed(TRUE);
                }
            } failureBlock:^(NSError *error)
             {
                 NSLog(@"error :%@",[error localizedDescription]);
                 if(completed)
                 {
                     completed(NO);
                 }
             }];
        }
    });
}

// 将原始视频的URL转化为NSData数据,写入沙盒
- (void) copyMTVFromAlbum:(NSURL *)assetUrl withFilePath:(NSString *)filePath completed:(void(^)(BOOL finished,NSString * coverFile))completed
{
    if([HCFileManager isLocalFile:[assetUrl absoluteString]] && [HCFileManager isInAblum:[assetUrl absoluteString]]==NO)
    {
        [HCFileManager copyFile:[HCFileManager checkPath:[assetUrl path]] target:filePath overwrite:YES];
        NSString * coverPath = [NSString stringWithFormat:@"%@.jpg",filePath];
        
        AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:filePath]];
        if(asset && CMTimeGetSeconds(asset.duration)>0)
        {
            AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
            imageGenerator.appliesPreferredTrackTransform = YES;
            NSError *error = nil;
            CMTime actucalTime; //缩略图实际生成的时间
            
            CGImageRef BGImgRef = [imageGenerator copyCGImageAtTime:CMTimeMake(300, 600) actualTime:&actucalTime error:&error];
            if (error) {
                NSLog(@"截取视频图片失败:%@",error.localizedDescription);
                if(completed)
                {
                    completed(NO,nil);
                }
            }
            //    CMTimeShow(actucalTime);
            UIImage *image = [UIImage imageWithCGImage:BGImgRef];
            [UIImageJPEGRepresentation(image, 1.0) writeToFile:coverPath atomically:YES];
            
            if(completed)
            {
                completed(YES,coverPath);
            }
        }
        else
        {
            if(completed)
            {
                completed(NO,nil);
            }
        }
    }
    else
    {
        // 解析一下,为什么视频不像图片一样一次性开辟本身大小的内存写入?
        // 想想,如果1个视频有1G多,难道直接开辟1G多的空间大小来写?
        ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (assetUrl) {
                [assetLibrary assetForURL:assetUrl resultBlock:^(ALAsset *asset) {
                    ALAssetRepresentation *rep = [asset defaultRepresentation];
                    NSLog(@"rep size:%@",NSStringFromCGSize(rep.dimensions));
                    NSLog(@"desc:%@",rep.description);
                    if(!rep)
                    {
                        NSLog(@"error :rep is nil:%@",[assetUrl absoluteString]);
                        if(completed)
                        {
                            completed(NO,nil);
                        }
                        return;
                    }
                    NSString * coverPath = [NSString stringWithFormat:@"%@.jpg",filePath];
                    char const *cvideoPath = [filePath UTF8String];
                    FILE *file = fopen(cvideoPath, "a+");
                    if (file) {
                        {
                            const int bufferSize = 11024 * 1024;
                            // 初始化一个1M的buffer
                            Byte *buffer = (Byte*)malloc(bufferSize);
                            NSUInteger read = 0, offset = 0, written = 0;
                            NSError* err = nil;
                            if (rep.size != 0)
                            {
                                do {
                                    read = [rep getBytes:buffer fromOffset:offset length:bufferSize error:&err];
                                    written = fwrite(buffer, sizeof(char), read, file);
                                    offset += read;
                                } while (read != 0 && !err);//没到结尾，没出错，ok继续
                            }
                            // 释放缓冲区，关闭文件
                            free(buffer);
                            buffer = NULL;
                            fclose(file);
                            file = NULL;
                        }
                        {
                            CGImageRef  imageRef = [rep fullScreenImage];
                            UIImage * image = [UIImage imageWithCGImage:imageRef];
                            NSData *imageData = UIImageJPEGRepresentation(image, 1);
                            [imageData  writeToFile:coverPath atomically:YES];
                        }
                        if(completed)
                        {
                            completed(TRUE,coverPath);
                        }
                    }
                    else
                    {
                        if(completed)
                        {
                            completed(NO,nil);
                        }
                    }
                } failureBlock:^(NSError *error)
                 {
                     NSLog(@"error :%@",[error localizedDescription]);
                     if(completed)
                     {
                         completed(NO,nil);
                     }
                 }];
            }
            else
            {
                completed(NO,nil);
            }
        });
    }
}
#pragma mark - deallocate

- (NSError *)buildError:(NSString *)msg
{
    if(!msg) return nil;
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:msg
                                                         forKey:NSLocalizedDescriptionKey];
    NSError *aError = [NSError errorWithDomain:@"com.seenvoice.maiba" code:-1000 userInfo:userInfo];
    return aError;
}
//伴奏不动，只清除用户的信息
- (void)clearCurrentInfo
{
    mergeMTVItem = nil;
    MTVID = 0;
    MTVTitle = nil;
    _Memo = nil;
    
    PP_RELEASE(_Tags);
    PP_RELEASE(_Memo);
    
    PP_RELEASE(lyricList_);
    lyricBegin_ = 0;
    lyricDuration_ = -1;
    secondsBeginForMerge_ = 0;
    secondsEndForMerge_ = -1;
    SampleID = _CurrentSample?_CurrentSample.SampleID:0;
    _UserData = nil;
    
    [audioList_ removeAllObjects];
    [mediaList_ removeAllObjects];
    
    [[MediaListModel shareObject]clear];
}
- (void)clear
{
    NSLog(@"MediaEdit Clear....");
    
    [[MediaListModel shareObject]clear];
    
    mergeRate_ = 1.0;
    MTVID = 0;
    MBMTVID = 0;
    SampleID = 0;
    useFontCamera_ = NO;
    _UserData = nil;
    tempTotalSeconds_ = 60*60;
    //    generateQueue_
    [self setTimeForMerge:0 end:0];
    
    [self clearFiles];
    PP_RELEASE(_Tags);
    PP_RELEASE(_Memo);
    
    deviceOrietation_ = 0;
    
    renderSize = CGSizeMake(540,960);
    
    
    PP_RELEASE(waterMarkFile_);
    waterMarkFile_ = PP_RETAIN(CT_WATERMARKFILE);
    
    //    PP_RELEASE(WaterMarkLayer);
    PP_RELEASE(_CurrentSample);
    PP_RELEASE(sampleMTV_);
    PP_RELEASE(coverImageUrl);
    PP_RELEASE(backgroundAudio);
    PP_RELEASE(backgroundVideo);
    PP_RELEASE(coverMedialItem_);
    //    PP_RELEASE(dataList);
    //    PP_RELEASE(myMTVList);
    PP_RELEASE(accompanyDownKey);
    //    PP_RELEASE(justMergedMTV);
    
    PP_RELEASE(previewAudio_);
    
    isGenerateAudioing_ = NO;
    isGenerating_ = NO;
    
    [self setMixedAudio:nil];
    
    self.NotAddCover = NO;
    playVolumeWhenRecord_ = 0.6;
    singVolume_ = 1;
    orgBgVolume_ = playVolumeWhenRecord_;
    orgSingVolumne_ = singVolume_;
    needRegenerate_ = NO;
    
    PP_RELEASE(lyricList_);
    lyricBegin_ = 0;
    lyricDuration_ = -1;
    secondsBeginForMerge_ = 0;
    secondsEndForMerge_ = -1;
    
    [audioList_ removeAllObjects];
    [mediaList_ removeAllObjects];
    //    [playItemList_ removeAllObjects];
    totalDuration = CMTimeMake(0, VIDEO_CTTIMESCALE);
    totalSecondsDuration_  =0 ;
    totalSecondsDurationByFullItems_ = 0;
    
    prevCompletedSeconds = -1;
    stepIndex = -1;
    PP_RELEASE(mergeFilePath);
    PP_RELEASE(mergeMTVItem);
    
    PP_RELEASE(audioMixUrl_);
}
- (void)dealloc
{
    PP_RELEASE(audioList_);
    PP_RELEASE(mediaList_);
    PP_SUPERDEALLOC;
}
#pragma mark - mixedAudio

- (BOOL)checkMTVItemOrientation:(MTV *)item
{
    if(self.DeviceOrietation == UIDeviceOrientationLandscapeLeft||
       self.DeviceOrietation == UIDeviceOrientationLandscapeRight)
    {
        item.IsLandscape = 1;
    }
    else if(self.DeviceOrietation==UIDeviceOrientationPortrait ||
            self.DeviceOrietation == UIDeviceOrientationPortraitUpsideDown)
    {
        item.IsLandscape = 0;
    }
    else if(item.FileName && [HCFileManager isFileExistAndNotEmpty:[item getFilePathN] size:nil])
    {
        item.IsLandscape = [self isAVLandscape:[item getFilePathN]];
    }
    NSLog(@"item orientation island:%d",item.IsLandscape);
    return item.IsLandscape>0;
}
- (short)isAVLandscape:(NSString *)path
{
    short isLandscape = -1;
    AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:[HCFileManager checkPath:path]]];
    if(asset && [asset tracksWithMediaType:AVMediaTypeVideo].count>0)
    {
        AVAssetTrack * track = [[asset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];
        //            int degree = [[MediaEditManager shareObject]degressFromVideoFileWithTrack:track];
        //            if(degree==90 ||degree==270)
        //            {
        //                item.IsLandscape = NO;
        //            }
        //            else
        //            {
        //                item.IsLandscape = YES;
        //            }
        //            return YES;
        CGSize avSize = track.naturalSize;
        isLandscape = [self isLandscapeBySize:avSize];
    }
    return isLandscape;
}
- (short)isLandscapeBySize:(CGSize )avSize
{
    DeviceConfig * config = [DeviceConfig config];
    CGSize scSize = CGSizeMake(config.Width,config.Height);
    
    BOOL isPortraitNormarl = YES;
    if(scSize.width > scSize.height)
    {
        isPortraitNormarl = NO;
    }
    
    if(avSize.width>0 && avSize.height>0)
    {
        if(avSize.height > avSize.width)
        {
            return (!isPortraitNormarl)?1:0;
        }
        else
        {
            return isPortraitNormarl?1:0;
        }
    }
    return -1;
}
//- (void) setCacheDataBetweenWindows:(MTV *)currentMtv sample:(Samples *)currentSample
//{
//    PP_RELEASE(_CurrentMTV);
//    PP_RELEASE(_CurrentSample);
//
//    _CurrentMTV = PP_RETAIN(currentMtv);
//    _CurrentSample = PP_RETAIN(currentSample);
//}
- (void)copyMTVFromAlbum:(NSURL *)assetUrl extInfo:(NSString *)extInfo completed:(void(^)(BOOL finished,NSString * localFile, NSString * coverPath))completed
{
    NSString * ext = [HCFileManager getFileExtensionName:extInfo defaultExt:@"mov"];
    NSString * localFile = [self getTempFileName:[NSString stringWithFormat:@"%@%ld.%@",[assetUrl absoluteString],[CommonUtil getDateTicks:[NSDate date]],ext]];
    if(localFile)
    {
        if([HCFileManager isExistsFile:localFile])
        {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError * error = nil;
            [fileManager removeItemAtPath:localFile error:&error];
            if(error)
            {
                NSLog(@"delete file:%@ error:%@",localFile,[error localizedDescription]);
            }
        }
    }
    //save
    [self copyMTVFromAlbum:assetUrl withFilePath:localFile completed:^(BOOL finished,NSString * coverPath) {
        if(completed)
        {
            completed(finished,localFile,coverPath);
        }
    }];
}
@end

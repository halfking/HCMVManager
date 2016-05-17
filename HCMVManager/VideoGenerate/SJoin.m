//
//  SJoin.m
//  AVAnimation
//
//  Created by Matthew on 16/5/13.
//  Copyright © 2016年 Matthew. All rights reserved.
//

#import "SJoin.h"
#import <CommonCrypto/CommonDigest.h>
#import "MediaActionDo.h"

@implementation SJoin
{
    NSArray * items_;
    NSString * path_;
    NSString * rPath_;
    CGFloat lastTime_;
    AVAssetExportSession *joinVideoExporter;
    AVMutableVideoComposition *mainComposition;
    AVMutableComposition *mixComposition;
}
-(instancetype)initWithPath:(NSString *)path withReverse:(NSString *)rPath withSitems:(NSArray *)items
{
    if (self = [super init]) {
        path_ = path;
        rPath_ = rPath;
        items_ = [[NSArray alloc] initWithArray:items];
        lastTime_ = 0;
        [self preJoin];
    }
    return  self;
}
-(void)resetPath:(NSString *)path withReverse:(NSString *)rPath withSitems:(NSArray *)items
{
    path_ = path;
    rPath_ = rPath;
    items_ = nil;
    items_ = [[NSArray alloc] initWithArray:items];
    lastTime_ = 0;
    [self preJoin];
}
-(void)preJoin
{
    if (joinVideoExporter) {
        [joinVideoExporter cancelExport];
        joinVideoExporter = nil;
    }
    mixComposition = [[AVMutableComposition alloc] init];
    NSMutableArray *layers  = [[NSMutableArray alloc] init];
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableVideoCompositionLayerInstruction *curLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    //将当前层保存到音频层管理器中
    
    AVAsset *curAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path_]];
    AVAsset *rAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:rPath_]];

    
//    for (int i = 0; i< items_.count; i ++) {
//        SItem * tem = (SItem *)[items_ objectAtIndex:i];
//        int32_t timeScale = curAsset.duration.timescale;
//        CMTime start = CMTimeMakeWithSeconds(lastTime_, timeScale);
//        CMTime diff;
//        CMTime trackDur = videoTrack.timeRange.duration;
//        if (isnan(CMTimeGetSeconds(trackDur))) {
//            trackDur = kCMTimeZero;
//        }
//        NSLog(@"videotrack dur = %.3f", CMTimeGetSeconds(trackDur));
//        AVAssetTrack * cTrack = [[curAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//        AVAssetTrack * rTrack = [[rAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//        switch (tem.type) {
//            case SFast:
//            {
//                if (tem.sTime > lastTime_) {
//                    //插入原视频片段<lasttime, tem.st>
//                    diff = CMTimeMakeWithSeconds(tem.sTime - lastTime_, timeScale);
//                    [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//                    trackDur = videoTrack.timeRange.duration;
//                    NSLog(@"videotrack dur = %.3f", CMTimeGetSeconds(trackDur));
//                }
//                //插入原视频片段<tem.st,tem.ed>，压缩range,使播放加速
//                diff = CMTimeMakeWithSeconds(tem.eTime - tem.sTime, timeScale);
//                start = CMTimeMakeWithSeconds(tem.sTime, timeScale);
//                [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//                [videoTrack scaleTimeRange:CMTimeRangeMake(trackDur, diff) toDuration:CMTimeMakeWithSeconds((tem.eTime- tem.sTime) / 2, timeScale)];
//                lastTime_ = tem.eTime;
//            }
//                break;
//            case SSlow:
//            {
//                if (tem.sTime > lastTime_) {
//                    //插入原视频片段<lasttime, tem.st>
//                    diff = CMTimeMakeWithSeconds(tem.sTime - lastTime_, timeScale);
//                    [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//                    trackDur = videoTrack.timeRange.duration;
//                    NSLog(@"videotrack dur = %.3f", CMTimeGetSeconds(trackDur));
//                }
//                //插入原视频片段<tem.st,tem.ed>，延展range,使播放减速
//                diff = CMTimeMakeWithSeconds(tem.eTime - tem.sTime, timeScale);
//                start = CMTimeMakeWithSeconds(tem.sTime, timeScale);
//                [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//                [videoTrack scaleTimeRange:CMTimeRangeMake(trackDur, diff) toDuration:CMTimeMakeWithSeconds((tem.eTime- tem.sTime) * 2, timeScale)];
//                lastTime_ = tem.eTime;
//            }
//                break;
//            case SRepeat:
//            {
//                if (tem.sTime > lastTime_) {
//                    //插入片段
//                    diff = CMTimeMakeWithSeconds(tem.sTime - lastTime_, timeScale);
//                    [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//                    trackDur = videoTrack.timeRange.duration;
//                    NSLog(@"videotrack dur = %.3f", CMTimeGetSeconds(trackDur));
//                }
//                //回退0.5s并反复插入
//                diff = CMTimeMakeWithSeconds(0.5, timeScale);
//                start = CMTimeMakeWithSeconds(tem.sTime - 0.5, timeScale);
//                [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//                trackDur = videoTrack.timeRange.duration;
//                [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//                trackDur = videoTrack.timeRange.duration;
//                [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//                trackDur = videoTrack.timeRange.duration;
//                lastTime_ = tem.sTime;
//            }
//                break;
//            case SReverse:
//            {
//                CGFloat stInOrigin = CMTimeGetSeconds(curAsset.duration) - tem.sTime;
//                if (stInOrigin > lastTime_) {
//                    //插入正向片段
//                    diff = CMTimeMakeWithSeconds(tem.sTime - lastTime_, timeScale);
//                    [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//                    trackDur = videoTrack.timeRange.duration;
//                    NSLog(@"videotrack dur = %.3f", CMTimeGetSeconds(trackDur));
//                }
//                //插入反向片段 rAsset<sTime, eTime>
//                diff = CMTimeMakeWithSeconds(tem.eTime - tem.sTime, timeScale);
//                start = CMTimeMakeWithSeconds(tem.sTime, timeScale);
//                [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:rTrack atTime:trackDur error:nil];
//                lastTime_ = CMTimeGetSeconds(curAsset.duration) - tem.eTime;
//            }
//                break;
//            default:
//            {
//                NSLog(@"finish mark");
//                if (tem.eTime && tem.eTime > lastTime_) {
//                    diff = CMTimeMakeWithSeconds(tem.eTime - lastTime_, timeScale);
//                    [videoTrack insertTimeRange:CMTimeRangeMake(start, diff) ofTrack:cTrack atTime:trackDur error:nil];
//                    trackDur = videoTrack.timeRange.duration;
//                    NSLog(@"videotrack dur = %.3f", CMTimeGetSeconds(trackDur));
//                }
//            }
//                break;
//        }
//    }
//    
//    [layers addObject:curLayerInstruction];
//    mainInstruction.timeRange = videoTrack.timeRange;
//    mainInstruction.layerInstructions = [[NSArray alloc] initWithArray:layers];
//    mainComposition = [AVMutableVideoComposition videoComposition];
//    mainComposition.instructions = [NSArray arrayWithObjects:mainInstruction,nil];
//    mainComposition.frameDuration = CMTimeMake(1, 30);
//    _RenderSize = [[curAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0].naturalSize;
//    mainComposition.renderSize = _RenderSize;
}
-(void)join
{
    NSLog(@"start join video!");
    NSURL * pathForFinalVideo = [self finalVideoUrl];
    joinVideoExporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    joinVideoExporter.outputURL = pathForFinalVideo;
    joinVideoExporter.outputFileType = AVFileTypeQuickTimeMovie;
    joinVideoExporter.shouldOptimizeForNetworkUse = YES;
    joinVideoExporter.videoComposition = mainComposition;
    [joinVideoExporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self exportDidFinish:joinVideoExporter];
        });
    }];
}

-(NSURL *)finalVideoUrl
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSTimeInterval time  = [[NSDate date] timeIntervalSince1970];
    
    NSString *newVideoName = [NSString stringWithFormat:@"%@.mp4",[self urlMd5:[NSString stringWithFormat:@"%.0f",time]]];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"%@",newVideoName]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:myPathDocs error:NULL];
    
    NSURL *url = [NSURL fileURLWithPath:myPathDocs];
    return url;
    
}
-(void)exportDidFinish:(AVAssetExportSession*)session{
    
    NSLog(@"exportDidFinish");
    NSLog(@"%@", session.outputURL.absoluteString);
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = session.outputURL;
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL])  {
            [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        NSLog(@"exporter error!!");
                    }else {
                        NSLog(@"exporter success!!");
                    }
                });
            }];
        }
    }else {
        NSLog(@"error!");
    }
}
-(void)cancelJoin
{
    if (joinVideoExporter) {
        [joinVideoExporter cancelExport];
        joinVideoExporter = nil;
    }
}
- (NSString *)urlMd5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end

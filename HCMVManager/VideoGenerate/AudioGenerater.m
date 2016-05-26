//
//  AudioGenerater.m
//  maiba
//
//  Created by HUANGXUTAO on 16/4/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "AudioGenerater.h"
//#import "PlayerMediaItem.h"
#import <hccoren/base.h>
#import <hccoren/RegexKitLite.h>
#import <hccoren/images.h>
//#import <hccoren/HCFileManager.h>
//#import <hcbasesystem/UDManager(Helper).h>
#import "MediaEditManager.h"
#import "MediaItem.h"

@implementation AudioGenerater
- (id)init
{
    if(self = [super init])
    {
        defaultAudioScale_ = 44100;
    }
    return self;
}
#pragma mark - new functions for generateit
- (BOOL) generateAudioWithRange:(NSURL *)audioUrl
                   beginSeconds:(CGFloat)beginSeconds
                     endSeconds:(CGFloat)endSeconds
                     targetFile:(NSString*)targetFile
                      completed:(void(^)(NSURL *audioUrl, NSError *error))completeHandler
{
    if(!audioUrl || !targetFile) return NO;
    AVURLAsset * curAsset = [[AVURLAsset alloc]initWithURL:audioUrl options:nil];
    
    if(!curAsset || curAsset.duration.value==0 ||curAsset.duration.timescale < 1000)
    {
        NSLog(@"audio file not exists:%@",[audioUrl path]);
        return NO;
    }
    else
    {
        if(curAsset.duration.timescale>0 && curAsset.duration.timescale!=defaultAudioScale_)
        {
            defaultAudioScale_ = curAsset.duration.timescale;
        }
        CGFloat duration = CMTimeGetSeconds(curAsset.duration);
        if(duration <= beginSeconds)
        {
            NSLog(@"file length not enought.");
            return NO;
        }
        if(duration<endSeconds)
        {
            endSeconds = duration;
        }
    }
    //申明组合器
    AVMutableComposition *composition = [AVMutableComposition composition];
    //申明音频层管理器
    NSMutableArray * audioMixParams = [[NSMutableArray alloc] init];
    //构建参数
    AVMutableCompositionTrack *curTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                   preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableAudioMixInputParameters *curTrackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:curTrack];
    NSError * error = nil;
    if(![curTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(beginSeconds, defaultAudioScale_),
                                                  CMTimeMakeWithSeconds(endSeconds - beginSeconds, defaultAudioScale_))
                          ofTrack:[[curAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                           atTime:kCMTimeZero
                            error:&error])
    {
        NSLog(@"join audio failure:%@",[error localizedDescription]);
        return NO;
    }
    
    [audioMixParams addObject:curTrackMix];
    
    NSURL * targetUrl = [NSURL fileURLWithPath:[HCFileManager checkPath:targetFile]];
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = [NSArray arrayWithArray:audioMixParams];
    
    AVAssetExportSession * exporter= [[AVAssetExportSession alloc] initWithAsset: composition presetName: AVAssetExportPresetAppleM4A];
    exporter.audioMix = audioMix;
    exporter.outputFileType = AVFileTypeAppleM4A;
    exporter.shouldOptimizeForNetworkUse = YES;
    
    exporter.outputURL = targetUrl;
    if ([[NSFileManager defaultManager] fileExistsAtPath:targetFile]) {
        NSLog(@"删除同名文件声音文件：%@！！！",[audioUrl path]);
        if ([[NSFileManager defaultManager] removeItemAtPath:targetFile error:NULL]) {
            NSLog(@"删除文件成功！！！");
        } else {
            NSLog(@"删除文件失败！！！");
        }
    }
    // do the export
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        int exportStatus = exporter.status;
        switch (exportStatus) {
            case AVAssetExportSessionStatusFailed:{
#ifndef __OPTIMIZE__
                NSError *exportError = exporter.error;
                NSLog (@"AVAssetExportSessionStatusFailed: %@", exportError);
#endif
                break;
            }
                
            case AVAssetExportSessionStatusCompleted: NSLog (@"AVAssetExportSessionStatusCompleted");
                break;
            case AVAssetExportSessionStatusUnknown: NSLog (@"AVAssetExportSessionStatusUnknown"); break;
            case AVAssetExportSessionStatusExporting: NSLog (@"AVAssetExportSessionStatusExporting"); break;
            case AVAssetExportSessionStatusCancelled: NSLog (@"AVAssetExportSessionStatusCancelled"); break;
            case AVAssetExportSessionStatusWaiting: NSLog (@"AVAssetExportSessionStatusWaiting"); break;
            default:  NSLog (@"didn't get export status"); break;
        }
        
        if(exportStatus == AVAssetExportSessionStatusCompleted)
        {
            completeHandler(targetUrl,nil);
        }
        else
        {
            completeHandler(targetUrl,exporter.error);
        }
    }];
    
    return YES;
}
-(BOOL) generateAudioWithAccompany:(NSArray *)audioItemQueue
//                         Accompany:(NSURL *)accompany
                          filePath:(NSString *) filePath
                      beginSeconds:(CGFloat)beginSeconds
                        endSeconds:(CGFloat)endSeconds
                         overwrite:(BOOL) overwrite
                         completed:(void(^)(NSURL *audioUrl, NSError *error))completeHandler
{
    if (!audioItemQueue || !audioItemQueue.count) {
        NSLog(@"Import AudioItemQueue Is Empty!");
        //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //            completeHandler(nil,[self buildError:@"录制的声音队列为空"]);
        //        });
        return NO;
    }
    if(!filePath || filePath.length==0)
    {
        NSLog(@"target file path is empty.");
        //        completeHandler(nil,[self buildError:@"目标文件路径不能为空"]);
        return NO;
    }
    //    NSString * bgvUrl = accompany;
    
    NSURL * audioUrl = [NSURL fileURLWithPath:filePath];
    
    NSLog(@"check audio file exists...");
    
    if([HCFileManager isFileExistAndNotEmpty:[HCFileManager checkPath:filePath] size:nil])
    {
        if(!overwrite)
        {
            NSLog(@"check audio file exsits (%@)....",filePath);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                completeHandler(audioUrl,nil);
            });
            return YES;
        }
        else
        {
            [[NSFileManager defaultManager]removeItemAtPath:filePath error:nil];
        }
    }
    
    CMTime beginTime = CMTimeMakeWithSeconds(beginSeconds,defaultAudioScale_);
    CMTime endTime = CMTimeMakeWithSeconds(endSeconds,defaultAudioScale_);
    //这里的参数是合成所有的音频文件，并没有截取其中一部分
    audioItemQueue = [self checkAudioQueue:audioItemQueue beginTime:beginTime endTime:endTime resetBegin:NO];
    
    //申明组合器
    AVMutableComposition *composition = [AVMutableComposition composition];
    //申明音频层管理器
    NSMutableArray * audioMixParams = [[NSMutableArray alloc] init];
    
    //============添加用户的音频============
    CMTimeValue lastTimeValue = 0;
    
    for (int i = 0; i<audioItemQueue.count; i++) {
        AudioItem * curAudioItem = [audioItemQueue objectAtIndex:i];
        NSURL * curAdudioUrl = [NSURL fileURLWithPath:curAudioItem.filePath];
        AVURLAsset * curAsset = [[AVURLAsset alloc]initWithURL:curAdudioUrl options:nil];
        if(curAsset.duration.value==0 ||curAsset.duration.timescale < 1000)
        {
            NSLog(@"joinaudio:(%d) skip:(%.2f-- %.2f) intrack:(%.2f---%.2f)(%d)",i,curAudioItem.secondsInArray,curAudioItem.secondsDurationInArray,curAudioItem.secondsBegin,curAudioItem.secondsEnd,curAsset.duration.timescale);
            CMTimeValue curEnd = (curAudioItem.secondsInArray + curAudioItem.secondsDurationInArray) * defaultAudioScale_;
            if(curEnd> lastTimeValue)
                lastTimeValue = curEnd;
            continue;
        }
        
        NSLog(@"%ld,%ld",(long)curAsset.duration.timescale,(long)curAsset.duration.value);
        UInt32 curAudioTimescale =  curAsset.duration.timescale;
        if(curAudioTimescale>0 && curAudioTimescale>defaultAudioScale_) //需要统一码流
        {
            defaultAudioScale_ = curAudioTimescale;
        }
        //        CMTime stInQ = CMTimeMakeWithSeconds(curAudioItem.secondsInArray, curAudioTimescale);
        //        CMTime edInQ = CMTimeMakeWithSeconds(curAudioItem.secondsInArray + curAudioItem.secondsDurationInArray, curAudioTimescale);
        
        
        CMTime stInQ = CMTimeMakeWithSeconds(curAudioItem.secondsInArray, defaultAudioScale_);
        CMTime edInQ = CMTimeMakeWithSeconds(curAudioItem.secondsInArray + curAudioItem.secondsDurationInArray, defaultAudioScale_);
        
        //接好
        edInQ.value = edInQ.value + lastTimeValue - stInQ.value;
        stInQ.value = lastTimeValue;
        lastTimeValue = edInQ.value;
        
        
        CMTime beginInFile = CMTimeMakeWithSeconds(curAudioItem.secondsBegin, curAudioTimescale);
        CMTime durationInFile = CMTimeMakeWithSeconds(curAudioItem.secondsDurationInArray, curAudioTimescale);
        NSLog(@"joinaudio:(%d) timeline:(%.2f-- %.2f) intrack:(%.2f---%.2f)(%d)",i,curAudioItem.secondsInArray,curAudioItem.secondsDurationInArray,curAudioItem.secondsBegin,curAudioItem.secondsEnd,(unsigned int)curAudioTimescale);
        
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
        
    }
    
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = [NSArray arrayWithArray:audioMixParams];
    
    AVAssetExportSession * exporter= [[AVAssetExportSession alloc] initWithAsset: composition presetName: AVAssetExportPresetAppleM4A];
    //    SDAVAssetExportSession *exporter = [SDAVAssetExportSession exportSessionWithAsset:composition];
    exporter.audioMix = audioMix;
    exporter.outputFileType = AVFileTypeAppleM4A;
    exporter.shouldOptimizeForNetworkUse = YES;
    
    //    exporter.audioSettings = @{
    //                                        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
    //                                        AVNumberOfChannelsKey: @2,
    //                                        AVSampleRateKey: @44100,
    //                                        AVEncoderBitRateKey: @160000,
    //                                        };
    
    exporter.outputURL = audioUrl;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[audioUrl path]]) {
        NSLog(@"删除同名文件声音文件：%@！！！",[audioUrl path]);
        if ([[NSFileManager defaultManager] removeItemAtPath:[audioUrl path] error:NULL]) {
            NSLog(@"删除文件成功！！！");
        } else {
            NSLog(@"删除文件失败！！！");
        }
    }
    // do the export
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        int exportStatus = exporter.status;
        switch (exportStatus) {
            case AVAssetExportSessionStatusFailed:{
#ifndef __OPTIMIZE__
                NSError *exportError = exporter.error;
                NSLog (@"AVAssetExportSessionStatusFailed: %@", exportError);
#endif
                break;
            }
                
            case AVAssetExportSessionStatusCompleted: NSLog (@"AVAssetExportSessionStatusCompleted");
                break;
            case AVAssetExportSessionStatusUnknown: NSLog (@"AVAssetExportSessionStatusUnknown"); break;
            case AVAssetExportSessionStatusExporting: NSLog (@"AVAssetExportSessionStatusExporting"); break;
            case AVAssetExportSessionStatusCancelled: NSLog (@"AVAssetExportSessionStatusCancelled"); break;
            case AVAssetExportSessionStatusWaiting: NSLog (@"AVAssetExportSessionStatusWaiting"); break;
            default:  NSLog (@"didn't get export status"); break;
        }
        
        if(exportStatus == AVAssetExportSessionStatusCompleted)
        {
            completeHandler(audioUrl,nil);
        }
        else
        {
            completeHandler(audioUrl,exporter.error);
        }
    }];
    
    return YES;
}

- (NSString *) scaleAudio:(AVAsset *)asset withRate:(CGFloat)rate beginSeconds:(CGFloat)beginSeconds
               endSeconds:(CGFloat)endSeconds
{
    NSString * filePath =  nil;
    if(!asset) return nil;
    @synchronized (self) {
        __block BOOL scaleAudio = YES;
        filePath = [NSString stringWithFormat:@"%ld.m4a",[CommonUtil getDateTicks:[NSDate date]]];
        filePath = [[HCFileManager manager] tempFileFullPath:filePath];
        
        if(![self scaleAudio:asset withRate:rate writeFile:filePath
         beginSeconds:beginSeconds endSeconds:endSeconds
               completed:^(NSURL *audioUrl, NSError *error) {
            scaleAudio = NO;
        }])
        {
            scaleAudio = NO;
        }
        while (scaleAudio) {
            [NSThread sleepForTimeInterval:0.1];
            NSLog(@"waiting for scale....");
        }
    }
    if(filePath && [HCFileManager isExistsFile:filePath])
        return filePath;
    else
        return nil;
}
- (BOOL) scaleAudio:(AVAsset *)asset withRate:(CGFloat)rate writeFile:(NSString *)targetFile
       beginSeconds:(CGFloat)beginSeconds
         endSeconds:(CGFloat)endSeconds
          completed:(void(^)(NSURL *audioUrl, NSError *error))completeHandler
{
    if(!asset) return NO;
    NSURL * audioUrl = [NSURL fileURLWithPath:targetFile];
    
    NSLog(@"check audio file exists...");
    
    if([HCFileManager isFileExistAndNotEmpty:[HCFileManager checkPath:targetFile] size:nil])
    {
        [[NSFileManager defaultManager]removeItemAtPath:targetFile error:nil];
    }
    
    NSArray * trackList = [asset tracksWithMediaType:AVMediaTypeAudio];
    if(trackList.count==0) return NO;
    
    //默认视频长度大于音频长度
    TimeScale bgScale = AUDIO_CTTIMESCALE;
    if(asset.duration.timescale>0)
    {
        bgScale = asset.duration.timescale;
    }
    CGFloat durationSeconds = CMTimeGetSeconds(asset.duration);
    
    if(beginSeconds>= durationSeconds) beginSeconds = 0;
    else if(beginSeconds<0) beginSeconds = 0;
    
//    CMTime bgAudioTime = asset.duration;
    CMTime startTime = CMTimeMakeWithSeconds(beginSeconds, bgScale);
    if(endSeconds <0) endSeconds = durationSeconds;
    
    CMTime duration = CMTimeMakeWithSeconds(endSeconds - beginSeconds,bgScale);
    
    
    //申明组合器
    AVMutableComposition *composition = [AVMutableComposition composition];
    //申明音频层管理器
    NSMutableArray * audioMixParams = [[NSMutableArray alloc] init];
    
    {
        AVMutableCompositionTrack *track = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
        [trackMix setVolume:1 atTime:kCMTimeZero];
        
        NSError * error = nil;
        
        if(![track insertTimeRange:CMTimeRangeMake(startTime, duration)
                           ofTrack:[trackList objectAtIndex:0]
                            atTime:kCMTimeZero
                             error:&error])
        {
            if(error)
            {
                NSLog(@"join video:(insert audio) %@",[error localizedDescription]);
            }
            
        }
        else
        {
            NSLog(@"join video:(audio) %ld/%ld (%ld)",(long)asset.duration.value,(long)bgScale,(long)asset.duration.timescale);
        }
        if(rate >0 && rate!=1.0)
        {
            [track scaleTimeRange:CMTimeRangeMake(kCMTimeZero, duration)
                       toDuration:CMTimeMake(duration.value/rate, duration.timescale)];
        }
        [audioMixParams addObject:trackMix];
    }
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = [NSArray arrayWithArray:audioMixParams];
    
    AVAssetExportSession * exporter= [[AVAssetExportSession alloc] initWithAsset:composition presetName: AVAssetExportPresetAppleM4A];
    exporter.audioMix = audioMix;
    exporter.outputFileType = AVFileTypeAppleM4A;
    exporter.shouldOptimizeForNetworkUse = YES;
    
    exporter.outputURL = audioUrl;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[audioUrl path]]) {
        NSLog(@"删除同名文件声音文件：%@！！！",[audioUrl path]);
        if ([[NSFileManager defaultManager] removeItemAtPath:[audioUrl path] error:NULL]) {
            NSLog(@"删除文件成功！！！");
        } else {
            NSLog(@"删除文件失败！！！");
        }
    }
    // do the export
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        int exportStatus = exporter.status;
        switch (exportStatus) {
            case AVAssetExportSessionStatusFailed:{
#ifndef __OPTIMIZE__
                NSError *exportError = exporter.error;
                NSLog (@"AVAssetExportSessionStatusFailed: %@", exportError);
#endif
                break;
            }
                
            case AVAssetExportSessionStatusCompleted: NSLog (@"AVAssetExportSessionStatusCompleted");
                break;
            case AVAssetExportSessionStatusUnknown: NSLog (@"AVAssetExportSessionStatusUnknown"); break;
            case AVAssetExportSessionStatusExporting: NSLog (@"AVAssetExportSessionStatusExporting"); break;
            case AVAssetExportSessionStatusCancelled: NSLog (@"AVAssetExportSessionStatusCancelled"); break;
            case AVAssetExportSessionStatusWaiting: NSLog (@"AVAssetExportSessionStatusWaiting"); break;
            default:  NSLog (@"didn't get export status"); break;
        }
        
        if(exportStatus == AVAssetExportSessionStatusCompleted)
        {
            completeHandler(audioUrl,nil);
        }
        else
        {
            completeHandler(audioUrl,exporter.error);
        }
    }];
    return YES;
}
- (BOOL)createAudioFromVideo:(NSURL *)fileUrl completed:(void(^)(NSURL *audioUrl, NSError *error))completed
{
    AVURLAsset * asset = [[AVURLAsset alloc]initWithURL:fileUrl options:nil];
    NSArray * tracklist = [asset tracksWithMediaType:AVMediaTypeAudio];
    CMTime  bgAudioTime = asset.duration;
    CMTime startTime = CMTimeMake(0, bgAudioTime.timescale);
    
    NSString * audioFileName = [NSString stringWithFormat:@"%@.m4a",[CommonUtil md5Hash:fileUrl.absoluteString]];
    NSURL * audioUrl = [NSURL fileURLWithPath:[[HCFileManager manager]tempFileFullPath:audioFileName]];
    if(tracklist.count>0)
    {
        //申明组合器
        AVMutableComposition *composition = [AVMutableComposition composition];
        //申明音频层管理器
        NSMutableArray * audioMixParams = [[NSMutableArray alloc] init];
        
        AVMutableCompositionTrack *track = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableAudioMixInputParameters *trackMix = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
        [trackMix setVolume:1 atTime:kCMTimeZero];
        
        NSError * error = nil;
        
        //因为合成的音乐应该与背景音乐等长，就算短一点也没有关系
        if(![track insertTimeRange:CMTimeRangeMake(startTime, bgAudioTime)
                           ofTrack:[tracklist objectAtIndex:0]
                            atTime:kCMTimeZero
                             error:&error])
        {
            if(error)
            {
                NSLog(@"join video:(insert audio) %@",[error localizedDescription]);
            }
            else
            {
                NSLog(@"join error.....");
            }
        }
        else
        {
            NSLog(@"join video:(audio) %lld/%d",bgAudioTime.value,bgAudioTime.timescale);
        }
        [audioMixParams addObject:trackMix];
        
        //generate
        AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
        audioMix.inputParameters = [NSArray arrayWithArray:audioMixParams];
        
        AVAssetExportSession * exporter= [[AVAssetExportSession alloc] initWithAsset: composition presetName: AVAssetExportPresetAppleM4A];
        //    SDAVAssetExportSession *exporter = [SDAVAssetExportSession exportSessionWithAsset:composition];
        exporter.audioMix = audioMix;
        exporter.outputFileType = AVFileTypeAppleM4A;
        exporter.shouldOptimizeForNetworkUse = YES;
        
        //    exporter.audioSettings = @{
        //                                        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        //                                        AVNumberOfChannelsKey: @2,
        //                                        AVSampleRateKey: @44100,
        //                                        AVEncoderBitRateKey: @160000,
        //                                        };
        
        exporter.outputURL = audioUrl;
        if ([[NSFileManager defaultManager] fileExistsAtPath:[audioUrl path]]) {
            NSLog(@"删除同名文件声音文件：%@！！！",[audioUrl path]);
            if ([[NSFileManager defaultManager] removeItemAtPath:[audioUrl path] error:NULL]) {
                NSLog(@"删除文件成功！！！");
            } else {
                NSLog(@"删除文件失败！！！");
            }
        }
        // do the export
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            int exportStatus = exporter.status;
            switch (exportStatus) {
                case AVAssetExportSessionStatusFailed:{
#ifndef __OPTIMIZE__
                    NSError *exportError = exporter.error;
                    NSLog (@"AVAssetExportSessionStatusFailed: %@", exportError);
#endif
                    break;
                }
                    
                case AVAssetExportSessionStatusCompleted: NSLog (@"AVAssetExportSessionStatusCompleted");
                    break;
                case AVAssetExportSessionStatusUnknown: NSLog (@"AVAssetExportSessionStatusUnknown"); break;
                case AVAssetExportSessionStatusExporting: NSLog (@"AVAssetExportSessionStatusExporting"); break;
                case AVAssetExportSessionStatusCancelled: NSLog (@"AVAssetExportSessionStatusCancelled"); break;
                case AVAssetExportSessionStatusWaiting: NSLog (@"AVAssetExportSessionStatusWaiting"); break;
                default:  NSLog (@"didn't get export status"); break;
            }
            
            if(exportStatus == AVAssetExportSessionStatusCompleted)
            {
                completed(audioUrl,nil);
            }
            else
            {
                completed(audioUrl,exporter.error);
            }
        }];
        
        return YES;
    }
    return NO;
}

#pragma mark  - helper
//检查队列中的音频数据，如果在设定的时间范围外的，排除，并且重新计算相对于设定的时间的起止位置
- (NSMutableArray *)checkAudioQueue:(NSArray*)AudioItemQueue beginTime:(CMTime)beginTime endTime:(CMTime)endTime resetBegin:(BOOL)resetBegin
{
    NSMutableArray * audioSegments = [NSMutableArray new];
    if(AudioItemQueue)
    {
        [audioSegments addObjectsFromArray:AudioItemQueue];
    }
    if(audioSegments.count>0 &&  CMTimeCompare(endTime, kCMTimeZero)>0)
    {
        NSMutableArray * removeList = [NSMutableArray new];
        CGFloat beginSeconds = CMTimeGetSeconds(beginTime);
        CGFloat endSeconds = CMTimeGetSeconds(endTime);
        
        for (AudioItem * item in audioSegments) {
            CGFloat endInArray = item.secondsInArray + item.secondsDurationInArray;
            if(endInArray <= beginSeconds || item.secondsInArray>=endSeconds)
            {
                [removeList addObject:item];
                continue;
            }
            else
            {
                CGFloat durationChanged = 0;
                if(item.secondsInArray < beginSeconds)
                {
                    durationChanged = beginSeconds - item.secondsInArray;
                    item.secondsInArray = beginSeconds;
                    item.secondsBegin +=   durationChanged;
                }
                if(endInArray > endSeconds)
                {
                    durationChanged = endInArray - endSeconds;
                    item.secondsEnd -= durationChanged;
                }
                //重置起点的时间计数
                if(resetBegin)
                {
                    item.secondsInArray -= beginSeconds;
                }
            }
        }
        
        if(removeList.count>0)
        {
            [audioSegments removeObjectsInArray:removeList];
        }
        
        PP_RELEASE(removeList);
    }
    return PP_AUTORELEASE(audioSegments);
    
}
- (NSString *)getAudioFileNameByQueue:(NSArray *)audioItemQueue
{
    //如果文件存在，则检查是否匹配，如果匹配，则不需要再生成
    NSMutableString * audioFileName = [NSMutableString new];
    
    for (AudioItem * item in audioItemQueue) {
        [audioFileName appendFormat:@"%@-%.1f-%.1f-%.1f",item.fileName,item.secondsInArray,item.secondsBegin,item.secondsDurationInArray ];
    }
    
    NSString * tempFileName = [NSString stringWithFormat:@"%@.m4a",[CommonUtil md5Hash:audioFileName]];
    return tempFileName;
}
- (NSError *)buildError:(NSString *)msg
{
    if(!msg) return nil;
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:msg
                                                         forKey:NSLocalizedDescriptionKey];
    NSError *aError = [NSError errorWithDomain:@"com.seenvoice.maiba" code:-1000 userInfo:userInfo];
    return aError;
}
#pragma mark - mixer

+ (OSStatus)mixAudio:(NSString *)audioPath1
            andAudio:(NSString *)audioPath2
              toFile:(NSString *)outputPath
  preferedSampleRate:(float)sampleRate
{
    OSStatus                            err = noErr;
    AudioStreamBasicDescription         inputFileFormat1;
    AudioStreamBasicDescription         inputFileFormat2;
    AudioStreamBasicDescription         converterFormat;
    UInt32                              thePropertySize = sizeof(inputFileFormat1);
    ExtAudioFileRef                     inputAudioFileRef1 = NULL;
    ExtAudioFileRef                     inputAudioFileRef2 = NULL;
    ExtAudioFileRef                     outputAudioFileRef = NULL;
    AudioStreamBasicDescription         outputFileFormat;
    
    NSURL *inURL1 = [NSURL fileURLWithPath:audioPath1];
    NSURL *inURL2 = [NSURL fileURLWithPath:audioPath2];
    NSURL *outURL = [NSURL fileURLWithPath:outputPath];
    
    // Open input audio file
    
    err = ExtAudioFileOpenURL((__bridge CFURLRef)inURL1, &inputAudioFileRef1);
    if (err)
    {
        goto reterr;
    }
    assert(inputAudioFileRef1);
    
    err = ExtAudioFileOpenURL((__bridge CFURLRef)inURL2, &inputAudioFileRef2);
    if (err)
    {
        goto reterr;
    }
    assert(inputAudioFileRef2);
    
    // Get input audio format
    
    bzero(&inputFileFormat1, sizeof(inputFileFormat1));
    err = ExtAudioFileGetProperty(inputAudioFileRef1, kExtAudioFileProperty_FileDataFormat,
                                  &thePropertySize, &inputFileFormat1);
    if (err)
    {
        goto reterr;
    }
    
    // only mono or stereo audio files are supported
    
    if (inputFileFormat1.mChannelsPerFrame > 2)
    {
        err = kExtAudioFileError_InvalidDataFormat;
        goto reterr;
    }
    
    bzero(&inputFileFormat2, sizeof(inputFileFormat2));
    err = ExtAudioFileGetProperty(inputAudioFileRef2, kExtAudioFileProperty_FileDataFormat,
                                  &thePropertySize, &inputFileFormat2);
    if (err)
    {
        goto reterr;
    }
    
    // only mono or stereo audio files are supported
    
    if (inputFileFormat2.mChannelsPerFrame > 2)
    {
        err = kExtAudioFileError_InvalidDataFormat;
        goto reterr;
    }
    
    int numChannels = MAX(inputFileFormat1.mChannelsPerFrame, inputFileFormat2.mChannelsPerFrame);
    
    // Enable an audio converter on the input audio data by setting
    // the kExtAudioFileProperty_ClientDataFormat property. Each
    // read from the input file returns data in linear pcm format.
    
    AudioFileTypeID audioFileTypeID = kAudioFileCAFType;
    
    Float64 mSampleRate = sampleRate? sampleRate : MAX(inputFileFormat1.mSampleRate, inputFileFormat2.mSampleRate);
    
    [self _setDefaultAudioFormatFlags:&converterFormat sampleRate:mSampleRate numChannels:inputFileFormat1.mChannelsPerFrame];
    
    err = ExtAudioFileSetProperty(inputAudioFileRef1, kExtAudioFileProperty_ClientDataFormat,
                                  sizeof(converterFormat), &converterFormat);
    if (err)
    {
        goto reterr;
    }
    [self _setDefaultAudioFormatFlags:&converterFormat sampleRate:mSampleRate numChannels:inputFileFormat2.mChannelsPerFrame];
    err = ExtAudioFileSetProperty(inputAudioFileRef2, kExtAudioFileProperty_ClientDataFormat,
                                  sizeof(converterFormat), &converterFormat);
    if (err)
    {
        goto reterr;
    }
    // Handle the case of reading from a mono input file and writing to a stereo
    // output file by setting up a channel map. The mono output is duplicated
    // in the left and right channel.
    
    if (inputFileFormat1.mChannelsPerFrame == 1 && numChannels == 2) {
        SInt32 channelMap[2] = { 0, 0 };
        
        // Get the underlying AudioConverterRef
        
        AudioConverterRef convRef = NULL;
        UInt32 size = sizeof(AudioConverterRef);
        
        err = ExtAudioFileGetProperty(inputAudioFileRef1, kExtAudioFileProperty_AudioConverter, &size, &convRef);
        
        if (err)
        {
            goto reterr;
        }
        
        assert(convRef);
        
        err = AudioConverterSetProperty(convRef, kAudioConverterChannelMap, sizeof(channelMap), channelMap);
        
        if (err)
        {
            goto reterr;
        }
    }
    if (inputFileFormat2.mChannelsPerFrame == 1 && numChannels == 2) {
        SInt32 channelMap[2] = { 0, 0 };
        
        // Get the underlying AudioConverterRef
        
        AudioConverterRef convRef = NULL;
        UInt32 size = sizeof(AudioConverterRef);
        
        err = ExtAudioFileGetProperty(inputAudioFileRef2, kExtAudioFileProperty_AudioConverter, &size, &convRef);
        
        if (err)
        {
            goto reterr;
        }
        
        assert(convRef);
        
        err = AudioConverterSetProperty(convRef, kAudioConverterChannelMap, sizeof(channelMap), channelMap);
        
        if (err)
        {
            goto reterr;
        }
    }
    // Output file is typically a caff file, but the user could emit some other
    // common file types. If a file exists already, it is deleted before writing
    // the new audio file.
    
    [self _setDefaultAudioFormatFlags:&outputFileFormat sampleRate:mSampleRate numChannels:numChannels];
    
    UInt32 flags = kAudioFileFlags_EraseFile;
    
    err = ExtAudioFileCreateWithURL((__bridge CFURLRef)outURL, audioFileTypeID, &outputFileFormat,
                                    NULL, flags, &outputAudioFileRef);
    if (err)
    {
        // -48 means the file exists already
        goto reterr;
    }
    assert(outputAudioFileRef);
    
    // Enable converter when writing to the output file by setting the client
    // data format to the pcm converter we created earlier.
    
    err = ExtAudioFileSetProperty(outputAudioFileRef, kExtAudioFileProperty_ClientDataFormat,
                                  sizeof(outputFileFormat), &outputFileFormat);
    if (err)
    {
        goto reterr;
    }
    
    // Buffer to read from source file and write to dest file
    
    UInt16 bufferSize = 8192;
    
    AudioSampleType * buffer1 = malloc(bufferSize);
    AudioSampleType * buffer2 = malloc(bufferSize);
    AudioSampleType * outBuffer = malloc(bufferSize);
    
    AudioBufferList conversionBuffer1;
    conversionBuffer1.mNumberBuffers = 1;
    conversionBuffer1.mBuffers[0].mNumberChannels = inputFileFormat1.mChannelsPerFrame;
    conversionBuffer1.mBuffers[0].mDataByteSize = bufferSize;
    conversionBuffer1.mBuffers[0].mData = buffer1;
    
    AudioBufferList conversionBuffer2;
    conversionBuffer2.mNumberBuffers = 1;
    conversionBuffer2.mBuffers[0].mNumberChannels = inputFileFormat2.mChannelsPerFrame;
    conversionBuffer2.mBuffers[0].mDataByteSize = bufferSize;
    conversionBuffer2.mBuffers[0].mData = buffer2;
    
    //
    AudioBufferList outBufferList;
    outBufferList.mNumberBuffers = 1;
    outBufferList.mBuffers[0].mNumberChannels = outputFileFormat.mChannelsPerFrame;
    outBufferList.mBuffers[0].mDataByteSize = bufferSize;
    outBufferList.mBuffers[0].mData = outBuffer;
    
    UInt32 numFramesToReadPerTime = INT_MAX;
    UInt8 bitOffset = 8 * sizeof(AudioSampleType);
    UInt64 bitMax = (UInt64) (pow(2, bitOffset));
    UInt64 bitMid = bitMax/2;
    
    
    while (TRUE) {
        conversionBuffer1.mBuffers[0].mDataByteSize = bufferSize;
        conversionBuffer2.mBuffers[0].mDataByteSize = bufferSize;
        outBufferList.mBuffers[0].mDataByteSize = bufferSize;
        
        UInt32 frameCount1 = numFramesToReadPerTime;
        UInt32 frameCount2 = numFramesToReadPerTime;
        
        if (inputFileFormat1.mBytesPerFrame)
        {
            frameCount1 = bufferSize/inputFileFormat1.mBytesPerFrame;
        }
        if (inputFileFormat2.mBytesPerFrame)
        {
            frameCount2 = bufferSize/inputFileFormat2.mBytesPerFrame;
        }
        // Read a chunk of input
        
        err = ExtAudioFileRead(inputAudioFileRef1, &frameCount1, &conversionBuffer1);
        
        if (err) {
            goto reterr;
        }
        
        err = ExtAudioFileRead(inputAudioFileRef2, &frameCount2, &conversionBuffer2);
        
        if (err) {
            goto reterr;
        }
        // If no frames were returned, conversion is finished
        
        if (frameCount1 == 0 && frameCount2 == 0)
            break;
        
        UInt32 frameCount = MAX(frameCount1, frameCount2);
        UInt32 minFrames = MIN(frameCount1, frameCount2);
        
        outBufferList.mBuffers[0].mDataByteSize = frameCount * outputFileFormat.mBytesPerFrame;
        
        UInt32 length = frameCount * 2;
        for (int j =0; j < length; j++)
        {
            if (j/2 < minFrames)
            {
                SInt32 sValue =0;
                
                SInt16 value1 = (SInt16)*(buffer1+j);   //-32768 ~ 32767
                SInt16 value2 = (SInt16)*(buffer2+j);   //-32768 ~ 32767
                
                SInt8 sign1 = (value1 == 0)? 0 : abs(value1)/value1;
                SInt8 sign2 = (value2== 0)? 0 : abs(value2)/value2;
                
                if (sign1 == sign2)
                {
                    UInt32 tmp = ((value1 * value2) >> (bitOffset -1));
                    
                    sValue = value1 + value2 - sign1 * tmp;
                    
                    if (abs(sValue) >= bitMid)
                    {
                        sValue = (SInt32)(sign1 * (bitMid -  1));
                    }
                }
                else
                {
                    SInt32 tmpValue1 = (SInt32)(value1 + bitMid);
                    SInt32 tmpValue2 = (SInt32)(value2 + bitMid);
                    
                    UInt32 tmp = ((tmpValue1 * tmpValue2) >> (bitOffset -1));
                    
                    if (tmpValue1 < bitMid && tmpValue2 < bitMid)
                    {
                        sValue = tmp;
                    }
                    else
                    {
                        sValue = (SInt32)(2 * (tmpValue1  + tmpValue2 ) - tmp - bitMax);
                    }
                    sValue -= bitMid;
                }
                
                if (abs(sValue) >= bitMid)
                {
                    SInt8 sign =(SInt8)(sValue>=0?1:-1);//abs(sValue)/sValue;
                    
                    sValue = (SInt32)(sign * (bitMid -  1));
                }
                
                *(outBuffer +j) = sValue;
            }
            else{
                if (frameCount == frameCount1)
                {
                    //将buffer1中的剩余数据添加到outbuffer
                    *(outBuffer +j) = *(buffer1 + j);
                }
                else
                {
                    //将buffer1中的剩余数据添加到outbuffer
                    *(outBuffer +j) = *(buffer2 + j);
                }
            }
        }
        
        // Write pcm data to output file
        NSLog(@"frame count (%ld, %ld, %ld)", (long)frameCount, (long)frameCount1, (long)frameCount2);
        err = ExtAudioFileWrite(outputAudioFileRef, frameCount, &outBufferList);
        
        if (err) {
            goto reterr;
        }
    }
    
reterr:
    if (buffer1)
        free(buffer1);
    
    if (buffer2)
        free(buffer2);
    
    if (outBuffer)
        free(outBuffer);
    
    if (inputAudioFileRef1)
        ExtAudioFileDispose(inputAudioFileRef1);
    
    if (inputAudioFileRef2)
        ExtAudioFileDispose(inputAudioFileRef2);
    
    if (outputAudioFileRef)
        ExtAudioFileDispose(outputAudioFileRef);
    
    return err;
}

// Set flags for default audio format on iPhone OS

+ (void) _setDefaultAudioFormatFlags:(AudioStreamBasicDescription*)audioFormatPtr
                          sampleRate:(Float64)sampleRate
                         numChannels:(NSUInteger)numChannels
{
    bzero(audioFormatPtr, sizeof(AudioStreamBasicDescription));
    
    audioFormatPtr->mFormatID = kAudioFormatLinearPCM;
    audioFormatPtr->mSampleRate = sampleRate;
    audioFormatPtr->mChannelsPerFrame = (UInt32)numChannels;
    audioFormatPtr->mBytesPerPacket = (UInt32)(2 * numChannels);
    audioFormatPtr->mFramesPerPacket = 1;
    audioFormatPtr->mBytesPerFrame = audioFormatPtr->mBytesPerPacket;// (UInt32)(2 * numChannels);
    audioFormatPtr->mBitsPerChannel = 16;
    audioFormatPtr->mFormatFlags = kAudioFormatFlagsNativeEndian |
    kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
}
@end

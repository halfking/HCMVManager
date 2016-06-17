//
//  ActionManager(index).m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "ActionManager(index).h"
#import "MediaAction.h"
#import "MediaItem.h"
#import "MediaEditManager.h"
#import "MediaWithAction.h"

#import "ActionManager(player).h"

#import "ActionProcess.h"
#import "WTPlayerResource.h"

@implementation ActionManager(index)
#pragma mark - overlap manager
- (CGFloat) reindexAllActions
{
    @synchronized (self) {
        [mediaList_ removeAllObjects];
        secondsEffectPlayer_ = 0;
        currentMediaWithAction_ = nil;
        
        NSAssert(videoBgAction_, @"必须先设置了源背景视频才能进行处理!");
        MediaWithAction * bgMedia = [videoBgAction_ copyItem];
        
        [mediaList_ addObject:bgMedia];
        mediaList_ = [self processActions:actionList_ sources:mediaList_];
        mediaList_ = [self combinateArrayItems:mediaList_];
        
        [self ActionManager:self doProcessOK:mediaList_ duration:durationForTarget_];
        
        if(self.needPlayerItem)
        {
            [self generatePlayerItem:mediaList_];
        }
        return durationForTarget_;
    }
}
- (NSMutableArray *) processActions:(NSArray *)actions sources:(NSMutableArray *) sources
{
    if(!actions || !sources || actions.count==0 || sources.count==0) return sources;
    NSMutableArray * result = sources;
    for (MediaActionDo * action in actions) {
        result = [action processAction:result secondsEffected:secondsEffectPlayer_];
        
        MediaWithAction * item = [result lastObject];
        
        //当没有结束的动作加入时，则其Duration未知，导致计算终止，因为后面的所有动作都可能被覆盖
        if(item && item.secondsDurationInArray >=0)
        {
        }
        else
        {
            break;
        }
        
    }
    durationForTarget_ = 0;
    for (MediaWithAction * action in result) {
        durationForTarget_ += action.durationInPlaying;
    }
    return result;
}
//执行最新的Action，最新的一般在最后
- (CGFloat) processNewActions
{
    MediaActionDo * action = [actionList_ lastObject];
#ifndef __OPTIMIZE__
    NSMutableArray * orgMediaList = [NSMutableArray new];
    [orgMediaList addObjectsFromArray:mediaList_];
    CGFloat orgSecondsEffect = secondsEffectPlayer_;
#endif
    mediaList_ = [action processAction:mediaList_ secondsEffected:secondsEffectPlayer_];
    
#ifndef __OPTIMIZE__
    BOOL hasItem = NO;
    for (MediaWithAction * item in mediaList_) {
        if(item.Action.MediaActionID == action.MediaActionID)
        {
            hasItem = YES;
            break;
        }
    }
    if(!hasItem)
    {
        mediaList_ = [action processAction:orgMediaList secondsEffected:orgSecondsEffect];
    }
#endif
    if(action.isOPCompleted)
    {
        mediaList_ = [self combinateArrayItems:mediaList_];
    }
    
#ifndef __OPTIMIZE__
    hasItem = NO;
    for (MediaWithAction * item in mediaList_) {
        if(item.Action.MediaActionID == action.MediaActionID)
        {
            hasItem = YES;
            break;
        }
    }
    if(!hasItem)
    {
        NSLog(@"has been combinate....");
    }
#endif
    durationForTarget_ = 0;
    for (MediaWithAction * action in mediaList_) {
        durationForTarget_ += action.durationInPlaying;
    }
    
    return durationForTarget_;
}

//获取在此动作之前的已经存在的素材列表
- (NSArray *) getMediaBaseLine:(MediaActionDo *)action
{
    return mediaList_;
}
- (NSMutableArray *) combinateArrayItems:(NSMutableArray *)source
{
    NSMutableArray * targetSource = [NSMutableArray new];
    MediaWithAction * lastItem = nil;
    for (MediaWithAction * item in source) {
        if(!lastItem
           ||
           (lastItem.playRate != item.playRate)
           ||
           !((lastItem.fileName == nil && item.fileName == nil)
             || [lastItem.fileName isEqualToString:item.fileName]))
        {
            [targetSource addObject:item];
            lastItem = item;
        }
        else
        {
            if(fabs(lastItem.secondsEnd - item.secondsBegin)<SECONDS_ERRORRANGE)
            {
                
                //Repeat 要立杆子，如果类型变了，就没有标识了
                if(lastItem.Action.ActionType==SRepeat)
                {
                    [targetSource addObject:item];
                    lastItem = item;
                }
                else
                {
                    lastItem.end = item.end;
                    
                    if(item.Action.ActionType==SNormal || lastItem.Action.ActionType==SNormal)
                    {
                        lastItem.end = item.end;
                        lastItem.Action.ActionType = SNormal;
                        lastItem.Action.MediaActionID = [self getMediaActionID];
                    }
                }
            }
            else
            {
                [targetSource addObject:item];
                lastItem = item;
            }
        }
    }
    return targetSource;
}
#pragma mark - export
- (void)cancelGenerate
{
    cancelReverseGenerate_ = YES;
    if(currentGenerate_)
    {
        [currentGenerate_ cancelExporter];
        [currentGenerate_ setJoinVideoUrl: nil];
        [currentGenerate_ clear];
        currentGenerate_ = nil;
    }
    if(currentFilterGen_)
    {
        [currentFilterGen_ cancelFilter];
        currentFilterGen_ = nil;
    }
    if(reverseGenerate_)
    {
        [reverseGenerate_ cancelExporter];
        [reverseGenerate_ setJoinVideoUrl:nil];
        [reverseGenerate_ clear];
        reverseGenerate_ = nil;
    }
    if(reverseMediaGenerate_)
    {
        [reverseMediaGenerate_ cancelExporter];
        [reverseMediaGenerate_ setJoinVideoUrl:nil];
        [reverseMediaGenerate_ clear];
        reverseMediaGenerate_ = nil;
    }
    isGenerating_ = NO;
    isReverseGenerating_ = NO;
    isReverseMediaGenerating_ = NO;
    isGeneratingByFilter_ = NO;
    //因为反向是循环调用，需要小心处理
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        cancelReverseGenerate_ = NO;
    });
}
- (BOOL) generateMV
{
    return [self generateMVWithWaterMarker:nil position:MP_RightBottom];
}
- (void)checkReverseGenerate
{
    NSArray * actionMediaList = [self getMediaList];
    
    //检查是否都已经将反向视频处理好
    BOOL needCheckAgagin = NO;
    int i = 0;
    for (MediaWithAction * media in actionMediaList) {
        if(media.playRate<0 && ![media isReverseMedia] && media.secondsDurationInArray >=self.minMediaDuration)
        {
            if(media.isReversed >=-1)//失败一次以内，或者没有生成
            {
                NSLog(@"AM : reverse gen index:%d/%d",i,(int)actionMediaList.count);
                [self generateMediaFile:media];
                
                needCheckAgagin = YES;
                break;
            }
        }
        i ++;
    }
}
//生成视频，并检查反向片段是否已经生成
-(BOOL) generateMVWithWaterMarker:(NSString *)waterMarker position:(WaterMarkerPosition)position
{
    @synchronized (self) {
        if(isGeneratingWithCheck_)
        {
            NSLog(@"正在生成中，不能重入(check)");
            return YES;
        }
        isGeneratingWithCheck_ = YES;
    }
    NSArray * actionMediaList = [self getMediaList];
    
    //检查是否都已经将反向视频处理好
    BOOL needCheckAgagin = NO;
    int i = 0;
    for (MediaWithAction * media in actionMediaList) {
        if(media.playRate<0 && ![media isReverseMedia] && media.secondsDurationInArray >=self.minMediaDuration)
        {
            if(media.isReversed>=-1)
            {
            NSLog(@"AM : reverse gen index:%d/%d",i,(int)actionMediaList.count);
            [self generateMediaFile:media];
            
            needCheckAgagin = YES;
            break;
            }
        }
        i ++;
    }
    if(needCheckAgagin)
    {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);// 页面刷新的时间基数
        dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            isGeneratingWithCheck_ = NO;
            [self generateMVWithWaterMarker:waterMarker position:position];
        });
        
        return YES;
    }
    else
    {
        isGeneratingWithCheck_ = NO;
        return [self generateMVWithWaterMarker:waterMarker position:position needReverseCheck:NO];
    }
}
//使用此函数，请确认所有的反向片段已经生成
- (BOOL) generateMVWithWaterMarker:(NSString *)waterMarker position:(WaterMarkerPosition)position needReverseCheck:(BOOL)needReverseCheck
{
    @synchronized (self) {
        if(isGenerating_ || isReverseGenerating_)
        {
            [self cancelGenerate];
        }
        if(isGenerating_) return NO;
        isGenerating_ = YES;
    }
    //再次整理数据，因为有可能有部分Media的长度不对的，去掉过短的素材
    NSMutableArray * actionMediaList = [NSMutableArray new];
    CGFloat secondsInArray = 0;
    for (MediaWithAction * item in [self getMediaList]) {
        if(item.playRate>0 && item.secondsDurationInArray > self.minMediaDuration) //反向视频如果生成了，则就会有正向的效果
        {
            if(item.secondsInArray!=secondsInArray)
            {
                item.timeInArray = CMTimeMakeWithSeconds(secondsInArray, item.timeInArray.timescale);
            }
            [actionMediaList addObject:item];
            secondsInArray += item.secondsDurationInArray;
        }
    }
    
    //动作 处理
    [self saveDraft];
    
    NSLog(@"generate begin ....");
    NSLog(@"duration:%.2f",durationForTarget_);
    int index = 0;
    for (MediaWithAction * item in actionMediaList) {
        NSLog(@"%@",[item toString]);
        index ++;
    }
    NSLog(@"**--**--**--**--**--**--**--**--**--**--");
    
    VideoGenerater * vg = [[VideoGenerater alloc]init];
    [vg resetGenerateInfo];
    vg.waterMarkFile = waterMarker;
    vg.waterMarkerPosition = position;
    vg.mergeRate = 1;
    vg.volRampSeconds = 0;
    vg.compositeLyric = NO;
    vg.delegate = self;
    vg.TagID = 1;
    vg.bitRate = self.bitRate;
    
    if(audioBg_ && audioBg_.fileName)
    {
        [vg setBgAudio:audioBg_];
        //        [vg setBgmUrl:audioBg_.url];
        //        [vg setTimeForAudioMerge:audioBg_.secondsInArray end:audioBg_.secondsDurationInArray];
    }
    
    UIDeviceOrientation or = [[MediaEditManager shareObject]orientationFromDegree:videoBg_.degree];
    //有部分没有正确设置方向的视频
    if(videoBg_.degree==0 && videoBg_.renderSize.width< videoBg_.renderSize.height)
    {
        or = UIDeviceOrientationPortrait;
    }
    if(videoBg_.renderSize.width <= self.renderSize.width && videoBg_.renderSize.height <=self.renderSize.width)
    {
        [vg setRenderSize:videoBg_.renderSize orientation:or withFontCamera:NO];
    }
    else
    {
        [vg setRenderSize:self.renderSize orientation:or withFontCamera:NO];
    }
    [vg setTimeForMerge:0 end:-1];
    if(audioBg_)
    {
        [vg setTimeForAudioMerge:audioBg_.secondsBegin end:audioBg_.secondsEnd];
    }
    else
    {
        [vg setTimeForAudioMerge:0 end:-1];
    }
    
    if(currentFilterGen_ && isGeneratingByFilter_)
    {
        [currentFilterGen_ cancelFilter];
    }
    currentFilterGen_ = nil;
    if(currentGenerate_)
    {
        [currentGenerate_ clear];
    }
    
    currentGenerate_ = vg;
    //    [vg setBlock:^(VideoGenerater *queue, CGFloat progress) {
    //        NSLog(@"progress %f",progress);
    //    } ready:^(VideoGenerater *queue, AVPlayerItem *playerItem) {
    //        NSLog(@"playerItem Ready");
    //
    //    } completed:^(VideoGenerater *queue, NSURL *mvUrl, NSString *coverPath) {
    //        NSLog(@"generate completed.  %@",[mvUrl path]);
    //        NSString * fileName = [[HCFileManager manager]getFileNameByTicks:@"merge.mp4"];
    //        NSString * filePath = [[HCFileManager manager]localFileFullPath:fileName];
    //        [HCFileManager copyFile:[mvUrl path] target:filePath overwrite:YES];
    //
    //        [manager_ setBackMV:filePath begin:0 end:-1];
    //
    //        [manager_ removeActions];
    //
    //        [self hideIndicatorView];
    //
    //    } failure:^(VideoGenerater *queue, NSString *msg, NSError *error) {
    //        NSLog(@"generate failure:%@ error:%@",msg,[error localizedDescription]);
    ////        [self hideIndicatorView];
    //    }];
    needSendPlayControl_ = NO;
    isGenerateEnter_ = NO;
    BOOL ret = [self generateMediaListWithActions:actionMediaList complted:^(NSArray * mediaList)
                {
                    @synchronized (self) {
                        if(isGenerateEnter_) return ;
                        isGenerateEnter_ = YES;
                    }
                    [vg generatePreviewAsset:mediaList
                                    bgVolume:audioVol_
                                  singVolume:videoVol_
                                  completion:^(BOOL finished)
                     {
                         if(![vg generateMVFile:mediaList retryCount:0])
                         {
                             isGenerateEnter_ = NO;
                         }
                     }];
                }];
    if(!ret)
    {
        needSendPlayControl_ = YES;
        isGenerating_ = NO;
        isGenerateEnter_ = NO;
        isGeneratingWithCheck_ = NO;
        NSLog(@"generate failure.");
    }
    return ret;
}
- (BOOL)generateMediaFileViaAction:(MediaActionDo *)action
{
    MediaWithAction * media = nil;
    if(action.ActionType==SReverse)
    {
        if([action.Media isKindOfClass:[MediaWithAction class]])
        {
            media = (MediaWithAction *)action.Media;
        }
    }
    if(media && media.playRate <0 && media.secondsDurationInArray >=self.minMediaDuration)
    {
        return [self generateMediaFile:media];
    }
    return NO;
}
- (BOOL)generateMediaFile:(MediaWithAction *)media
{
    //    if(!media || ([media isReverseMedia]==NO && media.playRate>0) || media.secondsDurationInArray<SECONDS_MINRANGE)
    if(!media || (media.playRate>0) || media.secondsDurationInArray<self.minMediaDuration)
        return NO;
    @synchronized (self) {
        if(isReverseMediaGenerating_)
        {
            NSLog(@"正在生成上一个，不能重入....");
            NSLog(@"next media:%@",[media toString]);
            return NO;
        }
        isReverseMediaGenerating_ = YES;
        
        if([media isReverseMedia] && [[HCFileManager manager]existFileAtPath:media.filePath])
        {
            NSLog(@"已经生成了，不需要再处理....");
            isReverseMediaGenerating_ = NO;
            return YES;
        }
    }
    
    NSString * fileName = [[HCFileManager manager]getFileNameByTicks:@"media_reverse.mp4"];
    NSString * outputPath = [[HCFileManager manager]tempFileFullPath:fileName];
    
    VideoGenerater * vg = [VideoGenerater new];
    //        vg.delegate = self;
    vg.TagID = 3;
    vg.bitRate = self.bitRate;
    reverseMediaGenerate_ = vg;
    
    if(media.degree >=0)
    {
        UIDeviceOrientation or = [[MediaEditManager shareObject]orientationFromDegree:media.degree];
        
        [vg setRenderSize:self.renderSize orientation:or withFontCamera:NO];
    }
    else
    {
        [vg setRenderSize:self.renderSize orientation:-1 withFontCamera:NO];
    }
    NSLog(@"VG  :reverse media video begin..duration:%f..",media.secondsDurationInArray);
    
    __weak ActionManager * weakSelf = self;
    BOOL ret = [vg generateMVReverse:media.filePath
                              target:outputPath
                               begin:media.secondsEnd
                                 end:media.secondsBegin
                           audioFile:media.filePath
                          audioBegin:media.secondsEnd
                            complted:^(NSString * filePathNew){
                                if(filePathNew && filePathNew.length>0)
                                {
                                    [media setFileName:filePathNew];
                                    CGFloat duration = media.secondsDurationInArray;
                                    media.isReversed = 1;
                                    media.secondsBeginBeforeReverse = media.secondsBegin;
                                    media.secondsEndBeforeReverse = media.secondsEnd;
                                    media.rateBeforeReverse = media.playRate;
                                    media.begin =  CMTimeMakeWithSeconds(0, media.begin.timescale);
                                    media.end = CMTimeMakeWithSeconds(duration, media.end.timescale);
                                    media.playRate = 0 - media.playRate;
                                    media.url = [NSURL fileURLWithPath:filePathNew];
                                    NSLog(@"VG  : reveser ok:%@ org filerange:%f->%f duration:%f",[filePathNew lastPathComponent],media.secondsBeginBeforeReverse,media.secondsEndBeforeReverse,media.secondsDurationInArray
                                          );
                                }
                                else if(media.isReversed<=0) //防止内部重复调用，导致死循环
                                {
                                    NSLog(@"VG  : reveser failure:%@ org filerange:%f->%f duration:%f",@"null",media.secondsBeginBeforeReverse,media.secondsEndBeforeReverse,media.secondsDurationInArray
                                          );
                                    media.isReversed --;
                                }
                               
                                //                                reverseMediaGenerate_ = nil;
                                [reverseMediaGenerate_ setJoinVideoUrl:nil];
                                [reverseMediaGenerate_ clear];
                                reverseMediaGenerate_ = nil;
                                isReverseMediaGenerating_ = NO;
                                if(!cancelReverseGenerate_)
                                {
                                    [weakSelf checkReverseGenerate];
                                }
                                
                            }];
    if(!ret)
    {
        media.isReversed --;
        [reverseMediaGenerate_ setJoinVideoUrl:nil];
        [reverseMediaGenerate_ clear];
        reverseMediaGenerate_ = nil;
        isReverseMediaGenerating_ = NO;
    }
    return ret;
}

//
//- (BOOL)generateReverseMV:(NSString*)filePath
//{
//    return [self generateReverseMV:filePath begin:0 end:-1];
//}
//- (BOOL)generateReverseMV:(NSString*)filePath begin:(CGFloat)sourceBegin end:(CGFloat)sourceEnd
//{
//    if(!filePath) return NO;
//    //生成反向的视频
//    {
//        if(isReverseGenerating_)
//        {
//            NSLog(@"正在生成反向视频中，不能再次进入");
//            return NO;
//        }
//        isReverseGenerating_ = YES;
////        if(reverseBG_)
////        {
////            PP_RELEASE(reverseBG_);
////        }
//        NSString * fileName = [[HCFileManager manager]getFileNameByTicks:@"reverse.mp4"];
//        NSString * outputPath = [[HCFileManager manager]tempFileFullPath:fileName];
//
//        VideoGenerater * vg = [VideoGenerater new];
//        vg.delegate = self;
//        vg.TagID = 2;
//        vg.bitRate = self.bitRate;
//
//        [vg setRenderSize:self.renderSize orientation:-1 withFontCamera:NO];
//
//        reverseGenerate_ = vg;
//        __weak ActionManager * weakSelf = self;
//        NSLog(@"begin generate reverse video....");
//        BOOL ret = [vg generateMVReverse:filePath
//                                  target:outputPath
//                                   begin:sourceBegin
//                                     end:sourceEnd
//                               audioFile:filePath
//                              audioBegin:sourceBegin
//                                complted:^(NSString * filePathNew){
//                                    NSLog(@"genreate reveser video ok:%@",[filePathNew lastPathComponent]);
//                                    [reverseMediaGenerate_ setJoinVideoUrl:nil];
//                                    [reverseMediaGenerate_ clear];
//                                    reverseGenerate_ = nil;
//                                    if(filePathNew)
//                                    {
//                                        isReverseHasGenerated_ = YES;
//                                        reverseBG_ = [manager_ getMediaItem:[NSURL fileURLWithPath:filePathNew]];
//                                        reverseBG_.begin = CMTimeMakeWithSeconds(videoBg_.secondsDuration - videoBg_.secondsEnd,videoBg_.end.timescale);
//                                        reverseBG_.end = CMTimeMakeWithSeconds(videoBg_.secondsDuration - videoBg_.secondsBegin,videoBg_.begin.timescale);
//
//                                        __strong ActionManager * strongSelf = weakSelf;
//                                        if(strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(ActionManager:reverseGenerated:)])
//                                        {
//                                            [strongSelf.delegate ActionManager:strongSelf reverseGenerated:reverseBG_];
//                                        }
//                                    }
//                                    isReverseGenerating_ = NO;
//                                }];
//        if(!ret)
//        {
//            [reverseMediaGenerate_ setJoinVideoUrl:nil];
//            [reverseMediaGenerate_ clear];
//            reverseGenerate_ = nil;
//            isReverseGenerating_ = NO;
//            isReverseHasGenerated_ = NO;
//            NSLog(@"generate reverse failure....");
//            return NO;
//        }
//    }
//    return YES;
//}


- (void) generatePlayerItem:(NSArray *)mediaList
{
    
}

//- (BOOL) generateThumnates:(CGSize)thumnateSize contentSize:(CGSize)contentSize
//{
//
//    return NO;
//}
@end

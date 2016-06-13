//
//  ActionManager.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "ActionManager.h"
#import "ActionManager(index).h"
#import <hccoren/base.h>
#import <hccoren/JSON.h>
#import "MediaAction.h"
#import "MediaItem.h"
#import "MediaActionDo.h"
#import "MediaWithAction.h"
#import "MediaEditManager.h"
#import "VideoGenerater.h"
#import "mvconfig.h"
#import "MediaActionForRAP.h"
#import "MediaActionForFast.h"
#import "MediaActionForSlow.h"
#import "MediaActionForNormal.h"
#import "MediaActionForReverse.h"

#import "ActionManager(player).h"

#import "WTPlayerResource.h"
#import <hccoren/HWWeakTimer.h>
@interface ActionManager()

@end
@implementation ActionManager
@synthesize videoVolume = videoVol_;
@synthesize audioVolume = audioVol_;
@synthesize isGenerating = isGenerating_;
@synthesize canSendPlayerMedia = needSendPlayControl_;
@synthesize secondsForAudioPlayerMaxRange = secondsForAudioPlayerMaxRange_;
//@synthesize moveFile = movieFile_;
//@synthesize moveFileOrg = movieFileOrg_;
@synthesize minMediaDuration = minMediaDuration_;
+(id)shareObject
{
    static dispatch_once_t pred = 0;
    static ActionManager *instance_ = nil;
    dispatch_once(&pred,^
                  {
                      instance_ = [[ActionManager alloc] init];
                  });
    return instance_;
}
- (id)init
{
    if(self == [super init])
    {
        actionList_ = [NSMutableArray new];
        //        mediaListBG_ = [NSMutableArray new];
        mediaList_ = [NSMutableArray new];
        mediaListFilter_ = [NSMutableArray new];
        manager_ = [MediaEditManager new];
        [manager_ setIsFragment:NO];
        
        videoBGHistroy_ = [NSMutableArray new];
        //        reverseBgHistory_ = [NSMutableArray new];
        actionsHistory_ = [NSMutableArray new];
        
        manager_.delegate = self;
        isReverseGenerating_ = NO;
        isReverseHasGenerated_ = NO;
        isGeneratingByFilter_ = NO;
        isGeneratingWithCheck_ = NO;
        isGenerateEnter_ = NO;
        isGenerating_ = NO;
        lastFilterIndex_ = 0;
        currentFilterIndex_ = 0;
        currentMediaWithAction_ = nil;
        videoVol_ = 1;
        audioVol_ = 1;
        secondsForAudioPlayerMaxRange_ = 0.5;
        minMediaDuration_ = SECONDS_MINRANGE;
        _bitRate = (long)(540 *960 * 10);
        _renderSize = CGSizeMake(540, 960);
        moveFileRemoveList_ = [NSMutableArray new];
        [self setNeedPlaySync:YES];
        
        //        lastPlayerSeconds_ = 0;
    }
    return self;
}
- (void)resetStates
{
    [self cancelGenerate];
    //    [self removeGPUFilter];
    
    isReverseMediaGenerating_ = NO;
    isGeneratingByFilter_ = NO;
    isReverseGenerating_ = NO;
    isGenerating_ = NO;
    isGeneratingWithCheck_ = NO;
    isGenerateEnter_ = NO;
    currentFilterIndex_ = 0;
    lastFilterIndex_ = 0;
    [self setNeedPlaySync:YES];
    durationForSource_ = 0;
    durationForAudio_ = 0;
    durationForTarget_ = 0;
    
    currentMediaWithAction_ = nil;
    secondsForAudioPlayerMaxRange_ = 0.5;
    videoVol_ = 1;
    audioVol_ = 1;
    _bitRate = (long)(540 *960 * 10);
    _renderSize = CGSizeMake(540, 960);
    
    
}
- (void)clearPlayers
{
    if(filterView_)
        [self removeGPUFilter];
    
    if(player_)
    {
        [player_ readyToRelease];
        player_ = nil;
    }
    //    if(reversePlayer_)
    //    {
    //        [reversePlayer_ readyToRelease];
    //        reversePlayer_ = nil;
    //    }
    if(audioPlayer_)
    {
        audioPlayer_ = nil;
    }
}

- (void)clear:(BOOL)includeBaseFile
{
    [self clearPlayers];
    
    [self cancelGenerate];
    
    [self removeGPUFilter];
    
    isReverseMediaGenerating_ = NO;
    currentGenerate_ = nil;
    isGeneratingByFilter_ = NO;
    isReverseGenerating_ = NO;
    isGenerating_ = NO;
    isGeneratingWithCheck_ = NO;
    isGenerateEnter_ = NO;
    currentFilterIndex_ = 0;
    lastFilterIndex_ = 0;
    videoVol_ = 1;
    audioVol_ = 1;
    secondsForAudioPlayerMaxRange_ = 0.5;
    _bitRate = (long)(540 *960 * 8);
    _renderSize = CGSizeMake(540, 960);
    
    [self setNeedPlaySync:YES];
    currentMediaWithAction_ = nil;
    
    [actionList_ removeAllObjects];
    [mediaList_ removeAllObjects];
    [mediaListFilter_ removeAllObjects];
    
    for (int i = 1;i<videoBGHistroy_.count;i++) {
        MediaItem * item = videoBGHistroy_[i];
        [[HCFileManager manager]removeFileAtPath:item.filePath];
    }
    
    //    for (int i = 0;i<reverseBgHistory_.count;i++) {
    //        MediaItem * item = reverseBgHistory_[i];
    //        [[HCFileManager manager]removeFileAtPath:item.filePath];
    //    }
    //    if(reverseBG_ && reverseBG_.filePath)
    //    {
    //        [[HCFileManager manager]removeFileAtPath:reverseBG_.filePath];
    //    }
    
    HCFileManager * manager = [HCFileManager manager];
    NSString * tempFilePath = [manager getFilePath:[manager tempFileDir]];
    [[HCFileManager manager]removeFilesAtPath:tempFilePath matchRegex:@"^media_reverse_\\d+.*"];
    
    NSString * localFilePath = [manager getFilePath:[manager localFileDir]];
    [[HCFileManager manager]removeFilesAtPath:localFilePath matchRegex:@"^action_merge_\\d+.*"];
    [[HCFileManager manager]removeFilesAtPath:localFilePath matchRegex:@"^\\d+\\.[^\\.]+$"];
    
    [videoBGHistroy_ removeAllObjects];
    //    [reverseBgHistory_ removeAllObjects];
    [actionsHistory_ removeAllObjects];
    
    PP_RELEASE(audioBg_);
    PP_RELEASE(videoBg_);
    //    PP_RELEASE(reverseBG_);
    
    durationForSource_ = 0;
    durationForAudio_ = 0;
    durationForTarget_ = 0;
}
- (void)setVol:(CGFloat)audioVol videoVol:(CGFloat)videoVol
{
    audioVol_ = audioVol;
    videoVol_ = videoVol;
    if(audioPlayer_)
    {
        [audioPlayer_ setVolume:audioVol_];
    }
    if(player_)
    {
        [player_ setVideoVolume:videoVol_];
    }
    //    if(reversePlayer_)
    //    {
    //        [reversePlayer_ setVideoVolume:videoVol_];
    //    }
    NSLog(@"set vol:%.2f videovol:%.2f",audioVol,videoVol);
}
- (NSArray *) getMediaList
{
    return mediaList_;
}
- (NSArray *) getActionList
{
    return actionList_;
}
- (MediaItem *) getBaseVideo
{
    return videoBg_;
}
- (MediaItem *)getBaseAudio
{
    return audioBg_;
}
- (int) getLastFilterID
{
    return lastFilterIndex_;
}
- (int) getCurrentFilterID
{
    return currentFilterIndex_;
}
//- (MediaItem *)getReverseVideo
//{
//    return reverseBG_;
//}
//将MediaWithAction转成普通的MediaItem，其实只需要检查其对应的文件片段是否需要生成
- (BOOL)generateMediaListWithActions:(NSArray *)mediaWithActions complted:(void (^)(NSArray *))complted
{
    NSMutableArray * resultList = [NSMutableArray new];
    for (MediaWithAction * action in mediaWithActions) {
        MediaItem * item = [[MediaItem alloc]init];
        [item fetchAsCore:(MediaItemCore*)action];
        
        //        //如果是已经生成的文件，如另选择的文件
        //        if(item.fileNameGenerated && item.fileNameGenerated.length>0)
        //        {
        //            //需要修改此处的开始与结束时间，以便于处理
        //            item.begin = CMTimeMakeWithSeconds(0,item.begin.timescale);
        //            item.end = item.duration;
        //            item.fileName = item.fileNameGenerated;
        //        }
        
        if(item.secondsDurationInArray>0)
        {
            [resultList addObject:item];
            NSLog(@"%d(%.2f len:%.2f) file:(%.2f--%.2f) rate:%.2f",
                  (int)action.Action.ActionType,
                  item.secondsInArray,
                  item.secondsDurationInArray,
                  item.secondsBegin,item.secondsEnd,
                  item.playRate);
        }
    }
    if(complted)
    {
        complted(resultList);
    }
    return YES;
}
- (MediaWithAction *) getCurrentMediaWithAction
{
    return currentMediaWithAction_;
}
- (void) setCurrentMediaWithAction:(MediaWithAction *)media
{
    currentMediaWithAction_ = nil;
    if(media)
    {
        currentMediaWithAction_ = media;
    }
    NSLog(@" 更新当前媒体:%@",currentMediaWithAction_?[currentMediaWithAction_ toString]:nil);
    [self setNeedPlaySync:YES];
}
//根据当前对像获取...
- (CGFloat) getSecondsInArrayViaCurrentState:(CGFloat)playerSeconds
{
    CGFloat secondsInArray = playerSeconds;
    
    if(!currentMediaWithAction_) return secondsInArray;
    
    MediaWithAction * nextItem = nil;
    if(currentMediaWithAction_)
    {
        BOOL isValid = NO;
        for (MediaWithAction * item in mediaList_) {
            if(item==currentMediaWithAction_)
            {
                isValid = YES;
            }
            else if(isValid)
            {
                nextItem = item;
                break;
            }
            if(isValid)
            {
                secondsInArray = [item getSecondsInArrayByPlaySeconds:playerSeconds];
                if(secondsInArray >=0)
                    break;
            }
        }
        if(nextItem && secondsInArray<0)
        {
            secondsInArray  = nextItem.secondsInArray;
        }
    }
    else
    {
        MediaWithAction * lastItem = nil;
        MediaWithAction * notLastItem = nil;
        
        
        for (int i = (int)mediaList_.count-1;i>=0;i--){
            //        for (MediaWithAction * item in mediaList_) {
            MediaWithAction * item = [mediaList_ objectAtIndex:i];
            if(!item.secondsInArrayNotConfirm)
            {
                if(!lastItem)
                {
                    lastItem = item;
                }
                else if(!notLastItem)
                {
                    notLastItem = item;
                }
                if(item.Action.ActionType==SNormal && item.secondsBeginBeforeReverse <= playerSeconds && item.secondsEndBeforeReverse > playerSeconds)
                {
                    secondsInArray = [item getSecondsInArrayByPlaySeconds:playerSeconds];
                    break;
                }
            }
        }
        if(secondsInArray<0)
        {
            if(notLastItem.Action.ActionType==SReverse)
            {
                secondsInArray = notLastItem.secondsInArray;
            }
            else
                secondsInArray = lastItem.secondsInArray;
        }
    }
    return secondsInArray;
}
#pragma mark - action list manager
- (BOOL) checkIsNeedChangeBG:(NSString *)filePath
{
    NSString * filePathOrg = videoBg_.filePath;
    if([filePath isEqualToString:filePathOrg])
    {
        return NO;
    }
    return YES;
    //    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:generateOK:cover:isFilter:)])
    //    {
    //        [self.delegate ActionManager:self generateOK:videoBg_.filePath cover:nil isFilter:NO];
    //    }
    //    if(isReverseHasGenerated_ && videoBg_ )
    //    {
    //        NSString * filePathOrg = videoBg_.filePath;
    //        if([filePath isEqualToString:filePathOrg])
    //        {
    //            if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:reverseGenerated:)])
    //            {
    //                [self.delegate ActionManager:self reverseGenerated:reverseBG_];
    //            }
    //            return NO;
    //        }
    //        isReverseHasGenerated_ = NO;
    //    }
    return YES;
}

- (BOOL)setBackMV:(NSString *)filePath begin:(CGFloat)beginSeconds end:(CGFloat)endSeconds  buildReverse:(BOOL)buildReverse
{
    if(![self checkIsNeedChangeBG:filePath]) return NO;
    
    if(isGenerating_ || isReverseGenerating_) return NO;
    isGenerating_ = YES;
    //设置正向视频
    {
        PP_RELEASE(videoBg_);
        videoBg_ = [manager_ getMediaItem:[NSURL fileURLWithPath:filePath]];
        if(beginSeconds>0 && beginSeconds < videoBg_.secondsDuration)
        {
            videoBg_.begin = CMTimeMakeWithSeconds(beginSeconds,DEFAULT_TIMESCALE);
        }
        if(endSeconds >0 && endSeconds < videoBg_.secondsDuration)
        {
            videoBg_.end = CMTimeMakeWithSeconds(endSeconds, DEFAULT_TIMESCALE);
        }
        videoBg_.timeInArray = CMTimeMakeWithSeconds(0, DEFAULT_TIMESCALE);
        
        PP_RELEASE(videoBgAction_);
    }
    //生成反向的视频
    //    if(buildReverse)
    //    {
    //        isReverseGenerating_ = NO;
    //        [self generateReverseMV:filePath];
    //    }
    
    videoBgAction_ = [self getNormalActionForBase];
    currentMediaWithAction_ = nil;
    isGenerating_ = NO;
    
    [player_ pause];
    
    [self changeFilterPlayerItem];
    
    [self reindexAllActions];
    
    if(currentGenerate_)
    {
        [currentGenerate_ setJoinVideoUrl:nil];
        [currentGenerate_ clear];
    }
    
    return YES;
}
- (MediaWithAction *) getNormalActionForBase
{
    MediaActionForNormal * action =[MediaActionForNormal new];
    action.ActionType = 0;
    action.MediaActionID = [self getMediaActionID];
    action.Rate = 1;
    action.ReverseSeconds = 0;
    action.DurationInSeconds = -1;
    action.IsFilter = NO;
    action.IsMutex = NO;
    action.Media = videoBg_;
    
    return [action toMediaWithAction:nil];
}
- (BOOL)setBackMV:(MediaItem *)bgMedia  buildReverse:(BOOL)buildReverse
{
    if(!bgMedia) return NO;
    if(![self checkIsNeedChangeBG:bgMedia.filePath]) return NO;
    
    if(isGenerating_ || isReverseGenerating_)
        return NO;
    isGenerating_ = YES;
    
    //设置正向视频
    {
        PP_RELEASE(videoBg_);
        videoBg_ = [bgMedia copyItem];
        videoBg_.timeInArray = CMTimeMakeWithSeconds(0, DEFAULT_TIMESCALE);
        
        PP_RELEASE(videoBgAction_);
    }
    //    //生成反向的视频
    //    if(buildReverse)
    //    {
    //        [self generateReverseMV:videoBg_.filePath];
    //    }
    
    videoBgAction_ = [self getNormalActionForBase];
    
    currentMediaWithAction_ = nil;
    
    [self reindexAllActions];
    isGenerating_ = NO;
    
    [self changeFilterPlayerItem];
    
    if(currentGenerate_)
    {
        [currentGenerate_ setJoinVideoUrl:nil];
        [currentGenerate_ clear];
    }
    
    return YES;
}

- (BOOL)setBackAudio:(NSString *)filePath begin:(CGFloat)beginSeconds end:(CGFloat)endSeconds
{
    PP_RELEASE(audioBg_);
    //    if(audioPlayer_)
    //    {
    //        [audioPlayer_ pause];
    //    }
    if(!filePath) return NO;
    
    audioBg_ = [manager_ getMediaItem:[NSURL fileURLWithPath:filePath]];
    
    AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:filePath]];
    if(!asset || asset.duration.value ==0) return NO;
    
    CMTimeScale timeScale = MAX(asset.duration.timescale,DEFAULT_AUDIOTIMESCALE);
    CGFloat secondsInArray = 0;
    if(beginSeconds<0)
    {
        secondsInArray = 0 - beginSeconds;
        beginSeconds = 0;
    }
    audioBg_.begin = CMTimeMakeWithSeconds(beginSeconds,timeScale);
    //    }
    
    if(endSeconds >0 && endSeconds < audioBg_.secondsDuration)
    {
        audioBg_.end = CMTimeMakeWithSeconds(endSeconds, timeScale);
    }
    else
    {
        audioBg_.end =  CMTimeMakeWithSeconds(0,timeScale);
    }
    audioBg_.timeInArray = CMTimeMakeWithSeconds(secondsInArray, timeScale);
    return YES;
}
- (BOOL)setBackAudio:(MediaItem *)audioItem
{
    PP_RELEASE(audioBg_);
    if(audioItem)
    {
        audioBg_ = [audioItem copyItem];
        //        audioBg_.timeInArray = CMTimeMakeWithSeconds(0, audioItem.begin.timescale);
    }
    return YES;
}
// 是否能在指定位置增加一个动作
// action:当前动作，需要加入的
// seconds:当前播放器时间，有可能为反向播放器的时间
- (BOOL)canAddAction:(MediaAction *)action seconds:(CGFloat)playerSeconds
{
    if(isGenerating_) return NO;
    
    if(playerSeconds<0||playerSeconds>= videoBg_.secondsDuration)
        return NO;
    else
    {
        if(!currentMediaWithAction_ || currentMediaWithAction_.Action.ActionType == SNormal)
        {
            return YES;
        }
        else
        {
            return NO;
        }
    }
}
//将播放器时间转为原轨时间
//当Rate发生变化时，播放器的时间并不发生变化，即播放到同一片段时，播放器返回的时钟值在不同速率时是相同的
//将播放器的时间转成素材轨的时间
//取最后的一个时间作为标准
//isrevers 标志当前这个时间是属于倒放的时间，如果是正放，则不需要标记
- (CGFloat) getSecondsInArrayFromPlayer:(CGFloat)playerSeconds  isReversePlayer:(BOOL)isReversePlayer
{
    CGFloat secondsInFinal = 0;
    
    MediaWithAction * lastDo_ = nil;
    int index = 0;
    //    if(!isReversePlayer)
    //    {
    for (int i = (int)mediaList_.count-1; i>=0; i --) {
        MediaWithAction * item = mediaList_[i];
        if(item.secondsBeginBeforeReverse <= playerSeconds
           && (item.secondsEndBeforeReverse > playerSeconds
               || (item.secondsEndBeforeReverse + SECONDS_ERRORRANGE>=playerSeconds && playerSeconds +SECONDS_ERRORRANGE >= [self getBaseVideo].secondsDuration)) //到结束了
           && ![self isReverseFile:item.fileName]
           && !item.secondsInArrayNotConfirm
           )
        {
            index = i;
            lastDo_ = item;
            break;
        }
    }
    //    }
    //    else
    //    {
    //        for (int i = (int)mediaList_.count-1; i>=0; i --) {
    //            MediaWithAction * item = mediaList_[i];
    //            if(item.secondsBeginBeforeReverse <= playerSeconds
    //               && (item.secondsEndBeforeReverse > playerSeconds
    //                   || (item.secondsEndBeforeReverse + SECONDS_ERRORRANGE>=playerSeconds && playerSeconds +SECONDS_ERRORRANGE >= [self getReverseVideo].secondsDuration)) //到结束了
    //               && [self isReverseFile:item.fileName]
    //               && !item.secondsInArrayNotConfirm
    //               )
    //            {
    //                index = i;
    //                lastDo_ = item;
    //                break;
    //            }
    //        }
    //    }
    if(lastDo_)
    {
        secondsInFinal = lastDo_.secondsInArray;
        if(lastDo_.Action.ActionType==SReverse)
        {
            if([self isReverseFile:lastDo_.fileName])
            {
                if(isReversePlayer)
                {
                    secondsInFinal += playerSeconds - lastDo_.secondsBeginBeforeReverse;
                }
                else
                {
                    secondsInFinal += [self getBaseVideo].secondsDuration -  lastDo_.secondsBeginBeforeReverse +  playerSeconds;
                    NSLog(@"不应该发生的事情。。。。");
                }
            }
            else
            {
                secondsInFinal += playerSeconds - lastDo_.secondsBeginBeforeReverse;
            }
        }
        else
        {
            secondsInFinal += playerSeconds - lastDo_.secondsBeginBeforeReverse;
        }
        
    }
    return secondsInFinal;
    
    //    for (MediaWithAction * item in mediaList_) {
    //        if(item.secondsDurationInArray <=0) continue;
    //        if(playerSeconds >=secondsInFinal && playerSeconds < secondsInFinal + item.secondsDurationInArray && item.secondsInArrayNotConfirm == NO)
    //        {
    //            return item.secondsInArray + (playerSeconds - secondsInFinal);// * item.secondsDurationInArray /item.durationInFinalArray;
    //        }
    //        else
    //        {
    //            secondsInFinal += item.secondsDurationInArray;
    //        }
    //    }
    //    return playerSeconds;
}
- (BOOL) isReverseFile:(NSString *)fileName
{
    if(!fileName) return NO;
    return [fileName rangeOfString:@"reverse_"].location !=NSNotFound;
}
- (MediaActionDo *) getMediaActionDo:(MediaAction *)action
{
    MediaActionDo * item = nil;
    switch (action.ActionType) {
        case 1:
            item = [MediaActionForSlow new];
            break;
        case 2:
            item = [MediaActionForFast new];
            break;
        case 3:
            item = [MediaActionForRAP new];
            break;
        case 4:
            item = [MediaActionForReverse new];
            break;
        default:
            item = [MediaActionForNormal new];
            break;
    }
    if(action.MediaActionID<=0)
    {
        action.MediaActionID = [self getMediaActionID];
    }
    [item fetchAsAction:action];
    return item;
}
- (double) getMediaActionID
{
    return [[NSDate date]timeIntervalSince1970];
}
- (MediaActionDo *) findMediaActionDoByType:(int)actionType
{
    MediaActionDo * result = nil;
    for (MediaActionDo * item in actionList_) {
        if(item.ActionType == actionType)
        {
            result = item;
            break;
        }
    }
    return result;
}
- (MediaActionDo *)addActionItem:(MediaAction *)action filePath:(NSString *)filePath
                              at:(CGFloat)playerSeconds
                            from:(CGFloat)mediaBeginSeconds
                        duration:(CGFloat)durationInSeconds;
{
    [self setNeedPlaySync:NO];
    [self pausePlayer];
    //    MediaActionDo * item = [self getMediaActionDo:action];
    
    //对用户在用手操作时的延时进行校正
    if(action.secondsBeginAdjust!=0)
    {
        playerSeconds += action.secondsBeginAdjust;
    }
    //Repeat，需要将定位放到前面
    CGFloat secondsInArray = playerSeconds;
    if(action.ActionType==SRepeat && action.ReverseSeconds<0)
    {
        secondsInArray =  [self getSecondsInArrayFromPlayer:playerSeconds isReversePlayer:NO] - durationInSeconds;
    }
    else
    {
        secondsInArray = [self getSecondsInArrayFromPlayer:playerSeconds isReversePlayer:NO];
    }
    return [self addActionItem:action filePath:filePath inArray:secondsInArray from:mediaBeginSeconds duration:durationInSeconds];
}
- (MediaActionDo *)addActionItem:(MediaAction *)action filePath:(NSString *)filePath
                         inArray:(CGFloat)secondsInArray
                            from:(CGFloat)mediaBeginSeconds
                        duration:(CGFloat)durationInSeconds;
{
    needSendPlayControl_ = NO;
    [self pausePlayer];
    
    MediaActionDo * item = [self getMediaActionDo:action];
    
    //    //对用户在用手操作时的延时进行校正
    //    if(item.secondsBeginAdjust!=0)
    //    {
    //        playerSeconds += item.secondsBeginAdjust;
    //    }
    
    if(filePath && filePath.length>0 && [filePath isEqualToString:videoBg_.filePath]==NO)
    {
        MediaItem * tempItem = [manager_ getMediaItem:[NSURL fileURLWithPath:filePath]];
        if(tempItem)
        {
            item.Media = [tempItem copyAsCore];
        }
    }
    else
    {
        //倒放对应的东东不太一样，有两段
        if(item.ActionType == SReverse)
        {
            item.Media = [videoBg_ copyAsCore];
            //            item.Media = [reverseBG_ copyAsCore];
            item.Media.begin = CMTimeMakeWithSeconds(mediaBeginSeconds, item.Media.begin.timescale);
            //                CMTimeMakeWithSeconds(MAX(item.Media.secondsDuration - mediaBeginSeconds,0), item.Media.begin.timescale);
            if(durationInSeconds>0)
            {
                item.Media.end = CMTimeMakeWithSeconds(MAX(item.Media.secondsBegin - durationInSeconds,0) , item.Media.end.timescale);
                //                item.Media.end = CMTimeMakeWithSeconds(MIN(item.Media.secondsBegin + durationInSeconds,videoBg_.secondsDuration) , item.Media.end.timescale);
            }
            
            MediaActionForReverse * reverse = (MediaActionForReverse *)item;
            reverse.normalMedia = [videoBg_ copyAsCore];
            reverse.normalMedia.end = CMTimeMakeWithSeconds(mediaBeginSeconds, reverse.normalMedia.end.timescale);
            if(durationInSeconds>0)
            {
                reverse.normalMedia.begin = CMTimeMakeWithSeconds(MAX(mediaBeginSeconds - durationInSeconds,0) , reverse.normalMedia.begin.timescale);
            }
        }
        else
        {
            item.Media = [videoBg_ copyAsCore];
            //重新设置开始与结束时间
            
            if(item.ActionType==SRepeat && item.ReverseSeconds>=0 && durationInSeconds>0)
            {
                item.Media.begin = CMTimeMakeWithSeconds(MAX(item.Media.secondsBegin + mediaBeginSeconds + action.ReverseSeconds - durationInSeconds,0),
                                                         item.Media.begin.timescale);
            }
            else
            {
                item.Media.begin = CMTimeMakeWithSeconds(MAX(item.Media.secondsBegin + mediaBeginSeconds + action.ReverseSeconds,0),
                                                         item.Media.begin.timescale);
            }
            if(durationInSeconds>0)
            {
                item.Media.end = CMTimeMakeWithSeconds(MIN(item.Media.secondsBegin + durationInSeconds,videoBg_.secondsDuration) , item.Media.end.timescale);
            }
        }
    }
    if(!item.Media || !item.Media.fileName || item.Media.fileName.length<2)
    {
        PP_RELEASE(item);
        [self resumePlayer];
        [self setNeedPlaySync:YES];
        return nil;
    }
    //Repeat，需要将定位放到前面
    if(item.ActionType==SRepeat && item.ReverseSeconds<0)
    {
        item.SecondsInArray =  MAX(secondsInArray - durationInSeconds,0);// [self getSecondsInArrayFromPlayer:playerSeconds isReversePlayer:NO] - durationInSeconds;
    }
    else
    {
        item.SecondsInArray = secondsInArray;// [self getSecondsInArrayFromPlayer:playerSeconds isReversePlayer:NO];
    }
    item.DurationInArray = durationInSeconds;
    
    if(durationInSeconds<=0)
    {
        item.isOPCompleted = NO;
    }
    else
    {
        item.isOPCompleted = YES;
    }
    item.Index = (int)actionList_.count;
    
    [actionList_ addObject:item];
    
    
    NSLog(@"####### before do:%@",[item toDicionary]);
    
    [self ActionManager:self actionChanged:item type:0];
    
    
    //    if(item.isOPCompleted)
    //    {
    [self processNewActions];
    //    [self reindexAllActions];
    //    }
    NSArray * array = [item buildMaterialProcess:mediaList_];
    MediaWithAction * media = [array firstObject];
    if(item.isOPCompleted)
    {
        [self refreshSecondsEffectPlayer:item.DurationInArray + item.SecondsInArray];
        NSLog(@"secondsEffectPlayer_:%.4f",secondsEffectPlayer_);
        
        if(item.ActionType ==SRepeat) //重复，则需要从下一个开始才行
        {
            [self ActionManager:self play:item media:media seconds:SECONDS_NOEND];
        }
        else //直接点击的，则直接执行当前Action
        {
            [self ActionManager:self play:item media:media seconds:SECONDS_NOEND];
        }
        [self buildTimerForPlayerSync:media.secondsDurationInArray];
    }
    else
    {
        needSendPlayControl_ = NO;
        [self ActionManager:self play:item media:media seconds:SECONDS_NOEND];
    }
    //延时处理倒放视频的问题
    [self doSomethingAfterProcess:item];
    
    return item;
}
- (MediaActionDo *) addActionItemDo:(MediaActionDo *)actionDo
                                 at:(CGFloat)playerSeconds
{
    needSendPlayControl_ = NO;
    [self pausePlayer];
    
    CGFloat secondsInArray = actionDo.SecondsInArray;
    //Repeat，需要将定位放到前面
    if(actionDo.ActionType==SRepeat && actionDo.ReverseSeconds<0)
    {
        secondsInArray = [self getSecondsInArrayFromPlayer:playerSeconds isReversePlayer:NO] - actionDo.DurationInSeconds;
    }
    else
    {
        secondsInArray = [self getSecondsInArrayFromPlayer:playerSeconds isReversePlayer:NO];
    }
    return [self addActionItemDo:actionDo inArray:secondsInArray];
}

- (MediaActionDo *) addActionItemDo:(MediaActionDo *)actionDo
                            inArray:(CGFloat)secondsInArray
{
    return [self addActionItemDo:actionDo inArray:secondsInArray changeCurrentAction:YES];
}
- (MediaActionDo *) addActionItemDo:(MediaActionDo *)actionDo
                            inArray:(CGFloat)secondsInArray
                changeCurrentAction:(BOOL)changeCurrentAction
{
    MediaActionDo * item = nil;//[actionDo copyItemDo];
    if(actionDo.isOPCompleted==NO)
    {
        BOOL hasAction = NO;
        for (MediaActionDo * item in actionList_) {
            if(item==actionDo)
            {
                hasAction = YES;
                break;
            }
        }
        if(hasAction)
        {
            item = [actionDo copyItemDo];
            [self setActionItemDuration:actionDo duration:secondsInArray - actionDo.SecondsInArray];
        }
        else
        {
            item = actionDo;
        }
    }
    else
    {
        item = [actionDo copyItemDo];
    }
    [self pausePlayer];
    
    
    
    //    //Repeat，需要将定位放到前面
    //    if(item.ActionType==SRepeat)
    //    {
    //        item.SecondsInArray = [self getSecondsInArrayFromPlayer:playerSeconds isReversePlayer:NO] - item.DurationInSeconds;
    //    }
    //    else
    //    {
    //        item.SecondsInArray = [self getSecondsInArrayFromPlayer:playerSeconds isReversePlayer:NO];
    //    }
    
    item.SecondsInArray = secondsInArray;
    
    [self refreshSecondsEffectPlayer:item.DurationInArray + item.SecondsInArray];
    //    secondsEffectPlayer_ += [item secondsEffectPlayer];
    
    item.Index = (int)actionList_.count;
    item.MediaActionID = [self getMediaActionID];
    
    [actionList_ addObject:item];
    
    
    NSLog(@"####### action in array:%.4f",item.SecondsInArray);
    
    [self ActionManager:self actionChanged:item type:0];
    
    
    //    if(item.isOPCompleted)
    //    {
    [self processNewActions];
    
    //播当前这个
    MediaWithAction * media = [[item buildMaterialProcess:mediaList_]firstObject];
    
    //影响当前播放对像
    if(changeCurrentAction)
    {
        [self ActionManager:self play:item media:media seconds:SECONDS_NOEND];
        if(actionDo.isOPCompleted)
        {
            [self buildTimerForPlayerSync:media.secondsDurationInArray];
        }
        else
            needSendPlayControl_ = NO;
    }
    else //不影响当前播放对像
    {
        //        [self buildTimerForPlayerSync:self.minMediaDuration];
        [player_ play];
    }
    //延时处理倒放视频的问题
    [self doSomethingAfterProcess:item];
    
    return item;
    
}
- (void)pausePlayer
{
    needSendPlayControl_ = NO;
    [player_ pause];
    //    [reversePlayer_ pause];
    //    [audioPlayer_ pause];
}
- (void)resumePlayer
{
    //    if(player_.hidden==NO)
    [player_ play];
    //    else
    //        [reversePlayer_ play];
    //    if(audioPlayer_)
    //    {
    //        [audioPlayer_ play];
    //    }
    [self setNeedPlaySync:YES];
    //    needSendPlayControl_ = YES;
}
//针对长按等操作，延后设置Action时长
- (BOOL)setActionItemDuration:(MediaActionDo *)action duration:(CGFloat)durationInSeconds
{
    if(!action) return NO;
    if(![actionList_ containsObject:action]) return NO;
    if(action.isOPCompleted) return NO;  //如果已经完成的，则不能再设时长。如果需要更改，需要将其移除再Add进来
    needSendPlayControl_ = NO;
    
    [self pausePlayer];
    
    //durationInseconds 会触发相关的更新事件
    //    action.Media.end = CMTimeMakeWithSeconds(action.Media.secondsBegin + durationInSeconds, action.Media.end.timescale);
    action.DurationInSeconds = durationInSeconds;
    action.DurationInArray = durationInSeconds;
    
    action.isOPCompleted = YES;
    NSLog(@"set actionitem %d inarray:%.2f  d:%.2f",action.ActionType, action.SecondsInArray,durationInSeconds);
    mediaList_ = [action ensureAction:mediaList_ durationInArray:durationInSeconds];
    //    [action processAction:mediaList_ secondsEffected:secondsEffectPlayer_];
    
    [self refreshSecondsEffectPlayer:action.DurationInArray + action.SecondsInArray];
    //    secondsEffectPlayer_ += [action secondsEffectPlayer];
    NSLog(@"secondsEffectPlayer_:%.4f",secondsEffectPlayer_);
    
    [self ActionManager:self actionChanged:action type:1];
    
    //检查播放器是否同步在走，如果是同步，表示长按，直接播下一个素材，如果不是同步，则表示Click，播当前素材
    BOOL isPlayerSync = YES;
    MediaWithAction * media = [action buildMaterialProcess:mediaList_].count>0?[[action buildMaterialProcess:mediaList_]firstObject]:nil;
    if(media && ((action.ActionType==SReverse  && player_.secondsPlaying > media.secondsBegin + 0.15) ||
                 (action.IsOverlap && player_.secondsPlaying + 0.1 < durationInSeconds + media.secondsBegin))
       )
    {
        isPlayerSync = NO;
    }
    if(!isPlayerSync && media)
    {
        NSLog(@"AM :播放器不同步，表示是Click");
    }
    else
    {
        NSLog(@"AM :播放器同步，表示是长按");
        //播下一个
        media = [self findMediaItemAt:action.SecondsInArray + action.DurationInArray+SECONDS_ERRORRANGE];
        //        media = [self findMediaItemAt:action.SecondsInArray + action.DurationInArray+SECONDS_ERRORRANGE];
#ifndef __OPTIMIZE__
        if(!media || media.secondsBeginBeforeReverse < SECONDS_ERRORRANGE)
        {
            media = [self findMediaItemAt:action.SecondsInArray + action.DurationInArray+SECONDS_ERRORRANGE];
        }
#endif
        if(!media)
        {
            NSArray * metaList = [action buildMaterialProcess:mediaList_];
            if(metaList.count>0)
            {
                MediaWithAction * item = [metaList lastObject];
                //reach end
                if(item.secondsEnd +SECONDS_ERRORRANGE >= [self getBaseVideo].secondsDuration)
                {
                    media = [mediaList_ firstObject];
                }
            }
            else
            {
                media = [mediaList_ firstObject];
            }
        }
    }

    NSLog(@"playerSeconds:%f (%f) media:%f->%f",player_.secondsPlaying,CMTimeGetSeconds(player_.currentPlayer.currentItem.currentTime), media.secondsBegin,media.secondsEnd);
    
    [self ActionManager:self play:action media:media seconds:SECONDS_NOTVALID];
    
    //因为切换播放进程时，有可能播放器会发送时间过来，导致切换出现BUG，所以延时处理一下
    [self buildTimerForPlayerSync:durationInSeconds];
    
    //延时处理倒放视频的问题
    [self doSomethingAfterProcess:action];
    return YES;
}
- (void)doSomethingAfterProcess:(MediaActionDo *)action
{
    //延时处理倒放视频的问题
    if(action.ActionType==SReverse && action.isOPCompleted)
    {
        __weak ActionManager * weakSelf = self;
        __block NSTimer * weakTimer2 = [HWWeakTimer scheduledTimerWithTimeInterval:0.25f
                                                                             block:^(id userInfo) {
                                                                                 [weakTimer2 invalidate];
                                                                                 weakTimer2 = nil;
                                                                                 if(action.ActionType==SReverse)
                                                                                 {
                                                                                     __strong ActionManager * strongSelf = weakSelf;
                                                                                     [strongSelf generateMediaFileViaAction:(MediaActionDo *)userInfo];
                                                                                 }
                                                                                 
                                                                             } userInfo:action repeats:NO];
        
        [weakTimer2 fire];
    }
}
- (void)buildTimerForPlayerSync:(CGFloat)secondsDurationInArray
{
    if(timerForPlayerSync_)
    {
        [timerForPlayerSync_ invalidate];
        timerForPlayerSync_ = nil;
    }
    timerForPlayerSync_ = [HWWeakTimer scheduledTimerWithTimeInterval:MAX(minMediaDuration_,secondsDurationInArray- 0.1)
                                                                block:^(id userInfo) {
                                                                    [self setNeedPlaySync:YES];
                                                                    [timerForPlayerSync_ invalidate];
                                                                    timerForPlayerSync_ = nil;
                                                                } userInfo:nil repeats:NO];
    
    [timerForPlayerSync_ fire];
}
- (void)refreshSecondsEffectPlayer:(CGFloat)secondsEndInArray
{
    secondsEffectPlayer_ = 0;
    for (MediaWithAction * item in mediaList_) {
        if(item.secondsInArray >= secondsEndInArray- SECONDS_ERRORRANGE)
        {
            break;
        }
        secondsEffectPlayer_ += item.secondsChangedWithActionForPlayer;
    }
}
//将未完成的Action完成，一般用于播放完成
- (BOOL) ensureActions:(CGFloat)playerSeconds
{
    MediaActionDo * action = [actionList_ lastObject];
    
    if(action && action.isOPCompleted==NO)
    {
        //        needSendPlayControl_ = NO;
        if(action.ActionType==SReverse)
        {
            CGFloat duration = playerSeconds - action.Media.secondsBegin;
            if(duration<0) duration = 0 - duration;
            [self setActionItemDuration:action duration:duration];
        }
        else
        {
            CGFloat duration = [self getSecondsInArrayFromPlayer:playerSeconds isReversePlayer:action.IsReverse];
            duration -= action.SecondsInArray;
            if(duration<0) duration = 0 - duration;
            [self setActionItemDuration:action duration:duration];
        }
        //        needSendPlayControl_ = YES;
        return YES;
    }
    return NO;
}
- (MediaActionDo *)findActionAt:(CGFloat)secondsInArray
                          index:(int)index
{
    MediaActionDo * retItem = nil;
    if(index>=0)
    {
        if(actionList_.count>index)
        {
            retItem =  actionList_[index];
        }
    }
    else if(secondsInArray>=0)
    {
        for (int i = (int)actionList_.count -1; i>=0; i--) {
            MediaActionDo * item = actionList_[i];
            
            BOOL containsSeconds = [item containSecondsInArray:secondsInArray];
            
            NSLog(@"[%d]find index:%d item[%d]: %.4f dur:%.4f media:%.2f-%.2f  targetSeconds:%.4f isfound:%d",i,
                  item.Index,
                  item.ActionType,item.SecondsInArray,item.DurationInSeconds,
                  item.Media.secondsBegin,item.Media.secondsEnd,
                  secondsInArray,containsSeconds);
            
            if(containsSeconds)
            {
                retItem = item;
                break;
            }
        }
    }
    //    if(secondsInArray<0||!retItem)
    //    {
    //        NSLog(@"not found");
    //    }
    return retItem;
}
- (MediaWithAction *)findMediaItemAt:(CGFloat)secondsInArray
{
    MediaWithAction * retItem = nil;
    for (int i = (int)mediaList_.count -1; i>=0; i--) {
        MediaWithAction * item = mediaList_[i];
        NSLog(@"find media: %.4f  targetSeconds:%.4f",item.secondsInArray,secondsInArray);
        if(!item.secondsInArrayNotConfirm   //只有开始时间已经确定了的才能参与选择
           && item.secondsInArray - item.Action.secondsBeginAdjust <=secondsInArray+SECONDS_ERRORRANGE
           && (item.secondsDurationInArray <0
               || item.secondsDurationInArray + item.secondsInArray - item.Action.secondsBeginAdjust >secondsInArray -SECONDS_ERRORRANGE)
           )
        {
            retItem = item;
            break;
        }
    }
    NSLog(@"find media:%@",retItem?@"OK":@"NO");
    return retItem;
}
////根据Action取对应的素材信息，可能取当前Action的，或者之前，或者之后的
//- (MediaWithAction *)findMediaWithAction:(MediaActionDo*)action index:(int)index
//{
//    MediaWithAction * retItem = nil;
//    int pos = 0;
//    MediaWithAction * nextItem = nil;
//    NSMutableArray * mediaInActions = [NSMutableArray new];
//    for (int i = 0;i< (int)mediaList_.count; i ++) {
//        MediaWithAction * item = mediaList_[i];
//
//        //根据MediaActionID来判断是否属于某个Action
//        if((
//            action
//            && item.Action.MediaActionID>0
//            &&
//            item.Action.MediaActionID == action.MediaActionID
//            )
//           ||
//           (
//            !action
//            && item.Action.ActionType==SNormal)
//           )
//        {
//            [mediaInActions addObject:item];
//        }
//        else
//        {
//            nextItem = item;
//        }
//    }
//
//    //取哪一个，负数表示之后的
//    if(pos==index || (index <0 && pos == 0 - index - 1))
//    {
//        retItem = item;
//        break;
//    }
//    pos ++;
//
//    NSLog(@"find media:%@",retItem?@"OK":@"NO");
//    if(index<0)
//    {
//        //最后了
//        if(!nextItem && action.Media.secondsEnd >= [self getBaseVideo].secondsDuration - SECONDS_ERRORRANGE)
//        {
//            nextItem = [mediaList_ firstObject];
//        }
//        return nextItem;
//    }
//    else
//        return retItem;
//}
- (BOOL)removeActionItem:(MediaAction *)action
                      at:(CGFloat)seccondsInArray
{
    MediaActionDo * item = [self findActionAt:seccondsInArray index:-1];
    if(!item) return NO;
    return [self removeActionItem:item];
}

- (BOOL)removeActionItem:(MediaActionDo *)actionDo
{
    if(actionDo)
    {
        BOOL beginDec = NO;
        for (MediaActionDo * item in actionList_) {
            if(item == actionDo)
            {
                beginDec = YES;
            }
            if(beginDec)
            {
                item.Index --;
            }
        }
        secondsEffectPlayer_ -= [actionDo secondsEffectPlayer];
        [actionList_ removeObject:actionDo];
        
        [self ActionManager:self actionChanged:actionDo type:2];
        
        [self reindexAllActions];
        return YES;
    }
    return NO;
}
- (BOOL) removeActionItemsInArray:(NSArray *)actions
{
    if(!actions || actions.count==0) return NO;
    for (int i = (int)actions.count-1; i >=0;i --) {
        
        MediaActionDo * actionDo = actions[i];
        BOOL beginDec = NO;
        for (MediaActionDo * item in actionList_) {
            if(item == actionDo)
            {
                beginDec = YES;
            }
            if(beginDec)
            {
                item.Index --;
            }
        }
        secondsEffectPlayer_ -= [actionDo secondsEffectPlayer];
        [actionList_ removeObject:actionDo];
        [self ActionManager:self actionChanged:actionDo type:2];
    }
    
    [self reindexAllActions];
    return YES;
}
- (BOOL) removeActions
{
    [actionList_ removeAllObjects];
    [mediaList_ removeAllObjects];
    [self reindexAllActions];
    return YES;
}
- (void) setNeedPlaySync:(BOOL)need
{
    needSendPlayControl_ = need;
#ifndef __OPTIMIZE__
    if(actionList_.count>0)
    {
        MediaActionDo * action = [actionList_ lastObject];
        if(action.isOPCompleted==NO && need)
        {
            NSLog(@"此时不需要同步播放时钟，但传入需要同步的信息，需检查 。");
        }
    }
#endif
}
#pragma mark - draft manager
- (BOOL) saveDraft
{
    if(!videoBg_ /*|| !reverseBG_*/)
    {
        NSLog(@"no data to save....");
        return NO;
    }
    if((actionList_.count>0 || currentFilterIndex_!=lastFilterIndex_) && videoBGHistroy_.count>0 )
    {
        [videoBGHistroy_ addObject:videoBg_];
        //        [reverseBgHistory_ addObject:reverseBG_];
        [actionsHistory_ addObject:[NSArray arrayWithArray:actionList_]];
        [filterHistory_ addObject:[NSNumber numberWithInt:currentFilterIndex_]];
        
        NSLog(@"items saved.");
    }
    else if(videoBGHistroy_.count==0)
    {
        [videoBGHistroy_ addObject:videoBg_];
        //        [reverseBgHistory_ addObject:reverseBG_];
        [actionsHistory_ addObject:[NSArray arrayWithArray:actionList_]];
        [filterHistory_ addObject:[NSNumber numberWithInt:currentFilterIndex_]];
    }
    else
    {
        NSLog(@"no data need save.");
    }
    
    return YES;
}
- (BOOL) resetOrigin
{
    //    if(videoBGHistroy_.count>0)
    //    {
    //        videoBg_ = [videoBGHistroy_ firstObject];
    ////        reverseBG_ = [reverseBgHistory_ firstObject];
    //    }
    
    currentMediaWithAction_ = nil;
    
    [actionsHistory_ removeAllObjects];
    //    [reverseBgHistory_ removeAllObjects];
    [videoBGHistroy_ removeAllObjects];
    [filterHistory_ removeAllObjects];
    [actionList_ removeAllObjects];
    
    [videoBGHistroy_ addObject:videoBg_];
    //    if(reverseBG_)
    //        [reverseBgHistory_ addObject:reverseBG_];
    [actionsHistory_ addObject:[NSArray arrayWithArray:actionList_]];
    [filterHistory_ addObject:[NSNumber numberWithInt:currentFilterIndex_]];
    
    videoBgAction_ = [self getNormalActionForBase];
    
    [self reindexAllActions];
    
    [self saveDraft];
    
    return YES;
}
- (BOOL) loadOrigin
{
    if(videoBGHistroy_.count>0)
    {
        videoBg_ = [videoBGHistroy_ firstObject];
        //        reverseBG_ = [reverseBgHistory_ firstObject];
    }
    //    currentFilterIndex_ = 0;
    //    lastFilterIndex_ = 0;
    currentMediaWithAction_ = nil;
    
    
    [actionList_ removeAllObjects];
    
    [actionsHistory_ removeAllObjects];
    //    [reverseBgHistory_ removeAllObjects];
    [videoBGHistroy_ removeAllObjects];
    [filterHistory_ removeAllObjects];
    
    
    [videoBGHistroy_ addObject:videoBg_];
    //    if(reverseBG_)
    //        [reverseBgHistory_ addObject:reverseBG_];
    [actionsHistory_ addObject:[NSArray arrayWithArray:actionList_]];
    [filterHistory_ addObject:[NSNumber numberWithInt:currentFilterIndex_]];
    
    videoBgAction_ = [self getNormalActionForBase];
    
    [self reindexAllActions];
    
    [self changeFilterPlayerItem];
    
    return YES;
}
- (BOOL) setLastDraftAsOrigin
{
    if(videoBGHistroy_.count==0)
        return NO;
    
    videoBg_ = [videoBGHistroy_ lastObject];
    //    reverseBG_ = [reverseBgHistory_ lastObject];
    
    currentMediaWithAction_ = nil;
    
    [actionsHistory_ removeAllObjects];
    //    [reverseBgHistory_ removeAllObjects];
    [videoBGHistroy_ removeAllObjects];
    [filterHistory_ removeAllObjects];
    [actionList_ removeAllObjects];
    
    [videoBGHistroy_ addObject:videoBg_];
    //    if(reverseBG_)
    //        [reverseBgHistory_ addObject:reverseBG_];
    [actionsHistory_ addObject:[NSArray arrayWithArray:actionList_]];
    [filterHistory_ addObject:[NSNumber numberWithInt:currentFilterIndex_]];
    
    videoBgAction_ = [self getNormalActionForBase];
    
    [self reindexAllActions];
    
    [self saveDraft];
    
    [self changeFilterPlayerItem];
    
    return YES;
}
- (BOOL) loadLastDraft
{
    if(videoBGHistroy_.count<=0) return NO;
    
    
    currentMediaWithAction_ = nil;
    
    videoBg_ = [videoBGHistroy_ lastObject];
    //    reverseBG_ = [reverseBgHistory_ lastObject];
    currentFilterIndex_ = [[filterHistory_ lastObject]intValue];
    [actionList_ removeAllObjects];
    //    [actionList_ addObjectsFromArray:[actionsHistory_ lastObject]];
    
    [actionsHistory_ removeObjectAtIndex:actionsHistory_.count-1];
    [videoBGHistroy_ removeObjectAtIndex:videoBGHistroy_.count-1];
    //    [reverseBgHistory_ removeObjectAtIndex:reverseBgHistory_.count-1];
    [filterHistory_ removeObjectAtIndex:filterHistory_.count-1];
    
    videoBgAction_ = [self getNormalActionForBase];
    
    [self reindexAllActions];
    NSLog(@"last draft loaded.remain history:%d",(int)videoBGHistroy_.count);
    
    [self changeFilterPlayerItem];
    
    return YES;
}
- (BOOL) loadFirstDraft
{
    if(videoBGHistroy_.count<=1) return NO;
    
    currentMediaWithAction_ = nil;
    
    videoBg_ = [videoBGHistroy_ objectAtIndex:1];
    //    reverseBG_ = [reverseBgHistory_ objectAtIndex:1];
    currentFilterIndex_ = [[filterHistory_ objectAtIndex:1]intValue];
    [actionList_ removeAllObjects];
    //不要赋值
    //        [actionList_ addObjectsFromArray:[actionsHistory_ objectAtIndex:1]];
    [actionsHistory_ removeAllObjects];
    //    [reverseBgHistory_ removeAllObjects];
    [videoBGHistroy_ removeAllObjects];
    [filterHistory_ removeAllObjects];
    
    [actionsHistory_ addObject:actionList_];
    //    [reverseBgHistory_ addObject:reverseBG_];
    [videoBGHistroy_ addObject:videoBg_];
    [filterHistory_ addObject:[NSNumber numberWithInt:currentFilterIndex_]];
    
    videoBgAction_ = [self getNormalActionForBase];
    
    [self reindexAllActions];
    NSLog(@"last draft loaded.remain history:%d",(int)videoBGHistroy_.count);
    
    [self changeFilterPlayerItem];
    return YES;
}
- (int) getHistoryCount
{
    return (int)videoBGHistroy_.count;
}
- (BOOL) getDraft:(int)index base:(MediaItem *__autoreleasing *)baseVideo reverse:(MediaItem *__autoreleasing *)reverseVideo actionList:(NSArray *__autoreleasing *)actionList filterID:(int *)filterID
{
    if(videoBGHistroy_.count <= index)
        return NO;
    if(baseVideo)
        *baseVideo = [videoBGHistroy_ objectAtIndex:index];
    //    if(reverseVideo)
    //        *reverseVideo = [reverseBgHistory_ objectAtIndex:index];
    if(*actionList)
        *actionList = [actionsHistory_ objectAtIndex:index];
    if(*filterID)
        *filterID = [[filterHistory_ objectAtIndex:index]intValue];
    
    return YES;
}
- (BOOL) needGenerateForOP
{
    return actionList_.count>0 ;//|| (lastFilterIndex_ != currentFilterIndex_);
}
- (BOOL) needGenerateForFilter
{
    return (lastFilterIndex_ != currentFilterIndex_);
}
- (CGFloat) secondsEffectedByActionsForPlayer
{
    return secondsEffectPlayer_;
}
- (CGFloat) secondsEffectedByActionsForPlayerBeforeMedia:(MediaWithAction *)media
{
    CGFloat totalSeconds = 0;
    for (MediaWithAction * item in mediaList_) {
        if(item==media)
            break;
        totalSeconds += item.secondsChangedWithActionForPlayer;
    }
    return totalSeconds;
}
- (CGFloat) secondsForTrack:(CGFloat)seconds
{
    return seconds + secondsEffectPlayer_;
}
#pragma mark - delegate
- (void)VideoGenerater:(VideoGenerater*)queue didPlayerItemReady:(AVPlayerItem *)playerItem
{
    NSLog(@"playeritem ready...");
}
- (void)VideoGenerater:(VideoGenerater *)queue didItemsChanged:(BOOL)finished
{
    NSLog(@"items changed:%d",finished);
}
- (void)VideoGenerater:(VideoGenerater *)queue generateProgress:(CGFloat)progress
{
    NSLog(@"progress:%f",progress);
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:generateProgress:isFilter:)])
    {
        [self.delegate ActionManager:self generateProgress:progress isFilter:NO];
    }
}
- (void)VideoGenerater:(VideoGenerater *)queue generateReverseProgress:(CGFloat)progress
{
    NSLog(@"reverse progress:%f",progress);
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:generateReverseProgress:)])
    {
        [self.delegate ActionManager:self generateReverseProgress:progress];
    }
}
- (void)VideoGenerater:(VideoGenerater *)queue didGenerateFailure:(NSString *)msg error:(NSError *)error
{
    NSLog(@"generate failure:%@",msg);
    NSLog(@"error:%@",[error localizedDescription]);
    isGenerating_ = NO;
    [self setNeedPlaySync:YES];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:genreateFailure:isFilter:)])
    {
        [self.delegate ActionManager:self genreateFailure:error isFilter:NO];
    }
    [currentGenerate_ clear];
    currentGenerate_ = nil;
    isGeneratingWithCheck_ = NO;
    isGenerateEnter_ = NO;
}
- (void)VideoGenerater:(VideoGenerater *)queue didGenerateCompleted:(NSURL *)fileUrl cover:(NSString *)cover
{
    isGenerating_ = NO;
    [self setNeedPlaySync:YES];
    NSString * fileName = [[HCFileManager manager]getFileNameByTicks:@"action_merge.mp4"];
    NSString * filePath = [[HCFileManager manager]localFileFullPath:fileName];
    [HCFileManager copyFile:[fileUrl path] target:filePath overwrite:YES];
    NSLog(@"generate completed:%@",[[HCFileManager manager]getFileName:filePath]);
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:generateOK:cover:isFilter:)])
    {
        [self.delegate ActionManager:self generateOK:filePath cover:cover isFilter:NO];
    }
    [currentGenerate_ clear];
    currentGenerate_ = nil;
    isGeneratingWithCheck_ = NO;
    isGenerateEnter_ = NO;
}
@end

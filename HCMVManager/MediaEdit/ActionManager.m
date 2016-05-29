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

@interface ActionManager()

@end
@implementation ActionManager
{
    
    BOOL isReverseGenerating_;
    BOOL isReverseHasGenerated_;
}
@synthesize videoVolume = videoVol_;
@synthesize audioVolume = audioVol_;
@synthesize isGenerating = isGenerating_;
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
        reverseBgHistory_ = [NSMutableArray new];
        actionsHistory_ = [NSMutableArray new];
        
        manager_.delegate = self;
        isReverseGenerating_ = NO;
        isReverseHasGenerated_ = NO;
        isGeneratingByFilter_ = NO;
        isGenerating_ = NO;
        lastFilterIndex_ = 0;
        currentFilterIndex_ = 0;
        currentMediaWithAction_ = nil;
        videoVol_ = 1;
        audioVol_ = 1;
        needSendPlayControl_ = YES;
        //        lastPlayerSeconds_ = 0;
    }
    return self;
}
- (void)resetStates
{
    isGeneratingByFilter_ = NO;
    isReverseGenerating_ = NO;
    isGenerating_ = NO;
    currentFilterIndex_ = 0;
    lastFilterIndex_ = 0;
    needSendPlayControl_ = YES;
    durationForSource_ = 0;
    durationForAudio_ = 0;
    durationForTarget_ = 0;
    currentMediaWithAction_ = nil;
    
    videoVol_ = 1;
    audioVol_ = 1;
}
- (void)clear
{
    isGeneratingByFilter_ = NO;
    isReverseGenerating_ = NO;
    isGenerating_ = NO;
    currentFilterIndex_ = 0;
    lastFilterIndex_ = 0;
    needSendPlayControl_ = YES;
    currentMediaWithAction_ = nil;
    
    [actionList_ removeAllObjects];
    [mediaList_ removeAllObjects];
    [mediaListFilter_ removeAllObjects];
    
    for (int i = 1;i<videoBGHistroy_.count;i++) {
        MediaItem * item = videoBGHistroy_[i];
        [[HCFileManager manager]removeFileAtPath:item.filePath];
    }
    
    for (int i = 0;i<reverseBgHistory_.count;i++) {
        MediaItem * item = reverseBgHistory_[i];
        [[HCFileManager manager]removeFileAtPath:item.filePath];
    }
    if(reverseBG_ && reverseBG_.filePath)
    {
        [[HCFileManager manager]removeFileAtPath:reverseBG_.filePath];
    }
    
    [videoBGHistroy_ removeAllObjects];
    [reverseBgHistory_ removeAllObjects];
    [actionsHistory_ removeAllObjects];
    
    PP_RELEASE(audioBg_);
    PP_RELEASE(videoBg_);
    PP_RELEASE(reverseBG_);
    
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
    if(reversePlayer_)
    {
        [reversePlayer_ setVideoVolume:videoVol_];
    }
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
- (int) getLastFilterID
{
    return lastFilterIndex_;
}
- (int) getCurrentFilterID
{
    return currentFilterIndex_;
}
- (MediaItem *)getReverseVideo
{
    return reverseBG_;
}
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
}
//根据当前对像获取...
- (CGFloat) getSecondsInArrayViaCurrentState:(CGFloat)playerSeconds
{
    CGFloat secondsInArray = playerSeconds;
    
    if(currentMediaWithAction_)
    {
        BOOL isValid = NO;
        for (MediaWithAction * item in mediaList_) {
            if(item==currentMediaWithAction_)
            {
                isValid = YES;
            }
            if(isValid && item.secondsBegin <= playerSeconds && item.secondsEnd > playerSeconds)
            {
                secondsInArray = item.secondsInArray + playerSeconds - item.secondsBegin;
                break;
            }
        }
        if(!isValid)
        {
            for (MediaWithAction * item in mediaList_) {
                if(item.secondsBegin <= playerSeconds && item.secondsEnd > playerSeconds)
                {
                    secondsInArray = item.secondsInArray + playerSeconds - item.secondsBegin;
                    break;
                }
            }
        }
    }
    else
    {
        for (MediaWithAction * item in mediaList_) {
            if(item.Action.ActionType==SNormal && item.secondsBegin <= playerSeconds && item.secondsEnd > playerSeconds)
            {
                secondsInArray = item.secondsInArray + playerSeconds - item.secondsBegin;
                break;
            }
        }
    }
    return secondsInArray;
}
#pragma mark - action list manager
- (BOOL) checkIsNeedChangeBG:(NSString *)filePath
{
    if(isReverseHasGenerated_ && videoBg_ )
    {
        NSString * filePathOrg = videoBg_.filePath;
        if([filePath isEqualToString:filePathOrg])
        {
            if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:reverseGenerated:)])
            {
                [self.delegate ActionManager:self reverseGenerated:reverseBG_];
            }
            return NO;
        }
        isReverseHasGenerated_ = NO;
    }
    return YES;
}
- (BOOL)generateReverseMV:(NSString*)filePath
{
    if(!filePath) return NO;
    //生成反向的视频
    {
        if(isReverseGenerating_)
        {
            NSLog(@"正在生成反向视频中，不能再次进入");
            return NO;
        }
        isReverseGenerating_ = YES;
        if(reverseBG_)
        {
            PP_RELEASE(reverseBG_);
        }
        NSString * fileName = [[HCFileManager manager]getFileNameByTicks:@"reverse.mp4"];
        NSString * outputPath = [[HCFileManager manager]tempFileFullPath:fileName];
        
        VideoGenerater * vg = [VideoGenerater new];
        vg.TagID = 2;
        __weak ActionManager * weakSelf = self;
        NSLog(@"begin generate reverse video....");
        BOOL ret = [vg generateMVReverse:filePath target:outputPath
                                complted:^(NSString * filePathNew){
                                    NSLog(@"genreate reveser video ok:%@",[filePathNew lastPathComponent]);
                                    if(filePathNew)
                                    {
                                        isReverseHasGenerated_ = YES;
                                        reverseBG_ = [manager_ getMediaItem:[NSURL fileURLWithPath:filePathNew]];
                                        reverseBG_.begin = CMTimeMakeWithSeconds(videoBg_.secondsDuration - videoBg_.secondsEnd,videoBg_.end.timescale);
                                        reverseBG_.end = CMTimeMakeWithSeconds(videoBg_.secondsDuration - videoBg_.secondsBegin,videoBg_.begin.timescale);
                                        
                                        __strong ActionManager * strongSelf = weakSelf;
                                        if(strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(ActionManager:reverseGenerated:)])
                                        {
                                            [strongSelf.delegate ActionManager:strongSelf reverseGenerated:reverseBG_];
                                        }
                                    }
                                    isReverseGenerating_ = NO;
                                }];
        if(!ret)
        {
            isReverseGenerating_ = NO;
            isReverseHasGenerated_ = NO;
            NSLog(@"generate reverse failure....");
            return NO;
        }
    }
    return YES;
}
- (BOOL)setBackMV:(NSString *)filePath begin:(CGFloat)beginSeconds end:(CGFloat)endSeconds  buildReverse:(BOOL)buildReverse
{
    if(![self checkIsNeedChangeBG:filePath]) return NO;
    
    if(isReverseGenerating_) return NO;
    
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
    if(buildReverse)
    {
        [self generateReverseMV:filePath];
    }
    MediaActionForNormal * action =[MediaActionForNormal new];
    action.ActionType = 0;
    action.MediaActionID = [self getMediaActionID];
    action.Rate = 1;
    action.ReverseSeconds = 0;
    action.DurationInSeconds = -1;
    action.IsFilter = NO;
    action.IsMutex = NO;
    action.Media = videoBg_;
    
    videoBgAction_ = [action toMediaWithAction:nil];
    currentMediaWithAction_ = nil;
    [self reindexAllActions];
    return YES;
}
- (BOOL)setBackMV:(MediaItem *)bgMedia  buildReverse:(BOOL)buildReverse
{
    if(!bgMedia) return NO;
    if(![self checkIsNeedChangeBG:bgMedia.filePath]) return NO;
    
    if(isReverseGenerating_) return NO;
    isReverseGenerating_ = YES;
    
    //设置正向视频
    {
        PP_RELEASE(videoBg_);
        videoBg_ = [bgMedia copyItem];
        videoBg_.timeInArray = CMTimeMakeWithSeconds(0, DEFAULT_TIMESCALE);
        
        PP_RELEASE(videoBgAction_);
    }
    //生成反向的视频
    if(buildReverse)
    {
        [self generateReverseMV:videoBg_.filePath];
    }
    MediaActionForNormal * action =[MediaActionForNormal new];
    action.ActionType = 0;
    action.MediaActionID = 0;
    action.Rate = 1;
    action.ReverseSeconds = 0;
    action.DurationInSeconds = -1;
    action.IsFilter = NO;
    action.IsMutex = NO;
    action.Media = videoBg_;
    
    videoBgAction_ = [action toMediaWithAction:nil];
    
    currentMediaWithAction_ = nil;
    
    [self reindexAllActions];
    
    return YES;
}

- (BOOL)setBackAudio:(NSString *)filePath begin:(CGFloat)beginSeconds end:(CGFloat)endSeconds
{
    PP_RELEASE(audioBg_);
    audioBg_ = [manager_ getMediaItem:[NSURL fileURLWithPath:filePath]];
    if(beginSeconds>0 && beginSeconds < audioBg_.secondsDuration)
    {
        audioBg_.begin = CMTimeMakeWithSeconds(beginSeconds,DEFAULT_TIMESCALE);
    }
    if(endSeconds >0 && endSeconds < audioBg_.secondsDuration)
    {
        audioBg_.end = CMTimeMakeWithSeconds(endSeconds, DEFAULT_TIMESCALE);
    }
    return YES;
}
- (BOOL)setBackAudio:(MediaItem *)audioItem
{
    PP_RELEASE(audioBg_);
    if(audioItem)
    {
        audioBg_ = [audioItem copyItem];
        audioBg_.timeInArray = CMTimeMakeWithSeconds(0, audioItem.begin.timescale);
        //    videoBg_.timeInArray = CMTimeMakeWithSeconds(0, audioItem.begin.timescale);
    }
    return YES;
}
// 是否能在指定位置增加一个动作
// action:当前动作，需要加入的
// seconds:当前播放器时间，有可能为反向播放器的时间
- (BOOL)canAddAction:(MediaAction *)action seconds:(CGFloat)playerSeconds
{
    if(isGenerating_) return NO;
    
    if(action.ActionType==SReverse && !reverseBG_)
    {
        return NO;
    }
    
    //    if([self findActionAt:seconds index:-1])
    //    {
    //        return NO;
    //    }
    //    else
    //    {
    if(playerSeconds<0||playerSeconds>= videoBg_.secondsDuration)
        return NO;
    else
    {
        return YES;
    }
    //    }
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
    if(!isReversePlayer)
    {
        for (int i = (int)mediaList_.count-1; i>=0; i --) {
            MediaWithAction * item = mediaList_[i];
            if(item.secondsBegin <= playerSeconds
               && (item.secondsEnd > playerSeconds
                   || (item.secondsEnd + SECONDS_ERRORRANGE>=playerSeconds && playerSeconds +SECONDS_ERRORRANGE >= [self getBaseVideo].secondsDuration)) //到结束了
               && ![self isReverseFile:item.fileName]
               && !item.secondsInArrayNotConfirm
               )
            {
                index = i;
                lastDo_ = item;
                break;
            }
        }
    }
    else
    {
        for (int i = (int)mediaList_.count-1; i>=0; i --) {
            MediaWithAction * item = mediaList_[i];
            if(item.secondsBegin <= playerSeconds
               && (item.secondsEnd > playerSeconds
                   || (item.secondsEnd + SECONDS_ERRORRANGE>=playerSeconds && playerSeconds +SECONDS_ERRORRANGE >= [self getReverseVideo].secondsDuration)) //到结束了
               && [self isReverseFile:item.fileName]
               && !item.secondsInArrayNotConfirm
               )
            {
                index = i;
                lastDo_ = item;
                break;
            }
        }
    }
    if(lastDo_)
    {
        secondsInFinal = lastDo_.secondsInArray;
        if(lastDo_.Action.ActionType==SReverse)
        {
            if([self isReverseFile:lastDo_.fileName])
            {
                if(isReversePlayer)
                {
                    secondsInFinal += playerSeconds - lastDo_.secondsBegin;
                }
                else
                {
                    secondsInFinal += [self getReverseVideo].secondsDuration -  lastDo_.secondsBegin +  playerSeconds;
                    NSLog(@"不应该发生的事情。。。。");
                }
            }
            else
            {
                secondsInFinal += playerSeconds - lastDo_.secondsBegin;
            }
        }
        else
        {
            secondsInFinal += playerSeconds - lastDo_.secondsBegin;
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
    MediaActionDo * item = [self getMediaActionDo:action];
    
    //对用户在用手操作时的延时进行校正
    if(item.secondsBeginAdjust!=0)
    {
        playerSeconds += item.secondsBeginAdjust;
    }
    //Repeat，需要将定位放到前面
    if(item.ActionType==SRepeat && item.ReverseSeconds<0)
    {
        item.SecondsInArray =  [self getSecondsInArrayFromPlayer:playerSeconds isReversePlayer:NO] - durationInSeconds;
    }
    else
    {
        item.SecondsInArray = [self getSecondsInArrayFromPlayer:playerSeconds isReversePlayer:NO];
    }
    return [self addActionItem:action filePath:filePath inArray:item.SecondsInArray from:mediaBeginSeconds duration:durationInSeconds];
}
- (MediaActionDo *)addActionItem:(MediaAction *)action filePath:(NSString *)filePath
                         inArray:(CGFloat)secondsInArray
                            from:(CGFloat)mediaBeginSeconds
                        duration:(CGFloat)durationInSeconds;
{
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
            item.Media = [reverseBG_ copyAsCore];
            item.Media.begin = CMTimeMakeWithSeconds(MAX(item.Media.secondsDuration - mediaBeginSeconds,0), item.Media.begin.timescale);
            if(durationInSeconds>0)
            {
                item.Media.end = CMTimeMakeWithSeconds(MIN(item.Media.secondsBegin + durationInSeconds,videoBg_.secondsDuration) , item.Media.end.timescale);
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
    }
    else
    {
        [self ActionManager:self play:item media:media seconds:SECONDS_NOEND];
    }
    return item;
}
- (MediaActionDo *) addActionItemDo:(MediaActionDo *)actionDo
                                 at:(CGFloat)playerSeconds
{
    if(actionDo.isOPCompleted==NO) return nil;
    CGFloat secondsInArray = actionDo.SecondsInArray;
    //Repeat，需要将定位放到前面
    if(actionDo.ActionType==SRepeat)
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
    if(actionDo.isOPCompleted==NO) return nil;
    
    MediaActionDo * item = [actionDo copyItemDo];
    
    //    //Repeat，需要将定位放到前面
    //    if(item.ActionType==SRepeat)
    //    {
    //        item.SecondsInArray = [self getSecondsInArrayFromPlayer:playerSeconds isReversePlayer:NO] - item.DurationInSeconds;
    //    }
    //    else
    //    {
    //        item.SecondsInArray = [self getSecondsInArrayFromPlayer:playerSeconds isReversePlayer:NO];
    //    }
    
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
    [self ActionManager:self play:item media:media seconds:SECONDS_NOEND];
    
    return item;
    
    
}
//针对长按等操作，延后设置Action时长
- (BOOL)setActionItemDuration:(MediaActionDo *)action duration:(CGFloat)durationInSeconds
{
    if(!action) return NO;
    if(![actionList_ containsObject:action]) return NO;
    
    action.DurationInSeconds = durationInSeconds;
    action.DurationInArray = durationInSeconds;
    action.Media.end = CMTimeMakeWithSeconds(action.Media.secondsBegin + durationInSeconds, action.Media.end.timescale);
    
    action.isOPCompleted = YES;
    NSLog(@"set actionitem %d inarray:%.2f  d:%.2f",action.ActionType, action.SecondsInArray,durationInSeconds);
    mediaList_ = [action ensureAction:mediaList_ durationInArray:durationInSeconds];
    //    [action processAction:mediaList_ secondsEffected:secondsEffectPlayer_];
    
    [self refreshSecondsEffectPlayer:action.DurationInArray + action.SecondsInArray];
    //    secondsEffectPlayer_ += [action secondsEffectPlayer];
    NSLog(@"secondsEffectPlayer_:%.4f",secondsEffectPlayer_);
    
    [self ActionManager:self actionChanged:action type:1];
    
    //    [self reindexAllActions];
    
    //播下一个
    MediaWithAction * media = [self findMediaItemAt:action.SecondsInArray + action.DurationInArray+SECONDS_ERRORRANGE];
    
    [self ActionManager:self play:action media:media seconds:SECONDS_NOTVALID];
    
    return YES;
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
        needSendPlayControl_ = NO;
        if(action.ActionType==SReverse)
        {
            CGFloat duration = playerSeconds - action.Media.secondsBegin;
            
            //            currentSeconds = reverseBG_.secondsDuration - currentSeconds;
            //            CGFloat duration = MAX(action.SecondsInArray - currentSeconds - secondsEffectPlayer_,0);
            [self setActionItemDuration:action duration:duration];
        }
        else
        {
            CGFloat duration = [self getSecondsInArrayFromPlayer:playerSeconds isReversePlayer:action.IsReverse];
            duration -= action.SecondsInArray;
            [self setActionItemDuration:action duration:duration];
        }
        needSendPlayControl_ = YES;
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
            
            NSLog(@"[%d]find item: %.4f  targetSeconds:%.4f result:%d",i,item.SecondsInArray,secondsInArray,containsSeconds);
            
            if(containsSeconds)
            {
                retItem = item;
                break;
            }
            //            //起hhko在当前时间前
            //            if(item.SecondsInArray - secondsInArray < 0 - item.secondsBeginAdjust + SECONDS_ERRORRANGE )
            //            {
            //                if(item.DurationInArray <0 ||
            //                   (item.DurationInArray>=0 && item.DurationInArray + item.SecondsInArray - secondsInArray > SECONDS_ERRORRANGE - item.secondsBeginAdjust))
            //                {
            //                    retItem = item;
            //                    break;
            //                }
            //                else if(item.DurationInArray <0)
            //                {
            //                    retItem = item;
            //                    break;
            //                }
            //            }
            //            NSLog(@"find item:%@",retItem?@"OK":@"NO");
        }
        
    }
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
- (MediaWithAction *)findMediaWithAction:(MediaActionDo*)action index:(int)index
{
    MediaWithAction * retItem = nil;
    int pos = 0;
    MediaWithAction * nextItem = nil;
    for (int i = (int)mediaList_.count -1; i>=0; i--) {
        MediaWithAction * item = mediaList_[i];
        if((action && item.Action.MediaActionID>0 &&
            item.Action.MediaActionID == action.MediaActionID)
           ||
           (!action && item.Action.ActionType==SNormal))
        {
            if(pos==index || (index <0 && pos == 0 - index - 1))
            {
                retItem = item;
                break;
            }
            pos ++;
        }
        else
        {
            nextItem = item;
        }
    }
    NSLog(@"find media:%@",retItem?@"OK":@"NO");
    if(index<0)
    {
        //最后了
        if(!nextItem && action.Media.secondsEnd >= [self getBaseVideo].secondsDuration - SECONDS_ERRORRANGE)
        {
            nextItem = [mediaList_ firstObject];
        }
        return nextItem;
    }
    else
        return retItem;
}
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
- (BOOL) removeActions
{
    [actionList_ removeAllObjects];
    [mediaList_ removeAllObjects];
    [self reindexAllActions];
    return YES;
}
#pragma mark - draft manager
- (BOOL) saveDraft
{
    if(!videoBg_ || !reverseBG_)
    {
        NSLog(@"no data to save....");
        return NO;
    }
    if((actionList_.count>0 || currentFilterIndex_!=lastFilterIndex_) && videoBGHistroy_.count>0 )
    {
        [videoBGHistroy_ addObject:videoBg_];
        [reverseBgHistory_ addObject:reverseBG_];
        [actionsHistory_ addObject:[NSArray arrayWithArray:actionList_]];
        [filterHistory_ addObject:[NSNumber numberWithInt:currentFilterIndex_]];
        
        NSLog(@"items saved.");
    }
    else if(videoBGHistroy_.count==0)
    {
        [videoBGHistroy_ addObject:videoBg_];
        [reverseBgHistory_ addObject:reverseBG_];
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
    if(videoBGHistroy_.count>0)
    {
        videoBg_ = [videoBGHistroy_ firstObject];
        reverseBG_ = [reverseBgHistory_ firstObject];
    }
    [actionsHistory_ removeAllObjects];
    [reverseBgHistory_ removeAllObjects];
    [videoBGHistroy_ removeAllObjects];
    [filterHistory_ removeAllObjects];
    [actionList_ removeAllObjects];
    
    [videoBGHistroy_ addObject:videoBg_];
    [reverseBgHistory_ addObject:reverseBG_];
    [actionsHistory_ addObject:[NSArray arrayWithArray:actionList_]];
    [filterHistory_ addObject:[NSNumber numberWithInt:currentFilterIndex_]];
    
    [self reindexAllActions];
    
    [self saveDraft];
    
    return YES;
}
- (BOOL) loadOrigin
{
    if(videoBGHistroy_.count>0)
    {
        videoBg_ = [videoBGHistroy_ firstObject];
        reverseBG_ = [reverseBgHistory_ firstObject];
    }
    currentFilterIndex_ = 0;
    lastFilterIndex_ = 0;
    [actionList_ removeAllObjects];
    
    [actionsHistory_ removeAllObjects];
    [reverseBgHistory_ removeAllObjects];
    [videoBGHistroy_ removeAllObjects];
    [filterHistory_ removeAllObjects];
    
    
    [videoBGHistroy_ addObject:videoBg_];
    [reverseBgHistory_ addObject:reverseBG_];
    [actionsHistory_ addObject:[NSArray arrayWithArray:actionList_]];
    [filterHistory_ addObject:[NSNumber numberWithInt:currentFilterIndex_]];
    
    
    [self reindexAllActions];
    
    return YES;
}
- (BOOL) loadLastDraft
{
    if(videoBGHistroy_.count<=0) return NO;
    
    videoBg_ = [videoBGHistroy_ lastObject];
    reverseBG_ = [reverseBgHistory_ lastObject];
    currentFilterIndex_ = [[filterHistory_ lastObject]intValue];
    [actionList_ removeAllObjects];
    //    [actionList_ addObjectsFromArray:[actionsHistory_ lastObject]];
    
    [actionsHistory_ removeObjectAtIndex:actionsHistory_.count-1];
    [videoBGHistroy_ removeObjectAtIndex:videoBGHistroy_.count-1];
    [reverseBgHistory_ removeObjectAtIndex:reverseBgHistory_.count-1];
    [filterHistory_ removeObjectAtIndex:filterHistory_.count-1];
    
    [self reindexAllActions];
    NSLog(@"last draft loaded.remain history:%d",(int)videoBGHistroy_.count);
    return YES;
}
- (BOOL) loadFirstDraft
{
    if(videoBGHistroy_.count<=1) return NO;
    
    videoBg_ = [videoBGHistroy_ objectAtIndex:1];
    reverseBG_ = [reverseBgHistory_ objectAtIndex:1];
    currentFilterIndex_ = [[filterHistory_ objectAtIndex:1]intValue];
    [actionList_ removeAllObjects];
    //不要赋值
    //        [actionList_ addObjectsFromArray:[actionsHistory_ objectAtIndex:1]];
    [actionsHistory_ removeAllObjects];
    [reverseBgHistory_ removeAllObjects];
    [videoBGHistroy_ removeAllObjects];
    [filterHistory_ removeAllObjects];
    
    [actionsHistory_ addObject:actionList_];
    [reverseBgHistory_ addObject:reverseBG_];
    [videoBGHistroy_ addObject:videoBg_];
    [filterHistory_ addObject:[NSNumber numberWithInt:currentFilterIndex_]];
    
    [self reindexAllActions];
    NSLog(@"last draft loaded.remain history:%d",(int)videoBGHistroy_.count);
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
    if(reverseVideo)
        *reverseVideo = [reverseBgHistory_ objectAtIndex:index];
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
- (void)VideoGenerater:(VideoGenerater *)queue didGenerateFailure:(NSString *)msg error:(NSError *)error
{
    NSLog(@"generate failure:%@",msg);
    NSLog(@"error:%@",[error localizedDescription]);
    isGenerating_ = NO;
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:genreateFailure:isFilter:)])
    {
        [self.delegate ActionManager:self genreateFailure:error isFilter:NO];
    }
}
- (void)VideoGenerater:(VideoGenerater *)queue didGenerateCompleted:(NSURL *)fileUrl cover:(NSString *)cover
{
    isGenerating_ = NO;
    NSString * fileName = [[HCFileManager manager]getFileNameByTicks:@"merge.mp4"];
    NSString * filePath = [[HCFileManager manager]localFileFullPath:fileName];
    [HCFileManager copyFile:[fileUrl path] target:filePath overwrite:YES];
    NSLog(@"generate completed:%@",[[HCFileManager manager]getFileName:filePath]);
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:generateOK:cover:isFilter:)])
    {
        [self.delegate ActionManager:self generateOK:filePath cover:cover isFilter:NO];
    }
}
@end

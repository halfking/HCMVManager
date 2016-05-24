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
        
        videoVol_ = 1;
        audioVol_ = 1;
    }
    return self;
}
- (void)clear
{
    
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
        if(reverseBG_)
        {
            PP_RELEASE(reverseBG_);
        }
        NSString * fileName = [[HCFileManager manager]getFileNameByTicks:@"reverse.mp4"];
        NSString * outputPath = [[HCFileManager manager]tempFileFullPath:fileName];
        
        VideoGenerater * vg = [VideoGenerater new];
        __weak ActionManager * weakSelf = self;
        [vg generateMVReverse:filePath target:outputPath
                     complted:^(NSString * filePathNew){
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
    }
    return YES;
}
- (BOOL)setBackMV:(NSString *)filePath begin:(CGFloat)beginSeconds end:(CGFloat)endSeconds  buildReverse:(BOOL)buildReverse
{
    if(![self checkIsNeedChangeBG:filePath]) return NO;
    
    if(isReverseGenerating_) return NO;
    isReverseGenerating_ = YES;
    
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
    audioBg_ = [audioItem copyItem];
    audioBg_.timeInArray = CMTimeMakeWithSeconds(0, audioItem.begin.timescale);
    //    videoBg_.timeInArray = CMTimeMakeWithSeconds(0, audioItem.begin.timescale);
    return YES;
}
- (BOOL)canAddAction:(MediaAction *)action seconds:(CGFloat)seconds
{
    if(action.ActionType==SReverse && !reverseBG_)
    {
        return NO;
    }
    
    if([self findActionAt:seconds index:-1])
    {
        return NO;
    }
    else
    {
        if(seconds<0||seconds>= videoBg_.secondsDuration)
            return NO;
        else
        {
            return YES;
        }
    }
}
//将播放器时间转为原轨时间
//当Rate发生变化时，播放器的时间并不发生变化，即播放到同一片段时，播放器返回的时钟值在不同速率时是相同的
- (CGFloat)getSecondsWithoutAction:(CGFloat)playerSeconds
{
    CGFloat secondsInFinal = 0;
    for (MediaWithAction * item in mediaList_) {
        if(item.secondsDurationInArray <=0) continue;
        if(playerSeconds >=secondsInFinal && playerSeconds < secondsInFinal + item.secondsDurationInArray && item.secondsInArrayNotConfirm == NO)
        {
            return item.secondsInArray + (playerSeconds - secondsInFinal);// * item.secondsDurationInArray /item.durationInFinalArray;
        }
        else
        {
            secondsInFinal += item.secondsDurationInArray;
        }
    }
    return playerSeconds;
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
- (MediaActionDo *)addActionItem:(MediaAction *)action filePath:(NSString *)filePath
                              at:(CGFloat)posSeconds
                            from:(CGFloat)mediaBeginSeconds
                        duration:(CGFloat)durationInSeconds;
{
    MediaActionDo * item = [self getMediaActionDo:action];
    
    //对用户在用手操作时的延时进行校正
    if(item.secondsBeginAdjust!=0)
    {
        posSeconds += item.secondsBeginAdjust;
    }
    
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
        //倒放对应的东东不太一样
        if(item.ActionType == SReverse)
        {
            item.Media = [reverseBG_ copyAsCore];
            item.Media.begin = CMTimeMakeWithSeconds(item.Media.secondsDuration - mediaBeginSeconds, item.Media.begin.timescale);
            if(durationInSeconds>0)
            {
                item.Media.end = CMTimeMakeWithSeconds(item.Media.secondsBegin + durationInSeconds , item.Media.end.timescale);
            }
        }
        else
        {
            item.Media = [videoBg_ copyAsCore];
            //重新设置开始与结束时间
            item.Media.begin = CMTimeMakeWithSeconds(item.Media.secondsBegin + mediaBeginSeconds + action.ReverseSeconds, item.Media.begin.timescale);
            if(durationInSeconds>0)
            {
                item.Media.end = CMTimeMakeWithSeconds(item.Media.secondsBegin + durationInSeconds , item.Media.end.timescale);
            }
        }
    }
    if(!item.Media || !item.Media.fileName || item.Media.fileName.length<2)
    {
        PP_RELEASE(item);
        return nil;
    }
    //Repeat，需要将定位放到前面
    if(item.ActionType==SRepeat)
    {
        item.SecondsInArray = posSeconds - durationInSeconds;
    }
    else
    {
        item.SecondsInArray = posSeconds;
    }
    item.DurationInArray = durationInSeconds;
    
    if(durationInSeconds<=0)
    {
        item.isOPCompleted = NO;
    }
    else
    {
        item.isOPCompleted = YES;
        
        secondsEffectPlayer_ += [item secondsEffectPlayer];
        NSLog(@"secondsEffectPlayer_:%.4f",secondsEffectPlayer_);
    }
    item.Index = (int)actionList_.count;
    
    [actionList_ addObject:item];
    
    
    NSLog(@"####### action in array:%.4f",item.SecondsInArray);
    
    [self ActionManager:self actionChanged:item type:0];
    
    
    //    if(item.isOPCompleted)
    //    {
    [self processNewActions];
    //    [self reindexAllActions];
    //    }
    if(item.isOPCompleted)
    {
        if(item.ActionType ==SRepeat) //重复，则需要从下一个开始才行
        {
            [self ActionManager:self play:item seconds:SECONDS_NOEND];
        }
        else //直接点击的，则直接执行当前Action
        {
            [self ActionManager:self play:item seconds:SECONDS_NOEND];
        }
    }
    else
        [self ActionManager:self play:item seconds:SECONDS_NOEND];
    return item;
}
- (MediaActionDo *) addActionItemDo:(MediaActionDo *)actionDo
                                 at:(CGFloat)posSeconds
{
    if(actionDo.isOPCompleted==NO) return nil;
    MediaActionDo * item = [actionDo copyItemDo];
    //Repeat，需要将定位放到前面
    if(item.ActionType==SRepeat)
    {
        item.SecondsInArray = posSeconds - item.DurationInSeconds;
    }
    else
    {
        item.SecondsInArray = posSeconds;
    }
    secondsEffectPlayer_ += [item secondsEffectPlayer];
    
    item.Index = (int)actionList_.count;
    item.MediaActionID = [self getMediaActionID];
    
    [actionList_ addObject:item];
    
    
    NSLog(@"####### action in array:%.4f",item.SecondsInArray);
    
    [self ActionManager:self actionChanged:item type:0];
    
    
    //    if(item.isOPCompleted)
    //    {
    [self processNewActions];
    
    [self ActionManager:self play:item seconds:SECONDS_NOEND];
    
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
    
    mediaList_ = [action processAction:mediaList_ secondsEffected:secondsEffectPlayer_];
    
    secondsEffectPlayer_ += [action secondsEffectPlayer];
    NSLog(@"secondsEffectPlayer_:%.4f",secondsEffectPlayer_);
    
    [self ActionManager:self actionChanged:action type:1];
    
    //    [self reindexAllActions];
    
    [self ActionManager:self play:action seconds:SECONDS_NOTVALID];
    
    
    return YES;
}
//将未完成的Action完成，一般用于播放完成
- (BOOL) ensureActions:(CGFloat)currentSeconds
{
    MediaActionDo * action = [actionList_ lastObject];
    if(action && action.isOPCompleted==NO)
    {
        if(action.ActionType==SReverse)
        {
            currentSeconds = reverseBG_.secondsDuration - currentSeconds;
            CGFloat duration = MAX(action.SecondsInArray - currentSeconds - secondsEffectPlayer_,0);
            [self setActionItemDuration:action duration:duration];
        }
        else
        {
            CGFloat duration = [self getSecondsWithoutAction:currentSeconds];
            duration += secondsEffectPlayer_;
            duration -= action.SecondsInArray;
            [self setActionItemDuration:action duration:duration];
        }
        return YES;
    }
    return NO;
}
- (MediaActionDo *)findActionAt:(CGFloat)seconds
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
    else if(seconds>=0)
    {
        for (int i = (int)actionList_.count -1; i>=0; i--) {
            MediaActionDo * item = actionList_[i];
            
            NSLog(@"find item: %.4f  targetSeconds:%.4f",item.SecondsInArray,seconds);
            //起hhko在当前时间前
            if(item.SecondsInArray - seconds < 0 - item.secondsBeginAdjust + SECONDS_ERRORRANGE )
            {
                if(item.DurationInArray <0 ||
                   (item.DurationInArray>=0 && item.DurationInArray + item.SecondsInArray - seconds > SECONDS_ERRORRANGE - item.secondsBeginAdjust))
                {
                    retItem = item;
                    break;
                }
                else if(item.DurationInArray <0)
                {
                    retItem = item;
                    break;
                }
            }
            NSLog(@"find item:%@",retItem?@"OK":@"NO");
        }
        
    }
    return retItem;
}
- (MediaWithAction *)findMediaItemAt:(CGFloat)seconds
{
    MediaWithAction * retItem = nil;
    for (int i = (int)mediaList_.count -1; i>=0; i--) {
        MediaWithAction * item = mediaList_[i];
        NSLog(@"find media: %.4f  targetSeconds:%.4f",item.secondsInArray,seconds);
        if(!item.secondsInArrayNotConfirm   //只有开始时间已经确定了的才能参与选择
           && item.secondsInArray - item.Action.secondsBeginAdjust <=seconds+SECONDS_ERRORRANGE
           && (item.secondsDurationInArray <0
               || item.secondsDurationInArray + item.secondsInArray - item.Action.secondsBeginAdjust >seconds -SECONDS_ERRORRANGE)
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
        return nextItem;
    else
        return retItem;
}
- (BOOL)removeActionItem:(MediaAction *)action
                      at:(CGFloat)posSeconds
{
    MediaActionDo * item = [self findActionAt:posSeconds index:-1];
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
    if(actionList_.count>0)
    {
        [videoBGHistroy_ addObject:videoBg_];
        [reverseBgHistory_ addObject:reverseBG_];
        [actionsHistory_ addObject:[NSArray arrayWithArray:actionList_]];
        
        NSLog(@"items saved.");
    }
    else
    {
        NSLog(@"no data need save.");
    }
    
    return YES;
}
- (BOOL) loadLastDraft
{
    if(videoBGHistroy_.count<=0) return NO;
    
    videoBg_ = [videoBGHistroy_ lastObject];
    reverseBG_ = [reverseBgHistory_ lastObject];
    [actionList_ removeAllObjects];
    [actionList_ addObjectsFromArray:[actionsHistory_ lastObject]];
    [self reindexAllActions];
    NSLog(@"last draft loaded.remain history:%d",(int)videoBGHistroy_.count);
    return YES;
}
- (BOOL) loadFirstDraft
{
    if(videoBGHistroy_.count<=0) return NO;
    
    videoBg_ = [videoBGHistroy_ firstObject];
    reverseBG_ = [reverseBgHistory_ firstObject];
    [actionList_ removeAllObjects];
    [actionList_ addObjectsFromArray:[actionsHistory_ firstObject]];
    [self reindexAllActions];
    NSLog(@"last draft loaded.remain history:%d",(int)videoBGHistroy_.count);
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
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:genreateFailure:isFilter:)])
    {
        [self.delegate ActionManager:self genreateFailure:error isFilter:NO];
    }
}
- (void)VideoGenerater:(VideoGenerater *)queue didGenerateCompleted:(NSURL *)fileUrl cover:(NSString *)cover
{
    
    NSString * fileName = [[HCFileManager manager]getFileNameByTicks:@"merge.mp4"];
    NSString * filePath = [[HCFileManager manager]localFileFullPath:fileName];
    [HCFileManager copyFile:[fileUrl path] target:filePath overwrite:YES];
    NSLog(@"generate completed:%@",filePath);
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:generateOK:cover:isFilter:)])
    {
        [self.delegate ActionManager:self generateOK:filePath cover:cover isFilter:NO];
    }
}
@end

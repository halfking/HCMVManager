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

#import "WTPlayerResource.h"

@interface ActionManager()<VideoGeneraterDelegate>

@end
@implementation ActionManager
{
    
    BOOL isReverseGenerating_;
    BOOL isReverseHasGenerated_;
}
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
- (NSArray *) getMediaList
{
    return mediaList_;
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
        if(item.fileNameGenerated && item.fileNameGenerated.length>0)
        {
#warning 需要修改此处的开始与结束时间，以便于处理
            item.begin = CMTimeMakeWithSeconds(0,item.begin.timescale);
            item.end = item.duration;
            item.fileName = item.fileNameGenerated;
        }
        [resultList addObject:item];
    }
    if(complted)
    {
        complted(resultList);
    }
    return NO;
}
#pragma mark - action list manager
- (BOOL)setBackMV:(NSString *)filePath begin:(CGFloat)beginSeconds end:(CGFloat)endSeconds
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
            return YES;
        }
        isReverseHasGenerated_ = NO;
    }
    if(isReverseGenerating_) return NO;
    isReverseGenerating_ = YES;
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
    {
        PP_RELEASE(reverseBG_);
        
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
- (BOOL)canAddAction:(MediaAction *)action seconds:(CGFloat)seconds
{
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
        if(item.durationInFinalArray <=0) continue;
        if(playerSeconds >=secondsInFinal && playerSeconds < secondsInFinal + item.durationInFinalArray)
        {
            return item.secondsInFinalArray + (playerSeconds - secondsInFinal);// * item.secondsDurationInArray /item.durationInFinalArray;
        }
        else
        {
            secondsInFinal += item.durationInFinalArray;
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
    [item fetchAsAction:action];
    return item;
}
- (MediaActionDo *)addActionItem:(MediaAction *)action filePath:(NSString *)filePath
                              at:(CGFloat)posSeconds
                        duration:(CGFloat)durationInSeconds;
{
    MediaActionDo * item = [self getMediaActionDo:action];
    if(filePath && filePath.length>0 && [filePath isEqualToString:videoBg_.filePath]==NO)
    {
        MediaItem * tempItem = [manager_ getMediaItem:[NSURL fileURLWithPath:filePath]];
        if(tempItem)
        {
            item.Media = [tempItem copyAsCore];
            //            [item parseCore:[tempItem copyAsCore]];
        }
    }
    else
    {
        //倒放对应的东东不太一样
        if(item.ActionType == SReverse)
        {
            item.Media = [reverseBG_ copyAsCore];
            item.Media.begin = CMTimeMakeWithSeconds(item.Media.secondsDuration - posSeconds, item.Media.begin.timescale);
            if(durationInSeconds>0)
            {
                item.Media.end = CMTimeMakeWithSeconds(item.Media.secondsBegin + durationInSeconds , item.Media.end.timescale);
            }
        }
        else
        {
            item.Media = [videoBg_ copyAsCore];
            //重新设置开始与结束时间
            item.Media.begin = CMTimeMakeWithSeconds(item.Media.secondsBegin + posSeconds + action.ReverseSeconds, item.Media.begin.timescale);
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
    item.SecondsInArray = posSeconds;// + action.ReverseSeconds;
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
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:actionChanged:type:)])
    {
        [self.delegate ActionManager:self actionChanged:item type:0];
    }
    
    //    if(item.isOPCompleted)
    //    {
    [self reindexAllActions];
    //    }
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:play:)])
    {
        MediaWithAction * media = [self findMediaItemAt:item.SecondsInArray];
        [self.delegate ActionManager:self play:media];
    }
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
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:actionChanged:type:)])
    {
        [self.delegate ActionManager:self actionChanged:action type:1];
    }
    
    [self reindexAllActions];
    
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:play:)])
    {
        MediaWithAction * item = [self findMediaItemAt:action.DurationInArray+action.SecondsInArray];
        [self.delegate ActionManager:self play:item];
    }
    
    return YES;
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
            if(item.SecondsInArray - seconds < 0.04)
            {
                if(item.DurationInArray>=0 && item.DurationInArray + item.SecondsInArray - seconds > 0.04)
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
        }
        
    }
    return retItem;
}
- (MediaWithAction *)findMediaItemAt:(CGFloat)seconds
{
    MediaWithAction * retItem = nil;
    for (int i = (int)mediaList_.count -1; i>=0; i--) {
        MediaWithAction * item = mediaList_[i];
        if(item.secondsInFinalArray <=seconds && item.durationInFinalArray + item.secondsInFinalArray >seconds)
        {
            retItem = item;
            break;
        }
    }
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
        
        [actionList_ removeObject:actionDo];
        
        if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:actionChanged:type:)])
        {
            [self.delegate ActionManager:self actionChanged:actionDo type:2];
        }
        
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
    NSLog(@"last draft loaded.");
    return YES;
}
- (BOOL) needGenerateForOP
{
    return actionList_.count>0;
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
}
- (void)VideoGenerater:(VideoGenerater *)queue didGenerateFailure:(NSString *)msg error:(NSError *)error
{
    NSLog(@"generate failure:%@",msg);
    NSLog(@"error:%@",[error localizedDescription]);
}
- (void)VideoGenerater:(VideoGenerater *)queue didGenerateCompleted:(NSURL *)fileUrl cover:(NSString *)cover
{
    NSLog(@"generate completed:%@",[fileUrl path]);
}
@end

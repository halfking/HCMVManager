//
//  ActionManager.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "ActionManager.h"
#import "ActionManager(index).h"

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

@interface ActionManager()<WTPlayerResourceDelegate,VideoGeneraterDelegate>

@end
@implementation ActionManager
{
    
    
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
        manager_.delegate = self;
    }
    return self;
}
- (void)clear
{
    PP_RELEASE(audioBg_);
    PP_RELEASE(videoBg_);
    [actionList_ removeAllObjects];
    [mediaList_ removeAllObjects];
    [mediaListFilter_ removeAllObjects];
//    [mediaListBG_ removeAllObjects];
    
    durationForSource_ = 0;
    durationForAudio_ = 0;
    durationForTarget_ = 0;
}
#pragma mark - action list manager
- (BOOL)setBackMV:(NSString *)filePath begin:(CGFloat)beginSeconds end:(CGFloat)endSeconds
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
- (CGFloat)getSecondsWithoutAction:(CGFloat)playerSeconds
{
#warning need fix 将播放时间变成真实的时间
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
- (BOOL)addActionItem:(MediaAction *)action filePath:(NSString *)filePath
                   at:(CGFloat)posSeconds
             duration:(CGFloat)durationInSeconds;
{
    MediaActionDo * item = [self getMediaActionDo:action];
    if(filePath && filePath.length>0)
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
        item.Media = [videoBg_ copyAsCore];
        //重新设置开始与结束时间
        item.Media.begin = CMTimeMakeWithSeconds(item.Media.secondsBegin + posSeconds + action.ReverseSeconds, item.Media.begin.timescale);
        //如果外部没有设定时长，则以Action的时长为主
        if(durationInSeconds <=0)
        {
            durationInSeconds = item.DurationInSeconds;
        }
        if(durationInSeconds>0)
        {
            item.Media.end = CMTimeMakeWithSeconds(item.Media.secondsBegin + durationInSeconds , item.Media.end.timescale);
        }
        //        [item parseCore:[videoBg_ copyAsCore]];
    }
    if(!item.Media || !item.Media.fileName || item.Media.fileName.length<2)
    {
        PP_RELEASE(item);
        return NO;
    }
    item.SecondsInArray = posSeconds;
    item.DurationInArray = durationInSeconds;
    
    item.Index = (int)actionList_.count;
    
    [actionList_ addObject:item];
    
    [self reindexAllActions];
    
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
            if(item.SecondsInArray <=seconds && item.DurationInArray + item.SecondsInArray >seconds)
            {
                retItem = item;
                break;
            }
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
#pragma mark - delegate

@end

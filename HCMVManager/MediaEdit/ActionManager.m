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
#import "MediaEditManager.h"
#import "VideoGenerater.h"
#import "mvconfig.h"

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

- (BOOL)addActionItem:(MediaAction *)action filePath:(NSString *)filePath
                   at:(CGFloat)posSeconds
             duration:(CGFloat)durationInSeconds;
{
    MediaActionDo * item = [MediaActionDo new];
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
        //        [item parseCore:[videoBg_ copyAsCore]];
    }
    if(!item.Media || !item.Media.fileName || item.Media.fileName.length<2)
    {
        PP_RELEASE(item);
        return NO;
    }
    [item fetchAsAction:action];
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
        [actionList_ removeObject:actionDo];
        [self reindexAllActions];
        return YES;
    }
    return NO;
}
#pragma mark - delegate

@end

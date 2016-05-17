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
                         reverseBG_ = [manager_ getMediaItem:[NSURL fileURLWithPath:filePathNew]];
                         reverseBG_.begin = CMTimeMakeWithSeconds(videoBg_.secondsDuration - videoBg_.secondsEnd,videoBg_.end.timescale);
                         reverseBG_.end = CMTimeMakeWithSeconds(videoBg_.secondsDuration - videoBg_.secondsBegin,videoBg_.begin.timescale);
                         
                         __strong ActionManager * strongSelf = weakSelf;
                         if(strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(ActionManager:reverseGenerated:)])
                         {
                             [strongSelf.delegate ActionManager:strongSelf reverseGenerated:reverseBG_];
                         }
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
- (CGFloat)getSecondsWithoutAction:(CGFloat)playerSeconds
{
    CGFloat secondsInFinal = 0;
    for (MediaWithAction * item in mediaList_) {
        if(item.finalDuration <=0) continue;
        if(playerSeconds >=secondsInFinal && playerSeconds < secondsInFinal + item.finalDuration)
        {
            return item.secondsInArray + (playerSeconds - secondsInFinal) * item.secondsDurationInArray /item.finalDuration;
        }
        else
        {
            secondsInFinal += item.finalDuration;
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
        //        if(durationInSeconds <=0)
        //        {
        //            durationInSeconds = item.DurationInSeconds;
        //        }
        //DurationInSecons为小于0时，表示长度未定，一般在长按按钮时发生
        if(durationInSeconds>0)
        {
            item.Media.end = CMTimeMakeWithSeconds(item.Media.secondsBegin + durationInSeconds , item.Media.end.timescale);
        }
        //        [item parseCore:[videoBg_ copyAsCore]];
    }
    if(!item.Media || !item.Media.fileName || item.Media.fileName.length<2)
    {
        PP_RELEASE(item);
        return nil;
    }
    item.SecondsInArray = posSeconds + action.ReverseSeconds;
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
    
    if(item.isOPCompleted)
    {
        [self reindexAllActions];
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

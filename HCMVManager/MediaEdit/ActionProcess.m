//
//  ActionProcess.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "ActionProcess.h"
#import "MediaItem.h"
#import "VideoGenerater.h"
#import "ActionManager.h"
#import "MediaActionDo.h"
#import "MediaWithAction.h"

@implementation ActionProcess
- (NSMutableArray *) processActions:(NSArray *)actions sources:(NSMutableArray *) sources
{
    if(!actions || !sources || actions.count==0 || sources.count==0) return sources;
    NSMutableArray * result = sources;
    for (MediaActionDo * action in actions) {
        result = [self processAction:action sources:result];
    }
    return result;
}
- (NSMutableArray *)processAction:(MediaActionDo *)actionDo sources:(NSMutableArray *)sources
{
    
    NSMutableArray * overlapList = [actionDo buildMaterialOverlaped:sources];
    NSMutableArray * materialList = [actionDo buildMaterialProcess:sources];
    if(!materialList || materialList.count==0)
    {
        return sources;
    }
    //检查插入的起点对像
    MediaWithAction * mediaToSplit = [overlapList firstObject];
    NSAssert(mediaToSplit, @"无法找到需要分割或移动的素材，数据有问题1");
    
    MediaWithAction * mediaToTail = [self splitMediaItemAtSeconds:overlapList
                                                        atSeconds:actionDo.SecondsInArray
                                                         duration:actionDo.DurationInArray
                                                          overlap:actionDo.IsOverlap];
    
    NSAssert(mediaToTail, @"无法找到需要分割或移动的素材，数据有问题2");
    
    //将数据插入到原队列中，并且将队列中对像的时间重新计算
    NSMutableArray * headList = [NSMutableArray new];
    NSMutableArray * tailList = [NSMutableArray new];
    BOOL isHead = YES;
    BOOL isTail = NO;
    
    CGFloat secondsInArray = 0;
    
    for (MediaWithAction * item in sources) {
        if(item==mediaToSplit)
        {
            [headList addObject:mediaToSplit];
            //这里不能用变速后的时长
            secondsInArray += mediaToSplit.secondsDurationInArray;// [self getDurationForAction:mediaToSplit];
            isHead = NO;
            //如果后一段就是从前而切出来的，则直接将其后的加入到队列中
            if(!mediaToTail || mediaToTail==mediaToSplit)
            {
                isTail = YES;
            }
        }
        else if(item == mediaToTail) //由于分割的部分已经加入到了materialList中，所以此处不要添加
        {
            //            [tailList addObject:mediaToTail];
            //secondsInArray += [self getDurationForAction:item];
            isTail = YES;
            isHead = NO;
        }
        
        if(isHead)
        {
            [headList addObject:item];
            secondsInArray += item.secondsDurationInArray;// [self getDurationForAction:item];
        }
        else if(isTail && item!=mediaToSplit)
        {
            //如果是覆盖，则不能将这些包含在其中的素材放到结果队列中
            if(actionDo.IsOverlap && [overlapList containsObject:item])
            {
                
            }
            else
            {
                [tailList addObject:item];
            }
            //secondsInArray += [self getDurationForAction:item];
        }
    }
    if(mediaToTail && mediaToTail != mediaToSplit)
    {
        [tailList insertObject:mediaToTail atIndex:0];
    }
    //插入新对像
    for (MediaWithAction * item in materialList) {
        item.timeInArray = CMTimeMakeWithSeconds(secondsInArray,item.timeInArray.timescale);
        [headList addObject:item];
        secondsInArray += item.secondsDurationInArray;// [self getDurationForAction:item];
    }
    
    //插入尾部的对像
    //    secondsInArray += durationChanged;
    for (MediaWithAction * item in tailList) {
        item.timeInArray = CMTimeMakeWithSeconds(secondsInArray,item.timeInArray.timescale);
        secondsInArray += item.secondsDurationInArray;// [self getDurationForAction:item];
    }
    currentDuration_ = secondsInArray;
    
    //重新构建完整的列表
    NSMutableArray * result = [NSMutableArray new];
    
    [result addObjectsFromArray:headList];
    [result addObjectsFromArray:tailList];
    
    headList = nil;
    tailList = nil;
    
    return result;
}

- (CGFloat)getDurationForAction:(MediaWithAction *)media
{
    MediaActionDo * item = [[ActionManager shareObject]getMediaActionDo:media.Action];
    item.Media = media;
    
    return [item getDurationInFinal:nil];
}
//从中间将一个媒体一分两段,并修改其各自时长，返回后半段的媒体
//1、如果不是覆盖，则取第一个对像，则直接切为两段即可
//2、如果是覆盖，则取最后一个对像，计算需要去除的量
//3、最后计算这些拆分对像的最终播放时长。
- (MediaWithAction *)splitMediaItemAtSeconds:(NSArray *)overlaps atSeconds:(CGFloat)seconds duration:(CGFloat)duration overlap:(BOOL)isOverlap
{
    MediaWithAction * media = nil;
    if(!isOverlap)
    {
        media = [overlaps firstObject];
    }
    else
    {
        media = [overlaps lastObject];
    }
    if(!media || seconds <0)
    {
        NSAssert(media, @"传入了不正确的参数 nil");
        return nil;
    }
    CGFloat beginChanged = seconds + duration - media.secondsInArray;
    UInt32 timeScale = MAX(media.begin.timescale,DEFAULT_TIMESCALE);
    
    if(fabs(seconds - media.secondsInArray)<0.1)
    {
        if(beginChanged>0)
        {
            media.begin = CMTimeMakeWithSeconds(media.secondsBegin + beginChanged,timeScale);
        }
        media.finalDuration = [self getFinalDurationForMedia:media];
        return media;
    }
    else if(seconds>media.secondsInArray && seconds < media.secondsInArray + media.secondsDurationInArray)
    {
        MediaWithAction * actionSecond = [media copyItem];
        actionSecond.finalDuration = -1;
        CGFloat endSeconds = media.secondsBegin + seconds - media.secondsInArray;
        CMTime endTime = CMTimeMakeWithSeconds(endSeconds, timeScale);
        media.end = endTime;
        
        media.finalDuration = [self getFinalDurationForMedia:media];
        
        actionSecond.begin = CMTimeMakeWithSeconds(actionSecond.secondsBegin+beginChanged, timeScale);
        actionSecond.timeInArray = CMTimeMakeWithSeconds(media.secondsInArray+seconds,timeScale);
        
        actionSecond.finalDuration = [self getFinalDurationForMedia:actionSecond];
        return actionSecond;
    }
    
    return nil;
}
#pragma mark - 获取受影响的素材队列：需要插入的，需要覆盖的
//获取要插入素材的队列中的素材
- (NSMutableArray *)getActionMediaies:(MediaActionDo *)action sources:(NSMutableArray *)sources
{
    MediaItemCore * item = action.Media;
    NSMutableArray * result = [NSMutableArray new];
    if(!item)
    {
        item = nil;
    }
    
    //指定了素材
    if(item)
    {
        MediaWithAction * media = [MediaWithAction new];
        [media fetchAsCore:item];
        media.Action = [(MediaAction *)action copyItem];
        
        //暂定4个，1 表示慢速 2 表示加速 3表示Rap 4表示倒放 0表示是一个模板类型的
        switch (action.ActionType) {
            case 1:
            {
                
            }
                break;
            case 2:
            {
                
            }
                break;
            case 3: //rap
            {
                
            }
                break;
            case 4: //reverse
            {
            }
                break;
                
            default: //模板类型，暂不支持。即二级类型
            {
                
            }
                break;
        }
        
    }
    
    return result;
}

//获取当前队列中的可能被分割的对像
//duration >0，则表示是覆盖，需要返回多个对像了
- (NSMutableArray *)getMediaItemAtSource:(CGFloat)seconds duration:(CGFloat)duration source:(NSArray *)source
{
    NSMutableArray * overlapList = [NSMutableArray new];
    
    for (MediaItem * item in source) {
        //第一个或跨界的
        if(item.secondsInArray <=seconds && item.secondsDurationInArray + item.secondsInArray > seconds)
        {
            [overlapList addObject:item];
        }
        //表示需要覆盖的
        else if(duration>0)
        {
            //被包含在这个区段中的
            if(item.secondsInArray > seconds && item.secondsDurationInArray + item.secondsInArray <= seconds+duration)
            {
                [overlapList addObject:item];
            }
            //有一部分在范围内，但尾部超过边界的
            else if (item.secondsInArray < seconds + duration && item.secondsInArray + item.secondsDurationInArray >= seconds +duration)
            {
                [overlapList addObject:item];
            }
        }
    }
    return overlapList;
}
- (CGFloat)getFinalDurationForMedia:(MediaWithAction *)media
{
    MediaActionDo * action = [[ActionManager shareObject]getMediaActionDo:media.Action];
    return [action getDurationFinal:media];
}
@end

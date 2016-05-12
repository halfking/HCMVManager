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

@implementation ActionProcess
- (NSMutableArray *) processActions:(NSArray *)actions sources:(NSMutableArray *) sources
{
    if(!actions || !sources || actions.count==0 || sources.count==0) return nil;
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
    NSAssert(!mediaToSplit, @"无法找到需要分割或移动的素材，数据有问题1");
    
    MediaWithAction * secondPharse = [self splitMediaItemAtSeconds:mediaToSplit atSeconds:actionDo.SecondsInArray];
    NSAssert(!secondPharse, @"无法找到需要分割或移动的素材，数据有问题2");
    
    [overlapList insertObject:secondPharse atIndex:0];
    
    //检查插入的终点对像
    MediaWithAction * mediaToTail = nil;
    if(overlapList.count>2)
    {
        mediaToTail = [overlapList lastObject];
        CGFloat durationChanged = [actionDo getDurationInFinal:sources];
        CGFloat durationForHeadItemSplit = [self getDurationForAction:secondPharse];
        MediaWithAction * tailSecond = [self splitMediaItemAtSeconds:mediaToTail
                                                           atSeconds:secondPharse.secondsInArray
                                        + durationForHeadItemSplit +durationChanged];
        
        //将分割的加入到需要插入的素材列表中
        if(tailSecond)
        {
            [materialList addObject:tailSecond];
        }
    }
    
//    CGFloat durationChanged = [self getDurationForActions:overlapList];
    
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
            secondsInArray += [self getDurationForAction:mediaToSplit];
            isHead = NO;
            //如果后一段就是从前而切出来的，则直接将其后的加入到队列中
            if(!mediaToTail || mediaToTail==mediaToSplit||mediaToTail == secondPharse)
            {
                isTail = YES;
            }
        }
        else if(isHead)
        {
            [headList addObject:item];
            secondsInArray += [self getDurationForAction:item];
        }
        else if(isTail)
        {
            [tailList addObject:item];
            //secondsInArray += [self getDurationForAction:item];
        }
        else if(item == mediaToTail) //由于分割的部分已经加入到了materialList中，所以此处不要添加
        {
//            [tailList addObject:mediaToTail];
            //secondsInArray += [self getDurationForAction:item];
            isTail = YES;
            isHead = NO;
        }
    }
    //插入新对像
    for (MediaWithAction * item in materialList) {
        item.timeInArray = CMTimeMakeWithSeconds(secondsInArray,item.timeInArray.timescale);
        [headList addObject:item];
        secondsInArray += [self getDurationForAction:item];
    }
    
    //插入尾部的对像
//    secondsInArray += durationChanged;
    for (MediaWithAction * item in tailList) {
        item.timeInArray = CMTimeMakeWithSeconds(secondsInArray,item.timeInArray.timescale);
        secondsInArray += [self getDurationForAction:item];
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
- (MediaWithAction *)splitMediaItemAtSeconds:(MediaWithAction *)media atSeconds:(CGFloat)seconds
{
    if(!media || seconds <0)
    {
        NSAssert(media, @"传入了不正确的参数 nil");
        return nil;
    }
    if(fabs(seconds - media.secondsInArray)<0.1)
    {
        return media;
    }
    else if(seconds>media.secondsInArray && seconds < media.secondsInArray + media.secondsDurationInArray)
    {
        MediaWithAction * actionSecond = [media copyItem];
        CMTime endTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(media.begin)+seconds - media.secondsInArray, MAX(media.begin.timescale,DEFAULT_TIMESCALE));
        media.end = endTime;
        
        actionSecond.begin = endTime;
        
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
@end

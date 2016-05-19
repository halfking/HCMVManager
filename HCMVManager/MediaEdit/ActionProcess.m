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
//- (NSMutableArray *) processActions:(NSArray *)actions sources:(NSMutableArray *) sources
//{
//    if(!actions || !sources || actions.count==0 || sources.count==0) return sources;
//    NSMutableArray * result = sources;
//    for (MediaActionDo * action in actions) {
//        result = [self processAction:action sources:result];
//        
//        MediaWithAction * item = [result lastObject];
//        
//        //当没有结束的动作加入时，则其Duration未知，导致计算终止，因为后面的所有动作都可能被覆盖
//        if(item && item.secondsDurationInArray >=0)
//        {
//        }
//        else
//        {
//            break;
//        }
//        
//    }
//    return result;
//}
//- (NSMutableArray *)processAction:(MediaActionDo *)actionDo
//                          sources:(NSMutableArray *)sources
//{
//    
//    NSMutableArray * overlapList = [actionDo buildMaterialOverlaped:sources];
//    NSMutableArray * materialList = [actionDo buildMaterialProcess:sources];
//    if(!materialList || materialList.count==0)
//    {
//        return sources;
//    }
//    //检查插入的起点对像
//    MediaWithAction * mediaToSplit = [overlapList firstObject];
//    NSAssert(mediaToSplit, @"无法找到需要分割或移动的素材，数据有问题1");
//    
//    MediaWithAction * mediaToTail = [self splitMediaItemAtSeconds:overlapList
//                                                        atSeconds:actionDo.SecondsInArray
//                                                         duration:actionDo.DurationInArray
//                                                          overlap:actionDo.IsOverlap];
//    
//    NSAssert(mediaToTail, @"无法找到需要分割或移动的素材，数据有问题2");
//    
//    //将数据插入到原队列中，并且将队列中对像的时间重新计算
//    NSMutableArray * headList = [NSMutableArray new];
//    NSMutableArray * tailList = [NSMutableArray new];
//    BOOL isHead = YES;
//    BOOL isTail = NO;
//    
//    CGFloat secondsInArray = 0;
//    
//    for (MediaWithAction * item in sources) {
//        if(item==mediaToSplit && item.secondsDurationInArray>0)
//        {
//            //如果起点刚好与新加的动作相同，在非覆盖模式下，此对像后移，但对像地址并没有发生变化，就会出现这种情况。
//            if(mediaToSplit == mediaToTail)
//            {
//                [tailList addObject:mediaToTail];
//            }
//            else
//            {
//                [headList addObject:mediaToSplit];
//                //这里不能用变速后的时长
//                secondsInArray += mediaToSplit.secondsDurationInArray;
//            }
//            isHead = NO;
//            
//            //如果后一段就是从前而切出来的，则直接将其后的加入到队列中
//            if(!mediaToTail || mediaToTail==mediaToSplit)
//            {
//                isTail = YES;
//            }
//            continue;
//        }
//        else if(item == mediaToTail) //由于分割的部分已经加入到了materialList中，所以此处不要添加
//        {
//            isTail = YES;
//            isHead = NO;
//        }
//        
//        if(isHead && item.secondsDurationInArray>0)
//        {
//            [headList addObject:item];
//            secondsInArray += item.secondsDurationInArray;
//        }
//        else if(isTail && item!=mediaToSplit && item.secondsDurationInArray>0)
//        {
//            //如果是覆盖，则不能将这些包含在其中的素材放到结果队列中
//            if(actionDo.IsOverlap && [overlapList containsObject:item])
//            {
//                
//            }
//            else
//            {
//                [tailList addObject:item];
//            }
//        }
//    }
//    if(mediaToTail && mediaToTail != mediaToSplit)
//    {
//        [tailList insertObject:mediaToTail atIndex:0];
//    }
//    //插入新对像
//    for (MediaWithAction * item in materialList) {
//        item.timeInArray = CMTimeMakeWithSeconds(secondsInArray,item.timeInArray.timescale);
//        
//        [headList addObject:item];
//        
//        secondsInArray += item.secondsDurationInArray;
//    }
//    
//    //插入尾部的对像
//    for (MediaWithAction * item in tailList) {
//        item.timeInArray = CMTimeMakeWithSeconds(secondsInArray,item.timeInArray.timescale);
//
//        secondsInArray += item.secondsDurationInArray;
//    }
//    currentDuration_ = secondsInArray;
//    
//    //重新构建完整的列表
//    NSMutableArray * result = [NSMutableArray new];
//    
//    [result addObjectsFromArray:headList];
//    [result addObjectsFromArray:tailList];
//    
//    headList = nil;
//    tailList = nil;
//    
//    return result;
//}
//
//- (CGFloat)getDurationForAction:(MediaWithAction *)media
//{
//    MediaActionDo * item = [[ActionManager shareObject]getMediaActionDo:media.Action];
//    item.Media = media;
//    
//    return [item getDurationInFinal:nil];
//}
////从中间将一个媒体一分两段,并修改其各自时长，返回后半段的媒体
////1、如果不是覆盖，则取第一个对像，则直接切为两段即可
////2、如果是覆盖，则取最后一个对像，计算需要去除的量
////3、最后计算这些拆分对像的最终播放时长。
////如果 duration <0 表示当前对像时长未确定，则后面的所有数据均无限后延。
//
//- (MediaWithAction *)splitMediaItemAtSeconds:(NSArray *)overlaps
//                                   atSeconds:(CGFloat)seconds
//                                    duration:(CGFloat)duration
//                                     overlap:(BOOL)isOverlap
//{
//    MediaWithAction * media = nil;
//    
//    
//    if(!overlaps ||overlaps.count==0 || seconds <0)
//    {
//        NSAssert(media, @"传入了不正确的参数 nil");
//        return nil;
//    }
//    
//    if(isOverlap) //如果是覆盖类型
//    {
//        media = [overlaps lastObject];
//    }
//    else
//    {
//        media = [overlaps firstObject];
//    }
//    
//    UInt32 timeScale = MAX(media.begin.timescale,DEFAULT_TIMESCALE);
//    
//    //从中间截断时
//    if(seconds>=media.secondsInArray && seconds < media.secondsInArray + media.secondsDurationInArray)
//    {
//        //创建后半部
//        MediaWithAction * actionSecond = [media copyItem];
//        actionSecond.durationInPlaying = -1;
//        
//        //重新计算前半部中超出的内容长度:素材有效内容起点 + 持续时长
//        CGFloat endSeconds = media.secondsBegin + seconds - media.secondsInArray; //如果起点在变化区域内:负值，否则为正值
//        CMTime endTime = CMTimeMakeWithSeconds(endSeconds, timeScale);
//        media.end = endTime;
//        media.durationInPlaying = [self getFinalDurationForMedia:media];
//        
//       
//        if(duration>=0) //当插入的素材有确定时长时
//        {
//            if(isOverlap)
//            {
//                actionSecond.begin = CMTimeMakeWithSeconds(media.secondsEnd +duration, timeScale);
//            }
//            else
//            {
//                actionSecond.begin = media.end;
//            }
//            actionSecond.timeInArray = CMTimeMakeWithSeconds(seconds + duration,timeScale);
//            actionSecond.durationInPlaying = [self getFinalDurationForMedia:actionSecond];
//        }
//        else //无确定时长时
//        {
//            actionSecond.begin = media.end;
//            actionSecond.timeInArray = CMTimeMakeWithSeconds(SECONDS_NOTVALID,timeScale);
//            actionSecond.durationInPlaying = 0;
//        }
//        return actionSecond;
//    }
//    else //如果是全部覆盖
//    {
//        if(isOverlap) //没有从中间截断，则需要全部弃用
//        {
//            media.end = media.begin;
//            media.durationInPlaying = 0;
//            return media;
//        }
//        else
//        {
//            if(duration>=0)
//            {
//                media.timeInArray = CMTimeMakeWithSeconds(seconds+duration,timeScale);
//            }
//            else
//            {
//                media.timeInArray = CMTimeMakeWithSeconds(SECONDS_NOTVALID,timeScale);
//            }
//        }
//    }
//    return nil;
//}
//#pragma mark - 获取受影响的素材队列：需要插入的，需要覆盖的
//
////获取当前队列中的可能被分割的对像
////duration >0，则表示是覆盖，需要返回多个对像了
//- (NSMutableArray *)getMediaItemAtSource:(CGFloat)seconds duration:(CGFloat)duration source:(NSArray *)source
//{
//    NSMutableArray * overlapList = [NSMutableArray new];
//    
//    for (MediaItem * item in source) {
//        //第一个或跨界的
//        if(item.secondsInArray <=seconds && item.secondsDurationInArray + item.secondsInArray > seconds)
//        {
//            [overlapList addObject:item];
//        }
//        //表示需要覆盖的
//        else if(duration>0)
//        {
//            //被包含在这个区段中的
//            if(item.secondsInArray > seconds && item.secondsDurationInArray + item.secondsInArray <= seconds+duration)
//            {
//                [overlapList addObject:item];
//            }
//            //有一部分在范围内，但尾部超过边界的
//            else if (item.secondsInArray < seconds + duration && item.secondsInArray + item.secondsDurationInArray >= seconds +duration)
//            {
//                [overlapList addObject:item];
//            }
//        }
//    }
//    return overlapList;
//}
//- (CGFloat)getFinalDurationForMedia:(MediaWithAction *)media
//{
//    MediaActionDo * action = [[ActionManager shareObject]getMediaActionDo:media.Action];
//    return [action getDurationInPlaying:media];
//}
@end

//
//  MediaActionForRAP.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/12.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "MediaActionForRAP.h"
#import "MediaActionDo.h"
#import "MediaWithAction.h"

@implementation MediaActionForRAP
- (id)init
{
    if(self =[super init])
    {
        self.IsOverlap = NO;
        self.IsReverse = NO;
    }
    return self;
}
- (NSMutableArray *) processAction:(NSMutableArray *)sources secondsEffected:(CGFloat)secondsEffected
{
    //    if(self.ActionType==SFast)
    //    {
    //        NSLog(@"fast...");
    //    }
    NSMutableArray * overlapList = [self buildMaterialOverlaped:sources];
    
    BOOL hasAction = NO;
    //校正，防止出现问题。
    if(self.DurationInArray >= 0)
    {
        for (MediaWithAction * aa in overlapList) {
            if(aa.Action.ActionType!=SNormal)
            {
                hasAction = YES;
                break;
            }
        }
        if(hasAction && self.ReverseSeconds <0)
        {
            self.SecondsInArray -= self.ReverseSeconds;
            self.ReverseSeconds = 0;
            overlapList = [self buildMaterialOverlaped:sources];
        }
    }
    NSMutableArray * materialList = [self buildMaterialProcess:sources];
    if(!materialList || materialList.count==0)
    {
        return sources;
    }
    if(overlapList.count==0)
    {
        NSLog(@"cannot find overlap items.");
        return sources;
    }
    else if(overlapList.count>1)
    {
        NSLog(@"overlaps:%d",(int)overlapList.count);
    }
    //检查插入的起点对像
    MediaWithAction * mediaToSplit = [overlapList firstObject];
    NSAssert(mediaToSplit, @"无法找到需要分割或移动的素材，数据有问题1");
    
    MediaWithAction * mediaToTail = [self splitMediaItemAtSeconds:overlapList
                                                        atSeconds:self.SecondsInArray
                                                             from:self.SecondsInArray - secondsEffected
                                                         duration:self.DurationInArray
                                                          overlap:self.IsOverlap];
    
    //后面的被拆分的Repeat元素无效
    MediaWithAction * mediaToRemove = nil;
    //    if(mediaToSplit.Action.ActionType==SRepeat && mediaToTail.Action.ActionType==SRepeat)
    //    {
    //        mediaToRemove = mediaToTail;
    //    }
    if(mediaToTail.Action.ActionType!=SNormal)
    {
        mediaToRemove = mediaToTail;
    }
    //    NSAssert(mediaToTail, @"无法找到需要分割或移动的素材，数据有问题2");
    //需要校正前一个的数据结尾是否正常，非IsOverLap的在分割时已经处理过了。
    if(mediaToSplit && mediaToSplit!=mediaToTail && self.IsOverlap)
    {
        //获取之前所有的对像的播放器时间影响
        CGFloat secondsChangedBefore = 0;
        for (MediaWithAction * ma in sources) {
            if(ma == mediaToSplit)
                break;
            secondsChangedBefore += ma.secondsChangedWithActionForPlayer;
        }
        //这里，当前对像的SeconsInArray 还没有处理
        if(mediaToSplit.secondsInArray + mediaToSplit.secondsDurationInArray > self.SecondsInArray + secondsChangedBefore)
        {
            CGFloat orgSecondsInDuration = mediaToSplit.secondsDurationInArray;
            
            mediaToSplit.end =
            CMTimeMakeWithSeconds(
                                  mediaToSplit.secondsEnd - (mediaToSplit.secondsInArray + mediaToSplit.secondsDurationInArray - self.SecondsInArray - secondsChangedBefore), mediaToSplit.end.timescale);
            
            CGFloat rate = mediaToSplit.secondsDurationInArray / orgSecondsInDuration;
            mediaToSplit.secondsChangedWithActionForPlayer *= rate;
            mediaToSplit.durationInPlaying *= rate;
        }
    }
    //将数据插入到原队列中，并且将队列中对像的时间重新计算
    NSMutableArray * headList = [NSMutableArray new];
    NSMutableArray * tailList = [NSMutableArray new];
    BOOL isHead = YES;
    BOOL isTail = NO;
    
    CGFloat secondsInArray = 0;
    
    for (MediaWithAction * item in sources) {
        if([materialList containsObject:item]) continue;
        if(item==mediaToSplit && (item.secondsDurationInArray>0||item.secondsInArrayNotConfirm))
        {
            //如果起点刚好与新加的动作相同，在非覆盖模式下，此对像后移，但对像地址并没有发生变化，就会出现这种情况。
            if(mediaToSplit == mediaToTail)
            {
                [tailList addObject:mediaToTail];
            }
            else
            {
                [headList addObject:mediaToSplit];
                //这里不能用变速后的时长
                secondsInArray += mediaToSplit.secondsDurationInArray;
            }
            isHead = NO;
            
            //如果后一段就是从前而切出来的，则直接将其后的加入到队列中
            if(!mediaToTail || mediaToTail==mediaToSplit || !self.IsOverlap)
            {
                isTail = YES;
            }
            continue;
        }
        else if(item == mediaToTail) //由于分割的部分已经加入到了materialList中，所以此处不要添加
        {
            isTail = YES;
            isHead = NO;
        }
        
        if(isHead && item.secondsDurationInArray>0)
        {
            [headList addObject:item];
            secondsInArray += item.secondsDurationInArray;
        }
        else if(isTail && item!=mediaToSplit && item!=mediaToRemove)
        {
            //如果是覆盖，则不能将这些包含在其中的素材放到结果队列中
            if(self.IsOverlap && [overlapList containsObject:item])
            {
                
            }
            else if(item.secondsInArrayNotConfirm ==NO && item.secondsDurationInArray<=0)
            {
                
            }
            else
            {
                [tailList addObject:item];
            }
        }
    }
    if(mediaToTail && mediaToTail != mediaToSplit && mediaToTail!=mediaToRemove)
    {
        [tailList insertObject:mediaToTail atIndex:0];
    }
    //    CGFloat lastMediaSeconds = 0;
    //插入新对像
    for (MediaWithAction * item in materialList) {
        item.timeInArray = CMTimeMakeWithSeconds(secondsInArray,item.timeInArray.timescale);
        
        [headList addObject:item];
        
        secondsInArray += item.secondsDurationInArray;
        item.durationInPlaying = item.secondsDurationInArray /item.playRate;
        
        item.secondsChangedWithActionForPlayer = [self secondsEffectPlayer:item.secondsDurationInArray];
        
    }
    
    
    //插入尾部的对像
    if(!self.isOPCompleted && tailList.count>0)  //如果是未完成的操作，则其后素材的位置只往后移1秒，因为还会有二次操作的
    {
        MediaWithAction * item = [tailList firstObject];
        secondsInArray = item.secondsInArray +1;
    }
    for (MediaWithAction * item in tailList) {
        if(mediaToRemove && item==mediaToRemove) continue;
        item.timeInArray = CMTimeMakeWithSeconds(secondsInArray,item.timeInArray.timescale);
        
        secondsInArray += item.secondsDurationInArray;
        
        //尚无法确认下一个素材的开始时间，因为当前操作未完成
        if(!self.isOPCompleted)
        {
            item.secondsInArrayNotConfirm = YES;
        }
        else
        {
            item.secondsInArrayNotConfirm = NO;
            item.durationInPlaying = item.secondsDurationInArray /item.playRate;
        }
    }
    
    //重新构建完整的列表
    NSMutableArray * result = [NSMutableArray new];
    
    [result addObjectsFromArray:headList];
    
    [result addObjectsFromArray:tailList];
    
    
    headList = nil;
    tailList = nil;
    
    return result;
}
- (NSMutableArray *)buildMaterialProcess:(NSArray *)sources
{
    if(materialList_ && materialList_.count>0) return materialList_;
    
    
    MediaItemCore * item = self.Media;
    
    if(!item || !item.fileName || item.fileName.length==0)
    {
        item = nil;
    }
    
    //指定了素材
    if(item)
    {
        MediaWithAction * media = [self toMediaWithAction:sources];
        
        media.timeInArray = CMTimeMakeWithSeconds(self.SecondsInArray,DEFAULT_TIMESCALE);
        materialList_ = [NSMutableArray arrayWithObject:media];
        media.durationInPlaying = [self getDurationInFinal:sources];
    }
    else //没有指定，则需要从当前队列中获取
    {
        materialList_ = [self getMateriasInterrect:self.SecondsInArray duration:self.DurationInArray sources:sources];
    }
    
    return materialList_;
    
}

- (CGFloat) getDurationInFinal:(NSArray *)sources
{
    if(!materialList_)
    {
        [self buildMaterialProcess:sources];
    }
    if(durationForFinal_>0) return durationForFinal_;
    
    durationForFinal_ = 0;
    for (MediaWithAction * media in materialList_) {
        
        CGFloat duration = 0;
        if(media.secondsDurationInArray>0)
        {
            duration = media.secondsDurationInArray /media.playRate;
        }
        else if(media.Action)
        {
            duration = media.Action.DurationInSeconds / media.Action.Rate;
        }
        durationForFinal_ += duration ; //重复3次
    }
    return durationForFinal_;
}
- (MediaWithAction *)toMediaWithAction:(NSArray *)sources
{
    MediaWithAction * result = [MediaWithAction new];
    [result fetchAsCore:self.Media];
    result.Action = [(MediaAction *)self copyItem];
    result.playRate = self.Rate;
    result.Action.DurationInSeconds = result.secondsDurationInArray;
    return result;
}
- (CGFloat)secondsEffectPlayer:(CGFloat)durationInArray
{
    //Rap可能导致播放器时长加
    if(durationInArray>0)
    {
        return durationInArray;
    }
    else
    {
        return 0;
    }
}
- (MediaActionDo *) copyItemDo
{
    MediaActionForRAP * item = [MediaActionForRAP new];
    item.MediaActionID =  self.MediaActionID;
    item.ActionTitle =  self.ActionTitle;
    item.ActionIcon = self.ActionIcon;
    item.ActionType = self.ActionType;
    item.SubActions = self.SubActions;
    item.Rate = self.Rate;
    item.ReverseSeconds =  self.ReverseSeconds;
    item.DurationInSeconds = self.DurationInSeconds;
    item.IsMutex = self.IsMutex;
    item.IsFilter = self.IsFilter;
    item.IsOverlap = self.IsOverlap;
    item.isOPCompleted = self.isOPCompleted;
    item.secondsBeginAdjust = self.secondsBeginAdjust;
    item.IsReverse = self.IsReverse;
    
    item.Index = self.Index;
    item.SecondsInArray = self.SecondsInArray;
    item.DurationInArray = self.DurationInArray;
    item.Media = [MediaItemCore new];
    [item.Media fetchAsCore:self.Media];
    
    return item;
}
@end

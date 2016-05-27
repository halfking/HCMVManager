//
//  MediaActionForReverse.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/12.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "MediaActionForReverse.h"
#import "MediaActionDo.h"
#import "MediaWithAction.h"

@implementation MediaActionForReverse
- (id)init
{
    if(self =[super init])
    {
        self.IsOverlap = NO;
        self.IsReverse = YES;
    }
    return self;
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
        
//        media.secondsInFinalArray = media.secondsInArray;
//        media.durationInFinalArray = media.secondsDurationInArray;

    }
    else //没有指定，则需要从当前队列中获取
    {
        materialList_ = [self getMateriasInterrect:self.SecondsInArray duration:self.DurationInArray sources:sources];
    }
    
    return materialList_;

}
//回溯需要检查前面的Media
- (NSMutableArray *)buildMaterialOverlaped:(NSArray *)sources
{
    return [super buildMaterialOverlaped:sources];
//    NSMutableArray * overlapList = [NSMutableArray new];
//    
//    CGFloat seconds = self.SecondsInArray;
//    CGFloat duration = self.DurationInSeconds;
//    for (MediaWithAction * item in sources) {
//        MediaWithAction * matchItem = nil;
//        //第一个或跨界的
//        if(item.secondsInArray <=seconds && item.secondsDurationInArray + item.secondsInArray > seconds)
//        {
//            matchItem = item;
//            
//        }
//        //表示需要覆盖的
//        else if(duration>0)
//        {
//            //被包含在这个区段中的
//            if(item.secondsInArray > seconds && item.secondsDurationInArray + item.secondsInArray <= seconds+duration)
//            {
//                matchItem = item;
//            }
//            //有一部分在范围内，但尾部超过边界的
//            else if (item.secondsInArray < seconds + duration && item.secondsInArray + item.secondsDurationInArray >= seconds +duration)
//            {
//                matchItem = item;
//            }
//            else if (item.secondsInArray > seconds +duration && overlapList.count==0 && item.secondsInArrayNotConfirm)
//            {
//                matchItem = item;
//            }
//        }
//        if(matchItem )
//        {
//            if(fabs(matchItem.secondsInArray - self.SecondsInArray)<0.01 && matchItem.Action.ActionType == self.ActionType)
//            {
//                NSLog(@"matched..same....");
//            }
//            else
//            {
//                [overlapList addObject:matchItem];
//            }
//        }
//    }
//    
//    return overlapList;
}
//回溯，影响的对像不一样
//reverse  secondsInArray = seconds   duration:duration
//right media: secondsInArray = seconds - duration duration = orgDuration + duration
//left media: no change.

- (NSMutableArray *) processAction:(NSMutableArray *)sources secondsEffected:(CGFloat)secondsEffected
{
    
    NSMutableArray * overlapList = [self buildMaterialOverlaped:sources];
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
    //检查插入的起点对像
    MediaWithAction * mediaToSplit = [overlapList firstObject];
    NSAssert(mediaToSplit, @"无法找到需要分割或移动的素材，数据有问题1");
    
    MediaWithAction * mediaToTail = [self splitMediaItemAtSeconds:overlapList
                                                        atSeconds:self.SecondsInArray
                                                             from:self.SecondsInArray - secondsEffected
                                                         duration:self.DurationInArray
                                                          overlap:self.IsOverlap];
    
    //    NSAssert(mediaToTail, @"无法找到需要分割或移动的素材，数据有问题2");
//    //需要校正前一个的数据结尾是否正常
//    //这种情况在这时好像不会发生
//    if(mediaToSplit && mediaToSplit!=mediaToTail && self.IsOverlap)
//    {
//        //获取之前所有的对像的播放器时间影响
//        CGFloat secondsChangedBefore = 0;
//        for (MediaWithAction * ma in sources) {
//            if(ma == mediaToSplit)
//                break;
//            secondsChangedBefore += ma.secondsChangedWithActionForPlayer;
//        }
//        //这里，当前对像的SeconsInArray 还没有处理
//        if(mediaToSplit.secondsInArray + mediaToSplit.secondsDurationInArray > self.SecondsInArray + secondsChangedBefore)
//        {
//            CGFloat orgSecondsInDuration = mediaToSplit.secondsDurationInArray;
//            
//            mediaToSplit.end =
//            CMTimeMakeWithSeconds(
//                                  mediaToSplit.secondsEnd - (mediaToSplit.secondsInArray + mediaToSplit.secondsDurationInArray - self.SecondsInArray - secondsChangedBefore), mediaToSplit.end.timescale);
//            
//            mediaToSplit.secondsChangedWithActionForPlayer *= mediaToSplit.secondsDurationInArray / orgSecondsInDuration;
//        }
//    }
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
            if(!mediaToTail || mediaToTail==mediaToSplit)
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
        else if(isTail && item!=mediaToSplit)
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
    if(mediaToTail && mediaToTail != mediaToSplit)
    {
        [tailList insertObject:mediaToTail atIndex:0];
    }
    //    CGFloat lastMediaSeconds = 0;
    //插入新对像
    for (MediaWithAction * item in materialList) {
        item.timeInArray = CMTimeMakeWithSeconds(secondsInArray,item.timeInArray.timescale);
        
        [headList addObject:item];
        
        item.durationInPlaying = item.secondsDurationInArray;
        
        item.secondsChangedWithActionForPlayer = [self secondsEffectPlayer:item.secondsDurationInArray];
        
        secondsInArray += item.secondsDurationInArray;
        
    }
    
    
    //插入尾部的对像
    if(!self.isOPCompleted && tailList.count>0)  //如果是未完成的操作，则其后素材的位置只往后移1秒，因为还会有二次操作的
    {
        MediaWithAction * item = [tailList firstObject];
        secondsInArray = item.secondsInArray +1;
    }
    for (MediaWithAction * item in tailList) {
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
//            item.begin = CMTimeMakeWithSeconds(MAX(item.secondsBegin - self.DurationInArray,0),item.begin.timescale);
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
        durationForFinal_ += duration * 2;
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
#pragma mark - split op
- (MediaWithAction *)splitMediaItemAtSeconds:(NSArray *)overlaps
                                   atSeconds:(CGFloat)seconds
                                        from:(CGFloat)mediaBeginSeconds
                                    duration:(CGFloat)duration
                                     overlap:(BOOL)isOverlap
{
    MediaWithAction * media = nil;
    
    
    if(!overlaps ||overlaps.count==0 || seconds <0)
    {
        NSAssert(media, @"传入了不正确的参数 nil");
        return nil;
    }
    media = [overlaps firstObject];
    
    UInt32 timeScale = MAX(media.begin.timescale,DEFAULT_TIMESCALE);
     CGFloat orgDuration = media.secondsDurationInArray;
    
    //从中间截断时
    //一般在动作刚开始时
    if(seconds>=media.secondsInArray && seconds < media.secondsInArray + media.secondsDurationInArray)
    {
        //创建后半部
        MediaWithAction * actionSecond = [media copyItem];
        actionSecond.durationInPlaying = -1;
        
        //重新计算前半部中超出的内容长度:素材有效内容起点 + 持续时长
        CGFloat endSeconds = media.secondsBegin + seconds - media.secondsInArray; //如果起点在变化区域内:负值，否则为正值
        CMTime endTime = CMTimeMakeWithSeconds(endSeconds, timeScale);
        media.end = endTime;
        media.durationInPlaying = [self getFinalDurationForMedia:media];
        
        if(orgDuration>0)
        {
            CGFloat rate = media.secondsDurationInArray/orgDuration;;
            media.secondsChangedWithActionForPlayer *=  rate;
//            media.durationInPlaying *= rate;
            
        }
        else
        {
            media.secondsChangedWithActionForPlayer = 0;
            media.durationInPlaying = 0;
        }
        
        
        if(duration>=0) //当插入的素材有确定时长时
        {
            NSLog(@" 2reverver item: %.4f  reverse duration:%.4f",media.secondsBegin,self.DurationInArray);
            //反转
            actionSecond.begin = CMTimeMakeWithSeconds(media.secondsEnd - duration, timeScale);
            actionSecond.timeInArray = CMTimeMakeWithSeconds(seconds + duration,timeScale);
            actionSecond.durationInPlaying = [self getFinalDurationForMedia:actionSecond];
            
            if(orgDuration>0)
            {
                CGFloat rate = actionSecond.secondsDurationInArray/orgDuration;;
                actionSecond.secondsChangedWithActionForPlayer *=  rate;
//                actionSecond.durationInPlaying *= rate;
                
            }
            else
            {
                actionSecond.secondsChangedWithActionForPlayer = 0;
                actionSecond.durationInPlaying = 0;
            }
        }
        else //无确定时长时
        {
            actionSecond.begin = media.end;
            actionSecond.timeInArray = CMTimeMakeWithSeconds(seconds,timeScale);
            actionSecond.durationInPlaying = 0;
            actionSecond.secondsInArrayNotConfirm = YES;
            actionSecond.secondsChangedWithActionForPlayer = 0;
        }
        return actionSecond;
    }
    else //如果是全部覆盖
    {
            if(duration>=0)
            {
                media.timeInArray = CMTimeMakeWithSeconds(MAX(seconds+ duration,0),timeScale);
                NSLog(@" reverver item: %.4f  reverse duration:%.4f",media.secondsBegin,self.DurationInArray);
                //反转
                media.begin = CMTimeMakeWithSeconds(mediaBeginSeconds - duration, timeScale);
                media.durationInPlaying = [self getFinalDurationForMedia:media];
                
                if(orgDuration>0)
                {
                    CGFloat rate = media.secondsDurationInArray/orgDuration;;
                    media.secondsChangedWithActionForPlayer *=  rate;
//                    media.durationInPlaying *= rate;
                    
                }
                else
                {
                    media.secondsChangedWithActionForPlayer = 0;
                    media.durationInPlaying = 0;
                }

            }
            else
            {
                media.timeInArray = CMTimeMakeWithSeconds(seconds+0.1,timeScale);
                media.secondsInArrayNotConfirm = YES;
            }
            return media;
    }
    return nil;
}
- (CGFloat)secondsEffectPlayer:(CGFloat)durationInArray
{
    //Rap可能导致播放器时长加两份
    if(durationInArray>0)
    {
        return durationInArray * 2;
    }
    else
    {
        return 0;
    }
}
- (MediaActionDo *) copyItemDo
{
    MediaActionForReverse * item = [MediaActionForReverse new];
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

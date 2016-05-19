//
//  MediaActionDo.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/12.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "MediaActionDo.h"
#import "MediaAction.h"
#import "MediaWithAction.h"
#import "ActionManager.h"

@implementation MediaActionDo
@synthesize Index,SecondsInArray,DurationInArray;
@synthesize Media;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"mediaactionsdo";
        self.KeyName = @"MediaActionID,Index";
        self.DurationInArray = -1;
    }
    return self;
}
#pragma mark - data
- (void)fetchAsAction:(MediaAction *)action
{
    self.MediaActionID = action.MediaActionID;
    self.ActionTitle = action.ActionTitle;
    self.ActionIcon = action.ActionIcon;
    self.ActionType = action.ActionType;//暂定4个，1 表示慢速 2 表示加速 3表示Rap 4表示倒放 0表示是一个模板类型的
    self.SubActions = action.SubActions;
    self.Rate = action.Rate;
    self.ReverseSeconds = action.ReverseSeconds;
    self.DurationInSeconds = action.DurationInSeconds;
    self.IsMutex = action.IsMutex;
    self.IsFilter = action.IsFilter;
}
- (void)setDurationInSeconds:(CGFloat)DurationInSecondsA
{
    [super setDurationInSeconds:DurationInSecondsA];
    if(self.Media)
    {
        if(DurationInSecondsA>=0)
            self.Media.end = CMTimeMakeWithSeconds(self.Media.secondsBegin + DurationInSecondsA, self.Media.begin.timescale);
        else
            self.Media.end = CMTimeMakeWithSeconds(self.Media.secondsDuration, self.Media.end.timescale);
    }
    if(self.MaterialList && self.MaterialList.count==1)
    {
        MediaWithAction * media = [self.MaterialList firstObject];
        if(DurationInSecondsA>=0)
            media.end = CMTimeMakeWithSeconds(media.secondsBegin + DurationInSecondsA, media.begin.timescale);
        else
            media.end = CMTimeMakeWithSeconds(media.secondsDuration, media.end.timescale);
    }
    else if(self.MaterialList && self.MaterialList.count>1)
    {
        NSLog(@"这种多个对像的情况没有处理。。。。");
    }
}
- (NSMutableArray *)get_MaterialList
{
    return materialList_;
}
- (CGFloat) getDurationInFinal:(NSArray *)sources
{
    NSAssert(NO, @"此函数需要在子类中实现，不能直接使用父类的函数。");
    return -1;
}
- (CGFloat) getDurationInPlaying:(MediaWithAction *)media
{
    if(!media||!media.fileName || media.fileName.length<2) return 0;
    
    if(media.playRate>0)
    {
        return media.secondsDurationInArray / media.playRate;
    }
    //保存原值
    NSMutableArray * tempArray = materialList_;
    CGFloat orgDuration = durationForFinal_;
    
    materialList_ = [NSMutableArray arrayWithObject:media];
    
    CGFloat duration =  [self getDurationInFinal:nil];
    //恢复原值
    materialList_ = tempArray;
    durationForFinal_ = orgDuration;
    return duration;
}
- (CGFloat) getDurationInFinalArray:(MediaWithAction *)media
{
    if(!media||!media.fileName || media.fileName.length<2) return -1;
    
    return media.secondsDurationInArray;
}
- (MediaWithAction *)toMediaWithAction:(NSArray *)sources
{
    NSAssert(NO, @"此函数需要在子类中实现，不能直接使用父类的函数。");
    return nil;
}
#pragma mark - do process
- (NSMutableArray *) processAction:(NSMutableArray *)sources
{
    NSMutableArray * overlapList = [self buildMaterialOverlaped:sources];
    NSMutableArray * materialList = [self buildMaterialProcess:sources];
    if(!materialList || materialList.count==0)
    {
        return sources;
    }
    //检查插入的起点对像
    MediaWithAction * mediaToSplit = [overlapList firstObject];
    NSAssert(mediaToSplit, @"无法找到需要分割或移动的素材，数据有问题1");
    
    MediaWithAction * mediaToTail = [self splitMediaItemAtSeconds:overlapList
                                                        atSeconds:self.SecondsInArray
                                                         duration:self.DurationInArray
                                                          overlap:self.IsOverlap];
    
   
    NSAssert(mediaToTail, @"无法找到需要分割或移动的素材，数据有问题2");
    
    //将数据插入到原队列中，并且将队列中对像的时间重新计算
    NSMutableArray * headList = [NSMutableArray new];
    NSMutableArray * tailList = [NSMutableArray new];
    BOOL isHead = YES;
    BOOL isTail = NO;
    
    CGFloat secondsInArray = 0;
    
    for (MediaWithAction * item in sources) {
        if(item==mediaToSplit && item.secondsDurationInArray>0)
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
        else if(isTail && item!=mediaToSplit && item.secondsDurationInArray>0)
        {
            //如果是覆盖，则不能将这些包含在其中的素材放到结果队列中
            if(self.IsOverlap && [overlapList containsObject:item])
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
        
        secondsInArray += item.secondsDurationInArray;
//        if(self.IsOverlap)
//            lastMediaSeconds = item.secondsEnd;
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
#pragma mark - split op
- (MediaWithAction *)splitMediaItemAtSeconds:(NSArray *)overlaps
                                   atSeconds:(CGFloat)seconds
                                    duration:(CGFloat)duration
                                     overlap:(BOOL)isOverlap
{
    MediaWithAction * media = nil;
    
    
    if(!overlaps ||overlaps.count==0 || seconds <0)
    {
        NSAssert(media, @"传入了不正确的参数 nil");
        return nil;
    }
    
    if(isOverlap) //如果是覆盖类型
    {
        media = [overlaps lastObject];
    }
    else
    {
        media = [overlaps firstObject];
    }
    
    UInt32 timeScale = MAX(media.begin.timescale,DEFAULT_TIMESCALE);
    
    //从中间截断时
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
        
        
        if(duration>=0) //当插入的素材有确定时长时
        {
            if(isOverlap)
            {
                actionSecond.begin = CMTimeMakeWithSeconds(media.secondsEnd +duration, timeScale);
            }
            else
            {
                actionSecond.begin = media.end;
            }
            actionSecond.timeInArray = CMTimeMakeWithSeconds(seconds + duration,timeScale);
            actionSecond.durationInPlaying = [self getFinalDurationForMedia:actionSecond];
        }
        else //无确定时长时
        {
            actionSecond.begin = media.end;
            actionSecond.timeInArray = CMTimeMakeWithSeconds(seconds +1,timeScale);
            actionSecond.durationInPlaying = 0;
            actionSecond.secondsInArrayNotConfirm = YES;
        }
        return actionSecond;
    }
    else //如果是全部覆盖
    {
        if(isOverlap) //没有从中间截断，则需要全部弃用
        {
            media.end = media.begin;
            media.durationInPlaying = 0;
            return media;
        }
        else
        {
            if(duration>=0)
            {
                media.timeInArray = CMTimeMakeWithSeconds(seconds+duration,timeScale);
            }
            else
            {
                media.timeInArray = CMTimeMakeWithSeconds(seconds +1,timeScale);
                media.secondsInArrayNotConfirm = YES;
            }
        }
    }
    return nil;
}
- (CGFloat) getFinalDurationForMedia:(MediaWithAction *)media
{
    MediaActionDo * action = [[ActionManager shareObject]getMediaActionDo:media.Action];
    return [action getDurationInPlaying:media];
}
- (NSMutableArray *)buildMaterialProcess:(NSArray *)sources
{
    NSAssert(NO, @"此函数需要在子类中实现，不能直接使用父类的函数。");
    return nil;
}

#pragma mark - overlap or interect
- (NSMutableArray *)getMateriasInterrect:(CGFloat)seconds duration:(CGFloat)duration sources:(NSArray *)sources
{
    NSMutableArray * overlapList = [NSMutableArray new];
    
    for (MediaWithAction * item in sources) {
        //左相交
        if(item.secondsInArray  <=seconds && item.secondsDurationInArray + item.secondsInArray > seconds)
        {
            MediaWithAction * newItem = [item copyItem];
            newItem.begin = CMTimeMakeWithSeconds(newItem.secondsBegin + seconds - item.secondsInArray, newItem.begin.timescale);
            [overlapList addObject:newItem];
        }
        //包含
        else if(item.secondsInArray > seconds && item.secondsInArray + item.secondsDurationInArray <= seconds + duration)
        {
            [overlapList addObject:item];
        }
        //右相交
        else if(item.secondsInArray < seconds + duration && item.secondsInArray + item.secondsDurationInArray >seconds +duration)
        {
            MediaWithAction * newItem = [item copyItem];
            newItem.end = CMTimeMakeWithSeconds(newItem.secondsEnd - (item.secondsInArray + item.secondsDurationInArray - seconds - duration), newItem.end.timescale);
            [overlapList addObject:newItem];
        }
    }
    return overlapList;
}
- (NSMutableArray *)buildMaterialOverlaped:(NSArray *)sources
{
    NSMutableArray * overlapList = [NSMutableArray new];
    
    CGFloat seconds = self.SecondsInArray;
    CGFloat duration = self.DurationInSeconds;
    for (MediaWithAction * item in sources) {
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

#pragma mark - dealloc
- (void)dealloc
{
    PP_RELEASE(Media);
    PP_SUPERDEALLOC;
}
@end
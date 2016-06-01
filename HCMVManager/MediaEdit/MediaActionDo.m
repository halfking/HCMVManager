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
    self.isOPCompleted = action.isOPCompleted;
    self.secondsBeginAdjust = action.secondsBeginAdjust;
    self.IsReverse = action.IsReverse;
    self.allowPlayerBeFaster = action.allowPlayerBeFaster;
    
}
- (MediaActionDo *) copyItemDo
{
    MediaActionDo * item = [MediaActionDo new];
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
    item.allowPlayerBeFaster = self.allowPlayerBeFaster;
    
    item.Index = self.Index;
    item.SecondsInArray = self.SecondsInArray;
    item.DurationInArray = self.DurationInArray;
    item.Media = [MediaItemCore new];
    [item.Media fetchAsCore:self.Media];
    
    return item;
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
        if(self.ActionType==SReverse)
        {
            [self ensureMediaDuration:DurationInSecondsA];
        }
        else
        {
            NSLog(@"这种多个对像的情况没有处理。。。。");
        }
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
    
    if(media.playRate!=0)
    {
        return fabs(media.secondsDurationInArray / media.playRate);
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
//检查对应的播放器时间在队列中的位置
//如果播放器时间不在本动作 范围内，则直接-1
- (CGFloat) getSecondsInArray:(CGFloat)playerSeconds
{
    if(self.Media.secondsBegin <=playerSeconds + SECONDS_ERRORRANGE
       && (self.Media.secondsEnd >= playerSeconds || self.DurationInArray <0) )
    {
        return self.Media.secondsInArray + playerSeconds - self.Media.secondsBegin;
    }
    else
    {
        return -1;
    }
}
- (BOOL) containSecondsInArray:(CGFloat)secondsInArray
{
    if(self.SecondsInArray - secondsInArray < 0 - self.secondsBeginAdjust + SECONDS_ERRORRANGE )
    {
        if(self.DurationInArray <0 ||
           (self.DurationInArray>=0 && self.DurationInArray + self.SecondsInArray - secondsInArray > SECONDS_ERRORRANGE - self.secondsBeginAdjust))
        {
            return YES;
        }
    }
    return NO;
}
- (MediaWithAction *)toMediaWithAction:(NSArray *)sources
{
    NSAssert(NO, @"此函数需要在子类中实现，不能直接使用父类的函数。");
    return nil;
}
#pragma mark - do process
- (NSMutableArray *) processAction:(NSMutableArray *)sources secondsEffected:(CGFloat)secondsEffected
{
    //    if(self.ActionType==SFast)
    //    {
    //        NSLog(@"fast...");
    //    }
    
    NSMutableArray * materialList = [self buildMaterialProcess:sources];
    if(!materialList || materialList.count==0)
    {
        return sources;
    }
    
    int insertIndex = 0;
    NSMutableArray * newSources = [self splitArrayForAction:sources insertIndex:&insertIndex];
    
    [self addMediaToArray:materialList sources:newSources insertIndex:insertIndex];
    
    self.SecondsInArray  = ((MediaWithAction *)[materialList firstObject]).secondsInArray;
    
    return newSources;
}
- (NSMutableArray *)ensureAction:(NSMutableArray *)sources durationInArray:(CGFloat)durationInArrayA
{
    NSMutableArray * materialList = [self buildMaterialProcess:sources];
    if(!materialList || materialList.count==0)
    {
        return sources;
    }
    [self ensureMediaDuration:durationInArrayA];
    [self addMediaToArray:materialList sources:sources insertIndex:-1];
    
    return sources;
}
- (void) ensureMediaDuration:(CGFloat)durationInArrayA
{
    NSArray * mediaList = materialList_;
    if(mediaList.count>0)
    {
        for (MediaWithAction * item in mediaList) {
            item.end = CMTimeMakeWithSeconds(item.secondsBegin + durationInArrayA, item.end.timescale);
        }
        MediaWithAction * firstItem = [mediaList lastObject];
        if(firstItem!=self.Media && self.Media)
        {
            self.Media.end = firstItem.end;
        }
    }
    else if(self.Media)
    {
        self.Media.end = CMTimeMakeWithSeconds(self.Media.secondsBegin + durationInArrayA, self.Media.end.timescale);
    }
    
    
}
#pragma mark - split op
//- (MediaWithAction *)splitMediaItemAtSeconds:(NSArray *)overlaps
//                                   atSeconds:(CGFloat)seconds
//                                        from:(CGFloat)mediaBeginSeconds
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
//    CGFloat orgDuration = media.secondsDurationInArray;
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
//        if(orgDuration>0)
//        {
//            CGFloat rate = media.secondsDurationInArray/orgDuration;;
//            media.secondsChangedWithActionForPlayer *=  rate;
//
//        }
//        else
//        {
//            media.secondsChangedWithActionForPlayer = 0;
//            media.durationInPlaying = 0;
//        }
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
//
//            if(orgDuration>0)
//            {
//                CGFloat rate = actionSecond.secondsDurationInArray/orgDuration;;
//                actionSecond.secondsChangedWithActionForPlayer *=  rate;
//            }
//            else
//            {
//                actionSecond.secondsChangedWithActionForPlayer = 0;
//                actionSecond.durationInPlaying = 0;
//            }
//        }
//        else //无确定时长时
//        {
//            actionSecond.begin = media.end;
//            actionSecond.timeInArray = CMTimeMakeWithSeconds(seconds +1,timeScale);
//            actionSecond.durationInPlaying = 0;
//            actionSecond.secondsInArrayNotConfirm = YES;
//            actionSecond.secondsChangedWithActionForPlayer = 0;
//            actionSecond.durationInPlaying = 0;
//        }
//        return actionSecond;
//    }
//    else //如果是全部覆盖
//    {
//        if(isOverlap)
//        {
//            if(media.secondsInArray >=seconds) //  根本没有覆盖，这在没有立即完成的Action，即开始Duration为-1的时候会出现
//            {
//                if(duration>=0)
//                {
//                    media.timeInArray = CMTimeMakeWithSeconds(seconds+duration,timeScale);
//                    if(media.secondsInArrayNotConfirm)
//                    {
//                        media.begin = CMTimeMakeWithSeconds(media.secondsBegin+duration,timeScale);
//                    }
//                    if(orgDuration>0)
//                    {
//                        CGFloat rate = media.secondsDurationInArray/orgDuration;;
//                        media.secondsChangedWithActionForPlayer *=  rate;
//                        media.durationInPlaying *= rate;
//
//                    }
//                    else
//                    {
//                        media.secondsChangedWithActionForPlayer = 0;
//                        media.durationInPlaying = 0;
//                    }
//                }
//                else
//                {
//                    media.timeInArray = CMTimeMakeWithSeconds(seconds+1,timeScale);
//                }
//            }
//            else //没有从中间截断，则需要全部弃用
//            {
//                media.end = media.begin;
//                media.durationInPlaying = 0;
//                media.secondsChangedWithActionForPlayer = 0;
//                media.durationInPlaying = 0;
//            }
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
//                media.timeInArray = CMTimeMakeWithSeconds(seconds +1,timeScale);
//                media.secondsInArrayNotConfirm = YES;
//            }
//            return media;
//        }
//    }
//    return nil;
//}
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
        if(duration<0)
        {
            if(item.secondsDurationInArray + item.secondsInArray > seconds)
            {
                MediaWithAction * newItem = [item copyItem];
                [overlapList addObject:newItem];
            }
        }
        else
        {
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
                MediaWithAction * newItem = [item copyItem];
                [overlapList addObject:newItem];
            }
            //右相交
            else if(item.secondsInArray < seconds + duration && item.secondsInArray + item.secondsDurationInArray >seconds +duration)
            {
                MediaWithAction * newItem = [item copyItem];
                newItem.end = CMTimeMakeWithSeconds(newItem.secondsEnd - (item.secondsInArray + item.secondsDurationInArray - seconds - duration), newItem.end.timescale);
                [overlapList addObject:newItem];
            }
        }
    }
    return overlapList;
}
//- (NSMutableArray *)buildMaterialOverlaped:(NSArray *)sources
//{
//    NSMutableArray * overlapList = [NSMutableArray new];
//
//    CGFloat seconds = self.SecondsInArray;
//    CGFloat duration = self.DurationInArray;
//    for (MediaWithAction * item in sources) {
//
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
//        else if(item.secondsInArray >= seconds)
//        {
//            matchItem = item;
//        }
//        if(matchItem )
//        {
//            if(matchItem.Action.MediaActionID == self.MediaActionID)
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
//}
#pragma mark - 新处理方法
//只管切分数据，不管是否要替换
- (NSMutableArray *)splitArrayForAction:(NSArray *)sources insertIndex:(int *)insertIndex
{
    NSMutableArray * newSources = [NSMutableArray new];
    
    CGFloat seconds = self.SecondsInArray;
    
    long matchIndex = sources.count;
    
    for (MediaWithAction * item in sources) {
        if(item.secondsInArray + item.secondsDurationInArray <=seconds)
        {
            [newSources addObject:item];
        }
        //第一个或跨界的
        else if(item.secondsInArray <=seconds && item.secondsDurationInArray + item.secondsInArray > seconds)
        {
            if(fabs(item.secondsInArray - seconds) < SECONDS_ERRORRANGE)
            {
                matchIndex = newSources.count;
                [newSources addObject:item];
            }
            //拆分
            else
            {
                MediaWithAction * secondItem =  [self splitMediaItem:item splitSecondsInArray:seconds];
                
                [newSources addObject:item];
                
                matchIndex = newSources.count;
                
                if(secondItem)
                {
                    [newSources addObject:secondItem];
                }
            }
        }
        else
        {
            [newSources addObject:item];
        }
    }
    if(insertIndex)
    {
        *insertIndex = (int)matchIndex;
    }
    return newSources;
}
- (MediaWithAction *)splitMediaItem:(MediaWithAction *)item splitSecondsInArray:(CGFloat)splitSecondsInArray
{
    //不在拆分范围
    if(item.secondsInArray - splitSecondsInArray >=SECONDS_ERRORRANGE
       ||
       item.secondsInArray + item.secondsDurationInArray < splitSecondsInArray + SECONDS_ERRORRANGE)
    {
        return nil;
    }
    
    CGFloat orgDuration = item.secondsDurationInArray;
    CGFloat orgEffect = item.secondsChangedWithActionForPlayer;
    
    MediaWithAction * secondItem = [item copyItem];
    secondItem.durationInPlaying = -1;
    
    //重新计算前半部中超出的内容长度:素材有效内容起点 + 持续时长
    CGFloat endSeconds = item.secondsBegin + splitSecondsInArray - item.secondsInArray; //如果起点在变化区域内:负值，否则为正值
    CMTime endTime = CMTimeMakeWithSeconds(endSeconds, item.end.timescale);
    item.end = endTime;
    
    item.durationInPlaying = [self getFinalDurationForMedia:item];
    if(orgDuration>0)
        item.secondsChangedWithActionForPlayer *= item.secondsDurationInArray/orgDuration;
    else
        item.secondsChangedWithActionForPlayer = 0;
    
    secondItem.begin = item.end;
    secondItem.timeInArray = CMTimeMakeWithSeconds(item.secondsInArray + item.secondsDurationInArray, secondItem.timeInArray.timescale);
    secondItem.durationInPlaying = [self getFinalDurationForMedia:secondItem];
    secondItem.secondsChangedWithActionForPlayer = orgEffect - item.secondsChangedWithActionForPlayer;
    
    return secondItem;
}
- (void)addMediaToArray:(NSArray*)items sources:(NSMutableArray *)sources insertIndex:(int)insertIndex
{
    CGFloat duration = self.DurationInArray;
    int newInsertIndex = insertIndex;
    if(insertIndex<0) //表示不需要添加，已经加入，则是Ensure过程
    {
        for (int i = (int)sources.count-1; i>=0; i--) {
            MediaWithAction * item  = sources[i];
            if(item.Action.MediaActionID == self.MediaActionID && fabs(item.secondsInArray -self.SecondsInArray)<SECONDS_ERRORRANGE)
            {
                insertIndex = i;
                break;
            }
        }
        newInsertIndex = insertIndex + (int)materialList_.count;
    }
    else
    {
        if(duration<0)
        {
            for(int i = insertIndex;i<(int)sources.count;i++)
            {
                MediaWithAction * item = sources[i];
                item.secondsInArrayNotConfirm = YES;
            }
        }
        for (MediaWithAction * item in items) {
            [sources insertObject:item atIndex:newInsertIndex];
            newInsertIndex ++;
        }
    }
    
    CGFloat secondsInArray = self.SecondsInArray;
    CGFloat secondsEndInArray = self.SecondsInArray + (duration>0?duration:SECONDS_NOEND);
    if(self.IsOverlap && duration>0) //确认数据变化
    {
        NSMutableArray * removeList = [NSMutableArray new];
        for (int i = newInsertIndex;i<(int)sources.count;i++) {
            MediaWithAction * item = sources[i];
            if(item.secondsInArray + item.secondsDurationInArray <= secondsInArray + SECONDS_ERRORRANGE)
            {
                [removeList insertObject:[NSNumber numberWithInt:i] atIndex:0];
                //                [removeList addObject:item];
            }
            else if(item.secondsInArray <= secondsEndInArray+ SECONDS_ERRORRANGE)
            {
                if(item.secondsInArray + item.secondsDurationInArray < secondsEndInArray+ SECONDS_ERRORRANGE)
                {
                    [removeList insertObject:[NSNumber numberWithInt:i] atIndex:0];
                }
                else
                {
                    MediaWithAction * secondItem = [self splitMediaItem:item splitSecondsInArray:secondsEndInArray];
                    [removeList insertObject:[NSNumber numberWithInt:i] atIndex:0];
                    if(secondItem)
                    {
                        [sources insertObject:secondItem atIndex:i+1];
                    }
                    break;
                }
            }
            else
            {
                break;
            }
        }
        for (NSNumber * num in removeList) {
            [sources removeObjectAtIndex:[num intValue]];
        }
        //        [sources removeObjectsInArray:removeList];
        PP_RELEASE(removeList);
    }
    
    if(duration>0)
    {
        [self ensureExistItemDuration:insertIndex  sources:sources];
    }
}
- (void)ensureExistItemDuration:(int)beginIndex sources:(NSMutableArray *)sources
{
    //更新后面的数据值
    int index = 0;
    CGFloat secondsInArray = 0;
    int newInsertIndex = beginIndex + (int)materialList_.count;
    
    for (MediaWithAction * item in sources) {
        if(index < beginIndex) //队列左边的
        {
            secondsInArray += item.secondsDurationInArray;
        }
        else if(index >= newInsertIndex) //队列右边的
        {
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
                item.durationInPlaying = fabs(item.secondsDurationInArray /item.playRate);
            }
        }
        else //新增的
        {
            item.timeInArray = CMTimeMakeWithSeconds(secondsInArray,item.timeInArray.timescale);
            secondsInArray += item.secondsDurationInArray;
            item.durationInPlaying = fabs(item.secondsDurationInArray /item.playRate);
            item.secondsChangedWithActionForPlayer = [self secondsEffectPlayer:item.secondsDurationInArray];
        }
        index ++;
    }
}
- (CGFloat) secondsEffectPlayer
{
    return [self secondsEffectPlayer:self.DurationInArray];
}
- (CGFloat) secondsEffectPlayer:(CGFloat)durationInArray
{
    return 0;
}
#pragma mark - dealloc
- (void)dealloc
{
    PP_RELEASE(Media);
    PP_SUPERDEALLOC;
}
@end
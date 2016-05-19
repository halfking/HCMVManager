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
        media.durationInFinalArray = media.secondsDurationInArray;
        media.durationInPlaying = [self getDurationInPlaying:media];
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
- (NSMutableArray *)buildMaterialProcess:(NSArray *)sources
{
    NSAssert(NO, @"此函数需要在子类中实现，不能直接使用父类的函数。");
    return nil;
}
//- (NSMutableArray *)buildMaterialOverlaped:(NSArray *)sources
//{
//    NSAssert(NO, @"此函数需要在子类中实现，不能直接使用父类的函数。");
//    return nil;
//}
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
//    
//    if(!materialList_)
//    {
//        if(sources)
//        {
//            [self buildMaterialProcess:sources];
//        }
//        else if(self.Media)
//        {
//            MediaWithAction * item = [self toMediaWithAction:sources];
//            materialList_ = [NSMutableArray arrayWithObject:item];
//        }
//    }
//    if(!isnan(durationForFinal_) && durationForFinal_>0) return durationForFinal_;
//    
//    durationForFinal_ = 0;
//    for (MediaWithAction * media in materialList_) {
//        
//        CGFloat duration = 0;
//        if(media.secondsDurationInArray>0)
//        {
//            duration = media.secondsDurationInArray;
//        }
//        else if(media.Action)
//        {
//            duration = media.Action.DurationInSeconds;
//            
//        }
//        durationForFinal_ += duration;
//    }
//    return durationForFinal_;
}
- (MediaWithAction *)toMediaWithAction:(NSArray *)sources
{
    NSAssert(NO, @"此函数需要在子类中实现，不能直接使用父类的函数。");
    return nil;
}
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
- (void)dealloc
{
    PP_RELEASE(Media);
    PP_SUPERDEALLOC;
}
@end
//
//  MediaActionForFast.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/12.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "MediaActionForFast.h"

@implementation MediaActionForFast
- (NSMutableArray *)buildMaterialProcess:(NSArray *)sources
{
    NSAssert(NO, @"此函数需要在子类中实现，不能直接使用父类的函数。");
    return nil;
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
        if(media.secondsDuration>0)
        {
            duration = media.secondsDuration /media.playRate;
        }
        else if(media.Action)
        {
            duration = media.Action.DurationInSeconds / media.Action.Rate;
            
        }
        durationForFinal_ += duration;
    }
    return durationForFinal_;
}
- (MediaWithAction *)toMediaWithAction:(NSArray *)sources
{
    MediaWithAction * result = [MediaWithAction new];
    [result fetchAsCore:self.Media];
    result.Action = [(MediaAction *)self copyItem];
    
    return result;
}
@end

//
//  MediaActionForSlow.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/12.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "MediaActionForSlow.h"

@implementation MediaActionForSlow
- (NSMutableArray *)buildMaterialProcess:(NSArray *)sources
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

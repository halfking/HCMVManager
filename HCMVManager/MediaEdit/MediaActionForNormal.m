//
//  MediaActionForNormal.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/12.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "MediaActionForNormal.h"
#import "MediaActionDo.h"
#import "MediaWithAction.h"

@implementation MediaActionForNormal
- (id)init
{
    if(self =[super init])
    {
        self.IsOverlap = NO;
    }
    return self;
}
- (NSMutableArray *)buildMaterialProcess:(NSArray *)sources
{
    if(!materialList_ || materialList_.count==0)
    {
        MediaWithAction * item = [self toMediaWithAction:sources];
        item.timeInArray = CMTimeMakeWithSeconds(self.SecondsInArray,DEFAULT_TIMESCALE);
        
        
        materialList_ = [NSMutableArray arrayWithObject:item];
        item.durationInPlaying = [self getDurationInFinal:sources];
        
//        item.secondsInFinalArray = item.secondsInArray;
//        item.durationInFinalArray = item.secondsDurationInArray;

// 可能多重调用，因此，注释
//        item.finalDuration = [self getDurationInFinal:sources];
    }
    return materialList_;
}

- (CGFloat) getDurationInFinal:(NSArray *)sources
{
    if(!sources && !materialList_ && !self.Media) return 0;

    if(!materialList_)
    {
        [self buildMaterialProcess:sources];
    }
    if(!isnan(durationForFinal_) && durationForFinal_>0) return durationForFinal_;
    
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
        durationForFinal_ += duration;
    }
    return durationForFinal_;
}
- (MediaWithAction *)toMediaWithAction:(NSArray *)sources
{
    if(!self.Media)
    {
        NSLog(@"没有可操作的media对像");
    }
    MediaWithAction * result = [MediaWithAction new];
    [result fetchAsCore:self.Media];
    result.Action = [(MediaAction *)self copyItem];
    
    result.playRate = self.Rate;
    
    result.Action.DurationInSeconds = result.secondsDurationInArray;
    
    
    return result;
}
- (MediaActionDo *) copyItemDo
{
    MediaActionForNormal * item = [MediaActionForNormal new];
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

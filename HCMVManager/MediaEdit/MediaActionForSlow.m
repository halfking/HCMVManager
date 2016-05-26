//
//  MediaActionForSlow.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/12.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "MediaActionForSlow.h"
#import "MediaActionDo.h"
#import "MediaWithAction.h"

@implementation MediaActionForSlow
- (id)init
{
    if(self =[super init])
    {
        self.IsOverlap = YES;
        self.IsReverse = NO;
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
        if(sources)
        {
            [self buildMaterialProcess:sources];
        }
        else if(self.Media)
        {
            MediaWithAction * item = [self toMediaWithAction:sources];
            materialList_ = [NSMutableArray arrayWithObject:item];
        }
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
    MediaWithAction * result = [MediaWithAction new];
    [result fetchAsCore:self.Media];
    result.Action = [(MediaAction *)self copyItem];
    result.playRate = self.Rate;
    result.Action.DurationInSeconds = result.secondsDurationInArray;
    return result;
}
@end

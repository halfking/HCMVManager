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
        
        media.secondsInFinalArray = media.secondsInArray;
        media.durationInFinalArray = media.secondsDurationInArray;

    }
    else //没有指定，则需要从当前队列中获取
    {
        materialList_ = [self getMateriasInterrect:self.SecondsInArray duration:self.DurationInSeconds sources:sources];
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
    return result;
}
@end

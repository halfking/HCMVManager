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
        self.allowPlayerBeFaster = YES;
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
    
    if(!item && sources && sources.count>0)
    {
        MediaWithAction * sourceItem = nil;
        for (MediaWithAction * mm in sources) {
            if(mm.Action.ActionType!=SReverse)
            {
                sourceItem = mm;
                break;
            }
        }
        MediaWithAction * tempItem = [[MediaWithAction alloc]init];
        [tempItem fetchAsCore:sourceItem];
        tempItem.Action = [self copyItem];
        self.Media = tempItem;
        item = tempItem;
    }
    
    //指定了素材
    if(item)
    {
        MediaWithAction * media = nil;//[self toMediaWithAction:sources];
        if([item isKindOfClass:[MediaWithAction class]])
            media = (MediaWithAction *)item;
        else
            media = [self toMediaWithAction:sources];
        
        media.timeInArray = CMTimeMakeWithSeconds(self.SecondsInArray,DEFAULT_TIMESCALE);
        materialList_ = [NSMutableArray arrayWithObject:media];
        media.durationInPlaying = [self getDurationInFinal:sources];
        self.Media = media;
    }
//    else //没有指定，则需要从当前队列中获取
//    {
//        materialList_ = [self getMateriasInterrect:self.SecondsInArray duration:self.DurationInArray sources:sources];
//        if(materialList_.count>0)
//        {
//            self.Media = [materialList_ objectAtIndex:0];
//        }
//    }
    
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
            duration = fabs(media.secondsDurationInArray /media.playRate);
        }
        else if(media.Action)
        {
            duration = fabs(media.Action.DurationInSeconds / media.Action.Rate);
            
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
- (MediaActionDo *) copyItemDo
{
    NSLog(@"action slow copy item");
    MediaActionForSlow * item = [MediaActionForSlow new];
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
@end

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
#import "ActionManager.h"

@implementation MediaActionForRAP
- (id)init
{
    if(self =[super init])
    {
        self.IsOverlap = NO;
        self.IsReverse = NO;
        self.allowPlayerBeFaster = NO;
    }
    return self;
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
    
    //检查其后的对像是否也为被拆分的Rap后一段，如果是，则移除
    if(sources.count> newInsertIndex && insertIndex>0)
    {
        MediaWithAction * nextMedia = [sources objectAtIndex:newInsertIndex];
        MediaWithAction * prevMedia = [sources objectAtIndex:insertIndex -1];
        if(nextMedia.Action.ActionType == SRepeat && prevMedia.Action.ActionType ==SRepeat
           && nextMedia.Action.MediaActionID == prevMedia.Action.MediaActionID)
        {
            [sources removeObject:nextMedia];
        }
        nextMedia = nil;
        if(sources.count>newInsertIndex)
        {
            nextMedia = [sources objectAtIndex:newInsertIndex];
        }
        //如果间隔小于1秒，则自动接上
        if(nextMedia && nextMedia.Action.ActionType == SNormal && nextMedia.secondsBegin - self.Media.secondsEnd <= 1)
        {
            nextMedia.begin = self.Media.end;
        }
    }
    
    if(duration>0)
    {
        [self ensureExistItemDuration:insertIndex  sources:sources];
    }
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
        
        MediaWithAction * media = nil;
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
        [self buildMaterialProcess:sources];
    }
    if(durationForFinal_>0) return durationForFinal_;
    
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
        durationForFinal_ += duration ; //重复3次
    }
    return durationForFinal_;
}
- (MediaWithAction *)toMediaWithAction:(NSArray *)sources
{
    MediaWithAction * result = [MediaWithAction new];
    [result fetchAsCore:self.Media];
    result.Action = [(MediaAction *)self copyItem];
    result.Action.allowPlayerBeFaster = NO;
    
    result.playRate = self.Rate;
    result.Action.DurationInSeconds = result.secondsDurationInArray;
    return result;
}
- (CGFloat)secondsEffectPlayer:(CGFloat)durationInArray
{
    //Rap可能导致播放器时长加
    if(durationInArray>0)
    {
        return durationInArray;
    }
    else
    {
        return 0;
    }
}
- (MediaActionDo *) copyItemDo
{
    NSLog(@"action rap copy item");
    MediaActionForRAP * item = [MediaActionForRAP new];
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

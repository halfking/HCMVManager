//
//  ActionManager(index).m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "ActionManager(index).h"
#import "MediaAction.h"
#import "MediaItem.h"
#import "MediaEditManager.h"
#import "MediaWithAction.h"

#import "ActionManager(player).h"

#import "ActionProcess.h"
#import "WTPlayerResource.h"

@implementation ActionManager(index)
#pragma mark - overlap manager
- (CGFloat) reindexAllActions
{
    @synchronized (self) {
        [mediaList_ removeAllObjects];
        secondsEffectPlayer_ = 0;
        
        NSAssert(videoBgAction_, @"必须先设置了源背景视频才能进行处理!");
        MediaWithAction * bgMedia = [videoBgAction_ copyItem];
        
        [mediaList_ addObject:bgMedia];
        mediaList_ = [self processActions:actionList_ sources:mediaList_];
        mediaList_ = [self combinateArrayItems:mediaList_];
        
        [self ActionManager:self doProcessOK:mediaList_ duration:durationForTarget_];
        
        if(self.needPlayerItem)
        {
            [self generatePlayerItem:mediaList_];
        }
        return durationForTarget_;
    }
}
- (NSMutableArray *) processActions:(NSArray *)actions sources:(NSMutableArray *) sources
{
    if(!actions || !sources || actions.count==0 || sources.count==0) return sources;
    NSMutableArray * result = sources;
    for (MediaActionDo * action in actions) {
        result = [action processAction:result secondsEffected:secondsEffectPlayer_];
        
        MediaWithAction * item = [result lastObject];
        
        //当没有结束的动作加入时，则其Duration未知，导致计算终止，因为后面的所有动作都可能被覆盖
        if(item && item.secondsDurationInArray >=0)
        {
        }
        else
        {
            break;
        }
        
    }
    durationForTarget_ = 0;
    for (MediaWithAction * action in result) {
        durationForTarget_ += action.durationInPlaying;
    }
    return result;
}
//执行最新的Action，最新的一般在最后
- (CGFloat) processNewActions
{
    MediaActionDo * action = [actionList_ lastObject];
    
    mediaList_ = [action processAction:mediaList_ secondsEffected:secondsEffectPlayer_];
    
    mediaList_ = [self combinateArrayItems:mediaList_];
    
    durationForTarget_ = 0;
    for (MediaWithAction * action in mediaList_) {
        durationForTarget_ += action.durationInPlaying;
    }
    
    return durationForTarget_;
}

//获取在此动作之前的已经存在的素材列表
- (NSArray *) getMediaBaseLine:(MediaActionDo *)action
{
    return mediaList_;
}
- (NSMutableArray *) combinateArrayItems:(NSMutableArray *)source
{
    NSMutableArray * targetSource = [NSMutableArray new];
    MediaWithAction * lastItem = nil;
    for (MediaWithAction * item in source) {
        if(lastItem
                && lastItem.Action.ActionType == item.Action.ActionType
                && [lastItem.fileName isEqualToString:item.fileName]==YES
                && fabs(lastItem.secondsEnd - item.secondsBegin) < SECONDS_ERRORRANGE 
                && lastItem.playRate == item.playRate)
        {
            lastItem.end = item.end;
        }
        else
        {
            [targetSource addObject:item];
            lastItem = item;
        }
    }
    return targetSource;
}
#pragma mark - export
- (BOOL) generateMV
{
//    if(![self needGenerateForOP])
//    {
//        return NO;
//    }
    if(isGenerating_) return NO;
    isGenerating_ = YES;
    //    //滤镜处理
    //    if(actionList_.count==0)
    //    {
    //        [self generateMVByFilter:currentFilterIndex_];
    //        return YES;
    //    }
    //动作 处理
    [self saveDraft];
    
    NSArray * actionMediaList = [self getMediaList];
    
    NSLog(@"-------------** generate begin **--------------------");
    NSLog(@"duration:%.2f",durationForTarget_);
    int index = 0;
    for (MediaWithAction * item in actionMediaList) {
        NSLog(@"%@",[item toString]);
        index ++;
    }
    NSLog(@"**--**--**--**--**--**--**--**--**--**--");
    
    VideoGenerater * vg = [[VideoGenerater alloc]init];
    [vg resetGenerateInfo];
    vg.waterMarkFile = CT_WATERMARKFILE;
    vg.mergeRate = 1;
    vg.volRampSeconds = 0;
    vg.compositeLyric = NO;
    vg.delegate = self;
    vg.TagID = 1;
    
    if(audioBg_ && audioBg_.fileName)
    {
        [vg setBgmUrl:audioBg_.url];
    }
    
    UIDeviceOrientation or = [[MediaEditManager shareObject]orientationFromDegree:videoBg_.degree];
    
    [vg setRenderSize:videoBg_.renderSize orientation:or withFontCamera:NO];
    
    [vg setTimeForMerge:0 end:-1];
    if(audioBg_)
    {
        [vg setTimeForAudioMerge:audioBg_.secondsBegin end:audioBg_.secondsEnd];
    }
    else
    {
        [vg setTimeForAudioMerge:0 end:-1];
    }
    
    
    //    [vg setBlock:^(VideoGenerater *queue, CGFloat progress) {
    //        NSLog(@"progress %f",progress);
    //    } ready:^(VideoGenerater *queue, AVPlayerItem *playerItem) {
    //        NSLog(@"playerItem Ready");
    //
    //    } completed:^(VideoGenerater *queue, NSURL *mvUrl, NSString *coverPath) {
    //        NSLog(@"generate completed.  %@",[mvUrl path]);
    //        NSString * fileName = [[HCFileManager manager]getFileNameByTicks:@"merge.mp4"];
    //        NSString * filePath = [[HCFileManager manager]localFileFullPath:fileName];
    //        [HCFileManager copyFile:[mvUrl path] target:filePath overwrite:YES];
    //
    //        [manager_ setBackMV:filePath begin:0 end:-1];
    //
    //        [manager_ removeActions];
    //
    //        [self hideIndicatorView];
    //
    //    } failure:^(VideoGenerater *queue, NSString *msg, NSError *error) {
    //        NSLog(@"generate failure:%@ error:%@",msg,[error localizedDescription]);
    ////        [self hideIndicatorView];
    //    }];
    
    BOOL ret = [self generateMediaListWithActions:actionMediaList complted:^(NSArray * mediaList)
                {
                    [vg generatePreviewAsset:mediaList
                                    bgVolume:audioVol_
                                  singVolume:videoVol_
                                  completion:^(BOOL finished)
                     {
                         [vg generateMVFile:mediaList retryCount:0];
                     }];
                }];
    if(!ret)
    {
        isGenerating_ = NO;
        NSLog(@"generate failure.");
    }
    return ret;
}
- (void) generatePlayerItem:(NSArray *)mediaList
{
    
}

//- (BOOL) generateThumnates:(CGSize)thumnateSize contentSize:(CGSize)contentSize
//{
//    
//    return NO;
//}
@end

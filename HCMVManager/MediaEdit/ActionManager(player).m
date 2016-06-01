//
//  ActionManager(player).m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/23.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "ActionManager(player).h"
#import <hccoren/base.h>
#import "MediaItem.h"
#import "MediaActionDo.h"
#import "MediaWithAction.h"

#import "CLFiltersClass.h"
#import "CLVideoAddFilter.h"
#import "ActionManager.h"
#import "ActionManager(index).h"

@implementation ActionManager(player)
- (HCPlayerSimple *) getPlayer
{
    return player_;
}
- (HCPlayerSimple *) getReversePlayer
{
    return reversePlayer_;
}
- (GPUImageView *) getFilterView
{
    return filterView_;
}
- (UIImage*) getFilteredIcon:(UIImage *)image index:(int)index
{
    if(index==0)
        return image;
    else
        return [CLFiltersClass imageAddFilter:image index:index];
}
- (NSArray *) getGPUFilters
{
    return [NSArray arrayWithObjects:
            @{@"title":@"原片",@"index":@(0)},
            @{@"title":@"现代",@"index":@(1)},
            @{@"title":@"日韩",@"index":@(2)},
            @{@"title":@"放克",@"index":@(3)},
            @{@"title":@"东部",@"index":@(4)},
            @{@"title":@"黑白",@"index":@(5)},
            @{@"title":@"西部",@"index":@(6)},
            @{@"title":@"老派",@"index":@(7)},
            nil];
}
- (int) getCurrentFilterIndex
{
    return currentFilterIndex_;
}
- (BOOL) initPlayer:(HCPlayerSimple *)player reversePlayer:(HCPlayerSimple *)reversePlayer audioPlayer:(AVAudioPlayer *)audioPlayer
{
    if(player_!=player)
    {
        player_ = player;
        [player_ setVideoVolume:videoVol_];
    }
    if(reversePlayer_!=reversePlayer)
    {
        reversePlayer_ = reversePlayer;
        [reversePlayer_ setVideoVolume:videoVol_];
    }
    
    audioPlayer_ = audioPlayer;
    if(audioPlayer_)
    {
        [audioPlayer_ setVolume:audioVol_];
    }
    return YES;
}
- (BOOL) initReversePlayer:(HCPlayerSimple *)reversePlayer
{
    if(reversePlayer_!=reversePlayer)
    {
        reversePlayer_ = reversePlayer;
        [reversePlayer_ setVideoVolume:videoVol_];
    }
    return YES;
}
- (BOOL) initAudioPlayer:(AVAudioPlayer *)audioPlayer
{
    if(audioPlayer_)
    {
        [audioPlayer_ pause];
        audioPlayer_ = nil;
    }
    audioPlayer_ = audioPlayer;
    if(audioPlayer_)
    {
        [audioPlayer_ setVolume:audioVol_];
    }
    return YES;
}
- (BOOL) initGPUFilter:(HCPlayerSimple *)player in:(UIView *)container
{
    if(!player && !player_)
    {
        NSLog(@"not found player.. initPlayer pls.");
        return NO;
    }
    if(!container)
    {
        NSLog(@"container cannot be nil");
        return NO;
    }
    
    [player_ pause];
    
    currentFilterIndex_ = 0;
    if(movieFile_)
    {
        [movieFile_ cancelProcessing];
        [movieFile_ removeAllTargets];
        movieFile_ = nil;
    }
    if(filters_)
    {
        [filters_ endProcessing];
        [filters_ removeAllTargets];
        filters_ = nil;
    }
    if(filterView_)
    {
        [filterView_ removeFromSuperview];
        filterView_ =nil;
    }
    
    AVAsset *aset = [AVAsset assetWithURL:videoBg_.url];
    AVAssetTrack *videoAssetTrack = [[aset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    filterView_ = [self buildFilterView:videoAssetTrack playerFrame:player_.frame];
    
    filterView_.center = player_.center;
    [container addSubview:filterView_];
    
    
    AVPlayerItem * item = [AVPlayerItem playerItemWithAsset:aset];
    [player_ changeCurrentPlayerItem:item];
    
    movieFile_ = [[GPUImageMovie alloc] initWithPlayerItem:item];
    movieFile_.runBenchmark = NO;
    movieFile_.playAtActualSpeed = NO;
    
    filters_ = [GPUImageFilter new];
    [filters_ addTarget:filterView_];
    
    [movieFile_ addTarget:filters_];
    
    [movieFile_ startProcessing];
    
    
    [container bringSubviewToFront:filterView_];
    
    
    //        [player_ play];
    
    
    return YES;
}
//当外部对像发生变化时，需要更新当前播放对像
- (BOOL)changeFilterPlayerItem
{
    if(movieFile_)
    {
        AVAsset *aset = [AVAsset assetWithURL:videoBg_.url];
        AVPlayerItem * item = [AVPlayerItem playerItemWithAsset:aset];
        [player_ changeCurrentPlayerItem:item];
        
        [movieFile_ endProcessing];
        [movieFile_ removeAllTargets];
        [filters_ endProcessing];
        [filters_ removeAllTargets];
        
        movieFile_ = [[GPUImageMovie alloc] initWithPlayerItem:item];
    }
    return YES;
}
- (BOOL) setGPUFilter:(int)index
{
    lastFilterIndex_ = currentFilterIndex_;
    //    [player_ pause];
    // 实时切换滤镜
    //    filters_ = [CLFiltersClass addVideoFilter:movieFile_ index:index];
    [CLFiltersClass addFilterLayer:movieFile_ filters:filters_ filterView:filterView_ index:index];
    //    [filters_ addTarget:filterView_];
    
    currentFilterIndex_ = index;
    
    //    [player_ play];
    
    return  YES;
}
- (void) removeGPUFilter
{
    if(movieFile_ || filterView_)
    {
        [movieFile_ endProcessing];
        
        [filters_ removeAllTargets];
        [movieFile_ removeAllTargets];
        
        [filters_ endProcessing];
        movieFile_ = nil;
        
        
        if(filterView_)
        {
            [filterView_ removeFromSuperview];
            filterView_ =nil;
        }
        
        filters_ = nil;
        currentFilterIndex_ = 0;
        
        //restore player
        CGFloat seconds = CMTimeGetSeconds([player_.playerItem currentTime]);
        [player_ changeCurrentItemUrl:videoBg_.url];
        [player_ seek:seconds accurate:YES];
        //        [player_ play];
        
    }
}
- (GPUImageView *) buildFilterView:(AVAssetTrack *) videoAssetTrack playerFrame:(CGRect)playerFrame
{
    GPUImageView * filterView = [GPUImageView new];
    if(!videoAssetTrack)
    {
        AVAsset *aset = [AVAsset assetWithURL:videoBg_.url];
        videoAssetTrack = [[aset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    }
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        NSLog(@"1 up");
        
        CGAffineTransform transformA = CGAffineTransformMakeRotation(M_PI/2);
        transform = CGAffineTransformConcat(transform, transformA);
        
        CGFloat scale = 1;
        CGSize originSize = videoAssetTrack.naturalSize;
        CGSize renderSize = playerFrame.size;
        
        scale  = MIN(renderSize.width/originSize.height , renderSize.height/originSize.width);
        
        if(scale!=1)
        {
            transform = CGAffineTransformScale(transform, scale, scale);
        }
        // transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(0, - frame.size.height));
        
        filterView.frame = CGRectMake(0, 0, originSize.width, originSize.height);
        
    }else if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        NSLog(@"2 updownset");
        CGAffineTransform transformA = CGAffineTransformMakeRotation(- M_PI/2);
        transform = CGAffineTransformConcat(transform, transformA);
        
        CGFloat scale = 1;
        CGSize originSize = videoAssetTrack.naturalSize;
        CGSize renderSize = playerFrame.size;
        
        scale  = MIN(renderSize.width/originSize.height , renderSize.height/originSize.width);
        
        if(scale!=1)
        {
            transform = CGAffineTransformScale(transform, scale, scale);
        }
        // transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(0, - frame.size.height));
        
        filterView.frame = CGRectMake(0, 0, originSize.width, originSize.height);
        
    }else if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
        NSLog(@"3 lanleft");
        CGSize originSize = videoAssetTrack.naturalSize;
        CGSize renderSize = playerFrame.size;
        
        CGFloat scale  = MIN(renderSize.width/originSize.width , renderSize.height/originSize.height);
        
        if(scale!=1)
        {
            transform = CGAffineTransformScale(transform, scale, scale);
        }
        filterView.frame = CGRectMake(0, 0, originSize.width, originSize.height);
        
    }else if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
        NSLog(@"4");
        CGSize originSize = videoAssetTrack.naturalSize;
        CGSize renderSize = playerFrame.size;
        
        CGAffineTransform transformA = CGAffineTransformMakeRotation(M_PI);
        transform = CGAffineTransformConcat(transform, transformA);
        
        CGFloat scale  = MIN(renderSize.width/originSize.width , renderSize.height/originSize.height);
        
        if(scale!=1)
        {
            transform = CGAffineTransformScale(transform, scale, scale);
        }
        
        filterView.frame = CGRectMake(0, 0, originSize.width, originSize.height);
        //        filterView_.frame = CGRectMake(0, 0, kScreenHeight, kScreenWidth);
    }
    [filterView setTransform:transform];
    
    return PP_AUTORELEASE(filterView);
}

- (BOOL) generateMVByFilter:(int)filterIndex
{
    BOOL isExists = NO;
    if(filterIndex==0)
    {
        NSLog(@"not need filter.");
        
        return NO;
    }
    for (NSDictionary * dic in [self getGPUFilters])
    {
        if([[dic objectForKey:@"index"]intValue]==filterIndex)
        {
            isExists = YES;
            break;
        }
    }
    if(!isExists)
    {
        NSLog(@"filter:%d not support.",filterIndex);
        return NO;
    }
    if(isGeneratingByFilter_)
    {
        NSLog(@"正在生成中，请稍后进入...");
        return NO;
    }
    isGeneratingByFilter_ = YES;
    
    CLVideoAddFilter *addFilter = [[CLVideoAddFilter alloc]init];
    currentFilterGen_ = addFilter;
    
    addFilter.delegate = self;
    NSString * targetPath = [NSString stringWithFormat:@"filter_%d.mp4",filterIndex];
    targetPath = [[HCFileManager manager]getFileNameByTicks:targetPath];
    targetPath = [[HCFileManager manager]tempFileFullPath:targetPath];
    [addFilter addVideoFilter:videoBg_.url tempVideoPath:targetPath index:filterIndex];
    lastFilterIndex_ = filterIndex;
    
    return YES;
}


#pragma mark - clvideo delegate
// 视频完成处理
- (void)didFinishVideoDeal:(NSURL *)videoUrl
{
    isGeneratingByFilter_ = NO;
    if(currentFilterGen_)
    {
        [currentFilterGen_ readyToRelease];
        currentFilterGen_ = nil;
    }
    NSLog(@"filter generate ok....%@",[videoUrl path]);
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:generateOK:cover:isFilter:)])
    {
        [self.delegate ActionManager:self generateOK:[videoUrl path] cover:nil isFilter:YES];
    }
    
}

// 滤镜处理进度
- (void)filterDealProgress:(CGFloat)progress
{
    NSLog(@"filter generating %.2f....",progress);
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:generateProgress:isFilter:)])
    {
        [self.delegate ActionManager:self generateProgress:progress isFilter:NO];
    }
}

// 操作中断
- (void)operationFailure:(NSString *)failure
{
    isGeneratingByFilter_ = NO;
    if(currentFilterGen_)
    {
        [currentFilterGen_ readyToRelease];
        currentFilterGen_ = nil;
    }
    NSLog(@"filter generate failure:%@",failure);
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:genreateFailure:isFilter:)])
    {
        NSError * error = [NSError errorWithDomain:@"com.seenvoice.maiba" code:-1008 userInfo:@{NSLocalizedDescriptionKey:failure}];
        [self.delegate ActionManager:self genreateFailure:error isFilter:YES];
    }
    
}
#pragma mark - delegates
//当播放器的内容需要发生改变时
- (void)ActionManager:(ActionManager *)manager play:(MediaActionDo *)action media:(MediaWithAction *)media seconds:(CGFloat)seconds
{
    //    if(!needSendPlayControl_) return ;
    
    MediaWithAction * mediaToPlay = media;
    
    currentMediaWithAction_ = media;
    if(!isGenerating_ || player_.playing)
    {
        //    NSLog(@"mediaToPlay:%@",[mediaToPlay toDicionary]);
        NSLog(@"action %d play:%@ (file:%.2f) inarray:%.2f end of file:%.2f",
              action.ActionType,
              [mediaToPlay.fileName lastPathComponent],mediaToPlay.secondsBegin,mediaToPlay.secondsInArray,mediaToPlay.secondsEnd);
//        if(mediaToPlay.Action.ActionType!=SReverse
//           || [mediaToPlay.fileName rangeOfString:@"reverse_"].location==NSNotFound)
//        {
            [reversePlayer_ pause];
            
            [player_ setRate:mediaToPlay.playRate];
            
            //            //防止跳动
            //            if(mediaToPlay.Action.ActionType==SReverse)
            //            {
            ////                //防止播到前面或后面跳动
            ////                CGFloat secondsBegin = [self getReverseVideo].secondsDuration - reversePlayer_.secondsPlaying;
            ////                CGFloat diff = mediaToPlay.secondsBegin - secondsBegin;
            ////                [player_ seek:MIN(mediaToPlay.secondsBegin,secondsBegin) accurate:YES];
            ////
            ////                if(audioPlayer_)
            ////                {
            ////                    audioPlayer_.currentTime = mediaToPlay.secondsInArray + (diff<0?diff:0);
            ////                }
            //                [player_ seek:mediaToPlay.secondsBegin accurate:YES];
            //                if(audioPlayer_)
            //                {
            //                    audioPlayer_.currentTime = mediaToPlay.secondsInArray;
            //                }
            //            }
            //            else
            if(mediaToPlay.Action.ActionType==SReverse || !mediaToPlay.Action.allowPlayerBeFaster || player_.secondsPlaying <mediaToPlay.secondsBegin)
            {
                [player_ seek:mediaToPlay.secondsBegin accurate:YES];
                if(audioPlayer_)
                {
                    audioPlayer_.currentTime = mediaToPlay.secondsInArray;
                }
            }
            
            NSLog(@"player seconds:%.2f item:%.2f audio:%.2f",player_.secondsPlaying,CMTimeGetSeconds(player_.playerItem.currentTime),
                  audioPlayer_? audioPlayer_.currentTime:-1);
            
            [player_ play];
            if(audioPlayer_)
            {
                if(mediaToPlay.playRate <0)
                    audioPlayer_.rate = mediaToPlay.playRate;
                else
                    audioPlayer_.rate = 1;
                [audioPlayer_ play];
            }
            player_.hidden = NO;
            reversePlayer_.hidden = YES;
            NSLog(@"mediaplay:%@ player:(%.2f)",mediaToPlay.fileName,player_.secondsPlaying);
//        }
//        else
//        {
//            [player_ pause];
//            [reversePlayer_ setRate:mediaToPlay.playRate];
//            
//            //防止播到前面或后面跳动
//            //            CGFloat secondsBegin = [self getReverseVideo].secondsDuration - player_.secondsPlaying;
//            //            [reversePlayer_ seek:MIN(mediaToPlay.secondsBegin,secondsBegin) accurate:YES];
//            [reversePlayer_ seek:mediaToPlay.secondsBegin accurate:YES];
//            [reversePlayer_ play];
//            if(audioPlayer_)
//            {
//                audioPlayer_.currentTime = mediaToPlay.secondsInArray;
//                [audioPlayer_ play];
//            }
//            NSLog(@"reversePlayer_ seconds:%.2f item:%.2f audio:%.2f",reversePlayer_.secondsPlaying,CMTimeGetSeconds(reversePlayer_.playerItem.currentTime),
//                  audioPlayer_? audioPlayer_.currentTime:-1);
//            reversePlayer_.hidden = NO;
//            player_.hidden = YES;
//        }
    }
    else
    {
        NSLog(@"genreateing ,mediaplay:%@ (%.2f) inarray:%.2f begin:%.2f",[mediaToPlay.fileName lastPathComponent],mediaToPlay.secondsBegin,mediaToPlay.secondsInArray,mediaToPlay.secondsBegin);
        
        NSLog(@"pause in play functions");
        [player_ pause];
        [reversePlayer_ pause];
        [audioPlayer_ pause];
    }
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:play:)])
        [self.delegate ActionManager:self play:mediaToPlay];
}
- (MediaWithAction *)findMediaByActionDo:(MediaActionDo *)action withSeconds:(CGFloat)secondsInArray
{
    MediaWithAction * mediaToPlay = nil;
    if(action)
    {
        //Repeat 是将前面1秒的记录为Repeat，然后，将后面的整体切为一段，所以这时候要指向下一个对像
        //时间无效，也应该指向下一个
        if(secondsInArray == SECONDS_NOTVALID || (secondsInArray == SECONDS_NOEND && action.ActionType ==SRepeat && action.ReverseSeconds))
        {
            if(action.ActionType==SReverse && action.DurationInArray>0)
            {
                mediaToPlay = [self findMediaWithAction:action index:0];
            }
            else
            {
                mediaToPlay = [self findMediaWithAction:action index:-1];
            }
        }
        else if(secondsInArray==SECONDS_NOEND)   //当前对像未结束
        {
            if(action.ActionType==SReverse)
            {
                if(action.DurationInArray >0)
                {
                    mediaToPlay = [self findMediaWithAction:action index:0];
                }
                else
                {
                    mediaToPlay = [self findMediaWithAction:action index:1];
                }
            }
            else
            {
                mediaToPlay = [self findMediaWithAction:action index:0];
            }
        }
        else
        {
            mediaToPlay = [self findMediaItemAt:action.SecondsInArray - action.secondsBeginAdjust];
        }
    }
    //    else
    //    {
    //        mediaToPlay = [self findMediaItemAt:secondsInArray];
    //    }
    return mediaToPlay;
}
- (void)setPlaySeconds:(CGFloat)playerSeconds isReverse:(BOOL)isReverse
{
    //到开始或结束时，或者允许触发时，才可以操作
    if(
//       playerSeconds>=SECONDS_ERRORRANGE
//       &&
//       playerSeconds <= videoBg_.secondsDuration - SECONDS_ERRORRANGE
//       &&
       !needSendPlayControl_)
        return ;
    //有动作未完成时，不接收时间的变化
    BOOL hasNotCompleted = NO;
    for (MediaActionDo * action in actionList_) {
        if(!action.isOPCompleted)
        {
            hasNotCompleted = YES;
            break;
        }
    }
    if(hasNotCompleted) return;
    
    //不需要更换
    //有时候播放器定位不准，因此在某种情况下，也不作处理
    if(currentMediaWithAction_)
    {
        if(currentMediaWithAction_.secondsBegin <=playerSeconds + 0.2 && currentMediaWithAction_.secondsEnd > playerSeconds)
        {
            return ;
        }
        else if(isReverse && currentMediaWithAction_.secondsEnd <=playerSeconds + 0.2 && currentMediaWithAction_.secondsBegin > playerSeconds)
        {
            return;
        }
        else if(playerSeconds + 1 < currentMediaWithAction_.secondsBegin)
        {
#ifndef __OPTIMIZE__
            [player_ pause];
            NSLog(@"??? %.2f <-- %.2f",playerSeconds,currentMediaWithAction_.secondsBegin);
#endif
        }
    }
    if(playerSeconds >= videoBg_.secondsDuration - SECONDS_ERRORRANGE) return;
    
    CGFloat secondsInArray = [self getSecondsInArrayViaCurrentState:playerSeconds];
    
#ifndef __OPTIMIZE__
    [player_ pause];
#endif
    MediaActionDo * itemDo = [self findActionAt:secondsInArray index:-1];
    MediaWithAction * media  = itemDo?[self findMediaByActionDo:itemDo withSeconds:SECONDS_NOEND]:nil;
    if(!media)
    {
        media = [self findMediaItemAt:secondsInArray];
    }
    
    if(currentMediaWithAction_ && media == currentMediaWithAction_)
    {
#ifndef __OPTIMIZE__
        [player_ play];
#endif
        return;
    }
    else
        currentMediaWithAction_ = media;
    
    [self ActionManager:self play:itemDo media:media seconds:secondsInArray];
}
- (void)ActionManager:(ActionManager *)manager actionChanged:(MediaActionDo *)action type:(int)opType//0 add 1 update 2 remove
{
    NSLog(@"action do changed:%@ pause",action.ActionTitle);
#ifndef __OPTIMIZE__
    [reversePlayer_ pause];
    [player_ pause];
    [audioPlayer_ pause];
#endif
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:actionChanged:type:)])
    {
        [self.delegate ActionManager:self actionChanged:action type:opType];
    }
}
- (void)ActionManager:(ActionManager *)manager doProcessOK:(NSArray *)mediaList duration:(CGFloat)duration
{
    //#ifndef __OPTIMIZE__
    //    NSLog(@"-------------**--actions ok--**--------------------");
    //    NSLog(@"duration:%.2f",duration);
    //    //    NSLog(@"** playerSeconds:7 track seconds:%.2f",[[ActionManager shareObject]getSecondsWithoutAction:7]);
    //    //    NSLog(@"** playerSeconds:10 track seconds:%.2f",[[ActionManager shareObject]getSecondsWithoutAction:10]);
    //    int index = 0;
    //    for (MediaWithAction * item in mediaList) {
    //        NSLog(@"--%d-- type:%d",index,item.Action.ActionType);
    //        NSLog(@"%@",[item toString]);
    //        index ++;
    //    }
    //    NSLog(@"**--**--**--**--**--**--**--**--**--**--");
    //#endif
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:doProcessOK:duration:)])
    {
        [self.delegate ActionManager:manager doProcessOK:mediaList duration:duration];
    }
    
}
- (void)ActionManager:(ActionManager *)manager playerItem:(AVPlayerItem *)playerItem duration:(CGFloat)duration
{
    NSLog(@"action playerItem ready");
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:playerItem:duration:)])
    {
        [self.delegate ActionManager:manager playerItem:playerItem duration:duration];
    }
}
@end

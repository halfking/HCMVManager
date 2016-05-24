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
    player_ = player;
    reversePlayer_ = reversePlayer;
    audioPlayer_ = audioPlayer;
    
    [player_ setVideoVolume:videoVol_];
    [reversePlayer_ setVideoVolume:videoVol_];
    if(audioPlayer_)
    {
        [audioPlayer_ setVolume:audioVol_];
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
    if(player)
    {
        player_ = player;
    }
    if(!player_)
    {
        NSLog(@"not found player.. initPlayer pls.");
        return NO;
    }
    currentFilterIndex_ = 0;
    if(!container)
    {
        container = player_.superview;
    }
    if(filterView_)
    {
        [filterView_ removeFromSuperview];
        filterView_ =nil;
    }
    if(movieFile_)
    {
        [movieFile_ endProcessing];
        movieFile_ = nil;
    }
    filters_ = nil;
    
    AVAsset *aset = [AVAsset assetWithURL:videoBg_.url];
    AVAssetTrack *videoAssetTrack = [[aset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGAffineTransform transform = CGAffineTransformIdentity;
    filterView_ = [GPUImageView new];
    
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        NSLog(@"1 up");
        
        CGAffineTransform transformA = CGAffineTransformMakeRotation(M_PI/2);
        transform = CGAffineTransformConcat(transform, transformA);
        
        CGFloat scale = 1;
        CGSize originSize = videoAssetTrack.naturalSize;
        CGSize renderSize = player_.frame.size;
        
        scale  = MIN(renderSize.width/originSize.height , renderSize.height/originSize.width);
        
        if(scale!=1)
        {
            transform = CGAffineTransformScale(transform, scale, scale);
        }
        // transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(0, - frame.size.height));
        
        filterView_.frame = CGRectMake(0, 0, originSize.width, originSize.height);
        
    }else if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        NSLog(@"2 updownset");
        CGAffineTransform transformA = CGAffineTransformMakeRotation(- M_PI/2);
        transform = CGAffineTransformConcat(transform, transformA);
        
        CGFloat scale = 1;
        CGSize originSize = videoAssetTrack.naturalSize;
        CGSize renderSize = player_.frame.size;
        
        scale  = MIN(renderSize.width/originSize.height , renderSize.height/originSize.width);
        
        if(scale!=1)
        {
            transform = CGAffineTransformScale(transform, scale, scale);
        }
        // transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(0, - frame.size.height));
        
        filterView_.frame = CGRectMake(0, 0, originSize.width, originSize.height);
        
    }else if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
        NSLog(@"3 lanleft");
        CGSize originSize = videoAssetTrack.naturalSize;
        CGSize renderSize = player_.frame.size;
        
        CGFloat scale  = MIN(renderSize.width/originSize.width , renderSize.height/originSize.height);
        
        if(scale!=1)
        {
            transform = CGAffineTransformScale(transform, scale, scale);
        }
        filterView_.frame = CGRectMake(0, 0, originSize.width, originSize.height);
        
    }else if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
        NSLog(@"4");
        CGSize originSize = videoAssetTrack.naturalSize;
        CGSize renderSize = player_.frame.size;
        
        CGAffineTransform transformA = CGAffineTransformMakeRotation(M_PI);
        transform = CGAffineTransformConcat(transform, transformA);
        
        CGFloat scale  = MIN(renderSize.width/originSize.width , renderSize.height/originSize.height);
        
        if(scale!=1)
        {
            transform = CGAffineTransformScale(transform, scale, scale);
        }
        
        filterView_.frame = CGRectMake(0, 0, originSize.width, originSize.height);
        //        filterView_.frame = CGRectMake(0, 0, kScreenHeight, kScreenWidth);
    }
    
    AVPlayerItem * item = [AVPlayerItem playerItemWithAsset:aset];
    [player_ changeCurrentPlayerItem:item];
    
    //    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];// 监听status属性
    
    movieFile_ = [[GPUImageMovie alloc] initWithPlayerItem:item];
    movieFile_.runBenchmark = YES;
    movieFile_.playAtActualSpeed = NO;
    
    GPUImageFilter *filt = [GPUImageFilter new];
    filters_ = filt;
    [movieFile_ addTarget:filters_];
    
    filterView_.center = player_.center;
    [container addSubview:filterView_];
    [container bringSubviewToFront:filterView_];
    [filterView_ setTransform:transform];
    
    [filters_ addTarget:filterView_];
    [movieFile_ startProcessing];
    
    //    [player_ play];
    return YES;
}
- (void) removeGPUFilter
{
    if(movieFile_ || filterView_)
    {
        [movieFile_ endProcessing];
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
        
    }
}
- (BOOL) setGPUFilter:(int)index
{
    // 实时切换滤镜
    [CLFiltersClass addFilterLayer:movieFile_ filters:filters_ filterView:filterView_ index:index];
    [player_ play];
    currentFilterIndex_ = index;
    return  YES;
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
    
    CLVideoAddFilter *addFilter = [[CLVideoAddFilter alloc]init];
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
    NSLog(@"filter generate failure:%@",failure);
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:genreateFailure:isFilter:)])
    {
        NSError * error = [NSError errorWithDomain:@"com.seenvoice.maiba" code:-1008 userInfo:@{NSLocalizedDescriptionKey:failure}];
        [self.delegate ActionManager:self genreateFailure:error isFilter:YES];
    }
}
#pragma mark - delegates
//当播放器的内容需要发生改变时
- (void)ActionManager:(ActionManager *)manager play:(MediaActionDo *)action seconds:(CGFloat)seconds
{
    if(!(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:play:)]))
    {
        return ;
    }
    MediaWithAction *  mediaToPlay = nil;
    //Repeat 是将前面1秒的记录为Repeat，然后，将后面的整体切为一段，所以这时候要指向下一个对像
    //时间无效，也应该指向下一个
    if(seconds == SECONDS_NOTVALID || (seconds == SECONDS_NOEND && action.ActionType ==SRepeat))
    {
        mediaToPlay = [self findMediaWithAction:action index:-1];
    }
    else if(seconds==SECONDS_NOEND)   //当前对像未结束
    {
        mediaToPlay = [self findMediaWithAction:action index:0];
    }
    else
    {
        mediaToPlay = [self findMediaItemAt:action.SecondsInArray - action.secondsBeginAdjust];
    }
    
//    MediaWithAction *  mediaToPlay = [self findMediaWithAction:action index:0];
//    
//    if(!mediaToPlay)
//    {
//        mediaToPlay = [self findMediaItemAt:action.SecondsInArray - action.secondsBeginAdjust];
//    }
    if(!mediaToPlay)
    {
#ifndef __OPTIMIZE__
        if(seconds == SECONDS_NOTVALID || (seconds == SECONDS_NOEND && action.ActionType ==SRepeat))
        {
            mediaToPlay = [self findMediaWithAction:action index:-1];
        }
        else if(seconds==SECONDS_NOEND)   //当前对像未结束
        {
            mediaToPlay = [self findMediaWithAction:action index:0];
        }
        else
        {
            mediaToPlay = [self findMediaItemAt:action.SecondsInArray - action.secondsBeginAdjust];
        }
#endif
        [self.delegate ActionManager:self play:nil];
        [player_ setRate:1];
        NSLog(@"mediaToPlay:nil");
        return ;
    }
    currentMediaWithAction_ = mediaToPlay;
    //    NSLog(@"mediaToPlay:%@",[mediaToPlay toDicionary]);
    if(mediaToPlay.Action.ActionType!=SReverse)
    {
        [reversePlayer_ pause];
        [player_ seek:mediaToPlay.secondsBegin accurate:YES];
        player_.hidden = NO;
        reversePlayer_.hidden = YES;
        //        [player_ currentLayer].opacity = 1;
        //        [reversePlayer_ currentLayer].opacity = 0;
        [player_ setRate:mediaToPlay.playRate];
        [player_ play];
        if(audioPlayer_)
        {
            audioPlayer_.currentTime = mediaToPlay.secondsInArray;
            [audioPlayer_ play];
        }
    }
    else
    {
        [player_ pause];
        [reversePlayer_ seek:mediaToPlay.secondsBegin accurate:YES];
        reversePlayer_.hidden = NO;
        player_.hidden = YES;
        //        [reversePlayer_ currentLayer].opacity = 1;
        //        [player_ currentLayer].opacity = 0;
        [reversePlayer_ setRate:mediaToPlay.playRate];
        [reversePlayer_ play];
        if(audioPlayer_)
        {
            audioPlayer_.currentTime = mediaToPlay.secondsInArray;
            [audioPlayer_ play];
        }
    }
    [self.delegate ActionManager:self play:mediaToPlay];
}
- (void)setPlaySeconds:(CGFloat)seconds
{
    if(!currentMediaWithAction_)
    {
        currentMediaWithAction_ = [self findMediaItemAt:seconds];
        return ;
    }
    //如果在有效范围内，不处理
    if(currentMediaWithAction_.secondsDurationInArray<0 || (seconds + secondsEffectPlayer_ < currentMediaWithAction_.secondsInArray + currentMediaWithAction_.secondsDurationInArray))
    {
        
    }
    //切换对像
    else
    {
        MediaActionDo * itemDo = [self findActionAt:seconds index:-1];
        [self ActionManager:self play:itemDo seconds:SECONDS_NOEND];
    }
}
- (void)ActionManager:(ActionManager *)manager actionChanged:(MediaActionDo *)action type:(int)opType//0 add 1 update 2 remove
{
    NSLog(@"action do changed:%@",action.ActionTitle);
    [reversePlayer_ pause];
    [player_ pause];
    [audioPlayer_ pause];
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:actionChanged:type:)])
    {
        [self.delegate ActionManager:self actionChanged:action type:opType];
    }
}
- (void)ActionManager:(ActionManager *)manager doProcessOK:(NSArray *)mediaList duration:(CGFloat)duration
{
#ifndef __OPTIMIZE__
    NSLog(@"-------------**--actions ok--**--------------------");
    NSLog(@"duration:%.2f",duration);
    //    NSLog(@"** playerSeconds:7 track seconds:%.2f",[[ActionManager shareObject]getSecondsWithoutAction:7]);
    //    NSLog(@"** playerSeconds:10 track seconds:%.2f",[[ActionManager shareObject]getSecondsWithoutAction:10]);
    int index = 0;
    for (MediaWithAction * item in mediaList) {
        NSLog(@"--%d-- type:%d",index,item.Action.ActionType);
        NSLog(@"%@",[item toString]);
        index ++;
    }
    NSLog(@"**--**--**--**--**--**--**--**--**--**--");
#endif
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

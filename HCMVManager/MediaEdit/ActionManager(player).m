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
//- (HCPlayerSimple *) getReversePlayer
//{
//    return reversePlayer_;
//}
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
- (BOOL) initPlayer:(HCPlayerSimple *)player  audioPlayer:(AVAudioPlayer *)audioPlayer
{
    if(player_!=player)
    {
        player_ = player;
        [player_ setVideoVolume:videoVol_];
    }
    //    if(reversePlayer_!=reversePlayer)
    //    {
    //        reversePlayer_ = reversePlayer;
    //        [reversePlayer_ setVideoVolume:videoVol_];
    //    }
    
    audioPlayer_ = audioPlayer;
    if(audioPlayer_)
    {
        [audioPlayer_ setVolume:audioVol_];
    }
    return YES;
}
//- (BOOL) initReversePlayer:(HCPlayerSimple *)reversePlayer
//{
//    if(reversePlayer_!=reversePlayer)
//    {
//        reversePlayer_ = reversePlayer;
//        [reversePlayer_ setVideoVolume:videoVol_];
//    }
//    return YES;
//}
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
#pragma mark - filter
- (void) setFilterIndex:(int)filterIndex
{
    currentFilterIndex_ = filterIndex;
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
    
    if(movieFile_)
    {
        [movieFile_ cancelProcessing];
        [movieFile_ removeAllTargets];
        [moveFileRemoveList_ addObject:movieFile_];
//        movieFileOrg_ = movieFile_;
        //        [gpuMoveFileList_ addObject:movieFile_];
        
        movieFile_ = nil;
    }
    if(filters_)
    {
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
    NSString * key = [CommonUtil md5Hash:videoBg_.url.absoluteString];
    
    player_.key = key;
    [player_ changeCurrentPlayerItem:item];
    
    movieFile_ = [[GPUImageMovie alloc] initWithPlayerItem:item];
    movieFile_.runBenchmark = NO;
    movieFile_.playAtActualSpeed = NO;
    movieFile_.delegate = self;
    filters_ = [GPUImageFilter new];
    [filters_ addTarget:filterView_];
    
    [movieFile_ addTarget:filters_];
    
    [movieFile_ startProcessing];
    
    [container bringSubviewToFront:filterView_];
    
    //            [player_ play];
    
    if(currentFilterIndex_>0)
    {
        [self setGPUFilter:currentFilterIndex_];
    }
    //    __weak ActionManager * weakSelf = self;
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //        [weakSelf releaseGPUFilterInstance:YES];
    //    });
    return YES;
}
- (void)releaseGPUFilterInstance:(BOOL)repeat
{
    
}
//当外部对像发生变化时，需要更新当前播放对像
- (BOOL)changeFilterPlayerItem
{
    if(movieFile_||filterView_)
    {
        [moveFileRemoveList_ addObject:movieFile_];
//        movieFileOrg_ = movieFile_;
        [movieFile_ cancelProcessing];
        
        //        if(filterView_)
        //        {
        //            [filterView_ removeFromSuperview];
        //            filterView_ = nil;
        //        }
        
        
        //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        AVAsset *aset = [AVAsset assetWithURL:videoBg_.url];
        AVAssetTrack * track = [[aset tracksWithMediaType:AVMediaTypeVideo]firstObject];
        AVPlayerItem * item = [AVPlayerItem playerItemWithAsset:aset];
        if(!filterView_)
        {
            filterView_ = [self buildFilterView:track playerFrame:player_.frame];
            filterView_.center = player_.center;
            [player_.superview addSubview:filterView_];
        }
        
        movieFile_ = [[GPUImageMovie alloc] initWithPlayerItem:item];
        movieFile_.delegate = self;
        
        NSString * key = [CommonUtil md5Hash:videoBg_.url.absoluteString];
        player_.key = key;
        [player_ changeCurrentPlayerItem:item];
        
        if(!filters_)
        {
            filters_ = [GPUImageFilter new];
        }
        [self setGPUFilter:currentFilterIndex_];
        
        [movieFile_ startProcessing];
        //        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            movieFileOrg_ = nil;
            [self removeMovieFileList];
        });
    }
    else if(player_)
    {
        
        NSString * key = [CommonUtil md5Hash:videoBg_.url.absoluteString];
        if(player_.key && [player_.key isEqualToString:key])
        {
            
        }
        else
        {
            player_.key = key;
            [player_ changeCurrentItemUrl:videoBg_.url];
        }
    }
    return YES;
}
- (void)removeMovieFileList
{
    if(moveFileRemoveList_ && moveFileRemoveList_.count>0)
    {
        [moveFileRemoveList_ removeObjectAtIndex:0];
    }
}
- (BOOL) setGPUFilter:(int)index
{
    if(!filterView_ || !filters_) return NO;
    
    lastFilterIndex_ = currentFilterIndex_;
    
    [CLFiltersClass addFilterLayer:movieFile_ filters:filters_ filterView:filterView_ index:index];
    
    currentFilterIndex_ = index;
    
    return  YES;
}
- (void) removeGPUFilter
{
    if(movieFile_ || filterView_)
    {
        [movieFile_ cancelProcessing];
        
        [moveFileRemoveList_ addObject:movieFile_];
//        movieFileOrg_ = movieFile_;
        //        [gpuMoveFileList_ addObject:movieFile_];
        
        [filters_ removeAllTargets];
        [movieFile_ removeAllTargets];
        
        
        movieFile_ = nil;
        filters_ = nil;
        
        if(filterView_)
        {
            [filterView_ removeFromSuperview];
            filterView_ =nil;
        }
        
        currentFilterIndex_ = 0;
        
        //restore player
        CGFloat seconds = CMTimeGetSeconds([player_.playerItem currentTime]);
        [player_ changeCurrentItemUrl:videoBg_.url];
        [player_ seek:seconds accurate:YES];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self removeMovieFileList];
//            movieFileOrg_ = nil;
        });
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
- (void)didCompletePlayingMovie
{
    NSLog(@"moviefile complted....");
}
#pragma mark - generateMVByFilter
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
        [self.delegate ActionManager:self generateProgress:progress isFilter:YES];
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
    [self setCurrentMediaWithAction:media];
    
    if(!isGenerating_ || player_.playing)
    {
        [player_ setRate:media.playRate];
        
        //为了防止播放进度跳动，需检查是否需要Seek到指定位置
        if(media.Action.ActionType==SReverse
           || !media.Action.allowPlayerBeFaster
           || player_.secondsPlaying <media.secondsBegin)
        {
            NSLog(@"通过Media 更改播放器的时间：%f",media.secondsBegin);
            //是否要禁用时间回调?
            needSendPlayControl_ = NO;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                needSendPlayControl_ = YES;
            });
            
            [player_ seek:media.secondsBegin accurate:YES];
            [self syncAudioPlayer:media playerSeconds:media.secondsBegin];
            
        }
        else
        {
            NSLog(@"AM : 通过Media 属性%d，没有更改播放器的时间：%f-->%f",media.Action.allowPlayerBeFaster,player_.secondsPlaying, media.secondsBegin);
            [self syncAudioPlayer:media playerSeconds:player_.secondsPlaying];
        }
        [player_ play];
        
        NSLog(@"AM : player seconds:%.4f item:%.4f audio:%.4f mediabegin:%.4f",player_.secondsPlaying,CMTimeGetSeconds(player_.playerItem.currentTime),
              audioPlayer_? audioPlayer_.currentTime:-1,media.secondsBegin);
    }
    else
    {
        NSLog(@"AM :  pause by GEN player seconds:%.4f item:%.4f audio:%.4f mediabegin:%.4f",player_.secondsPlaying,CMTimeGetSeconds(player_.playerItem.currentTime),
              audioPlayer_? audioPlayer_.currentTime:-1,media.secondsBegin);
        [player_ pause];
        //        [reversePlayer_ pause];
        [audioPlayer_ pause];
    }
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:play:)])
        [self.delegate ActionManager:self play:media];
}
- (void)syncAudioPlayer:(MediaWithAction *)media playerSeconds:(CGFloat)playerSeconds
{
    if(audioPlayer_ && audioBg_)
    {
        CGFloat secondsForAudio = media.secondsInArray + playerSeconds - media.secondsBegin  //secondsInArray
        - audioBg_.secondsInArray
        + audioBg_.secondsBegin;
        
        
        if(secondsForAudio <0)
        {
            audioPlayer_.currentTime = 0;
            [audioPlayer_ pause];
        }
        else
        {
            NSLog(@"AM : check audioPlayer:%.4f,seconds:%.4f rate:%f",audioPlayer_.currentTime,secondsForAudio,audioPlayer_.rate);
            //因为操作过程中视频可能要暂停，但音频不停，因此音频的播放时间应该在视频的前面，但是为了不产生中断感，设定一个参数来处理
            if(audioPlayer_.currentTime < secondsForAudio
               || fabs(audioPlayer_.currentTime - secondsForAudio) > self.secondsForAudioPlayerMaxRange)
            {
                audioPlayer_.currentTime = secondsForAudio;
            }
            if(!audioPlayer_.playing)
                [audioPlayer_ play];
        }
        NSLog(@"AM : audio player sync changed:%.2f = (%.2f + %.2f-%.2f +%.2f - %.2f)",
              audioPlayer_.currentTime,
              media.secondsInArray,
              audioBg_.secondsBegin,
              audioBg_.secondsInArray,
              playerSeconds,
              media.secondsBegin);
    }
    
}
- (void)checkAudioPlayerSync:(MediaWithAction *)media playerSeconds:(CGFloat)playerSeconds
{
    if(audioPlayer_)
    {
        if(audioPlayer_.playing==NO)
        {
            if(!media)
            {
                media = [mediaList_ lastObject];
            }
            [self syncAudioPlayer:media playerSeconds:playerSeconds];
        }
        //        else
        //        {
        //            //end
        //            CGFloat end = [player_ getSecondsEnd];
        //            if(end>0 && playerSeconds >= end - SECONDS_ERRORRANGE)
        //            {
        //                [audioPlayer_ pause];
        //                audioPlayer_.currentTime = 0;
        //            }
        //        }
    }
}
- (void) setPlayerReachEnd:(CGFloat)playerSeconds
{
    needSendPlayControl_ = NO;
    if(audioPlayer_ && audioPlayer_.playing)
    {
        [audioPlayer_ pause];
        if(audioBg_)
            audioPlayer_.currentTime = audioBg_.secondsBegin;
        else
            audioPlayer_.currentTime = 0;
    }
    [player_ seek:0 accurate:YES];
    needSendPlayControl_ = YES;
}
- (void)setPlaySeconds:(CGFloat)playerSeconds isReverse:(BOOL)isReverse
{
    if(playerSeconds>=0)
        [self checkAudioPlayerSync:currentMediaWithAction_ playerSeconds:playerSeconds];
    
    //到开始或结束时，或者允许触发时，才可以操作
    if(!needSendPlayControl_) return ;
    
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
    //反向与正向有些不同
    if(currentMediaWithAction_)
    {
        //误差处理是否需要?
        CGFloat minSeconds = currentMediaWithAction_.playRate <0?currentMediaWithAction_.secondsEnd:currentMediaWithAction_.secondsBegin;
        CGFloat maxSeconds = currentMediaWithAction_.playRate<0?currentMediaWithAction_.secondsBegin:currentMediaWithAction_.secondsEnd;
        
        CGFloat diff = MIN(SECONDS_ERRORRANGE *2,currentMediaWithAction_.secondsDurationInArray/2);
        BOOL needReturn = NO;
        if(minSeconds <=playerSeconds +diff && maxSeconds > playerSeconds)
        {
            needReturn = YES ;
        }
        else if(playerSeconds + 1 < minSeconds)
        {
#ifndef __OPTIMIZE__
            [player_ pause];
            NSLog(@"??? %.2f <-- %.2f",playerSeconds,minSeconds);
#endif
        }
        else if(playerSeconds < minSeconds)
        {
            if(currentMediaWithAction_.playRate >=0)
                needReturn = YES ;
            else
            {
                playerSeconds = minSeconds;
                needReturn = NO;
            }
        }
        if(needReturn)
        {
            //            [self checkAudioPlayerSync:currentMediaWithAction_ playerSeconds:playerSeconds];
            return ;
        }
    }
    else
    {
        //        [self checkAudioPlayerSync:currentMediaWithAction_ playerSeconds:playerSeconds];
    }
    
    //超过媒体最后时间
    if(playerSeconds >= videoBg_.secondsDurationInArray - SECONDS_ERRORRANGE)
    {
        [audioPlayer_ pause];
        audioPlayer_.currentTime = 0;
        return;
    }
    CGFloat secondsInArray = [self getSecondsInArrayViaCurrentState:playerSeconds];
    
    
    MediaWithAction * media = nil;
    if(secondsInArray <=playerSeconds + SECONDS_ERRORRANGE && currentMediaWithAction_)
    {
#ifndef __OPTIMIZE__
        NSLog(@"AM : 不可能的事情发生了，没有找到对应的播放时间");
        NSLog(@"AM : seconds:%.4f",playerSeconds);
        NSLog(@"AM : current:%@",currentMediaWithAction_);
        NSLog(@"AM : medialist:%@",mediaList_);
        
        //        secondsInArray =[self getSecondsInArrayViaCurrentState:playerSeconds];
        [player_ pause];
#endif
        //这里可能需要放最后一个Media可能才合适。
        
        media = [self findNextItem:currentMediaWithAction_];
        secondsInArray = media.secondsInArray;
    }
    else
    {
        //根据时间，寻找CurrentMedia之后的第一个匹配的素材
        media  =  [self getMediaActionViaSecondsInArray:secondsInArray afterMedia:currentMediaWithAction_];
        
        //奇怪的，没有变化，为什么会走到这里
        if(currentMediaWithAction_ && media == currentMediaWithAction_)
        {
#ifndef __OPTIMIZE__
            [player_ play];
#endif
            if(player_.playing==NO) [player_ play];
            return;
        }
    }
    [self ActionManager:self play:nil media:media seconds:secondsInArray];
    
}
- (MediaWithAction *)findNextItem:(MediaWithAction *)media
{
    BOOL isFind = NO;
    MediaWithAction * nextItem = nil;
    for (MediaWithAction * item  in mediaList_) {
        if(item == media)
        {
            isFind = YES;
        }
        else if(isFind)
        {
            nextItem = item;
            break;
        }
    }
    if(!nextItem)
    {
        if(media == [mediaList_ lastObject])
        {
            nextItem = [mediaList_ firstObject];
        }
        else
        {
            nextItem = [mediaList_ lastObject];
        }
    }
    return nextItem;
}
//根据时间，寻找CurrentMedia之后的第一个匹配的素材
- (MediaWithAction *) getMediaActionViaSecondsInArray:(CGFloat)secondsInArray afterMedia:(MediaWithAction *)currentMedia
{
    MediaWithAction * media  =  nil;
    
    BOOL isBegin = NO;
    MediaWithAction * prevMedia = nil;
    for (MediaWithAction * item in mediaList_) {
        if(item.secondsInArrayNotConfirm==YES) continue;
        if(!currentMedia || currentMedia == item)
        {
            isBegin = YES;
            prevMedia = item;
            continue;
        }
        if(isBegin)
        {
            if(item.secondsInArray - SECONDS_ERRORRANGE <= secondsInArray
               && (item.secondsDuration + item.secondsInArray > secondsInArray
                   || item.Action.isOPCompleted == NO)
               )
            {
                media = item;
                break;
            }
            else
            {
                prevMedia = item;
            }
        }
    }
    if(!media)
    {
        if(actionList_.count==0)
        {
            media = [mediaList_ firstObject];
        }
        else
        {
            NSLog(@"AM : 不可能的事情发生了，没有找到对应的Media");
            NSLog(@"AM : secondsInArray:%.4f",secondsInArray);
            NSLog(@"AM : medialist:%@",mediaList_);
//            media = [mediaList_ lastObject];
            media = [self findNextItem:currentMedia];
        }
    }
    return media;
}
- (void)ActionManager:(ActionManager *)manager actionChanged:(MediaActionDo *)action type:(int)opType//0 add 1 update 2 remove
{
    //    NSLog(@"action do changed:%@ pause",action.ActionTitle);
#ifndef __OPTIMIZE__
    //    [reversePlayer_ pause];
    [player_ pause];
    //    [audioPlayer_ pause];
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
    //    NSLog(@"action playerItem ready");
    if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:playerItem:duration:)])
    {
        [self.delegate ActionManager:manager playerItem:playerItem duration:duration];
    }
}
@end

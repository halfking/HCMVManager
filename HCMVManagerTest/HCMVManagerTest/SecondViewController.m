//
//  SecondViewController.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/10.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//


#import "SecondViewController.h"
#import <VideoToolbox/VideoToolbox.h>
#import "mvconfig.h"
#import "AVAssetReverseSession.h"
#import "MediaActionDo.h"
#import "VideoGenerater.h"
#import "ActionManager.h"
#import "MediaAction.h"
#import "WTPlayerResource.h"
#import <hccoren/base.h>
#import "HCPlayerSimple.h"
@interface SecondViewController ()<ActionManagerDelegate,WTPlayerResourceDelegate,HCPlayerSimpleDelegate>
@property (nonatomic, strong) AVAssetReverseSession *reverseSession;
@end

@implementation SecondViewController
{
    //preview
    UIButton * playBtn_;
    UIButton * pausebtn_;
    UIView * contentsView_;
    
    //progress
    UISlider * precent_;
    
    //menu
    UIView * firstList_;
    UIButton * splitBtn_;
    UIButton * filterBtn_;
    UIButton * insertVideoBtn_;
    UIButton * insertImgBtn_;
    UIView * secondList_;
    UIScrollView * splitScroll_;
    UIScrollView * filterScroll_;
    UIScrollView * videoRateScroll_;
    UIScrollView * imageTransScroll_;
    //testbtn
    UIButton * rate2x_;
    UIButton * rate1x_;
    UIButton * continueSeekBtn_;
    UIButton * fast_;
    UIButton * slow_;
    UIButton * joinBtn_;
    
    CGFloat seekTime_;
    NSTimer * continueSeekTimeTimer_;
    NSTimer *  repeatTimer_;
    int repeatCnt_;
    CMTime repeatTime_;
    
    HCPlayerSimple * player_;
    HCPlayerSimple * rPlayer_;
    

    NSString * oPath_;
    NSString * rPath_;
    
    ActionManager * manager_;
    
    MediaItem * reverseVideo_;
    MediaItem * baseVideo_;
    BOOL viewShowed_;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    manager_ = [ActionManager shareObject];
    manager_.delegate = self;
    [manager_ removeActions];
    
    oPath_ = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    viewShowed_ = NO;
    [manager_ setBackMV:oPath_ begin:0 end:-1];
    
    // Do any additional setup after loading the view, typically from a nib.
}
-(void)viewDidAppear:(BOOL)animated
{
    //[self layout];
    [self layoutNew];
}
-(void)layoutNew
{
    slow_ = [UIButton buttonWithType:UIButtonTypeCustom];
    [slow_ setFrame:CGRectMake(20, 450, 60, 30)];
    [slow_ setTitle:@"slow" forState:UIControlStateNormal];
    [slow_ setTitle:@"normal" forState:UIControlStateSelected];
    slow_.titleLabel.font = [UIFont systemFontOfSize:14];
    [slow_ setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:slow_];
    
    fast_ = [UIButton buttonWithType:UIButtonTypeCustom];
    [fast_ setFrame:CGRectMake(100, 450, 60, 30)];
    [fast_ setTitle:@"fast" forState:UIControlStateNormal];
    [fast_ setTitle:@"normal" forState:UIControlStateSelected];
    fast_.titleLabel.font = [UIFont systemFontOfSize:14];
    [fast_ setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:fast_];
    
    joinBtn_ = [UIButton buttonWithType:UIButtonTypeCustom];
    [joinBtn_ setFrame:CGRectMake(180, 450, 60, 30)];
    [joinBtn_ setTitle:@"join" forState:UIControlStateNormal];
    joinBtn_.titleLabel.font = [UIFont systemFontOfSize:14];
    [joinBtn_ setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:joinBtn_];
    
    [slow_ addTarget:self action:@selector(slow:) forControlEvents:UIControlEventTouchUpInside];
    [fast_ addTarget:self action:@selector(fast:) forControlEvents:UIControlEventTouchUpInside];
    [joinBtn_ addTarget:self action:@selector(join:) forControlEvents:UIControlEventTouchUpInside];
    
    rate1x_ = [UIButton buttonWithType:UIButtonTypeCustom];
    [rate1x_ setFrame:CGRectMake(20, 400, 60, 30)];
    [rate1x_ setTitle:@"repeat" forState:UIControlStateNormal];
    rate1x_.titleLabel.font = [UIFont systemFontOfSize:14];
    [rate1x_ setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:rate1x_];
    rate2x_ = [UIButton buttonWithType:UIButtonTypeCustom];
    [rate2x_ setFrame:CGRectMake(100, 400, 60, 30)];
    [rate2x_ setTitle:@"reverse" forState:UIControlStateNormal];
    [rate2x_ setTitle:@"origin" forState:UIControlStateSelected];
    rate2x_.titleLabel.font = [UIFont systemFontOfSize:14];
    [rate2x_ setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:rate2x_];
    [rate1x_ addTarget:self action:@selector(repeat:) forControlEvents:UIControlEventTouchUpInside];
    [rate2x_ addTarget:self action:@selector(reverseStart:) forControlEvents:UIControlEventTouchUpInside];
    
    repeatTime_ = kCMTimeZero;
    
    if(!viewShowed_)
    {
        if(baseVideo_)
        {
            [self buildPlayer];
        }
        if(reverseVideo_)
        {
            [self buildReversePlayer];
        }
    }
    viewShowed_ = YES;
}
#pragma mark - buildPlayer
- (void) buildPlayer
{
    if(!baseVideo_)
    {
        NSLog(@"no base item");
        return;
    }
    AVAsset * asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:baseVideo_.filePath]];
    AVPlayerItem * item = [AVPlayerItem playerItemWithAsset:asset];
    
    player_ = [[HCPlayerSimple alloc]initWithFrame:CGRectMake(0, 0, 414, 414.0 /16 * 9)];
    [player_ changeCurrentPlayerItem:item];
    player_.delegate = self;
    [self.view.layer addSublayer:[player_ currentLayer]];
    [player_ play];
}
- (void) buildReversePlayer
{
    if(!reverseVideo_)
    {
        NSLog(@"no reverse item");
        return;
    }
    AVAsset * asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:reverseVideo_.filePath]];
    AVPlayerItem * item = [AVPlayerItem playerItemWithAsset:asset];
    rPlayer_ = [[HCPlayerSimple alloc]initWithFrame:CGRectMake(0, 0, 414, 414.0 /16 * 9)];
    [rPlayer_ changeCurrentPlayerItem:item];
    rPlayer_.delegate = self;
    AVPlayerLayer * playerLayer = [rPlayer_ currentLayer];
    
    playerLayer.opacity = 0;
    [self.view.layer addSublayer:playerLayer];
}
#pragma mark - button events
-(void)repeat:(UIButton *)sender
{
    [repeatTimer_ invalidate];
    repeatTimer_ = nil;
    if (repeatCnt_ > 2) {
        repeatCnt_ = 0;
        repeatTime_ = kCMTimeZero;
        return;
    }

    if (CMTimeGetSeconds(repeatTime_) == 0) {
        repeatTime_ = player_.playerItem.currentTime;
        NSLog(@"dot time = %.3f", CMTimeGetSeconds(repeatTime_));
        //记录这个repeat的时间点(repeat片段的终点)
        CGFloat secondsPlaying = CMTimeGetSeconds(repeatTime_);
        MediaAction * action = [MediaAction new];
        action.ActionType = SRepeat;
        action.ReverseSeconds = 0 - RepeatTime;
        action.DurationInSeconds = RepeatTime;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.isOPCompleted = YES;
        
        [manager_ addActionItem:action filePath:nil at:secondsPlaying duration:-1];
        
    }
    
    
}
-(void)reverseStart:(UIButton *)sender
{
    CMTime playerTime =  [player_.playerItem currentTime];
    CGFloat seconds = CMTimeGetSeconds(playerTime);
    
    CMTime reverSeconds = [rPlayer_.playerItem currentTime];
    CMTime reverDuration = [rPlayer_.playerItem duration];
    
    
    if (!sender.selected) {
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        action.ReverseSeconds = 0;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.isOPCompleted = NO;
        if([manager_ addActionItem:action filePath:nil at:seconds duration:-1])
        {
            sender.selected = YES;
        }
        
    } else {
        sender.selected = NO;
        MediaActionDo * actionDo = [manager_ findActionAt:seconds - 0.1 index:-1];
        if(actionDo)
        {
            CGFloat duration = CMTimeGetSeconds(reverDuration)-CMTimeGetSeconds(reverSeconds);
            seconds = seconds + seconds - duration;
            CGFloat end = [manager_ getSecondsWithoutAction:seconds];
            
            duration = end - actionDo.SecondsInArray;
            
            [manager_ setActionItemDuration:actionDo duration:duration];
        }
        
    }
}
-(void)slow:(UIButton *)sender
{
    CMTime playerTime =  [player_.playerItem currentTime];
    CGFloat seconds = CMTimeGetSeconds(playerTime);
    if (sender.selected) {
        sender.selected = NO;
        MediaActionDo * actionDo = [manager_ findActionAt:seconds - 0.1 index:-1];
        if(actionDo)
        {
            CGFloat duration = [manager_ getSecondsWithoutAction:seconds];
            duration -= actionDo.SecondsInArray;
            
            [manager_ setActionItemDuration:actionDo duration:duration];
        }
    } else {
        sender.selected = YES;
        
        MediaAction * action = [MediaAction new];
        action.ActionType = SSlow;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = YES;
        action.IsMutex = NO;
        action.isOPCompleted = NO;
        [manager_ addActionItem:action filePath:nil at:seconds duration:-1];
    }
}
-(void)fast:(UIButton *)sender
{
    CMTime playerTime =  [player_ durationWhen];
    CGFloat seconds = CMTimeGetSeconds(playerTime);
    if (sender.selected) {
        sender.selected = NO;
        MediaActionDo * actionDo = [manager_ findActionAt:seconds - 0.1 index:-1];
        if(actionDo)
        {
            CGFloat duration = [manager_ getSecondsWithoutAction:seconds];
            duration -= actionDo.SecondsInArray;
            
            [manager_ setActionItemDuration:actionDo duration:duration];
        }
    } else {
        sender.selected = YES;
        
        MediaAction * action = [MediaAction new];
        action.ActionType = SFast;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = YES;
        action.IsMutex = NO;
        action.isOPCompleted = NO;
        [manager_ addActionItem:action filePath:nil at:seconds duration:-1];
    }
}
- (void)playerSimple:(HCPlayerSimple *)playerSimple timeDidChange:(CGFloat)cmTime
{
    if(playerSimple == rPlayer_)
    {
        
    }
    else if(playerSimple == player_)
    {
        
    }
}
#pragma mark - delegate
- (void)ActionManager:(ActionManager *)manager reverseGenerated:(MediaItem *)reverseVideo
{
    baseVideo_ = [manager getBaseVideo];
    reverseVideo_ = reverseVideo;
    if(viewShowed_)
    {
        [self buildPlayer];
        [self buildReversePlayer];
    }
}
- (void)ActionManager:(ActionManager *)manager actionChanged:(MediaActionDo *)action type:(int)opType//0 add 1 update 2 remove
{
    NSLog(@"action changed");
    
    player_.rate = action.Rate;
    
    //repeater
    if(action.ActionType == SRepeat)
    {
        [player_ seek:action.DurationInSeconds + action.ReverseSeconds accurate:YES];
//        [player_ seekToTime:CMTimeMake(action.DurationInSeconds + action.ReverseSeconds  , repeatTime_.timescale)
//           toleranceBefore:kCMTimeZero
//            toleranceAfter:kCMTimeZero
//         completionHandler:^(BOOL finished) {
//             if (finished) {
                 [player_ play];
                 CMTime afterseek = player_.playerItem.currentTime;
                 CGFloat diff = CMTimeGetSeconds(repeatTime_) - CMTimeGetSeconds(afterseek);
                 NSLog(@"diff = %.3f afterseek time = %.3f", diff, CMTimeGetSeconds(afterseek));
                 
                 //repeater three times
                 repeatTimer_ = [NSTimer scheduledTimerWithTimeInterval:diff target:self selector:@selector(repeat:) userInfo:nil repeats:YES];
                 repeatCnt_ ++ ;
//             }
//         }];
        
    }
    else if(action.ActionType == SSlow)
    {
        //        player.rate = 1.0/3;
    }
    else if(action.ActionType ==SFast)
    {
        
    }
    else if(action.ActionType ==SReverse)
    {
        if(action.isOPCompleted==NO)
        {
            [player_ pause];
            if (rPlayer_) {
                CGFloat diff = CMTimeGetSeconds([player_ duration]) - CMTimeGetSeconds([player_ durationWhen]);
                NSLog(@"player reverse at time %.3f", diff);
                [rPlayer_ seek:diff accurate:YES];
                [rPlayer_ play];
                [rPlayer_ currentLayer].opacity = 1;
            }
        }
        else
        {
            [rPlayer_ pause];
            NSLog(@"normal play");
            CGFloat diff = CMTimeGetSeconds([rPlayer_ duration]) - CMTimeGetSeconds([rPlayer_ durationWhen]);
            [player_ seek:diff accurate:YES];
            [player_ play];
            [rPlayer_ currentLayer].opacity = 0;
        }
    }
    else
    {
        
    }
}
- (void)ActionManager:(ActionManager *)manager doProcessOK:(NSArray *)mediaList duration:(CGFloat)duration
{
    NSLog(@"action doProcessOK");
}
- (void)ActionManager:(ActionManager *)manager playerItem:(AVPlayerItem *)playerItem duration:(CGFloat)duration
{
    NSLog(@"action playerItem ready");
}
-(void)join:(UIButton *)sender
{
    [player_ pause];
    [rPlayer_ pause];
    
    VideoGenerater * vg = [[VideoGenerater alloc]init];
    [vg resetGenerateInfo];
    vg.waterMarkFile = CT_WATERMARKFILE;
    vg.mergeRate = 1;
    vg.volRampSeconds = 0.5;
    
    [vg setTimeForMerge:0 end:-1];
    [vg setTimeForAudioMerge:0 end:-1];
    
    NSArray * actionList = [manager_ getMediaList];
    
    [vg setBlock:^(VideoGenerater *queue, CGFloat progress) {
        NSLog(@"progress %f",progress);
    } ready:^(VideoGenerater *queue, AVPlayerItem *playerItem) {
        NSLog(@"playerItem Ready");
        
    } completed:^(VideoGenerater *queue, NSURL *mvUrl, NSString *coverPath) {
        NSLog(@"generate completed.  %@",[mvUrl path]);
    } failure:^(VideoGenerater *queue, NSString *msg, NSError *error) {
        NSLog(@"generate failure:%@ error:%@",msg,[error localizedDescription]);
    }];
    
    BOOL ret = [manager_ generateMediaListWithActions:actionList complted:^(NSArray * mediaList)
    {
        [vg generatePreviewAsset:mediaList
                        bgVolume:1
                      singVolume:1
                      completion:^(BOOL finished)
         {
              [vg generateMVFile:mediaList retryCount:0];
         }];
    }];
    if(!ret)
    {
        NSLog(@"generate failure.");
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

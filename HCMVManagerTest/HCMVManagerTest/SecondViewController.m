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
#import "ActionManager(index).h"
#import "MediaAction.h"
#import "MediaWithAction.h"
#import "WTPlayerResource.h"
#import <hccoren/base.h>
#import "HCPlayerSimple.h"
#import "ActionManagerPannel.h"
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
    
    MediaActionDo * currentAction_;
    MediaWithAction * currentMedia_;
    
    UIActivityIndicatorView * indicatorView_;
    
    BOOL showTimeChanged_;
    
    ActionManagerPannel * pannel_;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    manager_ = [ActionManager shareObject];
    manager_.delegate = self;
    [manager_ removeActions];
    
//    oPath_ = [[NSBundle mainBundle] pathForResource:@"test2" ofType:@"mp4"];
    oPath_ = [[NSBundle mainBundle] pathForResource:@"test3" ofType:@"MOV"];
    viewShowed_ = NO;
    [self showIndicatorView];
    [manager_ setBackMV:oPath_ begin:0 end:-1];
    
    showTimeChanged_ = YES;
    // Do any additional setup after loading the view, typically from a nib.
}
-(void)viewDidAppear:(BOOL)animated
{
    //[self layout];
    [self layoutNew];
    [ActionManager shareObject].delegate = self;
}
- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [player_ pause];
}
-(void)layoutNew
{
    if(!viewShowed_)
    {
        CGFloat top = self.view.frame.size.height - 120;
        slow_ = [UIButton buttonWithType:UIButtonTypeCustom];
        [slow_ setFrame:CGRectMake(20, top, 60, 30)];
        [slow_ setTitle:@"slow" forState:UIControlStateNormal];
        [slow_ setTitle:@"normal" forState:UIControlStateSelected];
        slow_.titleLabel.font = [UIFont systemFontOfSize:14];
        [slow_ setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.view addSubview:slow_];
        
        fast_ = [UIButton buttonWithType:UIButtonTypeCustom];
        [fast_ setFrame:CGRectMake(100, top, 60, 30)];
        [fast_ setTitle:@"fast" forState:UIControlStateNormal];
        [fast_ setTitle:@"normal" forState:UIControlStateSelected];
        fast_.titleLabel.font = [UIFont systemFontOfSize:14];
        [fast_ setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.view addSubview:fast_];
        
        joinBtn_ = [UIButton buttonWithType:UIButtonTypeCustom];
        [joinBtn_ setFrame:CGRectMake(180, top, 60, 30)];
        [joinBtn_ setTitle:@"reset" forState:UIControlStateNormal];
        joinBtn_.titleLabel.font = [UIFont systemFontOfSize:14];
        [joinBtn_ setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.view addSubview:joinBtn_];
        
        [slow_ addTarget:self action:@selector(slow:) forControlEvents:UIControlEventTouchUpInside];
        [fast_ addTarget:self action:@selector(fast:) forControlEvents:UIControlEventTouchUpInside];
        [joinBtn_ addTarget:self action:@selector(reset:) forControlEvents:UIControlEventTouchUpInside];
        
        rate1x_ = [UIButton buttonWithType:UIButtonTypeCustom];
        [rate1x_ setFrame:CGRectMake(20, top + 40, 60, 30)];
        [rate1x_ setTitle:@"repeat" forState:UIControlStateNormal];
        rate1x_.titleLabel.font = [UIFont systemFontOfSize:14];
        [rate1x_ setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.view addSubview:rate1x_];
        rate2x_ = [UIButton buttonWithType:UIButtonTypeCustom];
        [rate2x_ setFrame:CGRectMake(100, top + 40, 60, 30)];
        [rate2x_ setTitle:@"reverse" forState:UIControlStateNormal];
        [rate2x_ setTitle:@"origin" forState:UIControlStateSelected];
        rate2x_.titleLabel.font = [UIFont systemFontOfSize:14];
        [rate2x_ setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.view addSubview:rate2x_];
        [rate1x_ addTarget:self action:@selector(repeat:) forControlEvents:UIControlEventTouchUpInside];
        [rate2x_ addTarget:self action:@selector(reverseStart:) forControlEvents:UIControlEventTouchUpInside];
        
        repeatTime_ = kCMTimeZero;
        
        CGFloat playerBottom = 20 + self.view.frame.size.width/16 * 9;
        pannel_ = [[ActionManagerPannel alloc]initWithFrame:CGRectMake(10, 10 + playerBottom, self.view.frame.size.width -20, top - 20 - playerBottom)];
        pannel_.backgroundColor = [UIColor grayColor];
        [self.view addSubview:pannel_];
        
        
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
}
#pragma mark - buildPlayer
- (void) buildPlayer
{
    if(!baseVideo_)
    {
        NSLog(@"no base item");
        return;
    }
    AVAsset * asset = [AVAsset assetWithURL:baseVideo_.url];
    AVPlayerItem * item = [AVPlayerItem playerItemWithAsset:asset];
    if(player_)
    {
        [player_ changeCurrentPlayerItem:item];
        [self.view.layer addSublayer:[player_ currentLayer]];
    }
    else
    {
        player_ = [[HCPlayerSimple alloc]initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.width /16 * 9)];
        [player_ changeCurrentPlayerItem:item];
        player_.delegate = self;
        [self.view.layer addSublayer:[player_ currentLayer]];
    }
    [NSThread sleepForTimeInterval:0.1];
    [player_ play];
}
- (void) buildReversePlayer
{
    if(!reverseVideo_)
    {
        NSLog(@"no reverse item");
        return;
    }
    AVAsset * asset = [AVAsset assetWithURL:reverseVideo_.url];
    AVPlayerItem * item = [AVPlayerItem playerItemWithAsset:asset];
    if(rPlayer_)
    {
        [rPlayer_ changeCurrentPlayerItem:item];
        AVPlayerLayer * playerLayer = [rPlayer_ currentLayer];
        playerLayer.opacity = 0;
        [self.view.layer addSublayer:playerLayer];
    }
    else
    {
        rPlayer_ = [[HCPlayerSimple alloc]initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.width /16 * 9)];
        [rPlayer_ changeCurrentPlayerItem:item];
        rPlayer_.delegate = self;
        AVPlayerLayer * playerLayer = [rPlayer_ currentLayer];
        
        playerLayer.opacity = 0;
        [self.view.layer addSublayer:playerLayer];
    }
}
- (void) showIndicatorView
{
    if([NSThread isMainThread])
    {
        if(!indicatorView_)
        {
            indicatorView_ = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            indicatorView_.frame = CGRectMake(0, 0, 80, 80);
            indicatorView_.center = self.view.center;
            [self.view addSubview:indicatorView_];
        }
        else
        {
            indicatorView_.hidden = NO;
        }
        [indicatorView_ startAnimating];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showIndicatorView];
        });
    }
}
- (void) hideIndicatorView
{
    if([NSThread isMainThread])
    {
        if(indicatorView_)
        {
            [indicatorView_ stopAnimating];
            indicatorView_.hidden = YES;
        }
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideIndicatorView];
        });
    }
    
}
#pragma mark - button events
-(void)repeat:(UIButton *)sender
{
    //    [repeatTimer_ invalidate];
    //    repeatTimer_ = nil;
    //    if (repeatCnt_ > 2) {
    //        repeatCnt_ = 0;
    //        repeatTime_ = kCMTimeZero;
    //        return;
    //    }
    
    //    if (CMTimeGetSeconds(repeatTime_) == 0) {
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
    action.Rate = 1;
    
    [manager_ addActionItem:action filePath:nil at:secondsPlaying duration:1];
    
    //    }
    
    
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
        action.Rate = 1;
        if([manager_ addActionItem:action filePath:nil at:seconds duration:-1])
        {
            sender.selected = YES;
        }
        
    } else {
        sender.selected = NO;
        MediaActionDo * actionDo = [manager_ findActionAt:seconds index:-1];
        if(actionDo)
        {
            //反向没有变速，可以直接获取
            //反向轨转成正向轨
            CGFloat playerPos = CMTimeGetSeconds(reverDuration)-CMTimeGetSeconds(reverSeconds);
            //            seconds =  seconds - duration;
            CGFloat end = [manager_ getSecondsWithoutAction:seconds];
            CGFloat duration = end - playerPos;
            //            duration = end - actionDo.SecondsInArray;
            
            [manager_ setActionItemDuration:actionDo duration:duration];
        }
        
    }
}
- (void)subtractMV
{
    VideoGenerater * vg = [VideoGenerater new];
    [vg setBlock:^(VideoGenerater *queue, CGFloat progress) {
        NSLog(@"progress %f",progress);
    } ready:^(VideoGenerater *queue, AVPlayerItem *playerItem) {
        NSLog(@"playerItem Ready");
        
    } completed:^(VideoGenerater *queue, NSURL *mvUrl, NSString *coverPath) {
        NSLog(@"generate completed.  %@",[mvUrl path]);
        NSString * fileName = [[HCFileManager manager]getFileNameByTicks:@"subtract.mp4"];
        NSString * filePath = [[HCFileManager manager]localFileFullPath:fileName];
        [HCFileManager copyFile:[mvUrl path] target:filePath overwrite:YES];
        
        [self hideIndicatorView];
        
    } failure:^(VideoGenerater *queue, NSString *msg, NSError *error) {
        NSLog(@"generate failure:%@ error:%@",msg,[error localizedDescription]);
        [self hideIndicatorView];
    }];
    if([vg generateMVSegmentsViaFile:oPath_ begin:2 end:10])
    {
        [vg generateMVFile:nil retryCount:0];
    }
}
-(void)slow:(UIButton *)sender
{
    [player_ pause];
    
    
    CMTime playerTime =  [player_.playerItem currentTime];
    CGFloat seconds = CMTimeGetSeconds(playerTime);
    if (sender.selected) {
        sender.selected = NO;
        NSLog(@"player action seconds:%f",seconds);
        MediaWithAction * media = [manager_ findMediaItemAt:seconds];
        
        MediaActionDo * actionDo = nil;
        if([media.Action isKindOfClass:[MediaActionDo class]])
        {
            actionDo = (MediaActionDo *)media.Action;
        }
        else
        {
            actionDo = [manager_ findActionAt:media.secondsInArray index:-1];
        }
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
        action.Rate = 0.33333;
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
        action.Rate = 3.0;
        action.IsOverlap = YES;
        action.IsMutex = NO;
        action.isOPCompleted = NO;
        [manager_ addActionItem:action filePath:nil at:seconds duration:-1];
    }
}
#pragma mark - player delegate
- (void)playerSimple:(HCPlayerSimple *)playerSimple timeDidChange:(CGFloat)cmTime
{
    if(showTimeChanged_)
    {
        NSLog(@"---- player seconds:%f rate:%.2f",cmTime,[playerSimple currentPlayer].rate);
        showTimeChanged_ = NO;
    }
    if(playerSimple == rPlayer_)
    {
        
    }
    else if(playerSimple == player_)
    {
        
    }
    //    if(currentMedia_ && currentMedia_.secondsInArray + currentMedia_.secondsDurationInArray - 0.02 < cmTime)
    //    {
    //        [[ActionManager shareObject]checkActionForPlayViaTime:cmTime];
    //    }
}
- (void)playerSimple:(HCPlayerSimple *)playerSimple reachEnd:(CGFloat)end
{
    CGFloat endSeconds = end>0?end:-1;
    if(playerSimple == rPlayer_)
    {
        if(endSeconds<0)
            endSeconds = CMTimeGetSeconds([rPlayer_ durationWhen]);
        [rPlayer_ pause];
    }
    else if(playerSimple == player_)
    {
        if(endSeconds<0)
            endSeconds = CMTimeGetSeconds([player_ durationWhen]);
        //        [player_ seek:0 accurate:YES];
        //        [player_ play];
        [player_ pause];
    }
    //自动结束没有结束的动作
    [manager_ ensureActions:endSeconds];
    
    [self resetAllButtons];
    
    [self join:nil];
}
- (void)resetAllButtons
{
    slow_.selected = NO;
    fast_.selected = NO;
    rate1x_.selected = NO;
    rate2x_.selected = NO;
    showTimeChanged_ = YES;
}
#pragma mark - delegate
- (void)ActionManager:(ActionManager *)manager reverseGenerated:(MediaItem *)reverseVideo
{
    NSLog(@"*************** generate ok *****************");
    baseVideo_ = [manager getBaseVideo];
    reverseVideo_ = reverseVideo;
    if(viewShowed_)
    {
        [pannel_ setActionManager:manager];
        
        [self buildPlayer];
        [self buildReversePlayer];
    }
    [self hideIndicatorView];
}
//当播放器的内容需要发生改变时
- (void)ActionManager:(ActionManager *)manager play:(MediaWithAction *)mediaToPlay
{
    showTimeChanged_ = YES;
    
    [pannel_ refresh];
    
    if(!mediaToPlay)
    {
        [player_ pause];
        [rPlayer_ pause];
        NSLog(@"mediaToPlay:nil");
        return ;
    }
    NSLog(@"mediaToPlay:%@",[mediaToPlay toDicionary]);
    //    if((currentMedia_ && [mediaToPlay isSampleAsset:currentMedia_])
    //       ||
    //       ([mediaToPlay isSampleAsset:baseVideo_])
    //       ||
    //       ([mediaToPlay isSampleAsset:reverseVideo_])
    //       )
    //    {
    if(mediaToPlay.Action.ActionType!=SReverse)
    {
        [rPlayer_ pause];
        [player_ seek:mediaToPlay.secondsBegin accurate:YES];
        [player_ currentLayer].opacity = 1;
        [rPlayer_ currentLayer].opacity = 0;
        [player_ setRate:mediaToPlay.playRate];
        [player_ play];
    }
    else
    {
        [player_ pause];
        [rPlayer_ seek:mediaToPlay.secondsBegin accurate:YES];
        [rPlayer_ currentLayer].opacity = 1;
        [player_ currentLayer].opacity = 0;
        [rPlayer_ setRate:mediaToPlay.playRate];
        [rPlayer_ play];
    }
    //    }
    //    else
    //    {
    //        if(mediaToPlay.Action.ActionType!=SReverse)
    //        {
    //            [rPlayer_ pause];
    //            [rPlayer_ currentLayer].opacity = 0;
    //            [player_ currentLayer].opacity = 1;
    //            [player_ seek:mediaToPlay.secondsBegin accurate:YES];
    //            [player_ setRate:mediaToPlay.playRate];
    //            [player_ play];
    //        }
    //        else
    //        {
    //            [player_ pause];
    //            [rPlayer_ seek:mediaToPlay.secondsBegin accurate:YES];
    //            [rPlayer_ setRate:mediaToPlay.playRate];
    //            [rPlayer_ play];
    //            [player_ currentLayer].opacity = 0;
    //            [rPlayer_ currentLayer].opacity = 1;
    //        }
    //    }
    currentMedia_ = mediaToPlay;
}
- (void)ActionManager:(ActionManager *)manager actionChanged:(MediaActionDo *)action type:(int)opType//0 add 1 update 2 remove
{
    NSLog(@"action do changed:%@",action.ActionTitle);
    [rPlayer_ pause];
    [player_ pause];
    showTimeChanged_ = YES;
}
- (void)ActionManager:(ActionManager *)manager doProcessOK:(NSArray *)mediaList duration:(CGFloat)duration
{
    NSLog(@"-------------**----**--------------------");
    NSLog(@"duration:%.2f",duration);
    NSLog(@"** playerSeconds:7 track seconds:%.2f",[[ActionManager shareObject]getSecondsWithoutAction:7]);
    NSLog(@"** playerSeconds:10 track seconds:%.2f",[[ActionManager shareObject]getSecondsWithoutAction:10]);
    int index = 0;
    for (MediaWithAction * item in mediaList) {
        NSLog(@"--%d-- type:%d",index,item.Action.ActionType);
        NSLog(@"%@",[item toString]);
        index ++;
    }
    NSLog(@"**--**--**--**--**--**--**--**--**--**--");
}
- (void)ActionManager:(ActionManager *)manager playerItem:(AVPlayerItem *)playerItem duration:(CGFloat)duration
{
    NSLog(@"action playerItem ready");
}
- (void)ActionManager:(ActionManager *)manager generateOK:(NSString *)filePath cover:(NSString *)cover
{
    [manager_ setBackMV:filePath begin:0 end:-1];
    
    [manager_ removeActions];
    
//    [self hideIndicatorView];
}
- (void)ActionManager:(ActionManager *)manager genreateFailure:(NSError *)error
{
    [self hideIndicatorView];
}

- (void)reset:(UIButton *)sender
{
    [self showIndicatorView];
    [self resetAllButtons];
    [player_ pause];
    [rPlayer_ pause];
    [player_ setRate:1];
    [[ActionManager shareObject]clear];
    [manager_ setBackMV:oPath_ begin:0 end:-1];
}
-(void)join:(UIButton *)sender
{
    [self showIndicatorView];
    
    [player_ setRate:1];
    
    [player_ pause];
    [rPlayer_ pause];
    
    //暂时暂停，用于检查
//    if([manager_ needGenerateForOP]) return;
    
    NSLog(@"************ begin generate **************");
    if(![manager_ generateMV])
    {
        [player_ seek:0 accurate:YES];
        [player_ play];
        [self hideIndicatorView];
        return;
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

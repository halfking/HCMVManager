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
#import "MediaEditManager.h"
#import "MediaAction.h"
#import "MediaWithAction.h"
#import "WTPlayerResource.h"
#import <hccoren/base.h>
#import "HCPlayerSimple.h"
#import "ActionManagerPannel.h"
#import "ActionManager(player).h"
#import "mvconfig.h"
#import "CLFiltersClass.h"
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kNavgationHeight 64.0

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
    UIButton * subtract_;
    
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
    
    //    NSArray * titleArray_;
    //    NSMutableArray * filterArray_;
    //    GPUImageView *filterView_;
    //    GPUImageMovie *movieFile_;
    //    GPUImageOutput<GPUImageInput> *filters_;
    //    GPUImageMovieWriter *videoWriter_;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    manager_ = [ActionManager shareObject];
    manager_.delegate = self;
    //    [manager_ removeActions];
    
    NSString * audioPath  = [[NSBundle mainBundle] pathForResource:@"man" ofType:@"mp3"];
        oPath_ = [[NSBundle mainBundle] pathForResource:@"test2" ofType:@"mp4"];
//    oPath_ = [[NSBundle mainBundle] pathForResource:@"test2" ofType:@"MOV"];
    //    oPath_ = [[NSBundle mainBundle]pathForResource:@"up" ofType:@"MOV"];
    //        oPath_ = [[NSBundle mainBundle]pathForResource:@"upset" ofType:@"MOV"];
    //       oPath_ = [[NSBundle mainBundle]pathForResource:@"lanleft" ofType:@"MOV"];
    //        oPath_ = [[NSBundle mainBundle]pathForResource:@"lanright" ofType:@"MOV"];
    
    //   oPath_ = [[NSBundle mainBundle]pathForResource:@"front_up" ofType:@"MOV"];
    //        oPath_ = [[NSBundle mainBundle]pathForResource:@"front_lanright" ofType:@"MOV"];
    
    viewShowed_ = NO;
    [self showIndicatorView];
    if(![manager_ getBaseVideo])
    {
        [manager_ setBackMV:oPath_ begin:0 end:-1 buildReverse:YES];
    }
    [manager_ setBackAudio:audioPath begin:0 end:-1];
    
    baseVideo_ = [manager_ getBaseVideo];
    
    showTimeChanged_ = YES;
    // Do any additional setup after loading the view, typically from a nib.
}
-(void)viewDidAppear:(BOOL)animated
{
    //[self layout];
    [self layoutNew];
    [ActionManager shareObject].delegate = self;
    
    [pannel_ refresh];
    
    [self buildControls];
    
    [player_ play];
    
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
        CGFloat top = self.view.frame.size.height - 140;
        CGFloat left = 10;
        slow_ = [UIButton buttonWithType:UIButtonTypeCustom];
        [slow_ setFrame:CGRectMake(left, top, 60, 44)];
        [slow_ setTitle:@"slow" forState:UIControlStateNormal];
        [slow_ setTitle:@"normal" forState:UIControlStateSelected];
        slow_.titleLabel.font = [UIFont systemFontOfSize:14];
        [slow_ setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        slow_.backgroundColor = [UIColor grayColor];
        [self.view addSubview:slow_];
        left += 60;
        
        fast_ = [UIButton buttonWithType:UIButtonTypeCustom];
        [fast_ setFrame:CGRectMake(left, top, 60, 44)];
        [fast_ setTitle:@"fast" forState:UIControlStateNormal];
        [fast_ setTitle:@"normal" forState:UIControlStateSelected];
        fast_.titleLabel.font = [UIFont systemFontOfSize:14];
        [fast_ setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        fast_.backgroundColor = [UIColor grayColor];
        [self.view addSubview:fast_];
        left += 60;
        
        joinBtn_ = [UIButton buttonWithType:UIButtonTypeCustom];
        [joinBtn_ setFrame:CGRectMake(left, top, 60, 44)];
        [joinBtn_ setTitle:@"reset" forState:UIControlStateNormal];
        joinBtn_.titleLabel.font = [UIFont systemFontOfSize:14];
        [joinBtn_ setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        joinBtn_.backgroundColor = [UIColor grayColor];
        [self.view addSubview:joinBtn_];
        
        left += 60;
        
        [slow_ addTarget:self action:@selector(slow:) forControlEvents:UIControlEventTouchUpInside];
        [fast_ addTarget:self action:@selector(fast:) forControlEvents:UIControlEventTouchUpInside];
        [joinBtn_ addTarget:self action:@selector(reset:) forControlEvents:UIControlEventTouchUpInside];
        
        rate1x_ = [UIButton buttonWithType:UIButtonTypeCustom];
        [rate1x_ setFrame:CGRectMake(left, top, 60, 44)];
        [rate1x_ setTitle:@"repeat" forState:UIControlStateNormal];
        rate1x_.titleLabel.font = [UIFont systemFontOfSize:14];
        [rate1x_ setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        rate1x_.backgroundColor = [UIColor grayColor];
        [self.view addSubview:rate1x_];
        left += 60;
        
        rate2x_ = [UIButton buttonWithType:UIButtonTypeCustom];
        [rate2x_ setFrame:CGRectMake(left, top, 60, 44)];
        [rate2x_ setTitle:@"reverse" forState:UIControlStateNormal];
        [rate2x_ setTitle:@"origin" forState:UIControlStateSelected];
        rate2x_.titleLabel.font = [UIFont systemFontOfSize:14];
        [rate2x_ setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        rate2x_.backgroundColor = [UIColor grayColor];
        [self.view addSubview:rate2x_];
        left += 60;
        [rate1x_ addTarget:self action:@selector(repeat:) forControlEvents:UIControlEventTouchUpInside];
        [rate2x_ addTarget:self action:@selector(reverseStart:) forControlEvents:UIControlEventTouchUpInside];
        
        
        subtract_ = [UIButton buttonWithType:UIButtonTypeCustom];
        [subtract_ setFrame:CGRectMake(left, top, 60, 44)];
        [subtract_ setTitle:@"subt" forState:UIControlStateNormal];
        subtract_.titleLabel.font = [UIFont systemFontOfSize:14];
        [subtract_ setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        subtract_.backgroundColor = [UIColor grayColor];
        [self.view addSubview:subtract_];
        
        //        [subtract_ addTarget:self action:@selector(subtractMV:) forControlEvents:UIControlEventTouchUpInside];
        [subtract_ addTarget:self action:@selector(generateFilterItem) forControlEvents:UIControlEventTouchUpInside];
        
        top += 46;
        
        NSArray * filters = [manager_ getGPUFilters];
        
        for (NSDictionary * filter in filters) {
            UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
            int index = [[filter objectForKey:@"index"]intValue];
            [btn setFrame:CGRectMake(10 + index * 48, top, 44, 44)];
            [btn setTitle:[NSString stringWithFormat:@"%@",[filter objectForKey:@"title"]] forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont systemFontOfSize:14];
            [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            btn.backgroundColor = [UIColor grayColor];
            btn.tag = 10000 + index;
            [btn addTarget:self action:@selector(changeFilter:) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:btn];
        }
        
        
        repeatTime_ = kCMTimeZero;
        
        CGFloat playerBottom =  self.view.frame.size.width/16 * 9;
        pannel_ = [[ActionManagerPannel alloc]initWithFrame:CGRectMake(10, 10 + playerBottom,
                                                                       self.view.frame.size.width -20,
                                                                       top - 60 - playerBottom)];
        pannel_.backgroundColor = [UIColor grayColor];
        [self.view addSubview:pannel_];
        
        
        if(!viewShowed_)
        {
            [self buildControls];
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
    NSString * key = [CommonUtil md5Hash:baseVideo_.url.absoluteString];
    if(player_)
    {
        if([key isEqualToString:player_.key])
        {
            
        }
        else
        {
            CGFloat seconds = player_.secondsPlaying;
            BOOL isPlaying = player_.playing;
            player_.key = key;
            [player_ changeCurrentPlayerItem:item];
            [player_ seek:seconds accurate:YES];
            if(isPlaying)
            {
                [player_ play];
            }
        }
        //        [self.view.layer addSublayer:[player_ currentLayer]];
    }
    else
    {
        player_.key = key;
        player_ = [[HCPlayerSimple alloc]initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.width /16 * 9)];
        [player_ changeCurrentPlayerItem:item];
        player_.delegate = self;
        [self.view addSubview:player_];
        //        [self.view.layer addSublayer:[player_ currentLayer]];
    }
    player_.backgroundColor = [UIColor clearColor];
    [NSThread sleepForTimeInterval:0.1];
    //    [player_ play];
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
        rPlayer_.hidden= YES;
        //        AVPlayerLayer * playerLayer = [rPlayer_ currentLayer];
        //        playerLayer.opacity = 0;
        //        [self.view.layer addSublayer:playerLayer]; //此处可能导至x，y坐标有问题，因为在Player中都是0，实际上可能不为0
    }
    else
    {
        rPlayer_ = [[HCPlayerSimple alloc]initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.width /16 * 9)];
        [rPlayer_ changeCurrentPlayerItem:item];
        rPlayer_.delegate = self;
        rPlayer_.hidden = YES;
        [self.view addSubview:rPlayer_];
        //        AVPlayerLayer * playerLayer = [rPlayer_ currentLayer];//此处可能导至x，y坐标有问题，因为在Player中都是0，实际上可能不为0
        //
        //        playerLayer.opacity = 0;
        //        [self.view.layer addSublayer:playerLayer];
    }
    rPlayer_.backgroundColor = [UIColor clearColor];
}
- (void) buildControls
{
    if(![NSThread isMainThread])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self buildControls];
        });
        return ;
    }
    BOOL needPlayer = !viewShowed_ || !player_;
    if(baseVideo_)
    {
        [self buildPlayer];
    }
    if(reverseVideo_)
    {
        [self buildReversePlayer];
    }
    [pannel_ setActionManager:manager_];
    [manager_ initPlayer:player_ reversePlayer:rPlayer_ audioPlayer:nil];
    
    //    [manager_ initGPUFilter:player_ in:self.view];
    if(needPlayer)
        [player_ play];
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
#pragma mark - filter
- (void) changeFilter:(UIButton *)sender
{
    rPlayer_.hidden = YES;
    [manager_ initGPUFilter:player_ in:self.view];
    
    int index = (int)sender.tag - 10000;
    sender.selected = YES;
    
    for (int i = 10000 ;i < 10000+20;i ++) {
        if(i!=index)
        {
            UIButton * btn = (UIButton*)[self.view viewWithTag:i];
            if(btn) btn.selected = NO;
        }
    }
    
    // 实时切换滤镜
    [manager_ setGPUFilter:index];
}
- (void) subtractMV:(id)sender
{
    VideoGenerater * vg = [VideoGenerater new];
    [vg setBlock:^(VideoGenerater *queue, CGFloat progress) {
        NSLog(@"video generater progress %.1f",progress);
        
    } ready:^(VideoGenerater *queue, AVPlayerItem *playerItem) {
        NSLog(@"playerItem Ready");
        
    } completed:^(VideoGenerater *queue, NSURL *mvUrl, NSString *coverPath) {
        NSLog(@"generate completed.  %@",[mvUrl path]);
        NSString * fileName = [[HCFileManager manager]getFileNameByTicks:@"subtract.mp4"];
        NSString * filePath = [[HCFileManager manager]localFileFullPath:fileName];
        [HCFileManager copyFile:[mvUrl path] target:filePath overwrite:YES];
        
        [player_ changeCurrentItemPath:filePath];
        [NSThread sleepForTimeInterval:0.2];
        [player_ play];
        
    } failure:^(VideoGenerater *queue, NSString *msg, NSError *error) {
        NSLog(@"generate failure:%@ error:%@",msg,[error localizedDescription]);
        
    }];
    
    if([vg generateMVSegmentsViaFile:baseVideo_.filePath begin:0 end:5 targetSize:CGSizeMake(100, 100)])
    {
        [vg generateMVFile:nil retryCount:0];
    }
}
- (void)generateFilterItem
{
    [manager_ generateMVByFilter:5];
}
#pragma mark - buttons
-(void)repeat:(UIButton *)sender
{
    [manager_ removeGPUFilter];
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
    action.ReverseSeconds = 0;// - RepeatTime;
    action.DurationInSeconds = 1;
    action.IsOverlap = NO;
    action.IsMutex = NO;
    action.isOPCompleted = YES;
    action.Rate = 1;
    
    //    CGFloat secondsInTrack = [manager_ secondsForTrack:secondsPlaying];
    
    [manager_ addActionItem:action filePath:nil at:secondsPlaying from:secondsPlaying duration:1];
    
    //    }
    
    
}
-(void)reverseStart:(UIButton *)sender
{
    [manager_ cancelGenerate];
    [manager_ removeGPUFilter];
    CMTime playerTime =  [player_.playerItem currentTime];
    CGFloat seconds = CMTimeGetSeconds(playerTime);
    
    CMTime reverSeconds = [rPlayer_.playerItem currentTime];
    CMTime reverDuration = [rPlayer_.playerItem duration];
    
    CGFloat secondsInTrack = [manager_ getSecondsInArrayViaCurrentState:seconds];
    
    NSLog(@"#######reverse:%.4f  trackseconds:%.4f",seconds,secondsInTrack);
    [player_ pause];
    if (!sender.selected) {
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        action.ReverseSeconds = 0;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.isOPCompleted = NO;
        action.Rate = 1;
        action.IsReverse = YES;
        
        
        currentAction_ = [manager_ addActionItem:action filePath:nil at:seconds from:seconds duration:-1];
        if(currentAction_){
            sender.selected = YES;
        }
        
        
    } else {
        sender.selected = NO;
        MediaActionDo * actionDo = [manager_ findActionAt:secondsInTrack index:-1];
        if(!actionDo)
        {
            secondsInTrack = [manager_ getSecondsInArrayFromPlayer:seconds isReversePlayer:NO];
            actionDo = [manager_ findActionAt:secondsInTrack index:-1];
        }
        actionDo = currentAction_;// [manager_ findActionAt:secondsInTrack index:-1];
        if(actionDo)
        {
            //反向没有变速，可以直接获取
            //反向轨转成正向轨
            CGFloat duration = CMTimeGetSeconds(reverSeconds) - actionDo.Media.secondsBegin;
            
            //            CGFloat playerPos = CMTimeGetSeconds(reverDuration)-CMTimeGetSeconds(reverSeconds);
            //            CGFloat end = [manager_ getSecondsInArrayFromPlayer:playerPos isReversePlayer:actionDo.IsReverse];
            //            CGFloat duration = end - playerPos;
            
            [manager_ setActionItemDuration:actionDo duration:duration];
        }
        
    }
}
-(void)slow:(UIButton *)sender
{
    [manager_ removeGPUFilter];
    [player_ pause];
    
    
    CMTime playerTime =  [player_.playerItem currentTime];
    CGFloat seconds = CMTimeGetSeconds(playerTime);
    
    //    CGFloat secondsInTrack = [manager_ secondsForTrack:seconds];
    
    MediaAction * action = [MediaAction new];
    action.ActionType = SSlow;
    action.ReverseSeconds = 0 ;
    action.IsOverlap = YES;
    action.IsMutex = NO;
    action.Rate = 0.33333;
    action.isOPCompleted = YES;
    [manager_ addActionItem:action filePath:nil at:seconds from:seconds duration:0.5];
    
    return;
    
    //    if (sender.selected) {
    //        sender.selected = NO;
    //        NSLog(@"player action seconds:%f",seconds);
    //        MediaWithAction * media = [manager_ findMediaItemAt:secondsInTrack];
    //
    //        MediaActionDo * actionDo = nil;
    //        if([media.Action isKindOfClass:[MediaActionDo class]])
    //        {
    //            actionDo = (MediaActionDo *)media.Action;
    //        }
    //        else
    //        {
    //            actionDo = [manager_ findActionAt:media.secondsInArray index:-1];
    //        }
    //        if(actionDo)
    //        {
    //            CGFloat duration = secondsInTrack;// seconds;//[manager_ getSecondsWithoutAction:seconds];
    //            duration -= actionDo.SecondsInArray;
    //
    //            [manager_ setActionItemDuration:actionDo duration:duration];
    //        }
    //    } else {
    //        sender.selected = YES;
    //
    //        MediaAction * action = [MediaAction new];
    //        action.ActionType = SSlow;
    //        action.ReverseSeconds = 0 ;
    //        action.IsOverlap = YES;
    //        action.IsMutex = NO;
    //        action.Rate = 0.33333;
    //        action.isOPCompleted = NO;
    //        [manager_ addActionItem:action filePath:nil at:secondsInTrack from:seconds duration:-1];
    //    }
}
-(void)fast:(UIButton *)sender
{
    [manager_ removeGPUFilter];
    CMTime playerTime =  [player_ durationWhen];
    CGFloat seconds = CMTimeGetSeconds(playerTime);
    
    CGFloat secondsInTrack = [manager_ secondsForTrack:seconds];
    
    if (sender.selected) {
        sender.selected = NO;
        MediaActionDo * actionDo = [manager_ findActionAt:secondsInTrack - 0.1 index:-1];
        if(actionDo)
        {
            CGFloat duration = secondsInTrack;// [manager_ getSecondsWithoutAction:seconds];
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
        [manager_ addActionItem:action filePath:nil at:seconds from:seconds duration:-1];
    }
}
#pragma mark - player delegate
- (void)playerSimple:(HCPlayerSimple *)playerSimple timeDidChange:(CGFloat)cmTime
{
    if(playerSimple == rPlayer_)
    {
        [manager_ setPlaySeconds:cmTime isReverse:YES];
    }
    else if(playerSimple == player_)
    {
        [manager_ setPlaySeconds:cmTime isReverse:NO];
        
        [pannel_ setPlayerSeconds:cmTime isReverse:NO];
    }
    
    
}
- (void)playerSimple:(HCPlayerSimple *)playerSimple reachEnd:(CGFloat)end
{
    CGFloat endSeconds = end>0?end:-1;
    if(playerSimple == rPlayer_)
    {
        if(endSeconds<0)
            endSeconds = CMTimeGetSeconds([rPlayer_ durationWhen]);
        NSLog(@"pause in play end");
        [rPlayer_ pause];
        
        [manager_ ensureActions:endSeconds];
        
        //再继续播放
        [self resetAllButtons];
        return ;
    }
    else if(playerSimple == player_)
    {
        if(endSeconds<0)
            endSeconds = CMTimeGetSeconds([player_ durationWhen]);
        //        [player_ seek:0 accurate:YES];
        //        [player_ play];
        NSLog(@"pause in play end");
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
    NSLog(@"*************** generate reverse ok *****************");
    //    baseVideo_ = [manager getBaseVideo];
    
    //    [[VideoGenerater new]showMediaInfo:[manager_ getBaseVideo].filePath];
    
    reverseVideo_ = reverseVideo;
    if(viewShowed_)
    {
        [self buildControls];
    }
    if(player_.playing==NO)
    {
        [player_ seek:0 accurate:YES];
        [player_ play];
    }
    [self hideIndicatorView];
    
}
- (void) showCurrentMediaes:(CGFloat)seconds
{
    NSLog(@"-------------** media at player:%.4f rplayer:%.4f**---------------",[player_ secondsPlaying],[rPlayer_ secondsPlaying]);
    int index = 0;
    NSArray * mediaList = [manager_ getMediaList];
    for (MediaWithAction * item in mediaList) {
        NSLog(@"--%d-- type:%d",index,item.Action.ActionType);
        NSLog(@"%@",[item toString]);
        index ++;
    }
    NSLog(@"**--**--**--**--**--**--**--**--**--**--");
}
//当播放器的内容需要发生改变时
- (void)ActionManager:(ActionManager *)manager play:(MediaWithAction *)mediaToPlay
{
    showTimeChanged_ = YES;
    
    [pannel_ setPlayMedia:mediaToPlay];
    [pannel_ refresh];
    
    if(player_.hidden)
        [rPlayer_ pause];
    else
        [player_ pause];
    
    NSLog(@"mediaItem:%@",[mediaToPlay.fileName lastPathComponent]);
    NSLog(@"mediaItem:%@",[mediaToPlay toString]);
    
    
    
    if(player_.hidden)
        [rPlayer_ play];
    else
        [player_ play];
    
    if(!mediaToPlay)
    {
        [self showCurrentMediaes:-1];
        
        NSLog(@"mediaToPlay:nil");
        return ;
    }
    [self showCurrentMediaes:-1];
    currentMedia_ = mediaToPlay;
}
- (void)ActionManager:(ActionManager *)manager actionChanged:(MediaActionDo *)action type:(int)opType//0 add 1 update 2 remove
{
    showTimeChanged_ = YES;
}

- (void)ActionManager:(ActionManager *)manager generateOK:(NSString *)filePath cover:(NSString *)cover isFilter:(BOOL)isFilter
{
    //    if(!isFilter)
    //    {
    VideoGenerater * vg = [VideoGenerater new];
    [vg showMediaInfo:filePath];
    
    [manager_ setBackMV:filePath begin:0 end:-1 buildReverse:YES];
    
    [manager_ removeActions];
    
    baseVideo_ = [manager_ getBaseVideo];
    
    //    [self buildControls];
    
    //    [player_ play];
    
    
    //    }
    
}
- (void)ActionManager:(ActionManager *)manager genreateFailure:(NSError *)error isFilter:(BOOL)isFilter
{
    [self hideIndicatorView];
}
- (void)ActionManager:(ActionManager *)manager generateProgress:(CGFloat)progress isFilter:(BOOL)isFilter
{
    
}
- (void)reset:(UIButton *)sender
{
    [self showIndicatorView];
    [self resetAllButtons];
    
    player_.key = nil;
    rPlayer_.key = nil;
    [player_ seek:0 accurate:YES];
    [rPlayer_ seek:0 accurate:YES];
    
    [self buildControls];
    
    player_.hidden = NO;
    rPlayer_.hidden = YES;
    
    [player_ pause];
    [rPlayer_ pause];
    [player_ setRate:1];
    
    [manager_ loadOrigin];
    
    [[ActionManager shareObject]resetStates];
    
    //    [manager_ setBackMV:oPath_ begin:0 end:-1 buildReverse:YES];
    baseVideo_ = [manager_ getBaseVideo];
    reverseVideo_ = [manager_ getReverseVideo];
    
    [self buildControls];
    
    [pannel_ refresh];
    
    [player_ play];
}
-(void)join:(UIButton *)sender
{
    [self showIndicatorView];
    
    
    [player_ setRate:1];
    
    NSLog(@"pause in join");
    [player_ pause];
    [rPlayer_ pause];
    
    
    //暂时暂停，用于检查
    //    if([manager_ needGenerateForOP]) return;
    
    
    //    [[VideoGenerater new]showMediaInfo:[manager_ getBaseVideo].filePath];
    if(manager_.isGenerating)
    {
        NSLog(@"正在生成中，不能重入");
        [player_ seek:0 accurate:YES];
        [player_ play];
        return;
    }
    if(![manager_ needGenerateForOP])
    {
        [player_ seek:0 accurate:YES];
        [player_ play];
        return ;
    }
    NSLog(@"generate begin ....");
    
    [self showCurrentMediaes:0];
    
    if(![manager_ generateMVWithWaterMarker:@"watermark_MtvPlus.png" position:MP_RightBottom])
    {
        [player_ seek:0 accurate:YES];
        [player_ play];
        [self hideIndicatorView];
        return;
    }
    else
    {
        NSLog(@"pause in join 2");
        [player_ seek:0 accurate:YES];
        [player_ pause];
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
    if([vg generateMVSegmentsViaFile:oPath_ begin:2 end:10 targetSize:CGSizeMake(100, 100)])
    {
        [vg generateMVFile:nil retryCount:0];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

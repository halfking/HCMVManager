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
    AVAudioPlayer * audioPlayer_;
    
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
    
//    NSString * audioPath  = [[NSBundle mainBundle] pathForResource:@"ywy" ofType:@"mp3"];
//        oPath_ = [[NSBundle mainBundle] pathForResource:@"test2" ofType:@"mp4"];
    oPath_ = [[NSBundle mainBundle]pathForResource:@"test3" ofType:@"MOV"];
//    oPath_ = [[NSBundle mainBundle]pathForResource:@"IMG_0394" ofType:@"mp4"];
//    oPath_ = [[NSBundle mainBundle]pathForResource:@"0-0-1466157642551" ofType:@"mp4"];
//        oPath_ = [[NSBundle mainBundle]pathForResource:@"movie_34948659" ofType:@"m4v"];
    
//    oPath_ = [[NSBundle mainBundle] pathForResource:@"test2" ofType:@"MOV"];
//        oPath_ = [[NSBundle mainBundle]pathForResource:@"up" ofType:@"MOV"];
    //        oPath_ = [[NSBundle mainBundle]pathForResource:@"upset" ofType:@"MOV"];
    //       oPath_ = [[NSBundle mainBundle]pathForResource:@"lanleft" ofType:@"MOV"];
    //        oPath_ = [[NSBundle mainBundle]pathForResource:@"lanright" ofType:@"MOV"];
    
    //   oPath_ = [[NSBundle mainBundle]pathForResource:@"front_up" ofType:@"MOV"];
    //        oPath_ = [[NSBundle mainBundle]pathForResource:@"front_lanright" ofType:@"MOV"];
    
    viewShowed_ = NO;
    [self showIndicatorView];
    if(![manager_ getBaseVideo])
    {
        [manager_ setBackMV:oPath_ begin:0 end:-1 buildReverse:NO];
    }
    manager_.NotAllowAudioTrackEmpty = YES;
//    [manager_ setBackAudio:audioPath begin:-5 end:-1];
    
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
    
    [progress_ setManager:[ActionManager shareObject]];
    
    [self buildControls];

    
    [player_ play];
    
    [progress_ setCurrentMedia:nil];
    [progress_ setPlaySeconds:0 secondsInArray:0];
    
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
        
        [slow_ addTarget:self action:@selector(repeatLong:) forControlEvents:UIControlEventTouchUpInside];
//        [slow_ addTarget:self action:@selector(slow:) forControlEvents:UIControlEventTouchUpInside];
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
        
                [subtract_ addTarget:self action:@selector(subtractMV:) forControlEvents:UIControlEventTouchUpInside];
//        [subtract_ addTarget:self action:@selector(generateFilterItem) forControlEvents:UIControlEventTouchUpInside];
        
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
        
        {
            progress_ = [[ActionManagerProgress alloc]initWithFrame:CGRectMake(10, 20 + playerBottom, self.view.frame.size.width-20,
                                                                               30)];
            progress_.backgroundColor = [UIColor clearColor];
            [self.view addSubview:progress_];
        }
        
        pannel_ = [[ActionManagerPannel alloc]initWithFrame:CGRectMake(10, 50 + playerBottom,
                                                                       self.view.frame.size.width -20,
                                                                       top - 100 - playerBottom)];
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
    [player_ setVideoVolume:0.3];
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
- (void) buildAudioPlayer
{
    //初始化播放器，注意这里的Url参数只能时文件路径，不支持HTTP Url
    if(audioPlayer_)
    {
        [audioPlayer_ pause];
        audioPlayer_ = nil;
    }
    MediaItem * audioItem = [manager_ getBaseAudio];
    if(audioItem && audioItem.fileName)
    {
        NSString * filePath = [[HCFileManager manager]getFilePath:audioItem.fileName];
        NSError * error;
        audioPlayer_ =[[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:filePath]
                                                            error:&error];
        if(error)
        {
            NSLog(@"init audio player error:%@",[error localizedDescription]);
        }
        [audioPlayer_ setVolume:manager_.audioVolume];
        //设置播放器属性
        audioPlayer_.numberOfLoops=0;//设置为0不循环
        //        audioPlayer_.delegate=self;
        [audioPlayer_ prepareToPlay];//加载音频文件到缓存
        [audioPlayer_ setVolume:1];
        
    }
    [manager_ initAudioPlayer:audioPlayer_];
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
    if([manager_ getBaseAudio])
    {
        [self buildAudioPlayer];
    }
    [pannel_ setActionManager:manager_];
    [manager_ initPlayer:player_  audioPlayer:audioPlayer_];
    if([manager_ getFilterView])
    {
        [manager_ changeFilterPlayerItem];
        //        [manager_ setGPUFilter:0];
    }
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
    player_.hidden = NO;
    
    int index = (int)sender.tag - 10000;
    sender.selected = YES;
    
    for (int i = 10000 ;i < 10000+20;i ++) {
        if(i!=index)
        {
            UIButton * btn = (UIButton*)[self.view viewWithTag:i];
            if(btn) btn.selected = NO;
        }
    }
    
    
    if(![manager_ getFilterView])
    {
        [manager_ setFilterIndex:index];
        [player_ pause];
        [manager_ initGPUFilter:player_ in:self.view];
        [player_ play];
    }
    else
    {
        [manager_ setGPUFilter:index];
    }
    
    if(index >=4)
    {
        [manager_ generateMVByFilter:index];
    }
}
- (void) subtractMV:(id)sender
{
    VideoGenerater * vg = [VideoGenerater new];
    vg.forceAddAudioTrack = YES;
    vg.removeAudioWhenSubtractMV = YES;
    [vg setBlock:^(VideoGenerater *queue, CGFloat progress) {
        NSLog(@"video generater progress %.1f",progress);
        
    } ready:^(VideoGenerater *queue, AVPlayerItem *playerItem) {
        NSLog(@"playerItem Ready");
        
    } completed:^(VideoGenerater *queue, NSURL *mvUrl, NSString *coverPath) {
        NSLog(@"generate completed.  %@",[mvUrl path]);
        NSString * fileName = [[HCFileManager manager]getFileNameByTicks:@"subtract.mp4"];
        NSString * filePath = [[HCFileManager manager]localFileFullPath:fileName];
        [HCFileManager copyFile:[mvUrl path] target:filePath overwrite:YES];
        
        [manager_ setBackMV:filePath begin:0 end:-1 buildReverse:NO];
        
//        [player_ changeCurrentItemPath:filePath];
        [NSThread sleepForTimeInterval:0.2];
        [player_ play];
        
    } failure:^(VideoGenerater *queue, NSString *msg, NSError *error) {
        NSLog(@"generate failure:%@ error:%@",msg,[error localizedDescription]);
        
    }];
    
    if([vg generateMVSegmentsViaFile:baseVideo_.filePath begin:0 end:5 targetSize:baseVideo_.renderSize])
    {
        [vg generateMVFile:nil retryCount:0];
    }
}
- (void)generateFilterItem
{
    [manager_ generateMVByFilter:5];
}
#pragma mark - buttons
-(void)repeatLong:(UIButton *)sender
{
    if(manager_.isGenerating) return;
  
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
    
    MediaActionDo * doItem = [manager_ addActionItem:action filePath:nil at:secondsPlaying from:secondsPlaying duration:1];
//    [player_ pause];
//    [audioPlayer_ pause];
    [NSThread sleepForTimeInterval:0.01];
    NSLog(@"1 doitem :%f-%f",doItem.SecondsInArray,doItem.DurationInSeconds);
    doItem = [manager_ addActionItemDo:doItem inArray:doItem.SecondsInArray + doItem.DurationInSeconds changeCurrentAction:NO];
    NSLog(@"2 doitem :%f-%f",doItem.SecondsInArray,doItem.DurationInSeconds);
    [manager_ addActionItemDo:doItem inArray:doItem.SecondsInArray + doItem.DurationInSeconds changeCurrentAction:NO];
//    [player_ play];
//    [audioPlayer_ play];
    
    
}
-(void)repeat:(UIButton *)sender
{
    if(manager_.isGenerating) return;
    //    if([manager_ getFilterView])
    //    [manager_ setGPUFilter:0];
    //    [manager_ removeGPUFilter];
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
    
    if(manager_.isGenerating) return;
//    [manager_ cancelGenerate];
    //    if([manager_ getFilterView])
    //        [manager_ setGPUFilter:0];
    
    CMTime playerTime =  [player_.playerItem currentTime];
    CGFloat seconds = CMTimeGetSeconds(playerTime);
    
//    //    CMTime reverSeconds = [rPlayer_.playerItem currentTime];
//    //    CMTime reverDuration = [rPlayer_.playerItem duration];
//    
    CGFloat secondsInTrack = [manager_ getSecondsInArrayViaCurrentState:seconds];
//
//    MediaAction * action = [MediaAction new];
//    action.ActionType = SReverse;
//    action.ReverseSeconds = 0;
//    action.IsOverlap = NO;
//    action.IsMutex = NO;
//    action.isOPCompleted = YES;
//    action.Rate = -1;
//    action.IsReverse = YES;
//    
////    NSLog(@"** add action at seconds:%f",seconds);
//    currentAction_ = [manager_ addActionItem:action filePath:nil at:seconds from:seconds duration:1];
//    return;
    
    [player_ pause];
    if (!sender.selected) {
        NSLog(@"#######reverse:%.4f  trackseconds:%.4f",seconds,secondsInTrack);
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        action.ReverseSeconds = 0;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.isOPCompleted = NO;
        action.Rate = -1;
        action.IsReverse = YES;
        
        
        currentAction_ = [manager_ addActionItem:action filePath:nil at:seconds from:seconds duration:-1];
        if(currentAction_){
            sender.selected = YES;
        }
        
        
    } else {
        sender.selected = NO;
        [player_ pause];
        
        secondsInTrack = [manager_ getSecondsInArrayViaCurrentState:seconds];
        
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
            CGFloat duration = actionDo.Rate <0?secondsInTrack- actionDo.SecondsInArray:seconds - actionDo.Media.secondsBegin;
            //            CGFloat duration = CMTimeGetSeconds(reverSeconds) - actionDo.Media.secondsBegin;
            
            //            CGFloat playerPos = CMTimeGetSeconds(reverDuration)-CMTimeGetSeconds(reverSeconds);
            //            CGFloat end = [manager_ getSecondsInArrayFromPlayer:playerPos isReversePlayer:actionDo.IsReverse];
            //            CGFloat duration = end - playerPos;
            
            NSLog(@"#######reverse:%.4f  trackseconds:%.4f duration:%.2f",seconds,secondsInTrack,duration);
            [manager_ setActionItemDuration:actionDo duration:duration];
        }
        
    }
}
-(void)slow:(UIButton *)sender
{
    if(manager_.isGenerating) return;
    //    if([manager_ getFilterView])
    //    [manager_ setGPUFilter:0];
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
    if(manager_.isGenerating ) return;
    //    if([manager_ getFilterView])
    //    [manager_ setGPUFilter:0];
    //    [manager_ removeGPUFilter];
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
//    NSLog(@"player seconds:%f",cmTime);
//    if(playerSimple == player_)
//    {
//        [player_ pause];
        [pannel_ setPlayerSeconds:cmTime isReverse:NO];
        
        CGFloat secondsInArray = [manager_ getSecondsInArrayViaCurrentState:cmTime];
        
        [progress_ setPlaySeconds:cmTime secondsInArray:secondsInArray];
        
//        [player_ play];
        
        [manager_ setPlaySeconds:cmTime];
        
//    }
}
- (void)playerSimple:(HCPlayerSimple *)playerSimple reachEnd:(CGFloat)end
{
    CGFloat endSeconds = end>0?end:-1;
    
    if(endSeconds<0)
        endSeconds = CMTimeGetSeconds([player_ durationWhen]);
    NSLog(@"pause in play end");
    [player_ pause];
    [manager_ setPlayerReachEnd:endSeconds];
    
    //自动结束没有结束的动作
    [manager_ ensureActions:endSeconds];
    
    [self resetAllButtons];
    
    [self join:nil];
}
- (void)playerSimple:(HCPlayerSimple *)playerSimple reachBeginByReverse:(CGFloat)begin
{
    [manager_ ensureActions:begin];
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
//    NSLog(@"-------------** media at player:%.4f rplayer:%.4f**---------------",[player_ secondsPlaying],[rPlayer_ secondsPlaying]);
//    int index = 0;
//    NSArray * mediaList = [manager_ getMediaList];
//    for (MediaWithAction * item in mediaList) {
//        NSLog(@"--%d-- type:%d",index,item.Action.ActionType);
//        NSLog(@"%@",[item toString]);
//        index ++;
//    }
//    NSLog(@"**--**--**--**--**--**--**--**--**--**--");
}
//当播放器的内容需要发生改变时
- (void)ActionManager:(ActionManager *)manager play:(MediaWithAction *)mediaToPlay
{
    [player_ pause];
    [NSThread sleepForTimeInterval:0.01];
    [player_ pause];
    showTimeChanged_ = YES;
    
    [pannel_ refresh];
    [pannel_ setPlayMedia:mediaToPlay];
    [player_ pause];
    
    
    [progress_ setCurrentMedia:mediaToPlay];
    
    
//    NSLog(@"mediaItem:%@",[mediaToPlay.fileName lastPathComponent]);
//    NSLog(@"mediaItem:%@",[mediaToPlay toString]);
    NSLog(@"**player:%.2f playeritem:%f media:%.2f",[player_ secondsPlaying], CMTimeGetSeconds(player_.playerItem.currentTime),mediaToPlay.secondsBegin);
    
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
    
    [manager_ setBackMV:filePath begin:0 end:-1 buildReverse:NO];
    
    [manager_ removeActions];
    
    baseVideo_ = [manager_ getBaseVideo];
    
    //    [manager_ getFilterView].hidden = YES;
    
    //    [self buildControls];
    [player_ seek:0 accurate:YES];
    [player_ play];
    
    
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
//    [rPlayer_ seek:0 accurate:YES];
    
    [progress_ setCurrentMedia:nil];
    [progress_ setPlaySeconds:0 secondsInArray:0];
    
    //    [self buildControls];
    
    player_.hidden = NO;
    
    [player_ pause];
    
    [player_ setRate:1];
    
    [manager_ loadOrigin];
    
    [[ActionManager shareObject]resetStates];
    
    //    [manager_ setBackMV:oPath_ begin:0 end:-1 buildReverse:YES];
    baseVideo_ = [manager_ getBaseVideo];
//    reverseVideo_ = [manager_ getReverseVideo];
    
    [manager_ initAudioPlayer:audioPlayer_];
    //    [self buildControls];
    
    [progress_ setCurrentMedia:nil];
    [progress_ setPlaySeconds:0 secondsInArray:0];
    
    [pannel_ refresh];
    
    [player_ play];
}
-(void)join:(UIButton *)sender
{
//    [player_ pause];
//    [player_ seek:0 accurate:YES];
//    
//    [progress_ setCurrentMedia:nil];
//    [progress_ setPlaySeconds:0 secondsInArray:0];
//    [progress_ refresh];
//    [manager_ setCurrentMediaWithAction:nil];
//    [pannel_ refresh];
//    [player_ play];
//    return;
    
    [self showIndicatorView];
    
    
    [player_ setRate:1];
    
    NSLog(@"pause in join");
    [player_ pause];
    [audioPlayer_ pause];
    
    
    if(![manager_ needGenerateForOP])
    {
        [player_ seek:0 accurate:YES];
        [player_ play];
        return ;
    }
    //    [[VideoGenerater new]showMediaInfo:[manager_ getBaseVideo].filePath];
    if(manager_.isGenerating)
    {
        NSLog(@"正在生成中，不能重入");
//        [player_ seek:0 accurate:YES];
//        [player_ play];
        return;
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
//        [manager_ setBackAudio:nil begin:0 end:0];
//        [manager_ initAudioPlayer:nil];
        
        NSLog(@"pause in join 2");
        [player_ pause];
        [player_ seek:0 accurate:YES];
        [progress_ reset];
        
    }
    
}
//- (void)subtractMV
//{
//    VideoGenerater * vg = [VideoGenerater new];
//    vg.forceAddAudioTrack = YES;
//    [vg setBlock:^(VideoGenerater *queue, CGFloat progress) {
//        NSLog(@"progress %f",progress);
//    } ready:^(VideoGenerater *queue, AVPlayerItem *playerItem) {
//        NSLog(@"playerItem Ready");
//        
//    } completed:^(VideoGenerater *queue, NSURL *mvUrl, NSString *coverPath) {
//        NSLog(@"generate completed.  %@",[mvUrl path]);
//        NSString * fileName = [[HCFileManager manager]getFileNameByTicks:@"subtract.mp4"];
//        NSString * filePath = [[HCFileManager manager]localFileFullPath:fileName];
//        [HCFileManager copyFile:[mvUrl path] target:filePath overwrite:YES];
//        
//        [self hideIndicatorView];
//        
//    } failure:^(VideoGenerater *queue, NSString *msg, NSError *error) {
//        NSLog(@"generate failure:%@ error:%@",msg,[error localizedDescription]);
//        [self hideIndicatorView];
//    }];
//    if([vg generateMVSegmentsViaFile:oPath_ begin:2 end:10 targetSize:CGSizeMake(100, 100)])
//    {
//        [vg generateMVFile:nil retryCount:0];
//    }
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

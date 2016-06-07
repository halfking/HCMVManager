//
//  FirstViewController.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/10.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "FirstViewController.h"
#import <hccoren/base.h>
#import "MediaAction.h"
#import "MediaActionDo.h"
#import "ActionManager.h"
#import "MediaWithAction.h"
#import "WTPlayerResource.h"
#import "ActionManager(player).h"
#import "ActionManager(index).h"
#import "ActionManagerPannel.h"
#import "MediaEditManager.h"
#import "VideoGenerater.h"
#import "testPlayerVC.h"
#import "MediaActionForReverse.h"
#import "ActionManagerProgress.h"
@interface FirstViewController ()<ActionManagerDelegate,WTPlayerResourceDelegate,VideoGeneraterDelegate>

@end

@implementation FirstViewController
{
    MediaActionDo * testAction_;
    UIScrollView * imagesContainer_;
    int kThumbImageTag_;
    ActionManagerPannel * pannel_;
    
    ActionManagerProgress * progress_;
    
    NSTimer * playerTimer_;
    CGFloat playerSeconds_;
    int clickIndex_;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    CGFloat left = 20;
    CGFloat top = 20;
    
    {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(left, top, 54, 44);
        btn.backgroundColor = [UIColor blueColor];
        [btn setTitle:@"Click" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(clickTest:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        left += 54+10;
    }
    {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(left, top, 74, 44);
        btn.backgroundColor = [UIColor blueColor];
        [btn setTitle:@"longtouch" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(testLongTouch:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        left += 74+10;
    }
    {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(left, top, 54, 44);
        btn.backgroundColor = [UIColor blueColor];
        [btn setTitle:@"Rap" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(TestRap:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        left += 54+10;
    }
    {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(left, top, 54, 44);
        btn.backgroundColor = [UIColor blueColor];
        [btn setTitle:@"Shake" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(testShake:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        left += 54+10;
    }
    {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(left, top, 54, 44);
        btn.backgroundColor = [UIColor blueColor];
        [btn setTitle:@"SQ" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(testShackQuick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
    left = 20;
    top += 54;
    {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(left, top, 74, 44);
        btn.backgroundColor = [UIColor blueColor];
        [btn setTitle:@"testtime" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(testTime:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        left += 84;
    }
    {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(left, top, 64, 44);
        btn.backgroundColor = [UIColor blueColor];
        [btn setTitle:@"reset" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(resetClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        left += 74;
    }
    {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(left, top, 100, 44);
        btn.backgroundColor = [UIColor blueColor];
        [btn setTitle:@"clear" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(thumnates:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        left += 110;
    }
    
    {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(left, top, 100, 44);
        btn.backgroundColor = [UIColor blueColor];
        [btn setTitle:@"merge files" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(mergerFiles:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
    
    {
        imagesContainer_ = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 150, self.view.frame.size.width, 100)];
        imagesContainer_.backgroundColor = [UIColor grayColor];
        [self.view addSubview:imagesContainer_];
        kThumbImageTag_ = 20000;
    }
    {
        progress_ = [[ActionManagerProgress alloc]initWithFrame:CGRectMake(0, 150, self.view.frame.size.width,
                                                                           50)];
        progress_.backgroundColor = [UIColor clearColor];
        [self.view addSubview:progress_];
    }
    {
        pannel_ = [[ActionManagerPannel alloc]initWithFrame:CGRectMake(0, 200,
                                                                       self.view.frame.size.width,
                                                                       self.view.frame.size.height - 200)];
        pannel_.backgroundColor = [UIColor grayColor];
        [self.view addSubview:pannel_];
    }
    
    [self buildBaseData];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [ActionManager shareObject].delegate = self;
    
    [pannel_ refresh];
    [progress_ setManager:[ActionManager shareObject]];
}
- (void)buildBaseData
{
    
    ActionManager * manager = [ActionManager shareObject];
    manager.delegate = self;
//        NSString * path = [[NSBundle mainBundle]pathForResource:@"test2" ofType:@"mp4"];
    NSString * path = [[NSBundle mainBundle]pathForResource:@"test2" ofType:@"MOV"];
    //    NSString * path = [[NSBundle mainBundle]pathForResource:@"up" ofType:@"MOV"];
    //    NSString * path = [[NSBundle mainBundle]pathForResource:@"upset" ofType:@"MOV"];
    //    NSString * path = [[NSBundle mainBundle]pathForResource:@"lanleft" ofType:@"MOV"];
    //    NSString * path = [[NSBundle mainBundle]pathForResource:@"lanright" ofType:@"MOV"];
    //        NSString * path = [[NSBundle mainBundle]pathForResource:@"front_up" ofType:@"MOV"];
    //        NSString * path = [[NSBundle mainBundle]pathForResource:@"front_lanright" ofType:@"MOV"];
    if(![manager getBaseVideo])
    {
        [manager setBackMV:path begin:0 end:-1 buildReverse:NO];
    }
    [pannel_ setActionManager:manager];
    [pannel_ refresh];
    
}
#pragma  mark - buutons
- (void)resetClick:(id)sender
{
    if(playerTimer_)
    {
        [playerTimer_ invalidate];
        playerTimer_ = nil;
    }
    [[ActionManager shareObject]loadOrigin];
    playerSeconds_ = 0;
    clickIndex_ =0;
    [pannel_ refresh];
    
    [progress_ reset];
    [progress_ refresh];
    
}
- (void)clickTest:(id)sender
{
    if(playerTimer_)
    {
        [playerTimer_ invalidate];
        playerTimer_ = nil;
    }
    MediaActionDo * acdo = nil;
    ActionManager * manager = [ActionManager shareObject];
    
    if(clickIndex_ ==0){
        MediaAction * action = [MediaAction new];
        action.ActionType = SSlow;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = YES;
        action.IsMutex = NO;
        action.Rate = 0.3333333;
        action.isOPCompleted = YES;
        acdo =  [manager addActionItem:action filePath:nil at:1 from:1 duration:1];
    }
    
    if(clickIndex_ ==1){
        MediaAction * action = [MediaAction new];
        action.ActionType = SFast;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = YES;
        action.IsMutex = NO;
        action.Rate = 2;
        action.isOPCompleted = YES;
        acdo =  [manager addActionItem:action filePath:nil at:1.5 from:1.5 duration:2];
    }
    
    
    if(clickIndex_ ==2){
        MediaAction * action = [MediaAction new];
        action.ActionType = SRepeat;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = 1;
        action.isOPCompleted = YES;
        [manager addActionItem:action filePath:nil at:5 from:5 duration:1];
    }
    if(clickIndex_ ==3){
        MediaAction * action = [MediaAction new];
        action.ActionType = SRepeat;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = 1;
        action.isOPCompleted = YES;
        [manager addActionItem:action filePath:nil at:5 from:5 duration:1];
    }
    if(clickIndex_ ==4){
        MediaAction * action = [MediaAction new];
        action.ActionType = SRepeat;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = 1;
        action.isOPCompleted = YES;
        [manager addActionItem:action filePath:nil at:6 from:5 duration:1];
    }
    if(clickIndex_ ==5){
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = 1;
        action.isOPCompleted = YES;
        acdo =  [manager addActionItem:action filePath:nil at:8 from:8 duration:1];
    }
    
    if(clickIndex_ ==6){
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = 1;
        action.isOPCompleted = YES;
        acdo =  [manager addActionItem:action filePath:nil at:9 from:9 duration:1];
    }
    
    CGFloat lastSeconds = [manager getBaseVideo].secondsDuration;
    if(clickIndex_ ==7){
        MediaAction * action = [MediaAction new];
        action.ActionType = SFast;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = YES;
        action.IsMutex = NO;
        action.Rate = 2;
        action.isOPCompleted = YES;
        acdo =  [manager addActionItem:action filePath:nil at:lastSeconds - 0.5 from:lastSeconds- 0.5 duration:2];
    }
    clickIndex_ ++;
    if(clickIndex_ >7)
    {
        clickIndex_ = 0;
    }
}
- (void)testLongTouch:(id)sender
{
    if(playerTimer_)
    {
        [playerTimer_ invalidate];
        playerTimer_ = nil;
    }
    ActionManager * manager = [ActionManager shareObject];
    
    if(clickIndex_ ==0){
        MediaAction * action = [MediaAction new];
        action.ActionType = SSlow;
        action.ActionTitle = @"slow";
        action.ReverseSeconds = 0;
        action.DurationInSeconds = 1;
        action.Rate = 0.333333;
        action.IsMutex = NO;
        action.IsFilter = NO;
        
        testAction_ = [manager addActionItem:action filePath:nil at:1 from:1 duration:-1];
    }
    if(clickIndex_ ==1)
    {
        [manager setActionItemDuration:testAction_ duration:2.5];
    }
    if(clickIndex_ ==2){
        MediaAction * action = [MediaAction new];
        action.ActionType = SFast;
        action.ActionTitle = @"fast";
        action.ReverseSeconds = 0;
        action.DurationInSeconds = 1;
        action.Rate = 2;
        action.IsMutex = NO;
        action.IsFilter = NO;
        
        testAction_ = [manager addActionItem:action filePath:nil at:3.5 from:3.5 duration:-1];
    }
    if(clickIndex_ ==3)
        [manager setActionItemDuration:testAction_ duration:2];
    
    
    
    if(clickIndex_ ==4){
        MediaAction * action = [MediaAction new];
        action.ActionType = SSlow;
        action.ActionTitle = @"fast";
        action.ReverseSeconds = 0;
        action.DurationInSeconds = 1;
        action.Rate = 0.333333;
        action.IsMutex = NO;
        action.IsFilter = NO;
        
        testAction_ = [manager addActionItem:action filePath:nil at:4.5 from:4.5 duration:-1];
    }
    if(clickIndex_ ==5)
        [manager setActionItemDuration:testAction_ duration:1];
    
    
    if(clickIndex_ ==6){
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = -1;
        action.isOPCompleted = NO;
        testAction_ = [manager addActionItem:action filePath:nil at:6 from:6 duration:-1];
        
        {
            int index = 0;
            for (MediaWithAction * item  in [manager getMediaList]) {
                NSLog(@"AM : %d - %@",index,[item toString]);
                index ++;
            }
        }
    }
   
    if(clickIndex_ ==7)
    {
        [manager setActionItemDuration:testAction_ duration:2];
        {
            int index = 0;
            for (MediaWithAction * item  in [manager getMediaList]) {
                NSLog(@"AM : %d - %@",index,[item toString]);
                index ++;
            }
        }
    }
    if(clickIndex_ ==8){
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = -1;
        action.isOPCompleted = NO;
        testAction_ = [manager addActionItem:action filePath:nil at:7 from:7 duration:-1];
        {
            int index = 0;
            for (MediaWithAction * item  in [manager getMediaList]) {
                NSLog(@"AM : %d - %@",index,[item toString]);
                index ++;
            }
        }
    }
    
    if(clickIndex_ ==9)
    {
        [manager setActionItemDuration:testAction_ duration:1];
        {
            int index = 0;
            for (MediaWithAction * item  in [manager getMediaList]) {
                NSLog(@"AM : %d - %@",index,[item toString]);
                index ++;
            }
        }
    }
    if(clickIndex_ ==10){
        MediaAction * action = [MediaAction new];
        action.ActionType = SFast;
        
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = 2;
        action.isOPCompleted = NO;
        testAction_ = [manager addActionItem:action filePath:nil at:8 from:8 duration:-1];
        {
            int index = 0;
            for (MediaWithAction * item  in [manager getMediaList]) {
                NSLog(@"AM : %d - %@",index,[item toString]);
                index ++;
            }
        }
    }
    if(clickIndex_ ==11)
        [manager ensureActions:[manager getBaseVideo].secondsDuration];
    //    [manager setActionItemDuration:testAction_ duration:[manager getBaseVideo].secondsDuration - 7];
    clickIndex_ ++;
//    if(clickIndex_ >11)
//        clickIndex_ = 0;
    [pannel_ refresh];
}
- (void)TestRap:(id)sender
{
    if(playerTimer_)
    {
        [playerTimer_ invalidate];
        playerTimer_ = nil;
    }
    ActionManager * manager = [ActionManager shareObject];
    
    
    if(clickIndex_ ==0){
        MediaAction * action = [MediaAction new];
        action.ActionType = SRepeat;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = 1;
        action.isOPCompleted = YES;
        testAction_ = [manager addActionItem:action filePath:nil at:5 from:5 duration:0.5];
    }
    if(clickIndex_ ==1)
        [manager addActionItemDo:testAction_ at:6];
    if(clickIndex_ ==2)
        [manager addActionItemDo:testAction_ at:7];
    
    if(clickIndex_ ==3)
        [manager addActionItemDo:testAction_ at:4.8];
    
    if(clickIndex_ ==4){
        MediaAction * action = [MediaAction new];
        action.ActionType = SRepeat;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = 1;
        action.isOPCompleted = YES;
        testAction_ = [manager addActionItem:action filePath:nil at:8 from:5 duration:1];
    }
    if(clickIndex_ ==5)
        [manager addActionItemDo:testAction_ at:9];
    
    
    //test last action
    CGFloat lastSeconds = [manager getBaseVideo].secondsDuration;
    if(clickIndex_ ==6){
        MediaAction * action = [MediaAction new];
        action.ActionType = SRepeat;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = 1;
        action.isOPCompleted = YES;
        testAction_ = [manager addActionItem:action filePath:nil at:lastSeconds - 0.5 from:lastSeconds - 0.5 duration:1];
    }
    clickIndex_ ++;
    if(clickIndex_>6)
        clickIndex_ = 0;
    //    [manager ensureActions:[manager getBaseVideo].secondsDuration];
    [pannel_ refresh];
}
- (void)testShake:(id)sender
{
    if(playerTimer_)
    {
        [playerTimer_ invalidate];
        playerTimer_ = nil;
    }
    ActionManager * manager = [ActionManager shareObject];
    
    //    [manager setActionItemDuration:testAction_ duration:2];
    
    
    if(clickIndex_ ==0){
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = -1;
        action.isOPCompleted = YES;
        testAction_ = [manager addActionItem:action filePath:nil at:2.5 from:2.5 duration:2];
    }
    
    if(clickIndex_ ==1) {
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = -1;
        action.isOPCompleted = YES;
        testAction_ = [manager addActionItem:action filePath:nil at:4.5 from:4.5 duration:2];
    }
    
    
    if(clickIndex_ ==2){
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = -1;
        action.isOPCompleted = NO;
        testAction_ = [manager addActionItem:action filePath:nil at:6 from:6 duration:-1];
    }
    if(clickIndex_ ==3)
        [manager setActionItemDuration:testAction_ duration:3];
    
    //test interrect
    if(clickIndex_ ==4){
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = -1;
        action.isOPCompleted = YES;
        testAction_ = [manager addActionItem:action filePath:nil at:5 from:5 duration:1];
    }
    
    if(clickIndex_ ==5){
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = -1;
        action.isOPCompleted = NO;
        testAction_ = [manager addActionItem:action filePath:nil at:8 from:8 duration:-1];
    }
    if(clickIndex_ ==6)
        [manager ensureActions:[manager getBaseVideo].secondsDuration];
    
    clickIndex_ ++;
    if(clickIndex_>6) clickIndex_ = 0;
    [pannel_ refresh];
}
//player times
- (void)testTime:(id)sender
{
    playerSeconds_  = 0;
    clickIndex_ = 0;
    if(playerTimer_)
    {
        [playerTimer_ invalidate];
        playerTimer_ = nil;
    }
    
    [[ActionManager shareObject]setCurrentMediaWithAction:nil];
    [[ActionManager shareObject]setPlaySeconds:0];
    [progress_ setCurrentMedia:nil];
    [progress_ setPlaySeconds:0 secondsInArray:0];
    
    playerTimer_ = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timeChanged:) userInfo:nil repeats:YES];
}
- (void)timeChanged:(NSTimer *)timer
{
    
    ActionManager * manager = [ActionManager shareObject];
    MediaWithAction * currentMedia = [manager getCurrentMediaWithAction];
//    CGFloat secondsInArray = [manager getSecondsInArrayViaCurrentState:playerSeconds_];
//    if(secondsInArray>=3.2) return;
    if(currentMedia && currentMedia.rateBeforeReverse <0)
        playerSeconds_ -= 0.1;
    else
        playerSeconds_ += 0.1;
    
    
    
    if(playerSeconds_ >= [manager getBaseVideo].secondsDuration)
    {
        [playerTimer_ invalidate];
        playerTimer_ = nil;
    }
    [pannel_ setPlayerSeconds:playerSeconds_ isReverse:NO];
    CGFloat secondsInArray = [manager getSecondsInArrayViaCurrentState:playerSeconds_];
    
    [progress_ setPlaySeconds:playerSeconds_ secondsInArray:secondsInArray];
    
    [manager setPlaySeconds:playerSeconds_ ];
}
- (void)testShackQuick:(id)sender
{
    if(playerTimer_)
    {
        [playerTimer_ invalidate];
        playerTimer_ = nil;
    }
    ActionManager * manager = [ActionManager shareObject];
    
    //    [manager setActionItemDuration:testAction_ duration:2];
    
    
    if(clickIndex_ ==0){
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = -1;
        action.isOPCompleted = YES;
        testAction_ = [manager addActionItem:action filePath:nil at:1.5 from:1.5 duration:1];
    }
    
    if(clickIndex_ ==1) {
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = -1;
        action.isOPCompleted = YES;
        [manager setCurrentMediaWithAction:(MediaWithAction *)((MediaActionForReverse*)testAction_).normalMedia];
        testAction_ = [manager addActionItem:action filePath:nil at:1.2 from:1.2 duration:2];
    }
    if(clickIndex_ ==2) {
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = -1;
        action.isOPCompleted = YES;
        testAction_ = [manager addActionItem:action filePath:nil at:1.9 from:1.9 duration:1];
    }
    if(clickIndex_ ==3) {
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = -1;
        action.isOPCompleted = YES;
        testAction_ = [manager addActionItem:action filePath:nil at:1.8 from:1.8 duration:1];
    }
    if(clickIndex_ ==4) {
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = -1;
        action.isOPCompleted = YES;
        [manager setCurrentMediaWithAction:(MediaWithAction *)((MediaActionForReverse*)testAction_).normalMedia];
        
        testAction_ = [manager addActionItem:action filePath:nil at:1.6 from:1.6 duration:1];
    }
    clickIndex_ ++;
    if(clickIndex_>5)
    {
        clickIndex_ = 0;
        [manager removeActions];
        
    }
    [pannel_ refresh];
    [pannel_ setPlayMedia:[manager getCurrentMediaWithAction]];
}
- (void)thumnates:(id)sender
{
//    MediaWithAction * media = [(MediaWithAction *)[[[ActionManager shareObject]getMediaList]firstObject]copyItem];
//    media.begin = CMTimeMakeWithSeconds(4.5, media.begin.timescale);
//    media.playRate = -1;
//    media.end = CMTimeMakeWithSeconds(4.4, media.end.timescale);
//    [[ActionManager shareObject]generateMediaFile:media];
//    
//    return;
    ActionManager * manager = [ActionManager shareObject];
    MediaItem * item = [manager getBaseVideo];
    if(!item)
    {
        NSLog(@"not item .");
        return ;
    }
    
//    CGFloat width_ = self.view.frame.size.width - 20;
//    CGFloat maxValue_ = 0.9; //最多可以滑到哪里，最多点屏幕的90%
//    int step = 3;//共15秒，5张图，3秒一个
//    int imageCountInView = 5;
//    float temp = round(item.secondsDuration / 3.0 * 10) / 10.0f;
//    int count = item.secondsDuration / 3.0;
//    if (temp > count + 0.1) {
//        count++;
//    }
//    //    CGFloat scale = [DeviceConfig config].Scale;
//    //    width_ *= scale;
//    CGSize size = CGSizeMake((width_ * maxValue_ / imageCountInView), (width_ * maxValue_ / imageCountInView));
//    
//    size.width = (int)(size.width * 10 + 0.5)/10;
//    size.height = (int)(size.height * 10+0.5)/10;
//    
//    CGSize displaySize = size;
//    //    CGSize displaySize = CGSizeMake(size.width/scale, size.height/scale);
//    
//    //        __block int tempIndex = 0;
//    [[WTPlayerResource sharedWTPlayerResource] getVideoThumbs:item.url
//     //                                                      alAsset:nil
//                                       targetThumnateFileName:@"videoThumb"
//                                                        begin:0 andEnd:-1
//                                                      andStep:step
//                                                     andCount:count
//                                                      andSize:size
//                                                     callback:^(CMTime requestTime, NSString *path, NSInteger index) {
//                                                         [self changeImageViewContent:path index:index size:displaySize];
//                                                         
//                                                     } completed:^(CMTime requestTime, NSString *path, NSInteger index) {
//                                                         
//                                                     } failure:^(CMTime requestTime, NSError *error, NSString *filePath) {
//                                                     }];
//    
    [manager clear:YES];
    [manager setBackMV:item buildReverse:YES];
    [NSThread sleepForTimeInterval:1];
    [manager clear:YES];
    [manager setBackMV:item buildReverse:YES];
}
- (void) changeImageViewContent:(NSString *)path index:(NSInteger)index size:(CGSize)size
{
    if([NSThread isMainThread])
    {
        UIImageView * imageView = [imagesContainer_ viewWithTag:(kThumbImageTag_ + index)];
        if (!imageView) {
            imageView = [[UIImageView alloc]initWithFrame:CGRectMake(size.width * index, 0, size.width, size.height)];
            [imagesContainer_ addSubview:imageView];
        }
        [imageView setImage:[UIImage imageWithContentsOfFile:path]];
        index ++;
        if(imagesContainer_.contentSize.width < index* size.width)
        {
            imagesContainer_.contentSize = CGSizeMake(index * size.width, size.height);
        }
        //        NSLog(@"video thumb path %@ index %d",path,(int)index);
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self changeImageViewContent:path index:index size:size];
        });
    }
}
- (void)mergerFiles:(id)sender
{
    testPlayerVC * vc = [[testPlayerVC alloc]initWithNibName:nil bundle:nil];
    [self presentViewController:vc animated:YES completion:^{
        
    }];
    return;
    
//    {
//        beginInFile = 0;
//        endInFile = "5.003334";
//        endInTrack = "5.003334";
//        filename = "recordfiles/movie_26845112.m4v";
//        index = 1;
//        secondsDurationInArray = "5.003334";
//        secondsInTrack = 0;
//        type = 0;
//    },
//    {
//        beginInFile = 0;
//        endInFile = "8.74";
//        endInTrack = "13.74333";
//        filename = "recordfiles/movie_26855310.m4v";
//        index = 1;
//        secondsDurationInArray = "8.74";
//        secondsInTrack = "5.003334";
//        type = 0;
//    }
    
    
    NSString * path1 = [[NSBundle mainBundle]pathForResource:@"a" ofType:@"m4v"];
    NSString * path2 = [[NSBundle mainBundle]pathForResource:@"b" ofType:@"m4v"];
    
    
    MediaEditManager * manager = [MediaEditManager shareObject];
    
    [manager clearFiles];
    [manager clear];
    
    [manager setVideoOrietation:UIDeviceOrientationPortrait renderSize:CGSizeMake(720, 1280) withFontCamera:NO];
    manager.NotAddCover = YES;
    manager.delegate = self;
    
    
    int index = 0;
    NSArray * videoFiles = [NSArray arrayWithObjects:path1,path2, nil];
    CGFloat secondsInArray2 =0;
    for (NSString * filePath in videoFiles) {
        MediaItem * item = [manager addMediaItemWithFile:filePath atIndex:index indicatorPos:secondsInArray2];
        item.playRate = 1;
        
        secondsInArray2 += item.secondsDurationInArray;
        index ++;
    }
    manager.addWaterMark = NO;
    manager.addLyricLayer = NO;
    [manager setTimeForMerge:0 end:13.73];
    
//    if(![manager recheckGenerateQueue])
//    {
//        NSLog(@"check failure.");
//    }
    [manager joinMedias:0];

    
    
}

#pragma mark - delegate
- (void)VideoGenerater:(VideoGenerater *)queue generateProgress:(CGFloat)progress
{
    NSLog(@"progress.....%.2f",progress);
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (self.ShareDelegae && [self.ShareDelegae respondsToSelector:@selector(SettingCaptureJoinProgress:)]) {
//            [self.ShareDelegae SettingCaptureJoinProgress:progress];
//        }
//    });
}
- (void)VideoGenerater:(VideoGenerater *)queue didGenerateFailure:(NSString *)msg error:(NSError *)error
{
    NSLog(@"generate failure:%@",msg);
    
        NSArray * trackList = [queue getMediaTrackList];
        NSLog(@"mediatracklist:%@",trackList);
    
    
//    self.FinalPath = nil;
//    isGenerating_ = NO;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (self.ShareDelegae && [self.ShareDelegae respondsToSelector:@selector(SettingCaptureJoinFail:error:)]) {
//            [self.ShareDelegae SettingCaptureJoinFail:self error:error];
//        }
//    });
    
    
}
- (void)VideoGenerater:(VideoGenerater *)queue didGenerateCompleted:(NSURL *)fileUrl cover:(NSString *)cover
{
//    isGenerating_ = NO;
//    self.FinalPath = [fileUrl path];
//    // [self generateCover];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (self.ShareDelegae && [self.ShareDelegae respondsToSelector:@selector(SettingCaptureJoinCompleted:)]) {
//            [self.ShareDelegae SettingCaptureJoinCompleted:self];
//        }
//    });
}
#pragma mark - action manager delgates
- (void)ActionManager:(ActionManager *)manager reverseGenerated:(MediaItem *)reverseVideo
{
    [manager saveDraft];
}
- (void)ActionManager:(ActionManager *)manager play:(MediaWithAction *)mediaToPlay
{
    [pannel_ refresh];
    [pannel_ setPlayMedia:mediaToPlay];
    
    [progress_ setCurrentMedia:mediaToPlay];
    
    playerSeconds_ = mediaToPlay.secondsBeginBeforeReverse;
    
    if(testAction_)
        testAction_.mediaToPlay = mediaToPlay;
    
    NSLog(@"mediaItem1:%@",[mediaToPlay.fileName lastPathComponent]);
    NSLog(@"mediaItem1:%@",[mediaToPlay toString]);
}
- (void)ActionManager:(ActionManager *)manager doProcessOK:(NSArray *)mediaList duration:(CGFloat)duration
{
    NSLog(@"-------------**----**--------------------");
    NSLog(@"duration:%.2f",duration);
    //    NSLog(@"** playerSeconds:7 track seconds:%.2f",[[ActionManager shareObject]getSecondsWithoutAction:7]);
    //    NSLog(@"** playerSeconds:10 track seconds:%.2f",[[ActionManager shareObject]getSecondsWithoutAction:10]);
    int index = 0;
    for (MediaWithAction * item in mediaList) {
        NSLog(@"--%d--",index);
        NSLog(@"%@",[item toString]);
        index ++;
    }
    NSLog(@"**--**--**--**--**--**--**--**--**--**--");
}
- (void)ActionManager:(ActionManager *)manager actionChanged:(MediaActionDo *)action type:(int)opType
{
    NSLog(@"** change actions:%@ type:%d",action.ActionTitle,opType);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

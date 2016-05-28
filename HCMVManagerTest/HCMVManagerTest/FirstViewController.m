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

@interface FirstViewController ()<ActionManagerDelegate,WTPlayerResourceDelegate>

@end

@implementation FirstViewController
{
    MediaActionDo * testAction_;
    UIScrollView * imagesContainer_;
    int kThumbImageTag_;
    ActionManagerPannel * pannel_;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(20, 20, 64, 44);
        btn.backgroundColor = [UIColor blueColor];
        [btn setTitle:@"add" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(addItem:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
    {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(104, 20, 64, 44);
        btn.backgroundColor = [UIColor blueColor];
        [btn setTitle:@"begin" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(beginLongTouch:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
    {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(204, 20, 64, 44);
        btn.backgroundColor = [UIColor blueColor];
        [btn setTitle:@"end" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(endLongTouch:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
    {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(304, 20, 64, 44);
        btn.backgroundColor = [UIColor blueColor];
        [btn setTitle:@"play" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(playItem:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
    
    {
        UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(104, 80, 100, 44);
        btn.backgroundColor = [UIColor blueColor];
        [btn setTitle:@"thumnates" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(thumnates:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
    
    {
        imagesContainer_ = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 150, self.view.frame.size.width, 100)];
        imagesContainer_.backgroundColor = [UIColor grayColor];
        [self.view addSubview:imagesContainer_];
        kThumbImageTag_ = 20000;
    }
    {
        pannel_ = [[ActionManagerPannel alloc]initWithFrame:CGRectMake(10, 200,
                                                                       self.view.frame.size.width -20,
                                                                       500)];
        pannel_.backgroundColor = [UIColor grayColor];
        [self.view addSubview:pannel_];
    }
    
    [self buildBaseData];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [ActionManager shareObject].delegate = self;
}
- (void)buildBaseData
{
    
    ActionManager * manager = [ActionManager shareObject];
    manager.delegate = self;
//    NSString * path = [[NSBundle mainBundle]pathForResource:@"test2" ofType:@"mp4"];
    NSString * path = [[NSBundle mainBundle]pathForResource:@"test3" ofType:@"MOV"];
//    NSString * path = [[NSBundle mainBundle]pathForResource:@"up" ofType:@"MOV"];
//    NSString * path = [[NSBundle mainBundle]pathForResource:@"upset" ofType:@"MOV"];
//    NSString * path = [[NSBundle mainBundle]pathForResource:@"lanleft" ofType:@"MOV"];
//    NSString * path = [[NSBundle mainBundle]pathForResource:@"lanright" ofType:@"MOV"];
//        NSString * path = [[NSBundle mainBundle]pathForResource:@"front_up" ofType:@"MOV"];
//        NSString * path = [[NSBundle mainBundle]pathForResource:@"front_lanright" ofType:@"MOV"];
    
    [manager setBackMV:path begin:0 end:-1 buildReverse:YES];
    [pannel_ setActionManager:manager];
    [pannel_ refresh];
//    {
//        MediaAction * action = [MediaAction new];
//        action.ActionType = 1;
//        action.ActionTitle = @"slow";
//        action.ReverseSeconds = 0;
//        action.DurationInSeconds = 1;
//        action.Rate = 0.25;
//        action.IsMutex = NO;
//        action.IsFilter = NO;
//        
//        [manager addActionItem:action filePath:nil at:4 from:4 duration:action.DurationInSeconds];
//    }
//    {
//        MediaAction * action = [MediaAction new];
//        action.ActionType = SSlow;
//        action.ReverseSeconds = 0 ;
//        action.IsOverlap = YES;
//        action.IsMutex = NO;
//        action.Rate = 0.33333;
//        action.isOPCompleted = YES;
//        [manager addActionItem:action filePath:nil at:2 from:2 duration:0.5];
//    }
    
}
- (void)addItem:(id)sender
{
    ActionManager * manager = [ActionManager shareObject];
//    {
//        MediaAction * action = [MediaAction new];
//        action.ActionType = 3;
//        action.ActionTitle = @"Rap";
//        action.ReverseSeconds = -1;
//        action.DurationInSeconds = 1;
//        action.Rate = 1;
//        action.IsMutex = NO;
//        action.IsFilter = NO;
//        
//        [manager addActionItem:action filePath:nil at:7 from:7 duration:action.DurationInSeconds];
//    }
//    {
//        MediaAction * action = [MediaAction new];
//        action.ActionType = SSlow;
//        action.ReverseSeconds = 0 ;
//        action.IsOverlap = YES;
//        action.IsMutex = NO;
//        action.Rate = 0.33333;
//        action.isOPCompleted = YES;
//        [manager addActionItem:action filePath:nil at:2.1 from:2.1 duration:0.5];
//    }
    
//    {
//        MediaAction * action = [MediaAction new];
//        action.ActionType = SSlow;
//        action.ReverseSeconds = 0 ;
//        action.IsOverlap = YES;
//        action.IsMutex = NO;
//        action.Rate = 0.33;
//        action.isOPCompleted = YES;
//        [manager addActionItem:action filePath:nil at:5 from:5 duration:1];
//    }

//    {
//        MediaAction * action = [MediaAction new];
//        action.ActionType = SReverse;
//        action.ReverseSeconds = 0 ;
//        action.IsOverlap = NO;
//        action.IsMutex = NO;
//        action.Rate = 1;
//        action.isOPCompleted = YES;
//        [manager addActionItem:action filePath:nil at:4.5 from:4.5 duration:2];
//    }
    
//    {
//        MediaAction * action = [MediaAction new];
//        action.ActionType = SReverse;
//        action.ReverseSeconds = 0 ;
//        action.IsOverlap = NO;
//        action.IsMutex = NO;
//        action.Rate = 1;
//        action.isOPCompleted = YES;
//        [manager addActionItem:action filePath:nil at:4.5 from:4.5 duration:2];
//    }
//    {
//        MediaAction * action = [MediaAction new];
//        action.ActionType = SReverse;
//        action.ReverseSeconds = 0 ;
//        action.IsOverlap = NO;
//        action.IsMutex = NO;
//        action.Rate = 1;
//        action.isOPCompleted = YES;
//        [manager addActionItem:action filePath:nil at:5.5 from:5.5 duration:1];
//    }
//
//    {
//        MediaAction * action = [MediaAction new];
//        action.ActionType = SRepeat;
//        action.ReverseSeconds = 0 ;
//        action.IsOverlap = NO;
//        action.IsMutex = NO;
//        action.Rate = 1;
//        action.isOPCompleted = YES;
//        [manager addActionItem:action filePath:nil at:5 from:4 duration:1];
//    }
//    {
//        MediaAction * action = [MediaAction new];
//        action.ActionType = SRepeat;
//        action.ReverseSeconds = 0 ;
//        action.IsOverlap = NO;
//        action.IsMutex = NO;
//        action.Rate = 1;
//        action.isOPCompleted = YES;
//        [manager addActionItem:action filePath:nil at:5 from:4 duration:1];
//    }
    MediaActionDo * acdo = nil;
    {
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = 1;
        action.isOPCompleted = NO;
        acdo = [manager addActionItem:action filePath:nil at:4 from:4 duration:-1];
    }
    [manager setActionItemDuration:acdo duration:3];
//    [manager ensureActions:[manager getBaseVideo].secondsDuration];
    
//    [manager setActionItemDuration:acdo duration:manager.getBaseVideo.secondsDuration - 6];
    
    [manager setPlaySeconds:4];
    
    {
        MediaAction * action = [MediaAction new];
        action.ActionType = SReverse;
        action.ReverseSeconds = 0 ;
        action.IsOverlap = NO;
        action.IsMutex = NO;
        action.Rate = 1;
        action.isOPCompleted = NO;
        acdo = [manager addActionItem:action filePath:nil at:7 from:7 duration:-1];
    }
    
    [manager setActionItemDuration:acdo duration:2];
    
    [manager setPlaySeconds:7];
//    
//    MediaAction * action = [MediaAction new];
//    action.ActionType = SReverse;
//    action.ReverseSeconds = 0 ;
//    action.IsOverlap = NO;
//    action.IsMutex = NO;
//    action.Rate = 1;
//    action.isOPCompleted = NO;
//    acdo = [manager addActionItem:action filePath:nil at:5 from:5 duration:1];
//    
//    [manager setActionItemDuration:acdo duration:2];
//    {
//        MediaAction * action = [MediaAction new];
//        action.ActionType = SRepeat;
//        action.ReverseSeconds = -1 ;
//        action.IsOverlap = NO;
//        action.IsMutex = NO;
//        action.Rate = 1;
//        action.isOPCompleted = YES;
//        [manager addActionItem:action filePath:nil at:5 from:4.5 duration:1];
//    }
}
- (void)beginLongTouch:(id)sender
{
    ActionManager * manager = [ActionManager shareObject];
    
    {
        MediaAction * action = [MediaAction new];
        action.ActionType = 4;
        action.ActionTitle = @"reverse";
        action.ReverseSeconds = 0;
        action.DurationInSeconds = 1;
        action.Rate = 1;
        action.IsMutex = NO;
        action.IsFilter = NO;
        
        testAction_ = [manager addActionItem:action filePath:nil at:7 from:7 duration:-1];
    }
    
}
- (void)endLongTouch:(id)sender
{
    ActionManager * manager = [ActionManager shareObject];
    
    if(!testAction_) return;
    
    [manager setActionItemDuration:testAction_ duration:2];
    
    
}
- (void)playItem:(id)sender
{
    
}
- (void)thumnates:(id)sender
{
    ActionManager * manager = [ActionManager shareObject];
    MediaItem * item = [manager getBaseVideo];
    if(!item)
    {
        NSLog(@"not item .");
        return ;
    }
    CGFloat width_ = self.view.frame.size.width - 20;
    CGFloat maxValue_ = 0.9; //最多可以滑到哪里，最多点屏幕的90%
    int step = 3;//共15秒，5张图，3秒一个
    int imageCountInView = 5;
    float temp = round(item.secondsDuration / 3.0 * 10) / 10.0f;
    int count = item.secondsDuration / 3.0;
    if (temp > count + 0.1) {
        count++;
    }
//    CGFloat scale = [DeviceConfig config].Scale;
//    width_ *= scale;
    CGSize size = CGSizeMake((width_ * maxValue_ / imageCountInView), (width_ * maxValue_ / imageCountInView));
    
    size.width = (int)(size.width * 10 + 0.5)/10;
    size.height = (int)(size.height * 10+0.5)/10;
    
    CGSize displaySize = size;
//    CGSize displaySize = CGSizeMake(size.width/scale, size.height/scale);

    //        __block int tempIndex = 0;
    [[WTPlayerResource sharedWTPlayerResource] getVideoThumbs:item.url
//                                                      alAsset:nil
                                       targetThumnateFileName:@"videoThumb"
                                                        begin:0 andEnd:-1
                                                      andStep:step
                                                     andCount:count
                                                      andSize:size
                                                     callback:^(CMTime requestTime, NSString *path, NSInteger index) {
                                                         [self changeImageViewContent:path index:index size:displaySize];
                                                         
                                                     } completed:^(CMTime requestTime, NSString *path, NSInteger index) {

                                                     } failure:^(CMTime requestTime, NSError *error, NSString *filePath) {
                                                     }];
    
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
#pragma mark - action manager delgates
- (void)ActionManager:(ActionManager *)manager play:(MediaWithAction *)mediaToPlay
{
    NSLog(@"mediaItem:%@",[mediaToPlay.fileName lastPathComponent]);
    NSLog(@"mediaItem:%@",[mediaToPlay toString]);
    dispatch_async(dispatch_get_main_queue(), ^{
    [pannel_ refresh];
    });
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

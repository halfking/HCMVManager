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
@interface FirstViewController ()<ActionManagerDelegate,WTPlayerResourceDelegate>

@end

@implementation FirstViewController
{
    MediaActionDo * testAction_;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self buildBaseData];
    
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
    NSString * path = [[NSBundle mainBundle]pathForResource:@"4" ofType:@"m4v"];
    [manager setBackMV:path begin:0 end:-1];
    
    {
        MediaAction * action = [MediaAction new];
        action.ActionType = 1;
        action.ActionTitle = @"slow";
        action.ReverseSeconds = 0;
        action.DurationInSeconds = 1;
        action.Rate = 0.25;
        action.IsMutex = NO;
        action.IsFilter = NO;
        
        [manager addActionItem:action filePath:nil at:4 duration:action.DurationInSeconds];
    }
  
}
- (void)addItem:(id)sender
{
     ActionManager * manager = [ActionManager shareObject];
    {
        MediaAction * action = [MediaAction new];
        action.ActionType = 3;
        action.ActionTitle = @"Rap";
        action.ReverseSeconds = -1;
        action.DurationInSeconds = 1;
        action.Rate = 1;
        action.IsMutex = NO;
        action.IsFilter = NO;
        
        [manager addActionItem:action filePath:nil at:7 duration:action.DurationInSeconds];
    }

}
- (void)beginLongTouch:(id)sender
{
    ActionManager * manager = [ActionManager shareObject];
    
    {
        MediaAction * action = [MediaAction new];
        action.ActionType = 4;
        action.ActionTitle = @"reverse";
        action.ReverseSeconds = -1;
        action.DurationInSeconds = 1;
        action.Rate = 1;
        action.IsMutex = NO;
        action.IsFilter = NO;
        
        testAction_ = [manager addActionItem:action filePath:nil at:7 duration:-1];
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
#pragma mark - action manager delgates
- (void)ActionManager:(ActionManager *)manager doProcessOK:(NSArray *)mediaList duration:(CGFloat)duration
{
    NSLog(@"-------------**----**--------------------");
    NSLog(@"duration:%.2f",duration);
    NSLog(@"** playerSeconds:7 track seconds:%.2f",[[ActionManager shareObject]getSecondsWithoutAction:7]);
    NSLog(@"** playerSeconds:10 track seconds:%.2f",[[ActionManager shareObject]getSecondsWithoutAction:10]);
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

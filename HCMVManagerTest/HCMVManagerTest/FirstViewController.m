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
        btn.frame = CGRectMake(1040, 20, 64, 44);
        btn.backgroundColor = [UIColor blueColor];
        [btn setTitle:@"play" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(playItem:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
}
- (void)buildBaseData
{
    
    ActionManager * manager = [ActionManager shareObject];
    manager.delegate = self;
    NSString * path = [[NSBundle mainBundle]pathForResource:@"test" ofType:@"mp4"];
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
        
        [manager addActionItem:action filePath:nil at:4 duration:-1];
    }
  
}
- (void)addItem:(id)sender
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
        
        [manager addActionItem:action filePath:nil at:7 duration:-1];
    }

}
- (void)playItem:(id)sender
{
    
}
- (void)ActionManager:(ActionManager *)manager doProcessOK:(NSArray *)mediaList duration:(CGFloat)duration
{
    NSLog(@"-------------**----**--------------------");
    NSLog(@"duration:%.2f",duration);
    int index = 0;
    for (MediaWithAction * item in mediaList) {
        NSLog(@"--%d--",index);
        NSLog(@"%@",[item toString]);
        index ++;
    }
    NSLog(@"**--**--**--**--**--**--**--**--**--**--");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

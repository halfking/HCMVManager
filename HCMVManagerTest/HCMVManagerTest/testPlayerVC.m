//
//  testPlayerVC.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/6/1.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "testPlayerVC.h"
#import "MediaItem.h"
#import "ActionManager.h"
#import "ActionManager(index).h"
#import "ActionManager(player).h"
#import "HCPlayerSimple.h"
@interface testPlayerVC() <HCPlayerSimpleDelegate>

@end
@implementation testPlayerVC
{
    HCPlayerSimple * player_;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self buildPlayer];
    
    UIButton * btn = [[UIButton alloc]initWithFrame:CGRectMake(50, 300, 100, 100)];
    [btn setTitle:@"back" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    btn.backgroundColor = [UIColor darkGrayColor];
    [self.view addSubview:btn];
}
- (void)back:(id)sender
{
    [player_ readyToRelease];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void) buildPlayer
{
    MediaItem * baseVideo = [[ActionManager shareObject]getBaseVideo];
    
    AVAsset * asset = [AVAsset assetWithURL:baseVideo.url];
    AVPlayerItem * item = [AVPlayerItem playerItemWithAsset:asset];
    NSString * key = [CommonUtil md5Hash:baseVideo.url.absoluteString];
    
    
    player_ = [[HCPlayerSimple alloc]initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.width /16 * 9)];
    [player_ changeCurrentPlayerItem:item];
    player_.key = key;
    player_.delegate = self;
    [self.view addSubview:player_];
    [player_ setVideoVolume:1];
    player_.backgroundColor = [UIColor clearColor];
    [NSThread sleepForTimeInterval:0.1];
    [player_ play];
}

- (void)playerSimple:(HCPlayerSimple *)playerSimple itemReady:(AVPlayerItem *)item
{
    
}
- (void)playerSimple:(HCPlayerSimple *)playerSimple reachEnd:(CGFloat)end
{
    
}
- (void)playerSimple:(HCPlayerSimple *)playerSimple timeDidChange:(CGFloat)cmTime
{
    
}

- (void)dealloc
{
    
    NSLog(@"dealloc vc.....");
}
@end

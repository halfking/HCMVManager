//
//  SecondViewController.h
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/10.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define RepeatTime 1.5
@interface SecondViewController : UIViewController
{
    AVPlayer * player;
    AVPlayerLayer * layer;
    CFTimeInterval pausedTime1;
}
@property(strong, nonatomic) UIView * Preview;
@property(strong, nonatomic) UIView * Progress;
@property(strong, nonatomic) UIView * Menu;

@end


//
//  ActionManagerPogress.h
//  HCMVManager
//
//  Created by HUANGXUTAO on 16/6/7.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MediaWithAction.h"
#import "ActionManager.h"
@interface AMProgressItem:NSObject
@property (nonatomic,strong) UIView * barView;
@property (nonatomic,strong) MediaWithAction * media;
@property (nonatomic,assign) BOOL hasFlag;
@end

@interface ActionManagerProgress : UIView
{
    NSMutableArray * mediaList_;
    MediaWithAction * currentMedia_;
    
    UIView * barBgView_;
    NSMutableArray * barViews_;
    UILabel * msgLabel_;
    
    NSString * defaultMsg_;
    
    CGFloat widthPerSeconds_;
    CGFloat secondsInArray_;
    
    ActionManager * manager_;
}
@property (nonatomic,assign) CGFloat barHeight;
@property (nonatomic,PP_STRONG) UIColor * colorForNormal;
@property (nonatomic,PP_STRONG) UIColor * colorForTrack;
@property (nonatomic,PP_STRONG) UIColor * colorForSlow;
@property (nonatomic,PP_STRONG) UIColor * colorForFast;
@property (nonatomic,assign) CGFloat durationForFlag;
@property (nonatomic,PP_STRONG) NSString * flagImageName;
@property (nonatomic,assign) BOOL autoHideFlag;

- (void)setManager:(ActionManager *)manager;
- (void)reset;
- (void)refresh;

- (void)setMsgString:(NSString *)msg;
- (void)setCurrentMedia:(MediaWithAction *)media;
- (void)setPlaySeconds:(CGFloat)playerSeconds secondsInArray:(CGFloat)secondsInArray;

- (NSString *) getTipsForMedia:(MediaWithAction *)media;
- (UIColor *) getColorForMedia:(MediaWithAction *)media;
@end

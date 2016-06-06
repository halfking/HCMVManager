//
//  MediaWithActionView.h
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/29.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <hccoren/base.h>
#import "MediaWithAction.h"
#import "MediaActionDo.h"

@interface MediaWithActionView : UIView
{
    CGFloat leftMargin_;
    CGFloat widthPerseconds_;
    UIFont * font_;
}
@property (nonatomic,PP_STRONG) MediaWithAction * mediaWithAction;
@property (nonatomic,assign) int Index;
@property (nonatomic,assign,readonly) CGFloat ContentWidth;
@property (nonatomic,assign,readonly) BOOL isCurrent;
- (void) setBaseWidth:(CGFloat)leftMarin widthPerSeconds:(CGFloat)widthPerSeconds;
- (void) setCurrent:(BOOL)isCurrent;

- (BOOL)setPlayerSeconds:(CGFloat)seconds;
- (void) setData:(MediaWithAction *)media title:(NSString *)title;
@end

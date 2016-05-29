//
//  ActionManagerPannel.h
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/20.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ActionManager;
@class MediaWithAction;

@interface ActionManagerPannel : UIScrollView
- (void) setActionManager:(ActionManager *)actionManager;
- (void) refresh;
//与播放时间同步
- (void) setPlayerSeconds:(CGFloat)playerSeconds isReverse:(BOOL)isReverse;
//与管理器传给播放器的对像一致
- (void) setPlayMedia:(MediaWithAction *)playerMedia;
@end

//
//  ActionManagerPannel.h
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/20.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ActionManager;

@interface ActionManagerPannel : UIView
- (void) setActionManager:(ActionManager *)actionManager;
- (void) refresh;
@end

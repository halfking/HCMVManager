//
//  ActionManager(index).h
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ActionManager.h"
@interface ActionManager(index)
#pragma mark - overlap manager
- (CGFloat) reindexAllActions;
#pragma mark - export
- (void) generatePlayerItem:(NSArray *)mediaList;
@end

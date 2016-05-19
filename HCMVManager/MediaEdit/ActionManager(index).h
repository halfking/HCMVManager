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
- (CGFloat) processNewActions;
#pragma mark - export
- (BOOL) generateMV;
- (void) generatePlayerItem:(NSArray *)mediaList;

- (BOOL) generateThumnates:(CGSize)thumnateSize contentSize:(CGSize)contentSize;
@end

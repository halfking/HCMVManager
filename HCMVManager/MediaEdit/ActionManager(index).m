//
//  ActionManager(index).m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "ActionManager(index).h"
#import "MediaAction.h"
#import "MediaItem.h"
#import "MediaEditManager.h"

#import "ActionProcess.h"

@implementation ActionManager(index)
#pragma mark - overlap manager
- (CGFloat) reindexAllActions
{
    @synchronized (self) {
        [mediaList_ removeAllObjects];
        NSAssert(videoBgAction_, @"必须先设置了源背景视频才能进行处理!");
        
        [mediaList_ addObject:videoBgAction_];
        ActionProcess * process = [ActionProcess new];
        mediaList_ = [process processActions:actionList_ sources:mediaList_];
        durationForTarget_ = process.duration;
        
        if(self.delegate && [self.delegate respondsToSelector:@selector(ActionManager:doProcessOK:duration:)])
        {
            [self.delegate ActionManager:self doProcessOK:mediaList_ duration:durationForTarget_];
        }
        
        return durationForTarget_;
    }
  
}
//获取在此动作之前的已经存在的素材列表
- (NSArray *) getMediaBaseLine:(MediaActionDo *)action
{
    return mediaList_;
}
#pragma mark - export
@end

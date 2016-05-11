//
//  ActionProcess.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "ActionProcess.h"
#import "MediaItem.h"
#import "VideoGenerater.h"
@implementation ActionProcess
- (void)processAction:(MediaActionDo *)actionDo sources:(NSMutableArray *)sources
{
    NSMutableArray * overlapList = [self getActionMedia:actionDo];
    
    //暂定4个，1 表示慢速 2 表示加速 3表示Rap 4表示倒放 0表示是一个模板类型的
    switch (actionDo.ActionType) {
        case 1: //slow
        {
            
        }
            break;
        case 2: //fast
        {
            
        }
            break;
        case 3: //rap
        {
            
        }
            break;
        case 4: //reverse
        {
            
        }
            break;
            
        default: //模板类型，暂不支持。即二级类型
        {
            NSArray * actions = [actionDo getSubActionList];
            if(actions && actions.count>0)
            {
                [self processActions:actions sources:sources];
            }
        }
            break;
    }
}
//将素材插入到队列中
- (void)insertMediaItemAtSeconds:(MediaItem *)item
{
    
}

//获取要插入到队列中的素材
- (NSMutableArray *)getActionMedia:(MediaActionDo *)action
{
    MediaItemCore * item = action.Media;
    if(!item)
    {
        item = nil;
    }
    return nil;
}

//获取当前队列中的可能被分割的对像
//duration >0，则表示是覆盖，需要返回多个对像了
- (NSMutableArray *)getMediaItemAtSource:(CGFloat)seconds duration:(CGFloat)duration source:(NSArray *)source
{
    NSMutableArray * overlapList = [NSMutableArray new];
    
    for (MediaItem * item in source) {
        //第一个或跨界的
        if(item.secondsInArray <=seconds && item.secondsDurationInArray + item.secondsInArray > seconds)
        {
            [overlapList addObject:item];
        }
        //表示需要覆盖的
        else if(duration>0)
        {
            //被包含在这个区段中的
            if(item.secondsInArray > seconds && item.secondsDurationInArray + item.secondsInArray <= seconds+duration)
            {
                [overlapList addObject:item];
            }
            //有一部分在范围内，但尾部超过边界的
            else if (item.secondsInArray < seconds + duration && item.secondsInArray + item.secondsDurationInArray >= seconds +duration)
            {
                [overlapList addObject:item];
            }
        }
    }
    return overlapList;
}
- (void) processActions:(NSArray *)actions sources:(NSMutableArray *) sources
{
    if(!actions || !sources || actions.count==0 || sources.count==0) return;
    for (MediaActionDo * action in actions) {
        [self processAction:action sources:sources];
    }
}
@end

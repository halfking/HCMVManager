//
//  ActionProcess.h
//  HCMVManagerTest
//
//  处理Action的具体过程
//  Created by HUANGXUTAO on 16/5/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MediaActionDo.h"


@interface ActionProcess : NSObject
{
    CGFloat currentDuration_;
}
@property (nonatomic,assign) CGFloat duration;
//- (NSMutableArray *) processAction:(MediaActionDo *)actionDo
//                           sources:(NSMutableArray *)sources;
//                    secondsInArray:(CGFloat)secondsInArray
//               secondsInFinalArray:(CGFloat)secondsInFinalArray;
//- (NSMutableArray *) processActions:(NSArray *)actions sources:(NSMutableArray *) sources;
@end

//
//  MediaWithAction.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/12.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "MediaWithAction.h"
#import <hccoren/base.h>

@implementation MediaWithAction
@synthesize Action;
@synthesize durationInFinalArray;
@synthesize secondsInFinalArray;
@synthesize durationInPlaying;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"mediawithaction";
        self.KeyName = @"key";
    }
    return self;
}
- (MediaWithAction *)copyItem
{
    MediaWithAction * item = [MediaWithAction new];
    [item fetchAsCore:(MediaItemCore *)self];
    item.Action = [self.Action copyItem];
    item.secondsInFinalArray = self.secondsInFinalArray;
    item.durationInFinalArray = self.durationInFinalArray;
    item.durationInPlaying = self.durationInPlaying;
    return item;
}
- (NSString *) toString
{
    return [NSString stringWithFormat:@"%d(%.2f--%.2f-->final:%.2f-->%.2f) total:%.2f\n\t\t%@(%.2f--%.2f) rate:%.2f",
            (int)self.Action.ActionType,
            self.secondsInArray,
            self.secondsDurationInArray,
            self.secondsInFinalArray,
            self.durationInFinalArray,
            self.durationInPlaying,
            [self.fileName lastPathComponent] ,
            self.secondsBegin,self.secondsEnd,self.playRate];
}
- (void)dealloc
{
    PP_RELEASE(Action);
    PP_SUPERDEALLOC;
}
@end
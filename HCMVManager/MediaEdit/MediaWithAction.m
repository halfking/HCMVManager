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
//@synthesize durationInFinalArray;
//@synthesize secondsInFinalArray;
@synthesize durationInPlaying;
@synthesize secondsInArrayNotConfirm;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"mediawithaction";
        self.KeyName = @"key";
        self.secondsInArrayNotConfirm = NO;
    }
    return self;
}
- (MediaWithAction *)copyItem
{
    MediaWithAction * item = [MediaWithAction new];
    [item fetchAsCore:(MediaItemCore *)self];
    item.Action = [self.Action copyItem];
    item.durationInPlaying = self.durationInPlaying;
    item.secondsInArrayNotConfirm = self.secondsInArrayNotConfirm;
    return item;
}

- (NSString *) toString
{
    return [NSString stringWithFormat:@"%d-%ld(%.2f len:%.2f) file:(%.2f--%.2f) total:%.2f rate:%.2f",
            (int)self.Action.ActionType,
            (long)self.Action.MediaActionID,
            self.secondsInArray,
            self.secondsDurationInArray,
            self.secondsBegin,self.secondsEnd,
            self.durationInPlaying,
            self.playRate];
}
//是否同一个Asset
- (BOOL) isSampleAsset:(MediaItemCore *)item
{
    //反向的，使用不同的文件，因此只要文件名相同就行
    if([self.fileName isEqualToString:item.fileName])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}
- (void)dealloc
{
    PP_RELEASE(Action);
    PP_SUPERDEALLOC;
}
@end
//
//  MediaAction.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "MediaAction.h"
#import <hccoren/JSON.h>
@implementation MediaAction
{
    NSMutableArray * subActionsList_;
}
@synthesize MediaActionID;
@synthesize ActionTitle,ActionIcon;
@synthesize ActionType;
@synthesize SubActions;
@synthesize Rate,ReverseSeconds,DurationInSeconds,IsMutex,IsFilter,IsOverlap;
@synthesize isOPCompleted;
@synthesize secondsBeginAdjust;
@synthesize IsReverse;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"mediaactions";
        self.KeyName = @"MediaActionID";
        self.Rate = 1;
        self.DurationInSeconds = -1;
        self.ReverseSeconds = 0;
        self.IsMutex = NO;
        self.IsFilter = NO;
        self.IsOverlap = YES;
        self.isOPCompleted = YES;
        self.IsReverse = NO;
        self.secondsBeginAdjust = 0;//- 0.15;
    }
    return self;
}
- (void)setDurationInSeconds:(CGFloat)DurationInSecondsA
{
    DurationInSeconds = DurationInSecondsA;
    if(DurationInSeconds >=0)
    {
        self.isOPCompleted = YES;
    }
    else
    {
        self.isOPCompleted = NO;
    }
}
- (void)setSubActions:(NSString *)SubActionsA
{
    PP_RELEASE(SubActions);
    SubActions = PP_RETAIN(SubActionsA);
    
    PP_RELEASE(subActionsList_);
}
- (NSArray *)getSubActionList
{
    if(subActionsList_)
    {
        return subActionsList_;
    }
    else
    {
        if(SubActions && SubActions.length>2)
        {
            NSArray * list = [SubActions JSONValueEx];
            if(list)
            {
                PARSEDATAARRAY(listA,list,MediaAction);
                subActionsList_ = PP_RETAIN(listA);
            }
        }
        return subActionsList_;
    }
}
- (MediaAction *)copyItem
{
    MediaAction * item = [MediaAction new];
    
    item.MediaActionID =  self.MediaActionID;
    item.ActionTitle =  self.ActionTitle;
    item.ActionIcon = self.ActionIcon;
    item.ActionType = self.ActionType;
    item.SubActions = self.SubActions;
    item.Rate = self.Rate;
    item.ReverseSeconds =  self.ReverseSeconds;
    item.DurationInSeconds = self.DurationInSeconds;
    item.IsMutex = self.IsMutex;
    item.IsFilter = self.IsFilter;
    item.IsOverlap = self.IsOverlap;
    item.isOPCompleted = self.isOPCompleted;
    item.secondsBeginAdjust = self.secondsBeginAdjust;
    item.IsReverse = self.IsReverse;
    return item;
}
- (void)dealloc
{
    PP_RELEASE(ActionIcon);
    PP_RELEASE(ActionTitle);
    PP_RELEASE(SubActions);
    PP_RELEASE(subActionsList_);
    PP_SUPERDEALLOC;
}
@end


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
@synthesize Rate,ReverseSeconds,DurationInSeconds,IsMutex,IsFilter;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"mediaactions";
        self.KeyName = @"MediaActionID";
    }
    return self;
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
- (void)dealloc
{
    PP_RELEASE(ActionIcon);
    PP_RELEASE(ActionTitle);
    PP_RELEASE(SubActions);
    PP_RELEASE(subActionsList_);
    PP_SUPERDEALLOC;
}
@end

@implementation MediaActionDo
@synthesize Index,SecondsInArray,DurationInArray;
@synthesize Media;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"mediaactionsdo";
        self.KeyName = @"MediaActionID,Index";
    }
    return self;
}
- (void)fetchAsAction:(MediaAction *)action
{
    self.MediaActionID = action.MediaActionID;
    self.ActionTitle = action.ActionTitle;
    self.ActionIcon = action.ActionIcon;
    self.ActionType = action.ActionType;//暂定4个，1 表示慢速 2 表示加速 3表示Rap 4表示倒放 0表示是一个模板类型的
    self.SubActions = action.SubActions;
    self.Rate = action.Rate;
    self.ReverseSeconds = action.ReverseSeconds;
    self.DurationInSeconds = action.DurationInSeconds;
    self.IsMutex = action.IsMutex;
    self.IsFilter = action.IsFilter;
}
- (void)dealloc
{
    PP_RELEASE(Media);
    PP_SUPERDEALLOC;
}
@end

@implementation MediaWithAction
@synthesize Action;
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
- (void)fetchAsCore:(MediaItemCore *)item
{
    if(!item) return;
    
    self.fileName = item.fileName;
    self.title = item.title;
    self.cover = item.cover;
    self.url = item.url;
    self.key = item.key;
    self.duration = item.duration;
    self.begin = item.begin;
    self.end = item.end;
    self.originType = item.originType;
    self.cutInMode = item.cutInMode;
    self.cutOutMode = item.cutOutMode;
    self.cutInTime = item.cutInTime;
    self.cutOutTime = item.cutOutTime;
    self.playRate = item.playRate;
    self.timeInArray = item.timeInArray;
    self.renderSize = item.renderSize;
}
- (void)dealloc
{
    PP_RELEASE(Action);
    PP_SUPERDEALLOC;
}

@end


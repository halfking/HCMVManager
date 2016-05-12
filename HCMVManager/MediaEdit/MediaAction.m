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
        self.Rate = 1;
        self.DurationInSeconds = -1;
        self.ReverseSeconds = 0;
        self.IsMutex = NO;
        self.IsFilter = NO;
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
- (NSMutableArray *)get_MaterialList
{
    return materialList_;
}
- (NSMutableArray *)buildMaterialProcess:(NSArray *)sources
{
    NSAssert(NO, @"此函数需要在子类中实现，不能直接使用父类的函数。");
    return nil;
}
- (NSMutableArray *)buildMaterialOverlaped:(NSArray *)sources
{
    NSAssert(NO, @"此函数需要在子类中实现，不能直接使用父类的函数。");
    return nil;
}
- (CGFloat) getDurationInFinal:(NSArray *)sources
{
    NSAssert(NO, @"此函数需要在子类中实现，不能直接使用父类的函数。");
    return -1;
}
- (MediaWithAction *)toMediaWithAction:(NSArray *)sources
{
    NSAssert(NO, @"此函数需要在子类中实现，不能直接使用父类的函数。");
    return nil;
}
- (void)dealloc
{
    PP_RELEASE(Media);
    PP_SUPERDEALLOC;
}
@end

@implementation MediaWithAction
@synthesize Action;
@synthesize finalDuration;
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
    self.playRate = item.playRate;
    self.isOnlyAudio = item.isOnlyAudio;
    self.renderSize = item.renderSize;
    
}
- (MediaWithAction *)copyItem
{
    MediaWithAction * item = [MediaWithAction new];
    [item fetchAsCore:(MediaItemCore *)self];
    item.Action = [self.Action copyItem];
    return item;
}
- (void)dealloc
{
    PP_RELEASE(Action);
    PP_SUPERDEALLOC;
}

@end


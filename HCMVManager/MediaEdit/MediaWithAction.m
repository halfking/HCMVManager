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
//
//  HCUserSummary.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-10-15.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "HCUserSummary.h"

@implementation HCUserSummary
@synthesize UserID,FansCount,PlayCount,ConcernCount,BeFavCount,MTVCount;
@synthesize NewMessageCount;


@synthesize NewFriendCount;
@synthesize NewRequestCount;
@synthesize NewTranfersCount;
@synthesize NewCommentCount;

@synthesize LastSyncTime;
@synthesize IsChanged;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"usersummary";
        self.KeyName = @"UserID";
    }
    return self;
}
- (int)countForNotify
{
    return NewFriendCount + NewRequestCount+NewTranfersCount+NewMessageCount+NewCommentCount;
}
-(void) dealloc
{
    PP_RELEASE(LastSyncTime);
    PP_SUPERDEALLOC;
}
@end

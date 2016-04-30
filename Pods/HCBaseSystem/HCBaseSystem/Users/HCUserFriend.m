//
//  HCUserFriend.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-18.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "HCUserFriend.h"

@implementation HCUserFriend
@synthesize FW_ID;
@synthesize FW_UserID;
@synthesize FW_FellowType;
@synthesize FW_FellowUserID;
@synthesize FW_FellowNickName;
@synthesize FW_FellowHeadportrait;
@synthesize FW_Time;

-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"userfellows";
        self.KeyName = @"FW_ID";
    }
    return self;
}

-(void)dealloc
{
    self.FW_FellowHeadportrait = nil;
    self.FW_FellowNickName = nil;
    self.FW_Time = nil;
    PP_SUPERDEALLOC;
}

@end

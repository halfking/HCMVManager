//
//  UserInfo-Extend.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-10-13.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//
//用户扩展信息
#import "UserInfo-Extend.h"

@implementation HCUser_Extend
@synthesize User,Settings,Summary;
@synthesize UserID;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"userextend";
        self.KeyName = @"UserID";
    }
    return self;
}

-(void)dealloc
{
    PP_RELEASE(User);
    PP_RELEASE(Settings);
    PP_RELEASE(Summary);
    PP_SUPERDEALLOC;
}
@end

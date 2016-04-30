//
//  CMDLog.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/7/28.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMDLog.h"

@implementation CMDLog
@synthesize UserID,ID,CMDID,BytesReceived,BytesSend,CreateTicks,ReadyTicks,SendTicks,ParseTicks;
@synthesize DateCreated,CMDName;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"cmdlogs";
        self.KeyName = @"ID";
    }
    return self;
}
- (void)dealloc
{
    PP_RELEASE(DateCreated);
    PP_RELEASE(CMDName);
    
    PP_SUPERDEALLOC;
}
@end

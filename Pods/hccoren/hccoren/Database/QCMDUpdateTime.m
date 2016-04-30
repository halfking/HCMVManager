//
//  QCMDUpdateTime.m
//  SuixingSteward
//
//  Created by HUANGXUTAO on 14-7-13.
//  Copyright (c) 2014年 jokefaker. All rights reserved.
//

#import "QCMDUpdateTime.h"

@implementation QCMDUpdateTime
@synthesize CMDID,LastUpdateTime,ArgsHash,ResultMD5;
@synthesize Scode,WindowID;
//ValueMaxMargin,ValueMinMargin;
@synthesize Status;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"cmdupdatetime";
        self.KeyName = @"CMDID,ArgsHash";
    }
    return self;
}
-(void)dealloc
{
    PP_RELEASE(LastUpdateTime);
    PP_RELEASE(ArgsHash);
    PP_RELEASE(ResultMD5);
    PP_RELEASE(Scode);
    PP_RELEASE(WindowID);
    PP_SUPERDEALLOC;
}
@end

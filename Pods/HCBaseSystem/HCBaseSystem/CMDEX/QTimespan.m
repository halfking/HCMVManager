//
//  QTimespan.m
//  Hotel
//
//  Created by HUANGXUTAO on 14-6-5.
//  Copyright (c) 2014年 jokefaker. All rights reserved.
//

#import "QTimespan.h"

@implementation QTimespan
@synthesize Code,Value,LastUpdateTime;
//ValueMaxMargin,ValueMinMargin;
@synthesize IsDone;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"synctimespans";
        self.KeyName = @"Code";
    }
    return self;
}
-(void)dealloc
{
    PP_RELEASE(Code);
    PP_RELEASE(LastUpdateTime);
    PP_SUPERDEALLOC;
}

@end

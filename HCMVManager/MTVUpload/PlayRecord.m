//
//  PlayRecord.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/4/30.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "PlayRecord.h"

@implementation PlayRecord
@synthesize PlayID,UserID,MTVID,SampleID;
@synthesize PlayTime;
@synthesize BeginDurance,EndDurance,PlayDurance,IsFullScreen;
@synthesize TargetUserID;
@synthesize OPType;

-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"playrecords";
        self.KeyName = @"PlayID";
    }
    return self;
}

-(void) dealloc
{
    PP_RELEASE(PlayTime);

    PP_SUPERDEALLOC;
}
@end

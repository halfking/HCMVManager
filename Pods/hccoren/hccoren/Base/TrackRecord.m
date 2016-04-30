//
//  TrackRecord.m
//  Wutong
//  用户界面跟踪数据
//  用户ID、进入时间、上一界面、当前界面、退出时间、可见时间、不可见时间
//  Created by HUANGXUTAO on 15/4/30.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "TrackRecord.h"

@implementation TrackRecord
@synthesize TrackRecordID;
@synthesize UserID,WinClassName,WinParameters,LastWinClassName;
@synthesize EnterTime,LeaveTime,IsSynced,Durance;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"trackrecords";
        self.KeyName = @"TrackRecordID";
    }
    return self;
}

-(void) dealloc
{
    PP_RELEASE(WinClassName);
    PP_RELEASE(WinParameters);
    PP_RELEASE(LastWinClassName);
    PP_RELEASE(EnterTime);
    PP_RELEASE(LeaveTime);

    PP_SUPERDEALLOC;
}
@end

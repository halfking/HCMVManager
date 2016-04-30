//
//  ReportInfo.m
//  maiba
//
//  Created by HUANGXUTAO on 16/2/26.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "ReportInfo.h"

@implementation ReportInfo
@synthesize ReportID,ObjectID,ObjectType;
@synthesize UrlString,NickName,UserID,ReportReason,Message,DateCreated;
@synthesize TargetNickName,TargetUserID;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"reportinfos";
        self.KeyName = @"ReportID";
    }
    return self;
}

-(void)dealloc
{
    PP_RELEASE(TargetNickName);
    PP_RELEASE(UrlString);
    PP_RELEASE(NickName);
    PP_RELEASE(ReportReason);
    PP_RELEASE(Message);
    PP_RELEASE(DateCreated);
    PP_SUPERDEALLOC;
}

@end

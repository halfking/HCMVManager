//
//  CMD_DeleteMyMTV.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/7/4.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMD_DeleteMyMTV.h"
#import <hccoren/base.h>
#import <hcbasesystem/database_wt.h>
#import <hcbasesystem/cmd_wt.h>

@implementation CMD_DeleteMyMTV
@synthesize mtvID = mtvID_;
- (id)init
{
    if(self = [super init])
    {
        CMDID_ = 9;
        useHttpSender_ = YES;
        mtvID_ = 0;
    }
    return self;
}
- (BOOL)calcArgsAndCacheKey
{
    NSLog(@"A_1_9_0_9_用户创建、删除自己MTV");
    DeviceConfig * info = [DeviceConfig Instance];
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:
                          //                          info.UDI,@"ClientID",
                          //#ifdef IS_MANAGERCONSOLE
                          //                          @([SystemConfiguration sharedSystemConfiguration].loginUserID),@"UserID",
                          //#else
                          @([self userID]),@"userid",
                          @(1),@"isdelete",
                          @(mtvID_),@"mtvid",
                          @"1.9.0",@"scode",
                          info.IPAddress,@"ip",
                          nil];
    if(args_) PP_RELEASE(args_);
    args_ = PP_RETAIN([dic JSONRepresentationEx]);
    if(argsDic_) PP_RELEASE(argsDic_);
    argsDic_ = PP_RETAIN(dic);
    return YES;
    
}
#pragma mark - query from db
//取原来存在数据库中的数据，当需要快速响应或者网络不通时
- (NSObject *) queryDataFromDB:(NSDictionary *)params
{
    return nil;
}
- (BOOL) DeleteFromDB:(long)mtvID
{
    dispatch_async([DBHelper_WT getDBQueue], ^{
        DBHelper * db = [DBHelper sharedDBHelper];
        NSString * sql = [NSString stringWithFormat:@"delete FROM mtvs where mtvid = %ld",mtvID];
        if([db open])
        {
            [db execNoQuery:sql];
            [db close];
        }
    });
    return TRUE;
}
#pragma mark - parse
- (HCCallbackResult *) parseResult:(NSDictionary *)result
{
    //
    //需要在子类中处理这一部分内容
    //
    HCCallResultForWT * ret = [[HCCallResultForWT alloc]initWithArgs:argsDic_?argsDic_ : [self.args JSONValueEx]
                                                            response:result];
    ret.DicNotParsed = result;
    
    if(ret.Code ==0)
    {
        [self DeleteFromDB:mtvID_];
    }
    return PP_AUTORELEASE(ret);
}
@end
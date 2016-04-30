//
//  CMD_UserLogout.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/19.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMD_UserLogout.h"
#import <hccoren/base.h>
#import "HCCallResultForWT.h"
#import "HCDBHelper(WT).h"
@implementation CMD_UserLogout
@synthesize LoginType,LoginID;
@synthesize UserID;

- (id)init
{
    if(self = [super init])
    {
        CMDID_ = 15;
        useHttpSender_ = YES;
    }
    return self;
}
- (BOOL)calcArgsAndCacheKey
{
    NSLog(@"A_2_14_0_15_用户登出");
    DeviceConfig * info = [DeviceConfig Instance];
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:
                          @(UserID),@"userid",
                          info.UDI,@"clientid",
                          LoginID==nil?@"":LoginID,@"loginid",
                          @(LoginType),@"logintype",
                          @"2.14.0",@"scode",
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

#pragma mark - parse
- (HCCallbackResult *) parseResult:(NSDictionary *)result
{
    //
    //需要在子类中处理这一部分内容
    //
    HCCallResultForWT * ret = [[HCCallResultForWT alloc]initWithArgs:argsDic_?argsDic_ : [self.args JSONValueEx]
                                                            response:result];
    ret.DicNotParsed = result;
    
    if(ret.Code ==0 && ret.IsFromDB == NO)
    {
        //ret.Data = (HCEntity *)[self parseData:result];
    }
    
    
    
    return PP_AUTORELEASE(ret);
}

- (HCEntity*)parseData:(NSDictionary *)result
{
    return nil;
}


@end

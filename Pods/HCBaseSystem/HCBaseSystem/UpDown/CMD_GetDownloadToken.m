//
//  CMD_GetDownloadToken.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/15.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMD_GetDownloadToken.h"
#import <hccoren/base.h>
#import <hccoren/json.h>
#import "HCCallResultForWT.h"
@implementation CMD_GetDownloadToken
- (id)init
{
    if(self = [super init])
    {
        CMDID_ = 51;
        useHttpSender_ = YES;
    }
    return self;
}
- (BOOL)calcArgsAndCacheKey
{
    NSLog(@"A_3_2_0_51_获取7牛下载Token");
    DeviceConfig * info = [DeviceConfig Instance];
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:
                          info.UDI,@"clientid",
                          @([self userID]),@"Userid",
                          @"3.2.0",@"scode",
                          info.IPAddress,@"ip",nil];
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
//    {"dntoken":"tvDdyvnYo95nAz1a7PIcywpw21Eze-qYvy2QHSep:X0fEw8sxMWqLtzQWpew_N3xJE1w=:eyJzY29wZSI6ImhvbWUiLCJkZWFkbGluZSI6MTQzNTI4Mzc5NywiaW5zZXJ0T25seSI6MCwiZGV0ZWN0TWltZSI6MCwiZnNpemVMaW1pdCI6MH0="}
    
    HCCallResultForWT * ret = [[HCCallResultForWT alloc]initWithArgs:argsDic_?argsDic_ : [self.args JSONValueEx]
                                                            response:result];
    ret.DicNotParsed = result;
    return PP_AUTORELEASE(ret);
}
- (NSObject*)parseData:(NSDictionary *)result
{
    //
    //需要在子类中处理这一部分内容
    //
    
    return result;
}


@end

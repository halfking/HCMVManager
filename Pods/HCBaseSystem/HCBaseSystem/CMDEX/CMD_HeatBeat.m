//
//  CMD_0002.m
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-6.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "CMD_HeatBeat.h"
#import <hccoren/base.h>
#import <hccoren/json.h>
#import "HCCallResultForWT.h"

@implementation CMD_HeartBeat
- (id)init
{
    if(self = [super init])
    {
        CMDID_ = 2;
        useHttpSender_ = YES;
        isPost_ = NO;
    }
    return self;
}
- (BOOL)calcArgsAndCacheKey
{
    NSLog(@"A_1_1_0_2_HeartBeat心跳命令号0002");
    DeviceConfig * info = [DeviceConfig Instance];
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:
                          info.UDI,@"ClientID",
                          //#ifdef IS_MANAGERCONSOLE
                          //                          @([SystemConfiguration sharedSystemConfiguration].loginUserID),@"UserID",
                          //#else
                          @([self userID]),@"UserID",
                          //#endif
                          @"1.1.0",@"Scode",
                          info.IPAddress,@"IP",nil];
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
    //
    //需要在子类中处理这一部分内容
    //
    
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

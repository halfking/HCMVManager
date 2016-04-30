//
//  CMD_0001.m
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-6.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "CMD_0001.h"
#import <hccoren/base.h>
#import <hccoren/JSON.h>
#import "HCCallResultForWT.h"
#import "UserManager.h"
//#import "SystemConfiguration.h"

@implementation CMD_0001
- (id)init
{
    if(self = [super init])
    {
        CMDID_ = 1;
        useHttpSender_ = YES;
        isPost_ = NO;
    }
    return self;
}
- (BOOL)calcArgsAndCacheKey
{
    
    DeviceConfig * information = [DeviceConfig config];
    NSLog(@"A_1_1_0_1_getRegister登陆注册命令号0001");
    NSString * Scode = [NSString stringWithFormat: @"1.1.0"];
    
    NSMutableDictionary * dic = [[NSMutableDictionary alloc]init];
    
    [dic setObject:Scode forKey:@"scode"];
    [dic setObject:information.UDI forKey:@"clientid"];
    [dic setObject:information.UA forKey:@"ua"];
    [dic setObject:information.IPAddress forKey:@"ip"];
    
    [dic setObject:[NSNumber numberWithLong:[self userID]] forKey:@"userid"];
    [dic setObject:[NSNumber numberWithBool:[[UserManager sharedUserManager] isLogin]] forKey:@"islogin"];
    [dic setObject:information.MacAddress==nil?[NSNull null]:information.MacAddress forKey:@"macaddress"];
    NSString * ob = [self userName];
    if(ob)
    {
        [dic setObject:ob forKey:@"username"];
    }
    //    [dic setObject:ob==nil?[NSNull null]:ob forKey:@"UserName"];
    [dic setObject:information.Version forKey:@"version"];
    
    args_ = PP_RETAIN([dic JSONRepresentationEx]);
    argsDic_ = PP_RETAIN(dic);
    PP_RELEASE(dic);
    
    //CMDID_ = 1;
    
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
    if([result objectForKey:@"userid"])
        resultUserID_ = [[result objectForKey:@"userid"]intValue];
    else
        resultUserID_ = 0;
    if([result objectForKey:@"isforreview"])
    {
        int i = [[result objectForKey:@"isforreview"]intValue];
        ret.isForReview = i>0;
    }
    
    return PP_AUTORELEASE(ret);
    
    
}
- (int)resultUserID
{
    return resultUserID_;
}
- (NSObject*)parseData:(NSDictionary *)result
{
    //
    //需要在子类中处理这一部分内容
    //
    return result;
}
@end

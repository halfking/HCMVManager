//
//  CMD_RegisterPushToken.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/8/10.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMD_RegisterPushToken.h"
#import <hccoren/base.h>
//#import "UserStars.h"
#import "HCCallResultForWT.h"
#import "HCDBHelper(WT).h"

@implementation CMD_RegisterPushToken
@synthesize UserID,pushTocken;
- (id)init
{
    if(self = [super init])
    {
        CMDID_ = 2721;
        useHttpSender_ = YES;
    }
    return self;
}
- (BOOL)calcArgsAndCacheKey
{
    NSLog(@"A_1_16_0_2721_记录PushToken ");
    DeviceConfig * config = [DeviceConfig config];
    NSMutableDictionary * dic = [[NSMutableDictionary alloc]init];
    
    [dic setObject:@"1.16.0" forKey:@"scode"];
    
    if(UserID>0)
        [dic setObject:@(UserID) forKey:@"userid"];
    else
        [dic setObject:[NSNumber numberWithLong:[self userID]] forKey:@"userid"];
    [dic setObject:config.UDI forKey:@"clientid"];
    [dic setObject:pushTocken forKey:@"pushtoken"];
    
    
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
    
    return PP_AUTORELEASE(ret);
}
- (NSObject*)parseData:(NSDictionary *)result
{
    return nil;
}
@end

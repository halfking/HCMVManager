//
//  CMD_UpdateIP.m
//  maiba
//
//  Created by HUANGXUTAO on 15/11/20.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import "CMD_UpdateIP.h"
#import <hccoren/base.h>
#import "HCDBHelper(WT).h"
#import "HCCallResultForWT.h"
//2.20.0  更新用户信息（IP）
//传入 ip和userid
@implementation CMD_UpdateIP
@synthesize UserID,IP;


- (id)init
{
    if(self = [super init])
    {
        CMDID_ = 5321;
        useHttpSender_ = YES;
        isPost_ = YES;
        maxRetryTimes_ = 5;
    }
    return self;
}


- (BOOL)calcArgsAndCacheKey
{
    NSLog(@"A_2_20_0_更新IP");
    if(!IP || IP.length==0) return NO;
    
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:
                          @(UserID),@"userid",
                          IP,@"ip",
                          @"2.20.0",@"scode",
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
    
    
    
    return PP_AUTORELEASE(ret);
}

- (NSDictionary*)parseData:(NSDictionary *)result
{
    return result;
}


@end

//
//  CMD_Register.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/19.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMD_Register.h"
#import <hccoren/base.h>
#import "HCCallResultForWT.h"
#import "HCDBHelper(WT).h"

@implementation CMD_Register
@synthesize LoginID,LoginType;
@synthesize Password;
- (id)init
{
    if(self = [super init])
    {
        CMDID_ = 13;
        useHttpSender_ = YES;
    }
    return self;
}
- (BOOL)calcArgsAndCacheKey
{
    NSLog(@"A_2_12_0_13_用户注册");
    DeviceConfig * info = [DeviceConfig Instance];
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:
                          info.UDI,@"clientid",
                          LoginID==nil?@"":LoginID,@"loginid",
                          @(LoginType),@"logintype",
                          Password==nil?@"":Password,@"password",
                          @"2.12.0",@"scode",
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
        ret.Data = (HCEntity *)[self parseData:result];
    }
    
    
    
    return PP_AUTORELEASE(ret);
}

- (UserInformation*)parseData:(NSDictionary *)result
{
    NSDictionary * userData = [result objectForKey:@"data"];
    if(!userData )
    {
        id userIDObject = [userData objectForKey:@"userid"];
        if(userIDObject && [userIDObject intValue]>0)
        {
            UserInformation * user = [[UserInformation alloc]init];
            user.UserID = [userIDObject intValue];
            user.UserName = self.LoginID;
            return PP_AUTORELEASE(user);
        }
        else
        {
            return nil;
        }
    }
    else
    {
        UserInformation * user = [[UserInformation alloc]initWithDictionary:[result objectForKey:@"data"]];
        return PP_AUTORELEASE(user);
    }
}
@end

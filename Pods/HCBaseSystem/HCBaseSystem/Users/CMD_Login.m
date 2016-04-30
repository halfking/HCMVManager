//
//  CMD_Login.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/19.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMD_Login.h"
#import <hccoren/base.h>
#import "Config.h"
#import "HCCallResultForWT.h"
#import "HCDBHelper(WT).h"

@implementation CMD_Login
@synthesize LoginID,ThirdUser,Password;
@synthesize LoginType;
@synthesize Avatar;
@synthesize Nickname;
@synthesize ReturnData;
- (id)init
{
    if(self = [super init])
    {
        CMDID_ = 14;
        useHttpSender_ = YES;
        isPost_ = NO;
    }
    return self;
}
- (BOOL)calcArgsAndCacheKey
{
    NSLog(@"A_2_13_0_14_用户登录（含第三方登录）");
    //如果是新用户，可以用LoginID+LoginType，组成一个字串，作为UserName
    //只有第三方登录时，才需要保存这些属性
    
    DeviceConfig * info = [DeviceConfig Instance];
    NSString * tuString = nil;
    if(ThirdUser)
        tuString = [ThirdUser toJson];
    
    
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 info.UA,@"ua",
                                 info.UDI,@"clientid",
                                 LoginID==nil?@"":LoginID,@"loginid",
                                 [NSNumber numberWithInt:LoginType],@"logintype",
                                 @"2.13.0",@"scode",
                                 info.IPAddress,@"ip",
                                 @(ReturnData),@"isreturndata",
                                 @(DEFAULT_UserSource),@"source",
                                 nil];
    
    if(Nickname && Nickname.length>0)
    {
        [dic setObject:Nickname forKey:@"nickname"];
    }
    if(info.Version && info.Version.length>0)
    {
        [dic setObject:info.Version forKey:@"version"];
    }
    if(Password && Password.length>0)
    {
        [dic setObject:Password forKey:@"password"];
    }
    if(Avatar && Avatar.length>0)
    {
        [dic setObject:Avatar forKey:@"headerportrait"];
    }
    if(tuString && tuString.length>0)
    {
        [dic setObject:tuString forKey:@"additions"];
    }
    
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
        id userIDObject = [result objectForKey:@"userid"];
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

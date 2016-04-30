//
//  CMD_GetUserInfo.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/12.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMD_GetUserInfo.h"
#import <hccoren/base.h>
#import "HCCallResultForWT.h"
#import "HCDBHelper(WT).h"
#import "UserInformation.h"
#import "UserInfo-Extend.h"
#import "HCUserSettings.h"
#import "HCUserSummary.h"

@implementation CMD_GetUserInfo
@synthesize LoginID,LoginType;
@synthesize UserID;
@synthesize InfoType;


- (id)init
{
    if(self = [super init])
    {
        CMDID_ = 32;
        useHttpSender_ = YES;
        isPost_=NO;
    }
    return self;
}
- (BOOL)calcArgsAndCacheKey
{
    NSLog(@"A_2_2_0_32_获取用户信息");
//    DeviceConfig * info = [DeviceConfig Instance];
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:
                          @(LoginType),@"logintype",
                          @(UserID),@"userid",
                          @(InfoType),@"type",
                          @"2.2.0",@"scode",
                          LoginID==nil?@"":LoginID,@"loginid",
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

- (HCUser_Extend*)parseData:(NSDictionary *)result
{
    NSDictionary * userData = [result objectForKey:@"data"];
    UserInformation * user = nil;
    HCUserSettings * settings = nil;
    HCUserSummary * summary = nil;
    if(userData )
    {
         user = [[UserInformation alloc]initWithDictionary:[result objectForKey:@"data"]];
        if(user.UserID <=0)
            PP_RELEASE(user);
    }
    if([result objectForKey:@"settings"])
    {
        NSString * setStr = [result objectForKey:@"settings"];
        if([setStr isKindOfClass:[NSDictionary class]])
        {
            settings = [[HCUserSettings alloc]initWithDictionary:(NSDictionary*)setStr];
        }
        else
        {
            settings = [[HCUserSettings alloc]initWithJSON:setStr];
        }
        if(settings.UserID <=0) PP_RELEASE(settings);
    }
    if([result objectForKey:@"summary"])
    {
        summary = [[HCUserSummary alloc]initWithDictionary:[result objectForKey:@"summary"]];
        if(summary.UserID <=0) PP_RELEASE(summary);
    }
    HCUser_Extend * userExtend = [[HCUser_Extend alloc]init];
    userExtend.User = user;
    userExtend.UserID = UserID;
    userExtend.Summary = summary;
    userExtend.Settings = settings;
    return PP_AUTORELEASE(userExtend);
}



@end

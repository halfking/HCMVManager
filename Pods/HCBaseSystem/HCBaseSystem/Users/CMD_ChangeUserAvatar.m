//
//  CMD_ChangeUserAvatar.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/12.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMD_ChangeUserAvatar.h"
#import <hccoren/base.h>
#import "HCCallResultForWT.h"
#import "HCDBHelper(WT).h"

@implementation CMD_ChangeUserAvatar
@synthesize Avatar,UserID;

- (id)init
{
    if(self = [super init])
    {
        CMDID_ = 37;
        useHttpSender_ = YES;
    }
    return self;
}
- (BOOL)calcArgsAndCacheKey
{
    if(!Avatar ||Avatar.length==0) return NO;
    NSLog(@"A_2_7_0_37_保存用户Avatar");
    //    DeviceConfig * info = [DeviceConfig Instance];
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 @(UserID),@"userid",
                                 @"2.7.0",@"scode",
                                 Avatar==nil?@"":Avatar,@"headportrait",
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
        //        ret.Data = (HCEntity *)[self parseData:result];
    }
    
    return PP_AUTORELEASE(ret);
}

- (HCEntity*)parseData:(NSDictionary *)result
{
    return nil;
    //    NSDictionary * userData = [result objectForKey:@"data"];
    //
    //    HCUserSummary * summary = nil;
    //    if(userData )
    //    {
    //        summary = [[HCUserSummary alloc]initWithDictionary:[result objectForKey:@"summary"]];
    //        if(summary.UserID <=0) PP_RELEASE(summary);
    //    }
    //    return PP_AUTORELEASE(summary);
}

@end

//
//  CMD_GetSingedOnCertainSample.m
//  maiba
//
//  Created by SeenVoice on 15/8/26.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import "CMD_GetUserMTVBySample.h"
#import <hccoren/base.h>
#import <hccoren/JSON.h>

@implementation CMD_GetUserMTVBySample

@synthesize sampleID;
@synthesize userID;

- (id)init
{
    if(self = [super init])
    {
        CMDID_ = 12821;
        useHttpSender_ = YES;
        isPost_ = NO;
    }
    return self;
}

- (BOOL)calcArgsAndCacheKey
{
    NSLog(@"A_5_2_0_1_获取某个样例下，我唱过的MTV");
    //    DeviceConfig * info = [DeviceConfig Instance];
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:
                          @([self userID]),@"userid",
                          @(self.sampleID),@"sampleid",
                          @"5.2.0",@"scode", nil];
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
    
    if(ret.Code ==0)
    {
        if([result objectForKey:@"data"])
        {
            MTV * item = [[MTV alloc]initWithDictionary:[result objectForKey:@"data"]];
            ret.Data = item;
            PP_RELEASE(item);
        }
    }
    
    return PP_AUTORELEASE(ret);
}

- (NSObject*)parseData:(NSDictionary *)result
{
    return nil;
}
@end


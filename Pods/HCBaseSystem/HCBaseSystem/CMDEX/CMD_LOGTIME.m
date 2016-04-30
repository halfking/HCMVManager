//
//  CMD_LOGTIME.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/7/28.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMD_LOGTIME.h"
#import <hccoren/base.h>

#import "HCCallResultForWT.h"
#import "HCDBHelper(WT).h"

@implementation CMD_LOGTIME
@synthesize log;
- (id)init
{
    if(self = [super init])
    {
        CMDID_ = 900;
        useHttpSender_ = YES;
//        isPost_ = NO;
    }
    return self;
}
- (BOOL)calcArgsAndCacheKey
{
    NSLog(@"A_9_1_0_900_记录CMDLog ");
    
    NSMutableDictionary * dic = [[NSMutableDictionary alloc]init];
    
    [dic setObject:@"9.1.0" forKey:@"scode"];
    
    if(log)
        [dic setObject:log forKey:@"data"];
    else
        return NO;
    
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
    //    NSMutableArray * result = [[NSMutableArray alloc]init];
    //
    //    DBHelper * db = [DBHelper sharedDBHelper];
    //
    //    NSString * sql = [NSString stringWithFormat:@"select * from starts order by BeginMonthDay ASC;"];
    //    if([db open])
    //    {
    //        [db execWithArray:result class:NSStringFromClass([UserStars class]) sql:sql];
    //        [db close];
    //    }
    //
    //    if(result.count>0)
    //        return PP_AUTORELEASE(result);
    //    else
    //        PP_RELEASE(result);
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
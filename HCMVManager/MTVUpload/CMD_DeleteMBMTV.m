//
//  CMD_DeleteMBMTV.m
//  maiba
//
//  Created by SeenVoice on 15/8/26.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import "CMD_DeleteMBMTV.h"
#import <hccoren/base.h>
#import <HCBaseSystem/CMD_WT.h>
#import <HCBaseSystem/Database_WT.h>
@implementation CMD_DeleteMBMTV
@synthesize MBMTVID;
@synthesize sampleID,mtvID;

- (id)init
{
    if(self = [super init])
    {
        CMDID_ = 12841;
        useHttpSender_ = YES;
        isPost_ = NO;
    }
    return self;
}
   
- (BOOL)calcArgsAndCacheKey
{
    NSLog(@"A_5_4_0_删除麦霸MTV");
    //    DeviceConfig * info = [DeviceConfig Instance];
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:
                          @([self userID]),@"userid",
                          @(MBMTVID),@"mbmtvid",
                          @(mtvID),@"mtvid",
                          @(sampleID),@"sampleid",
                          @"5.4.0",@"scode", nil];
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
    if(ret.Code==0)
    {
        NSString * sql = nil;
        if(mtvID>0)
            sql =  [NSString stringWithFormat:@"delete from mtvs where mtvid=%ld;",mtvID];
        else
            sql = [NSString stringWithFormat:@"delete from mtvs where sampleid=%ld and userid=%ld;",sampleID,[self userID]];
        DBHelper * db = [DBHelper sharedDBHelper];
        if([db open])
        {
            [db execNoQuery:sql];
            [db close];
        }
    }
    return PP_AUTORELEASE(ret);
}
   
- (NSObject*)parseData:(NSDictionary *)result
{
    return nil;
}
   @end
   

//
//  CMD_UploadMBMTV.m
//  maiba
//
//  Created by SeenVoice on 15/8/26.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import "CMD_UploadMBMTV.h"
#import <hccoren/base.h>
#import <hccoren/json.h>
@implementation CMD_UploadMBMTV

@synthesize data;
@synthesize Materials;
@synthesize MBMTVID,MTVID;
- (id)init
{
    if(self = [super init])
    {
        CMDID_ = 12831;
        useHttpSender_ = YES;
        isPost_ = YES;
    }
    return self;
}

- (BOOL)calcArgsAndCacheKey
{
    NSLog(@"A_5_3_0_1_上传麦霸MTV");
    //    DeviceConfig * info = [DeviceConfig Instance];
    if(!data) return NO;
    NSMutableDictionary * dic = nil;
    if(data)
    {
        if(_justUpdateKey==1)
        {
            dic = [NSMutableDictionary new];
            [dic setObject:@(data.MTVID) forKey:@"mtvid"];
            [dic setObject:data.Key?data.Key:@"" forKey:@"key"];
            [dic setObject:data.Author?data.Author:@"" forKey:@"author"];
            [dic setObject:@(data.UserID) forKey:@"userid"];
            [dic setObject:@(data.IsLandscape) forKey:@"islandscape"];
        }
        else if(_justUpdateKey==2)
        {
            dic = [NSMutableDictionary new];
            [dic setObject:@(data.MTVID) forKey:@"mtvid"];
            [dic setObject:@(data.SampleID) forKey:@"sampleid"];
            [dic setObject:@(data.MBMTVID) forKey:@"mbmtvid"];
            [dic setObject:@(data.IsLandscape) forKey:@"islandscape"];
            [dic setObject:data.Memo?data.Memo:@"" forKey:@"memo"];
            [dic setObject:data.Tag?data.Tag:@"" forKey:@"tag"];
            [dic setObject:data.Title?data.Title:@"" forKey:@"title"];
            [dic setObject:data.CoverUrl?data.CoverUrl:@"" forKey:@"coverurl"];
            
            [dic setObject:@(data.Durance) forKey:@"durance"];
            
            [dic setObject:data.Key?data.Key:@"" forKey:@"key"];
            [dic setObject:data.Author?data.Author:@"" forKey:@"author"];
            [dic setObject:@(data.UserID) forKey:@"userid"];
            [dic setObject:[CommonUtil stringFromDate:[NSDate date]] forKey:@"uploadtime"];
        }
        else
        {
            dic = [data toDicionary];
        }
    }
    NSDictionary * dic2 = [NSDictionary dictionaryWithObjectsAndKeys:
                           @([data UserID]), @"UserID",
                           @([data SampleID]),@"SampleID",
                           dic?[dic JSONRepresentationEx]:@"{}", @"Data",
                           Materials?[Materials JSONRepresentationEx]:@"",@"Materials",
                           [NSNumber numberWithInteger:self.justUpdateKey],@"updatekey",
                           @"5.3.0",@"scode", nil];
    if(args_) PP_RELEASE(args_);
    args_ = PP_RETAIN([dic2 JSONRepresentationEx]);
    if(argsDic_) PP_RELEASE(argsDic_);
    argsDic_ = PP_RETAIN(dic2);
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
        if([result objectForKey:@"mtvid"])
        {
            ret.MTVID = [[result objectForKey:@"mtvid"] longValue];
            MTVID = ret.MTVID;
        }
        if([result objectForKey:@"mbmtvid"])
        {
            MBMTVID = [[result objectForKey:@"mbmtvid"] longValue];
        }
        if([result objectForKey:@"data"])
        {
            ret.Data = (HCEntity *)[self parseData:result];
        }
        else
        {
            MTV * item = [MTV new];
            item.MTVID = MTVID;
            item.MBMTVID = MBMTVID;
            
            ret.Data = item;
        }
        {
            MTV * item = (MTV*)ret.Data;
            if(!item.CoverUrl)
            {
                item.CoverUrl = self.data.CoverUrl;
            }
            if(!item.Title)
            {
                item.Title = self.data.Title;
            }
            if(!item.FileName)
            {
                [item setFilePathN:self.data.FileName];
            }
        }
    }
    
    return PP_AUTORELEASE(ret);
}

- (NSObject*)parseData:(NSDictionary *)result
{
    NSDictionary * dic = [result objectForKey:@"data"];
    MTV * item = [[MTV alloc]initWithDictionary:dic];
    if(item.MTVID ==0)
    {
        item.MTVID = self.MTVID;
    }
    
    return PP_AUTORELEASE(item);
}
@end


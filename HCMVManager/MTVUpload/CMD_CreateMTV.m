//
//  CMD_CreateMTV.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/6/19.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMD_CreateMTV.h"
#import <hccoren/base.h>
#import <HCBaseSystem/CMD_WT.h>
#import <HCBaseSystem/Database_WT.h>
#import "MTVFile.h"
@implementation CMD_CreateMTV
@synthesize MtvData;
@synthesize mtvID = mtvID_;
- (id)init
{
    if(self = [super init])
    {
        CMDID_ = 9;
        useHttpSender_ = YES;
        mtvID_ = 0;
        self.justUpdateKey = NO;
    }
    return self;
}
- (BOOL)calcArgsAndCacheKey
{
    NSLog(@"A_1_9_0_9_用户创建MTV");
    DeviceConfig * info = [DeviceConfig Instance];
    NSMutableDictionary * dic = nil;
    if(MtvData)
    {
        if(_justUpdateKey==1)
        {
            dic = [NSMutableDictionary new];
            [dic setObject:@(MtvData.MTVID) forKey:@"mtvid"];
            [dic setObject:MtvData.Key?MtvData.Key:@"" forKey:@"key"];
            [dic setObject:MtvData.Author?MtvData.Author:@"" forKey:@"author"];
            [dic setObject:@(MtvData.UserID) forKey:@"userid"];
            [dic setObject:@(MtvData.IsLandscape) forKey:@"islandscape"];
        }
        else if(_justUpdateKey==2)
        {
            dic = [NSMutableDictionary new];
            [dic setObject:@(MtvData.MTVID) forKey:@"mtvid"];
            [dic setObject:@(MtvData.SampleID) forKey:@"sampleid"];
            [dic setObject:@(MtvData.MBMTVID) forKey:@"mbmtvid"];
            [dic setObject:@(MtvData.IsLandscape) forKey:@"islandscape"];
            [dic setObject:MtvData.Memo?MtvData.Memo:@"" forKey:@"memo"];
            [dic setObject:MtvData.Tag?MtvData.Tag:@"" forKey:@"tag"];
            [dic setObject:MtvData.Title?MtvData.Title:@"" forKey:@"title"];
            [dic setObject:MtvData.CoverUrl?MtvData.CoverUrl:@"" forKey:@"coverurl"];
            
            [dic setObject:MtvData.Key?MtvData.Key:@"" forKey:@"key"];
            [dic setObject:MtvData.Author?MtvData.Author:@"" forKey:@"author"];
            [dic setObject:@(MtvData.UserID) forKey:@"userid"];
            [dic setObject:[CommonUtil stringFromDate:[NSDate date]] forKey:@"uploadtime"];
        }
        else
        {
            dic = [MtvData toDicionary];
        }
    }
    NSDictionary * dic2 = [NSDictionary dictionaryWithObjectsAndKeys:
                          //                          info.UDI,@"ClientID",
                          //#ifdef IS_MANAGERCONSOLE
                          //                          @([SystemConfiguration sharedSystemConfiguration].loginUserID),@"UserID",
                          //#else
                          @([self userID]),@"UserID",
                          dic==nil?@"null":[dic JSONRepresentationEx],@"data",
                          @"1.9.0",@"Scode",
                          info.IPAddress,@"IP",
                          [NSNumber numberWithInteger:self.justUpdateKey],@"updatekey",
                          nil];
    orgMtvID_ = MtvData.MTVID;
    
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
- (long) insertIntoDB:(MTV *)data
{
    DBHelper * db = [DBHelper sharedDBHelper];
    NSInteger newID = 0;
    //获取当前的最大的负ID
    if(data.MTVID == 0)
    {
        NSString * sql = [NSString stringWithFormat:@"select min(mtvID) as MtvID FROM mtvs"];
        NSString * newIDStr = nil;
        
        if([db open])
        {
            [db execScalar:sql result:&newIDStr];
            [db close];
        }
        if(newIDStr!=nil && newIDStr.length>0)
        {
            newID = [newIDStr integerValue];
        }
        if(newID >=0) newID = -1;
        else newID --;
        
        data.MTVID = newID;
    }
    
    
    mtvID_ = data.MTVID;
    
    orgMtvID_ = mtvID_;
    
    BOOL ret = [db insertData:data needOpenDB:YES forceUpdate:YES];
    if(ret)
        return data.MTVID;
    else
        return 0;
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
        //要注意本地文件地址保存，因为服务端的数据也许不会保存这些数据 的。
        MTV * data =(MTV *)[self parseData:result];
        ret.Data = (HCEntity*)data;
        if(self.justUpdateKey==NO && mtvID_>0)
        {
            //更新本地数据的ID
            DBHelper * db = [DBHelper sharedDBHelper];
            if([db open ])
            {
                NSLog(@"remove temp mtv:[%ld]",orgMtvID_);
                [db execNoQuery:[NSString stringWithFormat:@"delete from mtvs where MTVID = %li;",orgMtvID_!=0?orgMtvID_:MtvData.MTVID]];
                MtvData.MTVID = mtvID_;
               
                NSLog(@"insert new mtv:[%ld]%@",MtvData.MTVID,MtvData.Title);
                
                [db insertData:data needOpenDB:NO forceUpdate:YES];
                
                //记录LocalFile
                if(MtvData.FileName && MtvData.FileName.length>0)
                {
                    MTVFile * file = [MTVFile new];
                    file.MTVID = mtvID_;
                    file.FilePath = MtvData.FileName;// [MtvData getFilePathN];
                    file.Key = [MtvData getKey];
                    
                    [db insertData:file needOpenDB:NO forceUpdate:YES];
                }
                [db close];
            }
        }
    }
    return PP_AUTORELEASE(ret);
}

- (MTV*)parseData:(NSDictionary *)result
{
    NSDictionary * musicDic = result;
    if(!musicDic ) return nil;
    if([musicDic objectForKey:@"mtvid"])
    {
        mtvID_ = [[musicDic objectForKey:@"mtvid"]longValue];
    }
    
    MTV * newData = [[MTV alloc]initWithJSON:[MtvData JSONRepresentationEx]];
    newData.MTVID = mtvID_;
    return newData;
    //    //PARSEDATA(funDic, fun, Music);
    //    PARSEDATA(musicDic, item, Music);
    //
    //    PARSEDATAARRAY(musicObjects,musics,MTV);
    //
    //    return PP_AUTORELEASE(musicObjects);
}
@end

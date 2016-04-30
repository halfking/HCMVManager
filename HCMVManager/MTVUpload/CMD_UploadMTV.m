//
//  CMD_UploadMTV.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/12.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMD_UploadMTV.h"
#import <hccoren/base.h>
//#import "DeviceConfig.h"
#import <HCBaseSystem/CMD_WT.h>
#import <HCBaseSystem/Database_WT.h>

@implementation CMD_UploadMTV
@synthesize MtvData;
- (id)init
{
    if(self = [super init])
    {
        CMDID_ = 17;
        useHttpSender_ = YES;
        isPost_ = YES;
    }
    return self;
}
- (BOOL)calcArgsAndCacheKey
{
    NSLog(@"A_1_15_0_17_上传用户MTV");
    //data:{mtvid,key,downloadurl,filepath}
    
    NSDictionary * dataDic = nil;
    if(_uploadType==1)
    {
        dataDic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:MtvData.MTVID],@"mtvid",
                   MtvData.AudioFileName?MtvData.AudioFileName:@"",@"audiopath",
                   MtvData.AudioRemoteUrl?MtvData.AudioRemoteUrl:@"",@"audioremoteurl",
                   [MtvData getAudioKey]?[MtvData getAudioKey]:@"",@"audiokey",
                   nil];
    }
    else if(_uploadType==2)
    {
        dataDic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:MtvData.MTVID],@"mtvid",
                   [MtvData getKey]?[MtvData getKey]:@"",@"key",
                   MtvData.DownloadUrl?MtvData.DownloadUrl:@"",@"downloadurl",
                   MtvData.FileName?MtvData.FileName:@"",@"filepath",
                   MtvData.CoverUrl?MtvData.CoverUrl:@"",@"coverurl",
                   @(MtvData.Durance),@"durance",
                   nil];
    }
    else
    {
        dataDic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLong:MtvData.MTVID],@"mtvid",
                   [MtvData getKey]?[MtvData getKey]:@"",@"key",
                   MtvData.DownloadUrl?MtvData.DownloadUrl:@"",@"downloadurl",
                   MtvData.FileName?MtvData.FileName:@"",@"filepath",
                   MtvData.AudioFileName?MtvData.AudioFileName:@"",@"audiopath",
                   MtvData.AudioRemoteUrl?MtvData.AudioRemoteUrl:@"",@"audioremoteurl",
                   [MtvData getAudioKey]?[MtvData getAudioKey]:@"",@"audiokey",
                   MtvData.CoverUrl?MtvData.CoverUrl:@"",@"coverurl",
                   @(MtvData.Durance),@"durance",
                   nil];
    }
    DeviceConfig * info = [DeviceConfig Instance];
    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:
                          //                          info.UDI,@"ClientID",
                          //#ifdef IS_MANAGERCONSOLE
                          //                          @([SystemConfiguration sharedSystemConfiguration].loginUserID),@"UserID",
                          //#else
                          @([self userID]),@"UserID",
                          [dataDic JSONRepresentationEx],@"data",
                          @"1.15.0",@"Scode",
                          info.IPAddress,@"IP",
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
    //save data
    DBHelper * db = [DBHelper sharedDBHelper];
    if([db open ])
    {
        [db insertData:MtvData needOpenDB:NO forceUpdate:YES];
        [db close];
    }
    
    return nil;
}
//- (NSInteger) insertIntoDB:(MTV *)data
//{
//    DBHelper * db = [DBHelper sharedDBHelper];
//    NSInteger newID = 0;
//    //获取当前的最大的负ID
//    if(data.MusicID == 0)
//    {
//        NSString * sql = [NSString stringWithFormat:@"select min(mtvID) as MtvID FROM mtvs"];
//        NSString * newIDStr = nil;
//
//        if([db open])
//        {
//            [db execScalar:sql result:&newIDStr];
//            [db close];
//        }
//        if(newIDStr!=nil && newIDStr.length>0)
//        {
//            newID = [newIDStr integerValue];
//        }
//    }
//
//    if(newID >=0) newID = -1;
//    else newID --;
//
//    data.MTVID = newID;
//
//    BOOL ret = [db insertData:data needOpenDB:YES forceUpdate:YES];
//    if(ret)
//        return data.MTVID;
//    else
//        return 0;
//}
//- (BOOL)setUploadProgress:(long)mtvID bytes:(NSInteger)bytes downloadUrl:(NSString *)downloadUrl
//{
//    NSString * filePath = nil;
//    DBHelper * db = [DBHelper sharedDBHelper];
//    if([db open])
//    {
//        NSString * sql = [NSString stringWithFormat:@"select filepath from mtvs where mtvid = %ld;",mtvID];
//        [db execScalar:sql result:&filePath];
//        if(filePath==nil||filePath.length<=3)
//        {
//            [db close];
//            return NO;
//        }
//        return [self setUploadProgressA:filePath bytes:bytes downloadUrl:downloadUrl];
//    }
//    return NO;
//}
//
//- (BOOL)setUploadProgressA:(NSString*)filePath bytes:(NSInteger)bytes downloadUrl:(NSString *)downloadUrl
//{
//    if(!filePath||filePath.length==0) return NO;
//    long uploadID = 0;
//    DBHelper * db = [DBHelper sharedDBHelper];
//    if([db open])
//    {
//        UploadRecord * record = [[UploadRecord alloc]init];
//
//        NSString * sql =[NSString stringWithFormat:@"select * from uploads where filepath='%@';",filePath];
//
//        [db execWithEntity:record sql:sql];
//
//
//        //new
//        if(record.UploadID==0)
//        {
//            sql =[NSString stringWithFormat:@"select max(uploadid) from uploads; "];
//            NSString * uploadIDStr = nil;
//            [db execScalar:sql result:&uploadIDStr];
//            if(uploadIDStr==nil||uploadIDStr.length==0||[uploadIDStr isEqualToString:@"0"])
//            {
//                uploadID = 1;
//            }
//            else
//            {
//                uploadID = (long)[uploadIDStr longLongValue];
//                uploadID++;
//            }
//
//            NSFileManager * fileM = [NSFileManager defaultManager];
//            NSError * error = nil;
//            NSDictionary * dic = [fileM attributesOfItemAtPath:filePath error:&error];
//
//            if(error)
//            {
//                NSLog(@"get file attribute failure:%@",[error description]);
//            }
//            record.FileSize = (long)dic.fileSize;
//            record.BytesUploaded = bytes;
//
//            record.UploadBeginTime = [CommonUtil stringFromDate:[NSDate date]];
//            if(bytes>=record.FileSize)
//            {
//                record.IsUploaded = 2;
//            }
//            else if(bytes>0)
//            {
//                record.IsUploaded = 1;
//            }
//            else
//            {
//                record.IsUploaded = 0;
//            }
//
//            record.FilePath = filePath;
//            record.UploadID = uploadID;
//            record.UserID = [self userID];
//            record.IsSynced = NO;
//
//            if(downloadUrl)
//            {
//                record.DownloadUrl = downloadUrl;
//            }
//
//            [db insertData:record needOpenDB:NO forceUpdate:NO];
//
//        }
//        else //upload
//        {
//            record.BytesUploaded = bytes;
//            if(bytes>=record.FileSize)
//            {
//                record.IsUploaded = 2;
//            }
//            else if(bytes>0)
//            {
//                record.IsUploaded = 1;
//            }
//            else
//            {
//                record.IsUploaded = 0;
//            }
//            if(downloadUrl)
//            {
//                record.DownloadUrl = downloadUrl;
//            }
//            record.UploadEndTime =[CommonUtil stringFromDate:[NSDate date]];
//            [db insertData:record needOpenDB:NO forceUpdate:YES];
//        }
//        [db close];
//        return YES;
//    }
//    return NO;
//}
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
        MTV * data =(MTV *)[self parseData:result];
        ret.Data = (HCEntity*)data;
        //        if(data.MTVID>0)
        //        {
        //            DBHelper * db = [DBHelper sharedDBHelper];
        //            if([db open ])
        //            {
        //                [db execNoQuery:[NSString stringWithFormat:@"delete from mtvs where MTVID = %ld;",MtvData.MTVID]];
        //                [db insertData:ret.Data needOpenDB:NO forceUpdate:YES];
        //                [db close];
        //            }
        //        }
    }
    
    
    
    return PP_AUTORELEASE(ret);
}

- (MTV*)parseData:(NSDictionary *)result
{
    NSDictionary * musicDic = [result objectForKey:@"data"];
    if(!musicDic ) return nil;
    MTV * newData = [[MTV alloc]initWithJSON:[MtvData JSONRepresentationEx]];
    if(newData.MTVID <=0)
        newData.MTVID = [[musicDic objectForKey:@"id"] integerValue];
    return newData;
}
@end

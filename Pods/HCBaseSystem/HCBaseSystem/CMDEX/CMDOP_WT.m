//
//  CMDOP_SX.m
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-11-27.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "CMDOP_WT.h"
#import "CMDS_WT.h"
#import <hccoren/database.h>
#import <hccoren/CommonUtil.h>
#import "CMD_LOGTIME.h"
#import "CMDLog.h"
#import <hccoren/json.h>

@implementation CMDOP_WT
- (id)init
{
    if(self = [super init])
    {
    }
    return self;
}
//- (CMDHeader *)getHeader:(NSString *)responseString
//{
//    CMDSocketHeader * header = [[CMDSocketHeader alloc]initWithString:responseString];
//    header.MessageID = self.messageID;
//    return PP_AUTORELEASE(header);
//}
//- (CMDHeader *)getHeader
//{
//    CMDSocketHeader * header = [[CMDSocketHeader alloc]init];
//    header.MessageID = self.messageID;
//    return PP_AUTORELEASE(header);
//}
- (CMDs *)getCMDs
{
    if(!currentCMDs_)
        currentCMDs_ = (CMDs*)[CMDS_WT sharedCMDS_WT];
    return currentCMDs_;
}
- (NSString *)getMessageID
{
    //mesageid的userid前半部
    long userID = 0;
    if(params_)
    {
        userID = [[params_ objectForKey:@"userid"]longValue];
    }
    else
    {
        userID = [self userID];
    }
    NSString * userIDString = [CommonUtil leftFillZero:[CommonUtil toHEXstring:userID] withLength:8];
    
    //mesageid的毫秒数后半部
    
    NSString * time = nil;
    if(currentCMDs_)
        time = [currentCMDs_ getCurrentTimeForMessageID];
    else
        time = [[self getCMDs] getCurrentTimeForMessageID];
    
    return [NSString stringWithFormat:@"%@%@",userIDString,time];
}

#pragma mark - public funs
- (long)userID
{
    return [(CMDS_WT*)[self getCMDs]userID];
}
- (NSString *)mobile
{
    return [(CMDS_WT*)[self getCMDs]mobile];
}
- (NSString *)userName
{
    return [(CMDS_WT*)[self getCMDs]userName];
}
//- (int) hotelID
//{
//    return [(CMDS_WT*)[self getCMDs]hotelID];
//}
- (void)setPageSize:(int)ps pageIndex:(int)pi
{
    pageIndex_ = pi;
    pageSize_ = ps;
}
- (void)CheckDBIsNeedClear:(NSString *)keyName data:(NSDictionary *)data entity:(HCEntity*)entity
{
    int pageIndex = pageIndex_;
    
    if([data objectForKey:@"pageindex"])
    {
        pageIndex = [[data objectForKey:@"pageindex"]intValue];
    }
    int hotelID =0;
    if([data objectForKey:keyName])
    {
        hotelID = [[data objectForKey:keyName]intValue];
    }
    else if([data objectForKey:@"args"])
    {
        NSString * args = [data objectForKey:@"args"];
        if(args)
        {
            NSDictionary * dic = [args JSONValueEx];
            if([dic objectForKey:keyName])
            {
                hotelID = [[dic objectForKey:keyName]intValue];
            }
        }
        
    }
    if(pageIndex==0 && hotelID>0)
    {
        NSString * sql = [NSString stringWithFormat:@"delete from %@ where hotelID=%d;",entity.TableName,hotelID];
        if([[DBHelper sharedDBHelper]open])
        {
            [[DBHelper sharedDBHelper]execNoQuery:sql];
            [[DBHelper sharedDBHelper]close];
        }
    }
}
#ifdef LOGCMDTIME
- (void)    logCMD:(CMDLog *)log
{
    if(log.CMDID == 900) return;
    if([DeviceConfig config].networkStatus==ReachableNone) return;
    
    log.UserID = [self userID];
    CMD_LOGTIME * cmd = (CMD_LOGTIME *)[[CMDs sharedCMDs]createCMDOP:@"LOGTIME"];
    cmd.log = log;
    [cmd sendCMD];
}
#endif
@end

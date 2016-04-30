//
//  HCDBHelper(SX).m
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-17.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "HCDBHelper(WT).h"
#import <hccoren/CommonUtil.h>
#import <hccoren/CommonUtil(Date).h>

//#import "CommonUtil.h"
//#import "CommonUtil(Date).h"
//#import "SystemConfiguration.h"

//#import "HCDBHelper-initSX.h"
#import "HCUserFriend.h"
#import "HCUserConcern.h"

#import "HCMessageItem.h"
#import "HCMessageGroup.h"
#import "HCTransferItem.h"
#import "CMDS_WT.h"
#import "UserManager.h"

@implementation DBHelper_WT
SYNTHESIZE_SINGLETON_FOR_CLASS_NEW(DBHelper_WT)
//
//static DBHelper_SX *sharedDBHelper_SX = nil;
//+ (DBHelper_SX *)sharedDBHelper_SX
//{
//    if(sharedDBHelper_SX == nil)
//    {
//        @synchronized(self)
//        {
//            if (sharedDBHelper_SX == nil)
//            {
//
//                sharedDBHelper_SX = [[DBHelper_SX alloc] init];
//            }
//        }
//    }
//
//    return sharedDBHelper_SX;
//}

//+ (id)allocWithZone:(NSZone *)zone \
//{ \
//    @synchronized(self) \
//    { \
//        if (sharedDBHelper_SX == nil) \
//        { \
//            sharedDBHelper_SX= [super allocWithZone:zone]; \
//            return sharedDBHelper_SX; \
//        } \
//    } \
//    \
//    return nil; \
//} \
//\
//- (id)copyWithZone:(NSZone *)zone \
//{ \
//    return self; \
//} \
//\
//- (id)retain \
//{ \
//    return self; \
//} \
//\
//- (NSUInteger)retainCount \
//{ \
//    return NSUIntegerMax; \
//} \
//\
//- (oneway void)release \
//{ \
//} \
//\
//- (id)autorelease \
//{ \
//    return self; \
//}
- (id)init
{
    if(self = [super init])
    {
        //[DBHelper setInstance:self];
    }
    return self;
}
- (void)dealloc
{
    PP_RELEASE(createMoreTable_);
    //    cmdParent_.delegate = nil;
    PP_SUPERDEALLOC;
}
- (void)addCreateMoreDelegate:(id<CreateTables>)delegate
{
    PP_RELEASE(createMoreTable_);
    
    createMoreTable_ = PP_RETAIN(delegate);
}
+ (long)getMaxImageID
{
    NSString * ret = nil;
    NSString * sql = @"select max(imageid) from images;";
    if([[DBHelper sharedDBHelper]open])
    {
        [[DBHelper sharedDBHelper]execScalar:sql result:&ret];
        [[DBHelper sharedDBHelper]close];
    }
    if(ret && ret.length>0)
    {
        return [ret intValue];
    }
    return 1;
}

#pragma mark - cmd udpate time
+ (QCMDUpdateTime *)getCMDLastUpdate:(NSString *)winClass cmdID:(int)cmdID
{
    NSString * sql = [NSString stringWithFormat:@"select * from cmdupdatetime where CMDID=%d and WindowID='%@' order by LastUpdateTime Desc;",cmdID,winClass];
    QCMDUpdateTime * time = [QCMDUpdateTime new];
    if([[DBHelper sharedDBHelper]open])
    {
        [[DBHelper sharedDBHelper]execWithEntity:time sql:sql];
        [[DBHelper sharedDBHelper]close];
    }
    if(time && time.CMDID==cmdID)
    {
        return PP_AUTORELEASE(time);
    }
    else
    {
        PP_RELEASE(time);
        return nil;
    }
}
+(void) updateCMDLastUpdate:(NSString *)winClass cmdID:(int)cmdID result:(HCCallbackResult *)result
{
    if(!winClass) return;
    if(!result)
    {
        QCMDUpdateTime * time = [QCMDUpdateTime new];
        time.WindowID = winClass;
        time.CMDID = cmdID;
        time.LastUpdateTime =  [CommonUtil stringFromDate:[NSDate date]];
        time.Status = 1;
        time.ResultMD5 = nil;
        [[DBHelper sharedDBHelper]insertData:time needOpenDB:YES forceUpdate:YES];
        PP_RELEASE(time);
    }
    else if(result.Code==0 && result.IsFromDB==NO)
    {
        QCMDUpdateTime * time = [QCMDUpdateTime new];
        time.WindowID = winClass;
        time.CMDID = cmdID;
        if(result.ArgsHash)
        {
            time.ArgsHash = result.ArgsHash;
        }
        else if(result.Args)
        {
            time.ArgsHash = [CommonUtil md5Hash:[result.Args JSONRepresentationEx]];
        }
        if([result.Args objectForKey:@"scode"])
            time.Scode = [result.Args objectForKey:@"scode"];
        time.LastUpdateTime =  [CommonUtil stringFromDate:[NSDate date]];
        time.Status = 1;
        time.ResultMD5 = nil;
        [[DBHelper sharedDBHelper]insertData:time needOpenDB:YES forceUpdate:YES];
        PP_RELEASE(time);
    }
    
}
#pragma mark - messages
+(BOOL)MessageGroupExists:(long)groupID
{
    NSString * sql = [NSString stringWithFormat:@"select count(*) from messagegroup where GroupNoticeID=%ld; ",groupID];
    BOOL ret = NO;
    if([[DBHelper sharedDBHelper]open])
    {
        NSString * retString = nil;
        [[DBHelper sharedDBHelper]execScalar:sql result:&retString];
        [[DBHelper sharedDBHelper]close];
        if(retString && retString.length>0)
        {
            ret = [retString intValue]>0;
        }
    }
    return ret;
}
+(void)updateGroupNoticeNewCount:(long)groupnoticeid
{
    //删除本地数据
    if([[DBHelper sharedDBHelper] open])
    {
        NSString *sql = [[NSString alloc] initWithFormat:@"update messagegroup set NewCount = 0 where GroupNoticeID = %ld" , groupnoticeid ] ;
        [[DBHelper sharedDBHelper] execNoQuery:sql];
        [[DBHelper sharedDBHelper]close];
        PP_RELEASE(sql);
    }
    
}
+(void)deleteMessageGroup:(long)groupid
{
    if([[DBHelper sharedDBHelper] open])
    {
        NSString * sql = [NSString stringWithFormat:@"delete from messagegroup where GroupNoticeID = %ld;",groupid];
        
        [[DBHelper sharedDBHelper] execNoQuery:sql];
        sql = [NSString stringWithFormat:@"delete  from messages where GroupNoticeID = %ld;",groupid];
        [[DBHelper sharedDBHelper] execNoQuery:sql];
        sql = [NSString stringWithFormat:@"delete  from transfers where GroupNoticeID = %ld;",groupid];
        [[DBHelper sharedDBHelper] execNoQuery:sql];
        [[DBHelper sharedDBHelper]close];
    }
}
+(NSArray *)getUserConcernList:(long)userID objectType:(int)objectType objectIDs:(NSString *)objectIDs
{
    if(userID<=0) userID = [[CMDS_WT sharedCMDS_WT] userID];
    //查询数据库
    NSMutableArray * array = [[NSMutableArray alloc]init];
    
    if([[DBHelper sharedDBHelper] open])
    {
        NSString * sql1 = nil;
        NSString * className = nil;
        if(objectType== HCObjectTypeUser)
        {
            NSString * sql0 = @"select * from userfellows";
            className = [NSString stringWithCString:object_getClassName([HCUserFriend class]) encoding:NSUTF8StringEncoding];
            
            sql1 = [NSString stringWithFormat:@"%@ where fw_userid = %ld and FW_FellowUserID in (%@);",
                    sql0,userID,objectIDs];
            
        }
        else
        {
            className = [NSString stringWithCString:object_getClassName([HCUserConcern class]) encoding:NSUTF8StringEncoding];
            NSString * sql0 = @"select * from sys_user_favorite";
            
            sql1 = [NSString stringWithFormat:@"%@ where userid = %ld and objecttype= %d and objectid in (%@) and favtype='concern';",
                    sql0,userID,objectType,objectIDs];
        }
        
        [[DBHelper sharedDBHelper] execWithArray:array class:className sql:sql1];
        [[DBHelper sharedDBHelper]close];
    }
    if([array count]>0)
    {
        return PP_AUTORELEASE(array);
        
    }
    else
    {
        PP_RELEASE(array);
        return nil;
    }
}
#pragma mark - messages
+(HCMessageGroup *)getMessageGroup:(long)groupID
{
    NSMutableString * sql = [[NSMutableString alloc]init];
    [sql appendFormat:@"select * from messagegroup where GroupNoticeID=%ld ",groupID];
    
    HCMessageGroup * group = [[HCMessageGroup alloc]init];
    if([[DBHelper sharedDBHelper]open])
    {
        [[DBHelper sharedDBHelper]execWithEntity:group sql:sql];
        [[DBHelper sharedDBHelper]close];
    }
    PP_RELEASE(sql);
    if(group.GroupNoticeID==0)
    {
        PP_RELEASE(group);
        return nil;
    }
    else
    {
        return PP_AUTORELEASE(group);
    }
}
+(HCMessageGroup *)getMessageGroup:(long)receiverBelongID rec:(long)receiverID rectype:(int)receiverTypeID userID:(long)userID
{
    NSMutableString * sql = [[NSMutableString alloc]init];
    [sql appendString:@"select * from messagegroup where "];
    if(receiverTypeID!=HCObjectTypeUser)
    {
        [sql appendFormat:@" HotelID=%ld",receiverBelongID];
#ifdef IS_MANAGERCONSOLE
        [sql appendFormat:@" and SourceUserID=%ld",userID];
#else
        [sql appendFormat:@" and UserID=%ld",userID];
#endif
    }
    else
    {
        [sql appendFormat:@" SourceUserID=%ld",receiverID];
        [sql appendFormat:@" and UserID=%ld",userID];
    }
    [sql appendString:@" and groupnoticeid>0 ;"];
    HCMessageGroup * group = [[HCMessageGroup alloc]init];
    if([[DBHelper sharedDBHelper]open])
    {
        [[DBHelper sharedDBHelper]execWithEntity:group sql:sql];
        [[DBHelper sharedDBHelper]close];
    }
    PP_RELEASE(sql);
    if(group.GroupNoticeID==0)
    {
        PP_RELEASE(group);
        return nil;
    }
    else
    {
        return  PP_AUTORELEASE(group);//[group autorelease];
    }
}
+(BOOL)deleteMessageByGroupForDB:(HCMessageGroup *)group
{
    NSLog(@"delete messages...");
    if(!group) return NO;
    NSMutableString * sql = [[NSMutableString alloc]init];
    [sql appendFormat:@"delete from messages where groupnoticeid=%d or groupnoticeid= %d ; ",group.GroupNoticeID,group.OppositeNoticeID];
    NSLog(@"delete messages:%@",sql);
    if([[DBHelper sharedDBHelper]open])
    {
        [[DBHelper sharedDBHelper]execNoQuery:sql ];
        [[DBHelper sharedDBHelper]close];
    }
    
    PP_RELEASE(sql);
    return YES;
}
//获取消息得详情
+(HCMessageItem*)getMessageItem:(long)messageID andMessageGroupType:(HCMessageGroupType)msgType
{
    //查询数据库
    HCMessageItem * item = [HCMessageItem new];
    //    NSString * className = [NSString stringWithCString:object_getClassName([HCMessageItem class]) encoding:NSUTF8StringEncoding];
    if([[DBHelper sharedDBHelper] open])
    {
        NSString * sql = [NSString stringWithFormat:@"select * from messages where messageid = %ld;",messageID];
        
        [[DBHelper sharedDBHelper] execWithEntity:item sql:sql];
        [[DBHelper sharedDBHelper]close];
    }
    
    if(item && item.MessageID>0)
    {
        
        return PP_AUTORELEASE(item);
    }
    else
    {
        PP_RELEASE(item);
        return nil;
    }
}
//删除本地数据
+(void)deleteAllMessage{
    if([[DBHelper sharedDBHelper] open])
    {
        NSString *sql = @"delete  from messages;";
        [[DBHelper sharedDBHelper] execNoQuery:sql];
        sql = @"delete  from transfers;";
        [[DBHelper sharedDBHelper] execNoQuery:sql];
        sql = @"delete from messagegroup;";
        [[DBHelper sharedDBHelper] execNoQuery:sql];
        
        [[DBHelper sharedDBHelper]close];
        [[UserManager sharedUserManager]resetSummary];
        
    }
}


+ (dispatch_queue_t)getDBQueue
{
    return [DBHelper getDBQueue];
}
+ (BOOL)isDBThread
{
    return dispatch_get_current_queue() == [DBHelper_WT getDBQueue];
}
@end

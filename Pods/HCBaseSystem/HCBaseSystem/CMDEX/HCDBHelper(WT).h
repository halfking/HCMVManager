//
//  HCDBHelper(SX).h
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-17.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <hccoren/database.h>
#import <hccoren/HCCallbackResult.h>
#import "HCMessageItem.h"
#import "HCMessageGroup.h"


//#import "HCRegion.h"


//@class QSystemCategory;

//@class HCCategory,HCBillGoods,HCBillLogs,HCShopFunRuler;
@protocol CreateTables

- (BOOL) createTables:(DBHelper *)dbHelper;

@end
@interface DBHelper_WT:NSObject
{
    id<CreateTables> createMoreTable_;
}
+ (DBHelper_WT *)      sharedDBHelper_WT;
- (void) addCreateMoreDelegate:(id<CreateTables>)delegate;
+ (long) getMaxImageID;

//获取窗口的最后刷新时间。根据窗口中典型的命令与窗口类型名称
+(QCMDUpdateTime *)getCMDLastUpdate:(NSString *)winClass cmdID:(int)cmdID;
//更新当前窗口的刷新时间
+(void) updateCMDLastUpdate:(NSString *)winClass cmdID:(int)cmdID result:(HCCallbackResult *)result;

+(BOOL)MessageGroupExists:(long)groupID;
+(void)updateGroupNoticeNewCount:(long)groupnoticeid;
+(void)deleteMessageGroup:(long)groupid;
+(NSArray *)getUserConcernList:(long)userID objectType:(int)objectType objectIDs:(NSString *)objectIDs;
+(HCMessageItem*)getMessageItem:(long)messageID andMessageGroupType:(HCMessageGroupType)msgType;
+(BOOL)deleteMessageByGroupForDB:(HCMessageGroup *)group;
+(HCMessageGroup *)getMessageGroup:(long)receiverBelongID rec:(long)receiverID rectype:(int)receiverTypeID userID:(long)userID;
+(HCMessageGroup *)getMessageGroup:(long)groupID;
+(void)deleteAllMessage;



+ (dispatch_queue_t)getDBQueue;
+ (BOOL)isDBThread;

@end

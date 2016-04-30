//
//  HCDBHelper-initSX.m
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-11.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "HCDBHelper-initWT.h"
#import <hccoren/database.h>
#import <hccoren/HCImageItem.h>
#import <hccoren/HCCacheItem.h>
//#import "HCMessageGroup.h"
//#import "HCMessageItem.h"
//#import "HCTransferItem.h"
#import "QTimespan.h"
#import "HCUserSettings.h"
#import "UserInformation.h"
#import "HCUserFriend.h"
#import "HCUserConcern.h"
//#import "HCUserCredit.h"

//#import "PrefixHeader.pch"

//#import "PageTag.h"

#import "UDInfo.h"

//#import "HCRegion.h"
//#import "UserStars.h"

//#import "MTV.h"
//#import "Music.h"
//#import "UploadRecord.h"
//#import "PlayRecord.h"
//#import "MTVFile.h"
//#import "MBMTV.h"
//#import "Material.h"
//#import "PageTag.h"



@implementation DBHelper_WT(Init)

extern sqlite3* database_;
//发新版，数据结构有变化时，让系统强制更新数据结构
//此处易用最新的表，原版本中没有的表
- (BOOL)testDatabase
{
    BOOL isDBOK = YES;
    DBHelper * helper = [DBHelper sharedDBHelper];
    if([helper open])
    {
        NSString * result = nil;
        UDInfo * mtv = [UDInfo new];
        isDBOK = [helper execScalar:@"select max(Key) from udinfos;" result:&result];
        if(isDBOK && result && result.length>0)
        {
            isDBOK = [helper execWithEntity:mtv sql:[NSString stringWithFormat:@"select * from udinfos where key='%@';",result]];
            if(isDBOK && mtv.Key)
            {
                isDBOK  = [helper insertData:mtv needOpenDB:NO forceUpdate:YES];
            }
        }
        [helper close];
    }
    return isDBOK;
}
- (BOOL)createDatabase
{
    PP_BEGINPOOL(pool);
    NSString *path = [[DBHelper sharedDBHelper]databaseFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL find = [fileManager fileExistsAtPath:path];
    
#ifndef FORCE_UPDATEDB
    if (find) {
        NSLog(@"**OK** database file:%@ exits.",path);
        [fileManager removeItemAtPath:path error:nil];
        find =  YES;
    }        //    sqlite3 * cdatabase_;
    else
    {
        BOOL unzipped =[[DBHelper sharedDBHelper]unzipDBFile];
        find = [fileManager fileExistsAtPath:path];
        if(find &&unzipped)
        {
            find = YES;
        }
        else
        {
            find = NO;
        }
    }
#else
    if (find) {
        NSLog(@"**OK** database file:%@ exits. remove item.",path);
        [fileManager removeItemAtPath:path error:nil];
        find = NO;
    }
#endif
    NSLog(@"):%@",path);
    //文件有，但需要检查是否正确
    if(find)
    {
        if([self testDatabase])
        {
            return YES;
        }
        else //数据库文件可能已经破坏
        {
            [fileManager removeItemAtPath:path error:nil];
            find = NO;
        }
    }
    DBHelper * helper = [DBHelper sharedDBHelper];
#if USE_FMDATABASE
    if([helper open]){
#else
        if(sqlite3_open([path UTF8String], &database_) == SQLITE_OK) {
#endif
            //    if(sqlite3_open_v2([path UTF8String], &database_,SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,NULL) == SQLITE_OK) {
            //        helper->bFirstCreate_ = YES;
            
            CREATETABLE(helper, HCMessageGroup);
            
            CREATETABLE(helper, HCMessageItem);
            
            CREATETABLE(helper, HCTransferItem);
            
            CREATETABLE(helper, HCUserSettings);
            
            CREATETABLE(helper, HCUserSummary);
            
            CREATETABLE(helper, UserInformation);
            
            
            
            CREATETABLE(helper, UDInfo);
            
            [helper execNoQuery:@"CREATE INDEX idx_udinfos_orgurl ON udinfos(OrgUrl);"];
            
          
            
            CREATETABLE(helper, QTimespan);
            
            CREATETABLE(helper, HCUserConcern);
            
            CREATETABLE(helper, HCUserFriend);
            CREATETABLE(helper, HCImageItem);
           
                      
            CREATETABLE(helper, HCCacheItem);
            
            [helper execNoQuery:@"CREATE INDEX idx_cacheitems_cmdid ON cacheitems(CMDID);"];
            CREATETABLE(helper, QCMDUpdateTime);
            
            
            [helper commit];
            
            if(createMoreTable_)
            {
                [createMoreTable_ createTables:helper];
            }
            
#if PP_ARC_ENABLED
            return [helper returnCreateResult:YES];
#else
            return [helper returnCreateResult:YES pool:pool];
#endif
        } else {
            NSLog(@"Error: create database file.%@",[helper getError]);
#if PP_ARC_ENABLED
            return [helper returnCreateResult:NO];
#else
            return [helper returnCreateResult:NO pool:pool];
#endif
            //sqlite3_close(database_);
        }
    }
    
    @end

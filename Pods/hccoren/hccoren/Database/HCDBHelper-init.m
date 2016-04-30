//
//  HCDBHelper-init.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-17.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "HCDBHelper-init.h"
#import "HCDbHelper.h"


//#import "HCSkin.h"
//#import "HCWeather.h"
//#import "HCWeatherInfo.h"
//#import "QSystemCategory.h"
//#import "QCommentItems.h"
//#import "HCRegion.h"
//#import "QFilterItem.h"
//#import "QBZone.h"
#if USE_FMDATABASE
#import "FMDB.h"
#endif
@implementation DBHelper(init)
#if USE_FMDATABASE
extern FMDatabase* database_;
#else
extern sqlite3* database_;
#endif

- (BOOL)removeDatabase
{
    NSString *path = [[DBHelper sharedDBHelper] databaseFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL find = [fileManager fileExistsAtPath:path];
    
    if (find) {
        NSLog(@"Database file have already existed.deleting....");
        NSError * error = nil;
        [fileManager removeItemAtPath:path error:&error];
        if(error)
        {
            NSLog(@"delete db error:%@",[error description]);
            return NO;
        }
    }
    return YES;
}
- (BOOL)createDatabase
{
    PP_BEGINPOOL(pool);
    NSString *path = [[DBHelper sharedDBHelper] databaseFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL find = [fileManager fileExistsAtPath:path];
    
    if(!find)
    {
        [self unzipDBFile];
        find = [fileManager fileExistsAtPath:path];
    }
    if (find) {
        return YES;
    }
#if USE_FMDATABASE
    database_ = [FMDatabase databaseWithPath:path];
    if([database_ open]){
#else
    if(sqlite3_open([path UTF8String], &database_) == SQLITE_OK) {
#endif
        bFirstCreate_ = YES;

#if PP_ARC_ENABLED
        return [self returnCreateResult:YES];
#else
        return [self returnCreateResult:YES pool:pool];
#endif
    } else {
        NSLog(@"Error: create database file.%@",[self getError]);
#if PP_ARC_ENABLED
        return [self returnCreateResult:NO];
#else
        return [self returnCreateResult:NO pool:pool];
#endif
        //sqlite3_close(database_);
    }
}
    
#if PP_ARC_ENABLED
- (BOOL)returnCreateResult:(BOOL)ret
{
    #if USE_FMDATABASE
        BOOL ret1 =  [self close];
        if(!ret1)
        {
            NSLog(@"error:%@",[self getError]);
        }
        return  ret;
    #else
        int ret1 = sqlite3_close(database_);
        NSLog(@"Close database:%d",ret1);
        if(ret1 != SQLITE_OK)
        {
            NSLog(@"error:%@",[self getError]);
        }
        return ret;
    #endif
}
#else
- (BOOL)returnCreateResult:(BOOL)ret pool:(NSAutoreleasePool *)pool
{
    #if USE_FMDATABASE
        BOOL ret1 =  [database_ close];
        if(!ret1)
        {
            NSLog(@"error:%@",[self getError]);
        }
        [pool drain];
        return  ret;
    #else
        int ret1 = sqlite3_close(database_);
        NSLog(@"Close database:%d",ret1);
        if(ret1 != SQLITE_OK)
        {
            NSLog(@"error:%@",[self getError]);
        }
        [pool drain];
        return ret;
    #endif
}
#endif
- (BOOL)createTable:(HCEntity *)entity
{
    if(!entity) return NO;
    [self dropTable:entity];
    NSLog(@"create table[%@]...",entity.TableName);
    NSString * syntax = [HCSQLHelper getTableSyntax:entity];
//    DLog(@"create table:%@",syntax);
    return [self execNoQuery:syntax];
}
- (BOOL)dropTable:(HCEntity *)entity
{
    if(!entity) return NO;
    NSLog(@"drop table[%@]...",entity.TableName);
    NSString * syntax = [NSString stringWithFormat:@"drop table %@;",entity.TableName ];
    //    DLog(@"create table:%@",syntax);
    return [self execNoQuery:syntax];
}
- (BOOL)clearTable:(HCEntity *)entity
{
    if(!entity) return NO;
    NSLog(@"clear table[%@]...",entity.TableName);
    NSString * syntax = [NSString stringWithFormat:@"DELETE FROM %@;",entity.TableName ];
    //    DLog(@"create table:%@",syntax);
    return [self execNoQuery:syntax];
}

@end

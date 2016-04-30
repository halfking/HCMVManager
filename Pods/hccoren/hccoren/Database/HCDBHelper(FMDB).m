//
//  HCDBHelper(FMDB).m
//  maiba
//
//  Created by HUANGXUTAO on 15/11/15.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import "HCDBHelper(FMDB).h"
#import "HCDbHelper.h"
#import "HCBase.h"
#import "PublicMControls.h"
#import "HCSQLHelper.h"
#import "HCDBHelper-init.h"
//#import "HCImageItem.h"
//#import "QCMDUpdateTime.h"
#import "JSON.h"

#ifdef USE_FMDATABASE
#import "FMDB.h"
#endif

//#include <pthread.h>
//static pthread_mutex_t dbMutex=PTHREAD_MUTEX_INITIALIZER;

@implementation DBHelper(FMDB)

#ifdef USE_FMDATABASE
FMDatabase* database_;

-(FMDatabase *)database
{
    return database_;
}
-(id)init
{
    if(self=[super init])
    {

        NSString *path = [self databaseFilePath];
        //        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        //        NSString *documentsDirectory = [paths objectAtIndex:0];
        //        NSString *path = [documentsDirectory stringByAppendingPathComponent:DB_FILE];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL find = [fileManager fileExistsAtPath:path];
        
        if (find) {
            database_ = [FMDatabase databaseWithPath:path];
        }
        else
        {
            [self createDatabase];
            database_ = [FMDatabase databaseWithPath:path];
        }
        NSLog(@"physical path:%@",[self databaseFilePath]);
    }
    return self;
}

-(BOOL) open{
    LastErrorCode_ = SQLITE_OK;
    
    if(dbOpenCount_>0)
    {
        NSLog(@"db open not close:%d",dbOpenCount_);
        int i = 0;
        while (dbOpenCount_>0 && i < 100) {
            [NSThread sleepForTimeInterval:0.1f];
            //            sleep(100);
            i ++;
        }
        if(dbOpenCount_ >0)
            return NO;
        //        [self close];
        //        dbOpenCount_ = 0;
    }
    dbOpenCount_ ++;
    return [database_ open];
}
- (int)begin
{
    return [database_ beginTransaction];
}
- (int)commit
{
    return [database_ commit];
}
- (BOOL)close
{
    [database_ close];

    dbOpenCount_ -- ;
    return YES;
}

- (NSString *)getError
{
    return [[database_ lastError] description];
}
- (int)getErrorCode
{
    if([database_ lastError])
        return [[database_ lastError]code];
    else
        return 0;
}
- (BOOL) execNoQuery:(NSString *)sql
{
    LastErrorCode_ = SQLITE_OK;
    BOOL ret = NO;
    ret = [database_ executeUpdate:sql];
    if ([database_ hadError])
        ret = NO;
    else
        ret = YES;
    return ret;
}
-(BOOL) exit:(BOOL)ret statement:(sqlite3_stmt*)statement
{
    return [self exit:ret statement:statement autoClose:NO];
}
-(BOOL) exit:(BOOL)ret statement:(sqlite3_stmt*)statement autoClose:(BOOL)autoClose
{
    return YES;
}

- (BOOL) execScalar:(NSString *)sql result:(NSString **)result
{
    FMResultSet *rs = [database_ executeQuery:sql];
    BOOL ret = NO;
    if ([database_ hadError])
        ret = NO;
    else
        ret = YES;
    
    if ([rs next]) {
        *result = [rs stringForColumnIndex:0];
    }
    [rs close];
    return ret;
}
//- (BOOL) execWithKey:(NSString*)sql
//{
//    return YES;
//}
- (BOOL) execWithArray:(NSMutableArray*)fEntities class:(NSString *)className sql:(NSString*)sql
{
    LastErrorCode_ = SQLITE_OK;

    BOOL ret = NO;
    FMResultSet *rs = [database_ executeQuery:sql];
    if ([database_ hadError]) {
        ret = NO;
    }
    else
        ret = YES;
    while ([rs next]) {
        NSDictionary * dic = [rs resultDictionary];
        HCEntity * entity  = [[NSClassFromString(className) alloc] initWithDictionary:dic];
        if(entity)
        {
            [fEntities addObject:entity];
        }
        PP_RELEASE(entity);
    }
    [rs close];
    return ret;

}
- (BOOL) execWithDictionary:(NSMutableDictionary *)fEntity sql:(NSString *)sql
{
    LastErrorCode_ = SQLITE_OK;

    BOOL ret = NO;
    FMResultSet *rs = [database_ executeQuery:sql];
    if ([database_ hadError]) {
        ret = NO;
    }
    else
        ret = YES;
    if ([rs next]) {
        NSDictionary * dic = [rs resultDictionary];
        [fEntity setDictionary:dic];
    }
    [rs close];
    return ret;

}

- (BOOL) execWithEntity:(HCEntity *)fEntity sql:(NSString *)sql
{
    LastErrorCode_ = SQLITE_OK;

    BOOL ret = NO;
    FMResultSet *rs = [database_ executeQuery:sql];
    if ([database_ hadError]) {
        ret = NO;
    }
    else
        ret = YES;
    if ([rs next]) {
        NSDictionary * dic = [rs resultDictionary];
        [fEntity setProperties:dic];
    }
    [rs close];
    return ret;

}
#pragma mark - resetData
- (BOOL) resetData:(HCEntity*)fEntity
{
    LastErrorCode_ = SQLITE_OK;
    if(fEntity==nil)
    {
        NSLog(@"exec with array cannot accept parameter:fentities being null.");
        return NO;
    }

    //    if(![self dropTable:fEntity])
    //    {
    //        DLog(@"Cannot drop table %@;",fEntity.TableName);
    //        if(![self clearTable:fEntity])
    //        {
    //            DLog(@"Cannot clear table %@;",fEntity.TableName);
    //            return NO;
    //        }
    //    }
    if(![self createTable:fEntity])
    {
        return NO;
    }
    else
    {
        [self close];
        return YES;
    }
}
#pragma mark - insertdata
- (BOOL) insertDataArrayBatch:(NSArray *)data  forceUpdate:(BOOL)forceUpdate
{
    LastErrorCode_ = SQLITE_OK;
    return [self insertDataArray:data forceUpdate:forceUpdate];
}
- (BOOL) deleteExistsDataArray:(NSArray *)data
{
    LastErrorCode_ = SQLITE_OK;
    if(!data || data.count==0) return YES;
    NSMutableArray * deleteSqlArray = [[NSMutableArray alloc]init];
    
    NSMutableString * deleteWhere = [[NSMutableString alloc]init];
    for (HCEntity * entity in data) {
        [deleteWhere appendFormat:@"(%@) OR ",[HCSQLHelper getKeyCompareSyntax:entity]];
        if(deleteWhere.length> 10000)
        {
            NSString * deleteSql  = [HCSQLHelper getDeleteSyntax:[data objectAtIndex:0]
                                                           where:[deleteWhere substringToIndex:deleteWhere.length-3] ];
            [deleteSqlArray addObject:deleteSql];
            [deleteWhere deleteCharactersInRange:NSMakeRange(0, deleteWhere.length)];
        }
    }
    if(deleteWhere.length>0)
    {
        NSString * deleteSql  = [HCSQLHelper getDeleteSyntax:[data objectAtIndex:0]
                                                       where:[deleteWhere substringToIndex:deleteWhere.length-3] ];
        [deleteSqlArray addObject:deleteSql];
    }
    PP_RELEASE(deleteWhere);
    

    //    if([self open])
    //    {
    for (NSString * sql in deleteSqlArray) {
        if(![database_ executeStatements:sql])
        {
            //                [self close];
            return NO;
        }
    }
    //        [self close];
    return YES;
    //    }
    //    return NO;

}
- (BOOL) insertDataArray:(NSArray *)data  forceUpdate:(BOOL)forceUpdate
{
    LastErrorCode_ = SQLITE_OK;
    return [self insertDataArray:data forceUpdate:forceUpdate async:NO];
}
- (BOOL) insertDataArray:(NSArray *)data  forceUpdate:(BOOL)forceUpdate async:(BOOL)async
{
    LastErrorCode_ = SQLITE_OK;
    if(data==nil ||[data count]==0) return YES;

    BOOL ret = YES;
    if(!async)
    {
        if([self open])
        {
            NSDate * begin = [NSDate date];
            [self begin];
            [self deleteExistsDataArray:data];
            
            NSMutableDictionary * propDic = [[data objectAtIndex:0] getPropTypes:[[data objectAtIndex:0]  class]];
            
            NSString * sqlForPrepare = [HCSQLHelper getInsertSyntaxForPrepare:[data objectAtIndex:0] propDic:propDic];
            for (HCEntity * object in data)
            {
                NSArray * valList = [HCSQLHelper bindStateValueArray:object propDic:propDic];
                if(![database_ executeQuery:sqlForPrepare withArgumentsInArray:valList])
                {
                    ret = NO;
                    break;
                }
            }
            [self commit];
            [self close];
            
            NSDate * end = [NSDate date];
            NSTimeInterval time = [end timeIntervalSinceReferenceDate] - [begin timeIntervalSinceReferenceDate];
            if(time>0)
            {
                DLog(@"3 total:%d for time:%f,every %f per second",[data count],time,[data count]/time);
            }
        }
        else
            ret = NO;
    }
    else
    {
        if(data && data.count>0)
        {
            
            NSString *path = [self databaseFilePath];
            
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:path];
            [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                NSDate * begin = [NSDate date];
                NSMutableArray * deleteSqlArray = [[NSMutableArray alloc]init];
                NSMutableString * deleteWhere = [[NSMutableString alloc]init];
                for (HCEntity * entity in data) {
                    [deleteWhere appendFormat:@"(%@) OR ",[HCSQLHelper getKeyCompareSyntax:entity]];
                    if(deleteWhere.length> 10000)
                    {
                        NSString * deleteSql  = [HCSQLHelper getDeleteSyntax:[data objectAtIndex:0]
                                                                       where:[deleteWhere substringToIndex:deleteWhere.length-3] ];
                        [deleteSqlArray addObject:deleteSql];
                        [deleteWhere deleteCharactersInRange:NSMakeRange(0, deleteWhere.length)];
                    }
                }
                if(deleteWhere.length>0)
                {
                    NSString * deleteSql  = [HCSQLHelper getDeleteSyntax:[data objectAtIndex:0]
                                                                   where:[deleteWhere substringToIndex:deleteWhere.length-3] ];
                    [deleteSqlArray addObject:deleteSql];
                }
                PP_RELEASE(deleteWhere);
                
                
                for (NSString * sql in deleteSqlArray) {
                    if(![db executeStatements:sql])
                    {
                        *rollback = YES;
                        return;
                    }
                }
                
                
                
                NSMutableDictionary * propDic = [[data objectAtIndex:0] getPropTypes:[[data objectAtIndex:0]  class]];
                
                NSString * sqlForPrepare = [HCSQLHelper getInsertSyntaxForPrepare:[data objectAtIndex:0] propDic:propDic];
                for (HCEntity * object in data)
                {
                    NSArray * valList = [HCSQLHelper bindStateValueArray:object propDic:propDic];
                    if(![db executeQuery:sqlForPrepare withArgumentsInArray:valList])
                    {
                        *rollback = YES;
                        break;
                    }
                }
                
                NSDate * end = [NSDate date];
                NSTimeInterval time = [end timeIntervalSinceReferenceDate] - [begin timeIntervalSinceReferenceDate];
                if(time>0)
                {
                    DLog(@"3 total:%d for time:%f,every %f per second",[data count],time,[data count]/time);
                }
                
            }];
        }
    }
    
    return ret;
    
}
- (BOOL)checkResultForRebuild:(HCEntity *)object needOpenDB:(BOOL)needOpenDB
{
    int code = [self getErrorCode];
    if(code ==SQLITE_ERROR || code==SQLITE_MISMATCH)
    {
        //        [self dropTable:object];
        [self createTable:object];
    }
    else
    {
        NSString * codeString = [self getError];
        if([codeString rangeOfString:@"no such"].length>0||[codeString rangeOfString:@"not an error"].length>0)
        {
            [self createTable:object];
        }
        else
        {
            if(needOpenDB)
                [self close];
            return NO;
        }
    }
    return YES;
}
- (BOOL) insertData:(HCEntity *)object needOpenDB:(BOOL)needOpenDB  forceUpdate:(BOOL)forceUpdate
{
    LastErrorCode_ = SQLITE_OK;
    if(object==nil) return YES;
    BOOL isExists = NO;
    BOOL ret = TRUE;

    if(needOpenDB) [self open];
    NSString * sql = [HCSQLHelper getExistsSyntax:object];
    if(sql)
    {
        FMResultSet * set = [database_ executeQuery:sql];
        if ([database_ hadError])
            ret = NO;
        else
            ret = YES;
        if(ret)
        {
            if ([set next]) {
                isExists = [set intForColumn:0]>0?YES:NO;
            }
        }
        if(isExists && !forceUpdate)
        {
            ret = YES;
        }
        else
        {
            NSString * deleteSql = [HCSQLHelper getDeleteSyntax:object];
            if(![database_ executeStatements:deleteSql])
            {
                if(![self checkResultForRebuild:object needOpenDB:needOpenDB])
                {
                    return NO;
                }
            }
            //图片需要多一重处理
            if([object isKindOfClass:[HCImageItem class]])
            {
                HCImageItem * item = (HCImageItem*)object;
                if(item.Src)
                {
                    NSString * sql = [NSString stringWithFormat:@"delete from %@ where Src='%@' and ObjectID=%d and ObjectType=%d;",object.TableName,item.Src,item.ObjectID,item.ObjectType];
                    [database_ executeStatements:sql];
                }
            }
            
            // add new data
            NSString * sql = [HCSQLHelper getInsertSyntax:object];
            if(sql && [sql length]>5)
            {
                if(![database_ executeStatements:sql])
                {
                    //                DLog(@"database error code:%d",[self getErrorCode])
                    //                NSString * error = [self getError];
                    int code = [self getErrorCode];
                    if(code ==SQLITE_ERROR || code==SQLITE_MISMATCH)
                        //if(code ==1 || [error rangeOfString:@"no such"].length>0||[error rangeOfString:@"no column"].length>0)
                    {
                        //                        [self dropTable:object];
                        [self createTable:object];
                        ret = [database_ executeStatements:sql];
                    }
                    else
                        ret = NO;
                }
            }
            else
                ret = NO;
        }
    }
    else
        ret = NO;
    if(needOpenDB)
        [self close];
    return ret;
    
}
#endif

@end

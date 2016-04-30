#import "HCDbHelper.h"
#import "HCBase.h"
#import "PublicMControls.h"
#import "HCSQLHelper.h"
#import "HCDBHelper-init.h"
#import "HCImageItem.h"
#import "QCMDUpdateTime.h"
//#import "CommonUtil.h"
#import "HCFileManager.h"
#import "JSON.h"
#import <sqlite3.h>
#include <pthread.h>
static pthread_mutex_t dbMutex=PTHREAD_MUTEX_INITIALIZER;

@implementation DBHelper

#ifndef USE_FMDATABASE
sqlite3 * database_;
#endif

SYNTHESIZE_SINGLETON_FOR_CLASS_NEW(DBHelper)
- (NSString *)databaseFilePath
{
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[@"Library/Caches" stringByAppendingPathComponent:DB_FILE]];
    return path;
}
- (BOOL)unzipDBFile
{
    NSString * dbPath = [self databaseFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:dbPath]) {
        //result = [filemanager copyItemAtPath:dbPath toPath:toPath error:&error];
        NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip",DB_FILE]];
        NSString * targetPath = [NSHomeDirectory() stringByAppendingPathComponent:[@"Library/Caches" stringByAppendingPathComponent:@""]];
        
        //if db not exists
        if([fileManager fileExistsAtPath:sourcePath])
        {
            BOOL result = [HCFileManager unZipFileFrom:sourcePath to:targetPath];
            if (result) {
                //            [fileManager removeItemAtPath:sourcePath error:nil];
                return YES;
            }
            else
            {
                NSLog(@"**** unzip file:%@ failure *******",sourcePath);
            }
        }
        //        else
        
        {
            
            NSLog(@"***** not found db zipped, create default db. ******");
            
            if(sqlite3_open([targetPath UTF8String], &database_) != SQLITE_OK) {
                //        if(sqlite3_open_v2([path UTF8String], &database_,SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,NULL) != SQLITE_OK) {
                sqlite3_close(database_);
                NSLog(@"Error: open database file:%@.",targetPath);
                return NO;
            }
            
            sqlite3_close(database_);
            return NO;
        }
    }
    return YES;
}
-(void)dealloc
{
//    if(timer_)
//    {
//        [timer_ invalidate];
//        PP_RELEASE(timer_);
//    }
    //    if(ticketCondition_) [ticketCondition_ release];
    PP_SUPERDEALLOC;
}
-(void)unlock
{
//    if(timer_)
//    {
//        [timer_ invalidate];
//        PP_RELEASE(timer_);
//    }
    //    [ticketCondition_ tryLock];
    //    [ticketCondition_ unlock];
}
-(BOOL)dbExists
{
    //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //    NSString *documentsDirectory = [paths objectAtIndex:0];
    //    NSString *path = [documentsDirectory stringByAppendingPathComponent:DB_FILE];
    NSString *path = [self databaseFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL find = [fileManager fileExistsAtPath:path];
    return find;
}
- (void)testForDB
{
    NSString * sql = [NSString stringWithFormat:@"select * from cmdupdatetime where CMDID=%d and WindowID='%@' order by LastUpdateTime Desc;",130,@"HotelListViewController-0"];
    QCMDUpdateTime * time = [QCMDUpdateTime new];
    if([[DBHelper sharedDBHelper]open])
    {
        [[DBHelper sharedDBHelper]execWithEntity:time sql:sql];
        [[DBHelper sharedDBHelper]close];
    }
    NSLog(@"updatetime test:%@",[time JSONRepresentationEx]);
    PP_RELEASE(time);
}

#ifndef USE_FMDATABASE
-(id)init
{
    if(self=[super init])
    {
        sqlite3_config(SQLITE_CONFIG_SERIALIZED); //WAL + SERIAL 不需要使用并发模式
        NSLog(@"physical path:%@",[self databaseFilePath]);
    }
    return self;
}

-(BOOL) open{
    LastErrorCode_ = SQLITE_OK;
    
    if(dbOpenCount_>0)
    {
        NSLog(@"db open not close:%d",dbOpenCount_);
        if(database_)
        {
            dbOpenCount_ ++;
            return YES;
        }
        int i = 0;
        while (dbOpenCount_>0 && i < 10) {
            [NSThread sleepForTimeInterval:0.1f];
            //            sleep(100);
            i ++;
        }
        if(dbOpenCount_ >0)
        {
            return NO;
        }
        //        [self close];
        //        dbOpenCount_ = 0;
    }
    NSString *path = [self databaseFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL find = [fileManager fileExistsAtPath:path];
    if(!find)
    {
        [self unzipDBFile];
        find = [fileManager fileExistsAtPath:path];
    }
    if (find) {
        //NSLog(@"Database file have already existed.");
        if(sqlite3_open([path UTF8String], &database_) != SQLITE_OK) {
            //        if(sqlite3_open_v2([path UTF8String], &database_,SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,NULL) != SQLITE_OK) {
            sqlite3_close(database_);
            NSLog(@"Error: open database file.");
            return NO;
        }
        char * errorMsg = nil;
        if (sqlite3_exec(database_, "PRAGMA journal_mode=WAL;", NULL, NULL, &errorMsg) != SQLITE_OK) {
            
            NSLog(@"Failed to set WAL mode: %s", errorMsg);
            
        }
        //        sqlite3_wal_checkpoint(database_, NULL); // 每次测试前先checkpoint，避免WAL文件过大而影响性能
        
        //        sqlite3_exec(database_,"PRAGMA synchronous = OFF; ",0,0,0);
        dbOpenCount_ ++;
        return YES;
    }
    if(![self createDatabase]) return NO;
    
    if(sqlite3_open([path UTF8String], &database_) == SQLITE_OK) {
        //    if(sqlite3_open_v2([path UTF8String], &database_,SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,NULL) == SQLITE_OK) {
        bFirstCreate_ = YES;
        //[self createEntityTable:database_];//在后面实现函数createChannelsTable
        //        sqlite3_exec(database_,"PRAGMA synchronous = OFF; ",0,0,0);
        char * errorMsg = nil;
        if (sqlite3_exec(database_, "PRAGMA journal_mode=WAL;", NULL, NULL, &errorMsg) != SQLITE_OK) {
            
            NSLog(@"Failed to set WAL mode: %s", errorMsg);
            
        }
        sqlite3_wal_checkpoint(database_, NULL); // 每次测试前先checkpoint，避免WAL文件过大而影响性能
        dbOpenCount_ ++;
        return YES;
    } else {
        sqlite3_close(database_);
        dbOpenCount_ = 0;
        database_ = nil;
        NSLog(@"Error: open database file.");
        return NO;
    }
    return NO;
}
- (int)begin
{
    return sqlite3_exec(database_,"begin;",0,0,0);
}
- (int)commit
{
    return sqlite3_exec(database_,"commit;",0,0,0);
}
- (BOOL)close
{
    if(dbOpenCount_ <=0)
    {
        NSLog(@"close more....");
        return NO;
    }
    
    //    sqlite3_wal_checkpoint(database_, NULL); // 每次测试前先checkpoint，避免WAL文件过大而影响性能
    dbOpenCount_ --;
    if(dbOpenCount_ <=0)
    {
        sqlite3_close(database_);
//        if(timer_ )
//        {
//            [timer_ invalidate];
//            PP_RELEASE(timer_);
//        }
        database_ = nil;
    }
    else
    {
        NSLog(@"not realy close database .... %d",dbOpenCount_);
    }
    //    dbOpenCount_ -- ;
    //    [ticketCondition_ tryLock];
    //    [ticketCondition_ unlock];
    return YES;
}

- (NSString *)getError
{
    return [NSString stringWithCString:sqlite3_errmsg(database_) encoding:NSUTF8StringEncoding];
}
- (int)getErrorCode
{
    if(LastErrorCode_!=0)
    {
        return LastErrorCode_;
    }
    else
        return sqlite3_errcode(database_);
}
- (BOOL) execNoQuery:(NSString *)sql
{
    LastErrorCode_ = SQLITE_OK;
    const char * sqlchar = [sql cStringUsingEncoding:NSUTF8StringEncoding];
    sqlite3_stmt *statement = nil;
    int rc = SQLITE_OK;
    int nRetry = 0;
    //　线程安全：加锁保护
    //    sqlite3_mutex_enter(database_->mutex);
    // 设置错误为OK
    //    sqlite3Error(database_, SQLITE_OK, 0);
    
    pthread_mutex_lock(&dbMutex);
    while (rc == SQLITE_OK ||(rc==SQLITE_SCHEMA && (++nRetry)<2)) {
        rc =sqlite3_prepare_v2(database_, sqlchar, -1, &statement, nil) ;
        assert( rc==SQLITE_OK || (!statement));
        if( rc!=SQLITE_OK ){
#ifndef            __OPTIMIZE__
            NSString * error = [self getError];
            NSLog(@"Error: failed to prepare statement:%@",sql);
            NSLog(@"Error: %@",error);
#endif
            LastErrorCode_ = rc;
            return [self exit:NO statement:statement];
            //            continue;
        }
        if( !statement ){
            // 前导语句错误 . 这是在语句前有注释或者空格的条件下会发生
            //sqlchar = zLeftover;
            continue;
        }
        
        int success = sqlite3_step(statement);
        
        if ( success != SQLITE_DONE  && success!=SQLITE_ROW) {
            NSLog(@"Error: %@",sql);
            NSLog(@"ERROR: %@",[self getError]);
            LastErrorCode_ = success;
            return [self exit:NO statement:statement];
        }
        return [self exit:YES statement:statement];
    }
    //assert( (rc&db->errMask)==rc );
    //sqlite3_mutex_leave(db->mutex);
    
    //NSLog(@"Create table 'channels' successed.");
    return [self exit:NO statement:statement];
}
-(BOOL) exit:(BOOL)ret statement:(sqlite3_stmt*)statement
{
    return [self exit:ret statement:statement autoClose:NO];
}
-(BOOL) exit:(BOOL)ret statement:(sqlite3_stmt*)statement autoClose:(BOOL)autoClose
{
    @try {
        if(statement)
            sqlite3_finalize(statement);
        
        sqlite3_wal_checkpoint(database_, NULL); // 每次测试前先checkpoint，避免WAL文件过大而影响性能
        
        if(autoClose)
            [self close];
    }
    @catch (NSException *exception) {
        NSLog(@"sqlite3 error:%@",[exception description]);
    }
    @finally {
        
    }
    pthread_mutex_unlock(&dbMutex);
    //sqlite3_mutex_leave(db->mutex);
    //    if(pool_) {
    //        [pool_ release];
    //        pool_ = nil;
    //    }
    
    return ret;
}
- (BOOL) execScalar:(NSString *)sql result:(NSString **)result
{
    LastErrorCode_ = SQLITE_OK;
    
    const char * sqlchar = [sql cStringUsingEncoding:NSUTF8StringEncoding];
    sqlite3_stmt *statement = nil;
    
    int rc = SQLITE_OK;
    int nRetry = 0;
    
    pthread_mutex_lock(&dbMutex);
    
    while (rc == SQLITE_OK ||(rc==SQLITE_SCHEMA && (++nRetry)<2)) {
        rc =sqlite3_prepare_v2(database_, sqlchar, -1, &statement, nil) ;
        assert( rc==SQLITE_OK || (!statement));
        if( rc!=SQLITE_OK ){
            NSLog(@"Error: failed to prepare statement:%@",sql);
            NSLog(@"Error:%@",[self getError]);
            LastErrorCode_ = rc;
            continue;
        }
        if( !statement ){
            // 前导语句错误 . 这是在语句前有注释或者空格的条件下会发生
            //sqlchar = zLeftover;
            continue;
        }
        
        int success = sqlite3_step(statement);
        //    sqlite3_finalize(statement);
        if ( success != SQLITE_ROW && success!=SQLITE_DONE) {
            NSLog(@"Error: failed to dehydrate:%@",sql);
            NSLog(@"Error:%@",[self getError]);
            //            if(pool)
            //            {
            //                [pool drain];
            //                pool = nil;
            //            }
            return [self exit:NO statement:statement];
        }
        else
        {
            if(result){
                if(success==SQLITE_DONE)
                {
                    *result = @"";
                }
                else
                {
                    
                    char* cid = (char*)sqlite3_column_text(statement, 0);
                    if(cid==nil)
                    {
                        *result = @"";
                    }
                    else
                    {
                        
                        if(*result ==nil)
                        {
                            *result = PP_AUTORELEASE([[NSString alloc]initWithCString:cid encoding:NSUTF8StringEncoding]);
                        }
                        else
                        {
                            NSString *  test = *result;
                            test = [test initWithCString:cid encoding:NSUTF8StringEncoding];
                            NSLog(@"test:%@",test);
                        }
                        
                    }
                }
            }
        }
        //        if(pool)
        //        {
        //            [pool drain];
        //            pool = nil;
        //        }
        return [self exit:YES statement:statement];
    }
    //    if(pool)
    //    {
    //        [pool drain];
    //        pool = nil;
    //    }
    return [self exit:NO statement:statement];
}
- (BOOL) execWithArray:(NSMutableArray*)fEntities class:(NSString *)className sql:(NSString*)sql
{
    LastErrorCode_ = SQLITE_OK;
    
    if(fEntities==nil)
    {
        NSLog(@"exec with array cannot accept parameter:fentities being null.");
        return NO;
    }
    //    PP_BEGINPOOL(pool);
    const char * sqlchar = [sql cStringUsingEncoding:NSUTF8StringEncoding];
    sqlite3_stmt *statement;
    int rc = SQLITE_OK;
    int nRetry = 0;
    
    pthread_mutex_lock(&dbMutex);
    
    while (rc == SQLITE_OK ||(rc==SQLITE_SCHEMA && (++nRetry)<2)) {
        rc =sqlite3_prepare_v2(database_, sqlchar, -1, &statement, nil) ;
        assert( rc==SQLITE_OK || (!statement));
        if( rc!=SQLITE_OK ){
            NSLog(@"Error: failed to prepare statement:%@",sql);
            NSLog(@"Error:%@",[self getError]);
            //            int code = [self getErrorCode];
            //            if(code ==SQLITE_ERROR || code==SQLITE_MISMATCH)
            //            {
            //                HCEntity * entity  = [[NSClassFromString(className) alloc] init];
            //                [self dropTable:entity];
            //                [self createTable:entity];
            //                [entity release];
            //            }
            LastErrorCode_ = rc;
            continue;
        }
        if( !statement ){
            // 前导语句错误 . 这是在语句前有注释或者空格的条件下会发生
            //sqlchar = zLeftover;
            continue;
        }
        
        int success = sqlite3_step(statement);
        //    sqlite3_finalize(statement);
        if ( success != SQLITE_ROW && success!=SQLITE_DONE) {
            NSLog(@"Error: failed to dehydrate:%@",sql);
            NSLog(@"Error:%@",[self getError]);
            //            PP_ENDPOOL(pool)
            LastErrorCode_ = success;
            return [self exit:NO statement:statement];
        }
        else
        {
            while(success == SQLITE_ROW)
            {
                @try {
                    HCEntity * entity  = [[NSClassFromString(className) alloc] init];
                    NSMutableDictionary * dics = [entity getPropTypes:[entity class]];
                    int colCount = sqlite3_column_count(statement);
                    id value = nil;
                    for(int colID = 0;colID <colCount;colID++)
                    {
                        const char * colName = sqlite3_column_name(statement,colID);
                        NSString * colName2 = [NSString stringWithCString:colName encoding:NSUTF8StringEncoding];
                        if(! [dics objectForKey:colName2]) continue;
                        
                        switch (sqlite3_column_type(statement,colID)) {
                            case SQLITE_INTEGER:
                                value = [NSNumber numberWithInt: sqlite3_column_int(statement, colID)];
                                //[entity setPropValue:colName value:value];
                                //                                [entity setValue:value forKey:colName2];
                                [entity setPropValue:colName2 value:value];
                                break;
                            case SQLITE_FLOAT:
                                value = [NSNumber numberWithDouble:sqlite3_column_double(statement,colID)];
                                [entity setPropValue:colName2 value:value];
                                //                                [entity setValue:value forKey:colName2];
                                break;
                            case SQLITE_TEXT:
                            {
                                const char * v1 = (const char *)sqlite3_column_text(statement, colID);
                                if(v1!=nil)
                                {
                                    value = [[NSString alloc]initWithCString:v1 encoding:NSUTF8StringEncoding];
                                    //                                    value = [NSString stringWithCString:v1 encoding:NSUTF8StringEncoding];
                                    [entity setPropValue:colName2 value:value];
                                    
                                    PP_RELEASE(value);
                                    //                                    [value release];
                                }
                                //                                value = [NSString stringWithCString:(const char *)sqlite3_column_text(statement, colID) encoding:NSUTF8StringEncoding];
                                //                                [entity setPropValue:colName2 value:value];
                                break;
                            }
                            case SQLITE_NULL:
                                value = [NSNull null];
                                [entity setPropValue:colName2 value:value];
                                break;
                            default:
                                
                                break;
                        }
                        
                    }
                    [fEntities addObject:entity];
                    PP_RELEASE(entity);
                    //                    [entity release];
                }
                @catch (NSException *exception) {
                    NSLog(@"Error:%@",[exception description]);
                    //                    PP_ENDPOOL(pool);
                    //                    if(pool)
                    //                    {
                    //                        [pool drain];
                    //                        pool = nil;
                    //                    }
                    return [self exit:NO statement:statement];
                }
                @finally {
                    
                }
                
                success = sqlite3_step(statement);
            }
            //            PP_ENDPOOL(pool)
            //            if(pool)
            //            {
            //                [pool drain];
            //                pool = nil;
            //            }
            return [self exit:YES statement:statement];
        }
    }
    //    PP_ENDPOOL(pool);
    //    if(pool)
    //    {
    //        [pool drain];
    //        pool = nil;
    //    }
    //NSLog(@"Create table 'channels' successed.");
    return [self exit:NO statement:statement];
}
- (BOOL) execWithDictionary:(NSMutableDictionary *)fEntity sql:(NSString *)sql
{
    LastErrorCode_ = SQLITE_OK;
    
    if(fEntity==nil)
    {
        NSLog(@"exec with array cannot accept parameter:fentities being null.");
        return NO;
    }
    //    PP_BEGINPOOL(pool);
    const char * sqlchar = [sql cStringUsingEncoding:NSUTF8StringEncoding];
    sqlite3_stmt *statement;
    int rc = SQLITE_OK;
    int nRetry = 0;
    
    pthread_mutex_lock(&dbMutex);
    
    while (rc == SQLITE_OK ||(rc==SQLITE_SCHEMA && (++nRetry)<2)) {
        rc =sqlite3_prepare_v2(database_, sqlchar, -1, &statement, nil) ;
        assert( rc==SQLITE_OK || (!statement));
        
        if( rc!=SQLITE_OK ){
            NSLog(@"Error: failed to prepare statement:%@",sql);
            NSLog(@"Error:%@",[self getError]);
            LastErrorCode_ = rc;
            continue;
        }
        if( !statement ){
            // 前导语句错误 . 这是在语句前有注释或者空格的条件下会发生
            //sqlchar = zLeftover;
            continue;
        }
        
        int success = sqlite3_step(statement);
        //    sqlite3_finalize(statement);
        if ( success != SQLITE_ROW && success!=SQLITE_DONE) {
            NSLog(@"Error: failed to step:%@",sql);
            NSLog(@"Error:%@",[self getError]);
            //            PP_ENDPOOL(pool);
            LastErrorCode_ = success;
            return [self exit:NO statement:statement];
        }
        else
        {
            if(success == SQLITE_ROW)
            {
                @try {
                    int colCount = sqlite3_column_count(statement);
                    id value = nil;
                    for(int colID = 0;colID <colCount;colID++)
                    {
                        const char * colName = sqlite3_column_name(statement,colID);
                        NSString * colName2 = [NSString stringWithCString:colName encoding:NSUTF8StringEncoding];
                        switch (sqlite3_column_type(statement,colID)) {
                            case SQLITE_INTEGER:
                                value = [NSNumber numberWithInt: sqlite3_column_int(statement, colID)];
                                [fEntity setObject:value forKey:colName2];
                                break;
                            case SQLITE_FLOAT:
                                value = [NSNumber numberWithDouble:sqlite3_column_double(statement,colID)];
                                [fEntity setObject:value forKey:colName2];
                                break;
                            case SQLITE_TEXT:
                                value = [NSString stringWithCString:(const char *)sqlite3_column_text(statement, colID) encoding:NSUTF8StringEncoding];
                                [fEntity setObject:value forKey:colName2];
                                break;
                            case SQLITE_NULL:
                                value = [NSNull null];
                                [fEntity setObject:value forKey:colName2];
                                break;
                            default:
                                
                                break;
                        }
                        
                    }
                }
                @catch (NSException *exception) {
                    NSLog(@"db error:%@",[exception description]);
                }
                @finally {
                    
                }
                
            }
        }
        //        PP_ENDPOOL(pool);
        return [self exit:YES statement:statement];
    }
    //    PP_ENDPOOL(pool);
    return [self exit:NO statement:statement];
}

- (BOOL) execWithEntity:(HCEntity *)fEntity sql:(NSString *)sql
{
    LastErrorCode_ = SQLITE_OK;
    
    if(fEntity==nil)
    {
        NSLog(@"exec with array cannot accept parameter:fentities being null.");
        return NO;
    }
    //    PP_BEGINPOOL(pool);
    const char * sqlchar = [sql cStringUsingEncoding:NSUTF8StringEncoding];
    sqlite3_stmt *statement;
    int rc = SQLITE_OK;
    int nRetry = 0;
    
    pthread_mutex_lock(&dbMutex);
    
    while (rc == SQLITE_OK ||(rc==SQLITE_SCHEMA && (++nRetry)<2)) {
        rc =sqlite3_prepare_v2(database_, sqlchar, -1, &statement, nil) ;
        assert( rc==SQLITE_OK || (!statement));
        if( rc!=SQLITE_OK ){
             NSString * error = [self getError];
            if(rc == SQLITE_SCHEMA || (rc==SQLITE_ERROR && ([error rangeOfString:@"no column"].length>0||[error rangeOfString:@"no such table"].length>0)))
            {
                pthread_mutex_unlock(&dbMutex);
                [self createTable:fEntity];
                pthread_mutex_lock(&dbMutex);
            }
            NSLog(@"Error: failed to prepare statement:%@",sql);
            NSLog(@"Error:%@",error);
            LastErrorCode_ = rc;
            continue;
        }
        if( !statement ){
            // 前导语句错误 . 这是在语句前有注释或者空格的条件下会发生
            //sqlchar = zLeftover;
            continue;
        }
        
        int success = sqlite3_step(statement);
        //    sqlite3_finalize(statement);
        if ( success != SQLITE_ROW && success!=SQLITE_DONE) {
            NSLog(@"Error: failed to step:%@",sql);
            NSLog(@"Error:%@",[self getError]);
            //            PP_ENDPOOL(pool);
            LastErrorCode_ = success;
            return [self exit:NO statement:statement];
        }
        else
        {
            if(success == SQLITE_ROW|| success ==SQLITE_DONE)
            {
                @try {
                    NSMutableDictionary * dics = [fEntity getPropTypes:[fEntity class]];
                    int colCount = sqlite3_column_count(statement);
                    id value = nil;
                    for(int colID = 0;colID <colCount;colID++)
                    {
                        const char * colName = sqlite3_column_name(statement,colID);
                        NSString * colName2 = [NSString stringWithCString:colName encoding:NSUTF8StringEncoding];
                        if(![dics objectForKey:colName2]) continue;
                        switch (sqlite3_column_type(statement,colID)) {
                            case SQLITE_INTEGER:
                                value = [NSNumber numberWithInt: sqlite3_column_int(statement, colID)];
                                //[entity setPropValue:colName value:value];
                                [fEntity setValue:value forKey:colName2];
                                break;
                            case SQLITE_FLOAT:
                                value = [NSNumber numberWithDouble:sqlite3_column_double(statement,colID)];
                                [fEntity setValue:value forKey:colName2];
                                break;
                            case SQLITE_TEXT:
                            {
                                const char * v1 = (const char *)sqlite3_column_text(statement, colID);
                                if(v1!=nil)
                                {
                                    value = [[NSString alloc]initWithCString:v1 encoding:NSUTF8StringEncoding];
                                    [fEntity setPropValue:colName2 value:value];
                                    PP_RELEASE(value);
                                }
                                break;
                            }
                            case SQLITE_NULL:
                                value = [NSNull null];
                                [fEntity setPropValue:colName2 value:value];
                                break;
                            default:
                                
                                break;
                        }
                        
                    }
                }
                @catch (NSException *exception) {
                    NSLog(@"db execentity error:%@",[exception description]);
                }
                @finally {
                    
                }
                
            }
        }
        //        PP_ENDPOOL(pool);
        return [self exit:YES statement:statement];
    }
    //    PP_ENDPOOL(pool);
    return [self exit:NO statement:statement];
    
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
    
    @autoreleasepool {
        //        pthread_mutex_lock(&dbMutex);
        if([self open])
        {
            //            if(![self dropTable:fEntity])
            //            {
            //                DLog(@"Cannot drop table %@;",fEntity.TableName);
            //                if(![self clearTable:fEntity])
            //                {
            //                    //                pthread_mutex_unlock(&dbMutex);
            //                    DLog(@"Cannot clear table %@;",fEntity.TableName);
            //                    [self close];
            //                    return NO;
            //                }
            //            }
            if(![self createTable:fEntity])
            {
                //            pthread_mutex_unlock(&dbMutex);
                [self close];
                return NO;
            }
            else
            {
                //            pthread_mutex_unlock(&dbMutex);
                [self close];
                return YES;
            }
        }
        return NO;
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
    
    pthread_mutex_lock(&dbMutex);
    int rc = 0;
    sqlite3_stmt *statement = nil;
    for (NSString * sql in deleteSqlArray) {
        const char * sqlchar = [sql cStringUsingEncoding:NSUTF8StringEncoding];
        rc =sqlite3_prepare_v2(database_, sqlchar, (int)strlen(sqlchar), &statement, 0) ;
        assert( rc==SQLITE_OK || (!statement));
        if( rc!=SQLITE_OK ){
#ifndef            __OPTIMIZE__
            NSString * error = [self getError];
            NSLog(@"Error: failed to prepare statement:%@",sql);
            NSLog(@"Error: %@",error);
#endif
            PP_RELEASE(deleteSqlArray);
            return [self exit:NO statement:statement];
            //            continue;
        }
        if( !statement ){
            // 前导语句错误 . 这是在语句前有注释或者空格的条件下会发生
            //sqlchar = zLeftover;
            
            PP_RELEASE(deleteSqlArray);
            return [self exit:NO statement:statement];
            //            continue;
        }
        
        
        rc = sqlite3_step(statement);
        if ( rc != SQLITE_DONE  && rc!=SQLITE_ROW) {
            NSLog(@"Error: %@",sql);
            NSLog(@"ERROR: %@",[self getError]);
            PP_RELEASE(deleteSqlArray);
            LastErrorCode_ = rc;
            return [self exit:NO statement:statement];
        }
    }
    PP_RELEASE(deleteSqlArray);
    return [self exit:YES statement:statement];
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

#if PP_ARC_ENABLED
#else
    PP_RETAIN(data);
#endif
    BOOL ret = TRUE;
    
    
    [self open];
    [self begin];
    
    NSDate * begin = [NSDate date];
    [self deleteExistsDataArray:data];
    [self commit];
    
    NSMutableDictionary * propDic = [[data objectAtIndex:0] getPropTypes:[[data objectAtIndex:0]  class]];
    
    NSString * sqlForPrepare = [HCSQLHelper getInsertSyntaxForPrepare:[data objectAtIndex:0] propDic:propDic];
    
    
    const char * sqlchar = [sqlForPrepare cStringUsingEncoding:NSUTF8StringEncoding];
    sqlite3_stmt *statement = nil;
    int rc = SQLITE_OK;
    int nRetry = 0;
    [self begin];
    pthread_mutex_lock(&dbMutex);
    while (rc == SQLITE_OK ||(rc==SQLITE_SCHEMA && (++nRetry)<2)) {
        rc =sqlite3_prepare_v2(database_, sqlchar, (int)strlen(sqlchar), &statement, 0) ;
        assert( rc==SQLITE_OK || (!statement));
        if( rc!=SQLITE_OK ){
            //#ifndef            __OPTIMIZE__
            NSString * error = [self getError];
            NSLog(@"Error: failed to prepare statement:%@",sqlForPrepare);
            NSLog(@"Error: %@",error);
            //#endif
            if(rc == SQLITE_SCHEMA || (rc==SQLITE_ERROR && ([error rangeOfString:@"no column"].length>0||[error rangeOfString:@"no such table"].length>0)))
            {
                pthread_mutex_unlock(&dbMutex);
                [self createTable:[data objectAtIndex:0]];
                rc = [self commit];
                pthread_mutex_lock(&dbMutex);
                [self begin];
                continue;
            }
            else
            {
                [self commit];
                PP_RELEASE(data);
                return [self exit:NO statement:statement autoClose:YES];
            }
            //            continue;
        }
        if( !statement ){
            // 前导语句错误 . 这是在语句前有注释或者空格的条件下会发生
            //sqlchar = zLeftover;
            continue;
        }
        
        for (HCEntity * entity in data) {
            sqlite3_reset(statement);
            [HCSQLHelper bindStatement:statement entity:entity propDic:propDic];
            
            int success = sqlite3_step(statement);
            if ( success != SQLITE_DONE  && success!=SQLITE_ROW) {
                NSLog(@"Error: %@",sqlForPrepare);
                NSLog(@"ERROR: %@",[self getError]);
                [self commit];
                PP_RELEASE(data);
                LastErrorCode_ = success;
                return [self exit:NO statement:statement autoClose:YES];
            }
        }
        int success = [self commit];
        
        
        if (success!=SQLITE_OK && success != SQLITE_DONE  && success!=SQLITE_ROW) {
            NSLog(@"Error: %@",sqlForPrepare);
            NSLog(@"ERROR: %@",[self getError]);
            PP_RELEASE(data);
            return [self exit:NO statement:statement autoClose:YES];
        }
        
        NSDate * end = [NSDate date];
        NSTimeInterval time = [end timeIntervalSinceReferenceDate] - [begin timeIntervalSinceReferenceDate];
        if(time>0)
        {
            NSLog(@"2 total:%ld for time:%f,every %f per second",(long)[data count],time,[data count]/time );
        }
        PP_RELEASE(data);
        return [self exit:YES statement:statement autoClose:YES];
    }
    //没有Commit，直接退出了
    if(nRetry >=2) {
        [self commit];
        PP_RELEASE(data);
        return [self exit:NO statement:statement autoClose:YES];
    }
    //    }
    PP_RELEASE(data);
    //    [data release];
    //    PP_ENDPOOL(pool);
    
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
    
    
    @try {
        if(needOpenDB)
            [self open];
        
        
        //        if(!forceUpdate)
        //        {
        NSString * sql = [HCSQLHelper getExistsSyntax:object];
        if(sql)
        {
            NSString * result = nil;
            if([self execScalar:sql result:&result])
            {
                if(result && [result intValue]>0 )
                {
                    isExists = YES;
                }
            }
            else
            {
                if(![self checkResultForRebuild:object needOpenDB:needOpenDB])
                {
                    return NO;
                }
            }
        }
        else
        {
            NSLog(@" exist sql error:%@",sql);
            ret = NO;
        }
        //        }
        if(ret==NO)
        {
            if(needOpenDB)
                [self close];
            //            PP_ENDPOOL(pool);
            return ret;
        }
        if(isExists && !forceUpdate)
        {
            ret = YES;
        }
        else
        {
            //delete old data
            if(isExists && forceUpdate)
            {
                
                NSString * deleteSql = [HCSQLHelper getDeleteSyntax:object];
                if(![self execNoQuery:deleteSql])
                {
                    //纠正数据库结构
                    //                NSString * error = [self getError];
                    //                DLog(@"database error code:%d",[self getErrorCode])
                    if(![self checkResultForRebuild:object needOpenDB:needOpenDB])
                    {
                        return NO;
                    }
                }
//                //图片需要多一重处理
//                if([object isKindOfClass:[HCImageItem class]])
//                {
//                    HCImageItem * item = (HCImageItem*)object;
//                    if(item.Src)
//                    {
//                        NSString * sql = [NSString stringWithFormat:@"delete from %@ where Src='%@' and ObjectID=%d and ObjectType=%d;",object.TableName,item.Src,item.ObjectID,item.ObjectType];
//                        [self execScalar:sql result:nil];
//                    }
//                }
            }
            
            // add new data
            NSString * sql = [HCSQLHelper getInsertSyntax:object];
            if(sql && [sql length]>5)
            {
                if(![self execNoQuery:sql])
                {
                    //                DLog(@"database error code:%d",[self getErrorCode])
                    //                NSString * error = [self getError];
                    int code = [self getErrorCode];
                    if(code ==SQLITE_ERROR || code==SQLITE_MISMATCH)
                        //if(code ==1 || [error rangeOfString:@"no such"].length>0||[error rangeOfString:@"no column"].length>0)
                    {
                        //                        [self dropTable:object];
                        [self createTable:object];
                    }
                    
                    ret = NO;
                }
            }
            else
                ret = NO;
        }
        if(needOpenDB)
            [self close];
    }
    @catch (NSException *exception) {
        NSLog(@"error:%@",exception);
        if(dbOpenCount_>0)
        {
            [self close];
        }
    }
    @finally {
        
    }
    //    PP_ENDPOOL(pool);
    return ret;
    
}
#endif

#pragma mark  - savedatatofile
- (void) SaveDataJsonToFile:(NSString*)filePath content:(NSString*)content ver:(NSString*)ver
{
    LastErrorCode_ = SQLITE_OK;
    @try {
        NSMutableDictionary * dic = [[NSMutableDictionary alloc]init];
        [dic setObject:ver forKey:@"version"];
        if(content==nil) content = @"";
        [dic setObject:content forKey:@"data"];
        
        NSString * result = [dic JSONRepresentationEx];
        NSData * data = [result dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError * error = nil;
        [data writeToFile:filePath options:NSDataWritingAtomic error:&error];
        if(error!=nil)
        {
            NSLog(@"read file:%@ error:%@",filePath,[error description]);
        }
        PP_RELEASE(dic);
        //        [dic release];
    }
    @catch (NSException *exception) {
        NSLog(@"create filecontent:%@ error:%@",filePath,[exception description]);
    }
    @finally {
    }
    
}
- (NSString *)ReadDataJsonFromFile:(NSString *)filePath ver:(NSString*)ver
{
    LastErrorCode_ = SQLITE_OK;
    NSError * error = nil;
    NSData * data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    if(error!=nil)
    {
        NSLog(@"read file:%@ error:%@",filePath,[error description]);
        return nil;
    }
    NSString * resultTemp = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSString * result = nil;
    @try {
        NSDictionary * dic = PP_RETAIN([resultTemp JSONValueEx]);
        NSString *version = [dic objectForKey:@"version"];
        if(version==nil || [version compare:ver options:NSCaseInsensitiveSearch]==NSOrderedSame)
        {
            result= [dic objectForKey:@"data"];
        }
        PP_RELEASE(dic);
    }
    @catch (NSException *exception) {
        NSLog(@"parse file:%@ error:%@",filePath,[exception description]);
    }
    @finally {
        PP_RELEASE(resultTemp);
        //        [resultTemp release];
    }
    return result;
}
+ (char *)getDBQueueLabel
{
    return "dbqueue";
}
+ (dispatch_queue_t)getDBQueue
{
    static dispatch_queue_t dbQueue;
    static dispatch_once_t t = 0;
    dispatch_once(&t, ^{
        dbQueue = dispatch_queue_create("dbqueue", DISPATCH_QUEUE_SERIAL);
    });
    return dbQueue;
}

@end
#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "NSEntity.h"

//#define USE_FMDATABASE 

#import "HCSQLHelper.h"

#ifdef USE_FMDATABASE
#import "FMDB.h"
#endif

#define DB_FILE          @"wutong.db"

//创建表的宏
#if PP_ARC_ENABLED
#define CREATETABLE(dbhelper,class) \
{\
    class * item = PP_AUTORELEASE([[class alloc]init]);\
\
    if(![dbhelper createTable:item])\
    {\
\
        NSLog(@"create table fail:%@",[dbhelper getError]);\
\
        return [dbhelper returnCreateResult:NO];\
\
    }\
\
}\

#else
#define CREATETABLE(dbhelper,class) \
{\
    class * item = PP_AUTORELEASE([[class alloc]init]);\
    \
    if(![dbhelper createTable:item])\
    {\
        \
        NSLog(@"create table fail:%@",[dbhelper getError]);\
        \
        return [dbhelper returnCreateResult:NO pool:pool]; \
        \
    }\
    \
}\

#endif

typedef enum _db_op_result{
    
    SUCCESSED    = 0,
    FAILED       = 1,
    CREATE_TABLE_FAILED = 5,
    TRANSACTION_EXE_FAILED = 7,
    UPDATE_FAILED = 9,
    DELETE_FAILED = 10,
    NOT_ALL_DONE = 20
} SMPDB_OPERATION_RESULT;

typedef enum _db_op_type{
    
    UPDATE = 1,
    DELETE = 2,
    INSERT = 3,
} SMPDB_OPERTION_TYPE;



@interface DBHelper : NSObject
{
    BOOL bFirstCreate_;
//    NSTimer *timer_;
    int  LastErrorCode_;
    int dbOpenCount_;
    
//    int dbOpenWrite_;
//    int dbOpenRead_;

//    dispatch_queue_t    writeQueue_;
//    dispatch_queue_t    readQueue_;
}
+ (DBHelper *) sharedDBHelper;
//+ (void)setInstance:(DBHelper *)instance;
- (BOOL)unzipDBFile;
- (NSString *)databaseFilePath;
#if USE_FMDATABASE
-(FMDatabase *)database;
#endif
- (BOOL) dbExists;
- (BOOL) open;
- (BOOL) close;
- (int) begin;
- (int) commit;

- (BOOL) execNoQuery:(NSString *)sql;
- (BOOL) execScalar:(NSString *)sql result:(NSString **)result;
//- (BOOL) execWithKey:(NSString*)sql;
- (BOOL) execWithArray:(NSMutableArray*)fEntities class:(NSString *)className sql:(NSString*)sql;
- (BOOL) execWithEntity:(HCEntity *)fEntity sql:(NSString *)sql;
- (BOOL) execWithDictionary:(NSMutableDictionary *)fEntity sql:(NSString *)sql;
- (NSString *)getError;
- (int)getErrorCode;
-(BOOL) exit:(BOOL)ret statement:(sqlite3_stmt*)statement;
- (BOOL) resetData:(HCEntity*)fEntity;
- (BOOL) insertDataArray:(NSArray *)data forceUpdate:(BOOL)forceUpdate;

- (BOOL)checkResultForRebuild:(HCEntity *)object needOpenDB:(BOOL)needOpenDB;
- (BOOL) deleteExistsDataArray:(NSArray *)data;
- (BOOL) insertDataArrayBatch:(NSArray *)data  forceUpdate:(BOOL)forceUpdate;
- (BOOL) insertDataArray:(NSArray *)data  forceUpdate:(BOOL)forceUpdate async:(BOOL)async;
- (BOOL) insertData:(HCEntity *)object needOpenDB:(BOOL)needOpenDB  forceUpdate:(BOOL)forceUpdate;

#pragma mark - file store
- (void) SaveDataJsonToFile:(NSString*)filePath content:(NSString*)content ver:(NSString*)ver;
///读数据
- (NSString *)ReadDataJsonFromFile:(NSString *)filePath ver:(NSString*)ver;

+ (char *)getDBQueueLabel;
+ (dispatch_queue_t)getDBQueue;

@end
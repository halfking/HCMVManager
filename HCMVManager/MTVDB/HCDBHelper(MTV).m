//
//  HCDBHelper(MTV).m
//  HCMVManager
//
//  Created by HUANGXUTAO on 16/4/21.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "HCDBHelper(MTV).h"

@implementation DBHelper_WT(MTV)
#pragma mark - mtv updates
+ (void)updateFilePath:(MTV*)item filePath:(NSString*)filePath
{
    [item setFilePathN:filePath];
    
    dispatch_async([DBHelper_WT getDBQueue], ^{
        if(item.MTVID>0)
        {
            [[DBHelper sharedDBHelper]insertData:item needOpenDB:YES forceUpdate:YES];
        }
        else
        {
            NSString * sql = [NSString stringWithFormat:@"update samples set FileName='%@' where sampleid=%ld",item.FileName,item.SampleID];
            if([[DBHelper sharedDBHelper]open])
            {
                [[DBHelper sharedDBHelper]execNoQuery:sql];
                [[DBHelper sharedDBHelper]close];
            }
        }
    });
}
+ (void)updateMtvFilePath:(long)mtvID filePath:(NSString *)filePath
{
    if(mtvID==0) return;
    NSString * sql = [NSString stringWithFormat:@"update mtvs set FileName='%@' where mtvid=%li;",filePath?filePath:@"",mtvID];
    DBHelper * db =[DBHelper sharedDBHelper];
    if([db open])
    {
        [db execNoQuery:sql];
        [db close];
    }
}

+ (void)updateMtvKey:(long)mtvID key:(NSString *)key
{
    if(mtvID==0) return;
    NSString * sql = [NSString stringWithFormat:@"update mtvs set key='%@' where mtvid=%li;",key?key:@"",mtvID];
    DBHelper * db =[DBHelper sharedDBHelper];
    if([db open])
    {
        [db execNoQuery:sql];
        [db close];
    }
    
}
+ (void)updateMtvRemoteUrl:(long)mtvID removeUrl:(NSString *)removeUrl
{
    if(mtvID==0) return;
    NSString * sql = [NSString stringWithFormat:@"update mtvs set DownloadUrl='%@' where mtvid=%li;",removeUrl?removeUrl:@"",mtvID];
    DBHelper * db =[DBHelper sharedDBHelper];
    if([db open])
    {
        [db execNoQuery:sql];
        [db close];
    }
}
+ (void)updateMtvAudioPath:(long)mtvID audioPath:(NSString*)audioPath
{
    if(mtvID==0) return;
    NSString * sql = [NSString stringWithFormat:@"update mtvs set AudioFileName='%@' where mtvid=%li;",audioPath?audioPath:@"",mtvID];
    DBHelper * db =[DBHelper sharedDBHelper];
    if([db open])
    {
        [db execNoQuery:sql];
        [db close];
    }
}
+ (void)updateMtvAudioKey:(long)mtvID key:(NSString *)key
{
    if(mtvID==0) return;
    NSString * sql = [NSString stringWithFormat:@"update mtvs set AudioKey='%@' where mtvid=%li;",key?key:@"",mtvID];
    DBHelper * db =[DBHelper sharedDBHelper];
    if([db open])
    {
        [db execNoQuery:sql];
        [db close];
    }
    
}
+ (void)updateMtvAudioRemoteUrl:(long)mtvID removeUrl:(NSString *)removeUrl
{
    if(mtvID==0) return;
    NSString * sql = [NSString stringWithFormat:@"update mtvs set AudioRemoteUrl='%@' where mtvid=%li;",removeUrl?removeUrl:@"",(long)mtvID];
    DBHelper * db =[DBHelper sharedDBHelper];
    if([db open])
    {
        [db execNoQuery:sql];
        [db close];
    }
}
+ (MTV*)getMTVUserSinged:(long)userID sample:(long)sampleID
{
    MTV * myItem = [MTV new];
    
    DBHelper * helper = [DBHelper sharedDBHelper];
    if([helper open])
    {
        NSString * sql = [NSString stringWithFormat:@"select * from mtvs where userid=%ld and sampleid= %ld;",userID,sampleID ];
        [helper execWithEntity:myItem sql:sql];
        [helper close];
    }
    return PP_AUTORELEASE(myItem);
}
+ (BOOL)removeMtvUserSinged:(long)userID sampleID:(long)sampleID
{
    DBHelper * helper = [DBHelper sharedDBHelper];
    if([helper open])
    {
        NSString * sql = [NSString stringWithFormat:@"delete  from mtvs where userid=%ld and sampleid= %ld;",userID,sampleID ];
        [helper execNoQuery:sql];
        [helper close];
    }
    return YES;
}
@end

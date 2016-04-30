//
//  FileDataCacheHelper.m
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-6.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "FileDataCacheHelper.h"
#import "HCBase.h"
#import "PublicMControls.h"
#import "CommonUtil.h"
#import "CommonUtil(Date).h"
#import "HCDbHelper.h"
#import "HCCacheItem.h"
#import "JSON.h"


@implementation FileDataCacheHelper
SYNTHESIZE_SINGLETON_FOR_CLASS_NEW(FileDataCacheHelper)
- (id)init
{
    if(self = [super init])
    {
        _cachePath = PP_RETAIN([[self getIFile]currentDirectoryPath]);
    }
    return self;
}
- (void)dealloc
{
    PP_RELEASE(_cachePath);
    
    PP_SUPERDEALLOC;
}
#pragma  mark - save get cache data
- (BOOL) saveDataToCacheFile:(NSString *)cmd andCacheKeyMD5:(NSString*)cacheKeyMD5 andContent:(NSString*)jsonData
{
    if(cacheKeyMD5==nil ||jsonData==nil) return FALSE;
    
//    NSString *cacheKeyMD5 = [CommonUtil md5Hash:cacheKey];
    //    HCCacheList * cacheList = [HCCacheList sharedHCCacheList];
    NSString * fileName = [self cacheFile:cacheKeyMD5];
    @try{
        NSFileManager* fileM = [self getIFile];
        NSError * error = nil;
        if([fileM fileExistsAtPath:fileName])
        {
            if(![fileM removeItemAtPath:fileName error:&error])
            {
                NSLog(@"delete file:%@,error:%@",fileName,[error description]);
                return FALSE;
            }
        }
        [self SaveDataJsonToFile:fileName content:jsonData];
        
        return TRUE;
    }
    @catch (NSException *exception) {
        NSLog(@"写入缓存文件出错%@",[exception description]);
        NSLog(@"FilePath:%@",fileName);
    }
    @finally {
        
    }
    return FALSE;
}
//获得缓存数据的MD5值（首先从缓存列表中获取，然后再从文件中获得)
- (NSString *) getDataMD5FromCacheFile:(NSString *)cmd andCacheKey:(NSString *)cacheKey dataString:(NSString **)dataString
{
    BOOL isCache = NO;
    NSString * dataMD5 = nil;
    if(cacheKey==nil) return nil;
    
    NSFileManager* fileM = [self getIFile];
    
    NSString *cacheKeyMD5 = [CommonUtil md5Hash:cacheKey];
    
    NSString * filePath = [self getCacheFileName:cacheKeyMD5 andTimeout:60*48 andHasNetwork: YES];//[cacheList cacheFile:cacheKeyMD5];
    if(filePath!=nil) isCache = YES;
    if(!isCache) return nil;
    
    
    
    if(isCache && filePath!=nil && [fileM fileExistsAtPath:filePath])
    {
//        NSAutoreleasePool * pool  = [NSAutoreleasePool new];
        @try {
            
            
            NSString * jsonTest = PP_RETAIN([self ReadDataJsonFromFile:filePath]);
            if(jsonTest != nil)
            {
                if(dataString)
                {
                    *dataString = jsonTest;
                }
//                request.CacheData = jsonTest;
                //NSLog(@"doLoad Cache length:%d",[buf length]);
#ifndef __OPTIMIZE__
                NSString * showResult = jsonTest;
                if([showResult length]>120)
                {
                    showResult = [NSString stringWithFormat:@"%@..(省略 %d)..%@",
                                  [jsonTest substringToIndex:80],
                                  (int)jsonTest.length - 120,
                                  [jsonTest substringFromIndex:jsonTest.length -40]];
                    
                }
                NSLog(@"Cache data:%@",showResult);
#endif
                dataMD5 = [[CommonUtil md5Hash:jsonTest] copy];
                
                PP_RELEASE(jsonTest);
            }
        }
        @catch (NSException *exception) {
            NSLog(@"读取缓存文件出错%@",[exception description]);
            NSLog(@"FilePath:%@",filePath);
        }
        @finally {
//            [pool drain];
        }
    }
    return  PP_AUTORELEASE(dataMD5);
}
//从缓存文件中去读内容
- (NSString *) getDataFromCacheFile:(NSString *)cacheKeyMD5
{
    BOOL isCache = NO;
    
    if(cacheKeyMD5==nil) return nil;
    
    NSFileManager* fileM = [self getIFile];
    
    //    HCCacheList * cacheList = [HCCacheList sharedHCCacheList];
    NSString * filePath = [self cacheFile:cacheKeyMD5];
    if(filePath!=nil) isCache = YES;
    
    if(!isCache) return nil;
    
    @try {
        if(isCache && filePath!=nil && [fileM fileExistsAtPath:filePath])
        {
            
            NSString * jsonTest = [self ReadDataJsonFromFile:filePath];
            
            if(jsonTest != nil)
            {
                NSLog(@"Cache data:%@",jsonTest);
                
                return jsonTest;
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"读取缓存文件出错%@",[exception description]);
        NSLog(@"FilePath:%@",filePath);
    }
    @finally {
        
    }
    return nil;
}

#pragma mark - cache do
-(void) removeCacheItem:(NSString *)scode
{
    if(scode)
    {
        
        NSString * sql =[NSString stringWithFormat:SQL_CACHE_DELETEBYCODE,scode];
        if([[DBHelper sharedDBHelper]open])
        {
            [[DBHelper sharedDBHelper] execNoQuery:sql];
            [[DBHelper sharedDBHelper]close];
        }
    }
    else
    {
        NSString * sql = @"delete from cacheitems;";
        if([[DBHelper sharedDBHelper]open])
        {
            [[DBHelper sharedDBHelper] execNoQuery:sql];
            [[DBHelper sharedDBHelper]close];
        }
    }
}
-(void) saveCacheItem:(int)CMDID cmdName:(NSString*)CMD
          cacheKeyMD5:(NSString *)cacheKeyMD5 args:(NSString *)args body:(NSString *)body
{
    //myData =  [[response.Body JSONValue] retain];
    //Cache files
    //只写入结果JSON部分，去除包头。
    //大多数数据直接存放在数据库中，不需要缓存
    if((CMDID!=106
        && CMDID!=105
        && CMDID!=122
        && CMDID!=121
        && CMDID!=120
        && CMDID!=132
        && CMDID!=133)
       || [self saveDataToCacheFile:CMD
                        andCacheKeyMD5:cacheKeyMD5
                         andContent:body])
    {
        HCCacheItem * item = [[HCCacheItem alloc]init];
        DBHelper *dbhelper = [DBHelper sharedDBHelper];
        if([dbhelper open])
        {
            [dbhelper execWithEntity:item
                                 sql:[NSString stringWithFormat:SQL_CACHE_GET,cacheKeyMD5]];

            if(item.CacheKey==nil||[item.CacheKey length]==0)
            {
                item.CacheKey = cacheKeyMD5;
                item.Args = args;
                item.SCode = CMD;
            }
            if(item.CacheKey && [item.CacheKey length]>0)
            {
                item.LastUpdateTime = [CommonUtil stringFromDate:[NSDate date]];
                item.DataMD5 = [CommonUtil md5Hash:body];
            }
            [dbhelper insertData:item needOpenDB:NO forceUpdate:YES];
            [dbhelper close];
        }
        PP_RELEASE(item);
    }
    //[myData release];
}
- (NSString *) getDataMD5FromCacheDB:(NSString *)cacheKeyMD5 andCMD:(NSString *)cmd
{
    
    if(!cacheKeyMD5) return nil;
    
    HCCacheItem * item = PP_AUTORELEASE([[HCCacheItem alloc]init]);
    if([[DBHelper sharedDBHelper]open])
    {
        [[DBHelper sharedDBHelper]execWithEntity:item
                                             sql:[NSString stringWithFormat:SQL_CACHE_GET,cacheKeyMD5]];
        [[DBHelper sharedDBHelper]close];
        if(item.CacheKey && [item.CacheKey length]>0)
        {
            
        }
    }
    //    [item release];
    return item.DataMD5;
}
-(BOOL)isNeedRemoteCall:(NSString *)CMD cacheKeyMD5:(NSString *)cacheKeyMD5
{
    if(!cacheKeyMD5) return YES;
    
    HCCacheItem * item = [[HCCacheItem alloc]init];
    if([[DBHelper sharedDBHelper]open])
    {
        [[DBHelper sharedDBHelper]execWithEntity:item
                                             sql:[NSString stringWithFormat:SQL_CACHE_GET,cacheKeyMD5]];
        [[DBHelper sharedDBHelper]close];
        if(item.CacheKey && [item.CacheKey length]>0)
        {
            NSDate * expireDate = [NSDate dateWithTimeIntervalSinceNow: CACHE_TIME];
            NSDate * lastDate = [CommonUtil dateFromString:item.LastUpdateTime];
            if([lastDate compare:expireDate]==NSOrderedDescending)  //
            {
                PP_RELEASE(item);
                return NO;
            }
        }
    }
    PP_RELEASE(item);
    return YES;
}

//如果缓存过期，则输出nil
- (NSString *)getCacheFileName:(NSString *)cacheKeyMD5 andTimeout:(int)minutes  andHasNetwork:(BOOL)hasNetwork
{
    NSDate * date = [[NSDate alloc] initWithTimeIntervalSinceNow:(0 - minutes *60)];
    NSString * file = [self getCacheFileNameWithDate:cacheKeyMD5 andExpireTime:date andHasNetwork:hasNetwork];
    PP_RELEASE(date);
    return file;
}

//根据MD5，或者键值来判断
//文件不存在，无缓存
//文件过期，无缓存
//MD5不对，无缓存
- (NSString *)getCacheFileNameWithDate:(NSString *)cacheKeyMD5 andExpireTime:(NSDate *)expireTime andHasNetwork:(BOOL)hasNetwork
{
    NSString * filePath  = [_cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json",cacheKeyMD5]];
    NSFileManager * fileM = [self getIFile];
    if( [fileM fileExistsAtPath:filePath])
    {
        if(!hasNetwork) return filePath;
        if(expireTime != nil)
        {
            //check date
            NSDictionary * dicAttr;
            dicAttr = [fileM attributesOfItemAtPath:filePath error:NULL];
            
            if(dicAttr!=nil)
            {
                NSDate *creatdate = [dicAttr objectForKey:NSFileCreationDate];
                NSDate *modifydate = [dicAttr objectForKey:NSFileModificationDate];
                
                if(modifydate!=nil)
                {
                    if([expireTime compare:modifydate]==NSOrderedAscending)
                        return nil;
                }
                else
                {
                    if([expireTime compare:creatdate]==NSOrderedAscending)
                        return filePath;
                    else
                        return nil;
                }
            }
            else
                return nil;
        }
        NSString * jsonTest = [self ReadDataJsonFromFile:filePath];
        if(jsonTest==nil) return nil;
        return filePath;
    }
    else
        return nil;
    
    return filePath;
}
-(NSString *)cacheFile:(NSString *)cacheKeyMD5
{
    NSString * filePath  = [_cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json",cacheKeyMD5]];
    return filePath;
}
-(NSFileManager*)getIFile
{
    //FILE_CACHELIST
    NSFileManager *fileM = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);//NSDocumentDirectory
	NSString *documentsDirectory = [paths objectAtIndex:0];
    [fileM changeCurrentDirectoryPath:[documentsDirectory stringByExpandingTildeInPath]];
    if(![fileM fileExistsAtPath:@"Cache"]) //缓存文件目录下文件可能很多，这里就放在配置文件目录下
		[fileM createDirectoryAtPath:@"Cache" withIntermediateDirectories:YES attributes:nil error:nil];
    //[fileM changeCurrentDirectoryPath: [[fileM currentDirectoryPath] stringByAppendingPathComponent:@"Config"]];
    return fileM;
}
#pragma mark  - savedatatofile
- (void) SaveDataJsonToFile:(NSString*)filePath content:(NSString*)content
{
    @try {
        NSMutableDictionary * dic = [[NSMutableDictionary alloc]init];
        [dic setObject:CT_VERSION forKey:@"version"];
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
    }
    @catch (NSException *exception) {
        NSLog(@"create filecontent:%@ error:%@",filePath,[exception description]);
    }
    @finally {
    }
    
}
- (NSString *)ReadDataJsonFromFile:(NSString *)filePath
{
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
        NSDictionary * dic = [resultTemp JSONValueEx];
        NSString *version = [dic objectForKey:@"version"];
        if(version==nil || [version compare:CT_VERSION options:NSCaseInsensitiveSearch]==NSOrderedSame)
        {
            result= [dic objectForKey:@"data"];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"parse file:%@ error:%@",filePath,[exception description]);
    }
    @finally {
        PP_RELEASE(resultTemp);
    }
    return result;
}
#pragma mark - clear
//清除缓存
-(void) clearCache
{
	NSFileManager *fileM = [self getIFile];
	if([fileM fileExistsAtPath:@"Cache"])
		[fileM removeItemAtPath:@"Cache" error:nil];
}
@end

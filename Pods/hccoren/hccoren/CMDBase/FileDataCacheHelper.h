//
//  FileDataCacheHelper.h
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-6.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import <Foundation/Foundation.h>
#define SQL_CACHE_GET   @"select * from cacheitems where CacheKey='%@'"
#define SQL_CACHE_DELETEBYCODE @"delete from cacheitems where SCode='%@'"
#define CACHE_TIME  (0- 30 *60)
#define CT_VERSION          @"2.0"

@interface FileDataCacheHelper : NSObject
{
    NSString * _cachePath; //缓存 文件地址
}
+ (FileDataCacheHelper *)sharedFileDataCacheHelper;

- (BOOL)        saveDataToCacheFile:(NSString *)cmd andCacheKeyMD5:(NSString*)cacheKeyMD5 andContent:(NSString*)jsonData;
- (NSString *)  getDataMD5FromCacheFile:(NSString *)cmd andCacheKey:(NSString *)cacheKey dataString:(NSString **)dataString;
- (NSString *)  getDataFromCacheFile:(NSString *)cacheKeyMD5;
- (NSString *)  cacheFile:(NSString *)cacheKeyMD5;
- (NSString *)  getDataMD5FromCacheDB:(NSString *)cacheKeyMD5 andCMD:(NSString *)cmd;

- (BOOL)        isNeedRemoteCall:(NSString *)CMD cacheKeyMD5:(NSString *)cacheKeyMD5;
//如果缓存过期，则输出nil
- (NSString *) getCacheFileName:(NSString *)cacheKeyMD5 andTimeout:(int)minutes  andHasNetwork:(BOOL)hasNetwork;
//根据MD5，或者键值来判断
//文件不存在，无缓存
//文件过期，无缓存
//MD5不对，无缓存
//如果没有网络，则读取缓存。
- (NSString *) getCacheFileNameWithDate:(NSString *)cacheKeyMD5 andExpireTime:(NSDate *)expireTime andHasNetwork:(BOOL) hasNetwork;

- (void)        SaveDataJsonToFile:(NSString*)filePath content:(NSString*)content;
- (NSString *)  ReadDataJsonFromFile:(NSString *)filePath;
- (NSFileManager*)getIFile;
- (void)        removeCacheItem:(NSString *)scode;
- (void)        clearCache;
@end

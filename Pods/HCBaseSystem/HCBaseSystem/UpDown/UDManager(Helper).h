//
//  UDManager(Helper).h
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/15.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UDManager.h"
#import "UDInfo.h"
#include <sys/param.h>
#include <sys/mount.h>

@interface UDManager(Helper)
//- (NSString *)remoteUrl:(NSString *)key;
- (NSString *) remoteUrl:(NSString *)key domainType:(int)domainType;
- (NSString *) getMimeType:(NSString *)path;
- (NSString *) localFileFullPath:(NSString *)fileUrl;
- (NSString *) tempFileFullPath:(NSString *)fileUrl;
- (NSString *) recordFileFullPath:(NSString *)fileUrl;

//创建所有的缓存目录
- (BOOL)checkAllDireictories;

- (NSString *) getRootPath;
- (NSString *) getApplicationPath;
- (NSString *) getLocalFilePathForUrl:(NSString *)webUrl extension:(NSString *)ext;
- (NSString *) removeApplicationPath:(NSString *)filePath;
//- (NSArray *) getLocalFilesForMusic:(int)pageSize;

- (NSString *) getOuputFilePathForUrl:(NSString *)webUrl extension:(NSString *)ext;
- (NSString *) outputFileFullPath:(NSString *)fileUrl;
- (NSString *) outputFileDir;

- (NSString *) localFileDir;
- (NSString *) tempFileDir;
- (NSString *) recordDir;
- (NSString *) webRootFileDir;
- (NSString *) coverStoryFileDir;
- (NSString *) mtvPlusFileDir;
- (NSString *) lyricFilrDir;
- (NSString *) convertFileDir;//变声用

- (BOOL) isKeyValid:(NSString *)key;
- (BOOL) insertItemToDB:(UDInfo *) item;
- (UDInfo *)queryItemFromDB:(NSString *)key;
- (BOOL) removeItemFromDB:(NSString *)key;

//获取设备可用空间
- (UInt64)      getSizeFreeForDevice;
- (CGFloat)     getCacheSize:(BOOL)includeMyVideo;
- (CGFloat)     getCacheSizeIncludeRecordDir:(BOOL)includeRecordDir includeLocalDir:(BOOL)includeLocalDir;

- (BOOL)        clearCachePath:(BOOL)includeMyVideo;
- (long long)   fileSizeAtPath:(NSString*) filePath;
- (CGFloat )    folderSizeAtPath:(NSString*) folderPath;
- (BOOL)        existFileAtPath:(NSString *)path;

//只记录相对位置。相对转绝对
- (BOOL) isFullFilePath:(NSString *)filePath;
- (NSString *) getFileName:(NSString*)filePath;
- (NSString *) getFilePath:(NSString *)fileName;

- (NSString *)getThumnatePath:(NSString *)filename minsecond:(int)minsecond size:(CGSize)size;
- (BOOL) removeThumnates:(NSString *)orgFileName size:(CGSize) size;
- (BOOL) removeTempVideos;
- (BOOL) removeFileAtPath:(NSString*) filePath;
- (BOOL) removeFilesAtPath:(NSString * )folderPath;
- (BOOL) removeFilesAtPath:(NSString * )folderPath matchRegex:(NSString *)regexString;
- (BOOL) removeFilesAtPath:(NSString * )folderPath withoutRegex:(NSString *)regexString;
- (BOOL) removeFilesAtPath:(NSString * )folderPath withoutPrefixList:(NSArray *)prefixList;
- (BOOL) removeFilesAtPath:(NSString * )folderPath matchRegex:(NSString *)regexString withoutPrefixList:(NSArray *)prefixList;


//filetype 0:MTV的路径(FilePath)   1:唱的声音的路径(AudioPath)
- (NSString *)checkPathForApplicationPathChanged:(NSString *)orgPath mtvID:(NSInteger)mtvID filetype:(short)fileType  isExists:(BOOL*)isExists;
- (NSString *)checkPathForApplicationPathChanged:(NSString *)orgPath isExists:(BOOL*)isExists;

- (BOOL)isFileExistAndNotEmpty:(NSString *)filePath size:(UInt64 *)size pathAlter:(NSString**)pathAlter;
- (BOOL)isFileExistAndNotEmpty:(NSString *)filePath size:(UInt64 *)size;
//获取需要自动缓存的文件的内容，如歌词信息等，自动加缓存
- (NSString *)  getContentCachedByUrl:(NSString *)urlString ext:(NSString *)ext;
- (NSString *)  getLyricCachedByUrl:(NSString *)urlString ext:(NSString *)ext;
- (BOOL)    getImageDataFromUrl:(NSString *)urlString size:(CGSize)size completed:(void(^)(UIImage * image,NSError * error))completed;
- (void)testProgress;

@end

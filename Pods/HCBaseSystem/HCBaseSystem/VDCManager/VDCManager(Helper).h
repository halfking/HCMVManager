//
//  VDCManager(Helper).h
//  maiba
//
//  Created by HUANGXUTAO on 15/9/14.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VDCManager.h"
@interface VDCManager(Helper)
- (unsigned long long)fileSizeForPath:(NSString *)path;

- (NSString *) getRemoteFileCacheKey:(NSString *)urlString;
- (NSString *) getLocalWebUrl:(NSString *)key;
- (NSString *) getFilePathForLocalUrl:(NSString *)localUrl;
- (NSString *) getTempFilePathForLocalUrl:(NSString *)localUrl;
- (NSString *)getLocalVideoPathForRemoveUrl:(NSString*)remoteUrlString;
- (NSString *)getLocalAudioPathForRemoveUrl:(NSString*)remoteUrlString;

-(NSString * )getKeyFromLocalUrl:(NSString *)localUrl;
-(NSString * )getKeyFromLocalPath:(NSString *)filePath;

- (NSInteger) getContentLengthByUrl:(NSString *)urlString;
- (UInt64) getContentLengthForlocalFilePath:(NSString *)filePath;
- (UInt64) getContentLengthForlocalUrl:(NSString *)localUrlString;

- (VDCItem *)getDownloadItemFromFile:(NSString *)filePath;
- (void)rememberDownloadUrl:(VDCItem *)item tempPath:(NSString *)tempPath;
- (void)rememberContentLength:(UInt64)length tempPath:(NSString *)tempPath;
- (UInt64)getContentLengthByFile:(NSString *)filePath;

- (void)removeDownloadUrlFromFile:(NSString *)filePath;
- (BOOL)removeDownloadItemFile:(VDCItem *)item tempPath:(NSString *)tempPath;

//获取当前下载完的量，值可能为-1，0，或大于0的值。-1表示完整
- (CGFloat)   getSecondsDownloaded:(VDCItem *)item totalSeconds:(CGFloat)totalSeconds;


- (BOOL) removeUrlCahche:(NSString *)urlString;
- (void)clear;


- (VDCTempFileInfo *)addNewTempFileAtLast:(VDCItem *)item;
- (VDCTempFileInfo *)createTempFileByOffset:(UInt64)offset item:(VDCItem *)item;
- (VDCTempFileInfo *)addTempFileIntoList:(VDCItem *)item file:(VDCTempFileInfo *)file;
@end

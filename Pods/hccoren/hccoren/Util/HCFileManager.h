//
//  HCFileManager.h
//  hccoren
//
//  Created by HUANGXUTAO on 16/4/30.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface HCFileManager : NSObject
{

}
+(id)defaultManager;
+(HCFileManager *)manager;

#pragma mark - dir
- (NSString *) localFileDir;
- (NSString *) tempFileDir;
- (NSString *) webRootFileDir;
- (NSString *) localFileFullPath:(NSString *)fileUrl;
- (NSString *) tempFileFullPath:(NSString *)fileUrl;

#pragma mark - files
+ (void)    createFileDirectory:(NSString *)dirFullPath;
+ (BOOL)    createFileDirectories:(NSString * )path;
+ (void)    movePath:(NSString *)sourcePath target:(NSString *)targetPath overwrite:(BOOL)overwriter;
+ (void)    copyPath:(NSString *)sourcePath target:(NSString *)targetPath overwrite:(BOOL)overwriter;
+ (void)    copyFile:(NSString *)sourceFile target:(NSString *)targetFile overwrite:(BOOL)overwriter;
+ (BOOL)    isExistsFile:(NSString *)filePath;
+ (BOOL)    isFileExistAndNotEmpty:(NSString *)filePath size:(UInt64 *)size;
#pragma mark - removeFiles
//获取设备可用空间
- (UInt64)      getSizeFreeForDevice;
- (long long)   fileSizeAtPath:(NSString*) filePath;
- (CGFloat )    folderSizeAtPath:(NSString*) folderPath;
- (BOOL)        existFileAtPath:(NSString *)path;
- (BOOL) removeFileAtPath:(NSString*) filePath;
- (BOOL) removeFilesAtPath:(NSString * )folderPath;
- (BOOL) removeFilesAtPath:(NSString * )folderPath matchRegex:(NSString *)regexString;
- (BOOL) removeFilesAtPath:(NSString * )folderPath withoutRegex:(NSString *)regexString;
- (BOOL) removeFilesAtPath:(NSString * )folderPath withoutPrefixList:(NSArray *)prefixList;
- (BOOL) removeFilesAtPath:(NSString * )folderPath matchRegex:(NSString *)regexString withoutPrefixList:(NSArray *)prefixList;


#pragma mark - fileName
- (NSString *)getRootPath;
//只记录相对位置。相对转绝对
- (BOOL) isFullFilePath:(NSString *)filePath;
- (NSString *) getFileName:(NSString*)filePath;
- (NSString *) getFilePath:(NSString *)fileName;
- (NSString *)checkPathForApplicationPathChanged:(NSString *)orgPath isExists:(BOOL*)isExists;

#pragma mark - helper
+ (BOOL)    isQiniuServer:(NSString *)urlString;
+ (NSString *)checkPath:(NSString *)path;
+ (BOOL)    isLocalFile:(NSString *)urlString;
+ (BOOL)    isImageFile:(NSString *)filePath;
+ (BOOL)    isVideoFile:(NSString *)filePath;
+ (BOOL)    isInAblum:(NSString *)path;
+ (NSString *)getFileExtensionName:(NSString *)orgPath  defaultExt:(NSString *)defaultExt;
+ (NSString *)getMD5FileNameKeepExt:(NSString *)orgPath defaultExt:(NSString *)defaultExt;
+ (BOOL)    checkUrlIsExists:(NSString *)urlString contengLength:(UInt64*)contentLength level:(int *)level;
+ (BOOL)    isUrlOK:(NSString *)urlString;

+ (void)    SaveImageFile:(NSString *)filePath image:(UIImage *)image;

#pragma mark - unzip
+ (BOOL)    unZipFileFrom:(NSString *)source to:(NSString *)destination;
@end

//
//  UDManager.h
//  Wutong
//  上传下载管理器，将来加入图片的缓存处理
//  上传用7牛的组件，核心仍是AFNetworking2.0.3
//  下载同样用AFNetworking 2.0.3
//  Created by HUANGXUTAO on 15/5/14.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <hccoren/base.h>
#import "UDDelegate.h"
#import "PublicEnum.h"
#import <UIKit/UIKit.h>

#define TOKEN_TIMESPAN 3600
//NSFileSize usigned long long

@class UDManager;
@class UDInfo;

typedef void (^UploadProgress)(NSString * filePath,CGFloat progress);
typedef void (^UploadCompleted)(NSString * filePath,NSString * remoteUrl);
typedef void (^UploadFailure)(NSString * filePath,int  code,NSString * message);
typedef BOOL (^NeedStop)(NSString * filePath,NSString * key);

//上传或下载管理，将来加入图片的缓存处理
@interface UDManager : NSObject
{
    NSString * tempFileRoot_;
    NSString * applicationRoot_;
    NSString * rootPath_;
    NSString * rootPathMatchString_;
    NSArray * reservedFileNames_; // 需要保留的文件
    HCFileManager * fileManager_;
    
}
@property(nonatomic,assign) long UserID;
+ (UDManager *) sharedUDManager;
- (NSString *)  getKey:(NSString *)pathOrUrl;   //获取上传或下载对像的Key
- (NSString *)  getKey:(NSString *)pathOrUrl andUserID:(long)userID;
- (NSString *)  getKeyFromQiniuUrl:(NSString *)url;  //从7牛的Url中获取Key值，如http://7xi4n3.com1.z0.glb.clouddn.com/zPv7enqD94uy9R4wxod6QXtT1MU=/lqeKS-rK0U1G5PSeDrcD3NiPBlR9
- (UDInfo*)     queryItem:(NSString *)key;  //查询对应对像的上传或下载状态
- (UDInfo *)    getItemByFileUrl:(NSString *)fileUrl;


//直接上传一个文件
- (NSString *)  uploadFile:(NSString *)filePath domainType:(DOMAIN_TYPE)domainType progress:(UploadProgress) progress completed:(UploadCompleted)completed failure:(UploadFailure)failure stop:(NeedStop)needstop;

- (NSString *)  addUploadProgress:(NSString *)filePath domainType:(int)domainType delegate:(id<UDDelegate>)delegate  autoStart:(BOOL)autoStart;
- (void)        cancelProgress:(NSString *)key delegate:(id<UDDelegate>)delegate;
- (void)        stopProgress:(NSString *)key delegate:(id<UDDelegate>)delegate;
//- (void)        resumeUploadProgress:(NSString *)key;//上传的位置由manager管理，外界不知


- (NSString *)  addDownloadProgress:(NSString *)fileUrl localFileExt:(NSString *)fileExt delegate:(id<UDDelegate>)delegate  autoStart:(BOOL)autoStart;
//- (NSInteger)   resumeDownloadProgress:(NSString *)key;//下载的位置由manager管理，外界不知

- (BOOL)        stopAllUDs:(BOOL) byUser delegate:(id<UDDelegate>)delegate;        //停止所有上传和下载操作
- (BOOL)        startAllUDs:(id<UDDelegate>)delegate;       //开始所有上传及下载操作

- (BOOL)        startAlludsWithoutStopByUser:(id<UDDelegate>)delegate;//开始所有上传与下载，非人为停止的。
- (BOOL)        stopAllUploads:(BOOL) byUser  delegate:(id<UDDelegate>)delegate;//停止所有上传进程

- (BOOL)        startUploadItem:(NSString *)key delegate:(id<UDDelegate>)delegate;
- (BOOL)        startDownloadByKey:(NSString *)key delegate:(id<UDDelegate>)delegate;
- (NSDictionary *)itemList;

#pragma mark - helper
- (BOOL)    downloadFile:(NSString *)urlString fileName:(NSString *)fileName
               completed:(void(^)(NSString * filePath))block
                  falure:(void(^)(NSError * error))failure;
@end

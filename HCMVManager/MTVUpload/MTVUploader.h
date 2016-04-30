//
//  MTVUploader.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/6/19.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <hccoren/Reachability.h>
#import <hcbasesystem/updown.h>
#import "CMD_CreateMTV.h"
#import "CMD_UploadMTV.h"

#import "MTV.h"
#import "MTVLocal.h"
#import <AssetsLibrary/AssetsLibrary.h>
//#import "WTPlayerResource.h"

typedef void (^SendCompleted)(BOOL finished);

@class MTVUploader;
@protocol MTVUploadderDelegate<NSObject>
@optional
- (void)MTVUploader:(MTVUploader *)uploader didMTVSaveLocalDB:(MTV*)item;
//返回是否需要立即启动上传操作
- (BOOL)MTVUploader:(MTVUploader *)uploader didMTVInfoCompleted:(MTV *)item;
- (void)MTVUploader:(MTVUploader *)uploader didMtvInfoFailuer:(MTV *)item error:(NSString *)error;
@end

//专用于MTV上传相关的处理
@interface MTVUploader : NSObject<UDDelegate>//,WTPlayerResourceDelegate>
{
    BOOL isCreating_;//正在上传MTV基础信息
    BOOL canAutoUpload_;//是否可以在网络切换到WIFI时，自动上传
    
    NSMutableArray * mtvList_;//刚刚处理过的MTV列表，尽量少从数据库中查询
}
//@property (nonatomic,PP_STRONG) Reachability * reachability;
@property (nonatomic,assign,readonly) NetworkStatus networkStatus;
@property (nonatomic,PP_WEAK) id<MTVUploadderDelegate> delegate;

+ (MTVUploader *) sharedMTVUploader;

- (BOOL)        canDownloadUpload;
- (UDInfo *)    getUploadInfo:(MTV*)mtv;
- (NSArray *)   getUploadList;
- (UDInfo *)    getUDInfoByKey:(NSString *)key;
- (NSArray *)   getMTVListForUpload;

//保存MTV相关的数据，完成后调用Block语句
- (BOOL) sendMtvInfoToServer:(MTV *)mtv materias:(NSArray *)materias
                   completed:(SendCompleted)completed;
//上传MTV的Info，当录制完成后上传失败，则转入此处，此时可能要生成MTV的ID，上传COver，然后再来上传MTV的视频
- (BOOL) uploadMTVInfo:(MTV *)mtv materias:(NSArray *)materias
           forceUpload:(BOOL)force
              delegate:(id<MTVUploadderDelegate>)delegate;
//上传MTV视频
- (BOOL) uploadMTV:(MTV * )mtv;// delegate:(id<UDDelegate>)delegate;
//上传MTV中的音频部分
- (BOOL) uploadMTVAudio:(MTV *)mtv;
- (BOOL) stopUploadMtv:(MTV *)mtv;// delegate:(id<UDDelegate>)delegate;
- (BOOL) resetUpload:(MTV *)mtv;// delegate:(id<UDDelegate>)delegate;
- (BOOL) deleteUpload:(MTV *)mtv;// delegate:(id<UDDelegate>)delegate;
- (BOOL) isUploading:(MTV*)mtv;
- (void) clearAllUploads;

//- (void) checkNetwork;
//- (void) networkTimeout:(NSNotification *)notification;

- (void) updateMTVKeyAndUserID:(MTV*)mtv;
- (long) insertIntoLocalDB:(MTV *)data;
- (void) removeMtvUpload:(NSString *)fileFullPath;
- (BOOL) isMtvUploaded:(MTV *)mtv;

- (void) setAutoupload:(BOOL)autoupload;
- (BOOL) hasAudioPathNeedUpload:(MTV *)mtv;

#pragma mark - file to uploaders
- (NSMutableArray *) getListFromLocalDir;
- (BOOL) removeMTVFileInLocalDir:(MTVLocal*)item;
- (void)removeMtvLocalInfo:(MTVLocal *)item;
- (void) saveMTVInfoToLocalDir:(MTVLocal *)item;
- (MTV*) getMTVByKey:(NSString *)key;
@end

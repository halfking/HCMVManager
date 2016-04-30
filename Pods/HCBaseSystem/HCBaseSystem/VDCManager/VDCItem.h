//
//  VDCItem.h
//  maiba
//  Video dwonload cache item
//  记录缓存的文件与本地Key对应关系
//  Created by HUANGXUTAO on 15/9/14.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//
#import <hccoren/base.h>
#import "VDCManager.h"

@interface VDCItem : HCEntity
{
    NSString * localFilePath_;
    NSString * localAudioPath_;
}
@property(nonatomic,PP_STRONG) NSString * key;
@property(nonatomic,PP_STRONG) NSString * remoteUrl;
@property(nonatomic,assign) UInt64 contentLength;
@property(nonatomic,assign) UInt64 downloadBytes;
@property(nonatomic,PP_STRONG) NSString * lastDownloadTime;
@property (nonatomic,assign) BOOL isCompleted;
//@property (nonatomic,PP_STRONG) NSString * tempFilePath;
//@property (nonatomic,PP_STRONG) NSString * localFilePath;
@property (nonatomic,PP_STRONG) NSString * tempFileName;
@property (nonatomic,PP_STRONG) NSString * localFileName;
@property (nonatomic,PP_STRONG) NSString * localWebUrl;
@property (nonatomic,PP_STRONG) NSString * title;

@property (nonatomic,PP_STRONG) NSString * FileHash;//合成文件的MD5

@property (nonatomic,PP_STRONG) NSString * AudioFileName;
//@property (nonatomic,PP_STRONG) NSString * AudioPath;
//@property (nonatomic,PP_STRONG) NSString * AudioTempPath;
@property (nonatomic,PP_STRONG) NSString * AudioUrl;
@property (nonatomic,assign) BOOL isAudioItem;

@property (nonatomic,PP_STRONG) NSMutableArray * tempFileList;
@property (nonatomic,assign) long ticks;

@property (nonatomic,assign) BOOL needStop; //当需要停止此对像的所有文件下载时，置为True；在刚开始此文件下载时，应置为False
@property (nonatomic,assign) BOOL isDownloading;

@property (nonatomic,copy) videoUrlReady readyCall;
@property (nonatomic,copy) downloadProgress progressCall;
@property (nonatomic,copy) downloadCompleted downloadedCall;
@property (nonatomic,assign) BOOL isCheckedFiles;


//为了能够记录用户的未唱完的信息，并能从上次的位置开始，设定如下属性
@property (nonatomic,assign) long SampleID;
@property (nonatomic,assign) long MTVID;
@property (nonatomic,assign) CGFloat lastSeconds;//上次唱到什么位置,-1为无效
@property (nonatomic,assign) int stepIndex;//   到哪一阶段，-1 为未唱完 0 编辑成功 1 合成成功 2数据保存成功 3上传完成(原则上在此处不会出)
@property (nonatomic,PP_STRONG) NSString * mediaJson;//数据为当前的相关录音文件及时间起止信息，并且可以包含编辑的图片及视频信息（恢复时，如果无法访问，则会被移除）
- (BOOL) hasDraft;//此对Sample有效，其它类型数据无效
- (NSString *)getPlayUrlOrPath;
- (NSString *)tempFilePath;
- (NSString *)localFilePath;
- (NSString *)AudioPath;
@end

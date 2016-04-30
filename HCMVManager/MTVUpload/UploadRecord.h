//
//  UploadRecord.h
//  Wutong
//  记录用户上传记录信息，用于分析网络带宽等
//  Created by HUANGXUTAO on 15/4/30.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <hccoren/NSEntity.h>
#import <hcbasesystem/PublicEnum.h>

@interface UploadRecord : HCEntity
@property(nonatomic,assign)long UploadID;
@property(nonatomic,PP_STRONG) NSString * FilePath;
@property(nonatomic,PP_STRONG) NSString * DownloadUrl;
@property(nonatomic,PP_STRONG) NSString * UploadBeginTime;
@property(nonatomic,PP_STRONG) NSString * UploadEndTime;
@property(nonatomic,assign) CGFloat UploadDurance;
@property(nonatomic,assign) long FileSize;//bytes
@property(nonatomic,assign) CGFloat BytesUploaded;
@property(nonatomic,assign) int IsUploaded; //0 未开始，1 执行中，2完成，-1失败
@property(nonatomic,assign) long UserID;
@property(nonatomic,assign) BOOL IsSynced; //此数据是否已经同步到服务器上
@end

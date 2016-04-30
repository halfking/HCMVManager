//
//  UDInfo.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/14.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <hccoren/NSEntity.h>

#import "UDDelegate.h"
#import <UIKit/UIKit.h>

@interface UDInfo : HCEntity
{
    NSString * localFilePath_;
}
@property(nonatomic,PP_STRONG) NSString * Key;
@property(nonatomic,PP_STRONG) NSString * OrgUrl;
@property(nonatomic,assign) BOOL IsUpload; //1 upload 0 download
@property(nonatomic,assign) CGFloat Progress;
@property(nonatomic,assign) unsigned long    TotalBytes;
@property(nonatomic,assign) unsigned long    RemainBytes;
@property(nonatomic,PP_STRONG) NSString * DateCreated;
@property (nonatomic,PP_STRONG) NSString * DateModified;

@property(nonatomic,PP_STRONG) NSString * ErrorInfo;
@property(nonatomic,PP_STRONG) NSString * LocalFileName;
@property(nonatomic,PP_STRONG) NSString * RemoteUrl;
@property(nonatomic,assign) short Status; //0 未开始或暂停 1处理中 2 失败 4完成 5 因为网络，系统自动暂停,6用户取消 9 本地文件不存在
@property(nonatomic,PP_WEAK) id<UDDelegate> delegate;
@property(nonatomic,assign) CGFloat Percent;
@property(nonatomic,assign) CGFloat WillStop;
@property(nonatomic,PP_STRONG) NSString * Ext;
@property(nonatomic,assign) int DomainType; //类似MTVS，MUSIC，Cover等

@property (nonatomic,PP_WEAK) NSOperation * operate;

//@property (nonatomic,PP_STRONG) NSDictionary * headers;
- (NSString *)LocalFilePath;
@end

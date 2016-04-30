//
//  HCUserSettings.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-9-27.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//  用户设置相关得信息：隐私、开关等

#import <hccoren/base.h>
//#import "NSEntity.h"
//#import "PublicValues.h"
#import "PublicEnum.h"
@interface HCUserSettings : HCEntity
{
    //    BOOL AddFriendConfirm;              //好友认证
    //    BOOL IsShareContact;                //公开名片
    //    BOOL CanSendNewMessage;             //接收新消息
    //    BOOL IsExchangeUserInformation;     //交换信息
    //    BOOL IsBeQuiet;                     //免打扰
    //    NSString * BeginTime;               //免打扰开始事件
    //    NSString * EndTime;                 //免打扰结束事件
    //    BOOL IsSilence;                     //新消息来时，是否静音
    //    BOOL IsRocking;                     //新消息来时，是否震动
    //    BOOL SyncToSinaWeibo;                    //是否同步到新浪微博
    //    NSString *SinaWeiboID;
    //    BOOL SyncToTencentWeibo;
    //    NSString *TencentWeiboID;
    //    BOOL SyncToNeteaseWeibo;
    //    NSString *NeteaseWeiboID;
    //
    //    HCShareRights ShareRights;          //分享是否公开
    //    HCUserState UserState;              //用户状态
    //    BOOL IsUserStateShare;              //是否显示用户状态
    //
    //    BOOL IsChanged;                     //设置是否已经更改,此处将触发后台的同步操作
    
}
@property(nonatomic,assign) long UserID;
@property (nonatomic,assign) BOOL NoticeFor3G;//3G使用流量时提醒
@property (nonatomic,assign) BOOL DownloadVia3G;//下载时使用3G
@property(nonatomic,assign) HCImgViewModel imgModel;            //显示模式/*************/
@property (nonatomic,assign) BOOL AutoUploadDataViaWIFI;        //是否自动上传文件
@property (nonatomic,assign) BOOL AutoSave2Album;               //自动将MV保存到相册
@property (nonatomic,assign) BOOL UploadWithMixe;               //直接上传文件时允许编辑
@property (nonatomic,assign) BOOL EnbaleCacheWhenPlaying;       //播放时使用缓存技术
@property(nonatomic,assign) BOOL AddFriendConfirm;              //好友认证
@property(nonatomic,assign) BOOL IsShareContact;                //公开名片
@property(nonatomic,assign) BOOL CanSendNewMessage;             //接收新消息
@property(nonatomic,assign) BOOL IsExchangeUserInformation;     //交换信息
@property(nonatomic,assign) BOOL IsBeQuiet;                     //免打扰
@property(nonatomic,PP_STRONG) NSString * BeginTime;               //免打扰开始事件
@property(nonatomic,PP_STRONG) NSString * EndTime;                 //免打扰结束事件
@property(nonatomic,assign) BOOL IsSilence;                     //新消息来时，是否静音
@property(nonatomic,assign) BOOL IsRocking;                     //新消息来时，是否震动
@property(nonatomic,assign) BOOL SyncToSinaWeibo;                    //是否同步到新浪微博
@property(nonatomic,PP_STRONG) NSString *SinaWeiboID;
@property(nonatomic,assign) BOOL SyncToTencentWeibo;
@property(nonatomic,PP_STRONG) NSString *TencentWeiboID;
@property(nonatomic,assign) BOOL SyncToNeteaseWeibo;
@property(nonatomic,PP_STRONG) NSString *NeteaseWeiboID;

@property(nonatomic,assign) HCBother botherSet;                 //是否开启免打扰
@property(nonatomic,assign) HCShareRights ShareRights;          //分享是否公开

@property(nonatomic,assign) HCUserState UserState;              //用户状态
@property(nonatomic,assign) BOOL IsUserStateShare;              //是否显示用户状态
@property(nonatomic,assign) BOOL SaveLoginPassword;             //保存密码，用于下次自动登陆
@property(nonatomic,assign) BOOL IsFirstUse;                    //是否第一次使用？如果是，可能需要显示向导信息
@property(nonatomic,PP_STRONG) NSString * LastSyncTime;            //上次与服务器同步时间
@property(nonatomic,assign) int RegionID;                       //地区ID
@property(nonatomic,PP_STRONG) NSString * ProvinceName;            //省
@property(nonatomic,PP_STRONG) NSString * CityName;
@property(nonatomic,PP_STRONG) NSString * CountyName;
@property(nonatomic,assign) double LAT;                         //纬度
@property(nonatomic,assign) double LNG;
//@property(nonatomic,assign) int HotelID;

@property(nonatomic,assign) short TrueNameVisible;
@property(nonatomic,assign) short BirthdayVisible;
@property(nonatomic,assign) short EmailVisible;
@property(nonatomic,assign) short QQVisible;
@property(nonatomic,assign) short MSNVisible;

//用户汇总信息
@property(assign) BOOL IsChanged;
-(void)setDefault;
@end

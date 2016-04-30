//
//  HCUserSettings.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-9-27.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//  用户设置相关得信息：隐私、开关等

#import "HCUserSettings.h"

@implementation HCUserSettings
@synthesize UserID;
@synthesize NoticeFor3G;
@synthesize DownloadVia3G;

@synthesize imgModel;   /*************图片显示模式****************/

@synthesize  AddFriendConfirm;           //好友认证
@synthesize IsShareContact;                //公开名片
@synthesize CanSendNewMessage;           //接收新消息
@synthesize IsExchangeUserInformation;     //交换信息
@synthesize IsBeQuiet;                     //免打扰
@synthesize BeginTime;                      //免打扰开始事件
@synthesize EndTime;                         //免打扰结束事件
@synthesize IsSilence;                     //新消息来时，是否静音
@synthesize IsRocking;                     //新消息来时，是否震动
@synthesize SyncToSinaWeibo;                    //是否同步到新浪微博
@synthesize SinaWeiboID;
@synthesize SyncToTencentWeibo;
@synthesize TencentWeiboID ;
@synthesize SyncToNeteaseWeibo;
@synthesize NeteaseWeiboID ;
@synthesize ShareRights ;                 //分享是否公开
@synthesize UploadWithMixe;

@synthesize UserState ;                     //用户状态
@synthesize IsUserStateShare ;              //是否显示用户状态
@synthesize SaveLoginPassword ;     //保存密码，用于下次自动登陆
@synthesize IsFirstUse ;
@synthesize LastSyncTime ;
@synthesize RegionID;                       //地区ID
@synthesize ProvinceName;
@synthesize CityName;
@synthesize CountyName;
@synthesize LAT;
@synthesize LNG;
//@synthesize HotelID;
@synthesize AutoUploadDataViaWIFI;

@synthesize TrueNameVisible;
@synthesize BirthdayVisible;
@synthesize EmailVisible;
@synthesize QQVisible;
@synthesize MSNVisible;
@synthesize EnbaleCacheWhenPlaying;
@synthesize botherSet;
@synthesize AutoSave2Album;

@synthesize IsChanged;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"usersettings";
        self.KeyName = @"UserID";
//        [self setDefault];
    }
    return self;
}
-(void)setDefault
{
    self.CanSendNewMessage = YES;
    self.IsBeQuiet = NO;
    self.IsSilence = NO;
    self.IsRocking = NO;
    self.AutoUploadDataViaWIFI = YES;
    self.NoticeFor3G = YES;
    self.imgModel = HCImgViewModelAgent;
    self.NoticeFor3G = YES;
    self.DownloadVia3G = NO;
//#warning need change default NO;
    self.AutoSave2Album = NO;
    self.EnbaleCacheWhenPlaying = NO;
    self.UploadWithMixe = NO;
}
- (void)dealloc
{
    self.BeginTime = nil;
    self.EndTime  = nil;
    self.SinaWeiboID  = nil;
    self.TencentWeiboID  = nil;
    self.NeteaseWeiboID  = nil;
    self.LastSyncTime = nil;
    
    
    self.ProvinceName = nil;
    self.CityName = nil;
    self.CountyName = nil;

    
    PP_SUPERDEALLOC;
}
@end

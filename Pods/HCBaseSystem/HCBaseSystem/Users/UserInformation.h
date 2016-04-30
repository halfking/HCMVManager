//
//  UserInformation.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-9-27.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import <hccoren/NSEntity.h>

#import "HCUserSettings.h"
//#import "UserCard.h"
#import "HCUserSummary.h"
#import "PublicEnum.h"
#import "Cover.h"
@class HCRegion;

@interface UserInformation : HCEntity
@property(nonatomic,assign) long UserID;
@property(nonatomic,assign) HCLoginType LoginType; //来源
@property(nonatomic,assign) int LikedCount;
@property(nonatomic,assign) int FansCount;
@property(nonatomic,assign) int FollowingCount;
@property(nonatomic,PP_STRONG) NSString * ThirdLoginID;
@property(nonatomic,PP_STRONG) NSString * AccessTocken;
@property(nonatomic,PP_STRONG) NSString * NickName;
@property(nonatomic,PP_STRONG) NSString * HeadPortrait;//头像
@property(nonatomic,assign) int RegionID;
@property(nonatomic,assign) int StarID;
@property(nonatomic,assign) HCSexy Sex;
@property(nonatomic,PP_STRONG) NSString * Introduction;//简介
@property(nonatomic,assign) int Source;//用户来源 1 maiba 11 maibah5 2seen 21 seenh5
@property(nonatomic,assign) BOOL IsMobileValid;
@property(nonatomic,PP_STRONG) NSString * Mobile;
@property(nonatomic,PP_STRONG) NSString * QQ;
@property(nonatomic,PP_STRONG) NSString * Weixin;
@property(nonatomic,PP_STRONG) NSString * Blog;

@property(nonatomic,PP_STRONG) NSString * Email;
@property(nonatomic,PP_STRONG) NSString * Signature;//个性签名


@property(nonatomic,assign) short IsFollowed; //0 未关注 1已关注

@property(nonatomic,PP_STRONG) NSString * UserName;


@property(nonatomic,PP_STRONG) NSString * Password;   //密码
@property(nonatomic,assign) BOOL IsPwdSetted;//是否设置过密码
@property(nonatomic,PP_STRONG) NSString * TrueName;
@property(nonatomic,PP_STRONG) NSString * Birthday;
@property(nonatomic,assign) int IDNumberType;
@property(nonatomic,PP_STRONG) NSString * IDNumber;

//服务端返回的此用户是否可以查看
@property(nonatomic,assign) int Rights;
@property(assign) BOOL IsChanged; //数据是否发生修改，此处将触发后台的同步操作
@property(nonatomic,PP_STRONG) HCUserSummary * Summary;
//用于缓存用户的选择
@property(nonatomic,PP_STRONG)HCRegion * CurrentCity;
@property (nonatomic, PP_STRONG) NSMutableArray *covers;
@end

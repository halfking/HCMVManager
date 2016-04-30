//
//  UserInfo-Extend.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-10-13.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//
#import <hccoren/NSEntity.h>

#import "UserInformation.h"
#import "HCUserSettings.h"
#import "HCUserSummary.h"
@interface HCUser_Extend:HCEntity
@property(nonatomic,assign) long UserID;
@property(nonatomic,PP_STRONG) UserInformation * User;
@property(nonatomic,PP_STRONG) HCUserSettings * Settings;
@property(nonatomic,PP_STRONG) HCUserSummary * Summary;
@end

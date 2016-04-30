//
//  CMD_SetUserInfo.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/12.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMDOP_WT.h"
#import "UserInformation.h"
#import "HCUserSettings.h"

@interface CMD_SetUserInfo : CMDOP_WT
@property(nonatomic,assign) long UserID;
@property(nonatomic,PP_STRONG) UserInformation * User;
@property(nonatomic,PP_STRONG) HCUserSettings * Settings;
@end

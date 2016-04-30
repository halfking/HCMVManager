//
//  CMD_UserLogout.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/19.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMDOP_WT.h"
#import "PublicEnum.h"
@interface CMD_UserLogout : CMDOP_WT
@property (nonatomic,assign) long UserID;
@property (nonatomic,PP_STRONG) NSString * LoginID;
@property (nonatomic,assign) HCLoginType  LoginType;
@end

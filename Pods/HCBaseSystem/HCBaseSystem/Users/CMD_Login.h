//
//  CMD_Login.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/19.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMDOP_WT.h"
#import "UserInformation.h"

@interface CMD_Login : CMDOP_WT
@property (nonatomic,PP_STRONG) NSString * LoginID;
@property (nonatomic,assign) HCLoginType LoginType;
@property (nonatomic,PP_STRONG) NSString * Password;
@property (nonatomic,PP_STRONG) NSString * Avatar;
@property (nonatomic,PP_STRONG) NSString * Nickname;
@property (nonatomic,assign) BOOL ReturnData;
@property (nonatomic,PP_STRONG) UserInformation * ThirdUser;
@end

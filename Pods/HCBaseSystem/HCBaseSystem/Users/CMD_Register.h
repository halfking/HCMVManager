//
//  CMD_Register.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/19.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMDOP_WT.h"
#import "UserInformation.h"
#import "PublicEnum.h"
@interface CMD_Register : CMDOP_WT
@property (nonatomic,PP_STRONG) NSString * LoginID;
@property (nonatomic,assign) HCLoginType LoginType;
@property (nonatomic,assign) NSString * Password;
@end

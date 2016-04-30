//
//  CMD_GetUserInfo.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/12.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMDOP_WT.h"
#import "PublicEnum.h"

@interface CMD_GetUserInfo : CMDOP_WT
@property (nonatomic,assign) long UserID;
@property (nonatomic,PP_STRONG) NSString * LoginID;
@property (nonatomic,assign) HCLoginType LoginType;
@property (nonatomic,assign) int InfoType; //1 userinfo 2 settings 4 summary ,三个数据可以与
@end

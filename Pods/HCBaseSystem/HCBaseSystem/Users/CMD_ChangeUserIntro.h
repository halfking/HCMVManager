//
//  CMD_ChangeUserIntro.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/12.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMDOP_WT.h"
#import "PublicEnum.h"

@interface CMD_ChangeUserIntro : CMDOP_WT
@property (nonatomic,assign) long UserID;
@property (nonatomic,assign) HCSexy Sex;
@property (nonatomic,PP_STRONG) NSString * Introduct;
@property (nonatomic,PP_STRONG) NSString * Nickname;
@end

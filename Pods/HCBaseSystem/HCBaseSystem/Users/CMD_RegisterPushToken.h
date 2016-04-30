//
//  CMD_RegisterPushToken.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/8/10.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMDOP_WT.h"
@interface CMD_RegisterPushToken : CMDOP_WT
@property (nonatomic,assign) int UserID;
@property (nonatomic,PP_STRONG) NSString * pushTocken;
@end

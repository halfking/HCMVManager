//
//  CMD_ChangeUserAvatar.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/12.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMDOP_WT.h"

@interface CMD_ChangeUserAvatar : CMDOP_WT
@property(nonatomic,assign) NSInteger UserID;
@property (nonatomic,PP_STRONG) NSString * Avatar;
@end

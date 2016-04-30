//
//  CMD_DeleteMyMTV.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/7/4.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <hcbasesystem/cmd_wt.h>
//#import "CMDOP_WT.h"

@interface CMD_DeleteMyMTV : CMDOP_WT
@property (nonatomic,assign) long mtvID; //返回的数据
- (BOOL) DeleteFromDB:(long)mtvID;
@end

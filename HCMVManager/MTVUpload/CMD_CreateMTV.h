//
//  CMD_CreateMTV.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/6/19.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <hcbasesystem/cmd_wt.h>
//#import "CMDOP_WT.h"
#import "MTV.h"
//用户在本地创建了一个MTV，将该MTV的信息写入到服务器，但MTV文件还没有上传
// MTV文件上传，请使用CMD_UploadMusic

@interface CMD_CreateMTV : CMDOP_WT
{
    long orgMtvID_;
}
@property (nonatomic,PP_STRONG) MTV * MtvData;
@property (nonatomic,assign,readonly) long mtvID; //返回的数据
@property (nonatomic,assign) int justUpdateKey; //0 create/update all 1 update key 2 update selected
- (long) insertIntoDB:(MTV *)data;

@end

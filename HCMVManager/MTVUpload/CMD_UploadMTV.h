//
//  CMD_UploadMTV.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/12.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <hcbasesystem/cmd_wt.h>
#import "MTV.h"
#import "UploadRecord.h"

//此命令用于上传MTV的媒体文件
//前题，此MTV的信息已经上传到服务器中
@interface CMD_UploadMTV : CMDOP_WT
@property (nonatomic,PP_STRONG) MTV * MtvData;
@property (nonatomic,assign) int uploadType;// 0 all 1:audio 2 mtv
//- (NSInteger) insertIntoDB:(MTV *)data;

//记录上传进度
//- (BOOL) setUploadProgress:(long)mtvID bytes:(NSInteger)bytes downloadUrl:(NSString *)downloadUrl;
//- (BOOL) setUploadProgressA:(NSString * )filePath bytes:(NSInteger)bytes downloadUrl:(NSString *)downloadUrl;


@end

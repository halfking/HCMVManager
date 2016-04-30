//
//  QCMDUpdateTime.h
//  SuixingSteward
//
//  Created by HUANGXUTAO on 14-7-13.
//  Copyright (c) 2014年 jokefaker. All rights reserved.
//

#import "NSEntity.h"
//记录命令的刷新时间
@interface QCMDUpdateTime : HCEntity
@property(nonatomic,assign) int CMDID;
@property(nonatomic,PP_STRONG) NSString * WindowID;
@property(nonatomic,PP_STRONG) NSString * Scode;
@property(nonatomic,PP_STRONG) NSString * ArgsHash;
@property(nonatomic,PP_STRONG) NSString * LastUpdateTime;
@property(nonatomic,PP_STRONG) NSString * ResultMD5;
@property(nonatomic,assign) int Status;//是否刷新成功 1 成功
@end

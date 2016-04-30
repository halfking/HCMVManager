//
//  TrackRecord.h
//  Wutong
//  用户界面跟踪数据
//  用户ID、进入时间、上一界面、当前界面、退出时间、可见时间、不可见时间
//  Created by HUANGXUTAO on 15/4/30.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "NSEntity.h"

@interface TrackRecord : HCEntity
@property(nonatomic,assign) int TrackRecordID;
@property(nonatomic,assign) int UserID;
@property(nonatomic,PP_STRONG) NSString * WinClassName;
@property(nonatomic,PP_STRONG) NSString * WinParameters;
@property(nonatomic,PP_STRONG) NSString * EnterTime;
@property(nonatomic,PP_STRONG) NSString * LeaveTime;
@property(nonatomic,PP_STRONG) NSString * LastWinClassName;
@property(nonatomic,assign) BOOL IsSynced;
@property(nonatomic,assign) float Durance;


@end

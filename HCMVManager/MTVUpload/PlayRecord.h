//
//  PlayRecord.h
//  Wutong
//  UserID,MusicID,播放时间、停止时间、播放时长、使用全屏否
//  Created by HUANGXUTAO on 15/4/30.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <hccoren/base.h>

@interface PlayRecord : HCEntity
@property(nonatomic,assign) long PlayID;
@property(nonatomic,assign) long UserID;
@property(nonatomic,assign) long MTVID;
@property(nonatomic,assign) long SampleID;
@property(nonatomic,assign) long TargetUserID;
@property(nonatomic,assign) short OPType; // 0. 1. 2. 3.
@property(nonatomic,PP_STRONG) NSString * PlayTime;//播放的日期
@property(nonatomic,assign) CGFloat BeginDurance;
@property(nonatomic,assign) CGFloat EndDurance;
@property(nonatomic,assign) CGFloat PlayDurance;
@property(nonatomic,assign) BOOL IsFullScreen;
@property(nonatomic,assign) BOOL IsSynced;//是否同步到服务器
@end

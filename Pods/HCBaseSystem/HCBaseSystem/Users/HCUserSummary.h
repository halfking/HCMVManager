//
//  HCUserSummary.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-10-15.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//
/// 用户相关的统计信息，用于一些需要提示数据的地方
//粉丝数、播放数、关注数、被喜欢数、音乐数
#import <hccoren/NSEntity.h>


@interface HCUserSummary : HCEntity
@property(nonatomic,assign) long UserID;
@property(nonatomic,assign) int FansCount;
@property(nonatomic,assign) int PlayCount;
@property(nonatomic,assign) int ConcernCount;
@property(nonatomic,assign) int BeFavCount;
@property(nonatomic,assign) int MTVCount;

///消息中心角标数目
@property(nonatomic,assign) int NewMessageCount;
@property(nonatomic,assign) int NewFriendCount;
@property(nonatomic,assign) int NewRequestCount;
@property(nonatomic,assign) int NewTranfersCount;
@property(nonatomic,assign) int NewCommentCount;
@property(nonatomic,PP_STRONG) NSString * LastSyncTime;
@property(nonatomic,assign) BOOL IsChanged;
- (int)countForNotify;
@end

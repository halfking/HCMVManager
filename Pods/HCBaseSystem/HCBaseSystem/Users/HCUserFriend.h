//
//  HCUserFriend.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-18.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import <hccoren/NSEntity.h>

@interface HCUserFriend : HCEntity
@property(nonatomic,assign) long FW_ID;
@property(nonatomic,assign) long FW_UserID;
@property(nonatomic,assign) long FW_FellowUserID;
@property(nonatomic,assign) short FW_FellowType;
@property(nonatomic,PP_STRONG) NSString * FW_FellowNickName;
@property(nonatomic,PP_STRONG) NSString * FW_FellowHeadportrait;
@property(nonatomic,PP_STRONG) NSString * FW_Time;
@end

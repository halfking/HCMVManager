//
//  CMDLog.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/7/28.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <hccoren/NSEntity.h>
//id,userid,datecreated,cmdname,cmdid,bytessend,bytesrecieved,readyticks,sendticks,parseticks
@interface CMDLog : HCEntity
@property (nonatomic,assign) long UserID;
@property (nonatomic,PP_STRONG) NSString * DateCreated;
@property (nonatomic,PP_STRONG) NSString * CMDName;
@property (nonatomic,assign) long ID;
@property (nonatomic,assign) int CMDID;
@property (nonatomic,assign) int BytesSend;
@property (nonatomic,assign) int BytesReceived;
@property (nonatomic,assign) int CreateTicks;
@property (nonatomic,assign) int ReadyTicks;
@property (nonatomic,assign) int SendTicks;
@property (nonatomic,assign) int ParseTicks;

@end

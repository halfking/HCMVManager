//
//  HCMessageItem.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-9-27.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//
#import <hccoren/NSEntity.h>
#import "publicenum.h"
//#import "NSEntity.h"
//#import "PublicValues.h"
@class HCGroupQueryItem;
@interface HCTransferItem : HCEntity
{
    NSString * groupString_;
//    long TransferID;
//    int UserID;
//    int TransferType;
//    int SourceUserID;
//    NSString * SourceUserName;
//    NSString * SourceHeadPortrait;
//    int TargetUserID;
//    NSString * TargetUserName;
//    NSString * TargetHeadPortrait;
//    int ObjectID;
//    int ObjectType;
//    NSString * ObjectName;
//    NSString * Title;
//    NSString * HTML;
//    NSString * CreateTime;
//    BOOL IsRead;
//    NSString * ReadTime;
//    HCMessageType MessageType;
//    int RelationObjectType;  //消息涉及得根对象类型
//    int RelationObjectID;   //消息涉及得根对象ID
//    NSString * Url;
}
@property(nonatomic,assign) long TransferID;
@property(nonatomic,assign) int UserID;
@property(nonatomic,assign) int TransferTypeID;
@property(nonatomic,assign) int SourceUserID;
@property(nonatomic,copy) NSString * SourceUserName;
@property(nonatomic,copy) NSString * SourceHeadPortrait;
@property(nonatomic,assign) int TargetUserID;
@property(nonatomic,copy) NSString * TargetUserName;
@property(nonatomic,copy) NSString * TargetHeadPortrait;
@property(nonatomic,assign) int ObjectID;
@property(nonatomic,assign) int ObjectType;
@property(nonatomic,copy) NSString * ObjectName;
@property(nonatomic,copy) NSString * Title;
@property(nonatomic,copy) NSString * HTML;
@property(nonatomic,copy) NSString * CreateTime;
@property(nonatomic,copy) NSString * ReadTime;
@property(nonatomic,assign) BOOL IsRead;
@property(nonatomic,assign) TS_New_DoneType Donetype;
@property(nonatomic,assign) HCUserMessageType MessageType;
@property(nonatomic,assign) HCMessageGroupType MessageGroupType;
//@property(nonatomic,assign) short MessageType;
//@property(nonatomic,assign) int MessageGroupType;
@property(nonatomic,assign) int RelationObjectID;
@property(nonatomic,assign) int RelationObjectType;
@property(nonatomic,copy) NSString * Url;
@property(nonatomic,assign) int GroupNoticeID;
@property(nonatomic,copy) NSString * Images;
@property(nonatomic,assign) int HotelID;
@property(nonatomic,copy) NSString * IP;

@property(nonatomic,copy) NSString *SerialNO; //用于记录唯一的ＩＤ，刷新本地页面有用
@property(nonatomic,assign) BOOL IsSend;
//显示使用
@property(nonatomic,assign) int RowHeight;
@property(nonatomic,retain,getter = get_GroupString,setter = set_GroupString:) NSString * GroupString;
//根据本地缓存的信息，处理相关的用户信息结构
- (id) initWithLocalInformation;
@end

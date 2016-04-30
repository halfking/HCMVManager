//
//  HCMessageItem.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-8.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

//#import "NSEntity.h"
#import <hccoren/NSEntity.h>
#import <hccoren/JSON.h>
//#import "publicvalues.h"
#import "PublicEnum.h"
//#import "NSString+SBJSON.h"

@interface HCMessageItem : HCEntity
{
//    NSString * groupString_;
}
@property (nonatomic,assign) int MessageID;
@property (nonatomic,assign) int SenderID;
@property (nonatomic,copy) NSString * SenderName;
@property (nonatomic,copy) NSString * SenderHeadPortrait;
@property (nonatomic,copy) NSString * SenderIP;
@property (nonatomic,assign) HCUserMessageType MsgType;
@property (nonatomic,assign) int ReceiverType;
@property (nonatomic,assign) int ReceiverID;
@property (nonatomic,copy) NSString * ReceiverName;
@property (nonatomic,copy) NSString * ReceiverHeadPortrait;
@property (nonatomic,copy) NSString * Title;
@property (nonatomic,copy) NSString * Content;
@property (nonatomic,copy) NSString * CreateTime;
@property (nonatomic,assign) BOOL IsSendDelete;
@property (nonatomic,assign) BOOL IsReceiverDelete;
@property (nonatomic,assign) BOOL IsRead;
@property (nonatomic,copy) NSString *  ReadTime;
@property (nonatomic,assign) BOOL IsShareDialog;
@property (nonatomic,assign) int DialogID;
@property (nonatomic,copy) NSString *  DialogUpdateTime;
@property (nonatomic,assign) int DialogCount;
@property (nonatomic,copy) NSString *  DialogLastContent;
@property (nonatomic,assign) int DialogLastContentID;
@property (nonatomic,copy) NSString *  Images;
@property (nonatomic,assign) HCContentType ContentType;
@property (nonatomic,copy) NSString * ContentJson;

@property (nonatomic,assign) CGFloat RowHeight;
@property (nonatomic,assign) BOOL IsSend;
@property (nonatomic,assign) BOOL IsSendError;
@property (nonatomic,copy) NSString * SerialNO;
@property (nonatomic,assign) int GroupNoticeID;
//@property (nonatomic,assign,getter = get_gnid,setter = set_gnid:) long GroupNoticID;
@property (nonatomic,assign) int ReceiverBelongID;
//@property(nonatomic,retain,getter = get_GroupString,setter = set_GroupString:) NSString * GroupString;
@property(nonatomic,retain) NSString * GroupString;
@end

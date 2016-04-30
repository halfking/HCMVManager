//
//  HCMessageItem.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-8.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "HCMessageItem.h"

@implementation HCMessageItem
@synthesize MessageID;
@synthesize SenderID;
@synthesize SenderName;
@synthesize SenderHeadPortrait;
@synthesize SenderIP;
@synthesize MsgType;
@synthesize ReceiverType;
@synthesize ReceiverID;
@synthesize ReceiverName;
@synthesize ReceiverHeadPortrait;
@synthesize Title;
@synthesize Content;
@synthesize CreateTime;
@synthesize IsSendDelete;
@synthesize IsReceiverDelete;
@synthesize IsRead;
@synthesize ReadTime;
@synthesize IsShareDialog;
@synthesize DialogID;
@synthesize DialogUpdateTime;
@synthesize DialogCount;
@synthesize DialogLastContent;
@synthesize DialogLastContentID;
@synthesize Images;
@synthesize ContentType;
@synthesize ContentJson;

@synthesize RowHeight;
@synthesize IsSend;
@synthesize SerialNO;
@synthesize GroupNoticeID;
@synthesize ReceiverBelongID;
@synthesize IsSendError;

@synthesize GroupString;

//@synthesize GroupString;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"messages";
        self.KeyName = @"MessageID";
    }
    return self;
}
//- (NSString *)get_GroupString
//{
//    return groupString_;
//}
//- (void)set_GroupString:(NSString *)temp
//{
//    if(groupString_)
//    {
//        PP_RELEASE(groupString_);
//    }
//    groupString_ = [temp retain];
//}
//- (long)get_gnid
//{
//    return GroupNoticeID;
//}
//- (void)set_gnid:(long)gnid
//{
//    GroupNoticeID = gnid;
//}
-(void)dealloc
{
    self.SenderName = nil;
    self.SenderHeadPortrait = nil;
    self.SenderIP = nil;
    self.ReceiverName = nil;
    self.ReceiverHeadPortrait = nil;
    self.Title = nil;
    self.Content = nil;
    self.CreateTime = nil;
    self.ReadTime = nil;
    self.DialogUpdateTime = nil;
    self.DialogLastContent = nil;
    self.Images = nil;
    self.ContentJson = nil;
    self.SerialNO  = nil;
    self.GroupString = nil;
//    if(groupString_)
//    {
//        PP_RELEASE(groupString_);
////        [groupString_ release];
//    }
    PP_SUPERDEALLOC;
}
@end

//
//  HCMessageItem.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-9-27.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "HCTransferItem.h"
//#import "DeviceConfig.h"

@implementation HCTransferItem
@synthesize TransferID;
@synthesize UserID;
@synthesize TransferTypeID;
@synthesize SourceUserID;
@synthesize SourceUserName;
@synthesize SourceHeadPortrait;
@synthesize TargetUserID;
@synthesize TargetUserName;
@synthesize TargetHeadPortrait;
@synthesize ObjectID;
@synthesize ObjectType;
@synthesize ObjectName;
@synthesize Title;
@synthesize HTML;
@synthesize CreateTime;
@synthesize ReadTime;
@synthesize IsRead;
@synthesize Donetype;
@synthesize MessageType;
@synthesize MessageGroupType;
@synthesize RelationObjectID;
@synthesize RelationObjectType;
@synthesize Url;
@synthesize GroupNoticeID;
@synthesize Images;
@synthesize HotelID;
@synthesize IP;
@synthesize SerialNO;
@synthesize IsSend;
@synthesize RowHeight;
//@synthesize GroupString;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"transfers";
        self.KeyName = @"TransferID";
    }
    return self;
}

//根据本地的信息，填充消息中不完整的部分
- (id) initWithLocalInformation
{
//    DeviceConfig * info = [DeviceConfig Instance];
    return [self init];
}
- (NSString *)get_GroupString
{
    return groupString_;
}
- (void)set_GroupString:(NSString *)temp
{
    if(groupString_)
    {
        PP_RELEASE(groupString_);
    }
    groupString_ = PP_RETAIN(temp);
}
- (void)dealloc
{
    self.SourceUserName  = nil;
    self.SourceHeadPortrait = nil;
    self.TargetHeadPortrait = nil;
    self.TargetUserName = nil;
    self.ObjectName = nil;
    self.Title = nil;
    self.HTML = nil;
    self.CreateTime = nil;
    self.ReadTime = nil;
    self.Url = nil;
    self.Images = nil;
    self.IP = nil;
    self.SerialNO = nil;
//    self.GroupString  = nil;
    if(groupString_)
    {
         PP_RELEASE(groupString_);
    }
    PP_SUPERDEALLOC;
}
@end

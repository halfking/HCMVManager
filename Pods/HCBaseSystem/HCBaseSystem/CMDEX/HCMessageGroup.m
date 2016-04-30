//
//  HCMessageGroup.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-9-27.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "HCMessageGroup.h"
#import "textresource.h"
//#import "PublicValues.h"
@implementation HCMessageGroup
@synthesize GroupNoticeID;
@synthesize UserID;
@synthesize GroupNTitle;
@synthesize GroupNType;
@synthesize GroupNIcon;
@synthesize GroupNID;
@synthesize NewCount;
@synthesize TotalCount;
@synthesize OrderIndex;
@synthesize DateLastModified;
@synthesize LastMessageSyntax;
@synthesize LastMessage;
@synthesize SourceUserID;
@synthesize HotelID;
@synthesize ReceiverType;
@synthesize SenderType;
@synthesize isTransferFromOther;
@synthesize OppositeNoticeID;

-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"messagegroup";
        self.KeyName = @"GroupNoticeID";
    }
    return self;
}

- (id) initWithDictionaryNew:(NSDictionary *)dic
{
    self = [super initWithDictionary:dic];

    if(LastMessageSyntax!=nil && LastMessageSyntax.length>2)
    {
        self.LastMessage = nil;
//        if(LastMessage!=nil) [LastMessage release];
//        LastMessage = nil;
        //NSLog(@"lastmessage:%@",LastMessageSyntax);
        if(self.GroupNType == HCMessageGroupNews||self.GroupNType == HCMessageGroupSystem)
            self.LastMessage = PP_AUTORELEASE([[HCTransferItem alloc] initWithJSON:LastMessageSyntax]);
        else
            self.LastMessage = PP_AUTORELEASE([[HCMessageItem alloc] initWithJSON:LastMessageSyntax]);
    }
    if(self.GroupNIcon == nil||[self.GroupNIcon length]==0)
    {
        switch (self.GroupNType) {
            case HCMessageGroupOrg:
                self.GroupNIcon = NAV_MSGICON_ORG;
                break;
            case HCMessageGroupFriend:
                self.GroupNIcon = NAV_MSGICON_FRIEND;
                break;
            case HCMessageGroupNews:
                self.GroupNIcon = NAV_MSGICON_NEWS;
                break;
                
            default:
                self.GroupNIcon = NAV_MSGICON_SYSTEM;
                break;
        }
    }
    return self;
}
-(void) dealloc
{
    self.GroupNTitle = nil;
    //self.GroupNType = nil;
    self.DateLastModified = nil;
    self.LastMessageSyntax = nil;
    self.LastMessage = nil;
    self.GroupNIcon  = nil;
    
    PP_SUPERDEALLOC;
}
@end

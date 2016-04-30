//
//  HCMessageGroup.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-9-27.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import <hccoren/NSEntity.h>
#import "HCTransferItem.h"
#import "HCMessageItem.h"
@interface HCMessageGroup : HCEntity
{
//    int GroupNoticeID;
//    int UserID;
//    NSString * GroupNTitle;
//    NSString * GroupNType;
//    NSString * GroupNIcon;
//    int GroupNID;
//    int NewCount;
//    int TotalCount;
//    int OrderIndex;
//    NSString * DateLastModified;
//    NSString * LastMessageSyntax;
//    HCMessageItem * LastMessage;
}
@property (nonatomic,assign) int GroupNoticeID;
@property (nonatomic,assign) int UserID;
@property (nonatomic,copy) NSString * GroupNTitle;
@property (nonatomic,assign) int GroupNType;
@property (nonatomic,copy) NSString * GroupNIcon;
@property (nonatomic,assign) int GroupNID;
@property (nonatomic,assign) int NewCount;
@property (nonatomic,assign) int TotalCount;
@property (nonatomic,assign) int OrderIndex;
@property (nonatomic,copy) NSString * DateLastModified;
@property (nonatomic,copy) NSString * LastMessageSyntax;
/// 如果LastMessageSyntax有的话变成hcMessageItem
@property (nonatomic,retain) id  LastMessage;

@property (nonatomic,assign) int HotelID;
@property (nonatomic,assign) int SourceUserID;
@property (nonatomic,assign) int ReceiverType;
@property (nonatomic,assign) int SenderType;
@property (nonatomic,assign) BOOL isTransferFromOther;
@property (nonatomic,assign) int OppositeNoticeID;

- (id) initWithDictionaryNew:(NSDictionary *)dic;
@end

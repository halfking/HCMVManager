//
//  ReportInfo.h
//  maiba
//
//  Created by HUANGXUTAO on 16/2/26.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <hccoren/base.h>

@interface ReportInfo : HCEntity
@property (nonatomic,assign) NSInteger ReportID;
@property (nonatomic,assign) int ObjectType;
@property (nonatomic,assign) NSInteger ObjectID;
@property (nonatomic,PP_STRONG) NSString * UrlString;
@property (nonatomic,PP_STRONG) NSString * NickName;
@property (nonatomic,assign) NSInteger UserID;
@property (nonatomic,PP_STRONG) NSString * TargetNickName;
@property (nonatomic,assign) NSInteger TargetUserID;
@property (nonatomic,PP_STRONG) NSString * ReportReason;
@property (nonatomic,PP_STRONG) NSString * Message;
@property (nonatomic,PP_STRONG) NSString * DateCreated;

@end

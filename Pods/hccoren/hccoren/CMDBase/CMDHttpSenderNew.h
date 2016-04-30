//
//  CMDHttpSenderNew.h
//  Wutong
//
//  Created by 潘婷婷 on 15-8-5.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "CMDSender.h"
//#import "AFNetworking.h"

#define HTTP_TIMEOUT 10
@interface CMDHttpSenderNew : CMDSender
+ (CMDHttpSenderNew *)sharedCMDHttpSenderNew;
@end


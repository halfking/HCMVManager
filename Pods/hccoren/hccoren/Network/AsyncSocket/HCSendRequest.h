//
//  HCSendReqeust.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-29.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCBase.h"
@interface HCSendRequest : NSObject
@property(nonatomic,assign) double timeout;
@property(nonatomic,assign) int tagid;
@property(nonatomic,PP_STRONG) NSData * data;
@property(nonatomic,assign) int retrycount;
@end

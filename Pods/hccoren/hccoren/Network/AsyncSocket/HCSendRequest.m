//
//  HCSendReqeust.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-29.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "HCSendRequest.h"

@implementation HCSendRequest
@synthesize timeout,tagid,data,retrycount;
-(void)dealloc
{
    PP_RELEASE(data);
//    self.data = nil;
    PP_SUPERDEALLOC;
}
@end

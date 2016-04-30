//
//  ResponseEntity.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-9-24.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "ResponseEntity.h"

@implementation ResponseEntity
@synthesize Code;
@synthesize MessageType;
//@synthesize MessageType2;
@synthesize MSG;
@synthesize TotalCount;
@synthesize Data;
@synthesize Entity;
@synthesize Array;
- (void)test:(char *)MessageType
{
    
}
- (void)dealloc
{
    self.MSG  = nil;
    self.Data = nil;
    self.Entity = nil;
    self.Array = nil;
    PP_SUPERDEALLOC;
}
@end

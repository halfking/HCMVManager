//
//  ResponseEntity.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-9-24.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <hccoren/NSEntity.h>

@interface ResponseEntity : HCEntity
@property(nonatomic,assign) int Code;
@property(nonatomic,setter = test:) char * MessageType;
//@property(nonatomic,assign) char MessageType2;
//@property(nonatomic,assign) HCUserMessageType MessageType;
@property(nonatomic,PP_STRONG) NSString * MSG;
@property(nonatomic,assign) int TotalCount;
@property(nonatomic,PP_STRONG) id Data;
@property(nonatomic,PP_STRONG) HCEntity * Entity;
@property(nonatomic,PP_STRONG) NSArray * Array;
@end

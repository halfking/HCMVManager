//
//  QTimespan.h
//  Hotel
//
//  Created by HUANGXUTAO on 14-6-5.
//  Copyright (c) 2014年 jokefaker. All rights reserved.
//
#import <hccoren/base.h>


@interface QTimespan : HCEntity
@property(PP_STRONG,nonatomic)NSString * Code;
@property(assign,nonatomic)int Value;
@property(PP_STRONG,nonatomic)NSString * LastUpdateTime;
@property(assign,nonatomic)int IsDone;
@end

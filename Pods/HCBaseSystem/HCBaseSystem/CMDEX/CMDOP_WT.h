//
//  CMDOP_SX.h
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-11-27.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

//#import "CMDOP.h"
//#import <hccoren/CMDOP.h>
#import <hccoren/CMDOP.h>
#import <hccoren/base.h>
//#import <sncore/CMDOP.h>
@interface CMDOP_WT : CMDOP

#pragma mark - public events
- (long) userID;
- (NSString *)mobile;
- (NSString *)userName;
//- (int) hotelID;
- (void)setPageSize:(int)ps pageIndex:(int)pi;
- (void)CheckDBIsNeedClear:(NSString *)keyName data:(NSDictionary *)data entity:(HCEntity*)entity;

@end

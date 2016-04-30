//
//  HCDBHelper-init.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-17.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCDbHelper.h"

@interface DBHelper(init)
-(BOOL)createDatabase;
-(BOOL)removeDatabase;
- (BOOL)createTable:(HCEntity *)entity;
- (BOOL)dropTable:(HCEntity *)entity;
- (BOOL)clearTable:(HCEntity *)entity;
#if PP_ARC_ENABLED
- (BOOL)returnCreateResult:(BOOL)ret;
#else
- (BOOL)returnCreateResult:(BOOL)ret pool:(NSAutoreleasePool *)pool;
#endif
@end

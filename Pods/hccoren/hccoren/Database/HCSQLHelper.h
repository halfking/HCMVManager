//
//  HCSQLHelper.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-16.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCEPropetyType.h"
#import "NSEntity.h"
#import <sqlite3.h>
@interface HCSQLHelper : NSObject
+ (NSString *) columNameCheck:(NSString*)name;
+ (NSString *) fieldTypeName:(HCEPropertyType *)pt;
+ (NSString *) getFieldSyntax:(HCEPropertyType *)pt isprimarykey:(BOOL)isPrimaryKey;
+ (NSString *) fieldCompareSyntax:(HCEPropertyType *)pt value:(id)value;
+ (NSString *) fieldValueString:(HCEPropertyType *)pt value:(id)value;
+ (NSString *) fieldSetSyntax:(HCEPropertyType *)pt value:(id)value;
+ (NSString *)getKeyCompareSyntax:(HCEntity *)entity;
+ (NSString *) getTableSyntax:(HCEntity *)entity;
+ (NSString *) getSelectSyntax:(HCEntity *)entity where:(NSString*)where orderBy:(NSString*)orderBy;
+ (NSString *) getSelectSyntax:(HCEntity *)entity where:(NSString*)where orderBy:(NSString*)orderBy
                      pageSize:(int)pageSize pageIndex:(int)pageIndex;
+ (NSString *) getDeleteSyntax:(HCEntity *)entity;
+ (NSString *) getDeleteSyntax:(HCEntity *)entity where:(NSString *)whereString;
+ (NSString *) getInsertSyntax:(HCEntity *)entity;
+ (NSString *) getUpateSyntax:(HCEntity *)newEntity orgData:(HCEntity *)orgEntity;
+ (NSString *) getExistsSyntax:(HCEntity *)entity;
+ (NSString *) getCountSyntax:(NSString*)tableName;
+ (NSString *)getArraySyntax:(NSString*)itemString;
+ (NSString *) getInsertSyntaxForPrepare:(HCEntity *)entity propDic:(NSMutableDictionary *)propDic;
+(BOOL) bindStatement:(sqlite3_stmt * )statement entity:(HCEntity * )entity propDic:(NSMutableDictionary *)propDic;
+(NSMutableArray*) bindStateValueArray:(HCEntity * )entity propDic:(NSMutableDictionary *)propDic;


+ (BOOL)IsPrimary:(NSString *)pName keyName:(NSString *)keyName;

+(NSString *)getUpdateSqlFromDictionary:(HCEntity *)entity datas:(NSDictionary *)data;

@end

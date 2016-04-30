//
//  NSEntity.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-9-24.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HCEPropetyType.h"

static NSMutableDictionary * g_propertyArray_;
//所有数据的基类
@interface HCEntity : NSObject<NSCoding,NSCopying>
{

@protected
    NSMutableDictionary *  _dataEntity;
    //NSArray *       _dataArray;
    //NSEntityType    EntityType;
    BOOL            Changed;
    NSMutableArray * _IncludeArray;
    
}
//@property(nonatomic,assign) int BindPageIndex;  //数据位于数据页的位置
//@property(nonatomic,assign) int BindPageRow;
//sqllite use
@property(nonatomic,retain) NSString * TableName;
@property(nonatomic,retain) NSString * KeyName;
@property(nonatomic,assign) BOOL toJsonLowercase;
@property(nonatomic,assign) BOOL ignoreNilValueForDic;
//@property(nonatomic,assign) NSEntityType EntityType;
- (void) resetProperties;
- (id) initWithDictionary:(NSDictionary *)dic;
- (id) initWithJSON:(NSString *)json;
- (NSMutableDictionary *)compare:(HCEntity *)other;    //比较同类型的数据，并将不同的数据字段放到返回结果中，字段值使用原数据的。
- (HCEntity *) dynamicCreateFromDictionary:(NSString *)typeName andValue:(id)value;
- (void)setPropValue:(NSString *)pName value:(id)value;

- (NSString *) toJson;
- (NSMutableDictionary *) toDicionary;

//- (NSArray *) toArray;
- (id) objectForKey:(NSString *)key;
- (void) setObject:(id)object forKey:(NSString *)aKey;
//当前的解析后的数据类型
//- (NSEntityType) entityType;
- (void) setChange:(BOOL) isChanged;
//请不要使用此方法
//- (void)setDictionary:(NSDictionary *)dic;
- (void)setProperties:(NSDictionary *)dic;
- (void)includeAll:(BOOL)isAll;
- (void)includeProperties:(NSString *)pname IsInclude:(BOOL)include;
- (BOOL)isInclude:(NSString *)pname;
- (NSMutableArray *)getPropNameArray:(Class)clazz;
- (NSMutableDictionary *)getPropTypes:(Class)clazz;
- (NSMutableDictionary *)getPropTypes:(Class)clazz withHirent:(BOOL)include;

@end

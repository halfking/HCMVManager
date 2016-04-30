//
//  HCEPropetyType.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-13.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCBase.h"

//从字典中获取属性的宏
//声称如下类似的语句
//id tempTagID = [dic objectForKey:@"TagID"];
//if(tempTagID!=nil)
//item.TagID = [tempTagID intValue];
//R
//The property is read-only (readonly).
//
//C
//The property is a copy of the value last assigned (copy).
//
//&
//The property is a reference to the value last assigned (retain).
//
//N
//The property is non-atomic (nonatomic).
//
//G<name>
//The property defines a custom getter selector name. The name follows the G (for example, GcustomGetter,).
//
//S<name>
//The property defines a custom setter selector name. The name follows the S (for example, ScustomSetter:,).
//
//D
//The property is dynamic (@dynamic).
//
//W
//The property is a weak reference (__weak).
//
//P
//The property is eligible for garbage collection.
//
//t<encoding>
//Specifies the type using old-style encoding.

// const char * ======>r*
// char *   =====>*
// char     =====>c
#ifndef NSENTITY_GETPROPERTIESFROMDIC
#define NSENTITY_GETPROP(objName,propName,dicName,getValue) id tempGP##propName = [dicName objectForKey:@""#propName ]; if(tempGP##propName != nil) objName.propName = [ tempGP##propName getValue]
#endif

#ifndef   NSENTITY_TYPE
#define   NSENTITY_TYPE
enum _NSEntityType {
    NSEDictionaryType         = 0,
    NSEArrayType              = 1,
    NSEProxyType              = 2
};
typedef u_int8_t NSEntityType;
#endif // NSENTITY_TYPE

//属性的类型
@interface HCEPropertyType : NSObject
{
@private
    const char *c;
    //    BOOL IsReadOnly;
    //    BOOL IsRetain;
    //    BOOL IsCopy;
    //    BOOL IsAssign;
    //    BOOL IsRedirectSet;//是否制定了特殊的设置方法
    //    NSString * Code;
    //    NSString * Type;
    //    NSString * Name;
    short isSize_;
    short isRect_;
    short isCMTime_;
    short isPoint_;
    short isUrl_;
}
@property(nonatomic,readonly) BOOL IsReadOnly;
@property(nonatomic,readonly) BOOL IsRetain;
@property(nonatomic,readonly) BOOL IsCopy;
@property(nonatomic,readonly) BOOL IsAssign;
@property(nonatomic,readonly) BOOL IsRedirectSet;
@property(nonatomic,readonly) BOOL IsWeak;
@property(nonatomic,readonly) BOOL IsDynamic;
@property(nonatomic,readonly) BOOL IsGarbage;
@property(nonatomic,readonly) BOOL IsConst;
@property(nonatomic,readonly) BOOL IsChar;
@property(nonatomic,readonly) NSString * Code;
@property(nonatomic,readonly) NSString * Type;
@property(nonatomic,readonly) NSString * Name;
@property(nonatomic,readonly) NSString * Getter;
@property(nonatomic,readonly) NSString * Setter;

-(HCEPropertyType *) initWithCodeNew:(const char *)code Name:(const char *)pName;
-(HCEPropertyType *) initWithCode:(NSString *)code Name:(NSString*)pName;
-(BOOL) canSetValue;
-(BOOL) complexValue;
-(BOOL) isNumber;
-(BOOL) isChar;
-(BOOL) isString;
-(BOOL) isMutableString;
-(BOOL) isNSData;
-(BOOL) isInt;
-(BOOL) isFloat;
-(BOOL) canSaveToData;
-(BOOL) isEntity;
-(BOOL) isArray;
-(BOOL) isDictionary;
- (BOOL) isUrl;
- (BOOL) isCMTime;
- (BOOL) isSize;
- (BOOL) isPoint;
- (BOOL) isRect;
@end


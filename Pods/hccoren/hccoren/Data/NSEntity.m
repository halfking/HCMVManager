
//  HCEntity.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-9-24.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//
//#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "NSEntity.h"
#import "JSON.h"
#import "HCBase.h"
#include <CoreMedia/CMTime.h>
#include <AVFoundation/AVTime.h>
#import "RegexKitLite.h"
#import <UIKit/UIGeometry.h>

//extern static NSMutableDictionary * g_propertyArray_;
@implementation HCEntity
@synthesize TableName = TableName;
@synthesize KeyName = KeyName;
@synthesize toJsonLowercase;
@synthesize ignoreNilValueForDic;
- (id) init{
    self = [super init];
    if(self)
    {
        //        if(_IncludeArray) [_IncludeArray release];
        //        _IncludeArray = [[NSMutableArray alloc]init];
        //        [self includeAll:YES];
        toJsonLowercase = YES;
        ignoreNilValueForDic  = YES;
#ifdef TRACKPAGES2
        Class claz = [self class];
        NSString * cname = NSStringFromClass(claz);
        void * p = (void*)self;
        NSString * addr = [NSString stringWithFormat:@"%X",(unsigned int)p];
        [[SystemConfiguration sharedSystemConfiguration] openPageRec:cname  Addr:addr];
#endif
    }
    return self;
}
- (id) initWithDictionary:(NSDictionary *)dic
{
    //    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc]init];
    self = [self init];
    //[self resetProperties];
    Changed = NO;
    if([dic isKindOfClass:[NSDictionary class]])
    {
        if(dic!=nil && [dic.allKeys count]>0)
            [self setProperties:dic];
        //    [pool drain];
    }
    else if(dic)
    {
        NSLog(@"initwith dicitionary for entity error:not is a dictionary.");
    }
    return self;
}
- (id) initWithJSON:(NSString *)json
{
    //    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc]init];
    self = [self init];
    if(!json || json.length<5) return self;
    
    Changed = NO;
    //test three json parse,find the native is best,sbjson second.
    //    NSError *error;
    //    NSDictionary * dic = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
    //                                                         options:NSJSONReadingMutableLeaves
    //                                                           error:nil];
    NSDictionary * dic = [json JSONValueEx];
    //    NSDictionary * dic = [json objectFromJSONString];
    //    NSDictionary * dic = [json objectFromJSONStringWithParseOptions:JKParseOptionLooseUnicode];
    if(dic!=nil)
    {
        [self setProperties:dic];
    }
    else
    {
        //        NSLog(@"parse json error:%@",[error description]);
    }
    //    [pool drain];
    return self;
    //return nil;
}
- (void)resetProperties
{
    if(_dataEntity) PP_RELEASE(_dataEntity);//[_dataEntity release];
}
- (NSMutableDictionary *)getPropTypes:(Class)clazz
{
    return [self getPropTypes:clazz withHirent:YES];
}
- (NSMutableDictionary *)getPropTypes:(Class)clazz withHirent:(BOOL)include
{
    NSMutableDictionary * propertyArray = nil;
    @synchronized(self)
    {
        if(!g_propertyArray_)
        {
            g_propertyArray_ = [NSMutableDictionary new];
        }
        NSString * className = NSStringFromClass(clazz);
        if([g_propertyArray_ objectForKey:className])
        {
            
            propertyArray =  (NSMutableDictionary *)[g_propertyArray_ objectForKey:className];
        }
        else
        {
            Class rootClazz = [HCEntity class];
            
            propertyArray = [self getPropTypesN:clazz];
            
            if(include)
            {
                //上级就是HCEntity，所以没有必要再进行下去
                if([clazz superclass] == rootClazz)
                {
                    //
                }
                else
                {
                    while ([[clazz superclass] isSubclassOfClass:rootClazz]) {
                        clazz = [clazz superclass];
                        if(clazz == rootClazz) break;
                        NSMutableDictionary * arrayTemp = [self getPropTypesN:clazz];
                        for (NSString * key in arrayTemp.keyEnumerator) {
                            if([propertyArray objectForKey:key]==nil)
                            {
                                [propertyArray setObject:[arrayTemp objectForKey:key] forKey:key];
                            }
                        }
                    }
                }
            }
            [g_propertyArray_ setObject:propertyArray forKey:className];
        }
    }
    return propertyArray;
}
- (NSMutableDictionary *)getPropTypesN:(Class)clazz
{
    //    if(g_propertyArray_==nil) [[NSMutableDictionary alloc]init];
    //    NSString  * cname =  [NSString stringWithCString: class_getName(clazz)  encoding:NSUTF8StringEncoding] ;
    //    NSMutableDictionary * dic = [g_propertyArray_ objectForKey:cname];
    //    if(dic!=nil) return dic;
    
    
    u_int count;
    
    objc_property_t* properties = class_copyPropertyList(clazz, &count);
    NSMutableDictionary * propertyArray = [[NSMutableDictionary alloc ] initWithCapacity:count];
    
    for (int i = 0; i < count ; i++)
    {
        const char* propertyName = property_getName(properties[i]);
        const char * propattr =    property_getAttributes(properties[i]);
        //         NSString *pName = [NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding];
        //    if([pName compare:@"IsSelected" options:1]==NSOrderedSame)
        //    {
        //        NSLog(@" check rights set properites...");
        //    }
        //
        //        HCEPropertyType * etype =[[HCEPropertyType alloc] initWithCode:[NSString stringWithCString:propattr encoding:NSUTF8StringEncoding] Name:pName];
        HCEPropertyType * etype =[[HCEPropertyType alloc] initWithCodeNew:propattr  Name:propertyName];
        [propertyArray
         setObject:etype
         forKey:etype.Name];
        //        if(!etype.Name) etype.Name = [NSString stringWithCString:propertyName];
        PP_RELEASE(etype);
        //        [etype release];
        //free((char*)propertyName);
        //free((char*)propattr);
        //        [propertyArray addObject:[NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding]];
        
    }
    free(properties);
    //    [g_propertyArray_ setObject:propertyArray forKey:cname];
    return PP_AUTORELEASE(propertyArray);
}

- (NSMutableArray *)getPropNameArray:(Class)clazz
{
    u_int count;
    
    objc_property_t* properties = class_copyPropertyList(clazz, &count);
    NSMutableArray* propertyArray = [[NSMutableArray alloc] init ];
    for (int i = 0; i < count ; i++)
    {
        const char* propertyName = property_getName(properties[i]);
        [propertyArray addObject:[NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding]];
        //free((char*)propertyName);
    }
    free(properties);
    return PP_AUTORELEASE(propertyArray);
}
- (void)setPropValue:(NSString *)pName value:(id)value
{
    u_int count;
    Class clazz = [self class];
    objc_property_t* properties = class_copyPropertyList(clazz, &count);
    HCEPropertyType * etype = nil;
    const char * cName = [pName cStringUsingEncoding:NSUTF8StringEncoding];
    for (int i = 0; i < count ; i++)
    {
        const char* propertyName = property_getName(properties[i]);
        size_t len = strlen(cName);
        if(strncasecmp(cName,propertyName,len)==0)
        {
            const char * propattr =    property_getAttributes(properties[i]);
            //            NSString *pName = [NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding];
            //            if([pName compare:@"IsSelected" options:1]==NSOrderedSame)
            //            {
            //                NSLog(@" check rights set properites...");
            //            }
            
            etype =[[HCEPropertyType alloc]
                    initWithCodeNew:propattr
                    Name:propertyName];
            break;
        }
    }
    free(properties);
    if(etype!=nil && ([etype canSetValue]))
    {
        NSString *name = etype.Name;// [NSString stringWithCString:cName encoding:NSUTF8StringEncoding];
        [self setPropValue:name propType:etype value:value];
        PP_RELEASE(etype);
        //        [etype release];
    }
    else
    {
        PP_RELEASE(etype);
        //        [etype release];
    }
}
- (void)setPropValue:(NSString *)pName propType:(HCEPropertyType *)pt value:(id)value
{
    //    if([pt.Name compare:@"GroupNoticID" options:1]==NSOrderedSame)
    //    {
    //        NSLog(@" check GroupNoticID set properites...");
    //    }
    if(value == nil ||[value isKindOfClass:[NSNull class]] || ((!value) &&[pt complexValue]))
    {
        @try {
            if(pt.isChar && !pt.IsRedirectSet)
            {
                [self setValue:[NSNumber numberWithInt:0] forKey:pName];
                //                [self setValue:[NSNull null] forKey:pName];
            }
            else if(pt.isFloat&& !pt.IsRedirectSet)
            {
                [self setValue:[NSNumber numberWithFloat:0.0f] forKey:pName];
            }
            else if(pt.isInt)
            {
                [self setValue:[NSNumber numberWithInt:0] forKey:pName];
            }
            else if (pt.isNumber && !pt.IsRedirectSet)
            {
                [self setValue:[NSNumber numberWithDouble:0] forKey:pName];
            }
            else
                [self setValue:nil forKey:pName];
            //NSLog(@"name:%@,value:%@",pName,[self valueForKey:pName]);
        }
        @catch (NSException *exception) {
            NSLog(@"set properties error:name:%@ value:%@ error:%@",pName,value,[exception description]);
            @try {
                //                 object_setInstanceVariable(self, [pName cStringUsingEncoding:NSUTF8StringEncoding], nil);
                [self setNilValueForKey:pName];
                //NSLog(@"name:%@,value:%@",pName,[self valueForKey:pName]);
            }
            @catch (NSException *exception) {
                NSLog(@"set properties error:name:%@ value:%@ error:%@",pName,value,[exception description]);
            }
            @finally {
                
            }
            
        }
        @finally {
            
        }
    }
    else if([pt isString] == TRUE && (![pt isMutableString]))
    {
        if([value isKindOfClass:[NSString class]])
        {
            if([(NSString *)value length]==0)
            {
                [self setValue:@"" forKey:pName];
            }
            else
            {
                [self setValue:value forKey:pName];
            }
        }
        else if([value isKindOfClass:[NSArray class]])
        {
            NSArray * array = (NSArray *)value;
            if(array)
            {
                [self setValue:[array JSONRepresentationEx] forKey:pName];
            }
            else
            {
                [self setValue:@"[]" forKey:pName];
            }
        }
        else if([value isKindOfClass:[NSDictionary class]])
        {
            NSDictionary * dicT = (NSDictionary *)value;
            if(dicT)
            {
                [self setValue:[dicT JSONRepresentationEx] forKey:pName];
            }
            else
            {
                [self setValue:@"{}" forKey:pName];
            }
        }
        //NSLog(@"name:%@,value:%@",pName,[self valueForKey:pName]);
    }
    else if(![pt complexValue])
    {
        @try {
            if(pt.isChar)
            {
                @try {
                    if([value isKindOfClass:[NSString class]])
                    {
                        NSString * tempvalue = (NSString *)value;
                        [self setValue:[NSNumber numberWithShort:[tempvalue intValue]] forKey:pName];
                    }
                    else
                        [self setValue:value forKey:pName];
                }
                @catch (NSException *exception) {
                    //                    if([value isKindOfClass:[NSString class]])
                    //                    {
                    //                        @try {
                    //                            NSString * tempvalue = (NSString *)value;
                    //                            [self setValue:[NSNumber numberWithShort:[tempvalue intValue]] forKey:pName];
                    //                        }
                    //                        @catch (NSException *exception) {
                    //                             NSLog(@"set properties error6:name:%@ value:%@ error:%@",pName,value,[exception description]);
                    //                        }
                    //                        @finally {
                    //
                    //                        }
                    //
                    //                    }
                    //                    else
                    //                    {
                    NSLog(@"set properties error5:name:%@ value:%@ error:%@",pName,value,[exception description]);
                    //                    }
                }
                @finally {
                    
                }
                
            }
            else if (pt.isNumber)
            {
                if([pt.Type isEqualToString:@"l"])
                {
                    if([value isKindOfClass:[NSString class]])
                    {
                        [self setValue:[NSNumber numberWithLong:(long)[((NSString *)value) longLongValue] ] forKey:pName];
                    }
                    else
                        [self setValue:value forKey:pName];
                }
                else if([pt.Type isEqualToString:@"d"])
                {
                    if([value isKindOfClass:[NSString class]])
                    {
                        [self setValue:[NSNumber numberWithDouble:[((NSString *)value) doubleValue] ] forKey:pName];
                    }
                    else
                        [self setValue:value forKey:pName];
                    
                }
                else if([pt.Type isEqualToString:@"f"])
                {
                    if([value isKindOfClass:[NSString class]])
                    {
                        [self setValue:[NSNumber numberWithFloat:[((NSString *)value) floatValue] ] forKey:pName];
                    }
                    else
                        [self setValue:value forKey:pName];
                }
                else
                {
                    if([value isKindOfClass:[NSString class]])
                    {
                        [self setValue:[NSNumber numberWithInt:[((NSString *)value) intValue] ] forKey:pName];
                    }
                    else
                    {
                        [self setValue:value forKey:pName];
                    }
                }
            }
            else
                [self setValue:value forKey:pName];
            //[self setValue:value forKey:pName];
        }
        @catch (NSException *exception) {
            NSLog(@"set properties error:name:%@ value:%@ error:%@",pName,value,[exception description]);
            @try {
                //                object_setInstanceVariable(self, [pName cStringUsingEncoding:NSUTF8StringEncoding], value);
                [self setNilValueForKey:pName];
                //NSLog(@"name:%@,value:%@",pName,[self valueForKey:pName]);
            }
            @catch (NSException *exception) {
                NSLog(@"set properties error:name:%@ value:%@ error:%@",pName,value,[exception description]);
            }
            @finally {
                
            }
            
        }
        @finally {
            
        }
    }
    else
    {
        if([pt isUrl])
        {
            NSURL * url = [NSURL URLWithString:value];
            [self setValue:url forKey:pName];
            NSLog(@"is url");
        }
        else if([pt isCMTime])
        {
            CMTime time;
            NSString * sv = [NSString stringWithFormat:@"%@,",value];
            NSRange rangTemp = NSMakeRange(0, sv.length);
            NSRange rangEnd = [sv rangeOfRegex:@"," inRange:rangTemp];
            int index = 0;
            while (rangEnd.length>0) {
                NSString * temp = [sv substringWithRange:NSMakeRange(rangTemp.location, rangEnd.location - rangTemp.location)];
                if(index==0)
                {
                    time.value = [temp longLongValue];
                }
                else if(index ==1)
                {
                    time.timescale = [temp intValue];
                }
                else if(index ==2)
                {
                    time.flags = [temp intValue];
                }
                else if(index ==3)
                {
                    time.epoch = [temp longLongValue];
                }
                index ++;
                rangTemp.location = rangEnd.location + rangEnd.length;
                rangTemp.length = sv.length - rangTemp.location;
                rangEnd = [sv rangeOfRegex:@"," inRange:rangTemp];
            }
            NSValue * vv = [NSValue valueWithCMTime:time];
            [self setValue:vv forKey:pName];
        }
        else if([pt isSize])
        {
            CGSize  size = CGSizeFromString(value);
            NSValue * vv = [NSValue valueWithCGSize:size];
            [self setValue:vv forKey:pName];
            //            [self setValue:NSStringFromCGSize((CGSize)value) forKey:pName];
        }
        else if([pt isPoint])
        {
            CGPoint  size = CGPointFromString(value);
            NSValue * vv = [NSValue valueWithCGPoint:size];
            [self setValue:vv forKey:pName];
            //            [self setValue:NSStringFromCGSize((CGSize)value) forKey:pName];
        }
        else if([pt isRect])
        {
            CGRect  rect = CGRectFromString(value);
            NSValue * vv = [NSValue valueWithCGRect:rect];
            [self setValue:vv forKey:pName];
            //            [self setValue:NSStringFromCGSize((CGSize)value) forKey:pName];
        }
        else
        {
            //可能递归的数据结构
            if([value isKindOfClass:[NSDictionary class]]==YES)
            {
                if([pt isMutableString]==YES)
                {
                    NSMutableString * string = [NSMutableString stringWithString:[value JSONRepresentationEx]];
                    [self setValue:string forKey:pName];
                }
                else if([pt isString]==YES)
                {
                    [self setValue:[value JSONRepresentationEx] forKey:pName];
                }
                else
                {
                    HCEntity * entity = [self dynamicCreateFromDictionary:pt.Type andValue:value];
                    if(entity!=nil)
                    {
                        [self setValue:entity forKey:pName];
                    }
                    else
                    {
                        [self setValue:value forKey:pName];
                    }
                }
            }
            else if([value isKindOfClass:[NSArray class]]==YES)
            {
                //因为Array下的数据类型无法准确确定，因此取消这里的进一步解析，如果需要进一步，则手工处理
                //可以在子类中重写这一方法
                //                            NSArray * array = [self dynamicCreateListFromArray:pt.Type andValue:value];
                //                            if(array!=nil)
                //                               [self setValue:array forKey:name];
                //                            else
                if([pt isMutableString]==YES)
                {
                    NSMutableString * string = [NSMutableString stringWithString:[value JSONRepresentationEx]];
                    [self setValue:string forKey:pName];
                }
                else if([pt isString]==YES)
                {
                    [self setValue:[value JSONRepresentationEx] forKey:pName];
                }
                else
                {
                    [self setValue:value forKey:pName];
                }
            }
            else{
#ifndef __OPTIMIZE__
                if([value isKindOfClass:[NSString class]])
                {
                    NSLog(@"property:%@ type:%@ cannot put value(%@).",pName,pt.Type,(NSString*)value);
                }
                else
                {
                    NSLog(@"property:%@ type:%@ cannot put value().",pName,pt.Type);
                }
#endif
//                [self setValue:value forKey:pName];
                //NSLog(@"name:%@,value:%@",pName,[self valueForKey:pName]);
            }
        }
    }
}

- (void)setProperties:(NSDictionary *)dic
{
    if(dic==nil)
    {
        NSLog(@"NULL DIC to setProperties.");
        return ;
    }
    if([dic count]==0) return;
    //    if([super respondsToSelector:@selector(setProperties:)])
    //    {
    //        [super performSelector:@selector(setProperties:) withObject:dic];
    //    }
//    PP_RETAIN(dic);
    //    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    PP_BEGINPOOL(pool);
    
    //EntityType =NSEDictionaryType;
    
    //    if(_dataEntity!=nil) [_dataEntity release];
    //    _dataEntity = [[NSMutableDictionary alloc] initWithDictionary: dic];
    //    [dic release];
    @try {
        Class clazz = [self class];
        
        NSMutableDictionary * propertyArray = PP_RETAIN([self getPropTypes:clazz withHirent:YES]);
        
        
        NSEnumerator * enumeratorKey = [dic keyEnumerator];
        
        for (NSString *keyName in enumeratorKey)
        {
            
            BOOL hasProperty = FALSE;
            HCEPropertyType *pt = nil;
            NSString * pName = nil;
            //因为后台显示的JSON中的名称均是小写
            
            for (NSString *name in propertyArray.keyEnumerator)
            {
                NSString *myName = [[NSString alloc]init];
                if([name hasPrefix:@"_"] == YES)
                {
                    myName = [name substringFromIndex:1];
                }
                else if ([name hasPrefix:@"_"] == NO)
                {
                    myName = name;
                }
                //快速枚举遍历所有KEY的值
                
                //for (NSString *object in enumeratorKey) {
                
                if([keyName compare:myName options:NSCaseInsensitiveSearch]==kCFCompareEqualTo)
                {
                    pt = [propertyArray objectForKey:myName];
                    
                    pName = name;
                    hasProperty = TRUE;
                    break;
                }
            }
            //            if([keyName compare:@"Lat" options:1]==NSOrderedSame)
            //            {
            //                NSLog(@"name:%@,value:%@",keyName,[_dataEntity objectForKey:keyName]);
            //            }
            //只读属性无法赋值
            //            if(pt.canSetValue==FALSE) continue;
            
            //如果数据中没有此属性的值，则不处理此属性
            if(hasProperty == FALSE) continue;
            
            
            id value = [dic objectForKey:keyName];
            
            //有特殊get/set的需要另外方式
            //复合类型的赋值
            //简单类型的赋值
            @try {
                //                if([keyName compare:@"UserID" options:1]==NSOrderedSame)
                //                {
                //                    @try {
                //                        NSString * userid  = [NSString stringWithFormat:@"%d",(int)value];
                //                        NSLog(@"userid:%@",userid);
                //                    }
                //                    @catch (NSException *exception) {
                //                        NSString * userid2  = [NSString stringWithFormat:@"%@",value];
                //                        NSLog(@"userid:%@",userid2);
                //                    }
                //                    @finally {
                //
                //                    }
                //
                //                }
                [self setPropValue:pName propType:pt value:value];
            }
            @catch (NSException *exception) {
                NSLog(@"refrect class error 2:%@",[exception description]);
                NSLog(@"Prop:%@,TYPE:%@",pName,pt.Code);
            }
            @finally {
                
            }
        }
        PP_RELEASE(propertyArray);
        //        [propertyArray release];
    }
    @catch (NSException *exception) {
        NSLog(@"refrect class error:%@",[exception description]);
    }
    @finally {
        
        //        _dataEntity = nil;
    }
    //    [pool drain];
    PP_ENDPOOL(pool);
//    PP_RELEASE(dic);
    //    [dic release];
}
//将DIC转成NSEEntity
- (HCEntity *) dynamicCreateFromDictionary:(NSString *)typeName andValue:(id)value
{
    NSString * excTypeName  = nil;
    if([typeName rangeOfString:@"@\""].length>0)
    {
        unsigned long len = typeName.length -3;
        if(len <=0) return nil;
        excTypeName = [typeName substringWithRange:NSMakeRange(2, len)];
    }
    else
        excTypeName = [NSString stringWithString:typeName];
    if(excTypeName.length>=2)
    {
        if([excTypeName compare:@"NSDictionary" options:NSCaseInsensitiveSearch]!=0
           &&[excTypeName compare:@"NSMutableDictionary" options:NSCaseInsensitiveSearch]!=0)
        {
//            PP_RETAIN(value);//[value retain];
            //NSRange range1  = NSMakeRange(2, excTypeName.length-3);
            //NSString * newType = [typeName substringWithRange:range1];
            HCEntity * object = [[NSClassFromString(excTypeName) alloc] init];
            object = [object initWithDictionary:value];
//            PP_RELEASE(value);
            //            [value release];
            
            
            return PP_AUTORELEASE(object);
        }
        
    }
    return nil;
}
- (NSArray *) dynamicCreateListFromArray:(NSString *) typeName andValue:(id)value
{
    
    NSArray * list = [[NSArray alloc]initWithArray:value];
    NSMutableArray * result = [[NSMutableArray alloc] initWithCapacity:list.count];
    for (id object in list) {
        if([object isKindOfClass:[NSDictionary class]]==YES)
        {
            
            NSString * className = @"@\"HCEntity\"";//[object classNameForClass:[object class]];
            
            HCEntity * nse = [self dynamicCreateFromDictionary:className andValue:object];
            if(nse!=nil)
                [result addObject:nse];
            else
                [result addObject:object];
        }
        else if([object isKindOfClass:[NSArray class]]==YES)
        {
            NSArray * newArrayItem = [self dynamicCreateListFromArray:typeName andValue:object];
            [result addObject:newArrayItem];
            
        }
        else
            [result addObject:object];
    }
    PP_RELEASE(list);
    //    [list release];
    return PP_AUTORELEASE(result);
}
#pragma mark - compare
- (id)comparePropValues:(HCEPropertyType *)pt value:(id)value value_other:(id)value_other// diffValue:(id *)diffValue
{
    BOOL isSame = YES;
    BOOL isValueNull = value==nil || [value isKindOfClass:[NSNull class]];
    BOOL isOtherNull = value_other==nil || [value_other isKindOfClass:[NSNull class]];
    
    if((isValueNull && !isOtherNull) || (!isValueNull && isOtherNull))
    {
        isSame = NO;
    }
    else if(isValueNull && isOtherNull)
    {
        isSame = YES;
    }
    else
    {
        if([pt isNumber]||[pt isChar])
        {
            if([pt isInt])
            {
                if([value intValue]!=[value_other intValue])
                {
                    isSame = NO;
                }
            }
            else
            {
                if([value doubleValue]!= [value_other doubleValue])
                {
                    isSame = NO;
                }
            }
        }
        else if([pt isString])
        {
            
            NSString * v1 = [NSString stringWithString:(NSString*)value];
            NSString *v2 = [NSString stringWithString:(NSString *)value_other];
            if([v1 compare:v2]!=NSOrderedSame)
                isSame = NO;
            
        }
        else if([pt isNSData])
        {
            NSData * v11 = (NSData*)value;
            NSData * v21 = (NSData *)value_other;
            NSString * v1 = [[NSString alloc]initWithData:v11 encoding:NSUTF8StringEncoding];
            NSString * v2 = [[NSString alloc]initWithData:v21 encoding:NSUTF8StringEncoding];
            if([v1 compare:v2]!=NSOrderedSame)
                isSame = NO;
            PP_RELEASE(v1);
            PP_RELEASE(v2);
            //            [v1 release];
            //            [v2 release];
            
        }
        else if(![pt complexValue])
        {
            if(value!=value_other)
            {
                isSame = NO;
            }
        }
        else
        {
            if([value isKindOfClass:[HCEntity class]])
            {
                HCEntity * v1 = (HCEntity *) (value);
                HCEntity *v2  = (HCEntity *)value_other;
                NSMutableDictionary * dicTemp = [v1 compare:v2];
                if(dicTemp!=nil && [dicTemp count]>0)
                {
                    isSame = NO;
                    value = dicTemp;
                }
            }
            else if([value isKindOfClass:[NSDictionary class]])
            {
                NSString * v1 = [NSString stringWithString:[value JSONRepresentationEx]];
                NSString *v2 = [NSString stringWithString:[value_other JSONRepresentationEx]];
                if([v1 compare:v2]!=NSOrderedSame)
                    isSame = NO;
            }
            else if([value isKindOfClass:[NSArray class]])
            {
                NSString * v1 = [NSString stringWithString:[value JSONRepresentationEx]];
                NSString *v2 = [NSString stringWithString:[value_other JSONRepresentationEx]];
                if([v1 compare:v2]!=NSOrderedSame)
                    isSame = NO;
            }
            else
            {
                
            }
        }
    }
    if(!isSame)
        return value;
    else
        return nil;
    //    return isSame;
}
//- (BOOL)isEqual:(HCEntity *)other
//{
//
//}
- (NSMutableDictionary *)compare:(HCEntity *)other{    //比较同类型的数据，并将不同的数据字段放到返回结果中，字段值使用原数据的。
    NSMutableDictionary * result = [[NSMutableDictionary alloc]init];
    
    Class clazz = [self class];
    
    @try {
        
        NSMutableDictionary *propertyDictionary = PP_RETAIN([self getPropTypes:clazz withHirent:YES]);
        NSMutableArray* propertyArray = PP_RETAIN([self getPropNameArray:clazz]);
        NSMutableArray* propertyArray_other = PP_RETAIN([self getPropNameArray:[other class]]);
        
        HCEPropertyType *pt = nil;
        for (NSString *name in propertyArray)
        {
            pt = [propertyDictionary objectForKey:name];
            BOOL isFind = NO;
            //            BOOL isSame = YES;
            NSString * name_other= nil;
            for (NSString * name2 in propertyArray_other) {
                if([name compare:name2 options:NSCaseInsensitiveSearch] ==NSOrderedSame )
                {
                    isFind  = YES;
                    name_other = name2;
                    break;
                }
            }
            id value = [self valueForKey:name];
            id diffValue = [NSNull null];
            if(isFind){
                //比较值，看两者是否一致，注意数据类型，值类型还是引用类型
                
                id value_other = [other valueForKey:name_other];
                
                diffValue = [self comparePropValues:pt value:value value_other:value_other];
            }
            if((!isFind && value && (![value isKindOfClass:[NSNull class]])) || (diffValue && (![diffValue isKindOfClass:[NSNull class]])))
            {
                [result setObject:diffValue forKey:name];
            }
        }
        PP_RELEASE(propertyArray);
        PP_RELEASE(propertyDictionary);
        PP_RELEASE(propertyArray_other);
    }
    @catch (NSException *exception) {
        NSLog(@"compare using refrect error:%@",[exception description]);
//        PP_RELEASE(other);
        return nil;
    }
    @finally {
    }
//    PP_RELEASE(other);
    return PP_AUTORELEASE(result);// [result autorelease];
}
#pragma mark - TOJSON

- (NSString *) toJson
{
    NSMutableDictionary * muDic = [self toDicionary];
    NSString * result = PP_RETAIN([muDic JSONRepresentationEx]);
    return PP_AUTORELEASE(result);// [result autorelease];
}
- (NSArray *) getArrayDictionaries:(NSArray *) value
{
    if(value==nil) return nil;
    NSMutableArray * newArray = [[NSMutableArray alloc]initWithCapacity:value.count];
    for (id object in value) {
        if([object isKindOfClass:[HCEntity class]]==YES)
        {
            NSDictionary * dic = PP_RETAIN([(HCEntity *)object toDicionary]);
            [newArray addObject:dic];
            PP_RELEASE(dic);
            //            [dic release];
        }
        else if([object isKindOfClass:[NSArray class]]==YES)
        {
            NSArray * na = [self getArrayDictionaries:(NSArray*)object];
            if(na!=nil)
                [newArray addObject:na];
            else
                [newArray addObject:object];
        }
        else
            [newArray addObject:object];
    }
    return PP_AUTORELEASE(newArray);// [newArray autorelease];
}
- (id) objectForKey:(NSString *)key
{
    //    if(_dataEntity!=nil)
    //    {
    //        NSString * nameLower = [key lowercaseString];
    //        id result = [_dataEntity objectForKey:nameLower ];
    //        [nameLower release];
    //        return result;
    //    }
    //    else
    //    {
    @try {
        return [self valueForKey:key];
    }
    @catch (NSException *exception) {
        NSLog(@"get class property value failure:%@",[exception description]);
    }
    @finally {
        
    };
    return  nil;
    //    }
}
- (void) setObject:(id)object forKey:(NSString *)aKey
{
    @try {
        [self setValue:object forKey:aKey];
        //        if(_dataEntity!=nil)
        //        {
        //            NSString * nameLower = [aKey lowercaseString];
        //            [_dataEntity setObject:object forKey:nameLower];
        //            [nameLower release];
        //        }
    }
    @catch (NSException *exception) {
        NSLog(@"set class property value failure:%@",[exception description]);
    }
    @finally {
        
    };
}
//- (NSArray *) toArray
//{
//    if(EntityType == NSEArrayType)
//        return _dataArray;
//    else
//        return nil;
//}
- (NSMutableDictionary *) toDicionary
{
    //    if(Changed==NO &&_dataEntity!=nil)
    //        return [[_dataEntity copy] autorelease];
    //    else
    //    {
    //    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc]init];
    @try {
        
        //
        Class clazz = [self class];
        //            u_int count;
        
        NSMutableDictionary * muDic = [[NSMutableDictionary alloc] init];
        
        NSMutableDictionary * propDic = [self getPropTypes:clazz withHirent:YES];
        //            objc_property_t* properties = class_copyPropertyList(clazz, &count);
        //            NSMutableArray* propertyArray = [NSMutableArray arrayWithCapacity:count];
        //            for (int i = 0; i < count ; i++)
        //            {
        //                const char* propertyName = property_getName(properties[i]);
        //                [propertyArray addObject:[NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding]];
        //            }
        //            free(properties);
        
        for (NSString *name in propDic)
        {
            id value = nil;
            HCEPropertyType * pt = [propDic objectForKey:name];
            @try {
                if(!pt.IsRedirectSet)
                {
                    value = [self valueForKey:name];
                }
                else
                    continue;
            }
            @catch (NSException *exception) {
                NSLog(@"get [%@]value error:%@",name,[exception description]);
                continue;
            }
            @finally {
                
            }
            if(value == nil) continue;
            NSString * nameLower = toJsonLowercase?[name lowercaseString]:name;//[name lowercaseString];
            
            if([value isKindOfClass:[HCEntity class]]==YES)
            {
                NSDictionary * tempDic = [(HCEntity *)value toDicionary];
                [muDic setObject:tempDic forKey:nameLower];
            }
            else if([value isKindOfClass:[NSArray class]]==YES)
            {
                NSArray * tempArray = [self getArrayDictionaries:(NSArray*)value];
                if(tempArray ==nil)
                {
                    [muDic setObject:value forKey:nameLower];
                }
                else
                {
                    [muDic setObject:tempArray forKey:nameLower];
                }
            }
            else{
                //                    if(value==nil)
                //                        [muDic setNilValueForKey:nameLower];
                //                    else
                if(self.ignoreNilValueForDic)
                {
#ifdef OPTIZE_SET
                    if(pt.isString && (value == nil||[value isKindOfClass:[NSNull class]]))
                    {
                        
                    }
                    else if(pt.isInt && [value intValue]==0)
                    {
                        
                    }
                    else if(pt.isNumber && round([value doubleValue]*1000)==0)
                    {
                        
                    }
                    else
                    {
                        [self toDictionaryValueExtend:pt name:nameLower value:value dictionary:muDic];
                    }
#else
                    [self toDictionaryValueExtend:pt name:nameLower value:value dictionary:muDic];
#endif
                }
                else
                {
                    [self toDictionaryValueExtend:pt name:nameLower value:value dictionary:muDic];
                }
            }
            //[muDic setObject:value forKey:nameLower];
            
            //[nameLower release];
        }
        //        [pool drain];
        //        pool = nil;
        return PP_AUTORELEASE(muDic);// [muDic autorelease];
        
    }
    @catch (NSException *exception) {
        NSLog(@"refrect class error 3:%@",[exception description]);
    }
    @finally {
        //        if(pool) [pool drain];
    }
    return nil;
    //    }
}
- (void)toDictionaryValueExtend:(HCEPropertyType*)pt name:(NSString *)nameLower value:(id)value dictionary:(NSMutableDictionary*)muDic
{
    if([pt isSize])
    {
        CGSize size = CGSizeZero;
        [value getValue:&size];
        if(size.width!=0 ||size.height!=0)
        {
            NSString * str = NSStringFromCGSize(size);
            [muDic setObject:str forKey:nameLower];
        }
    }
    else if([pt isRect])
    {
        CGRect size = CGRectZero;
        [value getValue:&size];
        if(!CGRectIsEmpty(size))
        {
             NSString * str = NSStringFromCGRect(size);
            [muDic setObject:str forKey:nameLower];
        }
    }
    else if([pt isPoint])
    {
        CGPoint size = CGPointZero;
        [value getValue:&size];
        if(size.x!=0||size.y!=0)
        {
            NSString * str = NSStringFromCGPoint(size);
            [muDic setObject:str forKey:nameLower];
        }
    }
    else if([pt isCMTime])
    {
        CMTime time;
        [value getValue:&time];
        if(CMTIME_IS_VALID(time))
        {
            //            NSValue * vv = [NSValue valueWithCMTime:time];
            //
            //            [muDic setObject:[NSString stringWithFormat:@"%@",vv] forKey:nameLower];
            [muDic setObject:[NSString stringWithFormat:@"%ld,%d,%d,%ld",(long)time.value,time.timescale,time.flags,(long)time.epoch] forKey:nameLower];
        }
    }
    else
        [muDic setObject:value==nil?[NSNull null]:value forKey:nameLower];
}
#pragma encodeWithCode decodeWithCoder
- (void)encodeWithCoder:(NSCoder*)coder
{
    Class clazz = [self class];
    
    NSMutableArray* propertyArray = PP_RETAIN([self getPropNameArray:clazz]);
    NSMutableDictionary * p2 = [self getPropTypes:clazz withHirent:YES];
    
    for (NSString *name in propertyArray)
    {
        HCEPropertyType * ptype =  (HCEPropertyType*)[p2 objectForKey:name];
        //NSLog(@"encoder %@",name);
        if(ptype && [ptype canSetValue])
        {
            @try {
                id value = [self valueForKey:name];
                [coder encodeObject:value forKey:name];
            }
            @catch (NSException *exception) {
                NSLog(@"encode [%@] error:%@",name,[exception description]);
            }
            @finally {
                
            }
        }
        
    }
    PP_RELEASE(propertyArray);
    //    [propertyArray release];
}

- (id)initWithCoder:(NSCoder*)decoder
{
    
    if (self = [super init])
    {
        if (decoder == nil)
        {
            return self;
        }
        @try {
            Class clazz = [self class];
            
            NSMutableDictionary * propertyArray = PP_RETAIN([self getPropTypes:clazz withHirent:YES]);
            
            for (NSString *name in propertyArray.keyEnumerator)
            {
                
                
                HCEPropertyType *pt = [propertyArray objectForKey:name];
                //只读属性无法赋值
                if([pt canSetValue]==FALSE) continue;
                //因为后台显示的JSON中的名称均是小写
                id value = [decoder decodeObjectForKey:name];
                //有特殊get/set的需要另外方式
                //复合类型的赋值
                //简单类型的赋值
                NSString *pName  = name;
                //                if([pName compare:@"ischanged" options:1]==NSOrderedSame)
                //                {
                //                    NSLog(@"name:%@,value:%@",pName,value);
                //                }
                @try {
                    [self setPropValue:pName propType:pt value:value];
                }
                @catch (NSException *exception) {
                    NSLog(@"refrect class error 2:%@",[exception description]);
                    NSLog(@"TYPE:%@",pt.Code);
                }
                @finally {
                    
                }
                
                
            }
            PP_RELEASE(propertyArray);
            //            [propertyArray release];
        }
        @catch (NSException *exception) {
            NSLog(@"refrect class error:%@",[exception description]);
        }
        @finally {
            
        }
        
    }
    return self;
}
- (id) copyWithZone:(NSZone *)zone
{
    //    NSString * className = [NSString stringWithCString:object_getClassName([self class]) encoding:NSUTF8StringEncoding];
    //    NSString * json = [self toJson];
    //    return [[[self class]alloc]initWithJSON:json];
    //    NSMutableDictionary * dic = [self ];
    //    return [self dynamicCreateFromDictionary:className andValue:dic];
    
    //    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc]init];
    
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:self];
    
    id result =  PP_RETAIN([NSKeyedUnarchiver unarchiveObjectWithData:data]);
    
    //    [pool drain];
    
    return result;
    
}

//解析后得到的当前对象的类型ß
//- (NSEntityType) entityType
//{
//    return EntityType;
//}
- (void) setChange:(BOOL)isChanged
{
    Changed = isChanged;
}
- (void)includeAll:(BOOL)isAll
{
    if(isAll)
    {
        [_IncludeArray removeAllObjects];
        
        Class clazz = [self class];
        u_int count;
        
        objc_property_t* properties = class_copyPropertyList(clazz, &count);
        for (int i = 0; i < count ; i++)
        {
            const char* propertyName = property_getName(properties[i]);
            NSString * name = [NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding];
            [_IncludeArray addObject:name];
        }
        free(properties);
    }
    else
    {
        [_IncludeArray removeAllObjects];
    }
}
- (void)includeProperties:(NSString *)pname IsInclude:(BOOL)include
{
    BOOL isFind = NO;
    int index = -1;
    for (NSString * name in _IncludeArray) {
        index ++;
        if([name compare:pname options:1]==NSOrderedSame)
        {
            isFind = YES;
            break;
        }
    }
    if(include)
    {
        if(!isFind)
        {
            [_IncludeArray addObject:pname];
        }
    }
    else
    {
        if(isFind)
        {
            [_IncludeArray removeObjectAtIndex:index];
        }
    }
}
- (BOOL)isInclude:(NSString *)pname
{
    BOOL isFind = NO;
    for (NSString * name in _IncludeArray) {
        if([name compare:pname options:1]==NSOrderedSame)
        {
            isFind = YES;
            break;
        }
    }
    return isFind;
}
- (void) dealloc
{
#ifdef TRACKPAGES2
    Class claz = [self class];
    NSString * cname = NSStringFromClass(claz);
    void * p = (void*)self;
    NSString * addr = [NSString stringWithFormat:@"%X",(unsigned int)p];
    [[SystemConfiguration sharedSystemConfiguration] closePageRec:cname  Addr:addr];
#endif
    
    PP_RELEASE(TableName);
    PP_RELEASE(KeyName);
    if(_IncludeArray)
    {
        PP_RELEASE(_IncludeArray);
    }
    if(_dataEntity!=nil){
        PP_RELEASE(_dataEntity);
    }
    PP_SUPERDEALLOC;
}
@end

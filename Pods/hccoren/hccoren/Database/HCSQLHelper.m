//
//  HCSQLHelper.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-16.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//
// 处理ＳＱＬ拼装等事情
#import "HCSQLHelper.h"
#import "CommonUtil.h"
#import "CommonUtil(Date).h"
#import "JSON.h"
#import "RegexKitLite.h"
#import "HCBase.h"
#import <sqlite3.h>
@implementation HCSQLHelper
+ (NSString *) columNameCheck:(NSString*)name
{
    if(name)
    {
        NSError * error = nil;
        if([name isMatchedByRegex:@"index|user|column|key|from|int|varchar" options:RKLCaseless inRange:NSMakeRange(0, name.length) error:&error])
        {
            return [NSString stringWithFormat:@"[%@]",name];
        }
    
    }
    return name;
}
+ (NSString *) getFieldSyntax:(HCEPropertyType *)pt isprimarykey:(BOOL)isPrimaryKey
{
    
    return [NSString stringWithFormat:@"%@ %@ %@",[HCSQLHelper columNameCheck:pt.Name],
            [HCSQLHelper fieldTypeName:pt],
            (isPrimaryKey?@"PRIMARY KEY ":@"") ];
}
+ (NSString *) fieldTypeName:(HCEPropertyType *)pt
{
    NSString * typeString = @"TEXT";
    if([pt isInt])
    {
        typeString = @"INTEGER";
    }
    else if([pt isNumber])
    {
        typeString = @"REAL";
    }
    else if([pt isNSData])
    {
        typeString = @"BLOB";
    }
//    else if([pt isArray])
//    {
//       typeString = @"TEXT";
//    }
//    else if([pt isDictionary])
//    {
//        typeString = @"TEXT";
//    }
//    else if([pt isEntity])
//    {
//        typeString = @"TEXT";
//    }

    return typeString;
}
+ (NSString *) fieldCompareSyntax:(HCEPropertyType *)pt value:(id)value
{
    if(pt==nil || (![pt canSaveToData]))
    {
        NSLog(@"get field compare syntax error:field not exists or not saved in db table.");
        return nil;
    }
    if(value ==nil || [value isKindOfClass:[NSNull class]])
    {
        return [NSString stringWithFormat:@"%@ IS NULL",[HCSQLHelper columNameCheck:pt.Name]];
    }
    
    if([pt isInt])
    {
        return [NSString stringWithFormat:@"%@=%d",[HCSQLHelper columNameCheck:pt.Name],[value intValue]];
    }
    else if([pt isNumber]||[pt IsChar])
    {
        return [NSString stringWithFormat:@"%@=%f",[HCSQLHelper columNameCheck:pt.Name],[value doubleValue]];
    }
    else if([pt isString])
    {
        if([value isKindOfClass:[NSDate class]]) //日期有可能保存为字串
        {
            return [NSString stringWithFormat:@"%@='%@'",[HCSQLHelper columNameCheck:pt.Name],[CommonUtil stringFromDate:(NSDate*)value]];
        }
        else
        {
            NSString * v1 = [(NSString *)value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
            return [NSString stringWithFormat:@"%@='%@'",[HCSQLHelper columNameCheck:pt.Name],v1];
        }
    }
    else if([pt isNSData])
    {
        NSString * string = PP_AUTORELEASE([[NSString alloc]initWithData:(NSData*)value encoding:NSUTF8StringEncoding]);
        return [NSString stringWithFormat:@"%@='%@'",[HCSQLHelper columNameCheck:pt.Name],[string stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
    }
    return @"";
}
+ (NSString *) fieldValueString:(HCEPropertyType *)pt value:(id)value
{
    if(pt==nil || (![pt canSaveToData]))
    {
        NSLog(@"get field cfieldValueString error:field not exists or not saved in db table.");
        return nil;
    }
    if(value ==nil || [value isKindOfClass:[NSNull class]])
    {
        return @"NULL";
    }
    
    if([pt isInt])
    {
        return [NSString stringWithFormat:@"%d",[value intValue]];
    }
    else if([pt isNumber]||[pt IsChar])
    {
        return [NSString stringWithFormat:@"%f",[value doubleValue]];
    }
    else if([pt isString])
    {
        if([value isKindOfClass:[NSDate class]]) //日期有可能保存为字串
        {
            return [NSString stringWithFormat:@"'%@'",[CommonUtil stringFromDate:(NSDate*)value]];
        }
        else if([value isKindOfClass:[NSNumber class]])
        {
            return [NSString stringWithFormat:@"%d",[(NSNumber *)value intValue]];
        }
        else
        {
            NSString *v1  = (NSString *)value;
            NSString * v2 = [v1 stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
//            v1 = [v1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            return [NSString stringWithFormat:@"'%@'",v2];
        }
    }
    else if([pt isNSData])
    {
        NSString * string = [[NSString alloc]initWithData:(NSData*)value encoding:NSUTF8StringEncoding];
        NSString * ret = [NSString stringWithFormat:@"'%@'",[string stringByReplacingOccurrencesOfString:@"'" withString:@"''" ]];
        PP_RELEASE(string);
        return ret;
    }
    else if([pt isArray])
    {
        NSString * string = [(NSArray *)value JSONRepresentationEx];
        return [NSString stringWithFormat:@"'%@'",string];
    }
    else if([pt isDictionary])
    {
        NSString * string = [(NSDictionary *)value JSONRepresentationEx];
        return [NSString stringWithFormat:@"'%@'",string];
    }
    else if([pt isEntity])
    {
        NSString * string = [(HCEntity *)value toJson];
        return [NSString stringWithFormat:@"'%@'",string];
    }
    return @"NULL";
}
+ (NSString *) fieldSetSyntax:(HCEPropertyType *)pt value:(id)value
{
    if(pt==nil || (![pt canSaveToData]))
    {
        NSLog(@"get field compare syntax error:field not exists or not saved in db table.");
        return nil;
    }
    if(value ==nil || [value isKindOfClass:[NSNull class]])
    {
        return [NSString stringWithFormat:@"%@ =NULL",[HCSQLHelper columNameCheck:pt.Name]];
    }
    
    if([pt isInt])
    {
        return [NSString stringWithFormat:@"%@=%d",[HCSQLHelper columNameCheck:pt.Name],[value intValue]];
    }
    else if([pt isNumber]||[pt IsChar])
    {
        return [NSString stringWithFormat:@"%@=%f",[HCSQLHelper columNameCheck:pt.Name],[value doubleValue]];
    }
    else if([pt isString])
    {
        if([value isKindOfClass:[NSDate class]]) //日期有可能保存为字串
        {
            return [NSString stringWithFormat:@"%@='%@'",[HCSQLHelper columNameCheck:pt.Name],[CommonUtil stringFromDate:(NSDate*)value]];
        }
        else
        {
            NSString * v1  = [(NSString *)value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
            return [NSString stringWithFormat:@"%@=\"%@\"",[HCSQLHelper columNameCheck:pt.Name],v1];
        }
    }
    else if([pt isNSData])
    {
        NSString * string = PP_AUTORELEASE([[NSString alloc]initWithData:(NSData*)value encoding:NSUTF8StringEncoding]);
        return [NSString stringWithFormat:@"%@='%@'",[HCSQLHelper columNameCheck:pt.Name],[string stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
    }
    else if([pt isArray])
    {
        NSString * string = [(NSArray *)value JSONRepresentationEx];
        return [NSString stringWithFormat:@"'%@'",string];
    }
    else if([pt isDictionary])
    {
        NSString * string = [(NSDictionary *)value JSONRepresentationEx];
        return [NSString stringWithFormat:@"'%@'",string];
    }
    else if([pt isEntity])
    {
        NSString * string = [(HCEntity *)value toJson];
        return [NSString stringWithFormat:@"'%@'",string];
    }

    return @"";
}
+ (NSString *) getTableSyntax:(HCEntity *)entity
{
    NSString *tableCreateSyntax = @"CREATE TABLE %@ (%@ );";
    NSMutableString *fieldSyntax = PP_AUTORELEASE([[NSMutableString alloc]init]);
    NSDictionary * propDic = PP_RETAIN([entity getPropTypes:[entity class]]);
    
    //得到词典中所有KEY值
    NSEnumerator * enumeratorKey = [propDic keyEnumerator];
    
    int keyCount = 0;
    NSMutableString * keySyntax = [NSMutableString new];
    for (NSString *keyName in enumeratorKey)
    {
        HCEPropertyType * pt = [propDic objectForKey:keyName];
        if(pt.canSaveToData)
        {
            BOOL isPrimary = [HCSQLHelper IsPrimary:pt.Name keyName:entity.KeyName];
            if(isPrimary)
            {
                keyCount ++;
                if(keySyntax.length>0) [keySyntax appendString:@","];
                [keySyntax appendString:pt.Name];
                
            }
        }
    }
    //快速枚举遍历所有KEY的值
    enumeratorKey = [propDic keyEnumerator];
    for (NSString *keyName in enumeratorKey)
    {
        HCEPropertyType * pt = [propDic objectForKey:keyName];
        if(pt.canSaveToData)
        {
            if(keyCount==1)
            {
                BOOL isPrimary = [HCSQLHelper IsPrimary:pt.Name keyName:entity.KeyName];
                [fieldSyntax appendString:[HCSQLHelper getFieldSyntax:pt isprimarykey:isPrimary]];
            }
            else
                [fieldSyntax appendString:[HCSQLHelper getFieldSyntax:pt isprimarykey:NO]];
            
            [fieldSyntax appendString:@","];
        }
    }
    if(keyCount>1)
    {
        [fieldSyntax appendFormat:@" primary key (%@) ,",keySyntax];
    }
    //去掉最后一个逗号
    if([fieldSyntax length]>0)
    {
        [fieldSyntax deleteCharactersInRange:NSMakeRange(fieldSyntax.length -1, 1)];
    }
    PP_RELEASE(propDic);
    PP_RELEASE(keySyntax);
    return [NSString stringWithFormat:tableCreateSyntax,entity.TableName,fieldSyntax];
}
+ (BOOL)IsPrimary:(NSString *)pName keyName:(NSString *)keyName
{
    if([pName compare:keyName options:NSCaseInsensitiveSearch]==NSOrderedSame)
        return YES;
    else
    {
        return [keyName isMatchedByRegex:[NSString stringWithFormat:@"\\s*%@(\\s*,\\s*)?",pName]];
//        NSArray * array = [keyName arrayOfCaptureComponentsMatchedByRegex:@""];
//        return NO;
    }
}
+ (NSString *) getSelectSyntax:(HCEntity *)entity where:(NSString*)where orderBy:(NSString*)orderBy pageSize:(int)pageSize pageIndex:(int)pageIndex
{
    NSString *tableSelectSyntax = @"SELECT * FROM %@ WHERE (%@ ) ORDER BY %@ LIMIT %d,%d ;";
   
    return [NSString stringWithFormat:tableSelectSyntax,entity.TableName,where,orderBy,(pageIndex * pageSize),pageSize];
}
+ (NSString *) getSelectSyntax:(HCEntity *)entity where:(NSString*)where orderBy:(NSString*)orderBy
{
    NSString *tableSelectSyntax = @"SELECT * FROM %@ WHERE (%@ ) ORDER BY %@";
    
    return [NSString stringWithFormat:tableSelectSyntax,entity.TableName,where,orderBy];
}
+ (NSString *) getDeleteSyntax:(HCEntity *)entity
{
    NSString *tableDeleteSyntax = @"DELETE  FROM %@ WHERE %@;";
//    NSMutableDictionary * dic = [entity getPropTypes:[entity class]];
//    HCEPropertyType * pt = (HCEPropertyType *)[dic objectForKey:entity.KeyName];
//    if(pt==nil)
//    {
//        NSLog(@"get delete syntax error:%@ field not exists.",entity.KeyName);
//    }
//    id value = [entity objectForKey:pt.Name];
    return [NSString stringWithFormat:tableDeleteSyntax,
            entity.TableName,
            [HCSQLHelper getKeyCompareSyntax:entity]];
//            [HCSQLHelper fieldCompareSyntax:pt value:value]];

}
+ (NSString *)getKeyCompareSyntax:(HCEntity *)entity
{

    NSMutableString * result = [[NSMutableString alloc]init];
    [result appendString:@"("];
    @autoreleasepool {
        NSMutableDictionary * dic = [entity getPropTypes:[entity class]];
        NSCharacterSet * chars = [NSCharacterSet characterSetWithCharactersInString:@","];
        NSRange range1 = [entity.KeyName rangeOfCharacterFromSet:chars];
        int orgPos = 0;
        int length = 0;
        if(range1.length>0) //有多个值时
        {
//            NSArray * list = [entity.KeyName ar:<#(NSString *)#> ];
//            [keyName isMatchedByRegex:[NSString stringWithFormat:@"\\s*%@(\\s*,\\s*)?",pName]]

            while (range1.length>0) {
                length = (int)range1.location - orgPos ;
                
                NSString * keyName = [entity.KeyName substringWithRange:NSMakeRange(orgPos, length)];
                HCEPropertyType * pt = (HCEPropertyType *)[dic objectForKey:keyName];
                if(pt==nil)
                {
                    NSLog(@"get delete syntax error:%@ field not exists.",keyName);
                }
                if(result.length>2)
                {
                    [result appendString:@" AND "];
                }
                id value = [entity objectForKey:pt.Name];
                [result appendString:[HCSQLHelper fieldCompareSyntax:pt value:value]];
                
                if(range1.location+1 < entity.KeyName.length)
                {
                    orgPos = (int)range1.location +1;
                    range1 = [entity.KeyName rangeOfCharacterFromSet:chars
                                                             options:0
                                                               range:NSMakeRange(orgPos,
                                                                                 entity.KeyName.length - orgPos)];
                    if(range1.length==0)
                    {
                        range1.location = entity.KeyName.length;
                        range1.length = 1;
                    }
                }
                else
                    break;
            }
        }
        else
        {
            HCEPropertyType * pt = (HCEPropertyType *)[dic objectForKey:entity.KeyName];
            if(pt==nil)
            {
                NSLog(@"get delete syntax error:%@ field not exists.",entity.KeyName);
            }
            id value = [entity objectForKey:pt.Name];
            [result appendString:[HCSQLHelper fieldCompareSyntax:pt value:value]];
        }
    }
    
    [result appendString:@")"];
    
    return PP_AUTORELEASE(result);
}
+ (NSString *) getDeleteSyntax:(HCEntity *)entity where:(NSString *)whereString
{
    NSString *tableDeleteSyntax = @"DELETE  FROM %@ WHERE (%@);";
    
    return [NSString stringWithFormat:tableDeleteSyntax,entity.TableName,whereString];
}
+ (NSString *) getInsertSyntax:(HCEntity *)entity
{
    NSString *tableInsertSyntax = @"INSERT INTO %@ (%@) VALUES (%@);";
    NSMutableDictionary * propDic = [entity getPropTypes:[entity class]];
    //得到词典中所有KEY值
    NSEnumerator * enumeratorKey = [propDic keyEnumerator];
    NSMutableString * fieldList = PP_AUTORELEASE([[NSMutableString alloc]init]);
    NSMutableString * valueList = PP_AUTORELEASE([[NSMutableString alloc]init]);
    //快速枚举遍历所有KEY的值
    for (NSString *keyName in enumeratorKey)
    {
        HCEPropertyType * pt = [propDic objectForKey:keyName];
        if(pt.canSaveToData)
        {
            [fieldList appendString:[HCSQLHelper columNameCheck:pt.Name]];
            [fieldList appendString:@","];
            [valueList appendString:[HCSQLHelper fieldValueString:pt value:[entity objectForKey:pt.Name]]];
            [valueList appendString:@","];
            
        }
    }
    //去掉最后一个逗号
    if([fieldList length]>0)
    {
        [fieldList deleteCharactersInRange:NSMakeRange(fieldList.length -1, 1)];
    }
    if([valueList length]>0)
    {
        [valueList deleteCharactersInRange:NSMakeRange(valueList.length -1, 1)];
    }

//    [propDic release];
    return [NSString stringWithFormat:tableInsertSyntax,entity.TableName,fieldList,valueList];
}
+ (NSString *) getInsertSyntaxForPrepare:(HCEntity *)entity propDic:(NSMutableDictionary*)propDic
{
    NSString *tableInsertSyntax = @"INSERT INTO %@ (%@) VALUES (%@);";
    if(!propDic)
        propDic = [entity getPropTypes:[entity class]];
    //得到词典中所有KEY值
    NSEnumerator * enumeratorKey = [propDic keyEnumerator];
    NSMutableString * fieldList = PP_AUTORELEASE([[NSMutableString alloc]init]);
    NSMutableString * valueList = PP_AUTORELEASE([[NSMutableString alloc]init]);
    //快速枚举遍历所有KEY的值
    for (NSString *keyName in enumeratorKey)
    {
        HCEPropertyType * pt = [propDic objectForKey:keyName];
        if(pt.canSaveToData)
        {
            [fieldList appendString:[HCSQLHelper columNameCheck:pt.Name]];
            [fieldList appendString:@","];
            //[valueList appendString:[HCSQLHelper fieldValueString:pt value:[entity objectForKey:pt.Name]]];
            [valueList appendString:@"?,"];
            
        }
    }
    //去掉最后一个逗号
    if([fieldList length]>0)
    {
        [fieldList deleteCharactersInRange:NSMakeRange(fieldList.length -1, 1)];
    }
    if([valueList length]>0)
    {
        [valueList deleteCharactersInRange:NSMakeRange(valueList.length -1, 1)];
    }
    
    //    [propDic release];
    return [NSString stringWithFormat:tableInsertSyntax,entity.TableName,fieldList,valueList];
}
+(BOOL) bindStatement:(sqlite3_stmt * )statement entity:(HCEntity * )entity propDic:(NSMutableDictionary *)propDic
{
    if(!propDic)
       propDic = [entity getPropTypes:[entity class]];

    //得到词典中所有KEY值
    NSEnumerator * enumeratorKey = [propDic keyEnumerator];
 
    //快速枚举遍历所有KEY的值
    int i = 1;
    for (NSString *keyName in enumeratorKey)
    {
        HCEPropertyType * pt = [propDic objectForKey:keyName];
        if(pt.canSaveToData)
        {
            id value = [entity objectForKey:pt.Name];
            if(value ==nil || [value isKindOfClass:[NSNull class]])
            {
                sqlite3_bind_null(statement, i);
            }
            else if([pt isInt])
            {
                sqlite3_bind_int(statement,i,[value intValue]);
            }
            else if([pt isNumber]||[pt IsChar])
            {
                sqlite3_bind_double(statement,i, [value doubleValue]);
            }
            else if([pt isString])
            {
                if([value isKindOfClass:[NSDate class]]) //日期有可能保存为字串
                {
                    const char * v =[[CommonUtil stringFromDate:(NSDate*)value] cStringUsingEncoding:NSUTF8StringEncoding];
                    sqlite3_bind_text(statement,i,v,-1,NULL);
                }
                else if([value isKindOfClass:[NSNumber class]])
                {
                    const char * v =[[NSString stringWithFormat:@"%d",[(NSNumber *)value intValue]] cStringUsingEncoding:NSUTF8StringEncoding];
                    sqlite3_bind_text(statement,i,v,-1,NULL);
                }
                else
                {
                    NSString *v1  = (NSString *)value;
                     const char *  v2 = [[v1 stringByReplacingOccurrencesOfString:@"'" withString:@"''"]cStringUsingEncoding:NSUTF8StringEncoding];
                    //            v1 = [v1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
                    sqlite3_bind_text(statement,i,v2,-1,NULL);
                }
            }
            else if([pt isNSData])
            {
                sqlite3_bind_blob(statement,i,(__bridge const void *)((NSData *)value),-1,NULL);
            }
            else if([pt isArray])
            {
                const char * string = [[(NSArray *)value JSONRepresentationEx]cStringUsingEncoding:NSUTF8StringEncoding];
                sqlite3_bind_text(statement, i, string, -1, NULL);
            }
            else if([pt isDictionary])
            {
                
                const char * string = [[(NSDictionary *)value JSONRepresentationEx]cStringUsingEncoding:NSUTF8StringEncoding];
                sqlite3_bind_text(statement, i, string, -1, NULL);
              
            }
            else if([pt isEntity])
            {
                const char * string = [[(HCEntity *)value toJson]cStringUsingEncoding:NSUTF8StringEncoding];
                sqlite3_bind_text(statement, i, string, -1, NULL);
            }

            i ++;
        }
    }
    return YES;
}
+(NSMutableArray*) bindStateValueArray:(HCEntity * )entity propDic:(NSMutableDictionary *)propDic
{
    if(!propDic)
        propDic = [entity getPropTypes:[entity class]];
    
    //得到词典中所有KEY值
    NSEnumerator * enumeratorKey = [propDic keyEnumerator];
    NSMutableArray * result = [NSMutableArray new];
    //快速枚举遍历所有KEY的值
    int i = 1;
    for (NSString *keyName in enumeratorKey)
    {
        HCEPropertyType * pt = [propDic objectForKey:keyName];
        if(pt.canSaveToData)
        {
            id value = [entity objectForKey:pt.Name];
            if(value ==nil || [value isKindOfClass:[NSNull class]])
            {
                [result addObject:[NSNull null]];
            }
            else if([pt isInt])
            {
                [result addObject:[NSNumber numberWithInt:[value intValue]]];
            }
            else if([pt isNumber]||[pt IsChar])
            {
                 [result addObject:[NSNumber numberWithInt:[value doubleValue]]];
            }
            else if([pt isString])
            {
                if([value isKindOfClass:[NSDate class]]) //日期有可能保存为字串
                {
                    [result addObject:[CommonUtil stringFromDate:(NSDate*)value]];
                }
                else if([value isKindOfClass:[NSNumber class]])
                {
                    [result addObject:[NSString stringWithFormat:@"%d",[(NSNumber *)value intValue]]];
                }
                else
                {
                     NSString *v1  = (NSString *)value;
                    [result addObject:[v1 stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
                   
                }
            }
            else if([pt isNSData])
            {
                [result addObject:(NSData *)value];
            }
            else if([pt isArray])
            {
                NSString * string = [(NSArray *)value JSONRepresentationEx];
                [result addObject:string];
            }
            else if([pt isDictionary])
            {
                
                NSString * string  = [(NSDictionary *)value JSONRepresentationEx];
                [result addObject:string];
            }
            else if([pt isEntity])
            {
                NSString * string = [(HCEntity *)value toJson];
                [result addObject:string];
            }
            else
            {
                [result addObject:[NSNull null]];
            }
            i ++;
        }
    }
    return PP_AUTORELEASE(result);
}
+ (NSString *) getUpateSyntax:(HCEntity *)newEntity orgData:(HCEntity *)orgEntity
{
    NSString *tableUpdateSyntax = @"UPDATE %@ SET %@ WHERE %@;";
    NSMutableDictionary * propDic = [newEntity getPropTypes:[newEntity class]];
    //得到词典中所有KEY值
    NSEnumerator * enumeratorKey = [propDic keyEnumerator];
    NSMutableString * setList = PP_AUTORELEASE([[NSMutableString alloc]init]);
    NSMutableString * whereList = PP_AUTORELEASE([[NSMutableString alloc]init]);
    //快速枚举遍历所有KEY的值
    for (NSString *keyName in enumeratorKey)
    {
        HCEPropertyType * pt = [propDic objectForKey:keyName];
        if(pt.canSaveToData)
        {
//            BOOL isPrimary = ([pt.Name compare:orgEntity.KeyName options:NSCaseInsensitiveSearch]==NSOrderedSame);
//            if(isPrimary) {
//                [whereList appendString:[HCSQLHelper fieldCompareSyntax:pt value:[orgEntity objectForKey:pt.Name]]];
//                [whereList appendString:@" AND"];
//            }
            
            [setList appendString:[HCSQLHelper fieldSetSyntax:pt value:[newEntity objectForKey:pt.Name]]];
            [setList appendString:@","];
            
        }
    }
    [whereList appendString:[HCSQLHelper getKeyCompareSyntax:orgEntity]];
    //去掉最后一个逗号
    if([setList length]>0)
    {
        [setList deleteCharactersInRange:NSMakeRange(setList.length -1, 1)];
    }
    if([whereList length]>4)
    {
        [whereList deleteCharactersInRange:NSMakeRange(whereList.length -4, 4)];
    }
    
//    [propDic release];
    return [NSString stringWithFormat:tableUpdateSyntax,newEntity.TableName,setList,whereList];
}
+ (NSString *) getExistsSyntax:(HCEntity *)entity
{
    NSString *tableSelectSyntax = @"SELECT count(*) FROM %@ WHERE %@;";
//    NSMutableDictionary * dic = [entity getPropTypes:[entity class]];
//    HCEPropertyType * pt = (HCEPropertyType *)[dic objectForKey:entity.KeyName];
//    if(pt==nil)
//    {
//        NSLog(@"get delete syntax error:%@ field not exists.",entity.KeyName);
//    }
    return [NSString stringWithFormat:tableSelectSyntax,entity.TableName,
            [HCSQLHelper getKeyCompareSyntax:entity]];
//            [HCSQLHelper fieldCompareSyntax:pt value:[entity objectForKey:pt.Name]]];

}
+ (NSString *) getCountSyntax:(NSString*)tableName
{
    NSString *tableSelectSyntax = @"SELECT count(*) FROM %@;";
    return [NSString stringWithFormat:tableSelectSyntax,tableName];
}
+ (NSString *)getArraySyntax:(NSString*)itemString
{
    if(!itemString) return nil;
    NSArray * array = [itemString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", ，"]];
    NSMutableString * ret0 = [[NSMutableString alloc]init];
    for (NSString * str in array){
        [ret0 appendFormat:@"\"%@\",",str];
    }
    NSString * ret2 = nil;
    if(ret0.length>0)
    {
        ret2 = [ret0 substringToIndex:ret0.length-1];
    }
    PP_RELEASE(ret0);
    return ret2 ;
}
+(NSString *)getUpdateSqlFromDictionary:(HCEntity *)entity datas:(NSDictionary *)data
{
    NSString *tableUpdateSyntax = @"UPDATE %@ SET %@ WHERE %@;";
    
    NSMutableDictionary * propDic = [entity getPropTypes:[entity class]];
    
    //得到词典中所有KEY值
    NSEnumerator * enumeratorKey = [data keyEnumerator];
    NSMutableString * setList = PP_AUTORELEASE([[NSMutableString alloc]init]);
    NSMutableString * whereList = PP_AUTORELEASE([[NSMutableString alloc]init]);
    //快速枚举遍历所有KEY的值
    for (NSString *keyName in enumeratorKey)
    {
        HCEPropertyType * pt = [propDic objectForKey:keyName];
        if(pt && pt.canSaveToData)
        {
            [setList appendString:[HCSQLHelper fieldSetSyntax:pt value:[data objectForKey:keyName]]];
            [setList appendString:@","];
            
        }
    }
    if(setList.length==0) return nil;
    
    [whereList appendString:[HCSQLHelper getKeyCompareSyntax:entity]];
    //去掉最后一个逗号
    if([setList length]>0)
    {
        [setList deleteCharactersInRange:NSMakeRange(setList.length -1, 1)];
    }
    if([whereList length]>4)
    {
        [whereList deleteCharactersInRange:NSMakeRange(whereList.length -4, 4)];
    }
    
    //    [propDic release];
    return [NSString stringWithFormat:tableUpdateSyntax,entity.TableName,setList,whereList];
}

@end

//
//  HCCacheItem.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-28.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "HCCacheItem.h"
#import "JSON.h"
@implementation HCCacheItem
@synthesize CMDID;
@synthesize SCode;
@synthesize Args;
@synthesize CacheKey;
@synthesize DataMD5;
@synthesize LastUpdateTime;
@synthesize ExpireTime;

-(id)init{
    self = [super init];
    if(self)
    {
        self.TableName = @"cacheitems";
        self.KeyName = @"CacheKey";
    }
    return self;
}
-(void)dealloc
{
    PP_RELEASE(SCode);
    PP_RELEASE(Args);
    PP_RELEASE(CacheKey);
    PP_RELEASE(DataMD5);
    PP_RELEASE(LastUpdateTime);
    PP_RELEASE(ExpireTime);
    
    PP_SUPERDEALLOC;
//    [super dealloc];
}
#pragma encodeWithCode decodeWithCoder
- (void)encodeWithCoder:(NSCoder*)coder
{
    //[super encodeWithCoder:coder];
    //如果是子类，应该加上：
    //[super encodeWithCoder:aCoder];
    //注意这里如何处理对象的（其实是实现了NSCoding的类）！
    [coder encodeInt:self.CMDID forKey: @"cmdid"];
    [coder encodeObject:self.SCode forKey:@"scode"];
    [coder encodeObject:self.Args forKey:@"args"];
    [coder encodeObject:self.CacheKey forKey:@"cachekey"];
    [coder encodeObject:self.DataMD5 forKey:@"datamd5"];
    [coder encodeObject:self.LastUpdateTime forKey:@"lastupdatetime"];
    [coder encodeObject:self.ExpireTime forKey:@"expiretime"];
}
- (id)initWithCoder:(NSCoder*)decoder
{
    //解码对象
    self.CMDID = [decoder decodeIntForKey:@"cmdid"];
    self.SCode = [decoder decodeObjectForKey:@"scode"];
    self.Args = [decoder decodeObjectForKey:@"args"];
    self.CacheKey = [decoder decodeObjectForKey:@"cachekey"];
    self.DataMD5 = [decoder decodeObjectForKey:@"datamd5"];
    self.LastUpdateTime = [decoder decodeObjectForKey:@"lastupdatetime"];
    self.ExpireTime = [decoder decodeObjectForKey:@"expiretime"];
    
    return self;
}
- (id) copyWithZone:(NSZone *)zone
{
    HCCacheItem *newObj = [[[self class] allocWithZone:zone] init];
    newObj.CMDID = self.CMDID;
    newObj.SCode = PP_AUTORELEASE([self.SCode copyWithZone:zone]);
    newObj.CacheKey = PP_AUTORELEASE([self.CacheKey copyWithZone:zone]);
    newObj.Args = PP_AUTORELEASE([self.Args copyWithZone:zone]);
    newObj.DataMD5 = PP_AUTORELEASE([self.DataMD5 copyWithZone:zone]);
    newObj.LastUpdateTime = PP_AUTORELEASE([self.LastUpdateTime copyWithZone:zone]);
    newObj.ExpireTime = PP_AUTORELEASE([self.ExpireTime copyWithZone:zone]);
    
    return newObj;
}
-(NSString *)JSONRepresentationEx
{
    NSMutableDictionary * dic = [[NSMutableDictionary alloc]init];
    [dic setObject:[NSNumber numberWithInt:self.CMDID] forKey:@"CMDID"];
    [dic setObject:self.SCode forKey:@"SCode"];
    [dic setObject:self.CacheKey forKey:@"CacheKey"];
    [dic setObject:self.Args forKey:@"Args"];
    [dic setObject:self.DataMD5 forKey:@"DataMD5"];
    [dic setObject:self.LastUpdateTime forKey:@"LastUpdateTime"];
    [dic setObject:self.ExpireTime forKey:@"ExpireTime"];
    NSString * s = [dic JSONRepresentationEx];
    PP_RELEASE(dic);
    return s;
}
@end

//
//  HCCacheItem.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-28.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "NSEntity.h"
#import "HCBase.h"
@interface HCCacheItem : HCEntity
@property (assign) int CMDID;  //命令ID
@property (PP_STRONG) NSString * SCode;  //后台命令代码，如1.0.1等
@property (PP_STRONG) NSString * Args; //参数列表
@property (PP_STRONG) NSString * CacheKey; //缓存的KEy
@property (PP_STRONG) NSString * DataMD5; //数据的{data:...}部分的MD5值
@property (PP_STRONG) NSString * LastUpdateTime;
@property (PP_STRONG) NSString * ExpireTime;
@end

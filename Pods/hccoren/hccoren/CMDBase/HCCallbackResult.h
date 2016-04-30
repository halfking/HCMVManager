//
//  HCCallbackResult.h
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-5.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "NSEntity.h"
#import "HCBase.h"
@interface HCCallbackResult : HCEntity
@property (nonatomic,assign) int Code; //0 正常 1 网络失败 2 超时4 数据没有变化
@property (nonatomic,assign) int aCode;
#ifndef __OPTIMIZE__
@property (nonatomic,PP_STRONG) NSString * ABrequestString;
#endif
@property (nonatomic,PP_STRONG) NSString * Msg;
@property (nonatomic,PP_STRONG) HCEntity * Data;
@property (nonatomic,PP_STRONG) HCEntity * SecondsItem;
@property (nonatomic,PP_STRONG) NSArray * List;
@property (nonatomic,PP_STRONG) NSDictionary * Args;
@property (nonatomic,PP_STRONG) NSDictionary * DicNotParsed;
@property (nonatomic,PP_STRONG) NSString * ArgsHash;
@property (nonatomic,PP_STRONG) NSString * ResultHash;
@property (nonatomic,assign) BOOL IsFromDB;
- (id) initWithArgs:(NSDictionary*)args response:(NSDictionary*)dic;
@property(nonatomic,PP_STRONG) NSDictionary* resultDic;
@property (nonatomic,assign) int TotalCount;
@property (nonatomic,assign) int TotalDetailCount;
@property (nonatomic,assign) int feedbackID;
@end

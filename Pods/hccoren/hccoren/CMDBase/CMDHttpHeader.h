//
//  CMDHttpHeader.h
//  RBNews
//
//  Created by XUTAO HUANG on 13-5-14.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "PublicValues.h"
#import "DeviceConfig.h"
#import <CommonCrypto/CommonDigest.h>
//#import "ResponseEntity.h"
#import "NSDataGZipAdditions.h"
#import "JSON.h"
#import "HCBase.h"
#import "HCCallbackResult.h"
#import "CMDOP.h"
#import "CMDHeader.h"

#define REQUEST_POST 1
@class CMDOP;

//请求的命令头部
//os	string	客户端操作系统(01,ios,02,android)
//deviceID	string	设备唯一识别码
//timestamp	string	时间戳
//version	string	软件版本
//encryptionKey	string	Md5加密字符串(os#密钥 #deviceID#timestamp)进行md5
@interface CMDHttpHeader : CMDHeader
{
    int encryptMethod_;
    int protocolVersion_;
    
    NSDictionary * argsDic_;
#if REQUEST_POST
    NSMutableDictionary * postContents_;
#endif
}
- (id)          initWithString:(NSString *)responseString;
- (NSString *)  toString:(CMDOP*)cmd includeUDI:(BOOL)includeUDI;
- (NSDictionary *)Args;
#if REQUEST_POST
- (NSMutableDictionary *)postContents;
#endif

@end

//
//  CMDSocketHeader.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-9-21.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "PublicValues.h"
#import "DeviceConfig.h"
//#import <CommonCrypto/CommonDigest.h>
//#import "ResponseEntity.h"
#import "NSDataGZipAdditions.h"
#import "JSON.h"
#import "CMDHeader.h"

@class CMDOP;
//返回参数头部
//EncryptMethod	1	Uint8
//协议版本序号	2	Uint8
//命令号	4	Uint8
//MessageId	16	Uint8
//Code	1	Uint8
//SecretCode	8	Byte
//Body_SIZE	8	Uint8
@interface CMDSocketHeader : CMDHeader
{
    int encryptMethod_;
    int protocolVersion_;
}
- (id)      initWithString:(NSString *)responseString;
- (NSString *) toString:(CMDOP*)cmd includeUDI:(BOOL)includeUDI;
//- (void)        setArgs:(NSString *)Args;
@end

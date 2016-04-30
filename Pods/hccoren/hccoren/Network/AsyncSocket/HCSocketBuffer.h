//
//  HCSocketBuffer.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-7.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "PublicValues.h"
//SOcket的包头长度，及标志内容长度的字段字节
#define SOCKETHEADLEN       32   //不含Body长度数据的包头大小,返回的包没有UDI
#define SENDSOCKETLEN       31   //不含UDI长度
#define INCLUDEUDI          1
#define SOCKETPACKAGELEN    8

#define BUFFER_LENGTH 300*1024
enum{
    HCBufferStatusNeedRead = 0,
    HCBufferStatusReadOK =1,
    HCBufferStatusError =2
};
typedef u_int16_t HCBufferStatus;

@interface HCSocketBuffer : NSObject
{
#if USEBINARYDATA
    Byte _byteBuffer[BUFFER_LENGTH];
#else
    NSMutableData * _dataBuffer ;
#endif
    int _curPos;
    int _endPos;
    int _dataLength;
}
- (int) length;
#if USEBINARYDATA
- (void)appendBytes:(Byte *)data length:(uint)length;
- (void)readBytes:(Byte*)data length:(uint)length;
#endif
- (void)appendData:(NSData *)data;
- (HCBufferStatus)getNextPackage:(NSMutableData *)packageData;
//- (HCBufferStatus)getNextPackageBytes:(Byte *)packageData length:(int *)packageLen;
- (void)clearData;
- (void)decompressData:(NSData*)data plen:(int)plen result:(NSMutableData *)result;
- (void)compressData:(NSData*)data result:(NSMutableData * )result;
@end

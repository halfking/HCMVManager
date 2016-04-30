//
//  HCSocketBuffer.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-11-7.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "HCSocketBuffer.h"
#import "HCBase.h"
#import "NSDataGZipAdditions.h"
//#import "SystemConfiguration.h"
#define AR_SIZE( a ) sizeof( a ) / sizeof( a[0] )

@implementation HCSocketBuffer
- (id)init
{
    self = [super init];
    if(self)
    {
#if USEBINARYDATA
        memset(_byteBuffer,'\0',BUFFER_LENGTH);
#else
        _dataBuffer = [[NSMutableData alloc]init];
#endif
        //_byteBuffer[0]='\0';
        
        _curPos = 0;
        _endPos = 0;
        _dataLength = 0;
    }
    return self;
}
- (int) length
{
    return _dataLength;
}
#if USEBINARYDATA
- (void)calculateLength
{
    if(_endPos >= _curPos)
        _dataLength = _endPos - _curPos;
    else
        _dataLength = _endPos +BUFFER_LENGTH - _curPos;
}
- (void)readBytes:(Byte*)data length:(uint)length
{
    //环状队列
    int pharse1 = BUFFER_LENGTH - (_curPos + length);
    int pharse2 = 0;
    if(pharse1>= 0)
    {
        pharse1 = length;
        pharse2 = 0;
    }
    else
    {
        pharse1 = BUFFER_LENGTH - _curPos;
        pharse2 = _curPos + length - BUFFER_LENGTH;
    }
    
    memcpy(data,((void*) _byteBuffer) + _curPos, pharse1);
    _curPos += pharse1;
    if(pharse2 >0)
    {
        memcpy(((void*)data)+pharse1,((void*) _byteBuffer), pharse2);
        _curPos = pharse2;
    }
    [self calculateLength];
    
}
- (void)appendBytes:(Byte *)data length:(uint)length
{
    //环状队列
    int pharse1 = BUFFER_LENGTH - (_endPos + length);
    int pharse2 = 0;
    if(pharse1>= 0)
    {
        pharse1 = length;
        pharse2 = 0;
    }
    else
    {
        pharse1 = BUFFER_LENGTH - _endPos;
        pharse2 = _endPos + length - BUFFER_LENGTH;
    }
    
    memcpy(((void*) _byteBuffer) + _endPos, data, pharse1);
    _endPos += pharse1;
    if(pharse2 >0)
    {
        memcpy(((void*) _byteBuffer),((void*)data)+pharse1, pharse2);
        _endPos = pharse2;
    }
    [self calculateLength];

//    NSString * bufferString = [[NSString alloc]initWithBytes:_byteBuffer length:_dataLength encoding:NSUTF8StringEncoding];
//    NSLog(@" message:%@",bufferString);
//    [bufferString release];
}
#endif
- (void)appendData:(NSData *)data
{
#if USEBINARYDATA
    Byte bytes[data.length];
    [data getBytes:bytes length:data.length];
    [self appendBytes:bytes length:(int)data.length];
#else
    [_dataBuffer appendData:data];
    _dataLength = [_dataBuffer length];
#endif
}
- (void)clearData
{
    _curPos = 0;
    _dataLength = 0;
    _endPos =0;
#if USEBINARYDATA
    memset(_byteBuffer,'\0',BUFFER_LENGTH);
#else
    [_dataBuffer setData:nil];
#endif
}
#if USEBINARYDATA
- (HCBufferStatus)getNextPackage:(NSMutableData *)packageData
{
    if(!packageData) return HCBufferStatusNeedRead;
    //处理沾包的情况，多个包一次性发过来
    if(4  < _dataLength)
    {
        int plen = 0;
        int endPos = _curPos;
//        Byte * curBytes = nil;
        
        plen = _byteBuffer[_curPos] * (256*256*256)
                        + _byteBuffer[_curPos+1] *(256*256)
                        + _byteBuffer[_curPos+2] * 256
                        + _byteBuffer[_curPos+3];

//        curBytes = _byteBuffer + _curPos;
        
        int subLen = plen +4;
        endPos += subLen;
        if(subLen > _dataLength)
        {
            return HCBufferStatusNeedRead;
        }
        else if(endPos < _curPos || subLen >= BUFFER_LENGTH)
        {
            NSLog(@"bound error,plen:%i,endpos:%i",plen,endPos);
            [self clearData];
            return HCBufferStatusNeedRead;
        }
        //如果服务返回的字节数有问题，有可能需要注意如何处理
        //这个包处理完成后，有可能剩下一些字节是有问题的，如果小于一个包头，则略去
        
        //如果剩下的字节不足4个，则不认为是粘包，则一次性取出所有数据
        if(subLen + 4 > _dataLength)
            subLen = _dataLength;// - _curPos;

        if(subLen>4)
        {
            Byte *bytes= malloc(subLen);
            [self readBytes:bytes length:subLen];
            NSData * curData = [NSData dataWithBytesNoCopy:bytes length:subLen freeWhenDone:YES];
            NSData * newData = [NSData dataWithCompressedData:[curData subdataWithRange:NSMakeRange(4,subLen-4)]];
//            NSData * dd = [NSData dataWithData:newData];
            [packageData appendData:newData];
            
        }

        //如果解码错误，则重新获取数据
        if(packageData.length==0)
        {
            [self clearData];
            NSLog(@"get socket buffer error.");
            return HCBufferStatusNeedRead;
        }
        if(4 >=_dataLength)
        {
            [self clearData];
        }
        else
        {
//            Byte * ccBytes = _byteBuffer + _curPos;
//            ccBytes = nil;
//            Byte bytes[_dataLength];
//            
//            memcpy(bytes, _byteBuffer + _curPos, _dataLength);
//            
//            memset(bytes, 0, _dataLength);
        }
#ifdef TRACKPAGES
        [[SystemConfiguration sharedSystemConfiguration] addBytes:packageData.length compressBytes:subLen];
#endif
        return HCBufferStatusReadOK;
    }
    return HCBufferStatusNeedRead;
}

-(void)decompressData:(NSData*)data plen:(int)plen result:(NSMutableData *)result
{
    //解压
    //判断是否加密或压缩，取第一个字节处理
    if(plen <=0)
    {
        Byte  bytes[4];// = [[data subdataWithRange:NSMakeRange(0, 4)] bytes];
        [data getBytes:bytes length:4];
        
        plen = bytes[0] * (256*256*256)
            + bytes[1] *(256*256)
            + bytes[2] * 256
            +bytes[3];

    }
    NSData * cpData = nil;
    if(plen > data.length -4)
        cpData = [data subdataWithRange:NSMakeRange(4, data.length -4)];
    else
        cpData = [data subdataWithRange:NSMakeRange(4, plen)];
    
    NSData * ncpData = [NSData dataWithCompressedData:cpData];
    if(ncpData.length==0)
    {
//        Byte nBytes[data.length];
//        Byte wBytes[_dataBuffer.length];
//        [data getBytes:nBytes length:data.length];
//        [_dataBuffer getBytes:wBytes length:_dataBuffer.length];
//        memset(nBytes, 0, data.length);
//        memset(wBytes, 0, _dataBuffer.length);
    }
    [result appendData:ncpData];
    
}
- (void)compressData:(NSData*)data result:(NSMutableData * )result
{
//    NSData * cmdData = [data subdataWithRange:NSMakeRange(3, 4)];
    NSData * cpData = [NSData compressedDataWithData:data];
//    NSString * string = [NSString stringWithFormat:@"%X",cpData.length];
    uint len = (uint)cpData.length;
//    NSNumber * intNumber = [NSNumber numberWithInt:cpData.length];
    Byte bytes[4];
    if(len > (256*256*256))
        bytes[0] = (len/(256*256*256))%256;
    else
        bytes[0] = 0;
    if(len > (256*256))
        bytes[1] = (len/(256*256))%256;
    else
        bytes[1] = 0;
    
    bytes[2] = (len/256)%256;
    bytes[3] = len%256;
    
//    
//    Byte cmdID[4];
//    int cmd = [[[[NSString alloc]initWithData:cmdData encoding:NSUTF8StringEncoding]autorelease]intValue];
//    
//    if(cmd > (256*256*256))
//        cmdID[0] = (len/(256*256*256))%256;
//    else
//        cmdID[0] = 0;
//    if(cmd > (256*256))
//        cmdID[1] = (len/(256*256))%256;
//    else
//        cmdID[1] = 0;
//    
//    cmdID[2] = (cmd/256)%256;
//    cmdID[3] = cmd%256;

//    NSMutableString * lenString = [[NSMutableString alloc]init];
//    int i= 4 * 2 - string.length;
//    for (;i>=0;i--)
//    {
//        [lenString appendString:@"0"];
//    }
//    [lenString appendString:string];
//    [result appendBytes:nil length:4];
//    [result appendData:[lenString dataUsingEncoding:NSUTF8StringEncoding]];
//    [result appendBytes:cmdID length:4];
    [result appendBytes:bytes length:4];
    [result appendData:cpData];
//    [lenString release];
//    NSData * data1 = [[NSData alloc]initWithData:result];
//    NSString * s = [[NSString alloc]initWithData:data1 encoding:NSUTF8StringEncoding];
//    NSLog(@"log:%@", s);
//    [s release];
//    [data1 release];
//    NSData * cData = [[NSData alloc]initWithData:result];
//    NSMutableData * newData = [[NSMutableData alloc]initWithCapacity:1000];
//    [self decompressData:cData plen:0 result:newData];
//    NSData * nData = [[NSData alloc]initWithData:newData];
//    [newData release];
//    [cData release];
//    [nData release];
}
#else
- (HCBufferStatus)getNextPackage:(NSMutableData *)packageData
{
    if(!packageData) return HCBufferStatusNeedRead;
    //处理沾包的情况，多个包一次性发过来
    if(_curPos + SOCKETHEADLEN + SOCKETPACKAGELEN  < _dataLength)
    {
        
//        NSString* aStr1 = [[NSString alloc] initWithData:_dataBuffer encoding:NSUTF8StringEncoding];
        
        //NSLog(@"-----Have received data is :%@",aStr1);
//        [aStr1 release];
        NSString * pageckagelen = nil;
        int plen = 0;
        int startPos = _curPos + SOCKETHEADLEN;
        @try {
            pageckagelen = [[NSString alloc]initWithData:
                            [_dataBuffer subdataWithRange:
                             NSMakeRange(startPos  , SOCKETPACKAGELEN)]
                                                encoding:NSUTF8StringEncoding];
            plen = [pageckagelen integerValue];
            startPos += SOCKETPACKAGELEN + plen;
        }
        @catch (NSException *exception) {
            plen = 0;
            NSLog(@"parse socket package error:cannot find package len:%@",pageckagelen);
            return HCBufferStatusError;
        }
        @finally {
            PP_RELEASE(pageckagelen);
//            [pageckagelen release];
        }
        //        if(plen==2605)
        //        {
        //            DLog(@"log 2605");
        //        }
        if(startPos > _dataLength)
        {
            return HCBufferStatusNeedRead;
        }
        if(startPos > [_dataBuffer length])
        {
            NSLog(@"bound error:%i>%i",startPos,[_dataBuffer length]);
        }
        //001013000000020027E90A80c8d6323900000062  40
        //{"data":{},"totalcount":0,"msg":"  33
        //鏈幏鍙栧埌閰掑簵","code":1}   29
        
        //如果服务返回的字节数有问题，有可能需要注意如何处理
        //这个包处理完成后，有可能剩下一些字节是有问题的，如果小于一个包头，则略去
        int subLen = startPos - _curPos;
        if(startPos + SOCKETHEADLEN +SOCKETPACKAGELEN > _dataLength)
            subLen = [_dataBuffer length] - _curPos;
        
        NSData * curData = [_dataBuffer subdataWithRange:NSMakeRange(_curPos,subLen)];
        _curPos += subLen;
        
        //        NSString * fullString = [[NSString alloc] initWithData:_dataBuffer encoding:NSUTF8StringEncoding];
        //        NSString* aStr = [[NSString alloc] initWithData:curData encoding:NSUTF8StringEncoding];
        //        NSString *bStr = [fullString substringWithRange:NSMakeRange(_curPos, MIN(subLen,[fullString length]-_curPos))];
        
        
        
        
        //NSLog(@"1Have received data is :%@",aStr);
        //NSLog(@"2Have received data is :%@",bStr);
        //        [fullString release];
        
        
        //        [aStr release];
        
        [self decompressData:curData plen:plen result:packageData];
#ifdef TRACKPAGES
        //        NSData * compressedData = [NSData compressedDataWithData:packageData];
        //        NSLog(@"Not Compressed:%d compressed:%d  rate:%0.2f",packageData.length,compressedData.length,100.00 - compressedData.length * 100.0000/packageData.length );
        [[SystemConfiguration sharedSystemConfiguration] addBytes:curData.length compressBytes:packageData.length];
#endif
        //NSLog(@"left string len :%i",_dataLength - _curPos);
        //略过空格与回车换行符
        if(_curPos + SOCKETHEADLEN+ SOCKETPACKAGELEN > _dataLength)
            _curPos = _dataLength;
        
        while (_curPos <_dataLength)
        {
            char temp[1];
            [_dataBuffer getBytes:&temp range:NSMakeRange(_curPos, 1)];
            if(temp[0]=='\r'||temp[0]=='\n'||temp[0]==' ')
            {
                _curPos ++;
            }
            else
                break;
        }
        if(_curPos >=_dataLength)
        {
            [self clearData];
        }
        return HCBufferStatusReadOK;
    }
    return HCBufferStatusNeedRead;
}
-(void)decompressData:(NSData*)data plen:(int)plen result:(NSMutableData *)result
{
    //解压
    //判断是否加密或压缩，取第一个字节处理
    Byte byte[1];
    [data getBytes:&byte length:1];
    if((byte[0] & 0x02)>0)
    {
        if(plen <=0)
        {
            NSString * pageckagelen = nil;

            pageckagelen = [[NSString alloc]initWithData:
                            [data subdataWithRange:
                             NSMakeRange(SOCKETHEADLEN  , SOCKETPACKAGELEN)]
                                                encoding:NSUTF8StringEncoding];
            plen = [pageckagelen integerValue];
       
            PP_RELEASE(pageckagelen);
//            [pageckagelen release];
            
        }
        NSData * cpData = [data subdataWithRange:NSMakeRange(SOCKETHEADLEN + SOCKETPACKAGELEN, plen)];
        NSData * ncpData = [NSData dataWithCompressedData:cpData];
        plen = ncpData.length;
        
        [result appendData:[data subdataWithRange:NSMakeRange(0, SOCKETHEADLEN)]];
        
        NSString * plenString = [NSString stringWithFormat:@"%d",plen];
        NSMutableString * lenString = [[NSMutableString alloc]initWithCapacity:SOCKETPACKAGELEN];
        int i = plenString.length;
        while (i < SOCKETPACKAGELEN) {
            [lenString appendString:@"0"];
            i ++;
        }
        [lenString appendString:plenString];
        [result appendData:[lenString dataUsingEncoding:NSUTF8StringEncoding]];
        [result appendData:ncpData];
        if(data.length > SOCKETHEADLEN +SOCKETPACKAGELEN + plen)
        {
            [result appendData:[data subdataWithRange:NSMakeRange(SOCKETHEADLEN +SOCKETPACKAGELEN +plen, data.length - SOCKETHEADLEN -SOCKETPACKAGELEN - plen)]];
        }
        PP_RELEASE(lenString);
//        [lenString release];
        
    }
    else
    {
        [result appendData:data];
    }
}
- (void)compressData:(NSData*)data result:(NSMutableData * )result
{
    //解压
    //判断是否加密或压缩，取第一个字节处理
    if(data.length < SENDSOCKETLEN)
    {
        [result appendData:data];
        return;
    }
    Byte byte[1];
    [data getBytes:&byte length:1];
    if((byte[0] & 0x02)>0)
    {
  
        NSString * pageckagelen = nil;
        int plen = 0;
        
        //取UDI长度
        int startPos = 0;
        if(INCLUDEUDI)
        {
            startPos = SENDSOCKETLEN;
            pageckagelen = [[NSString alloc]initWithData:
                            [data subdataWithRange:
                             NSMakeRange(startPos  , 2)]
                                                encoding:NSUTF8StringEncoding];
            plen = [pageckagelen integerValue];
            startPos += plen +2;
        }
        PP_RELEASE(pageckagelen);
//        [pageckagelen release];
        //取Body长度
        pageckagelen = [[NSString alloc]initWithData:
                        [data subdataWithRange:
                         NSMakeRange(startPos  , 8)]
                                            encoding:NSUTF8StringEncoding];
        plen = [pageckagelen integerValue];
        
        NSData * ncpData = [data subdataWithRange:NSMakeRange(startPos, plen)];
        NSData * cpData = [NSData compressedDataWithData:ncpData];
        plen = cpData.length;
        
        [result appendData:[data subdataWithRange:NSMakeRange(0, startPos)]];
        PP_RELEASE(pageckagelen);
//        [pageckagelen release];
        
        
        NSString * plenString = [NSString stringWithFormat:@"%d",plen];
        NSMutableString * lenString = [[NSMutableString alloc]initWithCapacity:SOCKETPACKAGELEN];
        int i = plenString.length;
        while (i < SOCKETPACKAGELEN) {
            [lenString appendString:@"0"];
            i ++;
        }
        [lenString appendString:plenString];
        
        [result appendData:[lenString dataUsingEncoding:NSUTF8StringEncoding]];
        [result appendData:cpData];
        if(data.length > startPos + plen)
        {
            [result appendData:[data subdataWithRange:NSMakeRange(startPos +plen, data.length - startPos - plen)]];
        }
        PP_RELEASE(lenString);
//        [lenString release];
    }
    else
    {
        [result appendData:data];
    }
}
#endif
//
//- (HCBufferStatus)getNextPackageBytes:(Byte *)packageData length:(int *)packageLen
//{
//    *packageLen = 0;
//    if(!packageData) return HCBufferStatusNeedRead;
//    //处理沾包的情况，多个包一次性发过来
//    if(_curPos + SOCKETHEADLEN +SOCKETPACKAGELEN  < _dataLength)
//    {
//        
//        NSString* aStr1 = [[NSString alloc]initWithBytes:_byteBuffer length:_dataLength encoding:NSUTF8StringEncoding];
//        //NSString* aStr1 = [[NSString alloc] initWithData:_dataBuffer encoding:NSUTF8StringEncoding];
//        
//        //NSLog(@"-----Have received data is :%@",aStr1);
//        [aStr1 release];
//        NSString * pageckagelen = nil;
//        int plen = 0;
//        int startPos = _curPos + SOCKETHEADLEN;
//        @try {
//            pageckagelen = [aStr1 substringWithRange:NSMakeRange(startPos, SOCKETPACKAGELEN)];
//            //            pageckagelen = [[NSString alloc]initWithData:
//            //                            [_dataBuffer subdataWithRange:
//            //                                                NSMakeRange(_curPos + SOCKETHEADLEN - SOCKETPACKAGELEN  , SOCKETPACKAGELEN)]
//            //                                                encoding:NSUTF8StringEncoding];
//            plen = [pageckagelen integerValue];
//            startPos += plen +SOCKETPACKAGELEN;
//        }
//        @catch (NSException *exception) {
//            plen = 0;
//            NSLog(@"parse socket package error:cannot find package len:%@",pageckagelen);
//            return HCBufferStatusError;
//        }
//        @finally {
//            [pageckagelen release];
//        }
//        if(startPos > _dataLength)
//        {
//            return HCBufferStatusNeedRead;
//        }
//        //001013000000020027E90A80c8d6323900000062  40
//        //{"data":{},"totalcount":0,"msg":"  33
//        //鏈幏鍙栧埌閰掑簵","code":1}   29
//        
//        //        NSString * fullString = [[NSString alloc] initWithData:_dataBuffer encoding:NSUTF8StringEncoding];
//        //        NSData * curData = [_dataBuffer subdataWithRange:NSMakeRange(_curPos,SOCKETHEADLEN + plen)];
//        //        NSString* aStr = [[NSString alloc] initWithData:curData encoding:NSUTF8StringEncoding];
//        //        NSString *bStr = [fullString substringWithRange:NSMakeRange(_curPos, SOCKETHEADLEN +plen)];
//        *packageLen = startPos - _curPos;
//        memcpy(packageData, (void*)_byteBuffer + _curPos, *packageLen);
//        //NSData * curData = [[NSData alloc]initWithBytes:(void *)_byteBuffer +_curPos length:SOCKETHEADLEN + plen];
//        NSString * aStr = [[NSString alloc] initWithBytes:packageData length:*packageLen encoding:NSUTF8StringEncoding];
//        _curPos += (*packageLen);
//        
//        //NSLog(@"1Have received data is :%@",aStr);
//        //NSLog(@"2Have received data is :%@",bStr);
//        //[fullString release];
//        
//        //[packageData appendData:curData];
//        [aStr release];
//        
//        //略过空格与回车换行符
//        while (_curPos <_dataLength)
//        {
//            if(_byteBuffer[_curPos]=='\r'||_byteBuffer[_curPos]=='\n'||_byteBuffer[_curPos]==' ')
//            {
//                _curPos ++;
//            }
//            else
//                break;
//            //            char temp[1];
//            //            [_dataBuffer getBytes:&temp range:NSMakeRange(_curPos, 1)];
//            //            if(temp[0]=='\r'||temp[0]=='\n'||temp[0]==' ')
//            //            {
//            //                _curPos ++;
//            //            }
//            //            else
//            //                break;
//        }
//        if(_curPos >=_dataLength)
//        {
//            [self clearData];
//        }
//        return HCBufferStatusReadOK;
//    }
//    return HCBufferStatusNeedRead;
//}
@end

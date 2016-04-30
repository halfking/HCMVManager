//
//  CMDSocketHeader.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-9-21.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "CMDSocketHeader.h"
#import "CommonUtil.h"
#import "CommonUtil(Date).h"
#import "CMDs.h"
#import "CMDOP.h"
#import "FileDataCacheHelper.h"

#define CT_RESULTMD5KEY     @"ResultMD5"

//返回参数头部
//EncryptMethod	1	Uint8   0(00):不加密不压缩 1(01) 加密不压缩  3(11) 加密压缩 2(10) 不加密压缩
//协议版本序号	2	Uint8
//命令号	4	Uint8
//MessageId	16	Uint8
//Code	1	Uint8
//SecretCode	8	Byte
//Body_SIZE	8	Uint8

//请求的命令头部
//EncryptMethod	1	Uint8
//协议版本序号	2	Uint8
//命令号	4	Uint8
//MessageId	16	Uint8
//Code	1	Uint8
//SecretCode	8	Byte
//Body_SIZE	8	Uint8

@implementation CMDSocketHeader
- (id) init
{
    if(self = [super init])
    {
        encryptMethod_ = 0;
        protocolVersion_ =1;
    }
    return self;
}
- (id) initWithString:(NSString *)responseString
{
    if(self = [super initWithString:responseString])
    {
        if(responseString==nil ||[responseString length] <40)
            return nil;
        
        PP_RELEASE(body_);
//        PP_RETAIN(responseString);
        NSRange range = [responseString rangeOfString:@"{"];
        if(range.length>0)
            body_ = PP_RETAIN([responseString substringFromIndex:range.location]);
        else
            body_ = PP_RETAIN([responseString substringFromIndex:40]);
        
        self.CMDID = [[responseString substringWithRange:NSMakeRange(3, 4)]intValue];
        self.MessageID = [responseString substringWithRange:NSMakeRange(7, 16)];
        self.IsSilence = NO;
        self.CMD = [[CMDs sharedCMDs]getCMDOP:self.CMDID messageID:self.MessageID];
//        if(body_ && body_.length>=2 && self.CMDID>0)
//        {
//            NSString *testString = [[body_ substringFromIndex:[body_ length] -5 ]
//                                    stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
//            if([testString hasSuffix:@"}"] || [testString hasSuffix:@"]"])
//            {
//                CMDOP * cmd = [[CMDs sharedCMDs]getCMDOP:self.CMDID messageID:self.MessageID];
//                if(!cmd)    // 有可能是服务端主动发起的请求，在客户端并没有记录
//                {
//                    cmd = [[CMDs sharedCMDs]createCMDOP:self.CMDID];
//                }
//                
//                @try {
//                    HCCallbackResult * data =  [cmd parseResult:[body_ JSONValueEx]];
//                    self.Data = data;
//                }
//                @catch (NSException *exception) {
//                    DLog(@"error:%@",[exception description]);
//                    DLog(@"text:%@",body_);
//                    self.Data = nil;
//                }
//                @finally {
//                    
//                }
//                if(!self.Data)
//                {
//                    DLog(@"response body text error :%@",body_);
//                }
//            }
//        }
//        PP_RELEASE(responseString);
    }
    return self;
}
- (NSString *)requestHeaderUrl
{
    DeviceConfig * nconfig = [DeviceConfig Instance];
    return nconfig.InterfaceUrl;
}

//将数据专程可以使用的字串
- (NSString *) toString:(CMDOP*)cmd includeUDI:(BOOL)includeUDI
{
    PP_BEGINPOOL(pool);
	NSMutableString * url1 = [[NSMutableString alloc] init];// Encry+Version+CMD+MessageID
    NSMutableString * url2 = [[NSMutableString alloc] init];// 加密 Md5(M1+M3+Tockencode)[2][13][4][1]  4 个 byte 值
    NSMutableString * url3 = [[NSMutableString alloc] init];//ScreteCode之后的
    
    DeviceConfig * config = [DeviceConfig Instance];
    
    [url1 appendFormat:@"%d",encryptMethod_];//加密否
    [url1 appendString:[CommonUtil leftFillZero:[NSString stringWithFormat:@"%d",protocolVersion_] withLength:2]];//版本号
    [url1 appendString:[cmd getCMDName]];//命令号0001....0002
    [url1 appendString:cmd.messageID];
    
    
    //    EncryptMethod + Version + CMD + MESSAGEID + SecretCode + UDILEN + UDI +BODYLEN+BODY
    //      1+2+4+(8+8)+8+2+32+8 = 73
    //      1+2+4+(8+8)+8 = 31
    
    if(includeUDI)
    {
        [url3 appendString:[CommonUtil leftFillZero:[NSString stringWithFormat:@"%lu",(unsigned long)[config.UDI length]] withLength:2]];
        [url3 appendString:config.UDI];
    }
    
    NSString * argsString = [cmd args];
    //往BODY中增加JSON属性
    if(cmd.cacheKey)
    {
        NSString * cackeyMD5 = [CommonUtil md5Hash:cmd.cacheKey];
        NSString * resultMD5 = [[FileDataCacheHelper sharedFileDataCacheHelper]getDataMD5FromCacheDB:cackeyMD5
                                                                                              andCMD:[cmd getCMDName]];
        if(resultMD5!=nil && argsString!=nil)
        {
            @try {
                NSMutableDictionary * bodyJson = [argsString JSONValueEx];
                if(bodyJson!=nil)
                {
                    NSString * value =  [bodyJson objectForKey:CT_RESULTMD5KEY];
                    if(value!=nil) [bodyJson removeObjectForKey:CT_RESULTMD5KEY];
                    [bodyJson setObject:resultMD5 forKey:CT_RESULTMD5KEY];
                    argsString = [bodyJson JSONRepresentationEx];
                }
            }
            @catch (NSException *exception) {
                NSLog(@"when add resultmd5 to Body,body to json error:%@",exception);
            }
            @finally {
                
            }
            
        }
    }
    NSUInteger BodySize = argsString == nil?0:[argsString length];
    [url3 appendString:[CommonUtil leftFillZero:[NSString stringWithFormat:@"%d",(int)BodySize] withLength:8]];
    
    if (argsString!=nil)
    {
        [url3 appendString:argsString];//Body  JSON包
    }
    
    NSMutableString * toScode = [[NSMutableString alloc]init];
    [toScode appendString:url1];
    [toScode appendString:url3];
    
    if (tockenCode_ == nil)//首次登陆tockencode为空
    {
        [toScode appendString:@"0000"];
    }
    else//SecretCode    MD5（userid+tokencode）8位
    {
        [toScode appendString:[CommonUtil leftFillZero:tockenCode_ withLength:4]];
    }
    
    NSString * secretCode = [CommonUtil md5Hash:toScode];
    
    PP_RELEASE(toScode);
    
    [url2 appendString:[secretCode substringWithRange:NSMakeRange(2, 2)]]; //第2个字节，2个字符
    [url2 appendString:[secretCode substringWithRange:NSMakeRange(12, 2)]];//第7个字节
    [url2 appendString:[secretCode substringWithRange:NSMakeRange(4, 2)]]; //第3个字节
    [url2 appendString:[secretCode substringWithRange:NSMakeRange(0, 2)]]; //第1个字节
    
    //    secode = [secode initWithFormat:@"%@",secretCode];
    
    [url1 appendString:url2];
    [url1 appendString:url3];
#if !USEBINARYDATA
    [url1 appendString:@"\r\n"];//结束标识
#endif
	
    PP_RELEASE(url2);
    PP_RELEASE(url3);
    
    PP_ENDPOOL(pool);
    
	return PP_AUTORELEASE(url1);
}
- (id) initWithArgs:(NSString *)cmdString andEncryptMethod:(short)em andProtocolVersion:(short)pv andUDI:(NSString *)udi andTocken:(NSString *)tockenCode andUserID:(int)userID andBody:(NSString *)body andCacheKey:(NSString *)cacheKey andResultMD5:(NSString*) resultMD5
{
    //    static dispatch_once_t onceToken;
    //    dispatch_once(&onceToken, ^{
    //        cmdOrder_ = 0;
    //        lastMessageID_ = 0;
    //    });
    if(self = [super initWithArgs:cmdString andEncryptMethod:em andProtocolVersion:pv andUDI:udi
                        andTocken:tockenCode andUserID:userID andBody:body
                      andCacheKey:cacheKey andResultMD5:resultMD5])
    {
//        request.CMD = cmdString;
//        @try {
//            request.CMDID = [cmdString intValue];
//        }
//        @catch (NSException *exception) {
//            
//        }
//        @finally {
//            
//        }
//        
//        request.EncryptMethod = em;
//        request.ProtocolVersion = pv;
//        request.UDI = udi;
//        request.TockenCode = tockenCode;
//        request.UserID = userID;
//        request.Body = body;
//        request.IsDataFromCache = NO;
//        request.ResultMD5 = resultMD5;
//        
//        //request.CacheKey = [request getMD5:body];
//        //request.CacheKey = [self getMD5:[NSString stringWithFormat:@"%@_%@",cmdString,cacheKey]]
//        
//        request.CacheKey = cacheKey;
//        
//        
//        if(cacheKey!=nil)
//        {
//            request.CacheKeyMD5 = [CMDSocketRequest getMD5:cacheKey];
//        }
    }
    return self;
}
//- (void)setArgs:(NSString *)Args
//{
//    if(_Args!=nil) [_Args release];
//    if(Args==nil)
//    {
//        _Args = nil;
//        return;
//    }
//    _Args = [Args retain];
//    @try {
//        NSDictionary * dic = [Args JSONValueEx];
//        if(dic!=NULL)
//        {
//            if([dic objectForKey:@"pageindex"]!=nil)
//            {
//                self.PageIndex = [[dic objectForKey:@"pageindex"] intValue];
//            }
//            if([dic objectForKey:@"pagesize"]!=nil)
//            {
//                self.PageSize = [[dic objectForKey:@"pagesize"] intValue];
//            }
//            if([dic objectForKey:@"hotelid"]!=nil)
//            {
//                self.HotelID = [[dic objectForKey:@"hotelid"]intValue];
//            }
//        }
//        if(ArgsDic)
//        {
//            [ArgsDic release];
//            //            PP_RELEASE(ArgsDic);
//        }
//        ArgsDic = [dic retain];
//    }
//    @catch (NSException *exception) {
//        NSLog(@"parse pagesize,pageindex from  args:%@,error:%@",Args,[exception description]);
//        self.PageSize = -2;
//        self.PageIndex = -2;
//    }
//    @finally {
//        
//    }
//}
- (void) dealloc
{
    PP_SUPERDEALLOC;
}
@end

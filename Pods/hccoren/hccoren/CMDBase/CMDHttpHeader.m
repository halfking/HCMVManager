//
//  CMDHttpHeader.m
//  RBNews
//
//  Created by XUTAO HUANG on 13-5-14.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "CMDHttpHeader.h"
#import "CommonUtil.h"
#import "CommonUtil(Date).h"

#import "CMDs.h"
#import "CMDOP.h"

//返回参数头部
//EncryptMethod	1	Uint8   0(00):不加密不压缩 1(01) 加密不压缩  3(11) 加密压缩 2(10) 不加密压缩
//协议版本序号	2	Uint8
//命令号	4	Uint8
//MessageId	16	Uint8
//Code	1	Uint8
//SecretCode	8	Byte
//Body_SIZE	8	Uint8
@implementation CMDHttpHeader
- (id)init{
    if(self = [super init])
    {
#if REQUEST_POST
        if(!postContents_)
            postContents_ = [[NSMutableDictionary alloc]init];
        else
            [postContents_ removeAllObjects];
#endif
    }
    return self;
}
- (CMDHttpHeader *) initWithString:(NSString *)responseString
{
    if(self = [super initWithString:responseString])
    {
        PP_RELEASE(body_);
        body_ = PP_RETAIN(responseString);
//        NSDictionary * dic = [responseString JSONValueEx];
//        if(!dic)
//        {
//            self.MessageID = @"";
//            self.CMDID = -1;
//        }
//        else
//        {
//            self.IsSilence = NO;
//            self.MessageID =[dic objectForKey:@"timestamp"];
//            if([dic objectForKey:@"cmd"])
//                self.CMDID = [[dic objectForKey:@"cmd"]intValue];
//            else
//                self.CMDID = 0;
//            CMDOP * cmd = [[CMDs sharedCMDs]getCMDOP:self.CMDID messageID:self.MessageID];
////            if(!cmd)    // 有可能是服务端主动发起的请求，在客户端并没有记录
////            {
////                cmd = [[CMDs sharedCMDs]createCMDOP:self.CMDID];
////            }
//            self.CMD = cmd;
//            
////            @try {
////                HCCallbackResult * data =  [cmd parseResult:dic];
////                self.Data = data;
////            }
////            @catch (NSException *exception) {
////                DLog(@"error:%@",[exception description]);
////                DLog(@"text:%@",body_);
////                self.Data = nil;
////            }
////            @finally {
////                
////            }
////            if(!self.Data)
////            {
////                DLog(@"response body text error :%@",body_);
////            }
//            
//            if(!cmd.args)
//            {
//                NSMutableDictionary * dicArgs = [NSMutableDictionary new];
//                for (NSString * key in dic.allKeys) {
//                    if([key isEqualToString:@"list"]==NO && [key isEqualToString:@"data"]==NO)
//                    {
//                        [dicArgs setObject:[dic objectForKey:key] forKey:key];
//                    }
//                }
//                if(dicArgs.allKeys.count>0)
//                {
//                    [cmd setArgs:[dicArgs JSONRepresentationEx] dic:dicArgs];
//                }
//                PP_RELEASE(dicArgs);
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
- (NSString *)  toString:(CMDOP*)cmd includeUDI:(BOOL)includeUDI
{
    NSMutableString * url2 = [[NSMutableString alloc]init];
    @autoreleasepool {
        
//        NSMutableString * encryptSource = [[NSMutableString alloc] init];// Encry+Version+CMD+MessageID
        
        if([cmd requestUrl])
        {
            [url2 appendFormat:@"%@",[cmd requestUrl]];
        }
        else
        {
            DeviceConfig * nconfig = [DeviceConfig Instance];
        
        [url2 appendFormat:@"%@",nconfig.InterfaceUrl];
        }
//        [url2 appendFormat:@"http://%@:%d/json/%@.php",nconfig.HOST_IP1,nconfig.HOST_PORT1,cmd.SCode];
        
//#if REQUEST_POST
        [postContents_ removeAllObjects];
//        [postContents_ setObject:@"01" forKey:@"os"];
//        [postContents_ setObject:nconfig.UDI forKey:@"deviceid"];
        
//        [encryptSource appendString:@"01"];//nconfig.UA];
//        [encryptSource appendString:@"#"];
//        [encryptSource appendString:nconfig.TockenCode];
//        [encryptSource appendString:@"#"];
//        
//        [encryptSource appendString:nconfig.UDI];
//        [encryptSource appendString:@"#"];
//        
//        NSString * messageID = [cmd getMessageID];
//        NSMutableString * messageId = [[NSMutableString alloc]init];
//        
//        //mesageid的毫秒数后半部
//        //        NSString * time = [self getCurrentTime];
//        NSString * time = [NSString stringWithFormat:@"%d",[CommonUtil getDateTicks:[NSDate date]]];
//        
//        //    [retDic setObject:time forKey:@"timestamp"];
//        [postContents_ setObject:time forKey:@"timestamp"];
////        [encryptSource appendString:time];
//        PP_RELEASE(messageId);
//        
//        [postContents_ setObject:nconfig.Version forKey:@"version"];
//        
//        NSString *encryptionKey = [CommonUtil md5Hash:encryptSource];
//        
//        PP_RELEASE(encryptSource);
//        
//        [postContents_ setObject:encryptionKey forKey:@"checkcode"];
//        
//        BOOL hasPageSize = NO;
//    
//        if(cmd.pageSize>0)
//        {
//            [postContents_ setObject:@(cmd.pageIndex * cmd.pageSize+1) forKey:@"sindex"];
//            [postContents_ setObject:@((cmd.pageIndex +1) * cmd.pageSize) forKey:@"eindex"];
//            hasPageSize = YES;
//        }
//        //增加其它的非标准参数
//        if(!argsDic_ && cmd.args)
//            argsDic_ = [cmd.args JSONValueEx];
//        if(argsDic_)
//        {
//            for (NSString * key in [argsDic_ keyEnumerator]) {
//                if([key isEqualToString:@"pageindex"]
//                   ||[key isEqualToString:@"pagesize"]
//                   ||[key isEqualToString:@"scode"]
//                   ||([key isEqualToString:@"sindex"] && hasPageSize)
//                   ||([key isEqualToString:@"eindex"] && hasPageSize)
//                   || [key isEqualToString:@"os"]
//                   || [key isEqualToString:@"version"])
//                    continue;
//                [postContents_ setObject:[argsDic_ objectForKey:key] forKey:key];
//            }
//        }
        if(!cmd.argsDic)
        {
            [cmd calcArgsAndCacheKey];
        }
        argsDic_ = PP_RETAIN(cmd.argsDic);
        BOOL notAddAnd = NO;
        if(![cmd isPost])
        {
            if([url2 rangeOfString:@"?"].location==NSNotFound)
            {
                [url2 appendString:@"?"];
                notAddAnd = YES;
            }
        }
        for (NSString * key in argsDic_.keyEnumerator) {
            if(![cmd isPost])
            {
                if(notAddAnd)
                {
                [url2 appendFormat:@"%@=%@",key,[[argsDic_ objectForKey:key]JSONRepresentationEx]];
                    notAddAnd = NO;
                }
                else
                {
                     [url2 appendFormat:@"&%@=%@",key,[[argsDic_ objectForKey:key]JSONRepresentationEx]];
                }
            }
            else
            {
                [postContents_ setObject:[argsDic_ objectForKey:key] forKey:key];
            }
        }
//#else
//        if(![nconfig.InterfaceUrl hasSuffix:@"?"])
//        {
//            [url2 appendString:@"?"];
//        }
//        if(!cmd.argsDic)
//        {
//            [cmd calcArgsAndCacheKey];
//        }
//        argsDic_ = PP_RETAIN(cmd.argsDic);
//        int index =0;
//        for (NSString * key in argsDic_.keyEnumerator) {
//            if(index >0)  [url2 appendString:@"&"];
//            if([[ argsDic_ objectForKey:key] isKindOfClass:[NSString class]])
//            {
//                [url2 appendFormat:@"%@=%@",key,(NSString*)[ argsDic_ objectForKey:key]];
//            }
//            else
//            {
//                [url2 appendFormat:@"%@=%@",key,[[ argsDic_ objectForKey:key]JSONRepresentationEx]];
//            }
//            index ++;
//        }
////        [url2 appendFormat:@"?%@=%@&",@"os",@"01" ];//nconfig.UA ];
////        [encryptSource appendString:@"01"];//nconfig.UA];
////        [encryptSource appendString:@"#"];
////        [encryptSource appendString:nconfig.TockenCode];
////        [encryptSource appendString:@"#"];
////        
////        //    [retDic setObject:nconfig.UDI forKey:@"deviceTocken"];
////        [url2 appendFormat:@"%@=%@&",@"deviceid",nconfig.UDI ];
////        [encryptSource appendString:nconfig.UDI];
////        [encryptSource appendString:@"#"];
////        
////        NSMutableString * messageId = [[NSMutableString alloc]init];
////        
////        //mesageid的毫秒数后半部
////        //        NSString * time = [self getCurrentTime];
////        NSString * time = [NSString stringWithFormat:@"%d",[CommonUtil getDateTicks:[NSDate date]]];
////        
////        self.timestamp = time;
////        //    [retDic setObject:time forKey:@"timestamp"];
////        [url2 appendFormat:@"%@=%@&",@"timestamp",time ];
////        [encryptSource appendString:time];
////        [messageId release];
////        
////        //    [retDic setObject: nconfig.Version forKey:@"version"];
////        [url2 appendFormat:@"%@=%@&",@"version",nconfig.Version ];
////        NSString * encryptionKey = [CommonUtil md5Hash:encryptSource];
////        
////        PP_RELEASE(encryptSource);
////        
////        [url2 appendFormat:@"%@=%@",@"checkcode",self.encryptionKey ];
////        BOOL hasPageSize = NO;
////        if(cmd.pageSize>0)
////        {
////            [url2 appendFormat:@"&%@=%d&",@"sindex",cmd.pageIndex * cmd.pageSize+1 ];
////            [url2 appendFormat:@"%@=%d",@"eindex",(cmd.pageIndex +1) * cmd.pageSize) ];
////            hasPageSize = YES;
////        }
////       
////        //增加其它的非标准参数
////        if(!argsDic_ && cmd.args)
////            argsDic_ = [cmd.args JSONValueEx];
////        if(argsDic_)
////        {
////            for (NSString * key in [argsDic_ keyEnumerator]) {
////                if([key isEqualToString:@"pageindex"]
////                   ||[key isEqualToString:@"pagesize"]
////                   ||[key isEqualToString:@"scode"]
////                   ||([key isEqualToString:@"sindex"] && hasPageSize)
////                   ||([key isEqualToString:@"eindex"] && hasPageSize)
////                   || [key isEqualToString:@"os"]
////                   || [key isEqualToString:@"version"])
////                    continue;
////                [url2 appendFormat:@"&%@=%@",key,[[argsDic_ objectForKey:key]JSONRepresentationEx]];
////            }
////        }
//#endif
    }
    return PP_AUTORELEASE(url2);
//    PP_RELEASE(url2);
}
////将数据专程可以使用的字串
//- (NSString *) toString:(BOOL)includeUDI
//{
//    NSMutableString * url2 = [[NSMutableString alloc]init];
//    self.timestamp = [self getCurrentTimeStamp];
//    @autoreleasepool {
//        
//        NSMutableString * encryptSource = [[NSMutableString alloc] init];// Encry+Version+CMD+MessageID
//        NSMutableString * paramString = [[NSMutableString alloc]init];
//        DeviceConfig * nconfig = [DeviceConfig Instance];
//        if(nconfig.HOST_PORT1 == 80)
//        {
//            if([nconfig.HOST_IP1 hasPrefix:@"http://"])
//                [url2 appendFormat:@"%@?",nconfig.HOST_IP1];
//            else
//                [url2 appendFormat:@"http://%@?",nconfig.HOST_IP1];
//        }
//        else
//        {
//            if([nconfig.HOST_IP1 hasPrefix:@"http://"])
//                [url2 appendFormat:@"%@:%d?",nconfig.HOST_IP1,nconfig.HOST_PORT1];
//            else
//                [url2 appendFormat:@"http://%@:%d?",nconfig.HOST_IP1,nconfig.HOST_PORT1];
//        }
//        //添加默认参数
//        if(![paramDic objectForKey:@"access_token"])
//        {
//            if(nconfig.AccessTocken)
//                [paramDic setObject:nconfig.AccessTocken forKey:@"access_token"];
//            else
//                [paramDic setObject:access_tocken_ forKey:@"access_token"];
//        }
//        
//        [paramDic setObject:app_key_ forKey:@"app_key"];
//        [paramDic setObject:format_ forKey:@"format"];
//        if(![paramDic objectForKey:@"method"])
//        {
//            NSString * method = [paramDic objectForKey:@"scode"];
//            if(method)
//            {
//                [paramDic setObject:method forKey:@"method"];
//            }
//            else
//            {
//                [paramDic setObject:self.SCode forKey:@"method"];
//            }
//        }
//        [paramDic setObject:sign_method_ forKey:@"sign_method"];
//        [paramDic setObject:version_ forKey:@"v"];
//        [paramDic setObject:[self getCurrentTime] forKey:@"timestamp"];
//        //        [paramDic setObject:[CommonUtil encodeToPercentEscapeString:[self getCurrentTime]] forKey:@"timestamp"];
//        
//#if REQUEST_POST
//        [postContents_ removeAllObjects];
//        [postContents_ setObject:@"01" forKey:@"os"];
//        [postContents_ setObject:nconfig.UDI forKey:@"deviceid"];
//        
//        [encryptSource appendString:@"01"];//nconfig.UA];
//        [encryptSource appendString:@"#"];
//        [encryptSource appendString:nconfig.TockenCode];
//        [encryptSource appendString:@"#"];
//        
//        [encryptSource appendString:nconfig.UDI];
//        [encryptSource appendString:@"#"];
//        
//        NSMutableString * messageId = [[NSMutableString alloc]init];
//        
//        //mesageid的毫秒数后半部
//        //        NSString * time = [self getCurrentTime];
//        NSString * time = [NSString stringWithFormat:@"%d",[CommonUtil getDateTicks:[NSDate date]]];
//        
//        self.timestamp = time;
//        //    [retDic setObject:time forKey:@"timestamp"];
//        [postContents_ setObject:time forKey:@"timestamp"];
//        [encryptSource appendString:time];
//        [messageId release];
//        
//        [postContents_ setObject:nconfig.Version forKey:@"version"];
//        
//        self.encryptionKey = [CommonUtil md5Hash:encryptSource];
//        
//        [encryptSource release];
//        
//        [postContents_ setObject:self.encryptionKey forKey:@"checkcode"];
//        
//#else
//        NSArray * keys = [paramDic.allKeys sortedArrayWithOptions:NSSortStable
//                                                  usingComparator:^ NSComparisonResult (NSString* obj1,NSString* obj2){
//                                                      return [obj1 compare:obj2];
//                                                  }];
//        // access_token=test
//        [encryptSource appendString:presign_];
//        for (NSString * key in keys) {
//            [encryptSource appendFormat:@"%@%@",key,[paramDic objectForKey:key]];
//            //app_key,format,method,access_token,sign_method,v,sign
//            //            if([key isEqualToString:@"timestamp"])
//            if(![key isMatchedByRegex:@"^(app_key|format|method|access_token|sign_method|v|sign|term_id|term_mac)$"])
//            {
//                [paramString appendFormat:@"&%@=%@",key,[CommonUtil encodeToPercentEscapeString:[paramDic objectForKey:key]]];
//            }
//            else
//            {
//                [paramString appendFormat:@"&%@=%@",key,[paramDic objectForKey:key]];
//            }
//        }
//        [encryptSource appendString:presign_];
//        
//        //        DLog(@"md5:%@",[CommonUtil md5Hash:@"app_secretaccess_token=testapp_key=testformat=xmlmethod=linkea.mobilerecharge.getmobile=186581260XXsign_method=md5timestamp=2013-09-02 09:12:05v=1.1app_secret"]);
//        self.encryptionKey = [CommonUtil md5Hash:encryptSource];
//        
//        [url2 appendFormat:@"%@=%@",@"sign",self.encryptionKey ];
//        [url2 appendString:paramString];
//        PP_RELEASE(paramString);
//        PP_RELEASE(encryptSource);
//        
//#endif
//    }
//    return [url2 autorelease];
//    
//}
//+(CMDHttpRequest *)initwithParams:(NSString *)cmdString andParams:(NSDictionary *)params
//{
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        cmdOrder_ = 0;
//        lastMessageID_ = 0;
//    });
//    
//    CMDHttpRequest * request =[[CMDHttpRequest alloc]init];
//    request.SCode = cmdString;
//    request.paramDic = [NSMutableDictionary dictionaryWithDictionary:params];
//    return PP_AUTORELEASE(request);
//}
//+ (CMDHttpRequest *) initWithArgs:(NSString *)cmdString andEncryptMethod:(short)em andProtocolVersion:(short)pv andUDI:(NSString *)udi andTocken:(NSString *)tockenCode andUserID:(int)userID andBody:(NSString *)body andCacheKey:(NSString *)cacheKey andResultMD5:(NSString*) resultMD5
//{
//    CMDHttpRequest * request = [[CMDHttpRequest alloc] init];
//    request.CMD = cmdString;
//    @try {
//        request.CMDID = [cmdString intValue];
//    }
//    @catch (NSException *exception) {
//
//    }
//    @finally {
//
//    }
//
//    request.EncryptMethod = em;
//    request.version = pv;
//    request.deviceID = udi;
//    request.encryptionKey = tockenCode;
//    request.UserID = userID;
//    request.Body = body;
//    request.IsDataFromCache = NO;
//    request.ResultMD5 = resultMD5;
//
//    //request.CacheKey = [request getMD5:body];
//    //request.CacheKey = [self getMD5:[NSString stringWithFormat:@"%@_%@",cmdString,cacheKey]]
//
//    request.CacheKey = cacheKey;
//
//
//    if(cacheKey!=nil)
//    {
//        request.CacheKeyMD5 = [CMDHttpRequest getMD5:cacheKey];
//    }
//
//    return [request autorelease];
//}
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
//            if([dic objectForKey:@"pagesize"]!=nil)
//            {
//                self.PageSize = [[dic objectForKey:@"pagesize"] intValue];
//            }
//            if([dic objectForKey:@"scode"]!=nil)
//            {
//                self.SCode = [dic objectForKey:@"scode"];
//            }
//        }
//        if(argsDic_)
//        {
//            [argsDic_ release];
//            argsDic_ = nil;
//        }
//        if(dic)
//            argsDic_ = [dic retain];
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
#if REQUEST_POST
- (NSMutableDictionary *)postContents
{
    return postContents_;
}
#endif
- (NSDictionary*)Args
{
    return argsDic_;
}
#pragma mark - dealloc
- (void) dealloc
{
#if REQUEST_POST
    PP_RELEASE(postContents_);
#endif
    PP_RELEASE(argsDic_);
    PP_SUPERDEALLOC;
}
@end
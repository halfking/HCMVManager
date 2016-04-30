//
//  CMDSocketSender.m
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-6.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "CMDSocketSender.h"
#import "HCBase.h"
#import "CMDs.h"
#import "AsyncSocket.h"

//#import "Common.h"
#import "CommonUtil(Date).h"
#import "Socketsingleton.h"
#import "FileDataCacheHelper.h"
#import "CMDOP.h"
#import "CMDSocketHeader.h"
@implementation CMDSocketSender
SYNTHESIZE_SINGLETON_FOR_CLASS_NEW(CMDSocketSender)
//+ (CMDSender *)sharedCMDSender
//{
//    return [CMDSocketSender sharedCMDSocketSender];
//}
- (BOOL)sendCMD:(CMDOP *)cmd
{
    
    Socketsingleton * socket = [Socketsingleton sharedSocketsingleton];
    BOOL ret = NO;
    if(![socket isConnnection_] && [socket IsInited] && socket.asyncSocket && socket.asyncSocket.isConnected )
    {
        CMDSocketHeader * header = [[CMDSocketHeader alloc]init];
        NSString * url = [header toString:cmd includeUDI:YES];
        NSLog(@"send data:%@____>%@",cmd,url);
        NSData * data = [url dataUsingEncoding:NSUTF8StringEncoding];
        int suc = [socket sendData:data withTimeout:5 tag:1];
        if(suc>0)
        {
            ret = YES;
        }
        PP_RELEASE(header);
    }
    else
    {
        [socket connectToServer:self];
    }
    
    return ret;
}
#pragma mark - singleton delegate
-(void)netFailure:(NSError *)error
{
    NSLog(@"%ld",(long)[error code]);
    @synchronized(self){
        CMDs * cmds = [CMDs sharedCMDs];
        for (CMDOP * dic in cmdQueueSended_) {
            if(dic.ticksForSendReady >0)
            {
                //                PP_RETAIN(dic);
                [cmds removeCMDOP:dic];
                [cmds addCMDOPToQueue:NO cmd:dic];
                //                PP_RELEASE(dic);
            }
        }
    }
}
//- (BOOL)Call:(NSDictionary *)dic
//{
//    //    if(!timer ||![timer userInfo]) return YES;
//    //    NSDictionary * dic = [timer userInfo];
//    if(!dic) return YES;
//    NSString * cmd = [dic objectForKey:@"cmd"];
//    NSString * args = [dic objectForKey:@"args"];
//    NSString * cacheKey = [dic objectForKey:@"cachekey"];
//    BOOL useCache = [[dic objectForKey:@"usecache"]boolValue];
//    BOOL hasLocalData = [[dic objectForKey:@"haslocaldata"]boolValue];
////    long timeTicks = [[dic objectForKey:@"timeticks"]longValue];
//    if([cacheKey isKindOfClass:[NSNull class]]) cacheKey = nil;
//
//    NSString * messageID = nil;
//    if([self Call:cmd args:args
//         cachekey:cacheKey delegate:nil useCache:useCache
//     hasLocalData:hasLocalData isRetry:YES
//        messageID:&messageID])
//    {
//        return YES;
//    }
//    return NO;
//}
//-(BOOL) Call:(NSString *)cmd
//        args:(NSString *)args
//    cachekey:(NSString *)cacheKey
//    useCache:(BOOL)useCache
//hasLocalData:(BOOL)hasLocalData
//{
//    NSString * messageID = nil;
//
//    //如果发送失败，则加入到队列中
//    if(![self Call:cmd args:args
//          cachekey:cacheKey
//          useCache:useCache
//      hasLocalData:hasLocalData
//           isRetry:NO
//         messageID:&messageID])
//    {
//        return NO;
//    }
//    return YES;
//}
//-(BOOL) Call:(NSString *)cmd args:(NSString *)args cachekey:(NSString *)cacheKey
//    useCache:(BOOL)useCache hasLocalData:(BOOL)hasLocalData
//     isRetry:(BOOL)isRetry messageID:(NSString**)messageID
//{
//    //    BOOL hasNet = TRUE;
//    @synchronized(self){
//        //myObserver = delegate ;//传进来的self
//        if(myCmd!=nil) [myCmd release];
//        myCmd = cmd;//指令0001
//
//        CMDSocketRequest * request = [[CMDSocketRequest
//                                       initWithArgs:cmd
//                                       andEncryptMethod:USECOMPRESS
//                                       andProtocolVersion:1
//                                       andUDI:information.UDI
//                                       andTocken:config_.TockenCode
//                                       andUserID:[CMDs userID]
//                                       andBody:args
//                                       andCacheKey:cacheKey
//                                       andResultMD5:@""] retain];
//
//        request.Args = args;
//
//        //获得本地缓存的MD5，发送到服务端，进行比较。
//        if(cacheKey)
//        {
//            NSString * bodyString = nil;
//            request.ResultMD5 = [cacheHelper_ getDataMD5FromCacheFile:cmd
//                                                          andCacheKey:cacheKey
//                                                           dataString:&bodyString];
//            if(bodyString)
//            {
//                request.Body = bodyString;
//            }
//        }
//
//        //如果本地有数据，并且数据的最后更新日期不超过一定时间，则不需要查询网络
//        if(hasLocalData==YES && cacheKey &&
//           (! [delegate isKindOfClass:[ForceUpdateObserver class]]))
//        {
//            //        if(request.CMDID==139)
//            //            NSLog(@"request cachekey:%@",request.CacheKeyMD5);
//            if(![self isNeedRemoteCall:request])
//            {
//                if(messageDic &&request.MessageID)
//                {
//                    [messageDic removeObjectForKey:[NSString stringWithFormat:@"request-%@",request.MessageID]];
//                    [messageDic removeObjectForKey:[NSString stringWithFormat:@"rs-%@",request.MessageID]];
//                    [messageDic removeObjectForKey:request.MessageID];
//                }
//                [information release];
//                [request release];
//                DLog(@"Data from DB:%@ ,不需要从服务器读取数据.",request.CMD);
//                return YES;
//            }
//        }
//        if(hasLocalData==3)
//        {
//            request.IsSilence = YES; //表示后台读取数据，不需要前台响应
//            DLog(@"request is silence:%d",request.CMDID);
//        }
//        if (messageDic==nil)
//        {
//            @synchronized(self)
//            {
//                if(messageDic==nil)
//                {
//                    messageDic = [[NSMutableDictionary alloc]init];
//                }
//            }
//        }
//        //部分接口不需要直接去网络
//        //will call
//        if(delegate && [delegate respondsToSelector:@selector(willCall:cmd:request:)])
//        {
//            [delegate willCall:self cmd:myCmd request:request];
//        }
//
//        //只有读取URL后才能正确获得MessageID
//        NSString * url = [[request toString:(INCLUDEUDI > 0?YES:NO)] retain];
//        if([messageDic count]>5)
//        {
//            NSLog(@"Message List:%@",messageDic);
//        }
//
//
//        //check 网络连接
//        //如果没有网络，则尝试连接一次网络
//        if(![CMDHelper haveNetworkConn] && [DeviceConfig isAllowNet])
//        {
//            Socketsingleton * singleSocket = [Socketsingleton sharePassValue];
//            [singleSocket connectToServer:self];
//
//            *messageID = request.MessageID;
//
//            [messageDic removeObjectForKey:[NSString stringWithFormat:@"request-%@",request.MessageID]];
//            [messageDic removeObjectForKey:[NSString stringWithFormat:@"rs-%@",request.MessageID]];
//            [messageDic removeObjectForKey:request.MessageID];
//            [url release];
//            [information release];
//            [request release];
//
//            return NO;
//
//        }
//        else{
//            //        hasNet = [CMDHelper haveNetworkConn];
//        }
//        request.IsDataFromCache = NO;
//
//        //如果不禁止使用缓存
//        //现在处理的模式可能有变化，此处需要修改
//        //当前处理流程为，将数据发送至服务端，有服务端比较数据是否有变化，有变化则服务端发送完整数据，否则服务端值发送状态数据。
//
//        NSLog(@"拼接命令后%@",url);
//        BOOL resultValue = NO;
//        if([CMDHelper haveNetworkConn] &&[DeviceConfig isAllowNet])
//        {
//            *messageID = request.MessageID;
//            //缓存request
//            if(delegate)
//                [messageDic setObject:delegate forKey:request.MessageID];
//            [messageDic setObject:request forKey:[NSString stringWithFormat:@"request-%@",request.MessageID]];
//            if(request.IsSilence)
//            {
//                [messageDic setObject:[NSNumber numberWithInt:1] forKey:[NSString stringWithFormat:@"rs-%@",request.MessageID]];
//                //            DLog(@"requst is silence 2:%d",request.CMDID);
//            }
//            NSData * data = [url dataUsingEncoding:NSUTF8StringEncoding];
//            DLog(@"Ready to send....");
//            //        int ret = 1;
//            //        if(request.CMDID!=144)
//            int ret = [[Socketsingleton sharePassValue] sendData:data withTimeout:5 tag:1];
//            if(ret==0) //发送失败
//            {
//                [messageDic removeObjectForKey:[NSString stringWithFormat:@"request-%@",request.MessageID]];
//                [messageDic removeObjectForKey:[NSString stringWithFormat:@"rs-%@",request.MessageID]];
//                [messageDic removeObjectForKey:request.MessageID];
//                resultValue = NO;
//            }
//            else
//            {
//                resultValue = YES;
//            }
//        }
//        else
//        {
//            //去除观察者的缓存
//            [messageDic removeObjectForKey:request.MessageID];
//            [messageDic removeObjectForKey:[NSString stringWithFormat:@"request-%@",request.MessageID]];
//            [messageDic removeObjectForKey:[NSString stringWithFormat:@"rs-%@",request.MessageID]];
//            resultValue = NO;
//        }
//        [url release];
//        [information release];
//        [request release];
//
//        return resultValue;
//    }
//}
@end

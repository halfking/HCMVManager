//
//  CMDOP.m
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-4.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "CMDOP.h"
#import "base.h"
#import "FileDataCacheHelper.h"

#import "CMDHeader.h"
#import "CMDs.h"
#import "CMDSender.h"
#import "HCCallbackResult.h"
#import "CMDHttpHeader.h"
#import "CMDSocketHeader.h"
#ifdef LOGCMDTIME
#import "CMDLog.h"
#import "CMD_LOGTIME.h"
#endif

@implementation CMDOP
#ifdef LOGCMDTIME
@synthesize ticksForParse,ticksForSendTime,ticksForBegin,ticksForCreated;
#endif
@synthesize ticksForSendReady;
@synthesize messageID = MessageID_;
@synthesize CMDID = CMDID_;
@synthesize retryTimes;
@synthesize args = args_;
@synthesize argsHash = argsHash_;
@synthesize cacheKey = cacheKey_;
@synthesize resultMD5;
@synthesize SCode;
@synthesize didTimeout = didTimeout_;
@synthesize maxRetryTimes = maxRetryTimes_;
@synthesize retryForFailure = retryForFailure_;
- (id)init
{
    if(self = [super init])
    {
        params_ = nil;
        delegate_ = nil;
        MessageID_  = nil;
        CMDID_ = 0;
        cmdCompleted_ = NO;
        retryTimes = 0;
        canLoadFromDB_ = YES;
        networkFailureAlert = YES;
        retryForFailure_ = NO;
        useHttpSender_ = NO;
        args_ = nil;
        resultMD5 = nil;
        cacheKey_ = nil;
        SCode = nil;
        currentCMDs_ = nil;
        MessageID_ = PP_RETAIN([self getMessageID]);
        maxRetryTimes_ = 2;//默认重试3次
        didTimeout_ = NO;
        pageSize_ = 10;
        pageIndex_ = -1;//用特殊值，防止出现错误时不知。
        useHttpSender_ = YES;
        requestUrl_ = nil;
        isPost_ = YES;
#ifdef LOGCMDTIME
        ticksForCreated = [CommonUtil getDateTicks:[NSDate date]];
#endif
    }
    return self;
}
- (BOOL) needRemoved
{
    return cmdCompleted_;
}
- (BOOL) useHttpSender
{
    return useHttpSender_;
}
- (BOOL) isPost
{
    return isPost_;
}
- (NSString *)requestUrl
{
    if(requestUrl_==nil)
    {
        requestUrl_ = PP_RETAIN([[self getHeader] requestHeaderUrl]);
    }
    return requestUrl_;
}
- (void) setRequestUrl:(NSString *)urlString
{
    PP_RELEASE(requestUrl_);
    requestUrl_ = PP_RETAIN(urlString);
}
- (void)    setArgs:(NSString *)args1 dic:(NSDictionary*)dic
{
    if(args_) PP_RELEASE(args_);
    args_ = PP_RETAIN(args1);
    
    if(dic)
    {
        if(argsDic_) PP_RELEASE(argsDic_);
        argsDic_ = PP_RETAIN(dic);
    }
    //xxxxxxx
}
- (CMDs *) getCMDs
{
    if(!currentCMDs_)
    {
        currentCMDs_ = [CMDs sharedCMDs];
    }
    return currentCMDs_;
}
- (NSString *)getCMDName
{
    return
    [CommonUtil leftFillZero:[NSString stringWithFormat:@"%d",CMDID_]
                  withLength:4];
}
- (NSString *)getNotificationName
{
    return [NSString stringWithFormat:@"CMD_%@",
            [CommonUtil leftFillZero:[NSString stringWithFormat:@"%d",CMDID_]
                          withLength:4]
            ];
}
- (NSString *)getMessageID
{
    //mesageid的userid前半部
    int userID = 0;
    if(params_)
    {
        userID = [[params_ objectForKey:@"userid"]intValue];
    }
    
    NSString * userIDString = [CommonUtil leftFillZero:[CommonUtil toHEXstring:userID] withLength:8];
    
    //mesageid的毫秒数后半部
    
    NSString * time = nil;
    if(currentCMDs_)
        time = [currentCMDs_ getCurrentTimeForMessageID];
    else
        time = [[self getCMDs] getCurrentTimeForMessageID];
    
    return [NSString stringWithFormat:@"%@%@",userIDString,time];
}
- (CMDHeader *)getHeader:(NSString *)responseString
{
    CMDHeader * header = PP_RETAIN([self getHeader]);
    return PP_AUTORELEASE([header initWithString:responseString]);
    //    return PP_AUTORELEASE([[CMDHeader alloc]initWithString:responseString]);
}
- (CMDHeader *)getHeader
{
    if(useHttpSender_)
        return PP_AUTORELEASE([[CMDHttpHeader alloc]init]);
    else
        return PP_AUTORELEASE([[CMDSocketHeader alloc]init]);
}
- (BOOL) isMatch:(int)cmdid messageID:(NSString *)messageID
{
    if((CMDID_ == cmdid||cmdid==0) && ( (messageID && MessageID_ && [messageID isEqualToString:MessageID_])
                                       || (messageID==nil && MessageID_ == nil)))
    {
        return YES;
    }
    return NO;
}
- (BOOL) isMatch:(int)cmdid args:(NSString *)args
{
    if(CMDID_ == cmdid && ( (args && args_ && [args isEqualToString:args_])
                           || (args==nil && args == nil)))
    {
        return YES;
    }
    return NO;
}


#pragma mark  - send
//-(void)callDirect:(NSString *)body
//{
//    //    NSLog(@"body:%@",body);
//    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc]init];
//    CMDSocketRequest * request = [[CMDSocketRequest
//                                   initWithArgs:cmd
//                                   andEncryptMethod:0
//                                   andProtocolVersion:1
//                                   andUDI:information.UDI
//                                   andTocken:information.TockenCode
//                                   andUserID:[CMDs userID]
//                                   andBody:body
//                                   andCacheKey:nil
//                                   andResultMD5:@""] retain];
//
//    //    request.Args = body;
//    //获得本地缓存的MD5，发送到服务端，进行比较。
//    //request.ResultMD5 = [self getDataMD5FromCacheFile:request andCMD:cmd andCacheKey:nil];
//
//    //多了clientsize,clientid的参数，可能导致解析失败,因此增加了一个参数
//
//    NSString * requestString = [request toString:NO];
//    [request release];
//    //需要在第23个字节处增加一个code:0，加一个字节，否则结果少1个字节。
//    NSString * request2  = [NSString stringWithFormat:@"%@0%@",[requestString substringToIndex:22],[requestString substringFromIndex:22]];
//    //    NSLog(@"requst2:%@",request2);
//    //    NSLog(@"log:%@",requestString);
//
//    CMDSocketResponse * response = [[CMDSocketResponse initWithString:request2]retain];
//    if(request.Args)
//        response.Args = request.Args;
//    response.FromLocalDB = YES;
//    //异步调用，防止影响流程
//    if([delegate respondsToSelector:@selector(CMDCallback:)])
//    {
//        NSMutableDictionary * dd = [[NSMutableDictionary alloc]init];
//        [dd setObject:response forKey:@"response"];
//        if(response.Dictionary!=nil)
//            [dd setObject:response.Dictionary forKey:@"data"];
//        [NSTimer scheduledTimerWithTimeInterval:0.02 target:delegate selector:@selector(CMDCallback:) userInfo:dd repeats:NO];
//        [dd release];
//    }
//    else
//    {
//        [delegate CMDCallback:self response:response data:response.Dictionary];
//    }
//    [response release];
//    [pool drain];
//    [request release];
//}
- (BOOL)sendCMD:(id<CMDDelegate>)delegate params:(NSDictionary *)params
{
    return [self sendCMD:delegate params:params insertIntoQueue:retryForFailure_];
}
- (BOOL)sendCMD:(id<CMDDelegate>)delegate params:(NSDictionary *)params insertIntoQueue:(BOOL)insert
{
    //    retryTimes = 0;
#ifdef LOGCMDTIME
    ticksForBegin = [CommonUtil getDateTicks:[NSDate date]];
#endif
    [self clearTimer];
    if(params_)
    {
        PP_RELEASE(params_);
    }
    if(delegate_)
    {
        PP_RELEASE(delegate_);
    }
    if(MessageID_)
    {
        PP_RELEASE(MessageID_);
    }
    if(argsHash_)
    {
        PP_RELEASE(argsHash_);
    }
    params_ = PP_RETAIN(params);
    delegate_ = PP_RETAIN(delegate);
    
    
    
    MessageID_ = PP_RETAIN([self getMessageID]);
    
    //解析常用参数
    if(params_)
    {
        if([params_ objectForKey:@"pageindex"])
        {
            pageIndex_ = [[params_ objectForKey:@"pageindex"]intValue];
        }
        else if([params_ objectForKey:@"PageIndex"])
        {
            pageIndex_ = [[params_ objectForKey:@"PageIndex"]intValue];
        }
        
        if([params_ objectForKey:@"pagesize"])
        {
            pageSize_ = [[params_ objectForKey:@"pagesize"]intValue];
        }
        else if([params_ objectForKey:@"PageSize"])
        {
            pageSize_ = [[params_ objectForKey:@"PageSize"]intValue];
        }
    }
    
    //是否要获取本地数据的CacheMD5？
    if(argsDic_) {PP_RELEASE(argsDic_);}
    if(args_) {PP_RELEASE(args_);}
    if(argsHash_) PP_RELEASE(argsHash_);
    
    if(![self calcArgsAndCacheKey])
    {
        //        assert(@"error key ");
        NSLog(@"arg compile failure....");
        return NO;
    }
    if(args_) argsHash_ = PP_RETAIN([CommonUtil md5Hash:args_]);
    
    //检查网络是否正常,不正常情况下要判断是否可以从本地加载数据
    
    DeviceConfig * config = [DeviceConfig Instance];
    //是否从本地获取数据
    if([self isQueryFromLocal:argsDic_ networkStatus:config.networkStatus])
    {
        BOOL ret = [self sendLocalData];
        //如果本地获取了数据，就不从服务器上获取了
        if(ret) return ret;
    }
    if(config.networkStatus == ReachableNone)
    {
        [self sendNetworkFailure];
        return TRUE;
    }
    if(!useHttpSender_) //只有Socket时，才需要检查是否已经联接上服务器了
    {
        if(!config.IsServerConnected)
        {
            BOOL ret = NO;
            if(canLoadFromDB_ && (!(config.networkStatus==ReachableNone)))
            {
#ifdef LOGCMDTIME
                ticksForSendReady = [CommonUtil getDateTicks:[NSDate date]];
                ticksForSendTime = [CommonUtil getDateTicks:[NSDate date]];
#endif
                ret = [self sendLocalData];
                if(ret) return ret;
            }
#ifdef LOGCMDTIME
            else
            {
                ticksForSendReady = [CommonUtil getDateTicks:[NSDate date]];
                ticksForSendTime = [CommonUtil getDateTicks:[NSDate date]];
            }
#endif
            if(networkFailureAlert)
            {
                return [self sendNetworkFailure];
            }
            else
            {
                return NO;
            }
        }
        
        if(self.cacheKey)
        {
            NSString * cacheKeyMD5 = [CommonUtil md5Hash:self.cacheKey];
            if(![[FileDataCacheHelper sharedFileDataCacheHelper]isNeedRemoteCall:[self getCMDName] cacheKeyMD5:cacheKeyMD5])
            {
#ifdef LOGCMDTIME
                ticksForSendReady = [CommonUtil getDateTicks:[NSDate date]];
                ticksForSendTime = [CommonUtil getDateTicks:[NSDate date]];
#endif
                return [self sendLocalData];
            }
        }
    }
    
    
    //检查是否需要从DB提取数据,通过超时来实现
    //检查是否在短时间内重发的命令
    CMDs * handler_ = [self getCMDs];
    if([handler_ isRequestDuplicated:self])
    {
#ifdef LOGCMDTIME
        ticksForSendReady = [CommonUtil getDateTicks:[NSDate date]];
        ticksForSendTime = [CommonUtil getDateTicks:[NSDate date]];
        ticksForParse = [CommonUtil getDateTicks:[NSDate date]];
#endif
        return NO;
    }
    CMDSender * sender_ = [handler_ getCurrentSender:useHttpSender_];
    
    ticksForSendReady = [CommonUtil getDateTicks:[NSDate date]];
    //发送命令
    
    if(sender_ && [sender_ sendCMD:self])
    {
#ifdef FULL_REQUEST
        [handler_ incCmdCount];
#endif
        //   1、成功，则加入到已发送队列，准备接收返回的数据
        [handler_ addCMDOPToQueue:YES cmd:self];
        //如果发送后网络中断，这时候超时该如何处理？在再次重发前，超时到了，明显是有问题的。
        //begin timeout
        //        timerOuter_ = PP_RETAIN([NSTimer scheduledTimerWithTimeInterval:TIMEOUT
        //                                                                 target:self
        //                                                               selector:@selector(didTimerOut:)
        //                                                               userInfo:nil
        //                                                                repeats:NO]);
#ifdef LOGCMDTIME
        ticksForSendTime = [CommonUtil getDateTicks:[NSDate date]];
#endif
        return YES;
    }
    else
    {
#ifdef FULL_REQUEST
        [handler_ incCmdFailureCount];
#endif
#ifdef LOGCMDTIME
        ticksForSendTime = [CommonUtil getDateTicks:[NSDate date]];
#endif
        //   2、失败，加入到重发队列，准备重试
        if(self.CMDID!=2 && insert) //心跳不处理
            [handler_ addCMDOPToQueue:NO cmd:self];
    }
    return NO;
}
- (BOOL)sendCMD
{
    return [self sendCMD:delegate_ params:nil insertIntoQueue:retryForFailure_];
}
- (BOOL)sendCMD:(BOOL)insertIntoQueue
{
    return [self sendCMD:delegate_ params:nil insertIntoQueue:insertIntoQueue];
}
- (BOOL)calcArgsAndCacheKey
{
    //
    //需要在子类中处理这一部分内容
    //
    NSLog(@"args:%@",args_);
    return NO;
    
}
//发送本地缓存数据
- (BOOL)sendLocalData
{
    BOOL ret = NO;
    int totalCount = 0;
    NSObject * data = PP_RETAIN([self queryDataFromDB:argsDic_ totalCount:&totalCount]);
    if(!data)
    {
        data = PP_RETAIN([self queryDataFromDB:argsDic_]);
    }
    if(data)
    {
        __block CMDHeader * header = [[CMDHeader alloc]init];
        header.CMDID = CMDID_;
        header.MessageID = MessageID_;
        
        HCCallbackResult * result = [HCCallbackResult new];
        if([data isKindOfClass:[NSArray class]])
        {
            result.List = (NSArray*)data;
            result.TotalCount = totalCount>0?totalCount :(int)result.List.count;
        }
        else if([data isKindOfClass:[HCEntity class]])
        {
            result.Data = (HCEntity *)data;
            result.TotalCount = 1;
        }
        else if([data isKindOfClass:[NSDictionary class]])//如果返回复合结构的数据
        {
            NSDictionary * dic = (NSDictionary *)data;
            if([dic objectForKey:@"list"])
            {
                if([[dic objectForKey:@"list"] isKindOfClass:[NSArray class]])
                {
                    result.List = (NSArray*)[dic objectForKey:@"list"];
                    result.TotalCount = totalCount>0?totalCount :(int)result.List.count;
                }
            }
            if([dic objectForKey:@"data"])
            {
                if([[dic objectForKey:@"data"] isKindOfClass:[HCEntity class]])
                {
                    result.Data = (HCEntity*)[dic objectForKey:@"data"];
                    result.TotalCount = 1;
                }
            }
            NSLog(@"---invalid local data result....%@",NSStringFromClass([data class]));
        }
        result.Args = argsDic_;
        result.Msg = @"";
        result.Code = 0;
        result.IsFromDB = YES;
        header.Data = result;
        
        PP_RELEASE(result);
        
        //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //            [self sendNotification:header];
        //            [self removeFromQueue];
        //            PP_RELEASE(header);
        //        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self sendNotification:header];
            [self removeFromQueue];
            PP_RELEASE(header);
        });
        
        cmdCompleted_ = YES;
        ret = YES;
        
        PP_RELEASE(data);
        //    [self clearTimer];
        //    [self cancelCMD];
        
        
        return ret;
    }
    else
    {
        //return [self sendNetworkFailure];
#ifdef LOGCMDTIME
        ticksForParse = [CommonUtil getDateTicks:[NSDate date]];
#endif
        return ret;
    }
    
}
- (void)removeFromQueue
{
    CMDs * handler_ = [self getCMDs];
    [handler_ removeCMDOP:self];
}
//超时，伪装一个回调
- (void)didTimerOut:(NSTimer *)timer
{
    //如果超时，则从本地加载数据，然后再发送一个超时通知。
    didTimeout_ = YES;
    NSLog(@"sende time out...");
    if([self isQueryFromLocal:argsDic_ networkStatus:[DeviceConfig config].networkStatus])
    {
        NSLog(@"begin send local data");
        [self sendLocalData];
    }
    __block CMDHeader * header = [[CMDHeader alloc]init];
    header.CMDID = CMDID_;
    header.MessageID = MessageID_;
    
    HCCallbackResult * result = [HCCallbackResult new];
    result.Data = nil;
    result.Args = argsDic_;
    result.Msg = ERROR_TIMEOUT;
    result.Code = 2;
    header.Data = result;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sendNotification:header];
        [self removeFromQueue];
        PP_RELEASE(header);
    });
    [[NSNotificationCenter defaultCenter]postNotificationName:NET_CMDTIMEOUT object:nil];
    //    [self sendNotification:header];
    PP_RELEASE(result);
    //    PP_RELEASE(header);
    
    [self clearTimer];
    
    //    [self removeFromQueue];
    
    
    [self cancelCMD];
}
- (void)sendTimerOut
{
    [self didTimerOut:Nil];
}
//网络失败
- (BOOL)sendNetworkFailure
{
    __block CMDHeader * header = [[CMDHeader alloc]init];
    header.CMDID = CMDID_;
    header.MessageID = MessageID_;
    
    HCCallbackResult * result = [HCCallbackResult new];
    result.Data = nil;
    result.Args = argsDic_;
    result.Msg = MSG_NETWORKERROR;
    result.Code = 1;
    header.Data = result;
    cmdCompleted_ = YES;
    
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    //        [self sendNotification:header];
    //        [self clearTimer];
    //        [self removeFromQueue];
    //
    //        [self cancelCMD];
    //        PP_RELEASE(header);
    //    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sendNotification:header];
        [self clearTimer];
        [self removeFromQueue];
        
        [self cancelCMD];
        PP_RELEASE(header);
    });
    
    [[NSNotificationCenter defaultCenter]postNotificationName:NET_CMDTIMEOUT object:nil];
    PP_RELEASE(result);
    
    return YES;
}
- (BOOL)cancelCMD
{
    [self clearTimer];
    if(params_)
    {
        PP_RELEASE(params_);
    }
    if(delegate_)
    {
        PP_RELEASE(delegate_);
    }
    self.CMDCallBack = nil;
    PP_RELEASE(MessageID_);
    
    return YES;
}
- (void)sendNotification:(CMDHeader*)header
{
    [self clearTimer];
    if(header.Data)
    {
        if(!header.Data.Args)
        {
            header.Data.Args = argsDic_;
        }
    }
    if(didTimeout_)
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:NET_CMDTIMEOUT object:nil];
    }
    //block
    DeviceConfig * config = [DeviceConfig config];
    if(config.IsDebugMode)
    {
        //#ifndef __OPTIMIZE__
        if ([header.Data isKindOfClass:[NSDictionary class]]) {
            NSDictionary * dic = (NSDictionary *)header.Data;
            NSLog(@"result back:\n%@\n",dic);
        }
        else if([header.Data respondsToSelector:@selector(toDicionary)])
        {
            NSDictionary * dic = [header.Data toDicionary];
            NSLog(@"result back:\n%@\n",dic);
        }
        else
        {
            NSLog(@"result back:\n%@\n",[header.Data JSONRepresentationEx]);
        }
        //#endif
    }
    if(self.CMDCallBack)
    {
        self.CMDCallBack(header.Data);
    }
    else
    {
        NSString * name = [self getNotificationName];
        //    NSMutableDictionary * dic = [NSMutableDictionary new];
        //    if(header && header.Data && header.Data.Args)
        //    {
        //        [dic setObject:header.Data.Args forKey:@"args"];
        //    }
        //    if(header && header.Data)
        //    {
        //        [dic setObject:header.Data forKey:@"data"];
        //    }
        [[NSNotificationCenter defaultCenter]postNotificationName:name
                                                           object:header.Data
                                                         userInfo:nil];
        //    PP_RELEASE(dic);
        //    cmdCompleted_ = YES;
    }
#ifdef LOGCMDTIME
    if([DeviceConfig config].networkStatus==ReachableNone) return;
    ticksForParse = [CommonUtil getDateTicks:[NSDate date]];
    NSLog(@"ticks for cmd:%@,create:%li,ready:%li,send:%li,parse:%li",NSStringFromClass([self class]),ticksForBegin - ticksForCreated,ticksForSendReady - ticksForBegin,ticksForSendTime - ticksForSendReady,ticksForParse - ticksForSendTime)
    CMDLog * log = [[CMDLog alloc]init];
    log.CMDID = self.CMDID;
    log.CMDName = NSStringFromClass([self class]);
    log.BytesSend = self.bytesSend;
    log.BytesReceived = self.bytesReceived;
    log.CreateTicks = (int)(ticksForBegin - ticksForCreated);
    log.ReadyTicks = (int)(ticksForSendReady - ticksForBegin);
    log.SendTicks = (int)(ticksForSendTime - ticksForSendReady);
    log.ParseTicks = (int)(ticksForParse - ticksForSendTime);
    log.DateCreated = [CommonUtil stringFromDate:[NSDate date]];
    [self logCMD:log];
#endif
}
#ifdef LOGCMDTIME
- (void)    logCMD:(CMDLog *)log
{
    if(log.CMDID == 900) return;
    if([DeviceConfig config].networkStatus==ReachableNone) return;
    CMD_LOGTIME * cmd = (CMD_LOGTIME *)[[CMDs sharedCMDs]createCMDOP:@"LOGTIME"];
    cmd.log = log;
    [cmd sendCMD];
}
#endif
- (BOOL) isQueryFromLocal:(NSDictionary *)params networkStatus:(NetworkStatus)status
{
    //默认从服务器上读取数据
    if(status==ReachableNone)
        return YES;
    else
        return NO;
}
- (void)forceLoadFromNet
{
    canLoadFromDB_ = NO;
}
#pragma mark - query from db
//取原来存在数据库中的数据，当需要快速响应或者网络不通时
- (NSObject *) queryDataFromDB:(NSDictionary *)params
{
    //
    //需要在子类中处理这一部分内容
    //
    
    return nil;
}
- (NSObject *) queryDataFromDB:(NSDictionary *)params totalCount:(int *)totalCount
{
    //
    //需要在子类中处理这一部分内容
    //
    
    return nil;
}

#pragma mark - parse
- (HCCallbackResult *) parseResult:(NSDictionary *)result
{
    //
    //需要在子类中处理这一部分内容
    //
    
    return nil;
}
- (NSObject*)parseData:(NSDictionary *)result
{
    //
    //需要在子类中处理这一部分内容
    //
    
    return nil;
}
- (NSString *) preParseData:(NSString *)responseString
{
    //    NSString *testString = [[responseString substringFromIndex:[responseString length] -5 ]
    //                                    stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
    //    return testString;
    return responseString;
}
#pragma mark - public funs
//- (int)userID
//{
//    return [[CMDs sharedCMDs]userID];
//}
//- (NSString *)mobile
//{
//    return [[CMDs sharedCMDs]mobile];
//}
//- (NSString *)userName
//{
//    return [[CMDs sharedCMDs]userName];
//}
//- (int) hotelID
//{
//    return [[CMDs sharedCMDs]hotelID];
//}
- (int)pageIndex
{
    return pageIndex_;
}
- (int)pageSize
{
    return pageSize_;
}
- (NSDictionary*)argsDic
{
    return argsDic_;
}
- (NSString *)refer
{
    return nil;
}
- (NSString *)UA
{
    return nil;
}
#pragma mark - dealloc

- (void)clearTimer
{
    if(timerOuter_)
    {
        [timerOuter_ invalidate];
        timerOuter_ = nil;
    }
}
- (void)dealloc
{
    [self clearTimer];
    self.CMDCallBack = nil;
    PP_RELEASE(args_);
    PP_RELEASE(MessageID_);
    PP_RELEASE(delegate_);
    PP_RELEASE(params_);
    PP_RELEASE(argsDic_);
    PP_RELEASE(argsHash_);
    PP_RELEASE(resultMD5);
    PP_RELEASE(requestUrl_);
    
    PP_SUPERDEALLOC;
}
@end

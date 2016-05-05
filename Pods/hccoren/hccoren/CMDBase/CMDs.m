//
//  CMDs.m
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-4.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "CMDs.h"
//#import "Common.h"
#import "CommonUtil.h"
#import "CommonUtil(Date).h"

#import "CMDHeader.h"
#import "CMDOP.h"
#import "CMDSocketSender.h"
#import "DeviceConfig.h"
//#import "Socketsingleton.h"
//#import "SystemConfiguration.h"
//#if HttpSenderViaASI
#import "CMDHttpSenderNew.h"
//#else
//#import "CMDHttpSenderByAFN.h"
//#endif
@implementation CMDs
@synthesize responseString; //返回结果:String
@synthesize responseStream; //返回结果:NSData
//@synthesize DisconnectByUser;
SYNTHESIZE_SINGLETON_FOR_CLASS_NEW(CMDs)
//通过子类继承的对像取代原来的对像，可以通过多个不同层级的静态构造类指向同样的地址
+ (void)setInstance:(CMDs *)instance
{
    if(instance && [instance isKindOfClass:[CMDs class]])
    {
        if(sharedCMDs)
        {
            PP_RELEASE(sharedCMDs);
        }
        sharedCMDs = PP_RETAIN(instance);
    }
}
- (id)init
{
    if(self = [super init])
    {
        cmdQueue_ = [[NSMutableArray alloc]initWithCapacity:100];
        cmdQueueSended_ = [[NSMutableArray alloc]initWithCapacity:200];
        config_ = PP_RETAIN([DeviceConfig Instance]);
        isSending_ = NO;
        
        [self addObserver:self forKeyPath:@"responseString" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"responseStream" options:NSKeyValueObservingOptionNew context:nil];
        
        //每隔5秒处理一下缓存的发送列表
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(senderTimer) userInfo:nil repeats:NO];
        
        socketSender_ = [CMDSocketSender sharedCMDSocketSender];
        
//#if HttpSenderViaASI
        httpSender_ = [CMDHttpSenderNew sharedCMDHttpSenderNew];
//#else
//        httpSender_ = [CMDHttpSenderByAFN sharedCMDHttpSenderByAFN];
//#endif
        
#ifdef FULL_REQUEST
        cmdCount_ = 0;
        cmdFailureCount_ = 0;
        
#endif
    }
    return self;
}
- (void)setHeaderClass:(Class)classA
{
    headerClass_ = classA;
}
#pragma mark - connection info
- (void)connectedToServer:(id)sender
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(CMDs:didConnected:)])
    {
        [self.delegate CMDs:self didConnected:sender];
    }
}
- (void)disconnectedFromServer:(id)sender
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(CMDs:didDisConnected:)])
    {
        [self.delegate CMDs:self didDisConnected:sender];
    }
    [self clearQueues];
}
#pragma mark - getcurrentsender
- (CMDSender*)getCurrentSender:(BOOL)isHttpRequest
{
    if(isHttpRequest)
        return httpSender_;
    else
        return socketSender_;
}
- (CMDOP *)createCMDOPByID:(int)CMDID
{
    Class  op = nil;
    NSString * className = [NSString stringWithFormat:@"CMD_%@",
                            [CommonUtil leftFillZero:[NSString stringWithFormat:@"%d",CMDID] withLength:4]];
    op = NSClassFromString(className);
    if(!op)
    {
        NSLog(@"--xx- create op :%@ failure.",className);
        return nil;
    }
    else
    {
        return PP_AUTORELEASE([[op alloc]init]);
    }
}
- (CMDOP *)createCMDOP:(NSString *)CMDName
{
    Class  op = nil;
    NSString * className = [NSString stringWithFormat:@"CMD_%@",
                            CMDName];
    op = NSClassFromString(className);
    if(!op)
    {
        NSLog(@"--xx- create op :%@ failure.",className);
        return nil;
    }
    else
    {
        return PP_AUTORELEASE([[op alloc]init]);
    }
}

- (CMDOP *)getCMDOP:(int)CMDID messageID:(NSString *)messageID
{
    CMDOP * ret = nil;
    for (CMDOP * op in cmdQueueSended_) {
        if([op isMatch:CMDID messageID:messageID])
        {
            ret = op;
            break;
        }
    }
    if(!ret)
    {
        for (CMDOP * op in cmdQueue_) {
            if([op isMatch:CMDID messageID:messageID])
            {
                ret = op;
                break;
            }
        }
    }
    return ret;
}
//反复处理队列中的数据
- (void)senderTimer
{
    if(isSending_)
    {
        NSLog(@"sending.... return...");
        return;
    }
    isSending_ = YES;
    @synchronized(self)
    {
        BOOL isOK = YES;
        if([cmdQueue_ count]>0 ||cmdQueueSended_.count>0)
        {
            NSLog(@"cmd queue count:%d not callback:%d",(int)[cmdQueue_ count],(int)[cmdQueueSended_ count]);
        }
        //超过了，则移除前30个
        if(cmdQueue_.count >50)
        {
            [self reset];
            [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(senderTimer) userInfo:nil repeats:NO];
            return;
        }
        BOOL hasSendNetFailure = NO;
        
        BOOL needSocket = NO;
        if(!config_.IsServerConnected)
        {
            for (CMDOP * op in cmdQueue_) {
                if(![op useHttpSender])
                {
                    needSocket = YES;
                    break;
                }
            }
            if(!needSocket)
            {
                for (CMDOP * op in cmdQueueSended_) {
                    if(![op useHttpSender])
                    {
                        needSocket = YES;
                        break;
                    }
                }
            }
        }
        //将发送失败的重发
        if(config_.IsServerConnected || !needSocket)
        {
            
            while([cmdQueue_ count]>0 && isOK)
            {
                CMDOP * dic = PP_RETAIN((CMDOP *)[cmdQueue_ objectAtIndex:0]);
                [cmdQueue_ removeObjectAtIndex:0];
                if(! [dic needRemoved])
                {
                    dic.retryTimes ++;
                    isOK = [dic sendCMD:NO];//不需要再加入到队列中
                    
                    if(!isOK){
                        [self addCMDOPToQueue:NO cmd:dic];
                        PP_RELEASE(dic);
                        break;
                    }
                }
                //如果重试多次，则需要处理关于网络错误的信息
                else if(dic.retryTimes >= dic.maxRetryTimes)
                {
                    if(hasSendNetFailure)
                    {
                        [dic cancelCMD];
                    }
                    else
                    {
                        [dic sendNetworkFailure];
                        hasSendNetFailure = YES;
                    }
                }
                PP_RELEASE(dic);
            }
        }
        if(!isOK || (!config_.IsServerConnected && needSocket))
        {
            [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(senderTimer) userInfo:nil repeats:NO];
            isSending_ = NO;
            //重联服务器
//            if(!config_.IsServerConnected && needSocket)
//            {
//                [self connectToServer:nil];
//                //            [(Socketsingleton*)[Socketsingleton sharedSocketsingleton] connectToServer:];
//            }
            return;
        }
        
        //将未收到结果的命令重发
        if([cmdQueueSended_ count]>0)
        {
            long nowticks =[CommonUtil getDateTicks:[NSDate date]];
            isOK = YES;
            
            int i = 0;
            NSMutableArray * sendedTemp = [[NSMutableArray alloc]initWithCapacity:cmdQueueSended_.count];
            [sendedTemp addObjectsFromArray:cmdQueueSended_];
            [cmdQueueSended_ removeAllObjects];
            
            while (i<sendedTemp.count && isOK) {
                CMDOP * dic = PP_RETAIN([sendedTemp objectAtIndex:i]);
                NSInteger ticks = dic.ticksForSendReady;
                if(nowticks - ticks >= 30000) //30s
                {
                    NSString * messageID = dic.messageID;
                    if(messageID && messageID.length>0)
                    {
                        //                        [messageDic removeObjectForKey:[NSString stringWithFormat:@"request-%@",messageID]];
                        //                        [messageDic removeObjectForKey:[NSString stringWithFormat:@"rs-%@",messageID]];
                        //                        [messageDic removeObjectForKey:messageID];
                    }
                    //                    [sendedTemp removeObjectAtIndex:i];
                    if(! [dic needRemoved])
                    {
                        isOK = [dic sendCMD];
                        
                        if(isOK) //发送成功，也需要增加重试次数
                        {
                            int retryTimes = dic.retryTimes;
                            retryTimes ++;
                            //超过次数，则需要处理网络或者将命令取消
                            if(retryTimes>=dic.maxRetryTimes)
                            {
                                [dic sendTimerOut];
                            }
                            else
                            {
                                dic.ticksForSendReady = nowticks;
                                dic.retryTimes = retryTimes;
                                ////已经在发送时添加到队列中，所以这里不需要加。
                                //                                [cmdQueue_ addObject:dic];
                                
                            }
                        }
                        //                        else
                        //                        {
                        //                            //已经在发送时添加到队列中，所以这里不需要加。
                        ////                            [cmdQueueSended_ addObject:dic];
                        //                        }
                    }
                    i++;
                }
                else
                {
                    [cmdQueueSended_ addObject:dic];
                    i++;
                }
                PP_RELEASE(dic);
            }
            PP_RELEASE(sendedTemp);
            if(cmdQueueSended_.count==0 && cmdQueue_.count==0)
            {
                //                [self clearObservers];
            }
            //            DLog(@"call not back:%d",[_cmdQueueSended count]);
            if([cmdQueue_ count]==0 ||cmdQueueSended_.count==0)
            {
                NSLog(@"cmd queue count:%d not callback:%d",(int)[cmdQueue_ count],(int)[cmdQueueSended_ count]);
            }
        }
        [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(senderTimer) userInfo:nil repeats:NO];
    }
    isSending_ = NO;
}
#pragma mark - call back
////监听socket传来的数据，有变化即解析传值给mydata
////EncryptMethod	1	Uint8
////协议版本序号	2	Uint8
////命令号	4	Uint8
////MessageId	16	Uint8
////Code	1	Uint8
////SecretCode	8	Byte
////Body_SIZE	8	Uint8
//-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//    if ([keyPath isEqual: @"responseStream"])
//    {
//        @synchronized(self){
//#ifdef FULL_REQUEST
//            DLog(@"response Stream received...")
//#endif
//            //            NSAutoreleasePool * pool = [[NSAutoreleasePool alloc]init];
//            PP_BEGINPOOL(pool);
//            NSString *result = [[NSString alloc] initWithData:responseStream encoding:NSUTF8StringEncoding];
//#ifdef FULL_REQUEST
//            DLog(@"response stream:%@",result);
//#else
//            if(result.length>160)
//            {
//                NSLog(@"response stream:%@..(%ld bytes)..%@",[result substringToIndex:150],result.length - 160,[result substringFromIndex:result.length-10]);
//            }
//            else
//            {
//                NSLog(@"response stream:%@",result);
//            }
//#endif
//            if([result length]>=SOCKETHEADLEN + SOCKETPACKAGELEN){
//                
//                CMDHeader * header = [[headerClass_ alloc]initWithString:result];
//                if(header.CMDID==0)
//                {
//                    DLog(@"no cmdid:%@",result);
//                }
//                else
//                {
//                    CMDOP * op = nil;
//                    //从服务器端主动发起的请求
//                    if(header.CMD && header.CMD.CMDID>0)
//                    {
//                        op = PP_RETAIN(header.CMD);
//                    }
//                    else
//                    {
//                        op = PP_RETAIN([self getCMDOP:header.CMDID messageID:header.MessageID]);
//                    }
//                    if(op.CMDID==154 || op.CMDID==170)
//                    {
//                        //                        op.CMDID = ;
//                        NSLog(@"154    >>>>> 170");
//                    }
//                    if(op)
//                    {
//                        [self removeCMDOP:op];
//                        [header parseResult];
//                        [op sendNotification:header];
//                        [op cancelCMD];
//                        PP_RELEASE(op);
//                    }
//                    else
//                    {
//                        [header parseResult];
//                        [self sendNoMatchedCMD:header];
//                    }
//                    
//                }
//                PP_RELEASE(header);
//            }
//            else
//            {
//                DLog(@"---- incorrect callback:%@",result);
//            }
//            PP_RELEASE(result);
//            PP_ENDPOOL(pool);
//            //            [pool drain];
//        }
//    }
//    else if([keyPath isEqualToString:@"responseString"])
//    {
//        @synchronized(self){
//            NSString *result =  responseString;
//            
//#ifdef FULL_REQUEST
//            DLog(@"response String received...");
//            DLog(@"response String:%@",result);
//#endif
//            
//            CMDHeader * header = [[headerClass_ alloc]initWithString:result];
//            if(header.CMDID==0)
//            {
//                DLog(@"no cmdid:%@",result);
//            }
//            else
//            {
//                CMDOP * op =nil;
//                //从服务器端主动发起的请求
//                if(header.CMD && header.CMD.CMDID>0)
//                {
//                    op = PP_RETAIN(header.CMD);
//                }
//                else
//                {
//                    op = PP_RETAIN([self getCMDOP:header.CMDID messageID:header.MessageID]);
//                }
//                //                if(op.CMDID==105)
//                //                {
//                //                    op.CMDID = 105;
//                //                }
//                if(op)
//                {
//                    [self removeCMDOP:op];
//                    [header parseResult];
//                    [op sendNotification:header];
//                    
//                    [op cancelCMD];
//                    PP_RELEASE(op);
//                }
//                else
//                {
//                    [header parseResult];
//                    [self sendNoMatchedCMD:header];
//                }
//                PP_RELEASE(op);
//                
//            }
//            PP_RELEASE(header);
//        }
//    }
//}
- (void)sendNoMatchedCMD:(CMDHeader *)header
{
    return;
}
#pragma mark - queue manager
#ifdef FULL_REQUEST
- (int)cmdSendedCount
{
    return cmdCount_;
}
- (void)incCmdCount
{
    cmdCount_ ++;
}
- (void)incCmdFailureCount
{
    cmdFailureCount_ ++;
}
- (int)cmdSendFailureCount
{
    return cmdFailureCount_;
}
#endif
- (int)queueLength
{
    return (int)(cmdQueue_.count+cmdQueueSended_.count);
}
- (void)addCMDOPToQueue:(BOOL)sendOK cmd:(CMDOP*)cmd
{
    if(sendOK)
    {
        [cmdQueueSended_ addObject:cmd];
    }
    else
    {
        [cmdQueue_ addObject:cmd];
    }
}
- (void)removeCMDOP:(CMDOP *)cmdOP
{
    [cmdQueue_ removeObject:cmdOP];
    [cmdQueueSended_ removeObject:cmdOP];
}
- (void)removeCMDOP:(int)cmdID messageID:(NSString *)messageID
{
    CMDOP * op = [self getCMDOP:cmdID messageID:messageID];
    if(op)
        [self removeCMDOP:op];
}
- (BOOL)isRequestDuplicated:(CMDOP *)cmdOP
{
    //检查是否有刚发送但没有回来的信息，如果有，则不需要重发。这里需要检查Args和CMD是否一致。
    //要注意，如果是生发消息，则不能调用此方法，否则会认为消息全部已经发过，会跳过发送过程。
    @synchronized(self)
    {
        BOOL isExists = NO;
        for (CMDOP * dic in cmdQueue_) {
            if(dic ==cmdOP || [dic isMatch:cmdOP.CMDID args:cmdOP.args])
            {
                isExists = YES;
                break;
            }
        }
        if(isExists) return YES;
        
        //check 是否刚刚发过了
        for (CMDOP *  dic in cmdQueueSended_) {
            if(dic ==cmdOP || [dic isMatch:cmdOP.CMDID args:cmdOP.args])
            {
                isExists = YES;
                break;
            }
        }
        if(isExists) return YES;
    }
    return NO;
}
#pragma mark - publicsource
- (NSString *)getCurrentTimeForMessageID
{
    @synchronized(self) {
        NSDate *cTime = [NSDate date];
        
        if(!dFormatForMessageID_)
        {
            dFormatForMessageID_ = [[NSDateFormatter alloc] init];
            [dFormatForMessageID_ setDateFormat:@"HHmmssFFF"];
        }
        
        NSString *timestring = [dFormatForMessageID_ stringFromDate:cTime];
        //	NSString * timestring1 = [timestring substringToIndex:4];//hhmmss   获取前4个
        //    NSString * timestring2 = [timestring1 substringToIndex:2];//获取前四个的前两个   //小时
        //    NSString * timestring3 = [timestring1 substringFromIndex:2];//获取前四个的后两个    //分钟
        //    NSString * timestring4 = [timestring substringWithRange:NSMakeRange(4, 2)];//获取秒
        //    NSString * miniSeconde = [timestring substringFromIndex:6];
        //    int hnum = [timestring2 intValue];
        //    int mnum = [timestring3 intValue];
        //    int snum = [timestring4 intValue];
        //    int timenum = (hnum*60*60+mnum*60+snum)*1000 +[miniSeconde intValue];
        //    //    NSString * second = [NSString stringWithFormat:@"%x",timenum];
        //    int miniseconds = [CommonUtil getDateTicks:cTime];
        int timenum = [timestring intValue]*10 +cmdOrder_;
        //防止一个毫秒内发送多个命令，则导致MessageID相同
        @synchronized(self)
        {
            while (timenum==lastMessageID_)
            {
                cmdOrder_ ++;
                timenum += cmdOrder_;
            }
            if(cmdOrder_>=10)
            {
                cmdOrder_ = 0;
            }
            lastMessageID_ = timenum;
        }
        NSString * second1 = [CommonUtil toHEXstring:timenum];
        NSString * result = [CommonUtil leftFillZero:second1 withLength:8];
        return result;
    }
}
//- (int)userID
//{
//#ifdef IS_MANAGERCONSOLE
//    SystemConfiguration * config = [SystemConfiguration sharedSystemConfiguration];
//    return config.loginUserID;
//#else
//    SystemConfiguration * config = [SystemConfiguration sharedSystemConfiguration];
//    if(config && config.User!=nil)
//        return config.User.UserID;
//    else
//        return 0;
//#endif
//
//}
//- (NSString *)mobile
//{
//    SystemConfiguration * config = [SystemConfiguration sharedSystemConfiguration];
//    if(config && config.User!=nil)
//        return config.User.Mobile;
//    else
//        return nil;
//
//}
//- (NSString *)userName
//{
//    SystemConfiguration * config = [SystemConfiguration sharedSystemConfiguration];
//    if(config && config.User!=nil)
//        return config.User.UserName;
//    else
//        return nil;
//}
//- (int)hotelID
//{
//#ifdef IS_MANAGERCONSOLE
//    SystemConfiguration * config = [SystemConfiguration sharedSystemConfiguration];
//    return config.hotelID;
//#else
//    SystemConfiguration * config = [SystemConfiguration sharedSystemConfiguration];
//    if(config && config.User!=nil)
//        return config.User.HotelID;
//    else
//        //        return config.hotelID;
//        return 0;
//#endif
//}
#pragma mark - connect to server
//- (void)        disconnectToServer
//{
//    Socketsingleton * ton = [Socketsingleton sharedSocketsingleton];
//    ton.DisconnectByUser = YES;
//    [ton disconnectToMina];
//}
//- (BOOL)        connectToServer:(id<HCNetworkDelegate>)delegate
//{
//    Socketsingleton * ton = [Socketsingleton sharedSocketsingleton];
//    ton.DisconnectByUser = NO;
//    return [ton connectToServer:delegate CMDs:self];
//}
#pragma mark - dealloc
- (void)clearQueues
{
    [cmdQueue_ removeAllObjects];
    [cmdQueueSended_ removeAllObjects];
}
- (void)reset
{
    isSending_ = NO;
    [self clearQueues];
}
- (void)dealloc
{
    //释放监听者
    [self removeObserver:self forKeyPath:@"responseStream"];
    [self removeObserver:self forKeyPath:@"responseString"];
    
    //    PP_RELEASE(headerClass_);
    PP_RELEASE(cmdQueue_);
    PP_RELEASE(cmdQueueSended_);
    PP_RELEASE(socketSender_);
    PP_RELEASE(httpSender_);
    PP_RELEASE(config_);
    PP_RELEASE(dFormatForMessageID_);
    
    self.responseStream = nil;
    self.responseString = nil;
    
    PP_SUPERDEALLOC;
}

#pragma mark - base cmds
- (void)heartBeat
{
    //子类重写
}
@end

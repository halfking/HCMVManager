//
//  Socketsingleton.m
//  酒店云
//
//  Created by Suixing on 12-8-10.
//  Copyright (c) 2012年 杭州随行网络信息服务有限公司. All rights reserved.
//
//#import "PublicValues.h"
#import "HCBase.h"
#import "Socketsingleton.h"
#import "AsyncSocket.h"
//#import "CMDHelper.h"
#import "CMDs.h"
#import "UIDevice_Reachability.h"
//#include "SystemConfiguration.h"
#import "HCSendRequest.h"
//#import "PageBase(Windows).h"
#import "RegexKitLite.h"
#import "JSON.h"
#import <netdb.h>
#include <arpa/inet.h>
#import <sys/socket.h>
//#import "CMDDelegate.h"
#import "DeviceConfig.h"
#import "HCSocketBuffer.h"
#import "Reachability.h"
@interface Socketsingleton() <AsyncSocketDelegate>
{
    NSString * server;
    BOOL DisconnectByUser;
    
    HCSocketBuffer * _Buffer;
    BOOL isConnnection_;
    BOOL isIniting_; //是否正在初始化
    int showNoNetCount_; //显示没有网络的信息的次数，在网络未变情况下，不得超过2次
    
    int connectRequestCount_;//网络重联次数
    BOOL showConnectting_;  //是否显示正在联接信息
    
    Reachability * reachalility_;
    CMDs * cmds_;
}
@end
@implementation Socketsingleton
@synthesize  asyncSocket = asyncSocket_;
@synthesize DisconnectByUser;
@synthesize IsInited;
@synthesize isConnnection_;

static int webCount = 0;
//纪录在一次处理中，是否已经显示了网络的信息。回调可能有多次，但是只能显示一次。
static BOOL alertIsShow = FALSE;

SYNTHESIZE_SINGLETON_FOR_CLASS_NEW(Socketsingleton)
-(id)init{
    self = [super init];
    if(self)
    {
        _Buffer = [[HCSocketBuffer alloc]init];
        self.delegate = nil;
        isConnnection_ = NO;
        showConnectting_ = YES;
        cmds_ = nil;
        [NSThread detachNewThreadSelector:@selector(initNetwork) toTarget:self withObject:nil];
    }
    
    return self;
}
-(void) firstConnect
{
    NSLog(@"firstconnect...");
    DeviceConfig * information = [DeviceConfig Instance];
    if([self connectServer:information.HOST_IP1 port:information.HOST_PORT1]!=SRV_CONNECT_FAIL)
    {
        information.IsServerConnected = YES;
//        information.NetworkRechablility = YES;
    }
    
    
    self.DisconnectByUser = NO;
}
- (void)resetInitStatus
{
    isIniting_  = NO;
}
- (void) initNetwork
{
    if(isIniting_) return;
    isIniting_ = YES;
    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(resetInitStatus) userInfo:nil repeats:NO];
//    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    NSLog(@"首次初始化");
    
//    UIDevice * uidevice = PP_RETAIN([UIDevice currentDevice]);
    
#if REMOTESERVER
    DeviceConfig * information = [DeviceConfig Instance];
    NSString * hostip = [uidevice getIPAddressForHost:CT_HOSTNAME];
    //NSString * hostip2 = [hostip copy];
    if(!hostip||[hostip rangeOfRegex:@"0\\.0\\.0\\.0"].length>0)
    {
        NSLog(@"HOST:%@ cannot reachable.",CT_HOSTNAME);
        information.HOST_IP1 = CT_HOSTIP;
    }
    else
    {
        information.HOST_IP1 = hostip;
    }
#endif
    
    self.IsInited = TRUE;
    isIniting_ = NO;
    
    [self openReachalibity];
    
    //因为异步SOcket 需要从主线程中发起。
    [self performSelectorOnMainThread:@selector(firstConnect) withObject:self waitUntilDone:FALSE];
//    PP_RELEASE(uidevice);
//    [uidevice release];
    //    [information release];
    
//    [pool drain];
}
-(void)changeConnectionStatus
{
    isConnnection_ = NO;
}
-(int)connectServer:(NSString *)hostIP port:(long)hostPort
{
    NSLog(@"正在连接");
    if(isConnnection_) return SRV_CONNECTING;
    isConnnection_ = YES;
    [NSTimer scheduledTimerWithTimeInterval:RECONNECT_TIMEOUT
                                     target:self
                                   selector:@selector(changeConnectionStatus)
                                   userInfo:nil repeats:NO];
    //如果Socket不在或者没有连接，重新连接
    @try {
        if (!asyncSocket_ || [asyncSocket_ isConnected]==NO)
        {
            if(asyncSocket_)
            {
                PP_RELEASE(asyncSocket_);
            }
            
            asyncSocket_ = PP_RETAIN([[AsyncSocket alloc]initWithDelegate:self]);
            NSError * err = nil;
            NSLog(@"ready to connect %@:%li",hostIP,hostPort);
            
            @try {
                if (![asyncSocket_ connectToHost:hostIP onPort:hostPort error:&err])
                {
                    
                    NSLog(@"%@",[err localizedDescription]);
                    NSString * temp = [[NSString alloc]initWithFormat:@"%@",[err localizedDescription]];
                    NSString * message =[temp stringByAppendingString:[err localizedDescription]];
                    
                    PP_RELEASE(temp);
//                    [temp release];
                    PP_RELEASE(err);
                    
                    
                    [self removeSocket];
                    
                    NSMutableDictionary * dic = [[NSMutableDictionary alloc]
                                                 initWithObjectsAndKeys:[MSG_CONNECTERROR stringByAppendingString:hostIP],@"title",
                                                 message,@"msg",nil];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"CONNECTION_ERROR"
                                                                        object:self userInfo:dic];
                    PP_RELEASE(dic);
//                    [dic release];
                    //                [self showAlertN:[MSG_CONNECTERROR stringByAppendingString:hostIP] message:message];
                    //                    isConnnection_ = NO;
                    return SRV_CONNECT_FAIL;
                }else
                {
                    [asyncSocket_ readDataWithTimeout:-1 tag:0];
                    //                    isConnnection_ = NO;
                    return SRV_CONNECT_SUC;
                }
            }
            @catch (NSException *exception) {
                [self removeSocket];
                NSLog(@"connect exception:%@",[exception description]);
                
                
            }
            @finally {
                
            }
            //            isConnnection_ = NO;
            return SRV_CONNECT_SUC;
        }
        else
        {
            
            [asyncSocket_ readDataWithTimeout:-1 tag:0];
            //            isConnnection_ = NO;
            return  SRV_CONNECTED;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Connect error:%@",[exception description]);
    }
    @finally {
        //        isConnnection_ = NO;
    }
    return SRV_CONNECT_FAIL;
}
-(void)showAlertN:(NSString *)title message:(NSString *)message
{
    NSMutableDictionary * dic = [[NSMutableDictionary alloc]init];
    [dic setObject:message forKey:@"msg"];
    [dic setObject:title forKey:@"title"];
    [[NSNotificationCenter defaultCenter]postNotificationName:NT_MSGCENTER
                                                       object:dic];
    PP_RELEASE(dic);
}
#pragma mark - AsyncSocketDelegate method
//AsyncSocket创建了新的Socket用于处理和客户端的请求，如果这个新socket实例你不打算保留（retain），那么将拒绝和该客户端 连接
- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
    if (!asyncSocket_)
    {
        asyncSocket_ = PP_RETAIN(newSocket);
        NSLog(@"did accept new socket");
    }
}
//提供线程的runloop实例给AsyncSocket，后者将使用这个runloop执行socket通讯的操作
- (NSRunLoop *)onSocket:(AsyncSocket *)sock wantsRunLoopForNewSocket:(AsyncSocket *)newSocket
{
    NSLog(@"wants runloop for new socket.");
    return [NSRunLoop currentRunLoop];
}
//将要建立连接，这时可以做一些准备工作，如果需要的话
- (BOOL)onSocketWillConnect:(AsyncSocket *)sock
{
    NSLog(@"will connect");
    connectRequestCount_ ++;
    if(!showConnectting_) return YES;
    [[NSNotificationCenter defaultCenter]postNotificationName:NET_CONNECTING object:nil];
//    UIViewController * vc = [UIApplication sharedApplication].keyWindow.rootViewController;
//    if(vc)
//    {
//        SEL selector = NSSelectorFromString(@"showProgressHUDWithMessage:");
//        if([vc respondsToSelector:selector])
//        {
//            [vc performSelector:selector
//                       onThread:[NSThread mainThread]
//                     withObject:MSG_CONNECTING
//                  waitUntilDone:YES];
//        }
//    }
    
    return YES;
}
//连接了服务器
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    DeviceConfig * info = [DeviceConfig Instance];
    info.IsServerConnected  = YES;
    isConnnection_ = NO;
    showConnectting_ = YES;
    if(reachalility_)
    {
//        [DeviceConfig setCurNetType:(NetworkType)[reachalility_ currentReachabilityStatus]];
        if(info.IPAddress && info.IPAddress.length>0 && [info.IPAddress rangeOfString:@","].length==0)
        {
//            NSString * ip = [reachalility_ whatismyipdotcom];
//            if(ip && [ip rangeOfString:@"no"].length==0)
//            {
//                NSString * temp = [NSString stringWithFormat:@"%@%@%@",info.IPAddress,
//                                   info.IPAddress.length>0?@",":@"",
//                                   ip];
//                info.IPAddress = temp;
//            }
        }
        PP_RELEASE(reachalility_);
    }
    NSLog(@"onSocket:%p didConnectToHost:%@ port:%hu",sock,host,port);
    [asyncSocket_ readDataWithTimeout:-1 tag:0];
    //检查是否有队列，有逐个发送,暂时不处理
    if(self.delegate!=nil)
    {
        if([self.delegate respondsToSelector:@selector(netPrepared)])
        {
            [self.delegate performSelector:@selector(netPrepared)];
        }
        [self clearDelegate];
    }
    [_Buffer clearData];
    //     
    if(cmds_)
        [cmds_ connectedToServer:asyncSocket_];
    else
        [[CMDs sharedCMDs]connectedToServer:asyncSocket_];
    //    [CMDs deviceRegister:[CommonObserver sharedCommonObserver]];
    
    connectRequestCount_ = 0;
    
//将等待窗关闭
    [[NSNotificationCenter defaultCenter]postNotificationName:NET_CONNECTED object:nil];
//    UIViewController * vc = [UIApplication sharedApplication].keyWindow.rootViewController;
//    if(vc)
//    {
//        SEL selector = NSSelectorFromString(@"hideProgressHUD:");
//        if([vc respondsToSelector:selector])
//        {
//            [vc performSelector:selector
//                       onThread:[NSThread mainThread]
//                     withObject:[NSNumber numberWithBool:YES]
//                  waitUntilDone:YES];
//        }
//    }
    
}
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    
    DeviceConfig * info = [DeviceConfig Instance];
    info.IsServerConnected  = NO;
    isConnnection_ = NO;
    if(self.delegate!=nil)
    {
        if([self.delegate respondsToSelector:@selector(netFailure:)])
        {
            [self.delegate performSelector:@selector(netFailure:) withObject:err];
        }
        [self clearDelegate];
    }
    NSLog(@"onSocket:%p willDisconnectWithError:%@", sock, err);
//    [[SystemConfiguration sharedSystemConfiguration] stopHeartBeatByError];
    [self removeSocket];
}
-(void)removeSocket
{
    if(asyncSocket_!=nil )
    {
        if([asyncSocket_ isConnected]==YES)
            [self disconnectToMina];
    }
    DeviceConfig * info = [DeviceConfig Instance];
    info.IsServerConnected  = NO;

    PP_RELEASE(asyncSocket_);
}
#define PACKAGETAIL_LEN 0
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    
//    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc]init];
    if([_Buffer length]==0 && [data length]<SOCKETHEADLEN+SOCKETPACKAGELEN)
    {
        webCount = 0;//连接成功使网络连接计数置0；
        //          socket
        if(cmds_)
            cmds_.responseStream = data;
        else
            [CMDs sharedCMDs].responseStream = data;
        //        CMDHelper * cmdhelper = [CMDHelper sharedCMDHelper];
        //        cmdhelper.socketData = data;
        [asyncSocket_ readDataWithTimeout:-1 tag:0];
        //        NSString* aStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        //        NSLog(@"##1 Have received data is :%@",aStr);
        //        [aStr release];
//        [pool drain];
        return;
    }
    //    NSLog(@"data retaincount:%i",[data retainCount]);
    //    [_Buffer appendBytes:(Byte *)[data bytes] length:[data length]];
    [_Buffer appendData:data];
    //    NSLog(@"data retaincount2:%i",[data retainCount]);
    
    //int packageLen = 0;
    HCBufferStatus status = HCBufferStatusReadOK;
    while (status == HCBufferStatusReadOK) {
        
        NSMutableData * curData = [[NSMutableData alloc]init];
        status = [_Buffer getNextPackage:curData];
        
        //status = [_Buffer getNextPackageBytes:_PackageBuffer length:&packageLen];
        
        if(status!=HCBufferStatusReadOK)
        {
            PP_RELEASE(curData);
            break;
        }
        
        //        NSData * curData = [[NSData alloc]initWithBytes:_PackageBuffer length:packageLen];
        
        
        //        NSLog(@"Have received data is :%@",aStr);
        
        webCount = 0;//连接成功使网络连接计数置0；
        
        //检查是否注册命令，要考虑服务器跳转的问题（负载均衡的问题）
        Byte bytes[4];
        [curData getBytes:bytes range:NSMakeRange(3, 4)];
        if(bytes[0]=='0' && bytes[1]=='0' && bytes[2]=='0' && bytes[3]=='1')//1号指令，注册设备
        {
            NSString* aStr = [[NSString alloc] initWithData:curData encoding:NSUTF8StringEncoding];
            [self parseServerInfo:aStr];
            PP_RELEASE(aStr);
        }
        DeviceConfig * config = [DeviceConfig Instance];
        
        if(config.serverChanged)
        {
            config.serverChanged = NO;
            //清空队列
            if(cmds_)
                [cmds_ clearQueues];
            else
                [[CMDs sharedCMDs] clearQueues];
            [_Buffer clearData];
            
            [[NSNotificationCenter defaultCenter]postNotificationName:NT_RECONNECTSERVER object:nil];
            [self disconnectToMina];
            self.IsInited = YES;
            //重新联接服务器
            [self connectServer:config.HOST_IP1 port:config.HOST_PORT1];
        }
        else
        {
                //          socket
                if(cmds_)
                    cmds_.responseStream = curData;
                else
                    [CMDs sharedCMDs].responseStream = curData;
        }
        PP_RELEASE(curData);
    }
    if(status==HCBufferStatusError)
    {
        //需要重联
        [self removeSocket];
        //        [_Buffer clearData];
        //        //self.DisconnectByUser = NO;
        //        [self disconnectToMina];
        [self connectToServer:self.delegate];
//        [pool drain];
        return;
    }
    
//    [pool drain];
    [asyncSocket_ readDataWithTimeout:-1 tag:0];
    
}
- (void)parseServerInfo:(NSString *)package
{
//#ifndef REMOVESERVER
//    return;
//#endif
    if(package==nil) return;
    if ([package length]>SOCKETHEADLEN +SOCKETPACKAGELEN)
    {
        NSString * subString = [package substringWithRange:NSMakeRange(SOCKETHEADLEN+SOCKETPACKAGELEN,1)];
        if([subString hasPrefix: @"{"] == YES||[subString hasPrefix:@"["]==YES)
        {
            DeviceConfig * information = [DeviceConfig config];
            
            NSString * body = [package substringFromIndex:40];//返回值头有40位
            NSDictionary * dic = PP_RETAIN([body JSONValueEx]);
            if ([dic objectForKey:@"server"]!=nil)//只要服务器ip地址变化就会发送server地址，server地址不为空，则重新用新地址连接新服务器
            {
                server = [dic objectForKey:@"server"];
                if([server rangeOfRegex:@"192\\.168\\."].length==0 )
                {
                    long port  = information.HOST_PORT1;
                    @try {
                        if([dic objectForKey:@"port"]!=nil)
                            port = [[dic objectForKey:@"port"] intValue];
                    }
                    @catch (NSException *exception) {
                        NSLog(@"%@ convert to integer error",[dic objectForKey:@"port"]);
                    }
                    @finally {
                        port = 9000;
                    }
                    if(information.HOST_PORT1!=port ||
                       [information.HOST_IP1 compare:server]!=NSOrderedSame)
                    {
                        information.HOST_IP1 = server;
                        information.HOST_PORT1 = port;
                        information.serverChanged = YES;
                        //到外部联接
                        //                        [self connectServer:server port:information.HOST_PORT1];
                        
                    }
                }
                if ([dic objectForKey:@"uploadserver"]!=nil)
                {
                    information.UploadServer = [dic objectForKey:@"uploadserver"];
                }
                if ([dic objectForKey:@"uploadserverpath"]!=nil)
                {
                    information.UploadServices = [dic objectForKey:@"uploadserverpath"];
                }
                if ([dic objectForKey:@"imageserverpath"]!=nil)
                {
                    information.ImagePathRoot = [dic objectForKey:@"imageserverpath"];
                }
            }
            //接口地址
            if([dic objectForKey:@"baseurl"])
            {
                NSString * str = [dic objectForKey:@"baseurl"];
                if(str.length>3 && [str hasPrefix:@"http://"])
                {
                    information.InterfaceUrl = str;
                }
            }
            //安全码
            if ([dic objectForKey:@"tockencode"]!=nil)
            {
                information.TockenCode = [dic objectForKey:@"tockencode"];
            }
            //            if([dic objectForKey:@"userid"]!=nil)
            //            {
            //                SystemConfiguration * config = [SystemConfiguration sharedSystemConfiguration];
            //                int userID = [[dic objectForKey:@"userid"]intValue];
            //                if(userID >0 &&(config.User == nil || config.User.UserID!= userID))
            //                {
            //                    //如果当前是获取用户信息的方法，则不需要再次进行处理
            //                    if([[dic objectForKey:@"scode"] hasPrefix:@"4.2.0"]==FALSE)
            //                    {
            //                        [config getUserInfoFromServer:userID andHotelID:0];
            //                    }
            //                }
            //            }
            
            //            [information release];
            PP_RELEASE(dic);
        }
    }
}
- (void)onSocket:(AsyncSocket *)sock didSecure:(BOOL)flag
{
    NSLog(@"onSocket:%p didSecure:YES", sock);
}

//发生连接中断时，需要重新建立连接，一旦连接成功，就需要重新向服务器注册
- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    DeviceConfig * info = [DeviceConfig Instance];
    //    info.NetworkRechablility = NO;
    isConnnection_ = NO;
    //断开连接了
    webCount++;
    
    if(self.DisconnectByUser)
    {
        return;
    }
    
    while (webCount <3 && [self needConnectLater])
    {
        int ret =[self connectServer:info.HOST_IP1 port:info.HOST_PORT1];
        
        if(ret==SRV_CONNECT_FAIL)
        {
            NSLog(@"connect failure!");
        }
        else if(ret==SRV_CONNECTING)
        {
            NSLog(@"another connection...,current cancelled.");
        }
        else
        {
            //NSLog(@"connect success!");
            //info.NetworkRechablility = YES;
            break;
        }
        webCount++;
    }
    
    if(webCount >=3|| (![self needConnectLater]))
    {
        info.IsServerConnected = NO;
        [self openReachalibity];
        [self removeSocket];
    }
    //    [info release];
}
-(void)openReachalibity
{
    //开启网络状况的监听
    if(!reachalility_)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name: kReachabilityChangedNotification
                                                   object: nil];
        reachalility_ = PP_RETAIN([Reachability reachabilityWithHostName:@"http://www.baidu.com"]);
        [reachalility_ startNotifier];
    }
}

//-(void)showMessage:(id)sender msg:(NSString *)msg
//{
//    if(sender!=nil)
//    {
//        PP_RELEASE(sender);
//    }
//    [self showAlert:MSG_TITLE message:msg];
//
//}


- (void) reachabilityChanged: (NSNotification* )note
{
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
    [self updateInterfaceWithReachability: curReach];
}
//处理连接改变后的情况
- (void) updateInterfaceWithReachability: (Reachability*) curReach
{
    DeviceConfig * info = [DeviceConfig Instance];
    
    //对连接改变做出响应的处理动作。
    NetworkStatus status = [curReach currentReachabilityStatus];
    if (status == ReachableNone)
    {
        self.IsInited = FALSE;
        info.IsServerConnected = NO;
        //没有连接到网络就弹出提实况
        if(alertIsShow==FALSE)
        {
            alertIsShow = TRUE;
            if(showNoNetCount_ <2)
            {
//                [self showAlertN:APPNAME message:MSG_NETWORKERROR];
                showNoNetCount_ ++;
            }
            alertIsShow = FALSE;
        }
    }
    else
    {
        info.IsServerConnected = YES;
//        [DeviceConfig setCurNetType:(NetworkType)status];
        
        alertIsShow = FALSE;
        showNoNetCount_ = 0;
        if(![self connectToServer:self.delegate])
        {
            NSLog(@"reconnect .....add data to queue...cancelled...");
        }
//        if(info.IPAddress && info.IPAddress.length>0 && [info.IPAddress rangeOfString:@","].length==0)
//        {
//            NSString * ip = [curReach whatismyipdotcom];
//            if(ip && [ip rangeOfString:@"."].length>0)
//            {
//                NSString * temp = [NSString stringWithFormat:@"%@%@%@",info.IPAddress,
//                                   info.IPAddress.length>0?@",":@"",
//                                   ip];
//                info.IPAddress = temp;
//            }
//        }
    }
}
#pragma CMD CALLBACK
-(BOOL) connectToServer:(NSObject<HCNetworkDelegate>*)delegate CMDs:(CMDs *)cmds
{
    if(cmds_) PP_RELEASE(cmds_);
    cmds_ = PP_RETAIN(cmds);
    return [self connectToServer:delegate];
}
-(BOOL) connectToServer:(NSObject<HCNetworkDelegate> *)delegate
{
    self.delegate = delegate;
    if(!self.IsInited)
    {
        [self initNetwork];
        self.delegate = nil;
        return NO;
    }
    BOOL connectOK = TRUE;
    DeviceConfig * info = [DeviceConfig Instance];
    //
    if( info.IsServerConnected==NO|| asyncSocket_==nil || ![asyncSocket_ isConnected])
    {
        if(isConnnection_)
        {
            connectOK =  NO;
        }
        else
        {
            if(asyncSocket_)
            {
                [asyncSocket_ setDelegate:nil];
                [asyncSocket_ disconnect];
            }
            PP_RELEASE(asyncSocket_);
            
            //NSLog(@"network disconnected,reconnect...");
            int ret = [self connectServer:info.HOST_IP1 port:info.HOST_PORT1];
            if(ret==SRV_CONNECT_FAIL ||ret==SRV_CONNECTING)
            {
                connectOK = FALSE;
                
                NSLog(@"connect cmd send failure!");
            }
            else if(ret==SRV_CONNECTED ||ret==SRV_CONNECT_SUC)
            {
                NSLog(@"connect cmd send success!");
                info.IsServerConnected = YES;
                connectOK = TRUE;
            }
        }
    }
    //    [info release];
    if(connectOK)
    {
        if(self.delegate!=nil)
        {
            if([self.delegate respondsToSelector:@selector(netPrepared)])
            {
                [self.delegate performSelector:@selector(netPrepared)];
            }
            [self clearDelegate];
        }
        
    }
    return connectOK;
}
-(BOOL)needConnectLater
{
    if(connectRequestCount_ >= SRV_CONNECTCOUNT)
    {
        return NO;
    }
    if(connectRequestCount_ >=2)
    {
        showConnectting_ = NO;
    }
    if (asyncSocket_ && [asyncSocket_ isConnected]) {
        return NO;
    }
    return !isConnnection_;
}
-(void)clearDelegate
{
    self.delegate = nil;
}
-(int) sendData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag
{
    //NSLog(@"Ready to Send...");
    //NSString * ss = @"testsadfaskfdjasldfajdflasfd\r\n";
    //NSData * data1 = [ss dataUsingEncoding:NSUTF8StringEncoding];
    if (isConnnection_) {
        return 0;
    }
    DeviceConfig * info = [DeviceConfig Instance];
    //
    if(info.networkStatus==ReachableNone) //无网络，直接返回
    {
        //        if([self connectToServer:self.delegate])
        //        {
        //            return -1;
        //        }
        //        else
        //            NSLog(@"reconnect .....add data to queue...cancelled...");
        return -1;
    }
    if(asyncSocket_==nil || ![asyncSocket_ isConnected])
    {
        if([self connectToServer:self.delegate])
        {
            return 0;
        }
        else
            NSLog(@"reconnect .....add data to queue...cancelled...");
    }
    NSMutableData * result = [[NSMutableData alloc]init];
    [_Buffer compressData:data result:result];
#ifdef TRACKPAGES
    [[SystemConfiguration sharedSystemConfiguration] addBytes:data.length compressBytes:result.length];
#endif
    //    Byte bytes[4];
    //    [result getBytes:bytes length:4];
    //    int cmdid = bytes[0] *(256*256*256) + bytes[1] *(256*256)+bytes[2] * 256+bytes[3];
    //    if(cmdid==2 ||cmdid==1 ||cmdid==106||cmdid==105||cmdid==163)
    [[self asyncSocket] writeData:result withTimeout:timeout tag:tag];
    PP_RELEASE(result);
    
    return 1;
}
-(void)disconnectToMina
{
    DeviceConfig * info = [DeviceConfig Instance];
    if(info.IsServerConnected==NO||asyncSocket_==nil||[asyncSocket_ isConnected]==NO)
    {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    int count = 0;
    while ([asyncSocket_ writeQueueCount]>0) {
        [asyncSocket_ maybeDequeueWrite];
        count ++;
        if(count>30) break;
    }
    NSData * data = [[NSString stringWithFormat:@"bye-%@",info.UDI] dataUsingEncoding:NSUTF8StringEncoding];
    
    //    NSData * data = [@"bye" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData * result = [[NSMutableData alloc]init];
    [_Buffer compressData:data result:result];
    //    [asyncSocket_ setDelegate:nil];
    //    [asyncSocket_ moveto]
    [asyncSocket_ moveToRunLoop:[NSRunLoop mainRunLoop]];
    
    [asyncSocket_ writeData:result withTimeout:10 tag:1 msg:@"bye"];
    
    
    [asyncSocket_ disconnectAfterWriting];
    
    PP_RELEASE(result);
//    [result release];
    ////waiting for 500ms to send data
    //    sleep(0.5);
    // 
    if(cmds_)
    {
        [cmds_ disconnectedFromServer:asyncSocket_];
    }
    else
    {
        [[CMDs sharedCMDs]disconnectedFromServer:asyncSocket_];
    }
    //    [CMDHelper clearObservers];
    
    [asyncSocket_ setDelegate:nil];
    [asyncSocket_ disconnect];
    PP_RELEASE(asyncSocket_);
    self.IsInited = NO;
    NSLog(@"disconnected from server.");
}
#pragma Singletone functions
- (void) dealloc
{
    if(reachalility_)
    {
        PP_RELEASE(reachalility_);
    }
    [self removeSocket];
    self.delegate = nil;
    PP_RELEASE(cmds_);
    if(_Buffer)
    {
        PP_RELEASE(_Buffer);
    }
    PP_SUPERDEALLOC;
}
@end

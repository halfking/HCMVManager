//
//  Socketsingleton.h
//  酒店云
//
//  Created by Suixing on 12-8-10.
//  Copyright (c) 2012年 杭州随行网络信息服务有限公司. All rights reserved.
//

//#import "GCDAsyncSocket.h"
#import "HCBase.h"
#import <UIKit/UIKit.h>

@class CMDs;
@class AsyncSocket;

#define SRV_CONNECTED 0
#define SRV_CONNECT_SUC 1
#define SRV_CONNECT_FAIL 2
#define SRV_CONNECTING 3
#define RECONNECT_TIMEOUT 60
#define SRV_CONNECTCOUNT 5
#define NT_MSGCENTER            @"MSG_CENTER"        //内容：msg:"title..."
#define NT_STOPHT               @"CMD_STOPHT"
#define NT_RECONNECTSERVER      @"CMD_RECONNECT"    //当重联服务器时，发送给前端的消息
#define MSG_CONNECTERROR        @"Connect to host failed"
#define MSG_CONNECTERROR_MSG    @"服务器联接错误，请重试或联系服务商。"
#define MSG_CONNECTING          @"正在联接服务器..."


@protocol HCNetworkDelegate
@optional
    -(void)netPrepared;
    -(void)netFailure:(NSError*)error;
@end

@interface Socketsingleton : NSObject
{
//    AsyncSocket * asyncSocket_;
    //一定要用asyncsocket属性调用writedata     实例： [[[Socketsingleton sharePassValue]asyncSocket] writeData:data withTimeout:-1 tag:1];
   
}
@property   (nonatomic,PP_STRONG) AsyncSocket * asyncSocket;
@property   (nonatomic,assign) BOOL DisconnectByUser;
@property   (atomic,assign)    BOOL IsInited;
@property   (atomic,assign)    BOOL isConnnection_;
@property   (atomic,PP_WEAK)    NSObject<HCNetworkDelegate> * delegate;
+ (Socketsingleton *)     sharedSocketsingleton;
-(int)  sendData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag;
-(void) disconnectToMina;
-(BOOL) connectToServer:(NSObject<HCNetworkDelegate> *)delegate;
-(BOOL) connectToServer:(NSObject<HCNetworkDelegate> *)delegate CMDs:(CMDs *)cmds;
-(void) clearDelegate;
-(void) removeSocket;
-(BOOL) needConnectLater;

@end

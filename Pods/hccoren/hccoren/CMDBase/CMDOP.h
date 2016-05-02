//
//  CMDOP.h
//  HCIOS_2
//  命令的具体操作者，包括发送命令，回调的处理。回调数据处理完成后，将发出一个通知，界面开始处理UI相关的操作。
//  命令的发送与接收是异步的，因此有可能后发的命令先收到回调。
//  未完成的命令是缓存在一个队列中，当回调回来时，将根据CMDID与MESSAGEID来从队列中将命令取出，并进行后续操作
//  网络命令有可能会超时，此时需要有一个定时器来确定是否超时，及回调一个错误信息给UI，并且将此命令从队列中移除。
//  Created by XUTAO HUANG on 13-9-4.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCBase.h"
#import "CMDDelegate.h"
#import "Reachability.h"
#define TIMEOUT 15      //超时  15秒

//#ifndef CMD_CREATE
//#define CMD_CREATE(nn,xx,yy) CMD_##xx * nn = (CMD_##xx *)[[CMDS_WT sharedCMDS_WT]createCMDOP:yy]
//#define CMD_CREATEN(nn,xx) CMD_##xx * nn = (CMD_##xx *)[[CMDS_WT sharedCMDS_WT]createCMDOP:[NSString stringWithFormat:@"%s",#xx]]
//#endif

#ifndef __OPTIMIZE__
//#define LOGCMDTIME
#endif

@class CMDHeader;
@class HCCallbackResult;
@class CMDs;
@class CMDLog;

typedef void (^cmdCallback)(HCCallbackResult *result);


@interface CMDOP : NSObject
{
    NSTimer * timerOuter_; //处理请求超时的问题
@protected
    NSDictionary * params_;
    NSString * args_;
    NSDictionary * argsDic_;
    NSString * cacheKey_;
    id<CMDDelegate> delegate_;
    int CMDID_;
    NSString * MessageID_;
    
    BOOL canLoadFromDB_;    //此命令是否可以从本地加载缓存数据，某些命令是不需要的
    BOOL networkFailureAlert;//网络不正常时是否发送消息
    BOOL useHttpSender_;
    
    int pageSize_;
    int pageIndex_;
    CMDs * currentCMDs_;
    
    BOOL cmdCompleted_;
    int maxRetryTimes_; //重试N次后启动超时通知。
    BOOL didTimeout_;   //是否已经超时
    
    NSString * requestUrl_;
    BOOL isPost_;   //是否用Post来提交数据
    
}
@property (nonatomic,assign) long ticksForSendReady; //[CommonUtil getDateTicks:[NSDate date]]得到

#ifdef LOGCMDTIME
@property (nonatomic,assign) long ticksForCreated;

@property (nonatomic,assign) long ticksForSendTime; //[CommonUtil getDateTicks:[NSDate date]]得到
@property (nonatomic,assign) long ticksForParse; //[CommonUtil getDateTicks:[NSDate date]]得到
@property (nonatomic,assign) long ticksForBegin;//
@property (nonatomic,assign) int bytesSend;
@property (nonatomic,assign) int bytesReceived;
#endif

@property (nonatomic,assign) int retryTimes;
@property (nonatomic,PP_STRONG,readonly) NSString * messageID;
@property (nonatomic,assign) int CMDID;
@property (nonatomic,PP_STRONG,readonly) NSString * SCode;
@property (nonatomic,PP_STRONG,readonly) NSString * args;
@property (nonatomic,PP_STRONG,readonly) NSString * argsHash;
@property (nonatomic,PP_STRONG,readonly) NSString * cacheKey;
@property (nonatomic,PP_STRONG) NSString * resultMD5;
@property (nonatomic,assign) BOOL retryForFailure;

@property (nonatomic,assign) BOOL didTimeout;
@property (nonatomic,assign) int maxRetryTimes;
@property (nonatomic, copy) cmdCallback CMDCallBack;
//在有指定服务器的时候指定serverURL发送，没有的时候使用默认地址
@property (nonatomic, strong) NSString *serverURL;
@property (nonatomic,PP_STRONG) NSString * requestUrlString;//调用的完整的Request Url，包括Post指令
- (CMDs *)getCMDs;
- (NSString *)getCMDName;
- (NSString *)getNotificationName;
- (NSString *)getMessageID;
- (void) setArgs:(NSString *)args1 dic:(NSDictionary*)dic;
- (BOOL) needRemoved;
- (BOOL) useHttpSender;
- (BOOL) isPost;

- (CMDHeader *)getHeader:(NSString *)responseString;
//指定命令的类型，是String，还是Socket
- (CMDHeader *)getHeader;
- (BOOL) isMatch:(int)cmdid messageID:(NSString *)messageID;
- (BOOL) isMatch:(int)cmdid args:(NSString *)args;

#pragma mark - cmd operates
- (BOOL)    sendCMD:(id<CMDDelegate>)delegate params:(NSDictionary*)params;
- (BOOL)    sendCMD:(id<CMDDelegate>)delegate params:(NSDictionary*)params insertIntoQueue:(BOOL)insert;
- (BOOL)    sendCMD;
- (BOOL)    sendCMD:(BOOL)insertIntoQueue;
- (BOOL)    sendNetworkFailure;
- (BOOL)    sendLocalData;
- (void)    sendTimerOut;
- (BOOL)    cancelCMD;
- (BOOL)    calcArgsAndCacheKey;
- (BOOL)    isQueryFromLocal:(NSDictionary*)params networkStatus:(NetworkStatus)status; //是否从本地读取数据

- (void)    forceLoadFromNet;
#ifdef LOGCMDTIME
- (void)    logCMD:(CMDLog *)log;
#endif
//- (void)callDirect:(NSString *)body;

- (NSObject *)  queryDataFromDB:(NSDictionary*)params; //取原来存在数据库中的数据，当需要快速响应或者网络不通时
- (NSObject *)  queryDataFromDB:(NSDictionary*)params totalCount:(int *)totalCount; //取原来存在数据库中的数据，当需要快速响应或者网络不通时
- (HCCallbackResult *)  parseResult:(NSDictionary*)result;
- (NSObject *)  parseData:(NSDictionary*)result;

//预处理String，让后继的标准流程能处理
- (NSString *) preParseData:(NSString *)responseString;
- (void)sendNotification:(CMDHeader *)header;
#pragma mark - public events
//- (int) userID;
//- (NSString *)mobile;
//- (NSString *)userName;
//- (int) hotelID;
- (int) pageSize;
- (int) pageIndex;
- (void)clearTimer;
- (NSDictionary*)argsDic;
- (NSString *)requestUrl;
- (void)setRequestUrl:(NSString*)urlString;
- (NSString *)refer;
- (NSString *)UA;
@end

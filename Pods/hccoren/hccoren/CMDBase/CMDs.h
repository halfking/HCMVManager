//
//  CMDs.h
//  HCIOS_2
//  负责管理每个命令的实例及命令的调用、出错的重试等。具体的命令发送由每个命令调用公共的两个（SOcket、HTTP）来负责发送。
//  Created by XUTAO HUANG on 13-9-4.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PublicMControls.h"
#import "HCBase.h"
//#import "Socketsingleton.h"

@class CMDOP;
@class CMDSender;
@class DeviceConfig;
@class CMDs;


@protocol CMDsDelegate <NSObject>
@optional
-(void)CMDs:(CMDs*)cmds didConnected:(id)sender;
-(void)CMDs:(CMDs *)cmds didDisConnected:(id)sender;
@end

@interface CMDs : NSObject
{
    NSMutableArray * cmdQueue_;
    NSMutableArray * cmdQueueSended_;
    CMDSender * socketSender_;
    CMDSender * httpSender_;
    DeviceConfig * config_;
    Class headerClass_;
    //用于防止生成重复的MessageID
    long lastMessageID_;
    int cmdOrder_;
    NSDateFormatter *dFormatForMessageID_;
    BOOL isSending_;
#ifdef FULL_REQUEST
    int cmdCount_;
    int cmdFailureCount_;
#endif
}
@property (nonatomic,PP_STRONG) NSString * responseString;
@property (nonatomic,PP_STRONG) NSData * responseStream;
@property (nonatomic,assign) NSObject<CMDsDelegate>* delegate;
//@property (nonatomic,assign) BOOL DisconnectByUser;
+ (CMDs *)      sharedCMDs;
+ (void)        setInstance:(CMDs*)instance; //为了在子类中对应的实例与现有类指向同一个地址
- (CMDSender *) getCurrentSender:(BOOL)isHttpRequest;
- (CMDOP*)      createCMDOP:(NSString *)CMDName;
- (CMDOP *)     createCMDOPByID:(int)CMDID;
- (CMDOP*)      getCMDOP:(int)CMDID messageID:(NSString *)messageID;
- (void)        connectedToServer:(id)sender;
- (void)        disconnectedFromServer:(id)sender;
- (void)        setHeaderClass:(Class)classA;
#pragma mark - send queue manager
#ifdef FULL_REQUEST
- (int)         cmdSendedCount;
- (void)        incCmdCount;
- (void)        incCmdFailureCount;
- (int)         cmdSendFailureCount;
#endif
- (int)         queueLength;
- (void)        addCMDOPToQueue:(BOOL)sendOK cmd:(CMDOP*)cmd;
- (void)        removeCMDOP:(CMDOP*)cmdOP;
- (void)        removeCMDOP:(int) cmdID messageID:(NSString*)messageID;
- (BOOL)        isRequestDuplicated:(CMDOP*)cmdOP;
#pragma mark - publicsource
- (NSString *)  getCurrentTimeForMessageID;
//- (int)         userID;
//- (NSString *)  mobile;
//- (NSString *)  userName;
//- (int)         hotelID;
#pragma mark - connect server or disconnect
//- (void)        disconnectToServer;
//- (BOOL)        connectToServer:(id<HCNetworkDelegate>)delegate;
//- (void)        senderTimer;
#pragma mark - clear dealloc
- (void)        clearQueues;
- (void)        reset;

#pragma mark - base cmds
-(void)heartBeat;

@end

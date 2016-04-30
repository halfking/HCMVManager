//
//  CMDS_WT.m
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-11-27.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "CMDS_WT.h"
#import <hccoren/PublicMControls.h>
#import <hccoren/CMDSocketHeader.h>

//#import "PublicMControls.h"
//#import "SystemConfiguration.h"

//#import "CMD_0001.h"
#import "CMD_HeatBeat.h"

//#import "CMD_0154.h"
//#import "CMD_0170.h"
//#import "CMD_0003.h"
#import "UserManager.h"
@implementation CMDS_WT
SYNTHESIZE_SINGLETON_FOR_CLASS_NEW(CMDS_WT)

- (id)init
{
    if(self = [super init])
    {
        [CMDs setInstance:self];
        //        cmdParent_ = [CMDs sharedCMDs];
        self.delegate = self;
        [self setHeaderClass:[CMDSocketHeader class]];
        //        self.delegate = self;
    }
    return self;
}
- (void)dealloc
{
    self.delegate = nil;
    //    cmdParent_.delegate = nil;
    PP_SUPERDEALLOC;
}
#pragma mark - public resource
- (long)userID
{
    UserManager * config = [UserManager sharedUserManager];
    return [config userID];
}
- (NSString *)mobile
{
    UserManager * config = [UserManager sharedUserManager];
    return config.mobile;
//    if(config && [config currentUser]!=nil)
//        return [config currentUser].Mobile;
//    else
//        return nil;
    
}
- (NSString *)userName
{
    UserManager * config = [UserManager sharedUserManager];
    return config.userName;
//     if(config && [config currentUser]!=nil)
//        return [config currentUser].UserName;
//    else
//        return nil;
}

#pragma mark cmds delegate
- (void)sendNoMatchedCMD:(CMDHeader *)header
{
    if(!header) return;
    if(header.CMD)
    {
        [header parseResult];
        [header.CMD sendNotification:header];
    }
    else
    {
//        if(header.CMDID==154)
//        {
//            CMD_0154 * cmd = (CMD_0154*)[self createCMDOP:154];
//            header.CMD = cmd;
//            [header parseResult];
//            [cmd sendNotification:header];
//            cmd = nil;
//            
//        }
//        else if(header.CMDID==170)
//        {
//            CMD_0170 * cmd = (CMD_0170*)[self createCMDOP:170];
//            header.CMD = cmd;
//            [header parseResult];
//            [cmd sendNotification:header];
//            cmd = nil;
//        }
//        else if(header.CMDID==3) //force quit
//        {
//            CMD_0003 * cmd = (CMD_0003*)[self createCMDOP:3];
//            header.CMD = cmd;
//            [header parseResult];
//            [cmd sendNotification:header];
//            cmd = nil;
//        }
//        else
//        {
            NSLog(@"cannot match header:%@",[header JSONRepresentationEx]);
//        }
    }
}
-(void)CMDs:(CMDs *)cmds didConnected:(id)sender
{
    NSLog(@"connected,register device....");
    //connect to server
    //need register server
    //    [CMDs deviceRegister:[CommonObserver sharedCommonObserver]];
    
//    CMD_0001 * cmd1 = (CMD_0001*)[self createCMDOP:1];
//    
//    [cmd1 sendCMD];
    
}
-(void)CMDs:(CMDs *)cmds didDisConnected:(id)sender
{
    
}
//#pragma mark - cmds
-(void)heartBeat
{
//    CMD_0002 * cmd2 = (CMD_0002*)[self createCMDOP:2];
//    
//    [cmd2 sendCMD];
}
@end

//
//  CMDS_WT.h
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-11-27.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <hccoren/CMDs.h>

#ifndef CMD_CREATE
#define CMD_CREATE(nn,xx,yy) CMD_##xx * nn = (CMD_##xx *)[[CMDS_WT sharedCMDS_WT]createCMDOP:yy]
#define CMD_CREATEN(nn,xx) CMD_##xx * nn = (CMD_##xx *)[[CMDS_WT sharedCMDS_WT]createCMDOP:[NSString stringWithFormat:@"%s",#xx]]
#endif

@interface CMDS_WT : CMDs<CMDsDelegate>
{
//    CMDs * cmdParent_;
}
+ (CMDS_WT *)      sharedCMDS_WT;

#pragma mark - publicsource
- (long)         userID;
- (NSString *)  mobile;
- (NSString *)  userName;
@end

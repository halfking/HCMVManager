//
//  base.h
//  hccoren
//
//  Created by HUANGXUTAO on 16/4/20.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#ifndef base_h
#define base_h
#import "HCBase.h"
#import "config.h"
#import "DeviceConfig.h"
#import "NSEntity.h"
#import "CommonUtil.h"
#import "CommonUtil(Date).h"
#import "publicMControls.h"
#import "RegexKitLite.h"
#import "HCFileManager.h"
#endif /* base_h */

/* DeviceConfig 用法 */
/*
 DeviceConfig * config = [DeviceConfig config];
 
 #ifndef __OPTIMIZE__
 BOOL debugMode = YES;
 #else
 BOOL debugMode = NO;
 #endif
 
 [config changeConfigs:CT_INTERFACE imageServer:CT_IMAGESERVERPATH imageSever2:CT_IMAGEPATHROOT uploadServer:CT_UPLOADSERVER uploadService:CT_UPLOADSERVERPATH debugMode:debugMode];
 
*/
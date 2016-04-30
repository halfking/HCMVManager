//
//  CMDSocketSender.h
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-6.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "CMDSender.h"
#import "Socketsingleton.h"
#import "HCBase.h"
@class CMDOP;

@interface CMDSocketSender : CMDSender<HCNetworkDelegate>
+ (CMDSocketSender *)sharedCMDSocketSender;
@end

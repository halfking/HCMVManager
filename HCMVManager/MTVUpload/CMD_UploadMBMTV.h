//
//  CMD_UploadMBMTV.h
//  maiba
//
//  Created by SeenVoice on 15/8/26.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import <hcbasesystem/cmd_wt.h>
#import "MTV.h"

@interface CMD_UploadMBMTV : CMDOP_WT

@property(PP_STRONG, nonatomic) MTV *data;
@property(PP_STRONG, nonatomic) NSArray *Materials;
@property (nonatomic,assign,readonly) long MBMTVID;
@property (nonatomic,assign,readonly) long MTVID;
@property (nonatomic,assign) int justUpdateKey; //0 create/update all 1 update key 2 update selected
@end

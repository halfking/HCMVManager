//
//  CMD_GetSingedOnCertainSample.h
//  maiba
//
//  Created by SeenVoice on 15/8/26.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import "CMDOP_WT.h"
#import "MTV.h"
#import "HCCallResultForWT.h"

@interface CMD_GetUserMTVBySample : CMDOP_WT

@property(assign, nonatomic) NSInteger sampleID;
@property(assign, nonatomic) NSInteger userID;

@end

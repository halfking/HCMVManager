//
//  CMD_DeleteMBMTV.h
//  maiba
//
//  Created by SeenVoice on 15/8/26.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import <hcbasesystem/cmd_wt.h>


@interface CMD_DeleteMBMTV : CMDOP_WT

@property(assign, nonatomic) long MBMTVID;
//@property(assign, nonatomic) long userID;
@property (assign,nonatomic) long sampleID;
@property (assign,nonatomic) long mtvID;

@end

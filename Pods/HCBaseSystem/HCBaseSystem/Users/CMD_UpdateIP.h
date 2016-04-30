//
//  CMD_UpdateIP.h
//  maiba
//
//  Created by HUANGXUTAO on 15/11/20.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import "CMDOP_WT.h"

@interface CMD_UpdateIP : CMDOP_WT
@property (nonatomic,assign) long UserID;
@property (nonatomic,strong) NSString * IP;
@end

//
//  CMD_DeleteSingleUserMaterial.h
//  maiba
//
//  Created by SeenVoice on 15/8/26.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import <HCBaseSystem/CMD_WT.h>

@interface CMD_DeleteSingleUserMaterial : CMDOP_WT

@property(assign, nonatomic) int MaterialID;
@property(assign, nonatomic) int userID;

@end

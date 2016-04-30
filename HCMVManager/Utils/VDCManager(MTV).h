//
//  VDCManager(MTV).h
//  HCMVManager
//
//  Created by HUANGXUTAO on 16/4/21.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTV.h"
#import <hcbasesystem/vdcmanager.h>
#import <hcbasesystem/vdcmanager(helper).h>
#import <hcbasesystem/vdcmanager(localfiles).h>
@interface VDCManager(MTV)
- (VDCItem *) getVDCItemByMtv:(MTV*)mtv urlString:(NSString *)urlString;
- (void) removeItemByMTV:(MTV *)item;
@end

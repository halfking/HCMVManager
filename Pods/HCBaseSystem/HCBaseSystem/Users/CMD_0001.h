//
//  CMD_0001.h
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-6.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "CMDOP_WT.h"

@interface CMD_0001 : CMDOP_WT
{
    int resultUserID_;
}
// 传入的参数dic，key：value
//@property (strong, nonatomic) NSDictionary *parameterDictionary;
- (int) resultUserID;
@end

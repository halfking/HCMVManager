//
//  HCCallResultForSX.h
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-6.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

//#import <hccoren/HCCallbackResult.h>
//#import "HCCallbackResult.h"
#import <hccoren/cmd.h>
@interface HCCallResultForWT : HCCallbackResult
@property (nonatomic,assign,readonly) int userID;
@property (nonatomic,assign,readonly) int pageIndex;
@property (nonatomic,assign,readonly) int pageSize;
@property (nonatomic,assign) long ObjectID;
@property (nonatomic,assign) int Rank;
@property (nonatomic,assign) int MaterialID;
@property (nonatomic,assign) long MTVID;
@property (nonatomic,assign) BOOL isForReview;

//@property (nonatomic,assign,readonly) int hotelID;
@end

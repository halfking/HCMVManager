//
//  HCCallResultForSX.m
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-6.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "HCCallResultForWT.h"

@implementation HCCallResultForWT
@synthesize userID,pageSize,pageIndex;
@synthesize ObjectID;
@synthesize MTVID;
@synthesize isForReview;
- (id)initWithArgs:(NSDictionary *)args response:(NSDictionary *)dic
{
    if(self = [super initWithArgs:args response:dic])
    {
        if(dic && [dic objectForKey:@"userid"])
        {
            userID = [[dic objectForKey:@"userid"]intValue];
        }
        if(args)
        {
//            if([args objectForKey:@"hotelid"])
//            {
//                hotelID = [[args objectForKey:@"hotelid"]intValue];
//            }
            if([args objectForKey:@"pageindex"])
            {
                pageIndex = [[args objectForKey:@"pageindex"]intValue];
            }
            if([args objectForKey:@"pagesize"])
            {
                pageSize = [[args objectForKey:@"pagesize"]intValue];
            }
        }
    }
    return self;
}

@end

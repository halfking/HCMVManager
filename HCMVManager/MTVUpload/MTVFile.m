//
//  MTVFile.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/7/11.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "MTVFile.h"

@implementation MTVFile
@synthesize FilePath,Key;
@synthesize MTVID;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"mtvfiles";
        self.KeyName = @"MTVID";
    }
    return self;
}
- (void)dealloc
{
    PP_RELEASE(FilePath);
    PP_RELEASE(Key);
    
    PP_SUPERDEALLOC;
}
@end

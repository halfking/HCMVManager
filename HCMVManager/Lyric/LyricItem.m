//
//  LyricItem.m
//  maiba
//
//  Created by Matthew on 16/2/25.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "LyricItem.h"

@implementation LyricItem
@synthesize text,begin,end,duration;

-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"lyrics";
        self.KeyName = @"st";
        begin = 0;
        end = -1;
        duration = 0;
        text = nil;
    }
    return self;
}
- (void)dealloc
{
    PP_RELEASE(text);
    PP_SUPERDEALLOC;
}
@end

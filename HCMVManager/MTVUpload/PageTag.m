//
//  PageTag.m
//  maiba
//
//  Created by seentech_5 on 16/3/7.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "PageTag.h"

@implementation PageTag

@synthesize PageTagName,PageTagCover;
@synthesize PageTagID,PageCode,DataStatus,IsTag,Sort;
@synthesize OpenUrl;

-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"PageTags";
        self.KeyName = @"PageTagID";
    }
    return self;
}
- (id)initWithDictionary:(NSDictionary *)dic
{
    self = [super initWithDictionary:dic];
    if(self)
    {
        
    }
    return self;
}
-(void) dealloc
{
    PP_RELEASE(PageTagName);
    PP_RELEASE(PageTagCover);
    PP_SUPERDEALLOC;
}
@end

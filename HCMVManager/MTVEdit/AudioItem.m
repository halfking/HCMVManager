//
//  voiceItem.m
//  maiba
//
//  Created by HUANGXUTAO on 15/8/19.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import "AudioItem.h"
#import <hcbasesystem/updown.h>

@implementation AudioItem
@synthesize fileName;
@synthesize secondsDuration,secondsInArray;
@synthesize secondsBegin,secondsEnd,secondsDurationInArray;
@synthesize index;
@synthesize url;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"audioitems";
        self.KeyName = @"index";
    }
    return self;
}
- (void)setSecondsBegin:(CGFloat)psecondsBegin
{
    secondsBegin = psecondsBegin;
    secondsDurationInArray = secondsEnd - secondsBegin;
}
- (void)setSecondsEnd:(CGFloat)psecondsEnd
{
    secondsEnd = psecondsEnd;
    secondsDurationInArray = secondsEnd - secondsBegin;
}
- (void)dealloc
{
    PP_RELEASE(filePath_);
    PP_RELEASE(fileName);
    PP_RELEASE(url);
    PP_SUPERDEALLOC;
}
- (void)setFileName:(NSString *)fileNameA
{
    fileName  = [[UDManager sharedUDManager]getFileName:fileNameA];
    filePath_ = nil;
}
- (NSString *)filePath
{
    if(!filePath_)
    {
        filePath_ = [[UDManager sharedUDManager]getFilePath:fileName];
    }
    return filePath_;
}
@end

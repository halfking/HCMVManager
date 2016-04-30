//
//  MBMTV.m
//  maiba
//
//  Created by SeenVoice on 15/8/26.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import "MBMTV.h"

@implementation MBMTV

@synthesize MBMTVID,SampleID,UserID;
@synthesize Materials,UploadTime;

-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"mbmtvs";
        self.KeyName = @"MBMTVID";
    }
    return self;
}

-(void)dealloc
{
    PP_RELEASE(Materials);
    PP_RELEASE(UploadTime);
    PP_SUPERDEALLOC;
}

@end

//
//  UploadRecord.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/4/30.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "UploadRecord.h"

@implementation UploadRecord
@synthesize UploadID,UploadDurance,IsUploaded;
@synthesize FilePath,DownloadUrl,UploadBeginTime,UploadEndTime;
@synthesize UserID;
@synthesize IsSynced;
@synthesize FileSize;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"Uploads";
        self.KeyName = @"UploadID";
    }
    return self;
}

-(void) dealloc
{
    PP_RELEASE(FilePath);
    PP_RELEASE(DownloadUrl);
    PP_RELEASE(UploadBeginTime);
    PP_RELEASE(UploadEndTime);
    PP_SUPERDEALLOC;
}
@end

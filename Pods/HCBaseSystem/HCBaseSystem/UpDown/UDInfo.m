//
//  UDInfo.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/14.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "UDInfo.h"
//#import "UDManager(Helper).h"
#import <hccoren/base.h>
@implementation UDInfo
@synthesize Key,ErrorInfo;
@synthesize LocalFileName,RemoteUrl,OrgUrl;
@synthesize Status;
@synthesize IsUpload;
@synthesize delegate;
@synthesize Percent,WillStop;
@synthesize Ext;
@synthesize DateCreated;
@synthesize DateModified;
@synthesize DomainType;
//@synthesize headers;
@synthesize TotalBytes,RemainBytes,Progress;
@synthesize operate;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"udinfos";
        self.KeyName = @"Key";
        self.WillStop = NO;
        self.Percent = 0;
    }
    return self;
}

-(void) dealloc
{
    PP_RELEASE(Key);
    PP_RELEASE(ErrorInfo);
    PP_RELEASE(LocalFileName);
    PP_RELEASE(RemoteUrl);
    PP_RELEASE(OrgUrl);
    PP_RELEASE(Ext);
    PP_RELEASE(DateModified);
    PP_RELEASE(DateCreated);
    
    PP_RELEASE(operate);
//
//    PP_RELEASE(headers);
    
//    PP_RELEASE(delegate);
    delegate = nil;
    PP_SUPERDEALLOC;
}
- (void)setLocalFileName:(NSString *)LocalFileNameA
{
    if(LocalFileNameA && LocalFileNameA.length>0)
    {
        LocalFileName = [[HCFileManager manager]getFileName:LocalFileNameA];
    }
    else
    {
        LocalFileName = nil;
    }
    localFilePath_ = nil;
}
- (NSString *)LocalFilePath
{
    if(!localFilePath_)
    {
        localFilePath_ = [[HCFileManager manager]getFilePath:LocalFileName];
    }
    return localFilePath_;
}
@end

//
//  VDCItem.m
//  maiba
//  Video dwonload cache item
//  记录缓存的文件与本地Key对应关系
//  Created by HUANGXUTAO on 15/9/14.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import "VDCItem.h"
#import <hccoren/base.h>
//#import "Reachability.h"
//#import "UDManager.h"
//#import "UDManager(Helper).h"

#import "VDCManager.h"
@implementation VDCItem
@synthesize key,remoteUrl,contentLength,downloadBytes,lastDownloadTime;
@synthesize isCompleted;
//@synthesize localFilePath;
//@synthesize tempFilePath;
@synthesize localFileName,tempFileName;
@synthesize localWebUrl;
@synthesize needStop;
@synthesize ticks;
@synthesize isDownloading;
@synthesize title;
//@synthesize AudioPath,
@synthesize AudioFileName;
@synthesize AudioUrl;//AudioTempPath;
@synthesize isAudioItem;
@synthesize tempFileList;
@synthesize isCheckedFiles;
@synthesize FileHash;

@synthesize mediaJson,stepIndex,lastSeconds,SampleID,MTVID;

-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"vdcitems";
        self.KeyName = @"key";
        SampleID = 0;
    }
    return self;
}
- (BOOL)hasDraft
{
    if(self.MTVID!=0) return NO;
    if(self.SampleID==0) return NO;
    if(self.stepIndex>=-1 && self.stepIndex<2 && self.mediaJson && self.mediaJson.length>10)
    {
        //check files??? 放到外部检查吧
        return YES;
    }
    return NO;
}
-(void)dealloc
{
    PP_RELEASE(FileHash);
    PP_RELEASE(key);
    PP_RELEASE(remoteUrl);
    PP_RELEASE(lastDownloadTime);
    //    PP_RELEASE(localFilePath);
    PP_RELEASE(tempFileList);
    PP_RELEASE(title);
    PP_RELEASE(localFileName);
    PP_RELEASE(tempFileName);
    //    PP_RELEASE(AudioTempPath);
    PP_RELEASE(AudioUrl);
    PP_RELEASE(AudioFileName);
    
    PP_RELEASE(mediaJson);
    
    PP_RELEASE(localAudioPath_);
    PP_RELEASE(localFilePath_);
    
    PP_SUPERDEALLOC;
}
- (NSString *)getPlayUrlOrPath
{
    HCFileManager * ud = [HCFileManager manager];
    
    //首先看本地文件是否存在
    NSString * path = [ud getFilePath:localFileName];
    if(!path || path.length==0 || ![ud existFileAtPath:path])
    {
        path = remoteUrl;
    }
    return path;
}
- (void) setLocalFileName:(NSString *)localFileNameA
{
    localFileName = localFileNameA;
    localFilePath_ = nil;
}
- (void) setAudioFileName:(NSString *)AudioFileNameA
{
    AudioFileName = AudioFileNameA;
    localAudioPath_ = nil;
}
- (NSString *)tempFilePath
{
    HCFileManager * ud = [HCFileManager manager];
    NSString * path = [ud getFilePath:tempFileName];
    return path;
}
- (NSString *)localFilePath
{
    if(!localFilePath_)
    {
        HCFileManager * ud = [HCFileManager manager];
        localFilePath_ = [ud getFilePath:localFileName];
    }
    return localFilePath_;
}
- (NSString *)AudioPath
{
    if(!localAudioPath_)
    {
        HCFileManager * ud = [HCFileManager manager];
        localAudioPath_ = [ud getFilePath:AudioFileName];
    }
    return localAudioPath_;
}
@end

//
//  VDCTempFileInfo.m
//  maiba
//
//  Created by HUANGXUTAO on 15/9/22.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import "VDCTempFileInfo.h"
#import "UDManager(Helper).h"
#import "AFNetworking.h"
#import "HXNetwork.h"
@implementation VDCTempFileInfo
@synthesize fileName,offset,length,lengthFull;
@synthesize isDownloading;
@synthesize parentItem;
@synthesize operation;
@synthesize operationNew;
@synthesize Hash;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"tempfiles";
        self.KeyName = @"filename";
    }
    return self;
}
- (NSString *)filePath
{
    // 清除tempFileList后需要用localFilePath伪装成VDCTempFileInfo临时文件
    // 但是localFilePath在local路径下，而VDCTempFileInfo文件在temp路径下
    // localFilePath是以.mp4后缀，而VDCTempFileInfo文件不是以.mp4后缀
    // 所以用[fileName hasSuffix:@".mp4"] 区分是不是localFilePath
    if([fileName hasSuffix:@".mp4"]||[fileName hasPrefix:@"m4a"])
        return [[UDManager sharedUDManager]localFileFullPath:fileName];
    else
        return [[UDManager sharedUDManager]tempFileFullPath:fileName];
}
- (void)cancelOperation
{
    if(self.operation )
    {
        if(!self.operation.isCancelled)
            [self.operation cancel];
        self.operation = nil;
    }
    if(self.operationNew)
    {
        if(!self.operationNew.isCancelled)
        [self.operationNew cancel];
        self.operationNew = nil;
    }
    isDownloading = NO;
}
- (BOOL)isDownloadWithOperation
{
    if(isDownloading && (operation||operationNew))
    {
        return YES;
    }
    return NO;
}
- (NSMutableDictionary *) toDicionary
{
    VDCItem * item = PP_RETAIN(self.parentItem);
    AFHTTPRequestOperation * op = PP_RETAIN(self.operation);
    HXNetwork * opNew = PP_RETAIN(self.operationNew);
    self.parentItem = nil;
    self.operation = nil;
    self.operationNew = nil;
    NSMutableDictionary * dic = [super toDicionary];
    self.parentItem = item;
    self.operation = op;
    self.operationNew = opNew;
    
    PP_RELEASE(opNew);
    PP_RELEASE(item);
    PP_RELEASE(op);
    return dic;
}
-(void)dealloc
{
    if(operation)
    {
        [operation cancel];
        PP_RELEASE(operation);
    }
    if(operationNew)
    {
        [operationNew cancel];
        PP_RELEASE(operationNew);
    }
    PP_RELEASE(Hash);
//    PP_RELEASE(filePath);
    PP_RELEASE(fileName);
    
    PP_SUPERDEALLOC;
}
@end

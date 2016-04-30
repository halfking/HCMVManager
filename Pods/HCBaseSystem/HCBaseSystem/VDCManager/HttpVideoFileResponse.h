//
//  HttpVideoFileResponse.h
//  maiba
//
//  Created by HUANGXUTAO on 15/9/14.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <hccoren/HTTPResponse.h>
#import <hccoren/HTTPConnection.h>
#import <hccoren/RegexKitLite.h>
#import "UDManager(Helper).h"
@class VDCTempFileInfo;
@class VDCManager;
@class VDCItem;

@interface HttpVideoFileResponse : NSObject<HTTPResponse>
{
    NSString *filePath_;
    NSFileHandle *fileHandle_;
    VDCTempFileInfo * currentTempFileInfo_;
    NSString * key_;
    
    HTTPConnection *connection_;
    
    long fileLength_;
    UInt64 fileOffset_;
    
    BOOL aborted;
    
    UDManager * udManager_;
    VDCManager * vdcManager_;
    VDCItem * currentItem_;
    
    NSString * downloadUrl_;
    
     dispatch_queue_t   th_download_;
    
}
//@property(nonatomic,assign) BOOL needRelease;
- (id)initWithFilePath:(NSString *)filePath forConnection:(HTTPConnection *)parent;
- (void) setDownloadUrl:(NSString *)downloadUrl;

- (BOOL)needBreakLoop;

- (NSString *)filePath;
@end

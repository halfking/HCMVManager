//
//  VDCTempFileInfo.h
//  maiba
//
//  Created by HUANGXUTAO on 15/9/22.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <hccoren/base.h>
@class AFHTTPRequestOperation;
@class HXNetwork;

@class VDCItem;
@interface VDCTempFileInfo : HCEntity
@property(nonatomic,PP_STRONG) NSString * fileName;
//@property(nonatomic,PP_STRONG) NSString * filePath;
@property(nonatomic,assign) UInt64 offset;
@property(nonatomic,assign) UInt64 length;
@property(nonatomic,assign) UInt64 lengthFull;
@property (nonatomic,assign)BOOL isDownloading;
@property (nonatomic,PP_WEAK) VDCItem * parentItem;
@property (nonatomic,assign) BOOL changeUrlTicks;
@property (nonatomic,PP_STRONG) AFHTTPRequestOperation * operation;
@property (nonatomic,PP_STRONG) HXNetwork * operationNew;
@property (nonatomic,PP_STRONG) NSString * Hash;

- (NSString *) filePath;
- (void)cancelOperation;
- (BOOL)isDownloadWithOperation;
@end

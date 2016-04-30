//
//  VDCTempFileManager.h
//  maiba
//
//  Created by HUANGXUTAO on 16/3/14.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VDCTempFileInfo.h"
#import "VDCItem.h"
#import "UDManager(Helper).h"
#import "VDCTempFileManager.h"

@interface VDCTempFileManager(readwriter)
//- (BOOL) beginWithVDCItem:(VDCItem *)item withOffset:(UInt64)offset;
- (BOOL) finishedWriting;
- (void) close;
- (BOOL) writeContentToFile:(long long)startOffset content:(NSData *)content;
- (NSData *)readContentFromFile:(long long)startOffset length:(NSUInteger)length;
- (long long) correctOffset:(long long)offset;
- (VDCTempFileInfo *)getCurrentTempFileInfo:(VDCItem *)item offset:(long long) offset;
- (long long ) alignOffsetWithFileDownloaded:(VDCItem *)item offset:(long long) offset;
- (BOOL)    getNextRangeToDownload:(VDCItem *)item offset:(long long)offset range:(NSRange *)range;

@end

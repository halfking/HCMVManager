//
//  VDCManager(LocalFiles).h
//  maiba
//
//  Created by HUANGXUTAO on 15/10/10.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VDCManager.h"
#import "VDCItem.h"
#import "VDCTempFileInfo.h"

@interface VDCManager(LocalFiles)
- (void)checkItemFile:(VDCItem *)item removePartFile:(BOOL)removePartFile;

- (BOOL)combinateTempFiles:(VDCItem*)item tempFilePath:(NSString *)tempFilePath targetFilePath:(NSString *)targetFilePath;
- (UInt64)getTemFileList:(VDCItem *)item justCheckDownloading:(BOOL)justCheckDownloading;

- (UInt64)checkTempitemLengthByFile:(NSString *)path tempList:(NSMutableArray *)tempList ;// justCheckDownloading:(BOOL)justCheckDownloading;
- (void)sortFiles:(NSMutableArray *)array;
-(NSMutableArray *)removeTempFiles:(NSString *)filePath contentlength:(UInt64)contentLength
                  checkLength:(BOOL)checkLength matchSize:(UInt64)fileSize;
- (void)getTemplateFiles:(VDCItem *)item;
- (VDCTempFileInfo *)getNextTempfile:(UInt64)offset  item:(VDCItem *)item;


//- (VDCTempFileInfo *)createTempFileByOffset:(UInt64)offset item:(VDCItem *)item;
- (void)setItemsRemovedFlag;
- (NSMutableArray *) getVDCItemsFromDir;
- (CGFloat)getItemCacheSize:(VDCItem *)item;
- (void) removeMbdFileNoNeed;
- (void) resetLastDownloadTime:(VDCItem *)item;
- (void) removeVDCItemsExpired;
//- (void) removeItemByMTV:(MTV *)item;
@end

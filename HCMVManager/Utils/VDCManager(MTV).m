//
//  VDCManager(MTV).m
//  HCMVManager
//
//  Created by HUANGXUTAO on 16/4/21.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "VDCManager(MTV).h"
#import "UDManager(MTV).h"
@implementation VDCManager(MTV)
- (VDCItem *) getVDCItemByMtv:(MTV*)mtv urlString:(NSString *)urlString
{
    if(!mtv) return nil;
    if(!urlString || urlString.length==0)
    {
        if(mtv.OnlyAudio)
        {
            urlString = mtv.DownloadUrl;
        }
        else
        {
            urlString = [mtv getDownloadUrlOpeated:ReachableViaWiFi userID:0];
        }
    }
    
    NSString * key = [self getRemoteFileCacheKey:urlString];
    VDCItem * item = [self getVDCItem:key];
    if(!item)
    {
        item = [self createVDCItem:urlString key:key];
        item = [self addVDCItemToList:item];
        
        if(mtv.AudioFileName)
        {
            item.AudioFileName = mtv.AudioFileName;
            //            NSString * newPath = nil;
            //            BOOL hasSingFile = [[UDManager sharedUDManager]isFileExistAndNotEmpty:mtv.AudioPath
            //                                                                             size:nil
            //                                                                        pathAlter:&newPath];
            //            if(hasSingFile && newPath)
            //            {
            //                mtv.AudioPath = newPath;
            //                item.AudioPath = newPath;
            //            }
        }
        if(mtv.FileName)
        {
            NSString * newPath = [mtv getFilePathN];
            UInt64 size = 0;
            BOOL hasSingFile = [[UDManager sharedUDManager]isFileExistAndNotEmpty:newPath
                                                                             size:&size];
            if(hasSingFile && newPath)
            {
                item.localFileName = mtv.FileName;
                item.contentLength = size;
                item.downloadBytes = size;
                item.isCompleted = YES;
            }
        }
    }
    if(mtv.OnlyAudio)
    {
        item.isAudioItem = YES;
    }
    item.MTVID = mtv.MTVID;//如果不为0 表示为用户MTV的下载，如果为0，表示为Sample
    if (!item.title || item.title.length == 0) {
        NSString *title = [NSString stringWithFormat:@"%@  (%@)",mtv.Title,mtv.Author];
        item.title = title;
    }
    if(item.downloadBytes>=item.contentLength && item.contentLength>0)
    {
        item.isCompleted = YES;
    }
    return item;
}
- (void) removeItemByMTV:(MTV *)item
{
    if(item.Key && item.Key.length>2)
    {
        VDCItem * vdcItem = [self getVDCItem:item.Key];
        if(vdcItem)
        {
            [self removeItem:vdcItem withTempFiles:YES includeLocal:YES];
            [self removeDownloadItemFile:vdcItem tempPath:vdcItem.tempFilePath];
        }
        NSString * matchRegex = [NSString stringWithFormat:@"%@.(m4a|mp4|jpg)",item.Key];
        NSString * dir = [[UDManager sharedUDManager]localFileFullPath:nil];
        [[UDManager sharedUDManager]removeFilesAtPath:dir matchRegex:matchRegex];
        dir = [[UDManager sharedUDManager]tempFileFullPath:nil];
        [[UDManager sharedUDManager]removeFilesAtPath:dir matchRegex:matchRegex];
    }
    if(item.FileName && item.FileName.length>0)
    {
        NSString * fileName = [item.FileName lastPathComponent];
        NSString * dir = [[UDManager sharedUDManager]localFileFullPath:nil];
        fileName = [fileName stringByReplacingOccurrencesOfString:@"." withString:@"\\."];
        fileName = [fileName stringByReplacingOccurrencesOfString:@"-" withString:@"\\-"];
        NSString * matchRegex = [NSString stringWithFormat:@"%@.*",fileName];
        [[UDManager sharedUDManager]removeFilesAtPath:dir matchRegex:matchRegex];
    }
}
@end

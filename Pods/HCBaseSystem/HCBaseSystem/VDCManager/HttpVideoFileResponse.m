//
//  HttpVideoFileResponse.m
//  maiba
//
//  Created by HUANGXUTAO on 15/9/14.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import "HttpVideoFileResponse.h"
#import <hccoren/base.h>

#import "VDCManager.h"
#import "VDCManager(Helper).h"
#import "VDCManager(LocalFiles).h"

#import "UDManager(Helper).h"
#import "VDCTempFileInfo.h"
#import "VDCItem.h"
//#import "MTVUploader.h"
#define COMPARE_DIFF

@implementation HttpVideoFileResponse

- (id)initWithFilePath:(NSString *)fpath forConnection:(HTTPConnection *)parent
{
    //NSLog(@"filePath = %@",fpath);
    if((self = [super init]))
    {
        connection_ = parent; // Parents retain children, children do NOT retain parents
        
        NSLog(@"init response for %@",fpath);
        vdcManager_ = [VDCManager shareObject];
        udManager_ = [UDManager sharedUDManager];
        fileHandle_ = nil;
        filePath_ = [[fpath copy] stringByResolvingSymlinksInPath];
        if (filePath_ == nil)
        {
            //HTTPLogWarn(@"%@: Init failed - Nil filePath", THIS_FILE);
            return nil;
        }
        
        //        key_ = PP_RETAIN([vdcManager_ getKeyFromLocalUrl:fpath]);
        
        currentItem_ = PP_RETAIN([vdcManager_ getVDCItemForResponse:fpath]);
        if(!currentItem_)
        {
            NSLog(@"error ,cannot get vdc item");
            [self abort];
        }
        else
        {
            key_ = PP_RETAIN(currentItem_.key);
            fileLength_ = (long)currentItem_.contentLength;
            if(fileLength_<=DEFAULT_PKSIZE*2)
            {
                fileLength_ = (long)[[VDCManager shareObject] getContentLengthByFile:currentItem_.tempFilePath];
                
                if(fileLength_ <=0 && currentItem_.remoteUrl && currentItem_.remoteUrl.length>0)
                {
                    fileLength_ = [[VDCManager shareObject] getContentLengthByUrl:currentItem_.remoteUrl];
                }
            }
            if(fileLength_ >=0)
                currentItem_.contentLength = fileLength_;
            else
            {
                NSLog(@"contentlength error:%ld",(long)fileLength_);
            }
            fileOffset_ = 0;
            
            aborted = NO;
            
            if ([DeviceConfig config].networkStatus != ReachableNone) {
                if(![vdcManager_ isItemDownloadCompleted:currentItem_])
                {
                    [vdcManager_ downloadNextSlide:currentItem_ offset:fileOffset_ immediate:YES];
                }
            }
            [vdcManager_ regStopLocalWebRequest:currentItem_];
        }
    }
    return self;
}
//- (void)downloadTimer:(VDCItem*)currentItem
//{
//    if(!currentTempFileInfo_ && !currentItem) return;
//    if(currentItem_.needStop) return;
//    if(needCancelLocalWebRequest) return;
//    if([[VDCManager shareObject]getDownloadingCount]>1) return;
//
//    __weak VDCItem * item = currentItem?currentItem:currentTempFileInfo_.parentItem;
//    if(item.downloadBytes >= item.contentLength)
//    {
//
//    }
//    else
//    {
//        [[VDCManager shareObject]downloadNextSlide:item offset:0 immediate:NO];
//        NSLog(@"********------ start download for ideal------------******");
//        __weak HttpVideoFileResponse * weakSelf = self;
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);// 页面刷新的时间基数
//        dispatch_after(popTime, th_download_, ^(void){
//            [weakSelf downloadTimer:item];
//        });
//    }
//
//}

- (UInt64)offset
{
    return fileOffset_;
}
- (void)setOffset:(UInt64)offset
{
    NSLog(@"PLAY OFFSET:[%p](%llu)", self, offset);
    
#ifdef COMPARE_DIFF
//    UInt64 orgOffset = fileOffset_;
#endif
    fileOffset_ = offset;
    aborted = NO;
    //open file faiure
#ifdef COMPARE_DIFF
    if (![self openFileIfNeeded])
    {
//        fileOffset_ = orgOffset;
        return;
    }
    [fileHandle_ seekToFileOffset:fileOffset_ - currentTempFileInfo_.offset];
#endif
}
- (BOOL)openFileIfNeeded
{
    if (aborted)
    {
        return NO;
    }
    if([self needBreakLoop])
    {
        [self abort];
        return NO;
    }
    if(currentTempFileInfo_)
    {
        //offset 是否在本文件内，不在则需要更换文件
        BOOL offsetInset = currentTempFileInfo_.offset <= fileOffset_
        && currentTempFileInfo_.offset + currentTempFileInfo_.lengthFull -1 >= fileOffset_;
        
        if (fileHandle_ && offsetInset &&currentTempFileInfo_)
        {
            return YES;
        }
    }
    
    //需要更换文件，如果文件不在，说明请求错误或者初建的文件列表不完整
    currentTempFileInfo_ = [self getCurrentFileInfo:fileOffset_];
    
    int i = 0;
    while(!currentTempFileInfo_ || currentTempFileInfo_.length< currentTempFileInfo_.lengthFull)
    {
        NSLog(@"ERROR RD:(%@--%llu-DW:%llu) offset:%llu .",[currentItem_.tempFilePath lastPathComponent],
              (unsigned long long)currentTempFileInfo_.isDownloading,
              currentTempFileInfo_.offset,fileOffset_);
        if(!currentTempFileInfo_ || !currentTempFileInfo_.isDownloading) //文件不存在或者没有处理下载过程中，则延时一会再检查
        {
            [vdcManager_ downloadNextSlide:currentItem_ offset:fileOffset_ immediate:YES];
            [NSThread sleepForTimeInterval:0.2];
            if(!currentItem_)
            {
                currentItem_ = [vdcManager_ getVDCItem:key_];
            }
            if(i >= 5)
            {
                [self abort];
                return NO;
            }
            else
            {
                i ++;
                continue;
            }
        }
        else if(currentTempFileInfo_.isDownloading) //如果正在下载，就一直等
        {
            [NSThread sleepForTimeInterval:0.2];
            continue;
        }
    }
    return [self openFile];
}

#pragma mark - funs
- (void)abort
{
    if(fileHandle_)
    {
        [fileHandle_ closeFile];
        PP_RELEASE(fileHandle_);
    }
    [connection_ responseDidAbort:self];
    aborted = YES;
    //已经退出
    [vdcManager_ didStopLocalWebRequest:currentItem_];
    //    cancelHttpVideoResponse = NO;
}

- (BOOL)openFile
{
    if(fileHandle_)
    {
        [fileHandle_ closeFile];
        PP_RELEASE(fileHandle_);
    }
    if(!currentTempFileInfo_)
    {
        [self abort];
        return NO;
    }

    int i = 0;
    
    NSString * currentFilePath = currentTempFileInfo_.filePath;
    
//    //如果文件不在，则重试，两次失败后，报错。
//    while (![self needBreakLoop])
//    {
//        //检查本地文件是否存在
//        UInt64 size = 0;
//        NSString * newPath = nil;
//        if([udManager_ isFileExistAndNotEmpty:currentFilePath size:&size pathAlter:&newPath])
//        {
//            if(size>=currentTempFileInfo_.lengthFull)
//            {
//                currentTempFileInfo_.length = size;
//                break;
//            }
//            if(newPath && newPath !=currentFilePath)
//            {
//                currentFilePath = newPath;
//            }
//        }
//        
//        NSLog(@"sleep FO:%@",currentTempFileInfo_.fileName);
//        i ++;
//        if(i>2 && !currentTempFileInfo_.isDownloading)
//        {
//            if(fileHandle_) [fileHandle_ closeFile];
//            PP_RELEASE(fileHandle_);
//            [self abort];
//            return NO;
//        }
//    }
    
    fileHandle_ = PP_RETAIN([NSFileHandle fileHandleForReadingAtPath:currentFilePath]);
    
    //如果打开文件失败,重试几次
    while (!fileHandle_)
    {
        NSLog(@"ERROR (%i) OP: %@",i,currentFilePath);
        [NSThread sleepForTimeInterval:0.1];
        
        //检查本地文件是否存在
        UInt64 size = 0;
        NSString * newPath = nil;
        if([udManager_ isFileExistAndNotEmpty:currentFilePath size:&size pathAlter:&newPath])
        {
            if(size>=currentTempFileInfo_.lengthFull)
            {
                currentTempFileInfo_.length = size;
            }
            else if(!currentTempFileInfo_.isDownloading)
            {
                currentTempFileInfo_.length = size;
            }
            if(newPath && newPath !=currentFilePath)
            {
                currentFilePath = newPath;
            }
            if(!currentTempFileInfo_.isDownloading && currentTempFileInfo_.length==0)
            {
                [self abort];
                return NO;
            }
            continue;
        }
        if([self needBreakLoop] || (i>4 && currentTempFileInfo_.isDownloading==NO))
        {
            [self abort];
            return NO;
        }
        
        fileHandle_ = PP_RETAIN([NSFileHandle fileHandleForReadingAtPath:currentFilePath]);
        i ++;
    }
    NSLog(@"OP (%i) OK %@ ",i,currentTempFileInfo_.fileName);
    
    return YES;
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    // Determine how much data we should read.
    //
    // It is OK if we ask to read more bytes than exist in the file.
    // It is NOT OK to over-allocate the buffer.
    NSMutableData * allData = [NSMutableData new];
    
    
    UInt64 bytesLeftInFile = 0;
    if(fileOffset_ < fileLength_)
        bytesLeftInFile = fileLength_ - fileOffset_;
    
    NSUInteger bytesToRead = (NSUInteger)MIN(length, bytesLeftInFile);
    
    NSLog(@"READ :(%llu , %llu)",fileOffset_,(unsigned long long)bytesToRead);
    
    //从多个文件中读取数据（有可能）
#ifdef COMPARE_DIFF1
    if(bytesToRead<=0)
    {
        NSLog(@"length:%ul",length);
    }
#endif
    
    int i = 0;
    while (bytesToRead>0) {
        if (![self openFileIfNeeded])
        {
            if(i>=6)
            {
                [self abort];
            }
            if(aborted)
            {
                break;
            }
            else
            {
                [NSThread sleepForTimeInterval:0.2];
                i ++;
                continue;
            }
        }
        
        //虽然定位在此文件，但文件内容没有下载完成，并且读取的文件部分还没有下载完成，则需要等待
#ifdef COMPARE_DIFF
        if((currentTempFileInfo_.length==0 && currentTempFileInfo_.isDownloading) ||
           (currentTempFileInfo_.offset + currentTempFileInfo_.length <= fileOffset_))
#else
            if(currentTempFileInfo_.length + currentTempFileInfo_.offset < fileOffset_ + bytesToRead
               && currentTempFileInfo_.length< currentTempFileInfo_.lengthFull)
#endif
            {
                if(i%5==4)
                {
                    UInt64 fileSize = [udManager_ fileSizeAtPath:currentTempFileInfo_.filePath];
                    if(fileSize >= DEFAULT_PKSIZE && fileSize>=currentTempFileInfo_.lengthFull)
                    {
                        NSLog(@"sleep DATA:(%i in %llull)",i,fileSize);
                        currentTempFileInfo_.length = currentTempFileInfo_.lengthFull;
                        currentTempFileInfo_.isDownloading = NO;
                    }
                    else if(fileSize ==0 && (![self needBreakLoop]) &&
                            !(currentTempFileInfo_.isDownloading && currentTempFileInfo_.operation))
                    {
                        [vdcManager_ downloadTempFile:currentTempFileInfo_ urlReady:nil progress:nil completed:nil];
                    }
                }
                
                [NSThread sleepForTimeInterval:0.5];
                
                NSLog(@"sleep DATA:%i",i);
                if([self needBreakLoop])
                {
                    break;
                }
                i ++;
                
                if(i>18) break;
                continue;
            }
        
        NSData * data = nil;
        
        UInt64 bytesLeftInCurrentTempFile = currentTempFileInfo_.offset + currentTempFileInfo_.length - fileOffset_;
        
        NSUInteger bytesToReadInFile = (NSUInteger)MIN(bytesToRead, bytesLeftInCurrentTempFile);
        
#ifdef COMPARE_DIFF1
        while (!data || data.length==0){
            data = [fileHandle_ readDataOfLength:bytesToReadInFile];
            if(!data || data.length==0)
            {
                NSLog(@"sleep ZERO.%@(%llu-->%llu)",currentTempFileInfo_.fileName,fileOffset_,bytesToReadInFile);
                if([self needBreakLoop])
                {
                    break;
                }
                [vdcManager_ downloadTempFile:currentTempFileInfo_ urlReady:nil progress:nil completed:nil];
                
                [NSThread sleepForTimeInterval:0.5];
                bytesLeftInCurrentTempFile = currentTempFileInfo_.offset + currentTempFileInfo_.length - fileOffset_;
                bytesToReadInFile = (NSUInteger)MIN(bytesToRead, bytesLeftInCurrentTempFile);
                
                //                if(currentTempFileInfo_.lengthFull > currentTempFileInfo_.length)
                //                {
                //                    [vdcManager_ downloadTempFile:currentTempFileInfo_ urlReady:nil completed:nil];
                //                }
                
                if([self needBreakLoop])
                {
                    break;
                }
                i ++;
                continue;
            }
        }
#else
        data = [fileHandle_ readDataOfLength:bytesToReadInFile];
        if(!data || data.length==0)
        {
            break;
        }
#endif
        //        {
        //            NSLog(@" Error(%i) reading file(%@)", errno, currentTempFileInfo_.fileName);
        //            break;
        //        }
        //        else // (result > 0)
        //        {
        //            NSLog(@"Read [%llu]  %ld bytes from file:(%@)",fileOffset_,(long)data.length,currentTempFileInfo_.fileName);
        NSLog(@"READ (%i) OK:(%llu,%lu)",i,fileOffset_,(unsigned long)bytesToRead);
        fileOffset_ += bytesToReadInFile;
        bytesToRead -= bytesToReadInFile;
        
        [allData appendData:data];
        //        }
    }
    
    if (allData.length==0 && bytesToRead>0 )
    {
        if(currentTempFileInfo_)
        {
            NSLog(@" Error(%i) RD (%@) sub(%@)", errno, [filePath_ lastPathComponent],currentTempFileInfo_? currentTempFileInfo_.fileName:@"no tempfile");
        }
        else
        {
            NSLog(@" Error(%i) RD (%@) AB(%d)", errno, currentTempFileInfo_? currentTempFileInfo_.fileName:@"no tempfile",aborted);
        }
        if(!aborted)
            [self abort];
        return nil;
    }
    
    else // (result > 0)
    {
        //        NSLog(@"return ready bytes:%llu",allData.length);
        return PP_AUTORELEASE(allData);
    }
}

- (UInt64)contentLength
{
    return fileLength_;
}

- (NSString *)filePath
{
    return filePath_;
}

- (VDCTempFileInfo *)getCurrentFileInfo:(UInt64)offset
{
    VDCTempFileInfo * fi = nil;
    
    for(int i = 0;i<currentItem_.tempFileList.count;i++)
    {
        //    for (VDCTempFileInfo * item in currentItem_.tempFileList) {
        VDCTempFileInfo * item = [currentItem_.tempFileList objectAtIndex:i];
        if(item.offset <= fileOffset_ && item.offset + item.length-1 > fileOffset_)
        {
            fi = item;
            break;
        }
        else if(item.offset <=fileOffset_ && item.offset + item.lengthFull -1 > fileOffset_ && item.length < item.lengthFull)
        {
            if(!item.isDownloading)
            {
                UInt64 size = 0;
                NSString * newPath = nil;
                if([udManager_ isFileExistAndNotEmpty:item.filePath size:&size pathAlter:&newPath])
                {
                    item.length = size;
                    //if(item.offset <= fileOffset_ && item.offset + item.length-1 > fileOffset_)
                    //{
                    //    fi = item;
                    //    break;
                    //}
                }
            }
            //else
            //{
            fi = item;
            break;
            //}
        }
    }
    
    if(!fi && [vdcManager_ isItemDownloadCompleted:currentItem_])
    {
        fi = [[VDCTempFileInfo alloc]init];
        fi.length = currentItem_.downloadBytes;
        fi.lengthFull = currentItem_.contentLength;
        fi.offset=0;
        fi.fileName = [currentItem_.localFilePath lastPathComponent];
    }
    return fi;
}
#pragma mark - 循环控制等函数
- (void)setDownloadUrl:(NSString *)downloadUrl
{
    PP_RELEASE(downloadUrl_);
    downloadUrl_ = PP_RETAIN(downloadUrl_);
}
//HttpConnection中标记文件是否已经读取完成。原则上，不读到完成，应该不会设置为已经完成的
- (BOOL)isDone
{
    //如果本文件已经读完了
    BOOL result = (fileOffset_ == fileLength_);
    if(result && !currentItem_.needStop)
    {
        //有没有后继文件
        VDCTempFileInfo * fi = [vdcManager_ getNextTempfile:fileOffset_ item:currentItem_];
        if(!fi ||fi.isDownloading || fi.length < fi.lengthFull)
        {
            [vdcManager_ didStopLocalWebRequest:currentItem_];
        }
        else
        {
            result = NO;
        }
    }
    return result || currentItem_.needStop;
}

- (BOOL)needBreakLoop
{
    return [vdcManager_ needStopLocalWebRequest:currentItem_];
    //    return cancelHttpVideoResponse;
}
#pragma mark - dealloc
- (void)dealloc
{
    connection_ = nil;
    
    if(fileHandle_)
        [fileHandle_ closeFile];
    PP_RELEASE(fileHandle_);
    PP_RELEASE(currentItem_);
    
    PP_RELEASE(filePath_);
    PP_RELEASE(downloadUrl_);
    
    PP_SUPERDEALLOC;
}
@end

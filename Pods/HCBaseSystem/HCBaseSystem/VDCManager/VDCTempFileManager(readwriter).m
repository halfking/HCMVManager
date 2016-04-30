//
//  VDCManager(RequestTask).m
//  maiba
//
//  Created by HUANGXUTAO on 16/3/13.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "VDCManager(LocalFiles).h"
#import "VDCManager(Helper).h"
#import "VDCItem.h"
#import "VDCTempFileManager.h"
#import "VDCTempFileManager(readwriter).h"
#import <hccoren/base.h>

@implementation VDCTempFileManager(readwriter)
//NSFileHandle *fileHandleForRead_;
//NSFileHandle * fileHandleForWrite_;
//
//VDCTempFileInfo * currentTempFileInfoWrite_;
//VDCTempFileInfo * currentTempFileInfoRead_;
//
//NSString * key_;
//VDCItem * currentItem_;
//UInt64  offsetOfItem_;  //整体的偏移量
//UInt64 offsetInCurrentFile_; //当前文件内的偏移量
//
//UDManager * udManager_;

//根据VDCItem，构建当前的基础数据及信息
//- (BOOL) beginWithVDCItem:(VDCItem *)item withOffset:(UInt64)offset
//{
//    return YES;
//}
- (BOOL) writeContentToFile:(long long)startOffset content:(NSData *)content
{
    if(!content) return NO;
    
    NSInteger pos = 0;
    NSInteger contentLength = content.length;
    
    while (pos < contentLength) {
        if(![self openFileIfNeeded:NO offset:startOffset + pos tempFile:currentTempFileInfoWrite_])
        {
            break;
        }
        
        NSInteger bytesToWrite = 0;
        NSInteger writeOffset =  (NSInteger)(startOffset +  pos -currentTempFileInfoWrite_.offset);
        
        if(writeOffset <= currentTempFileInfoWrite_.length)
        {
            bytesToWrite = MIN(contentLength - pos,
                               (NSInteger)currentTempFileInfoWrite_.lengthFull + (NSInteger)currentTempFileInfoWrite_.offset - (NSInteger)startOffset - pos);
            NSLog(@"WRIT :(%llu , %ld)",startOffset+pos,(long)bytesToWrite);
            
            [fileHandleForWrite_ seekToFileOffset:writeOffset];
            
            NSData * dataToWrite = [content subdataWithRange:NSMakeRange((NSUInteger)pos, (NSUInteger)bytesToWrite)];
            [fileHandleForWrite_ writeData:dataToWrite];
            NSUInteger orgLength = (NSUInteger)currentTempFileInfoWrite_.length;
            
            currentTempFileInfoWrite_.length = writeOffset + bytesToWrite;
            currentItem_.downloadBytes += (currentTempFileInfoWrite_.length - orgLength); //考虑可能局部重写的问题。
            
        }
        else
        {
            // 如果不是从一个文件的头部开始，并且这个文件头部没有东东，如何处理？
            // 自动定位到下一个文件，本文件不写入
            bytesToWrite = (NSInteger)currentTempFileInfoWrite_.lengthFull - writeOffset;
            NSLog(@"WRIT: (%llu,%ld) NOT BEGIN FROM MARGIN,SKIP...",startOffset+pos,(long)bytesToWrite);
            if(bytesToWrite==0) break;
        }
        pos += bytesToWrite;
    }
    return YES;
}
- (NSData *)readContentFromFile:(long long)startOffset length:(NSUInteger)length
{
    NSMutableData * allData = [NSMutableData new];
#ifndef __OPTIMIZE__
    NSUInteger orgLength = length;
    long long orgOffset = startOffset;
#endif
    NSUInteger bytesTotalRead = 0;
    int i = 0;
    while (length>0) {
        if(![self openFileIfNeeded:YES offset:startOffset tempFile:currentTempFileInfoRead_])
        {
            break;
        }
        
        NSInteger bytesToRead = MIN(length,(NSInteger)currentTempFileInfoRead_.length + (NSInteger)currentTempFileInfoRead_.offset - (NSInteger)startOffset);
        NSData *data  = nil;
        if(bytesToRead>0)
        {
            
            [fileHandleForRead_ seekToFileOffset:startOffset - currentTempFileInfoRead_.offset];
            
            data = [fileHandleForRead_ readDataOfLength:(NSUInteger)bytesToRead];
            if(data && data.length>0)
            {
                i = 0;
                [allData appendData:data];
                length -= bytesToRead;
                startOffset += bytesToRead;
                bytesTotalRead += bytesToRead;
                if(bytesTotalRead > 10 * DEFAULT_PKSIZE)//不能一次性读太多文件，内存会有问题的
                {
                    break;
                }
            }
        }
#ifndef __OPTIMIZE__
        NSLog(@"READ :(%llu,%lu)--->(%llu , %lu)",orgOffset,(unsigned long)orgLength,startOffset,(unsigned long)bytesTotalRead);
#endif
        if(bytesToRead==0 || !data ||data.length==0)
        {
            i ++;
            
            [fileHandleForRead_ closeFile];
            PP_RELEASE(fileHandleForRead_);
            //            if(i >2)
            //            {
            //                break;
            //            }
            //            [NSThread sleepForTimeInterval:0.1];
            break;
        }
    }
    //#ifndef __OPTIMIZE__
    //    NSLog(@"read from file:%llu(%llu) return bytes:%llu (%llu) ",orgOffset,orgLength,bytesTotalRead,allData.length);
    //#endif
    return PP_AUTORELEASE(allData);
}

- (BOOL)openFileIfNeeded:(BOOL)isRead offset:(long long)offset tempFile:(VDCTempFileInfo *)tempFile
{
    if(offset >= currentItem_.contentLength) return NO;
    if(tempFile)
    {
        //offset 是否在本文件内，不在则需要更换文件
        BOOL offsetInset = tempFile.offset <= offset && tempFile.offset + tempFile.lengthFull -1 >= offset;
        
        if(isRead)
        {
            if (fileHandleForRead_ && offsetInset &&tempFile)
            {
                return YES;
            }
        }
        else
        {
            if (fileHandleForWrite_ && offsetInset &&tempFile)
            {
                return YES;
            }
        }
    }
    
    //需要更换文件，如果文件不在，说明请求错误或者初建的文件列表不完整
    tempFile = [self getCurrentTempFileInfo:currentItem_ offset:offset];
    
    return [self openFile:isRead file:tempFile];
}



- (BOOL)openFile:(BOOL)isRead file:(VDCTempFileInfo *)tempFile
{
    if(isRead)
    {
        if(fileHandleForRead_)
        {
            [fileHandleForRead_ closeFile];
            PP_RELEASE(fileHandleForRead_);
        }
    }
    else
    {
        if(fileHandleForWrite_)
        {
            [fileHandleForWrite_ closeFile];
            PP_RELEASE(fileHandleForWrite_);
        }
    }
    if(!tempFile)
    {
        return NO;
    }
    
    
    NSString * currentFilePath = tempFile.filePath;
    
    //如果文件不在，则重试，两次失败后，报错。
    {
        //检查本地文件是否存在
        UInt64 size = 0;
        NSString * newPath = nil;
        if([udManager_ isFileExistAndNotEmpty:currentFilePath size:&size pathAlter:&newPath])
        {
            if(size>tempFile.lengthFull)
            {
                tempFile.length = size;
            }
            if(newPath && newPath !=currentFilePath)
            {
                currentFilePath = newPath;
            }
        }
        else
        {
            if(isRead)
            {
                return NO;
            }
            else
            {
                //写入时，如果文件不存在，则创建一个
                [[NSFileManager defaultManager]createFileAtPath:currentFilePath contents:nil attributes:nil];
                //                tempFile.fileName = [newPath lastPathComponent];
                //                currentFilePath = newPath;
            }
        }
        
        NSLog(@"OPEN:%@ FOR READ:(%d)",tempFile.fileName,isRead);
    }
    
    if(isRead)
    {
        fileHandleForRead_ = PP_RETAIN([NSFileHandle fileHandleForReadingAtPath:currentFilePath]);
        currentTempFileInfoRead_ = tempFile;
    }
    else
    {
        fileHandleForWrite_ = PP_RETAIN([NSFileHandle fileHandleForWritingAtPath:currentFilePath]);
        currentTempFileInfoWrite_ = tempFile;
    }
    
    return YES;
}


//完成写入，关闭文件，并且检查是否下载完成。如果下载完成，则自动合成文件
- (BOOL) finishedWriting
{
    if(fileHandleForWrite_)
    {
        [fileHandleForWrite_ closeFile];
        fileHandleForWrite_ = nil;
    }
    if(!currentItem_) return NO;
    if(currentItem_.localFilePath && currentItem_.localFilePath.length>2)
    {
        if(![HCFileManager isFileExistAndNotEmpty:currentItem_.localFilePath size:nil])
        {
            if(currentItem_.tempFileList && currentItem_.tempFileList.count>1)
            {
                currentItem_.downloadBytes = 0;
                for (VDCTempFileInfo * fi in currentItem_.tempFileList) {
                    currentItem_.downloadBytes += fi.length;
                }
            }
            if(currentItem_.contentLength>0 && currentItem_.contentLength <= currentItem_.downloadBytes)
            {
                [[VDCManager shareObject]combinateTempFiles:currentItem_ tempFilePath:currentItem_.tempFilePath targetFilePath:currentItem_.localFilePath];
            }
            else if(currentItem_.contentLength>0 && currentItem_.contentLength - 2 * DEFAULT_PKSIZE <=currentItem_.downloadBytes)
            {
                //当还剩余少量文件时，直接下载完成
                NSLog(@"当还剩余少量文件时，直接下载完成");
                [[VDCManager shareObject]downloadUrl:currentItem_.remoteUrl title:currentItem_.title urlReady:nil progress:nil completed:nil];
            }
            [[VDCManager shareObject]rememberDownloadUrl:currentItem_ tempPath:currentItem_.tempFilePath];
        }
    }
    return YES;
}

- (void) close
{
    [self.connection cancel];
    if(fileHandleForRead_)
    {
        [fileHandleForRead_ closeFile];
        fileHandleForRead_ = nil;
    }
    [self finishedWriting];
    currentTempFileInfoRead_ = nil;
    currentTempFileInfoWrite_ = nil;
    currentItem_ = nil;
}
//校正Offset，让它边界对齐
- (long long) correctOffset:(long long)offset
{
    offset = (int)(offset/DEFAULT_PKSIZE) * DEFAULT_PKSIZE;
    return offset;
}
- (long long) alignOffsetWithFileDownloaded:(VDCItem *)item offset:(long long)offset
{
    if(offset>0 && item && item.tempFileList && item.tempFileList.count>0)
    {
        //校正偏移量，与文件中未下完部分对接
        VDCTempFileInfo * fi = [self getCurrentTempFileInfo:item offset:offset];
        if(fi)
        {
            if(fi.offset + fi.length < offset)
            {
                offset = (NSUInteger)(fi.offset + fi.length);
            }
        }
    }
    return offset;
}
- (VDCTempFileInfo *)getCurrentTempFileInfo:(VDCItem *)item offset:(long long) offset
{
    if(!item) return nil;
    @synchronized(item) {
        VDCTempFileInfo * target = nil;
        for (int i = 0; i< (int)item.tempFileList.count; i++) {
            VDCTempFileInfo * fi = item.tempFileList[i];
            if(fi.offset <= offset && fi.offset + fi.lengthFull > offset)
            {
                target = fi;
                break;
            }
        }
        if(!target && (item.downloadBytes >= item.contentLength|| (item.localFilePath && item.localFilePath.length>0)))
        {
            BOOL isExists = NO;
            NSString * newPath = [udManager_ checkPathForApplicationPathChanged:item.localFilePath isExists:&isExists];
            if(isExists)
            {
                target = [[VDCTempFileInfo alloc]init];
                
                target.offset = 0;
                target.length = item.contentLength;
                target.lengthFull = item.contentLength;
                target.fileName = [newPath lastPathComponent];
                target.parentItem = item;
                if(!item.tempFileList) item.tempFileList = [NSMutableArray new];
                
                [item.tempFileList addObject:target];
                [[VDCManager shareObject]sortFiles:item.tempFileList];
                
                item.downloadBytes = item.contentLength;
            }
            else
            {
                newPath = [udManager_ checkPathForApplicationPathChanged:item.tempFilePath isExists:&isExists];
                if(isExists)
                {
                    target = [[VDCTempFileInfo alloc]init];
                    
                    target.offset = 0;
                    target.length = item.contentLength;
                    target.lengthFull = item.contentLength;
                    target.fileName = [newPath lastPathComponent];
                    target.parentItem = item;
                    
                    if(!item.tempFileList) item.tempFileList = [NSMutableArray new];
                    
                    [item.tempFileList addObject:target];
                    [[VDCManager shareObject]sortFiles:item.tempFileList];
                    
                }
            }
        }
        if(!target && offset < item.contentLength)
        {
            offset = [self correctOffset:offset];
            target = [[VDCManager shareObject]createTempFileByOffset:offset item:item];
            if(!item.tempFileList) item.tempFileList = [NSMutableArray new];
            [item.tempFileList addObject:target];
            if(target)
            {
                [[VDCManager shareObject]sortFiles:item.tempFileList];
            }
        }
        return target;
    }
}
- (BOOL)getNextRangeToDownload:(VDCItem *)item offset:(long long)offset range:(NSRange *)range
{
    if(!item || !item.tempFileList || item.tempFileList.count <2)
    {
        *range = NSMakeRange(0, DEFAULT_PKSIZE);
        return NO;
    }
    BOOL begin = NO;
    int location = -1;
    int length = 0;
    for (VDCTempFileInfo * fi in item.tempFileList) {
        if((!begin) && (NSInteger)fi.offset >= (NSInteger)offset - DEFAULT_PKSIZE )
        {
            begin = YES;
        }
        if(begin)
        {
            if(fi.length < fi.lengthFull && location<0)
            {
                location = (int)(fi.length + fi.offset);
                continue;
            }
            if(location>=0 && fi.length>=fi.lengthFull&&fi.length>0)
            {
                length = (int)(fi.offset - location);
                break;
            }
        }
    }
    if(location>=0 && length==0)
    {
        length = (int)(item.contentLength -  location);
    }
    if(location<0 || length==0)
    {
        *range = NSMakeRange(0, DEFAULT_PKSIZE);
        return NO;
    }
    else
    {
        *range = NSMakeRange(location, length);
        return  YES;
    }
}

@end

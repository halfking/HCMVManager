//
//  UDManager.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/14.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "UDManager.h"
#import <hccoren/base.h>
#import <hccoren/JSON.h>
#import <hccoren/database.h>
#import <hccoren/cmd.h>
//#import "HCDbHelper.h"
#import "QiniuSDK.h"
#import "UDInfo.h"
#import "UDManager(Helper).h"
#import "AFNetworking.h"
#import <hccoren/RegexKitLite.h>

#import "UserManager.h"

#import <CommonCrypto/CommonDigest.h>
#import "CMD_GetUploadToken.h"
#import "CMD_GetDownloadToken.h"
#import "HXNetwork.h"

#define CC_MD5_DIGEST_LENGTH    16          /* digest length in bytes */
#define CC_MD5_BLOCK_BYTES      64          /* block size in bytes */
#define CC_MD5_BLOCK_LONG       (CC_MD5_BLOCK_BYTES / sizeof(CC_LONG))


@interface UDManager()
{
    NSMutableDictionary * items_;
    QNUploadManager * upManager_;
    NSString * uploadTokenCover_;
    NSString * uploadTokenHome_;
    NSString * uploadTokenMusic_;
    NSString * uploadTokenChat_;
    NSString * uploadTokenMTVS_;
    
    NSString * downloadToken_;
}
@end
@implementation UDManager
@synthesize UserID;

SYNTHESIZE_SINGLETON_FOR_CLASS_NEW(UDManager)

- (id) init
{
    if(self = [super init])
    {
        items_ = [NSMutableDictionary new];
        reservedFileNames_ = [NSArray arrayWithObjects:@"startup.mp4",@"empty.mp3",@"startup.m4v",@"startup.mp3",@"avatar.png", nil];
        
        NSError *error = nil;
        QNFileRecorder *file = [QNFileRecorder fileRecorderWithFolder:[NSTemporaryDirectory() stringByAppendingString:@"qiniutest"] error:&error];
        if(error)
        {
            NSLog(@"**recorder error %@", error);
        }
        upManager_ = [[QNUploadManager alloc] initWithRecorder:file];
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(changeUserID:) name:NT_USERIDCHANGED object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(willEnterBackground:) name:NT_WILLENTERBACK object:nil];
        UserID = [[UserManager sharedUserManager]userID];
    }
    return self;
}
- (void)willEnterBackground:(NSNotification *)notification
{
    [self stopAllUDs:NO delegate:nil];
}
- (void)changeUserID:(NSNotification *)no
{
    UserID = [UserManager sharedUserManager].userID;
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    PP_RELEASE(uploadTokenCover_);
    PP_RELEASE(uploadTokenHome_);
    PP_RELEASE(uploadTokenMusic_);
    PP_RELEASE(uploadTokenMTVS_);
    PP_RELEASE(uploadTokenChat_);
    
    PP_RELEASE(tempFileRoot_);
    PP_RELEASE(applicationRoot_);
    
    PP_RELEASE(upManager_);
    PP_RELEASE(items_);
    PP_RELEASE(downloadToken_);
    
}
#pragma mark - events
- (NSString *)getUploadTocken:(int)domainType
{
    switch (domainType) {
        case 1:
            return uploadTokenCover_;
        case 2:
            return uploadTokenMTVS_;
        case 3:
            return uploadTokenMusic_;
        case 4:
            return uploadTokenChat_;
        default:
            return uploadTokenHome_;
    }
}
- (int)getDomainTypeByToken:(NSString *) token
{
    if(!token) return 0;
    if([token isEqual:uploadTokenCover_]) return (int)DOMAIN_COVER;
    if([token isEqual:uploadTokenMTVS_]) return (int)DOMAIN_MTVS;
    if([token isEqual:uploadTokenMusic_]) return (int)DOMAIN_MUSIC;
    if ([token isEqual:uploadTokenChat_]) return (int)DOMAIN_CHAT;
    return 0;
}
- (void)setUploadTocken:(int)domainType token:(NSString *)token
{
    switch (domainType) {
        case 1:
            PP_RELEASE(uploadTokenCover_);
            uploadTokenCover_ = PP_RETAIN(token);
            break;
        case 2:
            PP_RELEASE(uploadTokenMTVS_);
            uploadTokenMTVS_ = PP_RETAIN(token);
        case 3:
            PP_RELEASE(uploadTokenMusic_);
            uploadTokenMusic_ = PP_RETAIN(token);
            break;
        case 4:
            PP_RELEASE(uploadTokenChat_);
            uploadTokenChat_ = PP_RETAIN(token);
            break;
        default:
            PP_RELEASE(uploadTokenHome_);
            uploadTokenHome_ = PP_RETAIN(token);
    }
}
//自动将Token超时 3600秒
- (void)setUploadTokenExpire:(NSTimer *)timer
{
    int domainType = [timer.userInfo intValue];
    switch (domainType) {
        case 1:
            PP_RELEASE(uploadTokenCover_);
            break;
        case 2:
            PP_RELEASE(uploadTokenMTVS_);
            break;
        case 3:
            PP_RELEASE(uploadTokenMusic_);
            break;
        case 4:
            PP_RELEASE(uploadTokenChat_);
            break;
        default:
            PP_RELEASE(uploadTokenHome_);
            break;
    }
    //    if([[timer.userInfo objectAtIndex:@"domaintype"]intValue])
    //    PP_RELEASE(uploadToken_);
}
- (void)setDownloadTokenExpire:(NSTimer *)timer
{
    PP_RELEASE(downloadToken_);
}

//获取Key = UID + MD5
- (NSString *)getKey:(NSString *)pathOrUrl
{
    return [self getKey:pathOrUrl andUserID:UserID];
}
- (NSString *)getKey:(NSString *)pathOrUrl andUserID:(long)userID
{
    NSString * filename = [CommonUtil md5Hash:pathOrUrl];
    
//    const char *str = [pathOrUrl UTF8String];
//    if (str == NULL) {
//        str = "";
//    }
//    unsigned char r[CC_MD5_DIGEST_LENGTH];
//    CC_MD5(str, (CC_LONG)strlen(str), r);
//    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
//                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return [NSString stringWithFormat:@"%lx-%@",userID,filename];
}
//从7牛的Url中获取Key值
//如 http://7xi4n3.com1.z0.glb.clouddn.com/zPv7enqD94uy9R4wxod6QXtT1MU=/lqeKS-rK0U1G5PSeDrcD3NiPBlR9
- (NSString *)getKeyFromQiniuUrl:(NSString *)url
{
    if(!url||url.length==0) return nil;
    NSString * reg = @"(\\.com/|\\.cn/|\\.net/|\\.tv/)(.*)";
    NSArray * list = [url componentsMatchedByRegex:reg capture:2];
    NSLog(@"list:%lu",(unsigned long)list.count);
    if(list.count>0)
        return [list objectAtIndex:0];
    else
        return nil;
}
#pragma mark - get or build item
- (UDInfo *)queryItem:(NSString *)key
{
    if(![self isKeyValid:key]) return nil;
    @synchronized(self)
    {
        UDInfo * item = (UDInfo*)[items_ objectForKey:key];
        if(item)
        {
            return item;
        }
        else
        {
            //不在当前队列中，表示没有在上传进程中
            item = [self queryItemFromDB:key];
            if(item && item.Status==1)
            {
                item.Status =0;
            }
            return item;
        }
    }
}
- (UDInfo *)getItemByFileUrl:(NSString *)fileUrl
{
    if(!fileUrl || fileUrl.length==0) return nil;
    //    fileUrl = [fileUrl lowercaseString];
    
    //check file is exists or not
    NSString * path = [self localFileFullPath:fileUrl];
    if(!path)
    {
        return nil;
    }
    NSLog(@"file full Path:%@",path);
    BOOL isExists = NO;
    UInt64 fileSize = 0;
    
    isExists = [self isFileExistAndNotEmpty:path size:&fileSize pathAlter:&path];
    if(!isExists || !path)
    {
        UDInfo * item = [UDInfo new];
        item.Key = nil;
        item.Status = 9;
        item.ErrorInfo = [NSString stringWithFormat:@"待上传的文件[%@]不存在。",[path lastPathComponent]];
        return item;
    }
    
    //build information for item
    NSString * pathWithoutApp = [self removeApplicationPath:path];
    if(!pathWithoutApp||pathWithoutApp.length==0) pathWithoutApp = fileUrl;
    NSString * key = [self getKey:pathWithoutApp];
    UDInfo * item = (UDInfo *)[items_ objectForKey:key];
    // if exists
    if (!item) {
        item = [self queryItemFromDB:key];
        if(!item)
        {
            item = [UDInfo new];
        }
    }
    else if(item.Status==1) //如果正在上传，则后续不需要处理
    {
        return item;
    }
    
    item.OrgUrl = fileUrl;
    item.LocalFileName = path;
    item.RemoteUrl = [self remoteUrl:key domainType:item.DomainType];
    item.Key = key;
    item.IsUpload = YES;
    item.Status = 0;
    item.Progress = 0;
    item.TotalBytes =0;
    item.DateCreated = [CommonUtil stringFromDate:[NSDate date]];
    
    item.RemainBytes = (unsigned long)fileSize;
    
    
    //加入到数据库中，备下次启动时再处理
    @synchronized(self)
    {
        if([self insertItemToDB:item])
        {
            [items_ setObject:item forKey:item.Key];
        }
        else
        {
            NSLog(@"** save uditem to db failure.");
            [items_ setObject:item forKey:item.Key];
        }
    }
    return item;
}
#pragma mark - upload
- (void)stopProgress:(NSString *)key delegate:(id<UDDelegate>)delegate
{
    UDInfo * item = [items_ objectForKey:key];
    if(!item || item.Key.length==0)
    {
        NSLog(@" item is null.");
        if(delegate)
        {
            [delegate UDManager:self key:key didStop:nil];
        }
        return;
    }
    
    item.delegate = delegate;
    if(item.IsUpload)
    {
        if(item.Status ==1 ||item.Percent < 1)
        {
            @synchronized(self)
            {
                if(item.Status ==1 ||item.Percent < 1)
                {
                    item.WillStop = YES;
                }
            }
            item.Status = 6;
        }
    }
    else
    {
        if(item.operate)
        {
            [item.operate cancel];
            item.Status = 6;
            item.operate = nil;
        }
    }
}
- (void)cancelProgress:(NSString *)key delegate:(id<UDDelegate>)delegate
{
    if (!key) return;
    
    UDInfo * item = [items_ objectForKey:key];
    if(!item || item.Key.length==0)
    {
        NSLog(@" item is null.");
    }
    item.delegate = delegate;
    if(item.IsUpload)
    {
        if(item.Status ==1 ||item.Percent < 1)
        {
            @synchronized(self)
            {
                if(item.Status ==1 ||item.Percent < 1)
                {
                    item.WillStop = YES;
                }
                [self removeItemFromDB:key];
                [items_ removeObjectForKey:key];
            }
        }
    }
    else
    {
        if(item.operate)
        {
            [item.operate cancel];
            item.operate = nil;
        }
        
        [self removeItemFromDB:key];
        [items_ removeObjectForKey:key];
    }
}

- (NSString *) addUploadProgress:(NSString *)fileUrl domainType:(int)domainType delegate:(id<UDDelegate>)delegate autoStart:(BOOL)autoStart
{
    UDInfo * item = [self getItemByFileUrl:fileUrl];
    if(!item) return nil;
    
    item.DomainType = domainType;
    item.delegate = delegate;
    
    if(item.Status == 9)
    {
        if(delegate)
        {
            [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(postError:) userInfo:item repeats:NO];
        }
        return nil;
    }
    
    if(!autoStart) return item.Key;
    
    //upload....
    [self startUploadItem:item.Key delegate:delegate];
    return item.Key;
}
//直接上传一个文件
- (NSString *)  uploadFile:(NSString *)filePath domainType:(DOMAIN_TYPE)domainType progress:(UploadProgress) progress completed:(UploadCompleted)completed failure:(UploadFailure)failure stop:(NeedStop)needstop
{
    
    UDInfo * item = [self getItemByFileUrl:filePath];
    if(!item)
    {
        if(failure)
        {
            failure(filePath,10,@"没有正确生成上传进程(nil).");
        }
        return nil;
    }
    if(item.Status==9)
    {
        if(failure)
        {
            failure(filePath,9,item.ErrorInfo);
        }
        return item.Key;
    }
    
    item.DomainType = domainType;
    item.delegate = nil;
    
    NSString * key = item.Key;
    NSString * token = [self getUploadTocken:(int)domainType];
    //get token
    if(token && token.length>0)
    {
        //        [self doUploadQiniu:item];
        [self doUploadQiniuN:item key:key token:token progress:progress completed:completed failure:failure stop:needstop];
    }
    else
    {
        CMD_GetUploadToken * cmd = [CMD_GetUploadToken new];
        cmd.domainType = (int)domainType;
        
        cmd.CMDCallBack = ^(HCCallbackResult *result)
        {
            NSString * uploadToken = [result.DicNotParsed objectForKey:@"uptoken"];
            
            if(!uploadToken)
            {
                NSLog(@"**get upload tocken failure");
                if(failure)
                {
                    failure(filePath,-1,@"上传令牌获取失败!");
                }
            }
            else
            {
                [self setUploadTocken:(int)domainType token:uploadToken];
                [NSTimer timerWithTimeInterval:TOKEN_TIMESPAN
                                        target:self
                                      selector:@selector(setUploadTokenExpire:)
                                      userInfo:[NSNumber numberWithInt:(int)domainType] repeats:NO];
                //                [self doUploadQiniu:item];
                [self doUploadQiniuN:item key:key token:uploadToken progress:progress completed:completed failure:failure stop:needstop];
                
            }
        };
        [cmd sendCMD];
    }
    return key;
}
- (void)postError:(NSTimer *)timer
{
    if(timer && timer.userInfo)
    {
        UDInfo * item = (UDInfo *)timer.userInfo;
        if(item.delegate)
        {
            [item.delegate UDManager:self key:item.Key didFailure:item];
        }
    }
}


#pragma mark - 7niu call
- (BOOL)startUploadItem:(NSString *)key delegate:(id<UDDelegate>)delegate
{
    if(![self isKeyValid:key]) return NO;
    UDInfo * item = [items_ objectForKey:key];
    
    if(!item)
    {
        NSLog(@"not find upload item for key %@",key);
        
        //        if(delegate && [delegate respondsToSelector:@selector(UDManager:key:didFailure:)])
        //        {
        //            [delegate UDManager:self key:key didFailure:nil];
        //        }
        return NO;
    }
    else if(item.Status==1) //如果正在上传
    {
        return NO;
    }
    
    item.delegate = delegate;
    //get token
    NSString * uploadToken = [self getUploadTocken:item.DomainType];
    if(uploadToken)
    {
        [self doUploadQiniuN:item key:item.Key token:uploadToken progress:nil completed:nil failure:nil stop:nil];
    }
    else
    {
        __weak UDManager * weakSelf = self;
        __weak id<UDDelegate> weakDelegate = delegate;
        __weak UDInfo * weakItem = item;
        CMD_GetUploadToken * cmd = [CMD_GetUploadToken new];
        cmd.domainType = item.DomainType;
        
        cmd.CMDCallBack = ^(HCCallbackResult *result)
        {
            __strong UDInfo * strongItem = weakItem;
            __strong UDManager * strongSelf = weakSelf;
            __strong id<UDDelegate> strongDelegate = weakDelegate;

            NSString * token = [result.DicNotParsed objectForKey:@"uptoken"];
            [self setUploadTocken:strongItem.DomainType token:token];
            

            if(!token)
            {
                NSLog(@"**get upload tocken failure");
                if(strongDelegate && [strongDelegate respondsToSelector:@selector(UDManager:key:didFailure:)])
                {
                    strongItem.ErrorInfo = @"上传令牌获取失败!";
                    [strongDelegate UDManager:self key:strongItem.Key didFailure:strongItem];
                }
            }
            else
            {
                [NSTimer timerWithTimeInterval:TOKEN_TIMESPAN
                                        target:strongSelf
                                      selector:@selector(setUploadTokenExpire:)
                                      userInfo:[NSNumber numberWithInt:(int)item.DomainType] repeats:NO];
                
                [strongSelf doUploadQiniuN:strongItem key:strongItem.Key token:token progress:nil completed:nil failure:nil stop:nil];
//                [self doUploadQiniu:item];
                
            }
        };
        [cmd sendCMD];
    }
    return YES;
}

- (BOOL)doUploadQiniuN:(UDInfo *)item key:(NSString *)key token:(NSString *)token progress:(UploadProgress)progress completed:(UploadCompleted)completed failure:(UploadFailure)failure stop:(NeedStop)needstop
{
    //    NSString * token =uploadToken_;
    __block CGFloat lastPostPercent = -1;
    __weak UDManager * weakSelf = self;
    __weak UDInfo * weakItem = item;
    
    QNUploadOption *opt = [[QNUploadOption alloc] initWithMime:nil /*[self getMimeType:item.LocalFilePath]*/
                                               progressHandler:^(NSString *key, float percent)
                           {
                               BOOL needPost = NO;
                               if(round(percent *100) > lastPostPercent || percent==1)
                               {
                                   needPost = YES;
                                   lastPostPercent = round(percent* 100) +1;
                                   NSLog(@"progress min:%f",lastPostPercent/100.f);
                               }
                               __strong UDInfo * strongItem = weakItem;
                               __strong UDManager * strongSelf = weakSelf;
                               
                               strongItem.Percent = percent;
                               //                               NSLog(@"progress %f", percent);
                               strongItem.Status = 1;
                               if(needPost)
                               {
                                   if(strongItem)
                                   {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [[DBHelper sharedDBHelper]insertData:strongItem needOpenDB:YES forceUpdate:YES];
                                       });
                                   }
                                   if(progress)
                                   {
                                       progress(strongItem.LocalFilePath,percent);
                                   }
                                   else if(strongItem.delegate && [strongItem.delegate respondsToSelector:@selector(UDManager:key:progress:)])
                                   {
                                       [strongItem.delegate UDManager:strongSelf key:strongItem.Key progress:strongItem];
                                   }
                                   else
                                   {
                                       [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADPROGRESSCHANGED object:strongItem userInfo:nil];
                                   }
                               }
                           }
                                                        params:@{ @"x:foo":@"fooval" }
                                                      checkCrc:YES
                                            cancellationSignal: ^BOOL(void)
                           {
                               __strong UDInfo * strongItem = weakItem;
                               if(needstop)
                               {
                                   return needstop(strongItem.LocalFilePath,key);
                               }
                               else if(strongItem.WillStop)
                               {
                                   strongItem.WillStop = NO; //将状态复位
                                   return YES;
                               }
                               return NO;
                           }];
    
    [upManager_ putFile:item.LocalFilePath
                    key:key
                  token:token
               complete:^(QNResponseInfo * info,NSString * key,NSDictionary * resp)
     {
         NSLog(@"%@", info);
         NSLog(@"%@", resp);
         
         //         hash	是	目标资源的hash值，可用于ETag头部。
         //         key	是	目标资源的最终名字，可由七牛云存储自动命名。
         
         /*__27-[UDManager doUploadQiniu:]_block_invoke132) (UDManager.m:212) {
          hash = "ln5CrjJvwJ4LMir9drXJBzwVB5_Z";
          key = "0-685b0161be1f7332911a73445b658e1d";
          "x:foo" = fooval;
          }
          */
         __strong UDInfo * strongItem = weakItem;
         __strong UDManager * strongSelf = weakSelf;
         
         if(info.statusCode==200)
         {
             //             NSString * hash = [resp objectForKey:@"hash"];
             @synchronized(self)
             {
                 strongItem.Status = 4;
                 strongItem.RemoteUrl = [self remoteUrl:strongItem.Key domainType:strongItem.DomainType];
                 strongItem.DateModified = [CommonUtil stringFromDate:[NSDate date]];
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [[DBHelper sharedDBHelper]insertData:strongItem needOpenDB:YES forceUpdate:YES];
                 });
                 if (items_ && [items_ objectForKey:strongItem.Key]) {
                     [items_ removeObjectForKey:strongItem.Key];
                 }
             }
             if(completed)
             {
                 completed(strongItem.LocalFilePath,strongItem.RemoteUrl);
             }
             else if(strongItem.delegate && [strongItem.delegate respondsToSelector:@selector(UDManager:key:didCompleted:)])
             {
                 [strongItem.delegate UDManager:strongSelf key:strongItem.Key didCompleted:strongItem];
             }
             else
             {
                 [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADCOMPLETED object:strongItem userInfo:nil];
             }
         }
         else
         {
             strongItem.Status = info.statusCode;
             if(info.error)
             {
                 strongItem.ErrorInfo = [info.error description];
             }
             else if([resp objectForKey:@"error"])
             {
                 strongItem.ErrorInfo = [resp objectForKey:@"error"];
             }
             strongItem.DateModified = [CommonUtil stringFromDate:[NSDate date]];
             //             @synchronized(mm)
             //             {
             dispatch_async(dispatch_get_main_queue(), ^{
                 [[DBHelper sharedDBHelper]insertData:strongItem needOpenDB:YES forceUpdate:YES];
             });
             //             }
             if(failure)
             {
                 failure(strongItem.LocalFilePath,strongItem.Status,strongItem.ErrorInfo);
             }
             else if(strongItem.delegate && [strongItem.delegate respondsToSelector:@selector(UDManager:key:didFailure:)])
             {
                 [strongItem.delegate UDManager:self key:strongItem.Key didFailure:strongItem];
             }
             else
             {
                 [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADSTATECHANGED object:strongItem userInfo:nil];
             }
             
         }
     }
                 option:opt
     ];
    
    return YES;
}

#pragma mark - download
//- (void)postCompletedEvent:(NSTime*)timer
//{
//
//}
- (NSString *) addDownloadProgress:(NSString *)fileUrl localFileExt:(NSString *)fileExt delegate:(id<UDDelegate>)delegate autoStart:(BOOL)autoStart
{
    if(!fileUrl || fileUrl.length==0) return nil;
    //    fileUrl = [fileUrl lowercaseString];
    NSString * key = [self getKey:fileUrl];
    //    if(key==nil||key.length==0)
    //    {
    //        key = [self getKey:fileUrl];
    //    }
    //check file is exists or not
    NSString * ext = fileExt && fileExt.length>0?[NSString stringWithFormat:@"%@",fileExt]:@"mp3";
    NSString * path = [self localFileFullPath:[NSString stringWithFormat:@"%@.%@",key,ext]];// [self getLocalFilePathForUrl:fileUrl extension:@"mp3_"];
    if(!path)
    {
        return nil;
    }
    //如果文件已经存在，则判断是否过期，如果过期则重新下载，不过期则不下载
    NSFileManager * fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:path])
    {
        BOOL notice = TRUE;
        NSLog(@"file exists:%@",path);
        //判断文件日期
        NSError * error = nil;
        NSDictionary * attributes = [fm attributesOfItemAtPath:path error:&error];
        if(error)
        {
            NSLog(@"**get attribute of file[%@ ]failure.",path);
            NSLog(@"**description:%@",[error description]);
        }
        else
        {
            //一个月前的文件作废
            NSDate * cDate = [attributes objectForKey:NSFileCreationDate];
            NSDate * lastDate = [CommonUtil date:[NSDate date] BySubtractingDays:40];
            
            if([cDate compare:lastDate]==NSOrderedAscending)
            {
                [fm removeItemAtPath:path error:&error];
                if(error)
                {
                    NSLog(@" remove file :%@ failure:%@",path,[error description]);
                }
                else
                {
                    notice = NO;
                }
            }
            if(notice)
            {
                long long size = [[attributes objectForKey:NSFileSize]longLongValue];
                UInt64 size2 = 0;
                if([HCFileManager checkUrlIsExists:fileUrl contengLength:&size2 level:0])
                {
                    if(size2 == size)
                    {
                        notice = YES;
                    }
                    else
                    {
                        notice = NO;
                        [self removeFileAtPath:path];
                        fileUrl = [fileUrl stringByAppendingString:[NSString stringWithFormat:@"?t=%ld",[CommonUtil getDateTicks:[NSDate date]]]];
                    }
                }
                
            }
        }
        if(notice)
        {
            if(delegate && [delegate respondsToSelector:@selector(UDManager:key:didCompleted:)])
            {
                __block UDInfo * item = (UDInfo *)[items_ objectForKey:key];
                // if exists
                if (!item) {
                    item = [self queryItemFromDB:key];
                    if(!item)
                    {
                        item = [UDInfo new];
                    }
                }
                
                
                item.OrgUrl = fileUrl;
                item.RemoteUrl = fileUrl;
                item.LocalFileName = path;
                item.Key = key;
                item.Status = 4;
                item.IsUpload = NO;
                item.Ext = fileExt;
                item.Progress = 1;
                item.DateCreated = [CommonUtil stringFromDate:[NSDate date]];
                //            item.TotalBytes =0;
                
                [self insertItemToDB:item];
//                __weak UDInfo * weakItem = item;
                dispatch_async(dispatch_get_main_queue(), ^(void)
                               {
//                                   __strong UDInfo * strongItem = weakItem;
                                   [delegate UDManager:self key:key didCompleted:item];
                                   item = nil;
//                                   strongItem = nil;
                               });
                
//                PP_RELEASE(item);
            }
            return key;
        }
    }
    
    path = [NSString stringWithFormat:@"%@_",path];
    NSLog(@"temp file full Path:%@",path);
    
    //build information for item
    UDInfo * item = (UDInfo *)[items_ objectForKey:key];
    // if exists
    if (!item) {
        item = [self queryItemFromDB:key];
        if(!item)
        {
            item = [UDInfo new];
        }
    }
    
    
    item.OrgUrl = fileUrl;
    item.RemoteUrl = fileUrl;
    item.LocalFileName = path;
    item.Key = key;
    item.Status = 0;
    item.IsUpload = NO;
    item.Ext = fileExt;
    item.Progress = 0;
    item.TotalBytes =0;
    
    item.DateCreated = [CommonUtil stringFromDate:[NSDate date]];
    
    item.delegate = delegate;
    
    //加入到数据库中，备下次启动时再处理
    @synchronized(self)
    {
        if([self insertItemToDB:item])
        {
            [items_ setObject:item forKey:item.Key];
        }
        else
        {
            [items_ setObject:item forKey:item.Key];
            NSLog(@"** save uditem to db failure.");
        }
    }
    
    if(!autoStart) return key;
    
    //upload....
    [self startDownloadByKey:key delegate:delegate];
    return key;
}
//获取已下载的文件大小
- (unsigned long long)fileSizeForPath:(NSString *)path {
    signed long long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager new]; // default is not thread safe
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileSize = [fileDict fileSize];
        }
    }
    return fileSize;
}
- (BOOL)startDownloadByKey:(NSString *)key delegate:(id<UDDelegate>)delegate
{
    if(![self isKeyValid:key]) return NO;
    UDInfo * item = [items_ objectForKey:key];
    if(!item) return NO;
    
    //get token
    if(![HCFileManager isQiniuServer:item.RemoteUrl])
    {
        [self startDownloadByItem:item delegate:delegate];
        return YES;
    }
    if(downloadToken_)
        //    if(TRUE)
    {
        [self startDownloadByItem:item delegate:delegate];
    }
    else
    {
        CMD_GetDownloadToken * cmd = [CMD_GetDownloadToken new];
        cmd.CMDCallBack = ^(HCCallbackResult *result)
        {
            downloadToken_ = [result.DicNotParsed objectForKey:@"dltoken"];
            if(!downloadToken_)
            {
                NSLog(@"**get download tocken failure");
            }
            else
            {
                [NSTimer timerWithTimeInterval:TOKEN_TIMESPAN
                                        target:self
                                      selector:@selector(setDownloadTokenExpire:)
                                      userInfo:nil repeats:NO];
                
                [self startDownloadByItem:item delegate:delegate];
                
            }
        };
        [cmd sendCMD];
    }
    return YES;
}
- (NSString *)buildUrlWithToken:(NSString *)url
{
    //一一步需要修改，针对私有资源进行TOken验证
    //    构造下载URL：
    //    DownloadUrl = 'http://my-bucket.qiniudn.com/sunflower.jpg'
    //    为下载URL加上过期时间（e参数，Unix时间）：
    //    DownloadUrl = 'http://my-bucket.qiniudn.com/sunflower.jpg?e=1451491200'
    //    对上一步得到的URL字符串计算HMAC-SHA1签名（假设SecretKey是MY_SECRET_KEY），并对结果做URL安全的Base64编码：
    //    Sign = hmac_sha1(DownloadUrl, 'MY_SECRET_KEY')
    //    EncodedSign = urlsafe_base64_encode(Sign)
    //    将AccessKey（假设是MY_ACCESS_KEY）与上一步计算得到的结果以“:”连接起来：
    //    Token = 'MY_ACCESS_KEY:NTQ3YWI5N2E5MjcxN2Y1ZTBiZTY3ZTZlZWU2NDAxMDY1YmI4ZWRhNwo='
    //    将下载凭证添加到含过期时间参数的下载URL之后，作为最后一个参数（token参数）：
    //    RealDownloadUrl = 'http://my-bucket.qiniudn.com/sunflower.jpg?e=1451491200&token=MY_ACCESS_KEY:NTQ3YWI5N2E5MjcxN2Y1ZTBiZTY3ZTZlZWU2NDAxMDY1YmI4ZWRhNwo='
    //    RealDownloadUrl即为下载对应私有资源的可用URL，并在指定时间后失效。
    //    失效后，可按需重新生成下载凭证。
    
    return url;
}
//开始下载
- (void)startDownloadByItem:(UDInfo *)item delegate:(id<UDDelegate>)delegate
{
    NSString *downloadUrl =  [self buildUrlWithToken:item.RemoteUrl];
    if(item.LocalFilePath == nil ||item.LocalFilePath.length==0)
    {
        NSString * ext = item.Ext && item.Ext.length>0?[NSString stringWithFormat:@"%@_",item.Ext]:@"mp3_";
        item.LocalFileName = [self getLocalFilePathForUrl:downloadUrl extension:ext];
    }
    NSString *downloadPath = item.LocalFilePath;
    
    
    __block UDInfo * currentItem = item;
    
    item.delegate = delegate;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:downloadUrl]];
    
    //    if(item.headers)
    //    {
    //        for (NSString * key in item.headers.allKeys) {
    //            [request setValue:[item objectForKey:key] forKey:key];
    //        }
    //    }
    
    //检查文件是否已经下载了一部分
    unsigned long long downloadedBytes = 0;
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadPath]) {
        //获取已下载的文件长度
        downloadedBytes = [self fileSizeForPath:downloadPath];
        if (downloadedBytes > 0) {
            //            NSMutableURLRequest *mutableURLRequest = [request mutableCopy];
            NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", downloadedBytes];
            [request setValue:requestRange forHTTPHeaderField:@"Range"];
            //            request = mutableURLRequest;
        }
    }
    
    //不使用缓存，避免断点续传出现问题
    //    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
    //
    //
    //    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    //    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    //
    //    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request
    //                                                                     progress:^(NSProgress * progress)
    //                                              {
    //
    //                                              }
    //                                                                  destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
    //
    //        return [NSURL URLWithString:downloadPath];
    //
    //    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
    //        NSLog(@"File downloaded to: %@", filePath);
    //    }];
    //    [downloadTask resume];
    
    
    
    //下载请求
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    //下载路径
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:downloadPath append:YES];
    //下载进度回调
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        //下载进度
        float progress = ((float)totalBytesRead + downloadedBytes) / (totalBytesExpectedToRead + downloadedBytes);
        NSLog(@" download %@ percent:%.2f---%lld",currentItem.Key,progress * 100,totalBytesRead);
        
        currentItem.TotalBytes = (unsigned long)(totalBytesExpectedToRead + totalBytesRead);
        currentItem.RemainBytes = (unsigned long)totalBytesExpectedToRead;
        currentItem.Percent = progress;
        currentItem.Progress = progress;
        currentItem.Status = 1;
        currentItem.DateModified = [CommonUtil stringFromDate:[NSDate date]];
        if(item.delegate && [item.delegate respondsToSelector:@selector(UDManager:key:progress:)])
        {
            [item.delegate UDManager:self key:currentItem.Key progress:currentItem];
        }
    }];
    
    //成功和失败回调
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@" download completed.");
        @synchronized(self)
        {
            currentItem.Status = 4;
            //            currentItem.RemoteUrl = [self remoteUrl:currentItem.Key];
            currentItem.RemainBytes = 0;
            
            
            //改文件名,同临时文件改成正式文件
            currentItem.LocalFileName = [self renameDownloadFileName:currentItem.LocalFilePath];
            currentItem.DateModified = [CommonUtil stringFromDate:[NSDate date]];
            
            [[DBHelper sharedDBHelper]insertData:currentItem needOpenDB:YES forceUpdate:YES];
            [items_ removeObjectForKey:currentItem.Key];
        }
        if(item.delegate && [item.delegate respondsToSelector:@selector(UDManager:key:didCompleted:)])
        {
            [item.delegate UDManager:self key:currentItem.Key didCompleted:currentItem];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@" download failure code:[%ld]:%@",(long)operation.response.statusCode,[error description]);
        @synchronized(self)
        {
            if(operation.response.statusCode == 416)
            {
                currentItem.LocalFileName = [self renameDownloadFileName:currentItem.LocalFilePath];
                currentItem.DateModified = [CommonUtil stringFromDate:[NSDate date]];
                
                [[DBHelper sharedDBHelper]insertData:currentItem needOpenDB:YES forceUpdate:YES];
                [items_ removeObjectForKey:currentItem.Key];
                currentItem.Status = 0;
            }
            else if(operation.response.statusCode == 200||operation.response.statusCode == 206) //user stop
            {
                currentItem.Status = 6;
            }
            else
            {
                currentItem.Status = 2;
                if(error)
                {
                    currentItem.ErrorInfo = [error description];
                }
            }
            currentItem.DateModified = [CommonUtil stringFromDate:[NSDate date]];
            
            [[DBHelper sharedDBHelper]insertData:currentItem needOpenDB:YES forceUpdate:YES];
        }
        if(item.delegate && [item.delegate respondsToSelector:@selector(UDManager:key:didFailure:)])
        {
            [item.delegate UDManager:self key:currentItem.Key didFailure:currentItem];
        }
    }];
    [operation start];
    item.operate = operation;
}
- (NSString *)renameDownloadFileName:(NSString *)LocalFilePath
{
    if([LocalFilePath hasSuffix:@"_"])
    {
        NSString * targetPath = [LocalFilePath substringToIndex:LocalFilePath.length-1];
        NSFileManager * fm = [NSFileManager defaultManager];
        NSError * error = nil;
        if([fm fileExistsAtPath:targetPath])
        {
            [fm removeItemAtPath:targetPath error:&error];
            if(error)
            {
                NSLog(@" remove file  failure:%@",[error description]);
            }
            
        }
        [fm moveItemAtPath:LocalFilePath toPath:targetPath error:&error];
        if(error)
        {
            NSLog(@" rename file failure:%@",[error description]);
        }
        return targetPath;
    }
    return LocalFilePath;
}
#pragma mark - others
- (NSDictionary *)itemList
{
    return items_;
}
- (BOOL)stopAllUDs:(BOOL) byUser delegate:(id<UDDelegate>)delegate
{
    for (NSString * key in items_.allKeys) {
        UDInfo * item = [items_ objectForKey:key];
        [self stopProgress:key delegate:delegate];
        if(!byUser)
            item.Status = 5;
        else
            item.Status = 0;
        [[DBHelper sharedDBHelper]insertData:item needOpenDB:YES forceUpdate:YES];
    }
    return YES;
}
- (BOOL)startAllUDs:(id<UDDelegate>)delegate
{
    for (NSString * key in items_.allKeys) {
        UDInfo * item = [items_ objectForKey:key];
        if(item.Status!=4)
        {
            if(item.IsUpload)
            {
                [self startUploadItem:key delegate:delegate];
            }
            else
            {
                [self startDownloadByKey:key delegate:delegate];
            }
        }
    }
    return YES;
}

- (BOOL) startAlludsWithoutStopByUser:(id<UDDelegate>)delegate//开始所有上传与下载，非人为停止的。
{
    for (NSString * key in items_.allKeys) {
        UDInfo * item = [items_ objectForKey:key];
        if(item.Status==5)
        {
            if(item.IsUpload)
            {
                [self startUploadItem:key delegate:delegate];
            }
            else
            {
                [self startDownloadByKey:key delegate:delegate];
            }
        }
    }
    return YES;
}
- (BOOL) stopAllUploads:(BOOL) byUser delegate:(id<UDDelegate>)delegate //停止所有上传进程
{
    for (NSString * key in items_.allKeys) {
        UDInfo * item = [items_ objectForKey:key];
        if(item.IsUpload)
        {
            [self stopProgress:key delegate:delegate];
            if(!byUser) item.Status = 5;
            [[DBHelper sharedDBHelper]insertData:item needOpenDB:YES forceUpdate:YES];
        }
    }
    return YES;
}
#pragma mark - download
- (BOOL)downloadFile:(NSString *)urlString fileName:(NSString *)fileName
           completed:(void (^)(NSString *))block
              falure:(void (^)(NSError *))failure
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    //    [request setValue:requestRange forHTTPHeaderField:@"Range"];
    [request setValue:@"http://maiba.seenvoice.com" forHTTPHeaderField:@"Referer"];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;//不使用缓存
    request.timeoutInterval = 20;
    
    NSString * filePath = [self tempFileFullPath:fileName];
    
    HXNetwork * operation = [[HXNetwork alloc]initWithRequest:request outputfile:filePath];
    downloadProgressBlock_t progressBlock = ^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        NSLog(@"download bytes %llu-%lld",bytesRead + totalBytesRead,totalBytesExpectedToRead);
    };
    completionDataBlock_t completedBlock = ^(HXNetwork *operation, id responseObject) {
        if(block)
        {
            block(filePath);
        }
    };
    completionWithError_t failureBlock =^(HXNetwork *operation, NSError *error) {
        if(failure)
        {
            failure(error);
        }
        
    };
    [operation setDownloadProgressBlock:progressBlock];
    [operation setCompletionDataBlock:completedBlock];
    [operation setCompletionWithError:failureBlock];
    
    [operation start];
    
    return YES;
}
//- (BOOL)doUploadQiniu:(UDInfo *)item
//{
//
//    __block UDInfo * currentItem = item;
//    item.WillStop = NO;
//    UDManager * mm = self;
//    NSString * token =[self getUploadTocken:item.DomainType];
//    __block int lastPostPercent = -1;
//    QNUploadOption *opt = [[QNUploadOption alloc] initWithMime:nil /*[self getMimeType:item.LocalFilePath]*/
//                                               progressHandler:^(NSString *key, float percent)
//                           {
//                               BOOL needPost = NO;
//                               if(round(percent *100) > lastPostPercent || percent==1)
//                               {
//                                   needPost = YES;
//                                   lastPostPercent = round(percent* 100) +1;
//                                   NSLog(@"progress min:%f",lastPostPercent/100.f);
//                               }
//                               currentItem.Percent = percent;
//                               //                               NSLog(@"progress %f", percent);
//                               currentItem.Status = 1;
//                               if(needPost)
//                               {
//                                   if(currentItem)
//                                   {
//                                       dispatch_async(dispatch_get_main_queue(), ^{
//                                           [[DBHelper sharedDBHelper]insertData:currentItem needOpenDB:YES forceUpdate:YES];
//                                       });
//                                   }
//                                   if(item.delegate && [item.delegate respondsToSelector:@selector(UDManager:key:progress:)])
//                                   {
//                                       [item.delegate UDManager:self key:currentItem.Key progress:currentItem];
//                                   }
//                                   else
//                                   {
//                                       [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADPROGRESSCHANGED object:currentItem userInfo:nil];
//                                   }
//                               }
//                           }
//                                                        params:@{ @"x:foo":@"fooval" }
//                                                      checkCrc:YES
//                                            cancellationSignal: ^BOOL(void)
//                           {
//                               if(currentItem.WillStop)
//                               {
//                                   currentItem.WillStop = NO; //将状态复位
//                                   return YES;
//                               }
//                               return NO;
//                           }];
//
//    [upManager_ putFile:item.LocalFilePath
//                    key:item.Key
//                  token:token
//               complete:^(QNResponseInfo * info,NSString * key,NSDictionary * resp)
//     {
//         //         NSLog(@"%@", info);
//         //         NSLog(@"%@", resp);
//
//         //         hash	是	目标资源的hash值，可用于ETag头部。
//         //         key	是	目标资源的最终名字，可由七牛云存储自动命名。
//
//         /*__27-[UDManager doUploadQiniu:]_block_invoke132) (UDManager.m:212) {
//          hash = "ln5CrjJvwJ4LMir9drXJBzwVB5_Z";
//          key = "0-685b0161be1f7332911a73445b658e1d";
//          "x:foo" = fooval;
//          }
//          */
//         if(info.statusCode==200)
//         {
//             //             NSString * hash = [resp objectForKey:@"hash"];
//             @synchronized(mm)
//             {
//                 currentItem.Status = 4;
//                 currentItem.RemoteUrl = [self remoteUrl:currentItem.Key domainType:currentItem.DomainType];
//                 currentItem.DateModified = [CommonUtil stringFromDate:[NSDate date]];
//                 dispatch_async(dispatch_get_main_queue(), ^{
//                     [[DBHelper sharedDBHelper]insertData:currentItem needOpenDB:YES forceUpdate:YES];
//                 });
//                 [items_ removeObjectForKey:currentItem.Key];
//             }
//             if(item.delegate && [item.delegate respondsToSelector:@selector(UDManager:key:didCompleted:)])
//             {
//                 [item.delegate UDManager:self key:currentItem.Key didCompleted:currentItem];
//             }
//             else
//             {
//                 [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADCOMPLETED object:currentItem userInfo:nil];
//             }
//         }
//         else
//         {
//             currentItem.Status = info.statusCode;
//             if(info.error)
//             {
//                 currentItem.ErrorInfo = [info.error description];
//             }
//             else if([resp objectForKey:@"error"])
//             {
//                 currentItem.ErrorInfo = [resp objectForKey:@"error"];
//             }
//             currentItem.DateModified = [CommonUtil stringFromDate:[NSDate date]];
//             //             @synchronized(mm)
//             //             {
//             dispatch_async(dispatch_get_main_queue(), ^{
//                 [[DBHelper sharedDBHelper]insertData:currentItem needOpenDB:YES forceUpdate:YES];
//             });
//             //             }
//             if(item.delegate && [item.delegate respondsToSelector:@selector(UDManager:key:didFailure:)])
//             {
//                 [item.delegate UDManager:self key:currentItem.Key didFailure:currentItem];
//             }
//             else
//             {
//                 [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADSTATECHANGED object:item userInfo:nil];
//             }
//
//         }
//     }
//                 option:opt
//     ];
//
//    return YES;
//}
@end

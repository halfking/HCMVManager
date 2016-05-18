//
//  MTVUploader.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/6/19.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "MTVUploader.h"
#import <hccoren/base.h>

#import <hcbasesystem/database_wt.h>
#import <hcbasesystem/user_wt.h>
#import <hcbasesystem/Updown.h>
//#import <hcbasesystem/umshareobject.h>
#import <hcbasesystem/config.h>
#import "MTVFile.h"
#import "CMD_DeleteMyMTV.h"
#import "CMD_UploadMBMTV.h"
#import "HCDBHelper(MTV).h"

@implementation MTVUploader
{
    //    NSMutableArray * udList_;
    //    int isCheckingNetwork_;
}
@synthesize networkStatus = networkStatus_;

SYNTHESIZE_SINGLETON_FOR_CLASS_NEW(MTVUploader)

- (id) init
{
    if(self = [super init])
    {
        //        udList_ = [NSMutableArray array];
        
        //        [self getUploadList];
        canAutoUpload_ = YES;
        isCreating_ = NO;
        //        监听网络，当切到3G、4G时，则暂停上传过程
        //        [self checkNetwork];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didNetworkChanged:)
                                                     name:NET_CHANGED
                                                   object:nil];
        
        
    }
    return self;
}
//
//- (void)checkNetwork
//{
//    if(!self.reachability)
//    {
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
//        self.reachability = [Reachability reachabilityForInternetConnection];
//
//        [self.reachability startNotifier];
//    }
//    [self updateInterfaceWithReachability:self.reachability];
//}
//- (void)checkNetworkNew
//{
//    Reachability *r = [Reachability reachabilityWithHostName:@"www.baidu.com"];
//    switch ([r currentReachabilityStatus]) {
//        case ReachableNone:
//            // 没有网络连接
//            NSLog(@"没有网络");
//
//            break;
//        case ReachableViaWWAN:
//            // 使用3G网络
//            NSLog(@"正在使用3G网络");
//            break;
//        case ReachableViaWiFi:
//            // 使用WiFi网络
//            NSLog(@"正在使用wifi网络");
//            break;
//    }
//}
- (void)dealloc
{
    //    [self.reachability stopNotifier];
    //    self.reachability = nil;
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    PP_RELEASE(mtvList_);
    
    PP_SUPERDEALLOC;
}
/*!
 * Called by Reachability whenever status changes.
 */
- (void) didNetworkChanged:(NSNotification *)note
{
    NetworkStatus orgNetworkStatus = networkStatus_;
    networkStatus_= [note.object intValue];
    
    [self doNetworkChanged:orgNetworkStatus];
}
//- (void) reachabilityChanged:(NSNotification *)note
//{
//    Reachability* curReach = [note object];
//    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
//    [self updateInterfaceWithReachability:curReach];
//}
//
//- (void)updateInterfaceWithReachability:(Reachability *)reachability
//{
//    NetworkStatus orgNetworkStatus = networkStatus_;
//    networkStatus_= [reachability currentReachabilityStatus];
//
//    [[NSNotificationCenter defaultCenter]postNotificationName:NT_NETWORKCHANGED object:[NSNumber numberWithInt:(int)networkStatus_] userInfo:nil];
//    [self doNetworkChanged:orgNetworkStatus];
//}
- (void)doNetworkChanged:(NetworkStatus)orgNetworkStatus
{
    //网络切换时，需要注意自动停止相关的操作
    if(networkStatus_ == ReachableNone ||(networkStatus_ == ReachableViaWWAN && [[UserManager sharedUserManager]currentSettings].NoticeFor3G))
    {
        [[UDManager sharedUDManager]stopAllUploads:NO delegate:self];
    }
    else if([[UserManager sharedUserManager]currentSettings].AutoUploadDataViaWIFI||[[UserManager sharedUserManager]currentSettings].NoticeFor3G==NO)
    {
        if(canAutoUpload_)
        {
            [[UDManager sharedUDManager]startAlludsWithoutStopByUser:self];
        }
    }
    if(orgNetworkStatus==ReachableNone && networkStatus_!=ReachableNone)
    {
        [[UserManager sharedUserManager]registerDevice:nil];
    }
}
- (BOOL)canDownloadUpload
{
    if([[UserManager sharedUserManager]currentSettings].AutoUploadDataViaWIFI||[[UserManager sharedUserManager]currentSettings].NoticeFor3G==NO)
    {
        return YES;
    }
    return NO;
}
////有可能网络联接，但无法访问数据，认为断网
//- (void)networkTimeout:(NSNotification *)noti
//{
//    if(networkStatus_ == ReachableNone) return;
//    NetworkStatus orgNetworkStatus = networkStatus_;
//    networkStatus_ = ReachableNone;
//
//    [[NSNotificationCenter defaultCenter]postNotificationName:NT_NETWORKCHANGED object:[NSNumber numberWithInt:(int)ReachableNone] userInfo:nil];
//
//    if(isCheckingNetwork_<=0)
//    {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//            [self startCheckNetwork];
//        });
//    }
//    [self doNetworkChanged:orgNetworkStatus];
//
//}
//- (void)startCheckNetwork
//{
//    if (isCheckingNetwork_>1) {
//        return ;
//    }
//    if(isCheckingNetwork_==0)
//    {
//        isCheckingNetwork_ ++ ;
//    }
//    isCheckingNetwork_ ++ ;
//    NSLog(@"check network begin...");
//    Reachability *r = [Reachability reachabilityWithHostName:@"www.baidu.com"];
//    switch ([r currentReachabilityStatus]) {
//        case ReachableNone:
//            // 没有网络连接
//            NSLog(@"没有网络");
//            networkStatus_ = ReachableNone;
//
//            break;
//        case ReachableViaWWAN:
//            // 使用3G网络
//            NSLog(@"正在使用3G/4G网络");
//            networkStatus_ = ReachableViaWWAN;
//            break;
//        case ReachableViaWiFi:
//            // 使用WiFi网络
//            NSLog(@"正在使用wifi网络");
//            networkStatus_ = ReachableViaWiFi;
//            break;
//    }
//    if(networkStatus_!=ReachableNone)
//    {
//        BOOL ret = YES;
//        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.baidu.com/"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:2];
//        request.HTTPMethod = @"HEAD";
//        NSError *error = nil;
//
//        NSHTTPURLResponse * response = nil;
//        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
//        if(error)
//        {
//            NSLog(@"error:%@",error);
//            ret = NO;
//        }
//        else
//        {
//            if(response.statusCode==404)
//            {
//                ret = NO;
//            }
//        }
//
//        if(ret)
//        {
//            NSLog(@"Checknet work completed...connected");
//            [[NSNotificationCenter defaultCenter]postNotificationName:NT_NETWORKCHANGED object:[NSNumber numberWithInt:(int)networkStatus_] userInfo:nil];
//            isCheckingNetwork_ = 0;
//            [self doNetworkChanged:networkStatus_];
//        }
//        else
//        {
//            NSLog(@"Checknet work completed...not connected");
//            networkStatus_ = ReachableNone;
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//                [self startCheckNetwork];
//            });
//        }
//    }
//    isCheckingNetwork_ --;
//
//}
#pragma mark - getuploadlist
- (NSArray *) getUploadList
{
    DBHelper * dbHelper = [DBHelper sharedDBHelper];
    NSString * sqlStr = @"select * from udinfos where isupload = 1 and (status = 0 or status = 1) order by DateCreated desc;";
    
    NSMutableArray * udList = [NSMutableArray array];
    if([dbHelper open])
    {
        [dbHelper execWithArray:udList class:NSStringFromClass([UDInfo class]) sql:sqlStr];
        [dbHelper close];
    }
    return udList;
}

- (UDInfo *) getUDInfoByKey:(NSString *)key
{
    if(!key || key.length==0) return nil;
    return [[UDManager sharedUDManager]queryItem:key];
}
- (UDInfo *) getUploadInfo:(MTV*)mtv
{
    return [self getUDInfoByKey:[mtv getKey]];
}

//上传MTV的Info，当录制完成后上传失败，则转入此处，此时可能要生成MTV的ID，上传COver，然后再来上传MTV的视频
- (BOOL) uploadMTVInfo:(MTV *)mtv materias:(NSArray *)materias forceUpload:(BOOL)force delegate:(id<MTVUploadderDelegate>)delegate
{
    //保存到本地数据库
    long mtvID = 0;
    if(mtv.MTVID ==0)
        mtvID = [self insertIntoLocalDB:mtv];
    else
        mtvID = mtv.MTVID;
    
    if(mtvID==0)
    {
        NSLog(@" save to localdb failure.");
        return NO;
    }
    
    if(delegate && [delegate respondsToSelector:@selector(MTVUploader:didMTVSaveLocalDB:)])
    {
        [delegate MTVUploader:self didMTVSaveLocalDB:mtv];
    }
    //上传封面
    if(mtv.CoverUrl && [HCFileManager isLocalFile:mtv.CoverUrl] && [HCFileManager isFileExistAndNotEmpty:mtv.CoverUrl size:nil])
    {
#ifndef __OPTIMIZE__
        UInt64 size = [[UDManager sharedUDManager]fileSizeAtPath:mtv.CoverUrl];
        NSLog(@"upload cover size:[%llu] for file:%@",size,[mtv.CoverUrl lastPathComponent]);
#endif
        mtv.UploadKey = [[UDManager sharedUDManager]uploadFile:mtv.CoverUrl domainType:DOMAIN_COVER progress:nil completed:^(NSString * filePath,NSString * removeUrl)
                         {
                             mtv.CoverUrl = removeUrl;
                             
                             NSLog(@"ready to send data to server2");
                             
                             [self updateLocalDB:mtv];
                             
                             //保存数据
                             [self sendMtvInfoToServer:mtv  materias:materias  forceUpload:force delegate:delegate];
                             
                         }failure:^(NSString * filePath,int  code,NSString * message)
                         {
                             if(delegate && [delegate respondsToSelector:@selector(MTVUploader:didMtvInfoFailuer:error:)])
                             {
                                 [delegate MTVUploader:self didMtvInfoFailuer:mtv error:message];
                             }
                             
                         }
                                                          stop:nil];
        
        return YES;
    }
    else if([HCFileManager isUrlOK:mtv.CoverUrl])
    {
        //保存数据
        return [self sendMtvInfoToServer:mtv  materias:materias forceUpload:force delegate:delegate];
    }
    else
    {
        if(delegate && [delegate respondsToSelector:@selector(MTVUploader:didMtvInfoFailuer:error:)])
        {
            [delegate MTVUploader:self didMtvInfoFailuer:mtv error:MSG_NOCOVER];
        }
        
        return NO;
    }
    //上传封面
    //    if(!mtv.CoverUrl || ([CommonUtil isLocalFile:mtv.CoverUrl] && ![CommonUtil isFileExistAndNotEmpty:mtv.CoverUrl size:nil]))
    //    {
    //        NSString * coverPath = [CommonUtil checkPath:mtv.CoverUrl];
    //        NSString * mediaPath = [CommonUtil checkPath:[mtv getFilePathN]];
    //
    //        NSFileManager * fm = [NSFileManager defaultManager];
    //        if(!coverPath || ![fm fileExistsAtPath:coverPath])
    //        {
    //            if([fm fileExistsAtPath:mediaPath])
    //            {
    //                return [[WTPlayerResource sharedWTPlayerResource]getVideoThumbOne:[NSArray arrayWithObject:[NSURL fileURLWithPath:mediaPath]] andSize:CGSizeZero callback:^(CMTime requestTime,NSString* path,UIImage * image)
    //                        {
    //                            mtv.CoverUrl = path;
    //                            [self updateLocalDB:mtv];
    //#ifndef __OPTIMIZE__
    //                            UInt64 size = [[UDManager sharedUDManager]fileSizeAtPath:path];
    //                            NSLog(@"upload cover size:[%llu] for file:%@",size,[path lastPathComponent]);
    //#endif
    //                            mtv.UploadKey = [[UDManager sharedUDManager]uploadFile:mtv.CoverUrl domainType:DOMAIN_COVER progress:nil completed:^(NSString * filePath,NSString * removeUrl)
    //                                             {
    //                                                 NSLog(@"ready to send data to server 1");
    //                                                 mtv.CoverUrl = removeUrl;
    //
    //
    //                                                 [self updateLocalDB:mtv];
    //                                                 //保存数据
    //                                                 [self sendMtvInfoToServer:mtv materias:materias forceUpload:force delegate:delegate];
    //
    //                                             }failure:^(NSString * filePath,int  code,NSString * message)
    //                                             {
    //                                                 if(delegate && [delegate respondsToSelector:@selector(MTVUploader:didMtvInfoFailuer:error:)])
    //                                                 {
    //                                                     [delegate MTVUploader:self didMtvInfoFailuer:mtv error:message];
    //                                                 }
    //
    //                                             }
    //                                                                              stop:nil];
    //
    //                        }];
    //            }
    //            else
    //            {
    //                if(delegate && [delegate respondsToSelector:@selector(MTVUploader:didMtvInfoFailuer:error:)])
    //                {
    //                    [delegate MTVUploader:self didMtvInfoFailuer:mtv error:MSG_NOCOVER];
    //                }
    //
    //                return NO;
    //            }
    //        }
    //        else
    //        {
    //#ifndef __OPTIMIZE__
    //            UInt64 size = [[UDManager sharedUDManager]fileSizeAtPath:mtv.CoverUrl];
    //            NSLog(@"upload cover size:[%llu] for file:%@",size,[mtv.CoverUrl lastPathComponent]);
    //#endif
    //            mtv.UploadKey = [[UDManager sharedUDManager]uploadFile:mtv.CoverUrl domainType:DOMAIN_COVER progress:nil completed:^(NSString * filePath,NSString * removeUrl)
    //                             {
    //                                 mtv.CoverUrl = removeUrl;
    //
    //                                 NSLog(@"ready to send data to server2");
    //
    //                                 [self updateLocalDB:mtv];
    //
    //                                 //保存数据
    //                                 [self sendMtvInfoToServer:mtv  materias:materias  forceUpload:force delegate:delegate];
    //
    //                             }failure:^(NSString * filePath,int  code,NSString * message)
    //                             {
    //                                 if(delegate && [delegate respondsToSelector:@selector(MTVUploader:didMtvInfoFailuer:error:)])
    //                                 {
    //                                     [delegate MTVUploader:self didMtvInfoFailuer:mtv error:message];
    //                                 }
    //
    //                             }
    //                                                              stop:nil];
    //        }
    //        return YES;
    //    }
    //    else
    //    {
    //        //保存数据
    //        return [self sendMtvInfoToServer:mtv  materias:materias forceUpload:force delegate:delegate];
    //    }
}
- (void)doUpload:(MTV *)mtv force:(BOOL)force
{
    //WIFI情况下直接上传
    if(self.networkStatus == ReachableViaWiFi || force)
    {
        [self uploadMTV:mtv];
    }
}
- (BOOL)sendMtvInfoToServer:(MTV *)mtv materias:(NSArray *)materias  completed:(SendCompleted)completed
{
    NSLog(@"begin to send data to server:id:%ld iscreating:%d",mtv.MTVID,isCreating_);
    if(isCreating_) return NO;
    isCreating_ = YES;
    
    //已经向线上提交过了的数据，不需要再次发送
    long orgMtvID = mtv.MTVID;
    cmdCallback callback = ^(HCCallbackResult * result)
    {
        if(result.Code==0)
        {
            mtv.MTVID = ((MTV*)result.Data).MTVID;
            mtv.CoverUrl = ((MTV*)result.Data).CoverUrl;
            
            if(orgMtvID!=mtv.MTVID)
            {
                NSString * sql =[NSString stringWithFormat:@"update mtvs set mtvid = %li where mtvid=%li",mtv.MTVID,orgMtvID];
                dispatch_async(dispatch_get_main_queue(), ^(void)
                               {
                                   if([[DBHelper sharedDBHelper]open])
                                   {
                                       [[DBHelper sharedDBHelper]execNoQuery:sql];
                                       [[DBHelper sharedDBHelper]close];
                                   }
                               });
                if([mtv isKindOfClass:[MTVLocal class]])
                {
                    [self saveMTVInfoToLocalDir:(MTVLocal *)mtv];
                }
                else
                {
                    MTVLocal * mtvLocal = [[MTVLocal alloc]initWithMTV:mtv];
                    [self saveMTVInfoToLocalDir:mtvLocal];
                }
                
            }
            isCreating_ = NO;
            if(completed)
            {
                completed(YES);
            }
            
            NSNotification * noti = [NSNotification notificationWithName:NT_MTVIDCREATED object:nil userInfo:@{@"orgid":@(orgMtvID),@"newid":@(mtv.MTVID),@"coverurl":mtv.CoverUrl==nil?@"":mtv.CoverUrl}];
            [[NSNotificationCenter defaultCenter]postNotification:noti];
        }
        else
        {
            if([mtv isKindOfClass:[MTVLocal class]])
            {
                [self saveMTVInfoToLocalDir:(MTVLocal *)mtv];
            }
            isCreating_ = NO;
            if(completed)
            {
                completed(NO);
            }
        }
        
    };
    
    //保存数据
    BOOL ret = NO;
    if([mtv isKindOfClass:[MTVLocal class]])
    {
        mtv = [mtv copyItem];
    }
    
    NSLog(@"create mtv islandscape:%d",mtv.IsLandscape);
#warning need repair 如果此处的MTVID大于0，则表示已经保存过，这里最多就是更新保存。
    
    int justUpdateKey = 0;
    if(mtv.MTVID>0)
    {
        justUpdateKey = 2;
    }
    if(mtv.SampleID <=0)
    {
        CMD_CreateMTV * cmd = (CMD_CreateMTV *)[[CMDS_WT sharedCMDS_WT]createCMDOP:@"CreateMTV"];
        cmd.MtvData = mtv;
        cmd.justUpdateKey = justUpdateKey;
        
        cmd.CMDCallBack = callback;
        ret =  [cmd sendCMD];
    }
    else
    {
        //        MTV * newMtv = [MTV new];
        //        newMtv.MTVID = mtv.MTVID;
        ////        newMtv.FilePath = mtv.FilePath;
        //        newMtv.MBMTVID = mtv.MBMTVID;
        ////        newMtv.DownloadUrl = mtv.DownloadUrl;
        //        newMtv.IsLandscape = mtv.IsLandscape;
        //        newMtv.Memo = mtv.Memo;
        //        newMtv.Tag = mtv.Tag;
        //        newMtv.UploadTime = [CommonUtil stringFromDate:[NSDate date]];
        //        newMtv.Materials = mtv.Materials;
        //        newMtv.Title = mtv.Title;
        //        newMtv.CoverUrl = mtv.CoverUrl;
        
        CMD_UploadMBMTV * cmd = (CMD_UploadMBMTV *)[[CMDS_WT sharedCMDS_WT]createCMDOP:@"UploadMBMTV"];
        cmd.data = mtv;
        cmd.justUpdateKey = justUpdateKey;
        cmd.Materials = materias;//如果为Nil，则后台不会更新这个字段
        cmd.CMDCallBack = callback;
        ret = [cmd sendCMD];
    }
    
    
    return ret;
}
- (BOOL)sendMtvInfoToServer:(MTV *)mtv materias:(NSArray *)materias forceUpload:(BOOL)force delegate:(id<MTVUploadderDelegate>)delegate
{
    NSLog(@"begin to send data to server:id:%ld iscreating:%d",mtv.MTVID,isCreating_);
    //    if(isCreating_) return NO;
    //    __block isCreating_ = YES;
    
    
    BOOL ret = [self sendMtvInfoToServer:mtv materias:nil completed:^(BOOL finished)
                {
                    if(finished)
                    {
                        BOOL needUpload = YES;
                        if([delegate respondsToSelector:@selector(MTVUploader:didMTVInfoCompleted:)])
                        {
                            needUpload = [delegate MTVUploader:self didMTVInfoCompleted:mtv];
                        }
                        if(needUpload)
                            [self doUpload:mtv force:force];
                    }
                    else{
                        if([delegate respondsToSelector:@selector(MTVUploader:didMtvInfoFailuer:error:)])
                        {
                            [delegate MTVUploader:self didMtvInfoFailuer:mtv error:MSG_SAVEFAILURE];
                        }
                    }
                    //        isCreating_ = NO;
                    
                }];
    if(!ret && isCreating_)
        ret = YES;
    return ret;
    
}
- (BOOL) uploadMTVAudio:(MTV *)mtv
{
    if([self hasAudioPathNeedUpload:mtv])
    {
        NSString * key = [mtv getAudioKey];
        if(!key || key.length==0)
        {
            key = [[UDManager sharedUDManager]getKey:mtv.AudioFileName];
        }
        UDInfo * item = [self getUDInfoByKey:key];
        
        if(item && item.Key && item.Key.length>0)
        {
            if(![[UDManager sharedUDManager]startUploadItem:item.Key delegate:self])
            {
#ifndef __OPTIMIZE__
                UInt64 size = [[UDManager sharedUDManager]fileSizeAtPath:[mtv getAudioPathN]];
                NSLog(@"upload audio size:[%llu] for file:%@",size,[mtv.AudioFileName lastPathComponent]);
#endif
                key = [[UDManager sharedUDManager]addUploadProgress:[mtv getAudioPathN] domainType:(int)DOMAIN_MUSIC delegate:self autoStart:YES];
            };
        }
        else
        {
#ifndef __OPTIMIZE__
            UInt64 size = [[UDManager sharedUDManager]fileSizeAtPath:[mtv getAudioPathN]];
            NSLog(@"upload audio size:[%llu] for file:%@",size,[mtv.AudioFileName lastPathComponent]);
#endif
            key = [[UDManager sharedUDManager]addUploadProgress:[mtv getAudioPathN] domainType:(int)DOMAIN_MUSIC delegate:self autoStart:YES];
        }
        if(key && key.length>0)
        {
            [mtv setAudioKey:key];
            [self updateLocalDB:mtv];
            //            [self saveMTVInfoToLocalDir:mtv];
            NSLog(@"start upload (%@) audiofile:%@ ....",key,mtv.AudioFileName);
            return YES;
        }
        else
        {
            NSLog(@"upload audio failure:%@ ....",mtv.AudioFileName);
            return NO;
        }
    }
    else
    {
        NSLog(@"upload audio : no files need upload.");
        NSString * key = [mtv getAudioKey];
        UDInfo * info = [UDInfo new];
        info.Key = key;
        info.Status = 4;
        info.RemoteUrl = mtv.AudioRemoteUrl;
        info.LocalFileName = mtv.AudioFileName;
        info.Percent = 1;
        info.DateModified = [CommonUtil stringFromDate:[NSDate date]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[DBHelper sharedDBHelper]insertData:info needOpenDB:YES forceUpdate:YES];
        });
        
        [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADCOMPLETED object:info userInfo:nil];
        PP_RELEASE(info);
    }
    return YES;
}
- (BOOL) uploadMTV:(MTV * )mtv
{
    if([self hasAudioPathNeedUpload:mtv]){
        if(![self uploadMTVAudio:mtv])
        {
            NSLog(@"upload audio failure.");
            return NO;
        }
    }
    {
        NSString * key = [mtv getKey];
        if(!key || key.length==0)
        {
            key = [[UDManager sharedUDManager]getKey:mtv.FileName];
        }
        UDInfo * item = [self getUDInfoByKey:key];
#ifndef __OPTIMIZE__
        UInt64 size = [[UDManager sharedUDManager]fileSizeAtPath:[mtv getFilePathN]];
        NSLog(@"upload mtv size:[%llu] for file:%@",size,[mtv.FileName lastPathComponent]);
#endif
        if(item && item.Key && item.Key.length>0)
        {
            if(![[UDManager sharedUDManager]startUploadItem:item.Key delegate:self])
            {
                key = [[UDManager sharedUDManager]addUploadProgress:[mtv getFilePathN] domainType:(int)DOMAIN_MTVS delegate:self autoStart:YES];
            };
        }
        else
        {
            key = [[UDManager sharedUDManager]addUploadProgress:[mtv getFilePathN] domainType:(int)DOMAIN_MTVS delegate:self autoStart:YES];
        }
        if(key && key.length>0)
        {
            if(![key isEqualToString:mtv.Key]||mtv.UserID!=[UserManager sharedUserManager].userID)
            {
                [mtv setKey:key];
                mtv.UserID = [UserManager sharedUserManager].userID;
                //            mtv.Key = key;
                [self updateMTVKeyAndUserID:mtv];
            }
            [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADBEGIN object:mtv];
            
            return YES;
        }
    }
    NSLog(@"upload mtv failure.");
    return NO;
}
- (void)updateMTVKeyAndUserID:(MTV*)mtv
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if(!mtv.Key || mtv.Key.length==0)
        {
            [mtv getKey];
        }
        mtv.Author = [[UserManager sharedUserManager]currentUser].NickName;
        dispatch_async([DBHelper_WT getDBQueue], ^{
            [DBHelper_WT updateMtvKey:mtv.MTVID key:mtv.Key];
        });
        
        //        MTV * newMtv = [MTV new];
        //        newMtv.MTVID = mtv.MTVID;
        //        newMtv.Key = mtv.Key;
        //        newMtv.UserID = mtv.UserID;
        //        newMtv.Author = mtv.Author;
        //        newMtv.IsLandscape = mtv.IsLandscape;
        //        newMtv.SampleID = mtv.SampleID;
        
        NSLog(@"create mtv islandscape:%d",mtv.IsLandscape);
        //更新服务器
        if(mtv.SampleID <=0)
        {
            CMD_CreateMTV * cmd = (CMD_CreateMTV *)[[CMDS_WT sharedCMDS_WT]createCMDOP:@"CreateMTV"];
            cmd.MtvData = mtv;
            cmd.CMDCallBack = nil;
            cmd.justUpdateKey = 1;
            [cmd sendCMD];
        }
        else
        {
            CMD_UploadMBMTV * cmd = (CMD_UploadMBMTV *)[[CMDS_WT sharedCMDS_WT]createCMDOP:@"UploadMBMTV"];
            cmd.data = mtv;
            cmd.Materials = nil;
            cmd.justUpdateKey = 1;
            cmd.CMDCallBack = nil;
            [cmd sendCMD];
        }
    });
}
- (BOOL) isUploading:(MTV *)mtv
{
    NSString * key = [mtv getKey];
    if(!key || key.length==0)
    {
        key = [[UDManager sharedUDManager]getKey:mtv.FileName];
    }
    UDInfo * item = [self getUDInfoByKey:key];
    if(item && item.Key && item.Key.length>0)
    {
        //0 未开始或暂停 1处理中 2 失败 4完成 5 因为网络，系统自动暂停,6用户取消 9 本地文件不存在
        if(item.Status == 1)
        {
            return YES;
        }
    }
    if(mtv.AudioFileName && mtv.AudioFileName.length>3)
    {
        key = [mtv getAudioKey];
        if(!key || key.length==0)
        {
            key = [[UDManager sharedUDManager]getKey:mtv.AudioFileName];
        }
        UDInfo * item = [self getUDInfoByKey:key];
        if(item && item.Key && item.Key.length>0)
        {
            //0 未开始或暂停 1处理中 2 失败 4完成 5 因为网络，系统自动暂停,6用户取消 9 本地文件不存在
            if(item.Status == 1)
            {
                return YES;
            }
        }
    }
    return NO;
}
- (BOOL)hasAudioPathNeedUpload:(MTV *)mtv
{
    UInt64 size = 0;
    if(mtv.AudioFileName && mtv.AudioFileName.length>3)
    {
        BOOL isExist = NO;
        NSString * newPath = [mtv getAudioPathN];
        isExist = [[UDManager sharedUDManager]isFileExistAndNotEmpty:newPath size:&size];
        if(isExist)
        {
        }
        else
        {
            [mtv setAudioPathN:nil];
        }
    }
    
    if(mtv.AudioFileName && mtv.AudioFileName.length>3)
    {
        if(!mtv.AudioRemoteUrl ||mtv.AudioRemoteUrl.length<3)
        {
            return YES;
        }
        if(self.networkStatus !=ReachableNone)
        {
            UInt64 remoteSize = 0;
            if([HCFileManager checkUrlIsExists:mtv.AudioRemoteUrl contengLength:&remoteSize level:nil])
            {
                if(remoteSize == size)
                {
                    return NO;
                }
                else
                {
                    return YES;
                }
            }
        }
        return YES;
    }
    return NO;
}

- (BOOL) stopUploadMtv:(MTV *)mtv
{
    NSString * key = [mtv getKey];
    if(!key || key.length==0)
    {
        key = [[UDManager sharedUDManager]getKey:mtv.FileName];
    }
    [[UDManager sharedUDManager]stopProgress:key delegate:self];
    if([self hasAudioPathNeedUpload:mtv])
    {
        key = [mtv getAudioKey];
        if(!key || key.length==0)
        {
            key = [[UDManager sharedUDManager]getKey:mtv.AudioFileName];
        }
        [[UDManager sharedUDManager]stopProgress:key delegate:self];
    }
    return YES;
}
- (BOOL) resetUpload:(MTV *)mtv
{
    NSString * key = [mtv getKey];
    if(!key || key.length==0)
    {
        key = [[UDManager sharedUDManager]getKey:mtv.FileName];
    }
    UDInfo * item = [self getUDInfoByKey:key];
    if(item && item.Key && item.Key.length>0)
    {
        [[UDManager sharedUDManager] cancelProgress:item.Key delegate:self];
    }
    key = [[UDManager sharedUDManager]addUploadProgress:[mtv getFilePathN]  domainType:(int)DOMAIN_MTVS delegate:self autoStart:YES];
    
    if([self hasAudioPathNeedUpload:mtv])
    {
        NSString * keyAudio = [mtv getAudioKey];
        if(!keyAudio || keyAudio.length==0)
        {
            keyAudio = [[UDManager sharedUDManager]getKey:mtv.AudioFileName];
        }
        [[UDManager sharedUDManager]cancelProgress:key delegate:self];
    }
    
    if(key && key.length>0)
    {
        return YES;
    }
    return NO;
}
- (BOOL) deleteUpload:(MTV *)mtv
{
    NSString * key = [mtv getKey];
    if(!key || key.length==0)
    {
        key = [[UDManager sharedUDManager]getKey:mtv.FileName];
    }
    
    UDInfo * item = [self getUDInfoByKey:key];
    if(item && item.Key && item.Key.length>0)
    {
        [[UDManager sharedUDManager] cancelProgress:item.Key delegate:self];
    }
    
    if([self hasAudioPathNeedUpload:mtv])
    {
        key = [mtv getAudioKey];
        if(!key || key.length==0)
        {
            key = [[UDManager sharedUDManager]getKey:mtv.AudioFileName];
        }
        UDInfo * item = [self getUDInfoByKey:key];
        if(item && item.Key && item.Key.length>0)
        {
            [[UDManager sharedUDManager] cancelProgress:item.Key delegate:self];
        }
    }
    return YES;
}

- (void)UDManager:(UDManager *)manager key:(NSString *)key progress:(UDInfo*)item
{
    [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADPROGRESSCHANGED object:item userInfo:nil];
}
- (void)UDManager:(UDManager *)manager key:(NSString *)key didCompleted:(UDInfo *)item
{
    MTV * mtv = [self getMTVByKey:item.Key];
    if(!mtv)
    {
        NSLog(@"** fatal error:********************");
        NSLog(@" not found mtv for udinfo:%@",[item JSONRepresentationEx]);
        NSLog(@"** fatal error:********************");
        //        [self moveUploadedMTV2Album:item.LocalFilePath mtvID:0 item:nil];
        [self didUploadMtvFile:mtv udInfo:item];
        return;
    }
    NSString * audioKey = [mtv getAudioKey];
    if(audioKey && [key isEqualToString:audioKey])
    {
        [self didUploadMtvMusic:mtv udInfo:item];
    }
    else if([key isEqualToString:[mtv getKey]])
    {
        [self didUploadMtvFile:mtv udInfo:item];
    }
}
- (void)didUploadMtvMusic:(MTV*)mtv udInfo:(UDInfo*)item
{
    dispatch_async([DBHelper_WT getDBQueue], ^{
        [DBHelper_WT updateMtvAudioRemoteUrl:mtv.MTVID removeUrl:item.RemoteUrl];
    });
    //如果上传完成了，则需要调用命令，去向服务器输入信息
    CMD_UploadMTV *cmd = (CMD_UploadMTV *)[[CMDS_WT sharedCMDS_WT]createCMDOP:@"UploadMTV"];
    mtv.AudioRemoteUrl = item.RemoteUrl;
    //    mtv.FilePath = item.OrgUrl; //更正FilePath
    [mtv setAudioPathN:item.LocalFilePath];
    
    NSLog(@"create mtv islandscape:%d",mtv.IsLandscape);
    
    cmd.MtvData = mtv;
    cmd.uploadType = 1;//audio
    cmd.CMDCallBack = ^(HCCallbackResult *result)
    {
        NSLog(@" mtv:[%ld]%@ audio url:[%@]upload ok.",mtv.MTVID,mtv.Title,mtv.AudioRemoteUrl);
        // [self copyUploadedMTV2Album:item.LocalFilePath mtvID:mtv.MTVID item:mtv];
        
        MTVLocal * mtvLocal = nil;
        if([mtv isKindOfClass:[MTVLocal class]])
        {
            mtvLocal = (MTVLocal *)mtv;
        }
        else
        {
            mtvLocal = [[MTVLocal alloc]initWithMTV:mtv];
        }
        [self saveMTVInfoToLocalDir:mtvLocal];
        //通知界面更新状态
        [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADCOMPLETED object:item userInfo:nil];
        
    };
    [cmd sendCMD];
    
//    [[UMShareObject shareObject]event:@"UploadAudio" attributes:@{@"title":mtv.Title?mtv.Title:@"NoName",@"url":@"UploadAudio"}];
}
- (void)didUploadMtvFile:(MTV *)mtv udInfo:(UDInfo *)item
{
    dispatch_async([DBHelper_WT getDBQueue], ^{
        [DBHelper_WT updateMtvRemoteUrl:mtv.MTVID removeUrl:item.RemoteUrl];
    });
    //如果上传完成了，则需要调用命令，去向服务器输入信息
    CMD_UploadMTV *cmd = (CMD_UploadMTV *)[[CMDS_WT sharedCMDS_WT]createCMDOP:@"UploadMTV"];
    mtv.DownloadUrl = item.RemoteUrl;
    //    mtv.FilePath = item.OrgUrl; //更正FilePath
    [mtv setFilePathN:item.LocalFilePath];
    cmd.MtvData = mtv;
    cmd.uploadType =2; //mtv
    NSLog(@"create mtv islandscape:%d",mtv.IsLandscape);
    
    cmd.CMDCallBack = ^(HCCallbackResult *result)
    {
        NSLog(@" mtv:[%ld]%@ file url:[%@]upload ok.",mtv.MTVID,mtv.Title,mtv.DownloadUrl);
        // [self copyUploadedMTV2Album:item.LocalFilePath mtvID:mtv.MTVID item:mtv];
        
        MTVLocal * mtvLocal = nil;
        if([mtv isKindOfClass:[MTVLocal class]])
        {
            mtvLocal = (MTVLocal *)mtv;
        }
        else
        {
            mtvLocal = [[MTVLocal alloc]initWithMTV:mtv];
        }
        [self removeMtvLocalInfo:mtvLocal];
        //        [self saveMTVInfoToLocalDir:mtvLocal];
        //通知界面更新状态
        [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADCOMPLETED object:item userInfo:nil];
        [[NSNotificationCenter defaultCenter]postNotificationName:NT_CHANGEITEMSTATUS object:mtv userInfo:nil];
        [self removeMTVFromList:mtv];
    };
    [cmd sendCMD];
//    [[UMShareObject shareObject]event:@"UploadMV" attributes:@{@"title":mtv.Title?mtv.Title:@"NoName",@"url":@"UploadMV"}];
}
- (void)UDManager:(UDManager *)manager key:(NSString *)key didFailure:(UDInfo *)item
{
    [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADSTATECHANGED object:item userInfo:nil];
}
- (void)UDManager:(UDManager *)manager key:(NSString *)key didStart:(UDInfo *)item
{
    [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADSTATECHANGED object:item userInfo:nil];
}
- (void)UDManager:(UDManager *)manager key:(NSString *)key didStop:(UDInfo *)item
{
    [[NSNotificationCenter defaultCenter]postNotificationName:NT_UPLOADSTATECHANGED object:item userInfo:nil];
}


#pragma mark - check upload
- (BOOL)isMtvUploaded:(MTV *)mtv
{
    //音频在视频之前上传，因此，有视频一定有音频
    if(!mtv || (!mtv.DownloadUrl || mtv.DownloadUrl.length<=2)) return NO;
    
    UDInfo * item  = [[UDManager sharedUDManager]queryItem:[mtv getKey]];
    BOOL isUrlExists = [HCFileManager checkUrlIsExists:mtv.DownloadUrl contengLength:nil level:nil];
    if(isUrlExists &&(!item || item.Status == 4))
    {
        return YES;
    }
    else
    {
        return NO;
    }
    
    //    return NO;
}

- (void)setAutoupload:(BOOL)autoupload
{
    if(canAutoUpload_!=autoupload)
    {
        canAutoUpload_ = autoupload;
        [self doNetworkChanged:networkStatus_];
    }
    else
    {
        canAutoUpload_ = autoupload;
    }
}

#pragma mark - file to uploaders
- (NSMutableArray *)getListFromLocalDir
{
    NSString * regEx = nil;
    //regEx = @".*\\.mp4\\.mtd$";
    regEx = @".*\\.mp4\\.mtd$|.*\\.mov\\.mtd$|.*\\.MOV\\.mtd$";
    
    HCFileManager * ud = [HCFileManager manager];
    
    NSString * dir = [ud getFilePath:[ud localFileDir]];
    
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:dir]) return nil;
    
    NSMutableArray * fileList = [NSMutableArray new];
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:dir] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        if([fileName isMatchedByRegex:regEx])
        {
            NSString* fileAbsolutePath = [dir stringByAppendingPathComponent:fileName];
            
            [fileList addObject:fileAbsolutePath];
            
        }
    }
    NSMutableArray * orgItemList = [NSMutableArray new];
    for (NSString * filePath in fileList) {
        NSError * error = nil;
        NSString * fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
        if(error)
        {
            NSLog(@"read file:%@ error:%@",filePath,[error localizedDescription]);
            fileContent = nil;
        }
        if([fileContent hasPrefix:@"{"]==NO)
        {
            continue;
        }
        else
        {
            MTVLocal * item = [[MTVLocal alloc]initWithJSON:fileContent];
            [self checkMTVFiles:item];
            if(!item.infoPath || item.infoPath.length<2)
                item.infoPath = filePath;
            
            CGFloat size = item.videoSize + item.audioSize + item.coverSize;
            if (size<0.1)
            {
                // 清除无效的mtd文件
                [manager removeItemAtPath:filePath error:nil];
            }
            else
            {
                [orgItemList addObject:item];
            }
        }
    }
    PP_RELEASE(fileList);
    
    return orgItemList;
}
- (void)checkMTVFiles:(MTVLocal *)item
{
    //如果Cover，Lyric，Mp4不存在，则根据文件构建目录，检查其大小
    if(item.coverPath)
    {
        item.coverPath = [[UDManager sharedUDManager] checkPathForApplicationPathChanged:item.coverPath mtvID:0 filetype:1 isExists:nil];
        item.coverSize = [[UDManager sharedUDManager] fileSizeAtPath:item.coverPath]/(1024.0*1024.0);
    }
    else
    {
        NSString * regEx = nil;
        regEx = @".*.jpg$";
        
        NSString * dir = [[UDManager sharedUDManager] localFileFullPath:nil];
        NSFileManager* manager = [NSFileManager defaultManager];
        if (![manager fileExistsAtPath:dir]) return ;
        
        NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:dir] objectEnumerator];
        NSString* fileName;
        while ((fileName = [childFilesEnumerator nextObject]) != nil){
            if([fileName isMatchedByRegex:regEx])
            {
                if ([fileName containsString:[item.FileName lastPathComponent]]) {
                    NSString* fileAbsolutePath = [dir stringByAppendingPathComponent:fileName];
                    item.coverPath = [[UDManager sharedUDManager] checkPathForApplicationPathChanged:fileAbsolutePath mtvID:0 filetype:1 isExists:nil];
                    // item.coverPath = fileAbsolutePath;
                    item.coverSize = [[UDManager sharedUDManager] fileSizeAtPath:item.coverPath]/(1024.0)/(1024.0);
                }
            }
        }
    }
    if(item.FileName && item.FileName.length>0)
    {
        //        item.FilePath = [[UDManager sharedUDManager] checkPathForApplicationPathChanged:item.FilePath mtvID:0 filetype:1 isExists:nil];
        item.videoPath = [item getFilePathN];
        item.videoSize = [[UDManager sharedUDManager] fileSizeAtPath:[item getFilePathN]]/(1024.0)/(1024.0);
    }
    else
    {
        NSLog(@"videoPath 不存在");
    }
    if(item.AudioFileName && item.AudioFileName.length>0)
    {
        //        item.AudioPath = [[UDManager sharedUDManager] checkPathForApplicationPathChanged:item.AudioPath mtvID:0 filetype:1 isExists:nil];
        item.audioSize = [[UDManager sharedUDManager] fileSizeAtPath:[item getAudioPathN]]/(1024.0)/(1024.0);
    }
    else
    {
        NSLog(@"audioPath 不存在");
    }
    if(item.infoPath && item.infoPath.length>2)
    {
        BOOL isExists = NO;
        item.infoPath = [[UDManager sharedUDManager] checkPathForApplicationPathChanged:item.infoPath isExists:&isExists];
        if(!isExists)
        {
            item.infoPath = nil;
        }
    }
    
}
- (BOOL) removeMTVFileInLocalDir:(MTVLocal*)item
{
    if(item.FileName && item.FileName.length>0)
    {
        [[HCFileManager manager]removeFileAtPath:[item getFilePathN]];
    }
    
    if (item.AudioFileName && item.AudioFileName.length>0) {
        [[HCFileManager manager]removeFileAtPath:[item getAudioPathN]];
    }
    
    if (item.coverPath) {
        [[HCFileManager manager]removeFileAtPath:item.coverPath];
    }
    NSString * checkPath = item.infoPath;
    if(!checkPath || checkPath.length<2)
    {
        NSString * checkFile = [NSString stringWithFormat:@"%@.%@",[item.FileName lastPathComponent],@"mtd"];
        checkPath = [[UDManager sharedUDManager]localFileFullPath:checkFile];
    }
    [[HCFileManager manager]removeFileAtPath:checkPath];
    return YES;
}
- (void)removeMtvLocalInfo:(MTVLocal *)item
{
    NSString * checkPath = item.infoPath;
    if(!checkPath || checkPath.length<2)
    {
        NSString * checkFile = [NSString stringWithFormat:@"%@.%@",[item.FileName lastPathComponent],@"mtd"];
        checkPath = [[UDManager sharedUDManager]localFileFullPath:checkFile];
    }
    [[HCFileManager manager]removeFileAtPath:checkPath];
}
- (void)saveMTVInfoToLocalDir:(MTVLocal *)item
{
    //save info
    if (item.FileName && item.FileName.length>0)
    {
        NSString * checkPath = item.infoPath;
        if(!checkPath || checkPath.length< 2)
        {
            NSString * checkFile = [NSString stringWithFormat:@"%@.%@",[item.FileName lastPathComponent],@"mtd"];
            checkPath = [[UDManager sharedUDManager]localFileFullPath:checkFile];
            item.infoPath = checkPath;
        }
        [[HCFileManager manager]removeFileAtPath:checkPath];
        NSString * json = [item toJson];
        NSError * error = nil;
        [json writeToFile:checkPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if(error)
        {
            NSLog(@"save info(%@) error:%@",checkPath,[error localizedDescription]);
        }
    }
}
- (MTV*) getMTVByKey:(NSString *)key
{
    if(!key || key.length==0) return nil;
    @synchronized(self) {
        if(mtvList_)
        {
            for (int i = (int)mtvList_.count-1; i>=0; i --) {
                MTV * item = mtvList_[i];
                NSString * mvKey = [item getKey];
                NSString * audioKey = [item getAudioKey];
                if(mvKey && [mvKey isEqualToString:key])
                {
                    return item;
                }
                else if(audioKey && [audioKey isEqualToString:key])
                {
                    return item;
                }
            }
        }
    }
    MTV * item = [self queryMTVFromLocal:key orgPath:nil];
    if(item)
    {
        [self addMTVToList:item];
    }
    return item;
}
- (void) addMTVToList:(MTV*)mtv
{
    @synchronized(self) {
        if(!mtvList_) mtvList_ = [NSMutableArray new];
        BOOL isExists = NO;
        for (int i = (int)mtvList_.count-1; i>=0; i--) {
            MTV * item = mtvList_[i];
            if(item == mtv ||
               (item.MTVID>0 && mtv.MTVID>0 && item.MTVID == mtv.MTVID) ||
               (item.FileName && mtv.FileName && [item.FileName isEqualToString:mtv.FileName])
               )
            {
                isExists = YES;
                break;
            }
        }
        if(!isExists)
        {
            [mtvList_ addObject:mtv];
        }
    }
}
- (void)removeMTVFromList:(MTV*)mtv
{
    @synchronized(self) {
        if(!mtvList_) return;
        
        NSMutableArray * removeList = [NSMutableArray new];
        for (int i = (int)mtvList_.count-1; i>=0; i--) {
            MTV * item = mtvList_[i];
            if(item == mtv ||
               (item.MTVID>0 && mtv.MTVID>0 && item.MTVID == mtv.MTVID) ||
               (item.FileName && mtv.FileName && [item.FileName isEqualToString:mtv.FileName])
               )
            {
                [removeList addObject:item];
            }
        }
        if(removeList.count>0)
        {
            [mtvList_ removeObjectsInArray:removeList];
        }
        PP_RELEASE(removeList);
    }
}
- (NSArray *)getMTVListForUpload
{
    DBHelper * dbHelper = [DBHelper sharedDBHelper];
    NSString * sqlStr = @"select * from mtvs where mtvid<0 or (mtv.downloadurl not like 'http://' ) order by DateCreated desc;";
    
    NSMutableArray * udList = [NSMutableArray array];
    if([dbHelper open])
    {
        [dbHelper execWithArray:udList class:NSStringFromClass([MTV class]) sql:sqlStr];
        [dbHelper close];
    }
    return udList;
}

- (MTV *)queryMTVFromLocal:(NSString *)key orgPath:(NSString *)orgPath
{
    MTV * mtv = [MTV new];
    if(key && key.length>0)
    {
        NSString * sqlStr = [NSString stringWithFormat:@"select * from mtvs where Key='%@' or AudioKey='%@';",key,key];
        DBHelper * dbHelper = [DBHelper sharedDBHelper];
        
        if([dbHelper open])
        {
            [dbHelper execWithEntity:mtv sql:sqlStr];
            [dbHelper close];
        }
        
        if(mtv.MTVID !=0 )
        {
            return PP_AUTORELEASE(mtv);
        }
    }
    if(orgPath && orgPath.length>0)
    {
        NSString * sqlStr = [NSString stringWithFormat:@"select * from mtvs where FilePath='%@' or AudioPath='%@';",orgPath,orgPath];
        DBHelper * dbHelper = [DBHelper sharedDBHelper];
        MTV * mtv = [MTV new];
        if([dbHelper open])
        {
            [dbHelper execWithEntity:mtv sql:sqlStr];
            [dbHelper close];
        }
        if(mtv.MTVID !=0 )
        {
            return PP_AUTORELEASE(mtv);
        }
    }
    PP_RELEASE(mtv);
    return nil;
}
- (long) insertIntoLocalDB:(MTV *)data
{
    
    DBHelper * db = [DBHelper sharedDBHelper];
    NSInteger newID = 0;
    //获取当前的最大的负ID
    if(data.MTVID == 0)
    {
        NSString * sql = [NSString stringWithFormat:@"select min(mtvID) as MtvID FROM mtvs;"];
        NSString * newIDStr = nil;
        
        if([db open])
        {
            [db execScalar:sql result:&newIDStr];
            [db close];
        }
        if(newIDStr!=nil && newIDStr.length>0)
        {
            newID = [newIDStr integerValue];
        }
        if(newID >=0) newID = -1;
        else newID --;
        
        data.MTVID = newID;
    }
    
    NSLog(@"insert mtv to localdb:[%ld]%@",data.MTVID,data.Title);
    BOOL ret = [db insertData:data needOpenDB:YES forceUpdate:YES];
    if(ret)
        return data.MTVID;
    else
        return 0;
}
- (void) updateLocalDB:(MTV *)data
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[DBHelper sharedDBHelper]insertData:data needOpenDB:YES forceUpdate:YES];
    });
}
- (void)clearAllUploads
{
    NSArray * itemList = [self getUploadList];
    for (UDInfo * item in itemList) {
        if(item.IsUpload)
        {
            [[UDManager sharedUDManager] cancelProgress:item.Key delegate:self];
            [self removeMtvUpload:item.OrgUrl];
        }
    }
}
- (void)removeMtvUpload:(NSString *)fileFullPath
{
    DBHelper * dbHelper = [DBHelper sharedDBHelper];
    NSString * sql = [NSString stringWithFormat:@"select * from mtvs where filepath='%@' OR AudioPath='%@';",fileFullPath,fileFullPath];
    MTV * mtv = [MTV new];
    if([dbHelper open])
    {
        [dbHelper execWithEntity:mtv sql:sql];
        [dbHelper close];
    }
    
    if(mtv.MTVID!=0)
    {
        CMD_DeleteMyMTV * cmd = (CMD_DeleteMyMTV *)[[CMDS_WT sharedCMDS_WT]createCMDOP:@"DeleteMyMTV"];
        if(mtv.MTVID<0)
        {
            [cmd DeleteFromDB:mtv.MTVID];
        }
        else
        {
            cmd.mtvID = mtv.MTVID;
            [cmd sendCMD];
        }
    }
    PP_RELEASE(mtv);
}
@end

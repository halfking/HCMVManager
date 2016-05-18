//
//  MTV.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/3/25.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "MTV.h"
#import <hccoren/json.h>
#import <hccoren/base.h>
#import <hcbasesystem/updown.h>
#import <hcbasesystem/user_wt.h>
#import <hcbasesystem/VDCManager.h>

@implementation MTV
@synthesize MTVID,Durance,ShareRights,MusicID,MtvType;
@synthesize Title,Author,Category,CoverUrl,Lyric;
@synthesize MergeTime,UploadTime;
@synthesize DownloadUrl,FileName,DownloadUrl720,DownloadUrl360,DownloadUrl1080,AudioFileName;
@synthesize Hash720,Hash360;
@synthesize AudioRemoteUrl;
@synthesize IsLandscape;
@synthesize UserID;
@synthesize Memo;
@synthesize DateCreated;
@synthesize PlayCount,FavCount,ShareCount,LikeCount,CommentCount,FansCount;
@synthesize IsLike,IsComment,IsFav,IsShare,IsFollowed;
@synthesize ShareUrl;
@synthesize Lat,Lng,Address,ShowAddress;
@synthesize HeadPortrait;
@synthesize SampleID;
@synthesize MBMTVID;

@synthesize MName,IsRecommend,Sort;
@synthesize UploadKey;
@synthesize QiKey;
@synthesize Shares,Tag,Key = key;
@synthesize DataStatus,Materials,Adapter;
@synthesize AudioKey,AudioQiKey;
@synthesize isCheckDownload;
@synthesize OnlyAudio;
//@synthesize Mbsum;

//@synthesize Key;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"mtvs";
        self.KeyName = @"MTVID";
        //        IsLandscape = 1;
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dic
{
    self = [super initWithDictionary:dic];
    
    //补:因为数据结构变化，导致的可能有些值无法直接获取的问题
    if (![dic objectForKey:@"FileName"] && [dic objectForKey:@"FilePath"]) {
        [self setFilePathN:[dic objectForKey:@"FilePath"]];
    }
    else if (![dic objectForKey:@"filename"] && [dic objectForKey:@"filepath"]) {
        [self setFilePathN:[dic objectForKey:@"filepath"]];
    }
    if (![dic objectForKey:@"AudioFileName"] && [dic objectForKey:@"AudioPath"]) {
        [self setAudioPathN:[dic objectForKey:@"AudioPath"]];
    }
    else if (![dic objectForKey:@"audiofilename"] && [dic objectForKey:@"audiopath"]) {
        [self setAudioPathN:[dic objectForKey:@"audiopath"]];
    }
    
    NSDictionary * summary = nil;
    if([dic objectForKey:@"WorkCollections"])
    {
        summary = [dic objectForKey:@"WorkCollections"];
        if(![summary isKindOfClass:[NSNull class]])
        {
            if([summary objectForKey:@"PlayCount"])
            {
                self.PlayCount = [[summary objectForKey:@"PlayCount"]intValue];
            }
            if([summary objectForKey:@"LikeCount"])
            {
                self.LikeCount = [[summary objectForKey:@"LikeCount"]intValue];
            }
            if([summary objectForKey:@"FavCount"])
            {
                self.FavCount = [[summary objectForKey:@"FavCount"]intValue];
            }
            if([summary objectForKey:@"ShareCount"])
            {
                self.ShareCount = [[summary objectForKey:@"ShareCount"]intValue];
            }
        }
    }
    else if([dic objectForKey:@"workcollections"])
    {
        summary = [dic objectForKey:@"workcollections"];
        if(![summary isKindOfClass:[NSNull class]])
        {
            if([summary objectForKey:@"playcount"])
            {
                self.PlayCount = [[summary objectForKey:@"playcount"]intValue];
            }
            if([summary objectForKey:@"likecount"])
            {
                self.LikeCount = [[summary objectForKey:@"likecount"]intValue];
            }
            if([summary objectForKey:@"favcount"])
            {
                self.FavCount = [[summary objectForKey:@"favcount"]intValue];
            }
            if([summary objectForKey:@"sharecount"])
            {
                self.ShareCount = [[summary objectForKey:@"sharecount"]intValue];
            }
        }
    }
    //    if([dic objectForKey:@"mbmtvsum"])
    //    {
    //
    //    }
    return self;
}
- (NSString *)getKey
{
    if(!key || key.length==0)
    {
        if(self.DownloadUrl && self.DownloadUrl.length>0)
        {
            NSString * result = [self.DownloadUrl lastPathComponent];
            NSLog(@"last path as key:%@",result);
            key = PP_RETAIN(result);
        }
        else if(self.FileName && self.FileName.length>0)
        {
            key = PP_RETAIN([[UDManager sharedUDManager]getKey:self.FileName andUserID:self.UserID]);
        }
    }
    return key;
}
- (void)setKey:(NSString *)key1
{
    PP_RELEASE(key);
    key = PP_RETAIN(key1);
}

- (NSString *)getAudioKey
{
    if(!AudioKey || AudioKey.length==0)
    {
        if(self.AudioRemoteUrl && self.AudioRemoteUrl.length>5)
        {
            NSString * result = [self.AudioRemoteUrl lastPathComponent];
            NSLog(@"last path as key:%@",result);
            AudioKey = PP_RETAIN(result);
        }
        else if(self.AudioFileName && self.AudioFileName.length>5)
        {
            AudioKey = PP_RETAIN([[UDManager sharedUDManager]getKey:self.AudioFileName andUserID:self.UserID]);
        }
    }
    return AudioKey;
}
- (void)setAudioKey:(NSString *)key1
{
    PP_RELEASE(AudioKey);
    AudioKey = PP_RETAIN(key1);
}
- (NSString *)getCoverPath
{
    //首先看本地文件是否存在
    NSString * path = self.CoverUrl;
    if([path hasPrefix:@"file://"])
    {
        path = [path substringFromIndex:7];
    }
    return path;
}
- (NSString *)getMTVUrlString:(NetworkStatus)netStatus userID:(NSInteger)userID  remoteUrl:(NSString **)remoteUrl;
{
    //首先看本地文件是否存在
    NSString * path = [self getFilePathN];
    if(path && path.length>0){
        
        //        path = @"/var/mobile/Containers/Data/Application/7D395D9F-A5A0-4D66-9498-1261B65F8893/Documents/recordfiles/20150713173604record.mov";
        
        if(![[UDManager sharedUDManager]isFileExistAndNotEmpty:path size:nil])
        {
            FileName = nil;
            path = nil;
        }
    }
    
    if(!path || path.length==0)
    {
        if(self.DownloadUrl720 && self.DownloadUrl720.length>0)
        {
            if ([[VDCManager shareObject]isExistsLocalFile:self.DownloadUrl720]) {
                path = self.DownloadUrl720;
            }
        }
        if(!path || path.length==0)
        {
            HCUserSettings * settings = [[UserManager sharedUserManager]currentSettings];
            
            if(settings.imgModel == HCImgViewModelCustom || (settings.imgModel == HCImgViewModelAgent && netStatus==ReachableViaWWAN)){
                path = self.DownloadUrl360 && self.DownloadUrl360.length>0?self.DownloadUrl360:self.DownloadUrl720;
            }
            
            if(!path || path.length==0)
                path = self.DownloadUrl720 && self.DownloadUrl720.length>0?self.DownloadUrl720:self.DownloadUrl1080;
            
            if(!path ||path.length==0)
            {
                path = self.DownloadUrl;
            }
            if(remoteUrl)
            {
                *remoteUrl = path;
            }
        }
        else if(remoteUrl)
        {
            *remoteUrl = path;
        }
    }
    else if(remoteUrl)
    {
        NSString * newPath = nil;
        HCUserSettings * settings = [[UserManager sharedUserManager]currentSettings];
        
        if(settings.imgModel == HCImgViewModelCustom || (settings.imgModel == HCImgViewModelAgent && netStatus==ReachableViaWWAN)){
            newPath = self.DownloadUrl360 && self.DownloadUrl360.length>0?self.DownloadUrl360:self.DownloadUrl720;
        }
        
        if(!newPath || newPath.length==0)
            newPath = self.DownloadUrl720 && self.DownloadUrl720.length>0?self.DownloadUrl720:self.DownloadUrl1080;
        
        if(!newPath ||newPath.length==0)
        {
            newPath = self.DownloadUrl;
        }
        *remoteUrl = newPath;
    }
    if(path && path.length>0)
        return path;
    else
        return nil;
    
}
- (NSString *)getAudioUrlString
{
    //首先看本地文件是否存在
    NSString * path = [self getAudioPathN];
    if(path && path.length>0){
        
        //        path = @"/var/mobile/Containers/Data/Application/7D395D9F-A5A0-4D66-9498-1261B65F8893/Documents/recordfiles/20150713173604record.mov";
        
        if(![[UDManager sharedUDManager]isFileExistAndNotEmpty:path size:nil])
        {
            AudioFileName = nil;
            path = nil;
        }
    }
    
    if(!path || path.length==0)
    {
        if(self.AudioRemoteUrl && self.AudioRemoteUrl.length>0)
        {
            if ([[VDCManager shareObject]isExistsLocalFile:self.AudioRemoteUrl]) {
                path = self.AudioRemoteUrl;
            }
        }
        if(!path || path.length==0)
        {
            if([HCFileManager checkUrlIsExists:self.AudioRemoteUrl contengLength:nil level:nil])
                path = self.AudioRemoteUrl;
        }
    }
    if(path && path.length>0)
        return path;
    else
        return nil;
    
}
- (NSString *)locationAddress:(NSInteger)userID
{
    if(self.ShowAddress >0 ||self.UserID == userID)
    {
        return self.Address;
    }
    else
    {
        return @"用户隐藏";
    }
}
- (NSString*)getDownloadUrlOpeated:(NetworkStatus)netStatus userID:(NSInteger)userID
{
    NSString * path = nil;
    if(self.DownloadUrl720 && self.DownloadUrl720.length>0)
    {
        if ([[VDCManager shareObject]isExistsLocalFile:self.DownloadUrl720]) {
            path = self.DownloadUrl720;
        }
    }
    if(!path || path.length==0)
    {
        HCUserSettings * settings = [[UserManager sharedUserManager]currentSettings];
        
        if(settings.imgModel == HCImgViewModelCustom || (settings.imgModel == HCImgViewModelAgent && netStatus==ReachableViaWWAN)){
            path = self.DownloadUrl360 && self.DownloadUrl360.length>0?self.DownloadUrl360:self.DownloadUrl720;
        }
        
        if(!path || path.length==0)
            path = self.DownloadUrl720 && self.DownloadUrl720.length>0?self.DownloadUrl720:self.DownloadUrl1080;
        
        if(!path ||path.length==0)
        {
            path = self.DownloadUrl;
        }
    }
    return path;
}
- (BOOL)hasAudio
{
    if(self.AudioFileName && self.AudioFileName.length>5)
    {
        if([[UDManager sharedUDManager]isFileExistAndNotEmpty:[self getAudioPathN] size:nil])
        {
            return YES;
        }
    }
    if(self.AudioRemoteUrl && self.AudioRemoteUrl.length>5)
        return YES;
    else
        return NO;
}
- (BOOL)hasVideo
{
    if(self.DownloadUrl && self.DownloadUrl.length>5)
        return YES;
    else if(self.DownloadUrl720 && self.DownloadUrl720.length>5)
        return YES;
    else if(self.FileName && self.FileName.length>5)
    {
        NSString * fileName = [[self.FileName lastPathComponent]lowercaseString];
        if([fileName hasSuffix:@"mp4"]||
           [fileName hasSuffix:@"mov"] ||
           [fileName hasSuffix:@"asf"] ||
           [fileName hasSuffix:@"avi"] ||
           [fileName hasSuffix:@"rvm"])
        {
            return YES;
        }
        else
        {
            return NO;
        }
    }
    else
        return NO;
}
- (MTV *)copyItem
{
    NSDictionary * dic = [self toDicionary];
    MTV * item = [[MTV alloc]initWithDictionary:dic];
    //
    //    item.MTVID = self.MTVID;
    //    item.SampleID = self.SampleID;
    //    item.Title = self.Title;
    //    item.Author = self.Author;
    //    item.HeadPortrait = self.HeadPortrait;
    //    item.Lyric = self.Lyric;
    //    item.CoverUrl = self.CoverUrl;
    //    item.DownloadUrl = self.DownloadUrl;
    //    item.DownloadUrl360 = self.DownloadUrl360;
    //    item.DownloadUrl720 = self.DownloadUrl720;
    //    item.FilePath = self.FilePath;
    //
    //    item.Adapter = self.Adapter;
    //    item.Durance = self.Durance;
    //
    //
    //    item.AudioRemoteUrl = self.AudioRemoteUrl;
    //    item.AudioKey = self.AudioKey;
    //    item.AudioPath = self.AudioPath;
    //    item.FilePath = self.FilePath;
    //
    //    item.IsLike = self.IsLike;
    //    item.LikeCount = self.LikeCount;
    //    item.FansCount = self.FansCount;
    //    item.IsFollowed = self.IsFollowed;
    //
    //    item.PlayCount = (int)self.PlayCount;
    //    item.IsShare = self.IsShare;
    //    item.ShareCount = self.ShareCount;
    //    item.IsFav = self.IsFav;
    //    item.FavCount = self.FavCount;
    //    item.CommentCount = self.CommentCount;
    //
    //    item.IsLandscape = self.IsLandscape;
    //    item.UserID = self.UserID;
    //    item.Memo = self.Memo;
    //
    //    item.DateCreated = self.DateCreated;
    //    item.ShareUrl = self.ShareUrl;
    //
    //    item.Lat = self.Lat;
    //    item.Lng = self.Lng;
    //    item.Address = self.Address;
    //    item.ShowAddress = self.ShowAddress;
    //
    //
    //    item.MBMTVID = self.MBMTVID;
    //    item.MName = self.MName;
    //    item.IsRecommend = self.IsRecommend;
    //    item.Sort = self.Sort;
    //    item.UploadKey = self.UploadKey;
    //    item.QiKey = self.QiKey;
    //    item.Shares = self.Shares;
    //    item.Key = self.Key;
    //    item.DataStatus = self.DataStatus;
    //
    //    item.AudioQiKey = self.AudioQiKey;
    //    item.isCheckDownload = self.isCheckDownload;
    
    return PP_AUTORELEASE(item);
}
-(void) dealloc
{
    PP_RELEASE(Hash360);
    PP_RELEASE(Hash720);
    PP_RELEASE(AudioRemoteUrl);
    PP_RELEASE(AudioFileName);
    PP_RELEASE(key_);
    PP_RELEASE(Title);
    PP_RELEASE(Author);
    PP_RELEASE(Category);
    PP_RELEASE(CoverUrl);
    PP_RELEASE(Lyric);
    PP_RELEASE(MergeTime);
    PP_RELEASE(UploadTime);
    PP_RELEASE(DownloadUrl);
    PP_RELEASE(DownloadUrl720);
    PP_RELEASE(DownloadUrl1080);
    PP_RELEASE(FileName);
    PP_RELEASE(Memo);
    PP_RELEASE(DateCreated);
    PP_RELEASE(Address);
    PP_RELEASE(HeadPortrait);
    PP_RELEASE(QiKey);
    
    PP_RELEASE(AudioQiKey);
    PP_RELEASE(AudioKey);
    
    PP_RELEASE(localAudioPath_);
    PP_RELEASE(localFilePath_);
    //    PP_RELEASE(Key);
    
    PP_SUPERDEALLOC;
}
- (void)setAudioFileName:(NSString *)AudioFileNameA
{
    AudioFileName = AudioFileNameA;
    localAudioPath_ = nil;
}
- (void)setFileName:(NSString *)FileNameA
{
    FileName = FileNameA;
    localFilePath_ = nil;
}
- (void) setFilePathN:(NSString *)filePath
{
    if(!filePath||filePath==0)
    {
        FileName = nil;
        localFilePath_ = nil;
    }
    else
    {
        FileName = [[HCFileManager manager]getFileName:filePath];
        localFilePath_ = nil;
    }
}
- (void) setAudioPathN:(NSString *)audioPath
{
    if(!audioPath||audioPath==0)
    {
        AudioFileName = nil;
        localAudioPath_= nil;
    }
    else
    {
        AudioFileName = [[HCFileManager manager]getFileName:audioPath];
        localAudioPath_ = nil;
    }
}
- (NSString *)getFilePathN
{
    if(!localFilePath_)
    {
        localFilePath_ =  [[HCFileManager manager]getFilePath:FileName];
    }
    return localFilePath_;
}
- (NSString *)getAudioPathN
{
    if(!localAudioPath_)
        localAudioPath_ = [[HCFileManager manager]getFilePath:AudioFileName];
    return localAudioPath_;
}
@end

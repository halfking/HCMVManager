//
//  Samples.m
//  maiba
//
//  Created by SeenVoice on 15/8/25.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import "Samples.h"
#import <hccoren/base.h>
#import <hcbasesystem/user_wt.h>
//#import <hcbasesystem/updown.h>
@implementation Samples

@synthesize SampleID,UserID;
//@synthesize ObjectID,ObjectType;
@synthesize Video;
@synthesize Audio;
@synthesize Lyric;
@synthesize Title;
@synthesize UploadTime;
@synthesize Author;
@synthesize Cover;
@synthesize DataStatus;
@synthesize Mbsum;
@synthesize Video720;
@synthesize Video360;
@synthesize Hash360;
@synthesize Hash720;
@synthesize UserMTV;
@synthesize Adapter;
@synthesize Duration;
@synthesize Sort;
@synthesize ExpectCount;
@synthesize SingCount;
@synthesize isFromUser;
@synthesize summary;
@synthesize Tag;
@synthesize lyricText;
@synthesize modifyTime;
@synthesize nickName;
@synthesize headPortrait;

@synthesize FileName;
@synthesize IsFollowed,FansCount;
@synthesize IsLiked,LikeCount,IsExpected;
//@synthesize Url;
@synthesize IsLandscape;

@synthesize AudioAcc;
@synthesize AudioAccM4a;
@synthesize AudioCodec;
//@synthesize HasVideo;
-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"samples";
        self.KeyName = @"SampleID";
        self.UploadTime = [CommonUtil stringFromDate:[NSDate dateWithTimeIntervalSinceNow:-3600*24]]; // 默认一天前
    }
    return self;
}
- (id)initWithDictionary:(NSDictionary *)dic
{
    self = [super initWithDictionary:dic];
    if(self)
    {
        NSObject * itemData = nil;
        if ([dic objectForKey:@"item"]) {
            itemData = [dic objectForKey:@"item"];
        }
        else if ([dic objectForKey:@"Item"]) {
            itemData = [dic objectForKey:@"Item"];
        }
        if(itemData)
        {
            PP_RELEASE(UserMTV);
            
            if([itemData isKindOfClass:[NSDictionary class]])
            {
                UserMTV = [[MTV alloc]initWithDictionary:(NSDictionary*)itemData];
            }
            else if([itemData isKindOfClass:[NSString class]])
            {
                UserMTV = [[MTV alloc]initWithJSON:(NSString*)itemData];
            }
            else
                UserMTV = [[MTV alloc] init];
        }
        if ([dic objectForKey:@"Adapter"]) {
            Adapter = [dic objectForKey:@"Adapter"];
        }
        if([dic objectForKey:@"durance"])
        {
            
            CGFloat test = [[dic objectForKey:@"durance"]floatValue];
            self.Duration = test;
            //            Duration = test;
            //            Duration = [[dic objectForKey:@"durance"]floatValue];
        }
        else if([dic objectForKey:@"Durance"])
        {
            CGFloat test = [[dic objectForKey:@"Durance"]floatValue];
            self.Duration = test;
        }
        
        // 有可能只有ObjectID
        if ([dic objectForKey:@"ObjectID"])
        {
            int test = [[dic objectForKey:@"ObjectID"]intValue];
            self.SampleID = test;
        }
        else if ([dic objectForKey:@"objectid"])
        {
            int test = [[dic objectForKey:@"objectid"]intValue];
            self.SampleID = test;
        }
        //self.SampleID = self.ObjectID;
        
        if ([dic objectForKey:@"JoinCount"])
        {
            int test = [[dic objectForKey:@"JoinCount"]intValue];
            self.SingCount = test;
        }
        else if ([dic objectForKey:@"joincount"])
        {
            int test = [[dic objectForKey:@"joincount"]intValue];
            self.SingCount = test;
        }
        //补:因为数据结构变化，导致的可能有些值无法直接获取的问题
        if (![dic objectForKey:@"FileName"] && [dic objectForKey:@"FilePath"]) {
            [self setFilePathN:[dic objectForKey:@"FilePath"]];
        }
        else if (![dic objectForKey:@"filename"] && [dic objectForKey:@"filepath"]) {
            [self setFilePathN:[dic objectForKey:@"filepath"]];
        }
//        if (![dic objectForKey:@"AudioFileName"] && [dic objectForKey:@"AudioPath"]) {
//            [self setAudioPathN:[dic objectForKey:@"AudioPath"]];
//        }
//        else if (![dic objectForKey:@"audiofilename"] && [dic objectForKey:@"audiopath"]) {
//            [self setAudioPathN:[dic objectForKey:@"audiopath"]];
//        }
        
    }
    return self;
}

- (NSString *)getCoverPath
{
    //首先看本地文件是否存在
    NSString * path = [HCFileManager checkPath:self.Cover];
    return path;
//    if([path hasPrefix:@"file://"])
//    {
//        path = [path substringFromIndex:7];
//    }
//    return path;
}

- (NSString *)getMTVUrlString:(NetworkStatus)netStatus
{
    //首先看本地文件是否存在
    NSString * path = [self getFilePathN];
    if(path && path.length>0){
        
        //        path = @"/var/mobile/Containers/Data/Application/7D395D9F-A5A0-4D66-9498-1261B65F8893/Documents/recordfiles/20150713173604record.mov";
        NSFileManager * fm = [NSFileManager defaultManager];
        if(![fm fileExistsAtPath:path])
        {
            if([path hasPrefix:@"file://"])
            {
                path = [path substringFromIndex:7];
            }
            if(![fm fileExistsAtPath:path])
            {
                path = nil;
            }
        }
        NSLog(@"localfile : %@ orginal:%@",path==nil?@"nil":path,self.FileName);
    }
    
    if(!path || path.length==0)
    {
        HCUserSettings * settings = [[UserManager sharedUserManager]currentSettings];
        
        if(settings.imgModel == HCImgViewModelCustom || (settings.imgModel == HCImgViewModelAgent && netStatus==ReachableViaWWAN)){
            path = self.Video360 && self.Video360.length>0?self.Video360:self.Video720;
        }
        
        if(!path || path.length==0)
            path = self.Video720 && self.Video720.length>0?self.Video720:self.Video720;
        
        if(!path ||path.length==0)
        {
            path = self.Video;
        }
    }
    if(path && path.length>0)
        return path;
    else
        return nil;
    
}
- (MTV *)toMTV
{
    MTV * item = [MTV new];
    item.UserID = self.UserID;
    item.SampleID = self.SampleID;
    item.Title = self.Title;
    item.HeadPortrait = self.headPortrait;
    item.Author = self.Author;
    item.Author = self.nickName;
    item.Lyric = self.Lyric;
    item.CoverUrl = self.Cover;
    item.DownloadUrl = self.Video;
    item.DownloadUrl360 = self.Video360;
    item.DownloadUrl720 = self.Video720;
    [item setFilePathN:self.FileName];
//    [item setFilePathN:self.FilePath];
    item.FavCount = (int)self.Mbsum;
    item.Adapter = self.Adapter;
    item.Durance = self.Duration;
    item.PlayCount = (int)self.SingCount;
    
    item.AudioRemoteUrl = self.Audio;   //导唱
//    item.DownloadUrl360 = self.AudioAccM4a; //获取伴奏
    item.IsLike = self.IsLiked;
    item.LikeCount = self.LikeCount;
    item.IsFollowed = self.IsFollowed;
    item.FansCount = self.FansCount;
    item.IsLandscape = self.IsLandscape;
    if(![self hasVideo])
    {
        item.DownloadUrl = self.AudioAccM4a;
        item.OnlyAudio = YES;
    }
//    if(!item.Author || item.Author.length==0)
//    {
//        item.Author = @"韩洋";
//    }
    
    return PP_AUTORELEASE(item);
}
- (void)parseMTV:(MTV *)item
{
    if(!item)return ;
    
    
    self.UserID = item.UserID ;
    self.SampleID =item.SampleID ;
    self.Title = item.Title;
    self.headPortrait = item.HeadPortrait;
    //    item.Author = self.Author;
    self.nickName= item.Author;
    self.Lyric = item.Lyric;
    self.Cover = item.CoverUrl;
    self.Video = item.DownloadUrl;
    self.Video360 = item.DownloadUrl360;
    self.Video720 = item.DownloadUrl720;
    self.FileName = item.FileName;// [item getFilePathN];
    self.Mbsum = item.FavCount;
    self.Adapter = item.Adapter;
    self.Duration = item.Durance;
    self.SingCount = item.PlayCount;
    
    self.Audio = item.AudioRemoteUrl ;
    
    self.IsLiked = item.IsLike;
    self.LikeCount = item.LikeCount;
    self.IsFollowed = item.IsFollowed;
    self.FansCount = item.FansCount;
    self.IsLandscape = item.IsLandscape;
}
- (BOOL)hasVideo
{
    if(self.Video && self.Video.length>5)
        return YES;
    else if(self.Video720 && self.Video720.length>5)
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
-(void)dealloc{
    PP_RELEASE(Video);
    PP_RELEASE(Audio);
    PP_RELEASE(Lyric);
    PP_RELEASE(Title);
    PP_RELEASE(UploadTime);
    PP_RELEASE(Author);
    //    PP_RELEASE(Cover);
    PP_RELEASE(Video360);
    PP_RELEASE(Video720);
    PP_RELEASE(UserMTV);
    PP_RELEASE(Adapter);
    PP_RELEASE(Hash720);
    PP_RELEASE(Hash360);
    PP_RELEASE(AudioCodec);
    PP_RELEASE(AudioAccM4a);
    PP_RELEASE(FileName);
    PP_RELEASE(localFilePath_);
    
    PP_SUPERDEALLOC;
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
//- (void) setAudioPathN:(NSString *)audioPath
//{
//    if(!audioPath||audioPath==0)
//    {
//        AudioFileName = nil;
//    }
//    else
//    {
//        AudioFileName = [[UDManager sharedUDManager]getFileName:audioPath];
//    }
//}
- (NSString *)getFilePathN
{
    if(!localFilePath_)
    {
        localFilePath_ = [[HCFileManager manager]getFilePath:FileName];
    }
    return localFilePath_;
}
//- (NSString *)getAudioPathN
//{
//    return [[UDManager sharedUDManager]getFilePath:AudioFileName];
//}
- (void)setFileName:(NSString *)FileNameA
{
    FileName = FileNameA;
    localFilePath_ = nil;
}
@end

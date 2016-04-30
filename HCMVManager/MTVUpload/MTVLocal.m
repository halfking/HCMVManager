//
//  MTVLocal.m
//  maiba
//
//  Created by HUANGXUTAO on 15/10/28.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import "MTVLocal.h"

@implementation MTVLocal
@synthesize coverSize,lyricSize,videoSize,audioSize;
@synthesize coverPath,lyricPath,videoPath;
@synthesize infoPath;
- (void)dealloc
{
    PP_RELEASE(coverPath);
    PP_RELEASE(lyricPath);
    PP_RELEASE(videoPath);
    PP_RELEASE(infoPath);
    PP_SUPERDEALLOC;
}
- (BOOL)notUpload
{
    return !self.DownloadUrl || self.DownloadUrl.length<10;
}
- (instancetype) initWithMTV:(MTV*)item
{
//    if(self = [super init])
//    {
        if(self = [self initWithDictionary:[item toDicionary]])
        {
//        item.MTVID = self.MTVID;
//        item.SampleID = self.SampleID;
//        item.Title = self.Title;
//        item.Author = self.Author;
//        item.HeadPortrait = self.HeadPortrait;
//        item.Lyric = self.Lyric;
//        item.CoverUrl = self.CoverUrl;
//        item.DownloadUrl = self.DownloadUrl;
//        item.DownloadUrl360 = self.DownloadUrl360;
//        item.DownloadUrl720 = self.DownloadUrl720;
//        item.FilePath = self.FilePath;
//        
//        item.Adapter = self.Adapter;
//        item.Durance = self.Durance;
//        
//        
//        item.AudioRemoteUrl = self.AudioRemoteUrl;
//        item.AudioKey = self.AudioKey;
//        item.AudioPath = self.AudioPath;
//        item.FilePath = self.FilePath;
//        
//        item.IsLike = self.IsLike;
//        item.LikeCount = self.LikeCount;
//        item.FansCount = self.FansCount;
//        item.IsFollowed = self.IsFollowed;
//        
//        item.PlayCount = (int)self.PlayCount;
//        item.IsShare = self.IsShare;
//        item.ShareCount = self.ShareCount;
//        item.IsFav = self.IsFav;
//        item.FavCount = self.FavCount;
//        item.CommentCount = self.CommentCount;
//        
//        item.IsLandscape = self.IsLandscape;
//        item.UserID = self.UserID;
//        item.Memo = self.Memo;
//        
//        item.DateCreated = self.DateCreated;
//        item.ShareUrl = self.ShareUrl;
//        
//        item.Lat = self.Lat;
//        item.Lng = self.Lng;
//        item.Address = self.Address;
//        item.ShowAddress = self.ShowAddress;
//        
//        
//        item.MBMTVID = self.MBMTVID;
//        item.MName = self.MName;
//        item.IsRecommend = self.IsRecommend;
//        item.Sort = self.Sort;
//        item.UploadKey = self.UploadKey;
//        item.QiKey = self.QiKey;
//        item.Shares = self.Shares;
//        item.Key = self.Key;
//        item.DataStatus = self.DataStatus;
//        
//        item.AudioQiKey = self.AudioQiKey;
//        item.isCheckDownload = self.isCheckDownload;

    }
    return self;
}
@end

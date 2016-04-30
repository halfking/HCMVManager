//
//  MTV.h
//  Wutong
//  视频与音乐汇合后，形成一个MTV
//  Created by HUANGXUTAO on 15/3/25.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <hccoren/NSEntity.h>
#import <hccoren/Reachability.h>

#import "Music.h"


@interface MTV : HCEntity
{
    NSString * key_;
    NSString * localFilePath_;
    NSString * localAudioPath_;
}
@property (nonatomic,assign) long MTVID;
@property (nonatomic,PP_STRONG) NSString * Materials;
@property (nonatomic,PP_STRONG) NSString * ShareUrl;    //分享链接
@property (nonatomic,PP_STRONG) NSString * Title;       //标题
@property (nonatomic,PP_STRONG) NSString * Author;      //作者
@property (nonatomic,PP_STRONG) NSString * Category;    //分类
@property (nonatomic,assign) short MtvType; // 1.纯音乐 2. 3.短视频
@property (nonatomic,PP_STRONG) NSString * CoverUrl;    //封面地址
@property (nonatomic,assign) CGFloat Durance;           //MTV的时长
@property (nonatomic,PP_STRONG) NSString * MergeTime;  //混音时间
@property (nonatomic,PP_STRONG) NSString * UploadTime;  //上传时间
@property (nonatomic,PP_STRONG) NSString * Lyric;       //歌词
@property (nonatomic,PP_STRONG) NSString * DownloadUrl;     //远端服务器地址 原片
@property (nonatomic,PP_STRONG) NSString * DownloadUrl720;    //720P 的视频 切片后
@property (nonatomic,PP_STRONG) NSString * DownloadUrl360;    //360P 的视频 切片后
@property (nonatomic,PP_STRONG) NSString * DownloadUrl1080;    //1080P 的视频 切片后,这里，暂进用作没有视频的Sample的地址
@property (nonatomic,PP_STRONG) NSString * Hash720;             //720 md5
@property (nonatomic,PP_STRONG) NSString * Hash360;             //360 md5

@property (nonatomic,PP_STRONG) NSString * FileName;    //本地文件地址，空则本地尚未下载
@property (nonatomic,PP_STRONG) NSString * AudioFileName;   //自己唱的音乐文件

@property (nonatomic,PP_STRONG) NSString * AudioRemoteUrl;//远程的URL
@property (nonatomic,assign) BOOL OnlyAudio; //只有音频，即几个Download全是音频的信息
@property (nonatomic,assign) short IsLandscape;  //视频是否横屏

@property (nonatomic,assign) HCShareRights ShareRights; //是否公开: 0 私有,1 好友，2粉丝 3 全部
@property (nonatomic,PP_STRONG) NSString * Adapter;

//@property (nonatomic,assign) VIDEO_COMPLETEDPHARSE CompletedType; //完成阶段
@property (nonatomic,assign) NSInteger MusicID;                //对应的音乐，没有对应，则为空
@property (nonatomic,assign) long UserID;
@property (nonatomic,PP_STRONG) NSString * Memo;
@property (nonatomic,PP_STRONG) NSString * DateCreated;
@property (nonatomic,assign) double Lat;        //座标
@property (nonatomic,assign) double Lng;
@property (nonatomic,PP_STRONG) NSString * Address;//地址描述
@property (nonatomic,assign) NSInteger    ShowAddress;//是否显示地址，0不显示，1 好友，2粉丝 3 全部。
@property (nonatomic,assign) NSInteger DataStatus;

@property (nonatomic,PP_STRONG) NSString *MName;
@property (nonatomic,assign) NSInteger IsRecommend;
@property (nonatomic,assign) NSInteger Sort;

@property (nonatomic,PP_STRONG) NSString *Tag;
@property (nonatomic,PP_STRONG) NSString *Shares;
@property (nonatomic,PP_STRONG) NSString *QiKey;
@property (nonatomic,PP_STRONG) NSString *Key;//上传媒体的KEY
@property (nonatomic,PP_STRONG) NSString * AudioKey; //音频的Key，上传用
@property (nonatomic,PP_STRONG) NSString * AudioQiKey;//音频的上传QiniuKey
//@property (nonatomic,assign) NSInteger MBMTVID;
//@property (nonatomic,PP_STRONG) NSString * Key;
//当前用户的关系，喜欢等
@property (nonatomic,assign) BOOL IsLike; // 喜欢、点赞
@property (nonatomic,assign) BOOL IsFav; // 收藏
@property (nonatomic,assign) BOOL IsComment; // 评论
@property (nonatomic,assign) BOOL IsShare; // 分享
@property (nonatomic,assign) BOOL IsFollowed; // 关注
@property (nonatomic,assign) NSInteger  PlayCount; // 播放数
@property (nonatomic,assign) NSInteger LikeCount; // 喜欢、点赞数
@property (nonatomic,assign) NSInteger FavCount; // 收藏数
@property (nonatomic,assign) NSInteger CommentCount; // 评论数
@property (nonatomic,assign) NSInteger ShareCount; // 分享数
@property (nonatomic,assign) NSInteger FansCount; // 粉丝数


//mbmtv
@property (nonatomic,assign) long SampleID; //在Maiba里面的样本视频的ID
//@property (nonatomic,assign) NSInteger Mbsum; //用于表示Sample中唱过的数量
@property (nonatomic,assign) long MBMTVID;  //在麦爸里面用户视频的ID
@property (nonatomic,PP_STRONG) NSString * HeadPortrait; //头像
@property (nonatomic,PP_STRONG) NSString * UploadKey;  //常用于封面上传时生成的KEY

@property (nonatomic,assign) BOOL isCheckDownload;//用于判断是否已经检查了本地文件

- (NSString *)getKey;
- (void)setKey:(NSString *)key;
- (NSString *)getAudioKey;
- (void)setAudioKey:(NSString *)key1;

- (NSString *)getAudioUrlString;
- (NSString *)getMTVUrlString:(NetworkStatus )netStatus  userID:(NSInteger)userID remoteUrl:(NSString **)remoteUrl;
- (NSString*)getDownloadUrlOpeated:(NetworkStatus)netStatus userID:(NSInteger)userID;

- (NSString *)getCoverPath;

- (NSString *)locationAddress:(NSInteger)userID;

- (BOOL) hasAudio;
- (BOOL) hasVideo;
- (MTV *) copyItem;

- (void) setFilePathN:(NSString *)filePath;
- (void) setAudioPathN:(NSString *)audioPath;
- (NSString * )getFilePathN;
- (NSString * )getAudioPathN;
//"WorkCollections": {
    //        "MTVID": 1,
    //        "PlayCount": 0,
    //        "LikeCount": 0,
    //        "FavCount": 0,
    //        "ShareCount": 0
    //    },


@end

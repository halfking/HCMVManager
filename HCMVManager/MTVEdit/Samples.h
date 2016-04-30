//
//  Samples.h
//  maiba
//
//  Created by SeenVoice on 15/8/25.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import <hccoren/base.h>
#import <hccoren/Reachability.h>
#import "MTV.h"


@interface Samples : HCEntity
{
    NSString * localFilePath_;
}

//@property(assign, nonatomic) NSInteger ObjectID;
//@property(assign, nonatomic) NSInteger ObjectType;
@property(assign, nonatomic) long SampleID;
@property(assign, nonatomic) long UserID;
@property(PP_STRONG, nonatomic) NSString *nickName;
@property(PP_STRONG, nonatomic) NSString *headPortrait;
@property(PP_STRONG, nonatomic) NSString *Video;
@property(PP_STRONG, nonatomic) NSString *Video360;
@property(PP_STRONG, nonatomic) NSString *Video720;
@property (nonatomic,PP_STRONG) NSString * Hash720;             //720 md5
@property (nonatomic,PP_STRONG) NSString * Hash360;             //360 md5
@property (nonatomic,assign) BOOL IsLandscape;  //视频是否横屏

@property(PP_STRONG, nonatomic) NSString *AudioAcc;//音频伴奏
@property(PP_STRONG, nonatomic) NSString *AudioAccM4a;//音频伴奏 m4a
@property(PP_STRONG, nonatomic) NSString *AudioCodec;//源音频文件编码
@property(PP_STRONG, nonatomic) NSString *Audio;//导唱的音频地址
@property(PP_STRONG, nonatomic) NSString *Lyric;
@property(PP_STRONG, nonatomic) NSString *Title;
@property(PP_STRONG, nonatomic) NSString *UploadTime;
@property(PP_STRONG, nonatomic) NSString *modifyTime;
@property(PP_STRONG, nonatomic) NSString *lyricText;
@property(PP_STRONG, nonatomic) NSString *Author;
@property(PP_STRONG, nonatomic) NSString *Cover;
@property(PP_STRONG, nonatomic) NSString *summary;   //sample的描述

@property(assign, nonatomic) BOOL isFromUser;
@property(assign,nonatomic) NSInteger Sort;
@property(assign, nonatomic) short DataStatus;
@property(assign, nonatomic) long Mbsum;
@property(assign, nonatomic) long ExpectCount; // 想唱
@property(assign, nonatomic) long SingCount; // 在唱
@property(assign, nonatomic) NSInteger IsFollowed; //
@property(assign, nonatomic) NSInteger FansCount;

@property(PP_STRONG, nonatomic) NSString *FileName;
@property(nonatomic, PP_STRONG) MTV *UserMTV;
@property(nonatomic, PP_STRONG) NSString *Adapter;
@property(nonatomic,assign) CGFloat Duration;//Durance
@property(nonatomic, PP_STRONG) NSString *Tag;
//@property(nonatomic,PP_STRONG) NSString * Url;
@property(assign, nonatomic) NSInteger LikeCount;
@property(assign, nonatomic) BOOL IsExpected;
@property(assign, nonatomic) BOOL IsLiked;
//@property(assign, nonatomic) BOOL HasVideo;
- (NSString *) getMTVUrlString:(NetworkStatus )netStatus;
- (NSString *) getCoverPath;
- (MTV *) toMTV;
- (void) parseMTV:(MTV *)item;
- (BOOL) hasVideo;

- (void) setFilePathN:(NSString *)filePath;
//- (void) setAudioPathN:(NSString *)audioPath;
- (NSString * )getFilePathN;
//- (NSString * )getAudioPathN;
@end

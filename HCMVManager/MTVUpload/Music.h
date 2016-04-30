//
//  Music.h
//  Wutong
//
//  音乐，专指不乐曲。
//  Created by HUANGXUTAO on 15/3/25.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <hccoren/NSEntity.h>
#import <hcbasesystem/PublicEnum.h>

@interface Music : HCEntity
@property (nonatomic,assign) long MusicID;               //后台分配的ID？还是直接用GUID？MuiscID = UserID + TIME + SN
@property (nonatomic,PP_STRONG) NSString * DownloadUrl; //远端服务器地址
@property (nonatomic,PP_STRONG) NSString * FilePath;    //本地文件地址，空则本地尚未下载
@property (nonatomic,assign) CGFloat Durance;           //音乐的时长
@property (nonatomic,assign) int Rate;                  //音乐的码率，如320K
@property (nonatomic,assign) MUSIC_TYPE Type;           //音乐的类型
@property (nonatomic,assign) MUSIC_SOURCE Source;       //音乐来源
@property (nonatomic,assign) long UserID;                //歌曲是谁上传的,0表示是系统后台
@property (nonatomic,PP_STRONG) NSString * UploadTime;  //上传时间
@property (nonatomic,PP_STRONG) NSString * Title;       //标题
@property (nonatomic,PP_STRONG) NSString * Author;      //作者
@property (nonatomic,PP_STRONG) NSString * Category;    //分类
@property (nonatomic,PP_STRONG) NSString * Memo;        //说明
@property (nonatomic,PP_STRONG) NSString * Logo;
@property (nonatomic,PP_STRONG) NSString * Artist;
@property (nonatomic,PP_STRONG) NSString * Key;
@end

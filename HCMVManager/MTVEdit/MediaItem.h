//
//  MediaItem.h
//  maiba
//  视频媒体素材
//  Created by HUANGXUTAO on 15/8/18.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <hccoren/base.h>
#import <hcbasesystem/publicenum.h>
#import <CoreMedia/CMTime.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "mvconfig.h"

@interface MediaItemCore : HCEntity
{
    NSString * filePath_;
}
@property (nonatomic,PP_STRONG) NSString * key;
@property (nonatomic,assign,readonly,getter=get_isImg) BOOL isImg;//是图片还是视频
@property (nonatomic,readwrite) MediaItemInQueueType originType;
@property (nonatomic,PP_STRONG) NSString * fileName;
@property (nonatomic,PP_STRONG) NSString * title;
@property (nonatomic,PP_STRONG) NSURL * url;
@property (nonatomic,assign) int degree;//拍摄 方向
@property (nonatomic,PP_STRONG) NSString * cover;
@property (nonatomic,assign) CMTime duration; //整个媒体的长度，如果是图片，这里表示图片的播放时间，此长度与PlayRate无关
@property (nonatomic,assign) CMTime begin;//加入到队列中时，该视频的起点时间，如果为图片，这里为0
@property (nonatomic,assign) CMTime end;//加入到队列中时，该视频的结束时间，如果为图片，这里为播放时长
@property (nonatomic,assign) CMTime cutInTime;//前转场的时长
@property (nonatomic,assign) CMTime cutOutTime;//后转场的时长
//@property (nonatomic,assign) CGFloat cutInOutSeconds;//转场总时长
@property (nonatomic,assign) CutInOutMode cutInMode;//转场模式
@property (nonatomic,assign) CutInOutMode cutOutMode;//转场模式
@property (nonatomic,assign) CMTime timeInArray;//该媒体在最终合成视频中的起始时间
@property (nonatomic,assign) CGFloat playRate;//播放速度
@property (nonatomic,assign) CGSize renderSize;//播放大小
@property (nonatomic,assign) BOOL isOnlyAudio;//是否为音频文件

@property (nonatomic,assign,readonly) CGFloat secondsInArray;//与TimeInArray同值，只是这里用秒表示
@property (nonatomic,assign,readonly) CGFloat secondsBegin;//同begin
@property (nonatomic,assign,readonly) CGFloat secondsEnd;//同end
@property (nonatomic,assign,readonly) CGFloat secondsDurationInArray;//在队列中的长度
@property (nonatomic,assign,readonly) CGFloat secondsDuration;//同duration，本媒体整体长度

- (NSString *)filePath;
- (BOOL)isEqual:(MediaItemCore *)item;
@end

@interface MediaItem : MediaItemCore
//@property (nonatomic,assign) CGPoint point;//播放大小
@property (nonatomic,assign) CGRect rect;//播放大小

//@property (nonatomic,PP_STRONG) NSString * key;
//@property (nonatomic,assign) BOOL isImg;//是图片还是视频
//@property (nonatomic,PP_STRONG) NSString * filePath;
//@property (nonatomic,PP_STRONG) NSString * title;
//@property (nonatomic,PP_STRONG) NSURL * url;
//@property (nonatomic,PP_STRONG) NSString * cover;
//@property (nonatomic,assign) CMTime duration; //整个媒体的长度，如果是图片，这里表示图片的播放时间
//@property (nonatomic,assign) CMTime begin;//加入到队列中时，该视频的起点时间，如果为图片，这里为0
//@property (nonatomic,assign) CMTime end;//加入到队列中时，该视频的结束时间，如果为图片，这里为播放时长
//@property (nonatomic,assign) CMTime cutInTime;//前转场的时长
//@property (nonatomic,assign) CMTime cutOutTime;//后转场的时长
////@property (nonatomic,assign) CGFloat cutInOutSeconds;//转场总时长
//@property (nonatomic,assign) CutInOutMode cutInMode;//转场模式
//@property (nonatomic,assign) CutInOutMode cutOutMode;//转场模式
//@property (nonatomic,assign) CMTime timeInArray;//该媒体在最终合成视频中的起始时间
//@property (nonatomic,assign) CGFloat playRate;//播放速度
//@property (nonatomic,assign) CGSize renderSize;//播放大小
//
//@property (nonatomic,assign,readonly) CGFloat secondsInArray;//与TimeInArray同值，只是这里用秒表示
//@property (nonatomic,assign,readonly) CGFloat secondsBegin;//同begin
//@property (nonatomic,assign,readonly) CGFloat secondsEnd;//同end
//@property (nonatomic,assign,readonly) CGFloat secondsDurationInArray;//在队列中的长度
//@property (nonatomic,assign,readonly) CGFloat secondsDuration;//同duration，本媒体整体长度

#pragma mark - views;
@property (nonatomic,PP_STRONG) UIView * contentView;//在轨中的原始图
@property (nonatomic,PP_STRONG) UIView * snapView; //移动过程中的缩略图
@property (nonatomic,assign) CGRect lastFrame;              //移动之前的Frame
@property (nonatomic,assign) CGRect targetFrame;            //准备移动到的位置
@property (nonatomic,assign) CGFloat widthForCollapse;      //缩小状态下的宽度
@property (nonatomic,assign) CGPoint pointForRoot;          //基本根View的座标
@property (nonatomic,assign) int changeType;//0 值变化 1 新增 2删除
@property (nonatomic,assign) NSInteger tagID;
@property (nonatomic,PP_STRONG) NSMutableArray * videoThumnateFilePaths;
@property (nonatomic,assign) int videoThumnateFilesCount;
@property (nonatomic,assign) BOOL isGenerating; //是否正在生成缩略图
@property (nonatomic,assign) UIDeviceOrientation orientation;
#pragma mark - helper
@property (nonatomic,PP_STRONG) ALAsset * alAsset;

//generate
@property (nonatomic,readwrite) BOOL status;
@property (nonatomic,assign) UInt64 lastGenerateInterval;//上次生成的时间，如果超时需要重新生成
@property (nonatomic,assign) CGFloat generateProgress;

#pragma mark - some functions
- (MediaItemCore *)copyAsCore;
@end

//
//  MediaEditManager.h
//  maiba
//
//  Created by HUANGXUTAO on 15/8/18.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaItem.h"
#import "AudioItem.h"
#import "WTPlayerResource.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "Samples.h"
#import "VideoGenerater.h"
#import "MediaListModel.h"

#define SECONDS_TRANS    2
#define MEDIAITEMVIEW_MINTAGID 11000
//#define MEDIA_EXCHANGESECONDS 2
#define IMAGE_DURATION  6
#define IMAGE_TIMESCALE 600
//#define IMAGE_RENDERSIZE CGSizeMake(720,480)

#define TOTALSECONDS_DEFAULT    360
#define MINVIDEO_SECONDS 0.2 //一段视频的最短时间
#define COVER_SECONDS 0.5 //封面的时长
#ifndef CONTENTWIDTH_PERSECOND
#define CONTENTWIDTH_PERSECOND  12
#endif

typedef void (^CheckMedia)(MediaItem * mItem);
typedef void (^GenerateThumnates)(MediaItem * mItem,BOOL isSuccess);



@interface MediaEditManager : NSObject<WTPlayerResourceDelegate,VideoGeneraterDelegate>
{
    NSMutableArray * mediaList_;
    NSMutableArray * audioList_;
//    NSMutableArray * animatesArray_;
//    NSMutableArray * playItemList_;
    
    CGFloat playVolumeWhenRecord_; //录音时，伴奏的音量 0-1
    CGFloat singVolume_;     //人声音量0-1
    //view
    CGFloat contentWidth_;
    CGFloat contentWidhtPerSecond_;
    CGFloat itemTop_;
    CGFloat itemHeight_;
    CGFloat itemWidth_;
    
    //    NSMutableArray * mediaListCheckpoint_;
    //    NSMutableArray * audioListCheckpoint_;
    
    //可显示的视频的总长度
    CGFloat totalSecondsDuration_;
    //所有视频的总长度，含不可显示的
    CGFloat totalSecondsDurationByFullItems_;
    
//    SeenVideoQueue * generateQueue_;
    VideoGenerater * videoGenerater_;
    
    NSURL * audioMixUrl_;
    BOOL isGenerating_;//是否正在处理中
    
//    dispatch_queue_t    dispatch_JoinVideo_;
    
    MediaItem * coverMedialItem_;
    MTV * sampleMTV_;
    
    BOOL needRegenerate_;
    CGFloat orgBgVolume_;
    CGFloat orgSingVolumne_;
    AVPlayerItem * currentPlayerItem_;
    
    NSMutableDictionary *previewAudio_;
    
    
    BOOL isDraftSaving_;
    
 
    //合成局部
    CGFloat secondsBeginForMerge_;
    CGFloat secondsEndForMerge_;
    
    
    //关于视频方向及大小
    int deviceOrietation_;//视频方向
    BOOL useFontCamera_;
    NSArray * lyricList_;   //解析好的歌词列表
    CGFloat lyricBegin_;    //视频开始时，歌词对应的位置
    CGFloat lyricDuration_; //歌词总共显示多少时间
    NSString * waterMarkFile_;//水印图标
    CGFloat mergeRate_;     //合成Rate，可以加速合成
    
    
    BOOL needCreateBGVideo_; //是否需要创建背景视频
    
}
@property (nonatomic,PP_WEAK) id<VideoGeneraterDelegate> delegate;
@property (nonatomic,readonly,assign) BOOL  isFragment;//是否片断管理，还是全曲管理
@property (nonatomic,readonly,assign) CMTime  totalDuration;
@property (nonatomic,readonly,assign) CGSize  renderSize;

@property (nonatomic,readonly,PP_STRONG) MTV * Sample;
@property (nonatomic,readonly,PP_STRONG) Samples * CurrentSample; //用于传参用的，与上为同一数据，不同结构
//@property (nonatomic,PP_STRONG) MTV * UserMTV;                  //一般为当前传递用户的MTV的参数，不用于合成时

@property (nonatomic,PP_STRONG) NSString * accompanyDownKey;//伴奏的下载的Key
@property (nonatomic,PP_STRONG) NSString * userAudioDownKey;//用户唱的音频Key
@property (nonatomic,readonly,PP_STRONG) MediaItem * backgroundVideo;
@property (nonatomic,readonly,PP_STRONG) AudioItem * backgroundAudio;
@property (nonatomic,readonly,PP_STRONG) NSString * coverImageUrl;
@property (nonatomic,assign) BOOL NotAddCover;
@property (nonatomic,assign) CGFloat TempTotalSeconds; //当未设置背景视频时，并不知总长度是多少，会导致录音有问题。这里可以临时使用，默认60X60
@property (nonatomic,assign) CGFloat VolRampSeconds;    //声音渐入的时长,默认0.5秒
////保存主界面的当前状态
//@property (nonatomic, PP_STRONG) NSMutableArray *dataList;
//@property (nonatomic, PP_STRONG) NSMutableArray *myMTVList;
//@property (nonatomic, assign) int selectedRow;

//@property (nonatomic, PP_STRONG) MTV *justMergedMTV;

@property (nonatomic,assign) CGFloat prevCompletedSeconds; //上次唱到的位置，与草稿相关
@property (nonatomic,assign) int stepIndex;//上次操作到的位置，与草稿有关
@property (nonatomic,PP_STRONG) NSString * mergeFilePath;//合成的文件地址，与草稿有关
@property (nonatomic,PP_STRONG) MTV * mergeMTVItem;//mtv item megered,用于编辑页与合成页，编辑现存的MTV。
@property (nonatomic,assign,readonly) int DeviceOrietation; //录像时设置的旋转情况
@property (nonatomic,assign) long SampleID;
@property (nonatomic,assign) long MBMTVID;
@property (nonatomic,assign) long MTVID;
@property (nonatomic,PP_STRONG) NSString * MTVTitle;
@property (nonatomic,PP_STRONG) NSString * Tags; //当前的相关信息
@property (nonatomic,PP_STRONG) NSString * Memo; //当前描述
//@property (nonatomic,PP_STRONG) CALayer * WaterMarkLayer;

@property (nonatomic, PP_STRONG) NSObject * UserData;

+ (id)Instance;
+ (MediaEditManager *)shareObject;
+ (MediaEditManager *)secondObject; //第二个实例，用于合成片段，这样代码不用大动。
- (void)setIsFragment:(BOOL)pIsFragement;

- (void) setSampleInfo:(Samples *)sampleMTV;
- (void) removeSampleInfo:(MTV *)sampleMTV;

//- (void) setCacheDataBetweenWindows:(MTV *)currentMtv sample:(Samples *)currentSample;

//设置歌词，用于后期合成歌词
- (void) setLyricArray:(NSArray *)lyricList atTime:(CGFloat)begin duration:(CGFloat)duration watermarkFile:(NSString *)waterMarkFile;

- (AudioItem*)addVoiceItem:(AudioItem *)item;
- (AudioItem *)addVoiceItemByFile:(NSString *)filePath atTime:(CGFloat)seconds  delaySeconds:(CGFloat)delaySeconds;
- (AudioItem *)removeVoiceItemAtTime:(CGFloat)seconds;
- (AudioItem *)removeVoiceItem:(AudioItem *)item;
- (NSArray *)removeVoiceItemAtTime:(CGFloat)seconds duration:(CGFloat)duration;
- (NSInteger) getVoiceItemIndexBySeconds:(CGFloat)seconds;
- (NSArray *)audioList;
- (CGFloat) totalAudioDuration;
- (BOOL) hasRemoteUserAudioUrl;
- (BOOL) isAudioGuide:(NSString *)remoteAudioUrl;
//添加一个媒体，自动添加到第一个空白区域
//现在暂时确定媒体之前不能重叠
- (MediaItem *)addMediaItem:(MediaItem *)item indicatorPos:(CGFloat)posSeconds ;
- (MediaItem *)addMediaItemWithFile:(NSString *)filePath atIndex:(NSInteger)index indicatorPos:(CGFloat)posSeconds ;
- (MediaItem *)addMediaItemWithUrl:(NSURL *)url atIndex:(NSInteger)index indicatorPos:(CGFloat)posSeconds ;
- (MediaItem *)addMediaItemWithAlAsset:(ALAsset *)alAsset atIndex:(NSInteger)index indicatorPos:(CGFloat)posSeconds ;

- (MediaItem *)removeMediaItem:(MediaItem *)item;
- (MediaItem *)removeMediaItemByTagID:(NSInteger)tagID;
- (NSArray *)removeMediaItemsAtTime:(CMTime)time duration:(CGFloat)vduration;
//删除超过边界的对像
- (NSArray *)removeMediaItemsOverflow;
- (void)clearMediaList;
- (MediaItem *)getMediaItemAtTime:(CMTime)time;
- (NSArray *)getMediaItemsAtTime:(CMTime)time duration:(CGFloat)vduration;
- (BOOL)parseItemWithALLib:(ALAsset *)alasset mediaItem:(MediaItem *)item completed:(void(^)(void))completed;

//获取指定位置的空白区,用于准备放入媒体文件
- (CGFloat)getEmptyScope:(NSInteger )index itemDuration:(CGFloat)itemDuration duration:(CGFloat*)duration;
- (CGFloat)secondsWithPos:(CGFloat)xPos;
- (void)resortAudioes;
- (void)resort;
- (NSString *)getKeyOfItem:(MediaItem *)item;
- (NSString *)toJson;
- (void)parseJson:(NSString *)json;

- (void)clear;
- (void)clearFiles;
- (void)setBackgroundVideo:(NSURL *)video andAudio:(NSURL *)audio
                     cover:(NSString *)coverUrl coverImage:(UIImage *)image;
- (void)setCoverImageUrl:(NSString *)aCoverImageUrl;

- (void)setVideoOrietation:(UIDeviceOrientation)orientation renderSize:(CGSize)size withFontCamera:(BOOL)useFontCamera;
- (void)setMergeRate:(CGFloat)rate;

- (void)setPlayVolumeWhenRecording:(CGFloat)volume; //伴奏
- (void)setSingVolume:(CGFloat)volume;  //人声
- (CGFloat)getSingVolumn;
- (CGFloat)getPlayVolumn;
#pragma mark - data manage
- (void)checkPoint;
- (void)restoreLastCheckPoint;
- (NSArray *)getMediaItemsLastCheckPoint;
- (void)checkMedia:(MediaItem *)mItem thumnateSize:(CGSize)tSize completed:(CheckMedia)completed;
- (NSArray *) mediaList;
- (NSArray *) mediaChangedList; //与CheckPoint保存的值进行比较，判断发生变化的列表

- (void)checkLyricInfo:(NSArray*)lyricList begin:(CGFloat)lyricBegin duration:(CGFloat)lyricDuration;
#pragma mark - views
- (NSInteger) getMaxTagID;
- (CGRect) getItemFrame:(MediaItem *)mItem;
- (UIView*) getSnapViewByTagID:(NSInteger)tagID;
- (UIView *) getContentViewByTagID:(NSInteger)tagID;
- (MediaItem *) getMediaItemByTagID:(NSInteger)tagID;
- (MediaItem *) getNextMediaItem:(MediaItem *)item;
- (UIView *) buildMediaView:(MediaItem *)mItem;
- (CGFloat) contentViewWidth:(CGFloat)widthPerSecond contentWidth:(CGFloat)contentWidth;
- (void) setContentItemPosistion:(CGFloat)top height:(CGFloat)height;
//将Rect规整成为轨中的标准大小
- (CGRect) refrectRect:(CGRect)rect tagID:(NSInteger)tagID;
- (void) logLastFrame;
- (void) restorelastFrame;

//根据Frame重新设定对像的时间
- (void) syncSecondsByFrame;
//获取当前对像的前一个对像及前前一个对像。并可以只返回相交的对像
//- (MediaItem *)getPrevMediaItem:(MediaItem *)item interSect:(BOOL)interSect prevPrevItem:(MediaItem **)prevprevItem;
- (CGRect)getContentViewsNeedMoved:(CGRect)targetRect
                      excludeTagID:(NSInteger)tagID
                         direction:(BOOL)isLeft
                            isDone:(BOOL)isDone //是否最后放下时，在移动时有些事情不好处理
                        targetItem:(MediaItem **)currentItem
                      leftSectItem:(MediaItem **)leftSectitem
                     rightItemList:(NSMutableArray **)rightViewList;

#pragma mark - get video list for player
//获取完整的视频列表，即将背景视频也加入到队列中
//- (NSArray *)   getFullMediaList:(MediaItem *)bgVideo fillEmptyWithBgVideo:(BOOL)fill;
//- (NSArray *)   exportPlayItemArray:(MediaItem*)bgVideo fillWithTrans:(BOOL)fillTrans;
- (AVPlayerItem *)getPlayerItem;
- (NSURL *)     getAuMixed;
- (NSURL *)     getAudioUrl;
- (NSArray *)   exportAudioItemsArray;
//获取当前唱完的量，值可能为-1，0，或大于0的值。-1表示完整
- (CGFloat)     getSecondsSinged:(long)sampleID;

#pragma mark - generate
//- (BOOL)didItemGenerated:(PlayerMediaItem *)playerMediaItem;
//- (BOOL)didItemGenerated:(NSString*)key path:(NSString *)path url:(NSURL*)url;
//- (void)joinMedias;
- (void)    joinMedias:(int)retryCount;
- (void)    cancelExporter;
- (void)    regenerateItems;
- (void)    recheckGenerateQueue;
- (BOOL)    generateAudio:(CMTime)begin end:(CMTime)end completed:(audioGenerateCompleted)completed;
- (BOOL)    generateAudio:(audioGenerateCompleted)completed;
- (BOOL)    needRegenerate;
- (void)    setNeedRegenerate;

//- (void) requireAlassetRigths;
#pragma mark - To core array
- (MediaItem *) getMediaItem:(NSURL *)videoUrl;

- (BOOL)        checkAudioPath:(MTV *)mtv;

- (NSString * ) getTempFileName:(NSString *)filePath;

#pragma mark - preview
- (void)copyContent:(MediaEditManager *)orgManager;
//记录预览时生成的Audio文件
- (void)addPreviewAudioUrl:(NSURL *)url ForSampleID:(NSInteger)sampleID;
//删除预览时生成的Audio文件
- (void)deletePreviewAudioUrlForSampleID:(NSInteger)sampleID;
- (void)removeAudioItemAfterSecondsInArray:(float)second;
//即时合成，录一小段，马上合成
//从当前视频中截取一段，与音乐合成在一起。
- (BOOL)generateMVSegment:(CMTime)beginTime end:(CMTime) endTime
                   userID:(NSInteger)userID sampleID:(NSInteger)sampleID
                 progress:(MEProgress)progress
                    ready:(MEPlayerItemReady)itemReady
                completed:(MECompleted)complted
                  failure:(MEFailure)failure;
- (BOOL)generateMVSegment:(NSURL *)accompnayUrl audios:(NSArray*)audios
                    begin:(CMTime)beginTime end:(CMTime) endTime
                   userID:(NSInteger)userID sampleID:(NSInteger)sampleID
             accompnayVol:(CGFloat)accompanyVol singVol:(CGFloat)singVol
                 progress:(MEProgress)progress
                    ready:(MEPlayerItemReady)itemReady
                completed:(MECompleted)complted
                  failure:(MEFailure)failure;


- (void) copyUploadedMTV2Album:(NSString *)filePath mtvID:(long)mtvID item:(MTV*)mtvItem  showMsg:(NSString *)msg;
- (void) saveVideo2Album:(NSURL *)url handler:(ALAssetsLibraryWriteVideoCompletionBlock)completionBlock;
- (void) setTimeForMerge:(CGFloat)secondsBegin end:(CGFloat)secondsEnd;
- (void) copyMTVFromAlbum:(NSURL *)assetUrl withFilePath:(NSString *)filePath completed:(void(^)(BOOL finished,NSString * coverFile))completed;
- (void) copyPhotoFromAlbum:(NSURL *)assetUrl withFilePath:(NSString *)filePath completed:(void(^)(BOOL finished))completed;
- (void)copyMTVFromAlbum:(NSURL *)assetUrl extInfo:(NSString *)extInfo completed:(void(^)(BOOL finished,NSString * localFile,NSString * coverPath))completed
;
- (CGFloat)secondsBeginForMerge;
- (CGFloat)secondsEndForMerge;
//- (void)imageWithUrl:(NSURL *)url withFilePath:(NSString *)filePath completed:(void(^)(BOOL finished))completed;
//- (void)videoWithUrl:(NSURL *)url withFilePath:(NSString *)filePath completed:(void(^)(BOOL finished))completed;
//+ (OSStatus)mixAudio:(NSString *)audioPath1
//            andAudio:(NSString *)audioPath2
//              toFile:(NSString *)outputPath
//  preferedSampleRate:(float)sampleRate;
- (int) degressFromVideoFileWithTrack:(AVAssetTrack *)videoTrack;
- (UIDeviceOrientation) orientationFromVideo:(AVAssetTrack *)videoTrack;
- (BOOL)isBgVideoLandsccape;
- (BOOL)checkMTVItemOrientation:(MTV*)item;
- (short)isLandscapeBySize:(CGSize )avSize;
- (void)clearCurrentInfo;
- (void)clearAudioList;

- (NSString *) getCoverImageFileName;
- (NSString *) getCoverVideoFilePath;
- (NSArray *)  getFilterLyricItems;
//- (UIImage *)checkImageSizeAndSave:(UIImage *)image isCover:(BOOL)isCover path:(NSString *)filePath;
@end

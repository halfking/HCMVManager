//
//  ActionManager.h
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//#import "WTPlayerResource.h"
#import "VideoGenerater.h"
#import "GPUImage.h"
#import "CLVideoAddFilter.h"

#import "HCPlayerSimple.h"

#define SECONDS_NOTVALID 999999
#define SECONDS_NOEND 999998
#define SECONDS_ERRORRANGE  0.05
@class MediaAction;
@class MediaActionDo;
@class MediaItem;
@class MediaEditManager;
@class MediaWithAction;
@class ActionManager;
@protocol ActionManagerDelegate <NSObject>
@optional
- (void)ActionManager:(ActionManager *)manager actionChanged:(MediaActionDo *)action type:(int)opType;//0 add 1 update 2 remove
- (void)ActionManager:(ActionManager *)manager doProcessOK:(NSArray *)mediaList duration:(CGFloat)duration;
- (void)ActionManager:(ActionManager *)manager playerItem:(AVPlayerItem *)playerItem duration:(CGFloat)duration;
- (void)ActionManager:(ActionManager *)manager reverseGenerated:(MediaItem *)reverseVideo;
//- (void)ActionManager:(ActionManager *)manager mediaReady:(MediaItem *)baseMedia;
//当播放器的内容需要发生改变时，将当前要处理的内容传给播放器
- (void)ActionManager:(ActionManager *)manager play:(MediaWithAction *)mediaToPlay;

- (void)ActionManager:(ActionManager *)manager generateOK:(NSString *)filePath cover:(NSString *)cover isFilter:(BOOL)isFilter;
- (void)ActionManager:(ActionManager *)manager genreateFailure:(NSError *)error isFilter:(BOOL)isFilter;
- (void)ActionManager:(ActionManager *)manager generateProgress:(CGFloat)progress isFilter:(BOOL)isFilter;
- (void)ActionManager:(ActionManager *)manager generateReverseProgress:(CGFloat)progress;
//-(void) didGetThumbImage:(float)requestTime andPath:(NSString*)path index:(int)index size:(CGSize)size; //index = 0表示只截了当前一张 ，否则表示是一批图中的一张
//- (void) didGetThumbFailure:(float)requestTime error:(NSString*)error index:(int)index size:(CGSize)size;
//-(void) didAllThumbsGenerated:(NSArray*) thumbs;
//- (void) didGenerateFailure:(NSError *)error file:(NSString *)filePath;

@end
@interface ActionManager : NSObject<VideoGeneraterDelegate>
{
    MediaItem * audioBg_;    //音频背景
    MediaItem * reverseBG_;  //倒序的视频
    MediaItem * videoBg_;    //源视频
    MediaWithAction * videoBgAction_; //暂存的源视频Action
    
    MediaWithAction * currentMediaWithAction_; //当前执行的Action
//    NSTimer * mediaCheckTimer_;                 //用于检查当前对像是否已经执行完成
    
    CGFloat audioVol_;      //背景音乐音量
    CGFloat videoVol_;      //视频音乐音量
    
    NSMutableArray * actionList_;   //效果的列表
//    NSMutableArray * mediaListBG_;  //背景文件列表
    NSMutableArray * mediaList_;    //素材文件列表
    NSMutableArray * mediaListFilter_;//滤镜列表
    
    //每次播放一个循环，将会生成一个视频
    NSMutableArray * videoBGHistroy_;
    NSMutableArray * reverseBgHistory_;
    NSMutableArray * actionsHistory_;
    NSMutableArray * filterHistory_;
    
    CGFloat durationForSource_;         //源时长
    CGFloat durationForTarget_;         //最终目标时长
    CGFloat durationForAudio_;          //音频时长
    
    MediaEditManager * manager_;        //原有的编辑管理组件
    CGFloat secondsEffectPlayer_; //播放器时长的影响
    
    //内部关于播放器的控制
    HCPlayerSimple * player_;
    HCPlayerSimple * reversePlayer_;
    AVAudioPlayer * audioPlayer_;
    
    //关于滤镜
    GPUImageView *filterView_;
    GPUImageMovie *movieFile_;
    GPUImageOutput<GPUImageInput> *filters_;
//    NSMutableArray * gpuMoveFileList_; //用于延时释放
    GPUImageMovie *movieFileOrg_; //用于延时释放
    
    int lastFilterIndex_;//上次合成时使用的过滤器
    int currentFilterIndex_;//本次选择的过滤器序号
    
    BOOL isGeneratingByFilter_;//是否正在生成中
    BOOL isReverseGenerating_;  //完整的Reverse文件生成
    BOOL isReverseMediaGenerating_; //局部文件生成
    BOOL isGenerating_;             //是否正在生成过程中
    BOOL needSendPlayControl_;  //是否需要向前台发送播放信息，默认为YES
//    CGFloat lastPlayerSeconds_; //上次播放时间
    
    VideoGenerater * currentGenerate_;
    VideoGenerater * reverseMediaGenerate_;
    CLVideoAddFilter * currentFilterGen_;
    VideoGenerater * reverseGenerate_;
    
    
}
@property (nonatomic,PP_WEAK)NSObject<ActionManagerDelegate> * delegate;
@property (nonatomic,assign,readonly) CGFloat audioVolume;
@property (nonatomic,assign,readonly) CGFloat videoVolume;
@property (nonatomic,assign,readonly) BOOL isGenerating;
@property (nonatomic,assign) BOOL needPlayerItem;
@property (nonatomic,assign) BOOL canSendPlayerMedia; //是否可以向前端的播放器发送需要播放的对像。默认YES，在合成或一些未完成的操作时，需要关闭
//@property (nonatomic,strong) GPUImageMovie * moveFile;
//@property (nonatomic,strong) GPUImageMovie * moveFileOrg;
+ (ActionManager *)shareObject;
- (void) clear;  //清除数据及临时文件，最后一个文件不清除
- (void)clearPlayers;
#pragma mark - action list manager
- (BOOL) setBackMV:(NSString *)filePath begin:(CGFloat)beginSeconds end:(CGFloat)endSeconds  buildReverse:(BOOL)buildReverse;
- (BOOL) setBackMV:(MediaItem *)bgMedia buildReverse:(BOOL)buildReverse;
- (BOOL) setBackAudio:(NSString *)filePath begin:(CGFloat)beginSeconds end:(CGFloat)endSeconds;
- (BOOL) setBackAudio:(MediaItem *)audioItem;
- (MediaItem *) getBaseVideo;
- (MediaItem *) getReverseVideo;
- (MediaItem *) getBaseAudio;
- (int) getLastFilterID;
- (int) getCurrentFilterID;
- (BOOL) isReverseFile:(NSString *)fileName;
- (BOOL)generateReverseMV:(NSString*)filePath;
- (BOOL)generateReverseMV:(NSString*)filePath begin:(CGFloat)sourceBegin end:(CGFloat)sourceEnd;
- (void)pausePlayer;
- (void)resumePlayer;
// 是否能在指定位置增加一个动作
// action:当前动作，需要加入的
// seconds:当前播放器时间，有可能为反向播放器的时间
- (BOOL) canAddAction:(MediaAction *)action seconds:(CGFloat)playerSeconds;

//将播放器的时间转成素材轨的时间
//取最后的一个时间作为标准
//isrevers 标志当前这个时间是属于倒放的时间，如果是正放，则不需要标记
- (CGFloat) getSecondsInArrayFromPlayer:(CGFloat)playerSeconds isReversePlayer:(BOOL)isReversePlayer;

- (MediaWithAction *) getCurrentMediaWithAction;
- (void)setCurrentMediaWithAction:(MediaWithAction *)media;
//根据当前对像获取...
- (CGFloat) getSecondsInArrayViaCurrentState:(CGFloat)playerSeconds;

- (double) getMediaActionID;
- (MediaActionDo *) findMediaActionDoByType:(int)actionType;
//添加一个Action到队列中。如果基于源视频，则filePath直接传nil
//posSeconds 为队列中时间 与播放器的时间不一定一致，因为有些操作可能导致当前播放器多次播放同一内容。
//mediaBeginSeconds 为素材中的起始位置
- (MediaActionDo *) addActionItem:(MediaAction *)action filePath:(NSString *)filePath
                   at:(CGFloat)playerSeconds
                             from:(CGFloat)mediaBeginSeconds
             duration:(CGFloat)durationInSeconds;
- (MediaActionDo *) addActionItem:(MediaAction *)action filePath:(NSString *)filePath
                               inArray:(CGFloat)secondsInArray
                             from:(CGFloat)mediaBeginSeconds
                         duration:(CGFloat)durationInSeconds;
//重复添加对像
- (MediaActionDo *) addActionItemDo:(MediaActionDo *)actionDo
                                 at:(CGFloat)playerSeconds;
- (MediaActionDo *) addActionItemDo:(MediaActionDo *)actionDo
                                 inArray:(CGFloat)secondsInArray;
//当长按时，我们并不知道一个Action的时长，需要结束时再给我们
- (BOOL) setActionItemDuration:(MediaActionDo *)action duration:(CGFloat)durationInSeconds;
- (BOOL) ensureActions:(CGFloat)playerSeconds; //将未完成的Action完成，一般用于播放完成

//注意此时的Seconds与播放器的时间不一定一致，因为有些操作可能导致当前播放器多次播放同一内容。
- (MediaActionDo *)findActionAt:(CGFloat)secondsInArray
                          index:(int)index;

//注意此时的Seconds与播放器的时间不一定一致，因为有些操作可能导致当前播放器多次播放同一内容。
- (MediaWithAction *)findMediaItemAt:(CGFloat)secondsInArray;

- (MediaWithAction *)findMediaWithAction:(MediaActionDo*)action index:(int)index;
//注意此时的posSeconds与播放器的时间不一定一致，因为有些操作可能导致当前播放器多次播放同一内容。
- (BOOL) removeActionItem:(MediaAction *)action
                      at:(CGFloat)seccondsInArray;

- (BOOL) removeActionItem:(MediaActionDo *)actionDo;
- (BOOL) removeActions;

- (MediaActionDo *) getMediaActionDo:(MediaAction *)action;

#pragma mark - other functions
- (void)resetStates;
- (NSArray *) getActionList;
- (NSArray *) getMediaList;
//将MediaWithAction转成普通的MediaItem，其实只需要检查其对应的文件片段是否需要生成
- (BOOL) generateMediaListWithActions:(NSArray *)mediaWithActions complted:(void (^) (NSArray *))mediaList;
//在生成之前，将当前操作信息保存
- (BOOL) saveDraft;
//获取最初的文件信息，并且清空后期的操作
- (BOOL) loadOrigin;
//获取最后一次保存的草稿，并清空后期操作。
- (BOOL) loadLastDraft;
//获取第一次操作的草稿，即Origin之后的一次
- (BOOL) loadFirstDraft;
//保存的草稿的数量
- (int)  getHistoryCount;

//用最新的文件作为在初始版本，原初始版本作废
- (BOOL) resetOrigin;
- (BOOL) setLastDraftAsOrigin;

 //读取草稿的信息，不对当前队列进行任何操作
- (BOOL) getDraft:(int)index base:(MediaItem **)baseVideo reverse:(MediaItem **)reverseVideo actionList:(NSArray **)actionList filterID:(int *)filterID;

- (BOOL) needGenerateForOP; //因为动作而需要重新生成的
- (BOOL) needGenerateForFilter; //因为滤镜变化需要重新生成的
- (CGFloat) secondsEffectedByActionsForPlayer;
- (CGFloat) secondsEffectedByActionsForPlayerBeforeMedia:(MediaWithAction *)media;
- (CGFloat) secondsForTrack:(CGFloat)seconds;


- (void) setVol:(CGFloat)audioVol videoVol:(CGFloat)videoVol;

@end

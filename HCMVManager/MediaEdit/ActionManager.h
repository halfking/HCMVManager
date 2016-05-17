//
//  ActionManager.h
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WTPlayerResource.h"

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

//-(void) didGetThumbImage:(float)requestTime andPath:(NSString*)path index:(int)index size:(CGSize)size; //index = 0表示只截了当前一张 ，否则表示是一批图中的一张
//- (void) didGetThumbFailure:(float)requestTime error:(NSString*)error index:(int)index size:(CGSize)size;
//-(void) didAllThumbsGenerated:(NSArray*) thumbs;
//- (void) didGenerateFailure:(NSError *)error file:(NSString *)filePath;

@end
@interface ActionManager : NSObject
{
    MediaItem * audioBg_;    //音频背景
    MediaItem * videoBg_;    //源视频
    MediaWithAction * videoBgAction_; //暂存的源视频Action
    
    NSMutableArray * actionList_;   //效果的列表
//    NSMutableArray * mediaListBG_;  //背景文件列表
    NSMutableArray * mediaList_;    //素材文件列表
    NSMutableArray * mediaListFilter_;//滤镜列表
    
    CGFloat durationForSource_;         //源时长
    CGFloat durationForTarget_;         //最终目标时长
    CGFloat durationForAudio_;          //音频时长
    
    MediaEditManager * manager_;        //原有的编辑管理组件
}
@property (nonatomic,PP_WEAK)NSObject<WTPlayerResourceDelegate,ActionManagerDelegate> * delegate;
@property (nonatomic,assign) BOOL needPlayerItem;
+ (ActionManager *)shareObject;
- (void) clear;
#pragma mark - action list manager
- (BOOL) setBackMV:(NSString *)filePath begin:(CGFloat)beginSeconds end:(CGFloat)endSeconds;
- (BOOL) setBackAudio:(NSString *)filePath begin:(CGFloat)beginSeconds end:(CGFloat)endSeconds;

- (BOOL) canAddAction:(MediaAction *)action seconds:(CGFloat)seconds;

//将播放器的时间转成素材轨的时间
- (CGFloat) getSecondsWithoutAction:(CGFloat)playerSeconds;

//添加一个Action到队列中。如果基于源视频，则filePath直接传nil
- (MediaActionDo *) addActionItem:(MediaAction *)action filePath:(NSString *)filePath
                   at:(CGFloat)posSeconds
             duration:(CGFloat)durationInSeconds;

//当长按时，我们并不知道一个Action的时长，需要结束时再给我们
- (BOOL) setActionItemDuration:(MediaActionDo *)action duration:(CGFloat)durationInSeconds;

- (MediaActionDo *)findActionAt:(CGFloat)seconds
                          index:(int)index;
- (BOOL) removeActionItem:(MediaAction *)action
                      at:(CGFloat)posSeconds;

- (BOOL) removeActionItem:(MediaActionDo *)actionDo;
- (BOOL) removeActions;

- (MediaActionDo *) getMediaActionDo:(MediaAction *)action;

#pragma mark - other functions
- (NSArray *) getMediaList;
//将MediaWithAction转成普通的MediaItem，其实只需要检查其对应的文件片段是否需要生成
- (BOOL)generateMediaListWithActions:(NSArray *)mediaWithActions complted:(void (^) (NSArray *))mediaList;
@end

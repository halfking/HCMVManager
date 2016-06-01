//
//  MediaActionDo.h
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/12.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "MediaAction.h"
#import "MediaItem.h"

/* Action 具体操作实例，即Action 操作一次，一条数据*/
@interface MediaActionDo : MediaAction
{
    NSMutableArray * materialList_;
    CGFloat durationForFinal_; //在播放器中的时间
}
@property (nonatomic,assign) int Index;                 //在队列中的诹号
@property (nonatomic,assign) CGFloat SecondsInArray;    //效果的位置
@property (nonatomic,assign) CGFloat DurationInArray;   //效果持续时长
@property (nonatomic,PP_STRONG) MediaItemCore * Media;
@property (nonatomic,PP_STRONG,readonly,getter=get_MaterialList) NSMutableArray * MaterialList;
@property (nonatomic,PP_STRONG) MediaWithAction * mediaToPlay;
- (void)fetchAsAction:(MediaAction *)action;
- (MediaActionDo *)copyItemDo;

- (NSMutableArray *)processAction:(NSMutableArray *)sources secondsEffected:(CGFloat)secondsEffected;
- (NSMutableArray *)ensureAction:(NSMutableArray *)sources durationInArray:(CGFloat)durationInArray;
- (void) ensureMediaDuration:(CGFloat)durationInArrayA;

- (NSMutableArray *)splitArrayForAction:(NSArray *)sources insertIndex:(int *)insertIndex;
- (MediaWithAction *)splitMediaItem:(MediaWithAction *)item splitSecondsInArray:(CGFloat)splitSecondsInArray;
- (void)addMediaToArray:(NSArray*)items sources:(NSMutableArray *)sources insertIndex:(int)insertIndex;
- (NSMutableArray *)getMateriasInterrect:(CGFloat)seconds duration:(CGFloat)duration sources:(NSArray *)sources;
- (NSMutableArray *)buildMaterialProcess:(NSArray *)sources;
//- (NSMutableArray *)buildMaterialOverlaped:(NSArray *)sources;
- (void)ensureExistItemDuration:(int)beginIndex sources:(NSMutableArray *)sources;

- (CGFloat) getDurationInFinal:(NSArray *)sources;
- (CGFloat) getDurationInPlaying:(MediaWithAction *)media;
- (CGFloat) getDurationInFinalArray:(MediaWithAction *)media;

- (CGFloat) getSecondsInArray:(CGFloat)playerSeconds;
- (BOOL) containSecondsInArray:(CGFloat)secondsInArray;

- (CGFloat) getFinalDurationForMedia:(MediaWithAction *)media;
- (MediaWithAction *)toMediaWithAction:(NSArray *)sources;
//- (MediaWithAction *)splitMediaItemAtSeconds:(NSArray *)overlaps
//                                   atSeconds:(CGFloat)seconds
//                                        from:(CGFloat)mediaBeginSeconds
//                                    duration:(CGFloat)duration
//                                     overlap:(BOOL)isOverlap;

//因为我们处理的采样时间来自于播放器，因此，Rap，Reverse这种类型会影响播放器的时刻对应在合成视频上的位置变化
// 如Reverse 1秒后，播放器位置在4秒，这时，在合成视频上的位置应该是4+2 = 6秒 timeinarray
- (CGFloat) secondsEffectPlayer;
- (CGFloat) secondsEffectPlayer:(CGFloat)durationInArray;
@end


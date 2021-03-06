//
//  MediaWithAction.h
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/12.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "MediaItem.h"
#import "MediaAction.h"
/*用于输出到Player或者合成的素材元素，用一个队列构成一个视频。*/
//生成中，所有的过程和时间都基于Rate=1的源，而不是真实播放或处理的时长。
//真实时长通过finalDuration来完成
//如果片断是合成过的，那么Rate就应该均为1，如果是源视频，有可能不会1
@interface MediaWithAction : MediaItemCore
@property (nonatomic,PP_STRONG) MediaAction * Action;
@property (nonatomic,assign)CGFloat durationInPlaying;//实际播放的时间，与Rate相关,可以用视频来计算实际播放时长
@property (nonatomic,assign) BOOL secondsInArrayNotConfirm;//在队列中的位置还没有确定，不参与相关的处理
@property (nonatomic,assign) CGFloat secondsChangedWithActionForPlayer;//在此之前，有多少播放器的时长变化
@property (nonatomic,assign) CGFloat secondsBeginBeforeReverse;     //生成反向文件前的开始时间
@property (nonatomic,assign) CGFloat secondsEndBeforeReverse;       //生成反向文件前的结束时间
@property (nonatomic,assign) CGFloat rateBeforeReverse;             //速度
@property (nonatomic,assign) int isReversed;                       //是否已经生成了反向文件，生成反向文件后，文件中的开始与结束时间均会发生变化,0未生成，1生成 <0失败，具体值为失败次数
//@property (nonatomic,assign) CGFloat durationInFinalArray;//在队列中占用的时长，Rate=1
//@property (nonatomic,assign) CGFloat secondsInFinalArray;//基于Rate=1时的在队列中的位置时间。

- (MediaWithAction *)copyItem;
- (NSString *) toString;
- (BOOL)isSampleAsset:(MediaItemCore *)item;
- (CGFloat) getSecondsInArrayByPlaySeconds:(CGFloat)playerSeconds;
@end
//
//  ActionManager(player).h
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/23.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ActionManager.h"
#import "GPUImage.h"
#import "HCPlayerSimple.h"

#import "CLVideoAddFilter.h"

@interface ActionManager(player)<CLVideoAddFilterDelegate,GPUImageMovieDelegate>

- (HCPlayerSimple *) getPlayer;
//- (HCPlayerSimple *) getReversePlayer;
- (GPUImageView *) getFilterView;
- (NSArray *) getGPUFilters;
- (UIImage*) getFilteredIcon:(UIImage *)image index:(int)index;
- (BOOL) changeFilterPlayerItem;

- (void) setFilterIndex:(int)filterIndex;
- (int) getCurrentFilterIndex;
- (BOOL) initPlayer:(HCPlayerSimple *)player audioPlayer:(AVAudioPlayer *)audioPlayer;
//- (BOOL) initReversePlayer:(HCPlayerSimple *)reversePlayer;

- (BOOL) initAudioPlayer:(AVAudioPlayer *)audioPlayer;
//注意，此函数一个VC只能初始化一次
- (BOOL) initGPUFilter:(HCPlayerSimple *)player  in:(UIView *)contaner;
- (GPUImageView *) buildFilterView:(AVAssetTrack *) videoAssetTrack playerFrame:(CGRect)playerFrame;
- (BOOL) setGPUFilter:(int)index;

- (BOOL) generateMVByFilter:(int)filterIndex;
- (void) removeGPUFilter;

//将播放器的时间发送给管理器，用于自动切换素材
- (void) setPlaySeconds:(CGFloat)seconds isReverse:(BOOL)isReverse;
//根据素材，自动同步背景音乐
- (void)syncAudioPlayer:(MediaWithAction *)media playerSeconds:(CGFloat)playerSeconds;

#pragma mark - player control
- (void)ActionManager:(ActionManager *)manager play:(MediaActionDo *)action media:(MediaWithAction *)media seconds:(CGFloat)seconds;
- (void)ActionManager:(ActionManager *)manager actionChanged:(MediaActionDo *)action type:(int)opType;//0 add 1 update 2 remove;
- (void)ActionManager:(ActionManager *)manager doProcessOK:(NSArray *)mediaList duration:(CGFloat)duration;
- (void)ActionManager:(ActionManager *)manager playerItem:(AVPlayerItem *)playerItem duration:(CGFloat)duration;
@end

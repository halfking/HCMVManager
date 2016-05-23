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

@interface ActionManager(player)<CLVideoAddFilterDelegate>
- (HCPlayerSimple *) getPlayer;
- (HCPlayerSimple *) getReversePlayer;
- (GPUImageView *) getFilterView;
- (NSArray *) getGPUFilters;
- (UIImage*) getFilteredIcon:(UIImage *)image index:(int)index;
- (int) getCurrentFilterIndex;
- (BOOL) initPlayer:(HCPlayerSimple *)player reversePlayer:(HCPlayerSimple *)reversePlayer;
- (BOOL) initGPUFilter:(HCPlayerSimple *)player  in:(UIView *)contaner;
- (BOOL) setGPUFilter:(int)index;

- (BOOL) generateMVByFilter:(int)filterIndex;

#pragma mark - player control
- (void)ActionManager:(ActionManager *)manager play:(MediaActionDo *)action;
- (void)ActionManager:(ActionManager *)manager actionChanged:(MediaActionDo *)action type:(int)opType;//0 add 1 update 2 remove;
- (void)ActionManager:(ActionManager *)manager doProcessOK:(NSArray *)mediaList duration:(CGFloat)duration;
- (void)ActionManager:(ActionManager *)manager playerItem:(AVPlayerItem *)playerItem duration:(CGFloat)duration;
@end

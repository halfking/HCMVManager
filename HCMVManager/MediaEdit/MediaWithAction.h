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
@property (nonatomic,assign) CGFloat finalDuration;
- (void)fetchAsCore:(MediaItemCore *)item;
- (MediaWithAction *)copyItem;
- (NSString *) toString;
@end
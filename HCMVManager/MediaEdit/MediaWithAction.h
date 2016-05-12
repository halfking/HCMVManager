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
@interface MediaWithAction : MediaItemCore
@property (nonatomic,PP_STRONG) MediaAction * Action;
@property (nonatomic,assign) CGFloat finalDuration;
- (void)fetchAsCore:(MediaItemCore *)item;
- (MediaWithAction *)copyItem;
@end
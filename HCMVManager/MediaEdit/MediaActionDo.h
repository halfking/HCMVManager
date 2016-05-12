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
    CGFloat durationForFinal_;
}
@property (nonatomic,assign) int Index;                 //在队列中的诹号
@property (nonatomic,assign) CGFloat SecondsInArray;    //效果的位置
@property (nonatomic,assign) CGFloat DurationInArray;   //效果持续时长
@property (nonatomic,PP_STRONG) MediaItemCore * Media;
@property (nonatomic,PP_STRONG,readonly,getter=get_MaterialList) NSMutableArray * MaterialList;

- (void)fetchAsAction:(MediaAction *)action;
- (NSMutableArray *)getMateriasInterrect:(CGFloat)seconds duration:(CGFloat)duration sources:(NSArray *)sources;
- (NSMutableArray *)buildMaterialProcess:(NSArray *)sources;
- (NSMutableArray *)buildMaterialOverlaped:(NSArray *)sources;
- (CGFloat) getDurationInFinal:(NSArray *)sources;
- (CGFloat) getDurationFinal:(MediaWithAction *)media;
- (MediaWithAction *)toMediaWithAction:(NSArray *)sources;
@end


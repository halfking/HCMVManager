//
//  MediaAction.h
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//  混剪效果动作

#import <hccoren/base.h>
#import "MediaItem.h"

@class MediaWithAction;

/* Action 模板，即Action的抽像操作模式 */
@interface MediaAction : HCEntity
@property (nonatomic,assign) int    MediaActionID;
@property (nonatomic,PP_STRONG) NSString * ActionTitle;
@property (nonatomic,PP_STRONG) NSString * ActionIcon;
@property (nonatomic,assign) int ActionType;//暂定4个，1 表示慢速 2 表示加速 3表示Rap 4表示倒放 0表示无特效 99999表示是一个模板类型的，
@property (nonatomic,PP_STRONG) NSString * SubActions;
@property (nonatomic,assign)    CGFloat Rate;           //对播放速度的影响
@property (nonatomic,assign)    CGFloat ReverseSeconds;  //从当前播放位置的何处开始。如-1，表示从当前位置前一秒开始生效
@property (nonatomic,assign)    CGFloat DurationInSeconds;  //效果延续时间，-1表示不限，此值与Rate无关
@property (nonatomic,assign)    BOOL IsMutex;       //是否互斥，不能与其它Action重叠
@property (nonatomic,assign)    BOOL IsFilter;      //是否滤镜
@property (nonatomic,assign)    BOOL IsOverlap;     //对于源视频是否进行覆盖
@property (nonatomic,assign)    BOOL isOPCompleted; //是否操作完成？当Action长按操作时，有可能操作没有完成，需要另外的函数来处理完成
//@property (nonatomic,assign)

- (NSArray *) getSubActionList;
- (MediaAction *)copyItem;
@end

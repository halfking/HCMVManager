//
//  ActionManager(index).h
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ActionManager.h"
#import "mvconfig.h"
@interface ActionManager(index)
#pragma mark - overlap manager
- (CGFloat) reindexAllActions;

//从队列中检查，合并同样的被拆分的段
- (NSMutableArray *) combinateArrayItems:(NSMutableArray *)source;

- (CGFloat) processNewActions;
#pragma mark - export
- (BOOL) generateMV;
- (BOOL) generateMVWithWaterMarker:(NSString *)waterMarker position:(WaterMarkerPosition)position;
//从原文件中切一部分内容生成新文件
- (BOOL)generateMediaFileViaAction:(MediaActionDo *)action;
- (BOOL)generateMediaFile:(MediaWithAction *)media;
//- (BOOL)generateReverseMV:(NSString*)filePath;
//- (BOOL)generateReverseMV:(NSString*)filePath begin:(CGFloat)sourceBegin end:(CGFloat)sourceEnd;


- (void) generatePlayerItem:(NSArray *)mediaList;
- (void) cancelGenerate;
//- (BOOL) generateThumnates:(CGSize)thumnateSize contentSize:(CGSize)contentSize;


@end

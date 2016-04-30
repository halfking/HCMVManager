//
//  MediaItem2Video.h
//  maiba
//
//  Created by HUANGXUTAO on 16/4/11.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#define VIDEO_CTTIMESCALE   600 //apple recommed
#define AUDIO_CTTIMESCALE    44100
//typedef void(^SuccessBlock)(BOOL success,CGFloat progress);
typedef void (^mvGenerateCompleted)(NSString * filePath,NSError *error);
typedef void (^audioGenerateCompleted)(NSURL *audioUrl, NSError *error);

@class MediaItem;

@interface MediaListModel : NSObject
+ (MediaListModel *)shareObject;

- (NSMutableArray *)checkMediaTimeLine:(CMTime)beginTime  //开始时间，基于背景视频
                            endTime:(CMTime)endTime       //结束时间
                         resetBegin:(BOOL)resetBegin;     //需要校准时，是否可以移动片段的开始时间。

- (BOOL) checkTempAVStatus;//那些需要转换的视频是否已经操作完成
- (NSArray*) getMediaList;
- (NSString *) generateImage2Video:(MediaItem *)item;

- (void) addMediaItem:(MediaItem *)item atIndex:(NSInteger)index;
- (void) removeMediaItem:(MediaItem *)item;

- (NSString *) getVideoPath:(MediaItem *)item;
- (NSString *) getNewVideoFileName:(MediaItem *)item;
- (NSString *) getItemKey:(MediaItem *)item;
- (void) clearFiles;
- (void) clear;

-(BOOL)generateMVByCover:(NSString *)imagePath
              targetPath:(NSString *)targetPath
                duration:(CGFloat)seconds
                     fps:(int)fps
                    size:(CGSize)size
             orientation:(UIDeviceOrientation)orientation
                progress:(mvGenerateCompleted)callbackBlock;

- (CGSize) getSizeByOrientation:(CGSize)size orientation:(UIDeviceOrientation)orientation;
@end

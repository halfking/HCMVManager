//
//  WTPlayerResource.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/6/18.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#include <AudioToolbox/AudioToolbox.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <hccoren/base.h>
@class WTPlayerResource;
@protocol WTPlayerResourceDelegate <NSObject>
@optional
- (void)WTPlayerResource:(WTPlayerResource *)player didMute:(BOOL)isMute;
-(void) didGetThumbImage:(float)requestTime andPath:(NSString*)path index:(int)index size:(CGSize)size; //index = 0表示只截了当前一张 ，否则表示是一批图中的一张
- (void) didGetThumbFailure:(float)requestTime error:(NSString*)error index:(int)index size:(CGSize)size;
-(void) didAllThumbsGenerated:(NSArray*) thumbs;
- (void) didGenerateFailure:(NSError *)error file:(NSString *)filePath;
@end

typedef void (^generateCompleted)(CMTime requestTime,NSString* path,UIImage * image);
typedef void (^getAlbumImage)(UIImage * image);
typedef void (^generateCompletedNew)(CMTime requestTime,NSString* path,NSInteger index);
typedef void (^generateFailure)(CMTime requestTime,NSError *error,NSString *filePath);
@interface WTPlayerResource : NSObject
{
@private
    float       soundDuration;
    NSTimer *   playbackTimer;
}
@property (nonatomic,PP_WEAK)   id<WTPlayerResourceDelegate> delegate;
+ (WTPlayerResource *) sharedWTPlayerResource;

//获取相册最后一张图片
//usage:
//__weak typeof(self) weakSelf = self;
//self updateLibraryButtonWithCameraMode:XHCameraModeVideo didFinishcompledBlock:^(UIImage *thumbnail) {
//  [weakSelf.videoLibraryButton setBackgroundImage:thumbnail forState:UIControlStateNormal];
//}];

- (void)updateLibraryButtonWithCameraMode:(int)cameraMode didFinishcompledBlock:(void (^)(UIImage *thumbnail))compled;

- (void)    resetThumnates;
- (NSString *)getObjectKey:(NSURL*)url index:(int)index;

- (CMTime)getDuration:(NSURL *)url;
- (CMTime)getDuration:(NSURL *)url prevSecond:(CGFloat)prevSecond index:(int)index durations:(NSMutableDictionary **)dictionaries;

- (CMTime)getDurations:(NSArray *)urls durations:(NSMutableDictionary **) dictionaries;
- (NSMutableDictionary *) getThumbTimes:(NSArray *)urls begin:(float) start andEnd:(float) end andStep:(float)step;

- (void)    getVideoThumbs:(NSArray *)urls begin:(CGFloat)start andEnd:(CGFloat)end step:(CGFloat)step count:(int)count  andSize:(CGSize)size delegate:(id<WTPlayerResourceDelegate>)delegate;
- (void)getVideoThumb:(NSArray *)urls time:(CMTime) time andSize:(CGSize)size delegate:(id<WTPlayerResourceDelegate>)delegate;

- (void)getVideoThumbN:(NSArray *)urls time:(CMTime) time andSize:(CGSize)size orientation:(int)orientation delegate:(id<WTPlayerResourceDelegate>)delegate;

- (BOOL) getVideoThumbOne:(NSArray *)urls andSize:(CGSize)size callback:(generateCompleted)completed;
- (BOOL) getVideoThumbOne:(NSURL *)url atTime:(CMTime)time andSize:(CGSize)size callback:(generateCompleted)completed;

//获取一个视频的截图
//targetThumnateFileName 目标文件的名字，不含路径
- (BOOL) getVideoThumbs:(NSURL *)url
                alAsset:(ALAsset *)alAsset
 targetThumnateFileName:(NSString *)fileName
                  begin:(float) start
                 andEnd:(float) end
                andStep:(float)step
               andCount:(int)count
                andSize:(CGSize)size
               callback:(generateCompletedNew)onegenerated
              completed:(generateCompletedNew)completed
                failure:(generateFailure)failure;

- (void)generateImages:(AVAsset*)asset times:(NSArray *)thumbnailTimes prevTotal:(CGFloat)prevTotal
                  path:(NSString *)fileName size:(CGSize)size
              callback:(generateCompletedNew)onegenerated
               failure:(generateFailure)failure;
#pragma mark - dirs
-(NSString *)getThumnatePath:(NSString *)filename minsecond:(int)minsecond size:(CGSize)size;
- (BOOL) removeThumnates:(NSString *)orgFileName size:(CGSize) size;
//- (BOOL) removeTempVideos;
@end

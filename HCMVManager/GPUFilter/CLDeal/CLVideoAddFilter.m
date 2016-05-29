//
//  CLVideoAddFilter.m
//  tiaooo
//
//  Created by ClaudeLi on 15/12/25.
//  Copyright © 2015年 dali. All rights reserved.
//

#import "CLVideoAddFilter.h"
#import <GPUImage.h>
#import "CLFiltersClass.h"

@interface CLVideoAddFilter ()
{
    GPUImageOutput<GPUImageInput> *filterCurrent;
    NSTimer *_timerEffect;    
}

@property (retain, nonatomic) GPUImageMovie *movieFile;
@property (retain, nonatomic) GPUImageOutput<GPUImageInput> *filter;
@property (retain, nonatomic) GPUImageMovieWriter *movieWriter;

@end

@implementation CLVideoAddFilter

- (instancetype)init
{
    self = [super init];
    if (self) {
        _timerEffect = nil;
    }
    return self;
}

- (void)addVideoFilter:(NSURL *)videoUrl tempVideoPath:(NSString *)tempVideoPath index:(NSInteger)index
{
    AVURLAsset* asset = [AVURLAsset assetWithURL:videoUrl];
    AVAssetTrack *asetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    NSURL *tempVideo = [NSURL fileURLWithPath:tempVideoPath];
    //1. 传入视频文件
    _movieFile = [[GPUImageMovie alloc] initWithURL:videoUrl];
    
    //2. 添加滤镜
    [self initializeVideo:videoUrl index:index];
    
    CGSize videoSize = CGSizeMake(asetTrack.naturalSize.width, asetTrack.naturalSize.height);
    
    // 自定义视频参数
//    NSDictionary* settings = @{AVVideoCodecKey : AVVideoCodecH264,
//                               AVVideoWidthKey : @(videoSize.width),
//                               AVVideoHeightKey : @(videoSize.height),
//                               AVVideoCompressionPropertiesKey: @ {
//                                   AVVideoAverageBitRateKey : @(1500000),
//                                   AVVideoProfileLevelKey : AVVideoProfileLevelH264Baseline31,
//                               },
//                               AVVideoScalingModeKey : AVVideoScalingModeResizeAspect};
//    _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:tempVideo size:videoSize fileType:AVFileTypeQuickTimeMovie outputSettings:settings];
    // 3.
    _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:tempVideo size:videoSize];
    if ((NSNull*)_filter != [NSNull null] && _filter != nil)
    {
        [_filter addTarget:_movieWriter];
    }
    else
    {
        [_movieFile addTarget:_movieWriter];
    }
    _movieWriter.transform = asetTrack.preferredTransform;
    
    // 4. Configure this for video from the movie file, where we want to preserve all video frames and audio samples
    _movieWriter.shouldPassthroughAudio = YES;
    _movieFile.audioEncodingTarget = _movieWriter;
    [_movieFile enableSynchronizedEncodingUsingMovieWriter:_movieWriter];
    
    // 5.
    [_movieWriter startRecording];
    [_movieFile startProcessing];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Progress monitor for effect
        _timerEffect = [NSTimer scheduledTimerWithTimeInterval:0.3f
                                                        target:self
                                                      selector:@selector(filterRetrievingProgress)
                                                      userInfo:nil
                                                       repeats:YES];
    });
    
    __unsafe_unretained typeof(self) weakSelf = self;
    // 7. Filter effect finished
    [weakSelf.movieWriter setCompletionBlock:^{
        
        if ((NSNull*)_filter != [NSNull null] && _filter != nil)
        {
            [_filter removeTarget:weakSelf.movieWriter];
        }
        else
        {
            [_movieFile removeTarget:weakSelf.movieWriter];
        }
        
        [_movieWriter finishRecordingWithCompletionHandler:^{
            // 完成后处理进度计时器 关闭、清空
            [_timerEffect invalidate];
            _timerEffect = nil;

            dispatch_async(dispatch_get_main_queue(), ^{
                _movieWriter = nil;
                if ([self.delegate respondsToSelector:@selector(didFinishVideoDeal:)]) {
                    [self.delegate didFinishVideoDeal:tempVideo];
                }
                
            });
        }];
        
    }];
}


- (void) initializeVideo:(NSURL*) inputMovieURL index:(NSInteger)index
{
    // 1.
    _movieFile = [[GPUImageMovie alloc] initWithURL:inputMovieURL];
    _movieFile.runBenchmark = NO;
    _movieFile.playAtActualSpeed = NO;
    
    // 2. Add filter effect
    _filter = nil;
    _filter = [CLFiltersClass addVideoFilter:_movieFile index:index];
}

/* 滤镜处理进度 */
- (void)filterRetrievingProgress
{
    if ([self.delegate respondsToSelector:@selector(filterDealProgress:)]) {
        [self.delegate filterDealProgress:_movieFile.progress];
    }
}

#pragma mark - Actions
- (void)cancelFilter
{
    if(_movieWriter)
    {
        [_movieWriter cancelRecording];
    }
}
- (void)deleteTempFile:(NSString *)tempVideoPath
{
    NSURL *url = [NSURL fileURLWithPath:tempVideoPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL exist = [fm fileExistsAtPath:url.path];
    NSError *err;
    if (exist) {
        [fm removeItemAtURL:url error:&err];
        NSLog(@"file deleted");
        if (err) {
            NSLog(@"file remove error, %@", err.localizedDescription );
        }
    } else {
        NSLog(@"no file by that name");
    }
}

@end

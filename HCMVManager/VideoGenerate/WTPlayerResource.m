//
//  WTPlayerResource.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/6/18.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "WTPlayerResource.h"
#import <hccoren/base.h>
#import <hccoren/RegexKitLite.h>
#import <hccoren/images.h>
//#import <hccoren/HCFileManager.h>
//#import <hcbasesystem/UDManager(Helper).h>

#import "WTAVAssetExportSession.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface WTPlayerResource()
{
    NSMutableDictionary *   unsortedThumbImages_;
    
    int thumnateCount_;     //需要处理的缩略图个数
    int completedCount_;    //已经处理的个数
}
@end
@implementation WTPlayerResource
//__strong static WTPlayerResource *sharedResource = nil;

SYNTHESIZE_SINGLETON_FOR_CLASS_NEW(WTPlayerResource)
//
//+ (WTPlayerResource *)instance
//{
//    if(sharedResource==nil)
//    {
////        static dispatch_once_t onceToken;
////        dispatch_once(&onceToken, ^{
////            sharedResource = [[super alloc] init];
////        });
//        @synchronized(self)
//        {
//            if(sharedResource==nil)
//            {
//                sharedResource = [[super alloc]init];
//            }
//        }
//    }
//    return sharedResource;
//}
- (id)init
{
    if(self = [super init])
    {
        //        thumnateCount_ = 0;
        //        completedCount_ = 0;
    }
    return self;
}
#pragma mark - device info
- (void)playbackComplete {
    if (self && [(id)self.delegate respondsToSelector:@selector(WTPlayerResource:didMute:)]) {
        // If playback is far less than 100ms then we know the device is muted
        if (soundDuration < 0.010) {
            [self.delegate WTPlayerResource:self didMute:YES];
        }
        else {
            [self.delegate WTPlayerResource:self didMute:NO];
        }
    }
    [playbackTimer invalidate];
    playbackTimer = nil;
    
    
}

static void soundCompletionCallback (SystemSoundID mySSID, void* myself) {
    AudioServicesRemoveSystemSoundCompletion (mySSID);
    [[WTPlayerResource sharedWTPlayerResource] playbackComplete];
}


- (void)incrementTimer {
    soundDuration = soundDuration + 0.001;
}
- (void)detectMuteSwitch {
#if TARGET_IPHONE_SIMULATOR
    // The simulator doesn't support detection and can cause a crash so always return muted
    if ([(id)self.delegate respondsToSelector:@selector(WTPlayerResource:didMute:)]) {
        [self.delegate WTPlayerResource:self didMute:YES];
    }
    return;
#endif
    
#if __IPHONE_5_0 <= __IPHONE_OS_VERSION_MAX_ALLOWED
    // iOS 5+ doesn't allow mute switch detection using state length detection
    // So we need to play a blank 100ms file and detect the playback length
    soundDuration = 0.0;
    CFURLRef		soundFileURLRef;
    SystemSoundID	soundFileObject;
    
    // Get the main bundle for the app
    CFBundleRef mainBundle;
    mainBundle = CFBundleGetMainBundle();
    
    // Get the URL to the sound file to play
    soundFileURLRef  =	CFBundleCopyResourceURL(
                                                mainBundle,
                                                CFSTR ("detection"),
                                                CFSTR ("aiff"),
                                                NULL
                                                );
    
    // Create a system sound object representing the sound file
    AudioServicesCreateSystemSoundID (
                                      soundFileURLRef,
                                      &soundFileObject
                                      );
    
    AudioServicesAddSystemSoundCompletion (soundFileObject,NULL,NULL,
                                           soundCompletionCallback,
                                           (__bridge void*) self);
    
    // Start the playback timer
    playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(incrementTimer) userInfo:nil repeats:YES];
    // Play the sound
    AudioServicesPlaySystemSound(soundFileObject);
    CFRelease(soundFileURLRef);
    return;
#else
    // This method doesn't work under iOS 5+
    CFStringRef state;
    UInt32 propertySize = sizeof(CFStringRef);
    AudioSessionInitialize(NULL, NULL, NULL, NULL);
    AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &state);
    if(CFStringGetLength(state) > 0) {
        if ([(id)self.delegate respondsToSelector:@selector(isMuted:)]) {
            [self.delegate isMuted:NO];
        }
    }
    if ([(id)self.delegate respondsToSelector:@selector(isMuted:)]) {
        [self.delegate isMuted:YES];
    }
    return;
#endif
}

#pragma mark - Library Thumbnail Getter
//usage:
//__weak typeof(self) weakSelf = self;
//self updateLibraryButtonWithCameraMode:XHCameraModeVideo didFinishcompledBlock:^(UIImage *thumbnail) {
//[weakSelf.videoLibraryButton setBackgroundImage:thumbnail forState:UIControlStateNormal];
//}];
- (void)updateLibraryButtonWithCameraMode:(int)cameraMode didFinishcompledBlock:(void (^)(UIImage *thumbnail))compled
{
    __block NSString *assetPropertyType = nil;
    __block NSMutableArray *assets = [[NSMutableArray alloc] init];
    if (cameraMode == 0) { //照片
        assetPropertyType = [ALAssetTypePhoto copy];
    } else if (cameraMode == 1) { //视频
        assetPropertyType = [ALAssetTypeVideo copy];
    }
    
    void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
    {
        if (group == nil)
        {
            return;
        }
        *stop = YES;
        
        __block int num = 0;
        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop)
         {
             if(result == nil)
             {
                 return;
             }
             __block ALAsset *assetResult = result;
             num++;
             NSInteger numberOf = [group numberOfAssets];
             
             NSString *al_assetPropertyType = [assetResult valueForProperty:ALAssetPropertyType];
             if ([al_assetPropertyType isEqualToString:assetPropertyType]) {
                 [assets addObject:assetResult];
             }
             
             if (num == numberOf) {
                 UIImage *img = [UIImage imageWithCGImage:[[assets lastObject] thumbnail]];
                 dispatch_async(dispatch_get_main_queue(), ^{
                     if (compled) {
                         compled(img);
                     }
                 });
             }
         }];
    };
    
    // Group Enumerator Failure Block
    void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *img = [UIImage imageNamed:@"photo_Library.png"];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (compled) {
                    compled(img);
                }
            });
        });
    };
    // Enumerate Albums
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                           usingBlock:assetGroupEnumerator
                         failureBlock:assetGroupEnumberatorFailure];
}
#pragma mark - thumnates
#pragma mark - duration
- (void) resetThumnates
{
    //    PP_RELEASE(durationDictionary_);
    //    PP_RELEASE(thumbImages_);
    //    completedCount_ = 0;
    //    thumnateCount_ = 0;
    PP_RELEASE(unsortedThumbImages_);
    
}
- (CMTime)getDurations:(NSArray *)urls durations:(NSMutableDictionary **) dictionaries
{
    if(!urls || urls.count==0)
    {
        if(dictionaries)
            *dictionaries = nil;
        return CMTimeMake(0, 30);
    }
    NSMutableDictionary * cDic= nil;
    if(!dictionaries || (! *dictionaries))
    {
        cDic = [NSMutableDictionary new];
    }
    else
    {
        cDic = *dictionaries;
    }
    
    int scale = 600;
    CGFloat seconds = 0;
    int index = 0;
    for (NSURL * url  in urls) {
        CMTime itemTime = [self getDuration:url prevSecond:seconds index:index durations:&cDic];
        if(itemTime.timescale>0)
        {
            scale = itemTime.timescale;
        }
        seconds += CMTimeGetSeconds(itemTime);
        index ++;
    }
    [cDic setObject:[NSNumber numberWithFloat:seconds] forKey:@"seconds"];
    if(dictionaries)
    {
        *dictionaries = cDic;
    }
    return CMTimeMake(seconds * scale, scale);
}

- (CMTime)getDuration:(NSURL *)url
{
    return [self getDuration:url prevSecond:0 index:0 durations:nil];
}
- (CMTime)getDuration:(NSURL *)url prevSecond:(CGFloat)prevSecond index:(int)index durations:(NSMutableDictionary **)dictionaries
{
    NSString * key = nil;
    if(dictionaries)
    {
        if(! *dictionaries)
        {
            *dictionaries = [NSMutableDictionary new];
        }
        key = [self getObjectKey:url index:index];
    }
    
    //
    //    NSString * str = [url absoluteString];
    CMTime duration ;
    if(dictionaries && [*dictionaries objectForKey:key])
    {
        NSDictionary * durationItem = [*dictionaries objectForKey:key];
        NSValue *startValue = [durationItem objectForKey:@"duration"];
        [startValue getValue:&duration];
    }
    else
    {
        if([HCFileManager isInAblum:[url absoluteString]])
        {
            NSLog(@"cannot do the video in album:%@",[url absoluteString]);
        }
        //        else
        {
            AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:url options:nil];
            duration = asset.duration;
            
            if(dictionaries && *dictionaries)
            {
                NSValue *timeValue = [NSValue valueWithCMTime:duration];//[NSValue valueWithBytes:&duration objCType:@encode(CMTime)];
                
                NSMutableDictionary * durationItem = [NSMutableDictionary new];
                [durationItem setObject:timeValue forKey:@"duration"];
                [durationItem setObject:[NSNumber numberWithFloat:prevSecond] forKey:@"begin"];
                [durationItem setObject:[NSNumber numberWithFloat:prevSecond + CMTimeGetSeconds(duration)] forKey:@"end"];
                [durationItem setObject:url.absoluteString forKey:@"path"];
                [durationItem setObject:url forKey:@"url"];
                [*dictionaries setObject:durationItem forKey:key];
            }
        }
    }
    return duration;
}
- (NSString *)getObjectKey:(NSURL*)url index:(int)index
{
    return [NSString stringWithFormat:@"%i-%@",index,[CommonUtil md5Hash:url.absoluteString]];
}

#pragma mark - get times
-(NSMutableDictionary *) getThumbTimes:(NSArray *)urls begin:(float) start andEnd:(float) end andStep:(float)step
{
    NSMutableDictionary * durations = [NSMutableDictionary new];
    
    CMTime duration = [self getDurations:urls durations:&durations];
    if(CMTimeGetSeconds(duration) ==0)
    {
        return PP_AUTORELEASE(durations);
    }
    //定义时间与序号
    CGFloat currentSecond = start;
    int index =0;
    int timeCount = 0;
    //遍历所有文件，同时将所有的时间安排出来
    for (NSURL * url in urls) {
        NSString * key = [self getObjectKey:url index:index];
        NSMutableDictionary * currentDuration = [durations objectForKey:key];
        currentSecond = [self matchTimeSplashes:currentDuration begin:start end:end step:step];
        
        if([currentDuration objectForKey:@"count"])
        {
            timeCount += [[currentDuration objectForKey:@"count"]intValue];
        }
        start = currentSecond;
        index ++;
    }
    
    //记录所有的截图的时间片数
    [durations setObject:[NSNumber numberWithInt:timeCount] forKey:@"count"];
    //    [durations setObject:[NSNumber numberWithFloat:CMTimeGetSeconds(duration)] forKey:@"totalseconds"];
    
    return PP_AUTORELEASE(durations);
}
- (CGFloat)matchTimeSplashes:(NSMutableDictionary *)duration begin:(CGFloat)begin end:(CGFloat)end step:(CGFloat)step
{
    CGFloat totalBegin = [[duration objectForKey:@"begin"]floatValue];
    CGFloat totalEnd = [[duration objectForKey:@"end"]floatValue];
    NSMutableArray * times = [duration objectForKey:@"times"];
    if(!times)
    {
        times = PP_AUTORELEASE([NSMutableArray new]);
        [duration setObject:times forKey:@"times"];
    }
    else
    {
        [times removeAllObjects];
    }
    CGFloat lastNextTime = begin;
    int timeCount = 0;
    
    if(end > totalEnd)
        end = totalEnd;
    //    else if(end +step < totalEnd)
    //        end += step;
    
    for (CGFloat second = begin; second < end ; second += step) {
        NSMutableDictionary * timeItem = [NSMutableDictionary new];
        
        NSNumber *time = [NSNumber numberWithFloat:second - totalBegin];
        NSNumber *ototal = [NSNumber numberWithFloat:totalBegin];
        
        [timeItem setValue:ototal forKey:@"lasttotal"];
        [timeItem setValue:time forKey:@"stime"];
        [timeItem setValue:time forKey:@"etime"];
        [timeItem setValue:[NSNumber numberWithFloat:second] forKey:@"fullsecond"];
        [times addObject:timeItem];
        timeCount ++;
        
        PP_RELEASE(timeItem);
        
        lastNextTime = second+step;
    }
    [duration setObject:[NSNumber numberWithInt:timeCount] forKey:@"count"];
    return lastNextTime;
}
- (void)getVideoThumbs:(NSArray *)urls begin:(CGFloat)start andEnd:(CGFloat)end step:(CGFloat)step count:(int)count  andSize:(CGSize)size delegate:(id<WTPlayerResourceDelegate>)delegate;
{
    if(end>0 && end - start < 0) return;
    
    if(end<0)
    {
        end = 100000000;//CMTimeGetSeconds([self getDurations:urls]);
    }
    BOOL needReduceOneImage = NO;
    NSMutableDictionary *durationList = [self getThumbTimes:urls begin:start andEnd:end andStep:step];
    
    NSString * fileName = [((NSURL *)[urls objectAtIndex:0]).absoluteString lastPathComponent];
    
    [self removeThumnates:fileName size:CGSizeMake(0, 0)];
    
    //统计需要生成的缩略图数据，将生成的缩略图数与外部计算的保持一致,由于精度问题，一般只会少一张
    int timeCount = [[durationList objectForKey:@"count"]intValue];
    if(timeCount < count)
    {
        end = [[durationList objectForKey:@"seconds"]floatValue];
        NSURL * url = [urls lastObject];
        NSString * key = [self getObjectKey:url index:(int)urls.count-1];
        NSMutableDictionary * duration = [durationList objectForKey:key];
        if(duration)
        {
            [self matchTimeSplashes:duration begin:end end:end +step step:step];
            timeCount ++;
        }
    }
    else if(timeCount >count)
    {
        needReduceOneImage = YES;
        timeCount --;
    }
    thumnateCount_ = timeCount;
    NSLog(@"snap images count:%i  need count:%i",thumnateCount_,timeCount);
    completedCount_ = 0;
    
    if(unsortedThumbImages_){
        [unsortedThumbImages_ removeAllObjects];
    }else{
        unsortedThumbImages_ = [[NSMutableDictionary alloc]init];
    }
    
    
    for(int i = 0;i<urls.count;i++){
        
        NSURL *url = [urls objectAtIndex:i];
        NSString * key = [self getObjectKey:url index:i];
        
        NSMutableDictionary *vdic = [durationList objectForKey:key];
        
        if(!vdic)
        {
            NSLog(@"not duration in url:%@", [url absoluteString]);
            continue;
        }
        else
        {
            NSLog(@"begin duration in url:%@",[url absoluteString]);
        }
        NSArray * timeItems = [vdic objectForKey:@"times"];
        if(!timeItems ||timeItems.count==0) continue;
        
        CGFloat prevSeconds = [[vdic objectForKey:@"begin"]floatValue];
        
        AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:url options:nil];
        
        NSMutableArray *thumbnailTimes = [[NSMutableArray alloc] init];
        
        
        for (NSDictionary * timeItem in timeItems) {
            CGFloat time = roundf( [[timeItem objectForKey:@"stime"]floatValue] *10)/10.0f;
            NSString *path = [self getThumnatePath:fileName minsecond:(int)(time * 1000) size:size];
            if( [[HCFileManager manager]existFileAtPath:path])
            {
                completedCount_ ++;
                
                 [self didOneImageCreated:prevSeconds time:time path:path index:completedCount_ size:size delegate:delegate];
                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if ([delegate respondsToSelector:@selector(didGetThumbImage:andPath:index:size:)]) {
//                        [delegate didGetThumbImage:time andPath:path index:completedCount_ size:size];
//                    }
//                });
                continue;
            }
            [thumbnailTimes addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(time , 30)]];
        }
        if(i == (int)urls.count-1 && needReduceOneImage)
        {
            [thumbnailTimes removeLastObject];
        }
        if(thumbnailTimes.count>0)
            [self generateImages:asset times:thumbnailTimes prevTotal:prevSeconds path:fileName size:size delegate:delegate];
    }
}
- (void)generateImages:(AVURLAsset*)asset times:(NSArray *)thumbnailTimes prevTotal:(CGFloat)prevTotal path:(NSString *)fileName size:(CGSize)size delegate:(id<WTPlayerResourceDelegate>)delegate;
{
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    //解决 时间不准确问题
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    generator.requestedTimeToleranceAfter = kCMTimeZero;
    __block BOOL isWarning = NO;
    AVAssetImageGeneratorCompletionHandler handler =
    ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        
        completedCount_ ++;
        
        if (result == AVAssetImageGeneratorSucceeded) {
            
            UIImage* thumbImg = [UIImage imageWithCGImage: image];
            
            NSNumber *time = [NSNumber numberWithFloat: prevTotal + CMTimeGetSeconds(requestedTime)];
            
            NSString *path = [self getThumnatePath:fileName minsecond:(int)([time floatValue] * 1000) size:size];
            [UIImageJPEGRepresentation(thumbImg, 1.0) writeToFile:path atomically:YES];
            
            [self didOneImageCreated:prevTotal time:[time floatValue] path:path index:completedCount_ size:size delegate:delegate];
        }
        
        if (result == AVAssetImageGeneratorFailed) {
            NSLog(@"Failed with error: %@ --%@", [error localizedDescription],[error localizedFailureReason]);
            if(!isWarning)
            {
                isWarning = YES;
                [generator cancelAllCGImageGeneration];
                if(delegate && [delegate respondsToSelector:@selector(didGenerateFailure:file:)])
                {
                    
                    [delegate didGenerateFailure:error file:fileName];
                    
                    NSArray * images = [self sortThumbImages:unsortedThumbImages_];
                    [delegate didAllThumbsGenerated:images];
                }
            }
            //            completedCount_ = (int)thumbnailTimes.count;
            
            //            [self didOneImageCreated:prevTotal time:-1 path:nil index:completedCount_ size:size delegate:delegate]]
            
        }
        
        if (result == AVAssetImageGeneratorCancelled) {
            NSLog(@"Canceled");
        }
        
    };
    
    generator.maximumSize = size;
    [generator generateCGImagesAsynchronouslyForTimes:thumbnailTimes completionHandler:handler];
}
- (void)didOneImageCreated:(CGFloat)prevTotal time:(CGFloat)time path:(NSString *)path index:(int)index size:(CGSize)size delegate:(id<WTPlayerResourceDelegate>)delegate;
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    [dic setValue:[NSNumber numberWithFloat:prevTotal ] forKey:@"lasttotal"];
    [dic setValue:[NSNumber numberWithFloat:time] forKey:@"time"];
    [dic setValue:path forKey:@"path"];
    [unsortedThumbImages_ setObject:dic forKey:[NSNumber numberWithFloat:time] ];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([delegate respondsToSelector:@selector(didGetThumbImage:andPath:index:size:)]) {
            [delegate didGetThumbImage:time andPath:path index:index size:size];
        }
    });
    
    NSLog(@"snap image count:%i currentIndex:%i",thumnateCount_,index);
    if(thumnateCount_ >= 1 && index == thumnateCount_){
        dispatch_async(dispatch_get_main_queue(), ^{
            //图片排序
            NSArray * images = [self sortThumbImages:unsortedThumbImages_];
            
            if ([delegate respondsToSelector:@selector(didAllThumbsGenerated:)]) {
                [delegate didAllThumbsGenerated:images];
            }
        });
    }
}
- (BOOL) getVideoThumbOne:(NSURL *)url atTime:(CMTime)time andSize:(CGSize)size callback:(generateCompleted)completed
{
    NSString * fileName = [url.absoluteString lastPathComponent];//使用第一个文件的名称 ，这样能保证清理缓存时没有遗漏
    CMTime thumnateTime = time;

    NSString *path = [self getThumnatePath:fileName minsecond:(int)(CMTimeGetSeconds(time)*1000) size:size];
    
    if( [[HCFileManager manager]existFileAtPath:path])
    {
        if(completed)
        {
            UIImage * image = [UIImage imageWithContentsOfFile:path];
            completed(thumnateTime,path,image);
        }
        return YES;
    }
    
    AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;  //按正确方向处理
    //解决 时间不准确问题
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    generator.requestedTimeToleranceAfter = kCMTimeZero;
    
    
    NSMutableArray *thumbnailTimes = [[NSMutableArray alloc] init];
    
    [thumbnailTimes addObject:[NSValue valueWithCMTime:thumnateTime]];
    
    AVAssetImageGeneratorCompletionHandler handler =
    ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        
        if (result == AVAssetImageGeneratorSucceeded) {
            
            UIImage* thumbImg = [UIImage imageWithCGImage: image];
            
            [UIImageJPEGRepresentation(thumbImg, 1.0) writeToFile:path atomically:YES];
            
            if(completed)
            {
                completed(thumnateTime,path,thumbImg);
            }
        }
        
        if (result == AVAssetImageGeneratorFailed) {
            NSLog(@"Failed with error: %@", [error localizedDescription]);
        }
        
        if (result == AVAssetImageGeneratorCancelled) {
            NSLog(@"Canceled");
        }
        
    };
    
    AVAssetTrack *vTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    if(vTrack)
    {
        CGRect targetSize = [CommonUtil rectFitWithScale:vTrack.naturalSize rectMask:size];
        if(targetSize.size.width<=10 || targetSize.size.height <=10)
            generator.maximumSize = size;
        else
            generator.maximumSize = targetSize.size;
        
    }
    else
    {
        generator.maximumSize = size;
    }
    [generator generateCGImagesAsynchronouslyForTimes:thumbnailTimes completionHandler:handler];
    return YES;
}

- (BOOL) getVideoThumbOne:(NSArray *)urls andSize:(CGSize)size callback:(generateCompleted)completed
{
    return [self getVideoThumbOne:[urls objectAtIndex:0] atTime:CMTimeMakeWithSeconds(1, 25) andSize:size callback:completed];
}
- (void)getVideoThumb:(NSArray *)urls time:(CMTime) time andSize:(CGSize)size  delegate:(id<WTPlayerResourceDelegate>)delegate;
{
    [self getVideoThumbN:urls time:time andSize:size orientation:0 delegate:delegate];
}
- (void)getVideoThumbN:(NSArray *)urls time:(CMTime) time andSize:(CGSize)size orientation:(int)orientation delegate:(id<WTPlayerResourceDelegate>)delegate;
{
    NSMutableDictionary * durations = [NSMutableDictionary new];
    
    CMTime duration = [self getDurations:urls durations:&durations];
    if(CMTimeGetSeconds(duration) ==0)
    {
        return;
    }
    CGFloat totalSeconds = [[durations objectForKey:@"seconds"]floatValue];
    CGFloat seconds = roundf(CMTimeGetSeconds(time)*10)/10.0f;
    
    NSDictionary * currentDuration = nil;
    for (NSString * key in durations.allKeys) {
        if([key isEqual:@"seconds"] || [key isEqual:@"totalseconds"]||[key isEqual:@"count"]) continue;
        NSDictionary * dic = [durations objectForKey:key];
        if([dic isKindOfClass:[NSDictionary class]])
        {
            CGFloat begin = [[dic objectForKey:@"begin"]floatValue];
            CGFloat end = [[dic objectForKey:@"end"]floatValue];
            if(begin <= seconds && (end > seconds|| (totalSeconds == end && end == seconds)))
            {
                currentDuration = dic;
                break;
            }
        }
    }
    if(!currentDuration) return;
    
    NSString * fileName = [((NSURL *)[urls objectAtIndex:0]).absoluteString lastPathComponent];//使用第一个文件的名称 ，这样能保证清理缓存时没有遗漏
    
    NSURL *url =  [currentDuration objectForKey:@"url"];
    
    float begin = [[currentDuration objectForKey:@"begin"] floatValue];
    
    //调整精度
    CGFloat cTime = roundf((seconds - begin) *10)/10.0;
    
    CMTime thumnateTime = CMTimeMakeWithSeconds(cTime, duration.timescale);
    
    
    NSString *path = [self getThumnatePath:fileName minsecond:(int)(seconds * 1000) size:size];
    
    if( [[HCFileManager manager]existFileAtPath:path])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([delegate respondsToSelector:@selector(didGetThumbImage:andPath:index:size:)]) {
                [delegate didGetThumbImage:seconds andPath:path index:0 size:size];
            }
        });
        return;
    }
    
    AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    //解决 时间不准确问题
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    generator.requestedTimeToleranceAfter = kCMTimeZero;
    
    
    NSMutableArray *thumbnailTimes = [[NSMutableArray alloc] init];
    
    [thumbnailTimes addObject:[NSValue valueWithCMTime:thumnateTime]];
    
    AVAssetImageGeneratorCompletionHandler handler =
    ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        
        if (result == AVAssetImageGeneratorSucceeded) {
            
            UIImage* thumbImg = [UIImage imageWithCGImage: image scale:[DeviceConfig config].Scale orientation:UIImageOrientationUp];
//            
//            if(orientation == UIDeviceOrientationLandscapeRight)
//            {
//                thumbImg = [thumbImg imageRotatedByDegrees:180];
//            }
//            else if(orientation == UIDeviceOrientationLandscapeLeft)
//            {
//                
//            }
//            else if(orientation == UIDeviceOrientationPortrait)
//            {
//                thumbImg = [thumbImg imageRotatedByDegrees:90];
//            }
//            else if(orientation == UIDeviceOrientationPortraitUpsideDown)
//            {
//                thumbImg = [thumbImg imageRotatedByDegrees:-90];
//            }
            [UIImageJPEGRepresentation(thumbImg, 1.0) writeToFile:path atomically:YES];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([delegate respondsToSelector:@selector(didGetThumbImage:andPath:index:size:)]) {
                    [delegate didGetThumbImage:CMTimeGetSeconds(requestedTime) andPath:path index:0 size:size];
                }
            });
        }
        else if (result == AVAssetImageGeneratorFailed) {
            NSLog(@"Failed with error: %@", [error localizedDescription]);
            if ([delegate respondsToSelector:@selector(didGetThumbFailure:error:index:size:)]) {
                [delegate didGetThumbFailure:CMTimeGetSeconds(requestedTime) error:[error localizedDescription]  index:0 size:size];
            }
        }
        else if (result == AVAssetImageGeneratorCancelled) {
            NSLog(@"Canceled");
            if ([delegate respondsToSelector:@selector(didGetThumbFailure:error:index:size:)]) {
                [delegate didGetThumbFailure:CMTimeGetSeconds(requestedTime) error:@"canceled" index:0 size:size];
            }
            
        }
        else
        {
            if ([delegate respondsToSelector:@selector(didGetThumbFailure:error:index:size:)]) {
                [delegate didGetThumbFailure:CMTimeGetSeconds(requestedTime) error:@"unkown" index:0 size:size];
            }
        }
        
    };
    AVAssetTrack *vTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    if(vTrack)
    {
        CGRect targetSize = [CommonUtil rectFitWithScale:vTrack.naturalSize rectMask:size];
        if(targetSize.size.width<=10 || targetSize.size.height <=10)
            generator.maximumSize = size;
        else
            generator.maximumSize = targetSize.size;

    }
    else
    {
        generator.maximumSize = size;
    }
    
    //    generator.maximumSize = size;
    [generator generateCGImagesAsynchronouslyForTimes:thumbnailTimes completionHandler:handler];
}
- (BOOL) getVideoThumbs:(NSURL *)url
//                alAsset:(ALAsset *)alAsset
 targetThumnateFileName:(NSString *)fileName
                  begin:(float) start
                 andEnd:(float) end
                andStep:(float)step
               andCount:(int)count
                andSize:(CGSize)size
               callback:(generateCompletedNew)onegenerated
              completed:(generateCompletedNew)completed
                failure:(generateFailure)failure
{
    if(end>0 && end - start < 0) return NO;
    
    if(end<0)
    {
        end = 100000000;//CMTimeGetSeconds([self getDurations:urls]);
    }
    BOOL needReduceOneImage = NO;
    NSMutableDictionary *durationList = [self getThumbTimes:[NSArray arrayWithObject:url] begin:start andEnd:end andStep:step];
    
    NSString * key = [self getObjectKey:url index:0];
    NSMutableDictionary * duration = [durationList objectForKey:key];
    NSArray * timeItems = nil;
    int completedCount = 0;
    
    [self removeThumnates:fileName size:CGSizeMake(0, 0)];
    
    //统计需要生成的缩略图数据，将生成的缩略图数与外部计算的保持一致,由于精度问题，一般只会少一张
    int timeCount = [[duration objectForKey:@"count"]intValue];
    
    if(timeCount < count && duration) //需增加最后一张图
    {
        NSMutableArray * times = [duration objectForKey:@"times"];
        end = [[duration objectForKey:@"end"]floatValue];
        NSMutableDictionary * timeItem = [NSMutableDictionary new];
        
        NSNumber *time = [NSNumber numberWithFloat:end-0.1];
        NSNumber *ototal = [NSNumber numberWithFloat:0];
        
        [timeItem setValue:ototal forKey:@"lasttotal"];
        [timeItem setValue:time forKey:@"stime"];
        [timeItem setValue:time forKey:@"etime"];
        [timeItem setValue:time forKey:@"fullsecond"];
        [times addObject:timeItem];
        
        timeCount ++;
        
        [duration removeObjectForKey:@"count"];
        [duration setObject:[NSNumber numberWithInt:timeCount] forKey:@"count"];
        
        PP_RELEASE(timeItem);
        
    }
    else if(timeCount >count)
    {
        needReduceOneImage = YES;
        timeCount --;
    }
    thumnateCount_ = timeCount;
    NSLog(@"snap images count:%i  need count:%i",thumnateCount_,timeCount);
    
    timeItems = [duration objectForKey:@"times"];
    if(!timeItems ||timeItems.count==0)
    {
        return NO;
    }
    CGFloat prevSeconds = [[duration objectForKey:@"begin"]floatValue];
    
    AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:url options:nil];
    
    NSMutableArray *thumbnailTimes = [[NSMutableArray alloc] init];
    
    
    size.height = round(size.height * 10)/10.0f;
    size.width = round(size.width * 10)/10.0f;
    
    //已经存在不需要再生成的
    for (NSDictionary * timeItem in timeItems) {
        CGFloat time = round( [[timeItem objectForKey:@"stime"]floatValue] *10)/10.0f;
        NSString *path = [self getThumnatePath:fileName minsecond:(int)(time * 1000+0.4) size:size];
        if( [[HCFileManager manager] existFileAtPath:path])
        {
            completedCount ++;
            NSLog(@"--generate:%d has cached",completedCount);
            if(onegenerated)
            {
                onegenerated(CMTimeMakeWithSeconds(time * 30 , 30),path,completedCount);
            }
            if(completed && completedCount>=count)
            {
                completed(CMTimeMakeWithSeconds(time * 30 , 30),path,completedCount);
            }
            continue;
        }
        //将需要加的图放在队列中
        [thumbnailTimes addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(time , 30)]];
    }
    if(needReduceOneImage)
    {
        [thumbnailTimes removeLastObject];
    }
    if(thumbnailTimes.count>0)
    {
        [self generateImages:asset times:thumbnailTimes prevTotal:prevSeconds path:fileName size:size
                    callback:^(CMTime time,NSString * path,NSInteger index)
         {
             NSLog(@"-- generate thumnate:%d(%@) has completed",(int)(completedCount+index),[path lastPathComponent]);
             if(completedCount +index+ 1 >=count)
             {
                 NSLog(@"-- generate thumnate:all done.");
             }
             if(onegenerated)
             {
                 onegenerated(time,path,completedCount + index);
             }
             if(completed && completedCount +index >=count)
             {
                 completed(time,path,completedCount + index);
             }
         }
                     failure:^(CMTime requestTime,NSError *error,NSString *filePath)
         {
              NSLog(@"--generate thumnate failure:%@",[error localizedDescription]);
             if(failure)
             {  
                 failure(requestTime,error,filePath);
             }
         }];
    }
    else
    {
        NSLog(@"--generate thumnate failure:nothing to thumnate");
        if(completed)
        {
            completed(kCMTimeZero,nil,-1);
        }
    }
    return YES;
}
- (void)generateImages:(AVAsset*)asset
                 times:(NSArray *)thumbnailTimes
             prevTotal:(CGFloat)prevTotal
                  path:(NSString *)fileName
                  size:(CGSize)size
              callback:(generateCompletedNew)onegenerated
               failure:(generateFailure)failure
{
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    //解决 时间不准确问题
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    generator.requestedTimeToleranceAfter = kCMTimeZero;
    CGFloat scale = [UIScreen mainScreen].scale;
    
    __block BOOL isWarning = NO;
    __block NSInteger completedCount = 0;
    AVAssetImageGeneratorCompletionHandler handler =
    ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        NSNumber *time = [NSNumber numberWithFloat: prevTotal + CMTimeGetSeconds(requestedTime)];
        
        if (result == AVAssetImageGeneratorSucceeded) {
            
            UIImage* thumbImg = [UIImage imageWithCGImage: image scale:scale orientation:0];
            NSString *path = [self getThumnatePath:fileName minsecond:(int)([time floatValue] * 1000 +0.4) size:size];
            
            [UIImageJPEGRepresentation(thumbImg, 1.0) writeToFile:path atomically:YES];
            
            if(onegenerated)
            {
                onegenerated(CMTimeMake([time floatValue]*30, 30),path,completedCount);
            }
        }
        if (result == AVAssetImageGeneratorFailed) {
            NSLog(@"Failed with error: %@ --%@", [error localizedDescription],[error localizedFailureReason]);
            if(!isWarning)
            {
                isWarning = YES;
                [generator cancelAllCGImageGeneration];
                
                if(failure)
                {
                    failure(CMTimeMake([time floatValue]*30, 30),error,nil);
                }
            }
        }
        if (result == AVAssetImageGeneratorCancelled) {
            if(failure)
            {
                failure(CMTimeMake([time floatValue]*30, 30),nil,@"用户取消");
            }
        }
        completedCount ++;
    };
    
    size.width = size.width * scale;
    size.height = size.height * scale;
    generator.maximumSize = size;
    [generator generateCGImagesAsynchronouslyForTimes:thumbnailTimes completionHandler:handler];
}

#pragma mark - sort

-(NSArray *)sortThumbImages:(NSDictionary *)unsortedThumbImages
{
    if(!unsortedThumbImages) return nil;
    
    NSArray *allKeys = [unsortedThumbImages allKeys];
    NSArray *sortedKeys = [allKeys sortedArrayUsingFunction:thumnateSecondSort context:NULL];
    
    NSMutableArray * thumbImages = [[NSMutableArray alloc]init];
    
    for(id key in sortedKeys) {
        id object = [unsortedThumbImages objectForKey:key];
        [thumbImages addObject:object];
    }
    return PP_AUTORELEASE(thumbImages);
}

NSInteger thumnateSecondSort(id num1, id num2, void *context)
{
    float v1 = [num1 floatValue];
    float v2 = [num2 floatValue];
    
    if (v1 < v2)
        return NSOrderedAscending;
    else if (v1 > v2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}
#pragma mark - file dir helper
-(NSString *)getThumnatePath:(NSString *)filename minsecond:(int)minsecond size:(CGSize)size
{
    if(!filename)
    {
        filename = @"";
    }
    if([filename rangeOfString:@"/"].length>0)
    {
        filename = [filename lastPathComponent];
    }
    NSString * path =  [NSString stringWithFormat:@"%@_%@.%@.jpg",filename,[CommonUtil stringWithFixedLength:minsecond withLength:6],NSStringFromCGSize(size)];
    return [[HCFileManager manager] tempFileFullPath:path];
}
- (BOOL) removeThumnates:(NSString *)orgFileName size:(CGSize) size
{
    if(!orgFileName)
    {
        orgFileName = @"";
    }
    if([HCFileManager isLocalFile:orgFileName])
    {
        orgFileName = [orgFileName lastPathComponent];
    }
    NSString * regEx = nil;
    if(size.width ==0 || size.height ==0)
        regEx = [NSString stringWithFormat:@"%@_\\d+\\..*\\.jpg",orgFileName];
    else
        regEx = [NSString stringWithFormat:@"%@_\\d+\\.\\{\\d+,\\d+\\}\\.jpg",orgFileName];
    NSString * dir = [[HCFileManager manager] tempFileFullPath:nil];
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:dir]) return NO;
    
    BOOL ret = YES;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:dir] objectEnumerator];
    NSString* fileName;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        if([fileName isMatchedByRegex:regEx])
        {
            NSString* fileAbsolutePath = [dir stringByAppendingPathComponent:fileName];
            if(![[HCFileManager manager] removeFileAtPath:fileAbsolutePath])
            {
                ret = NO;
            }
        }
    }
    return ret;
}

#pragma mark - singletone alloc release etc.
//+ (id)allocWithZone:(NSZone *)zone
//{
//    if(sharedResource==nil)
//    {
//        static dispatch_once_t onceToken;
//        dispatch_once(&onceToken, ^{
//            sharedResource = [[self alloc] init];
//        });
//    }
//    return sharedResource;
//}
//
//- (id)copyWithZone:(NSZone *)zone
//{
//    return self;
//}
//#if !PP_ARC_ENABLED
//- (id)retain
//{
//    return self;
//}
//
//- (NSUInteger)retainCount
//{
//    return NSUIntegerMax;
//}
//
//- (oneway void)release
//{
//}
//
//- (id)autorelease
//{
//    return self;
//}
//#endif

- (void)readyToRelease
{
    NSLog(@"player resource ready to release....");
}
- (void)dealloc
{
    PP_SUPERDEALLOC;
}

@end

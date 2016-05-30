#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "MediaItem.h"
#import "mvconfig.h"

//#import "LyricLayerAnimation.h"
//#import "LyricItem.h"

typedef void(^SuccessBlock)(BOOL success,CGFloat progress);
//#import "DDAudioLRCParser.h"

/**
 *  Determines defaults for transitions
 */
FOUNDATION_EXPORT BOOL const DefaultTransitionShouldAnimate;

/**
 *  Determines default frame size for videos
 */
FOUNDATION_EXPORT CGSize const DefaultFrameSize;

/**
 *  Determines default FPS of video - 10 Images at 10FPS results in a 1 second video clip.
 */
FOUNDATION_EXPORT NSInteger const DefaultFrameRate;

/**
 *  Number of frames to use in transition
 */
FOUNDATION_EXPORT NSInteger const TransitionFrameCount;

/**
 *  Number of frames to hold each image before beginning alpha fade into the next
 */
FOUNDATION_EXPORT NSInteger const FramesToWaitBeforeTransition;






@interface ImagesToVideo : NSObject
+ (CGSize) correctSizeWithoutOrientation:(CGSize)targetSize sourceSize:(CGSize)sourceSize;
+ (CGSize) correctSize:(CGSize)targetSize sourceSize:(CGSize)sourceSize keep16:(BOOL)keep16;
/**
 *  This is the main function for creating a video from a set of images
 *
 *  FPS of 1 with 10 images results in 10 second video, but not necessarily an only 10 frame video. Transitions will add frames, but maintain expected duration
 *
 *  @param images        Images to convert to video  [UIImage imageNamed:@"watermark_MtvPlus"]
 *  @param path          Path to write video to
 *  @param size          Frame size of image
 *  @param fps           FPS of video
 *  @param animate       Yes results in crossfade between images
 *  @param callbackBlock Block to execute when video creation completes or fails
 */

//+ (void)saveVideoToPhotosWithImage:(UIImage *)image
//                              item:(VideoItem *)item
//                 withCallbackBlock:(SuccessBlock)callbackBlock;
//构建歌词动画
+ (CALayer *)buildTitleLayer:(NSString *)title singer:(NSString*)singer renderSize:(CGSize)renderSize orientation:(int)orientation position:(int)position;
+ (CALayer *)buildWaterMarkerLayer:(NSString *)imageFilePath renderSize:(CGSize)renderSize orientation:(int)orientation position:(WaterMarkerPosition)position;
+ (CALayer *)getLrcAnimationLayer:(CGFloat)beginTime duration:(CGFloat)videoDuration lrc:(NSArray *)lrcList orientation:(int)orientation  renderSize:(CGSize) renderSize rate:(CGFloat)rate filterLyrics:(NSArray **)filterLyrics;
//+ (NSArray *)parseLyricItems:(DDAudioLRC *)lrcFile beginTime:(CGFloat)beginTime endTime:(CGFloat)endTime;
+ (NSArray *)filterLyricItems:(NSArray *)lrcItems beginTime:(CGFloat)beginTime endTime:(CGFloat)endTime;

+ (void)writeImageToMovieN:(UIImage *)image
                    toPath:(NSString*)path
                      size:(CGSize)size
                       fps:(CGFloat)fps
                   seconds:(CGFloat)seconds
               orientation:(UIDeviceOrientation)orientation
         withCallbackBlock:(SuccessBlock)callbackBlock;

+ (void)generateVideoByImage:(UIImage *)image
                        item:(MediaItem *)item
           withCallbackBlock:(SuccessBlock)callbackBlock;

@end

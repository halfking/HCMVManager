
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <hccoren/base.h>

@class HCPlayerSimple;

@protocol HCPlayerSimpleDelegate <NSObject>
@optional
- (void)playerSimple:(HCPlayerSimple *)playerSimple itemReady:(AVPlayerItem *)item;
- (void)playerSimple:(HCPlayerSimple *)playerSimple reachEnd:(CGFloat)end;
- (void)playerSimple:(HCPlayerSimple *)playerSimple timeDidChange:(CGFloat)cmTime;
- (void)playerSimple:(HCPlayerSimple *)playerSimple loadedTimeRangeDidChange:(float)duration;
- (void)playerSimple:(HCPlayerSimple *)playerSimple didFailWithError:(NSError *)error;
- (void)playerSimple:(HCPlayerSimple *)playerSimple didFailedToPlayToEnd:(NSError *)error;
- (void)playerSimple:(HCPlayerSimple *)playerSimple pausedByUnexpected:(NSError *)error item:(AVPlayerItem *)playerItem;
- (void)playerSimple:(HCPlayerSimple *)playerSimple autoPlayAfterPause:(NSError *)error item:(AVPlayerItem *)playerItem;
- (void)playerSimple:(HCPlayerSimple *)playerSimple didStalled:(AVPlayerItem *)playerItem;
- (void)playerSimple:(HCPlayerSimple *)playerSimple didTapped:(AVPlayerItem *)playerItem;
- (void)playerSimple:(HCPlayerSimple *)playerSimple beginPlay:(AVPlayerItem *)playerItem;

- (void)playerSimple:(HCPlayerSimple *)playerSimple showWaiting:(BOOL)isShow;
@end

@interface HCPlayerSimple : UIView
{
    CGFloat secondsPlaying_;
    CGFloat playRate_;
}

@property (nonatomic,PP_WEAK) id<HCPlayerSimpleDelegate> delegate;
@property (strong, nonatomic,readonly) AVPlayerItem *playerItem;

@property (assign,nonatomic) CGRect mainBounds;
@property (assign,nonatomic) BOOL playing;
@property (assign,nonatomic,readonly) CGFloat secondsPlaying;
//@property (nonatomic,strong) NSString * playerItemKey;
@property (nonatomic, assign) BOOL isEcoCancellationMode;

@property (nonatomic,assign) BOOL cachingWhenPlaying;   //在播放时是否缓存文件

//用于全局一个播放器时，可以在列表中显示时，找到当前的Player，并且自由处理
+ (instancetype)sharedHCPlayerSimple;

- (id)initWithFrame:(CGRect) frame;
- (AVPlayerLayer *)currentLayer;
- (BOOL) canPlay;
- (void) play;
- (BOOL) play:(CGFloat)begin end:(CGFloat)end;
- (void) pause;
- (BOOL) seek:(CGFloat)seconds accurate:(BOOL)accurate;
- (void) resetPlayer;

- (void) setRate:(CGFloat)rate;

- (void) setVideoVolume:(float)volume;//值 0-1
- (CGFloat) getVideoVolumne;

- (void) changeCurrentPlayerItem:(AVPlayerItem *)item;
- (void) changeCurrentItemUrl:(NSURL *)url;
- (void) changeCurrentItemPath:(NSString *)path;
- (void) setItemOrgPath:(NSString *)orgPath;
- (BOOL) isCurrentPath:(NSString *)path;

- (NSURL *) getUrlFromString:(NSString *)urlString;

- (CGFloat) getSecondsEnd;
- (NSURL *) getCurrentUrl;
- (CMTime) duration;
- (CMTime) durationWhen;
- (UIImage *) captureImage;
- (void) showActivityView;

-(void) resizeViewToRect:(CGRect) frame
         andUpdateBounds:(bool) isupdate
           withAnimation:(BOOL)animation
                  hidden:(BOOL)hidden
                 changed:(void (^)(CGRect frame,NSURL * url)) changed;

- (void)readyToRelease;
 
//- (void)setPlayerTransform:(CATransform3D)transform position:(CGPoint)position;
@end

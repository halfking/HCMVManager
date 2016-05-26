
#import "HCPlayerSimple.h"
#import <AVFoundation/AVFoundation.h>

@interface HCPlayerSimple ()
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@end

@implementation HCPlayerSimple
{
    id timeObserver_;
    
    NSURL *     currentPlayUrl_; //当前播放的媒体文件
    NSString *  orgPath_; //由于边下边播，源Path与真实播的Path不一致
    
    CGFloat secondsBegin_;
    CGFloat secondsEnd_;
    
    CMTime duration_;
    CGFloat secondsDuration_;
    
    
    BOOL hasObserver_;
    
    NSTimer * waitingTimer_;
    CGFloat waitingOffset_;
    UIImageView * waitingView_;
    
    NSNumber *audioPlayerID_;
    
    BOOL needAutoPlay_;//是否需要在加载完成后自动开始播放
    
    int pauseCount_;//即检测到播放速率为0的次数
    
    //    CATransform3D transform_;
    //    CGPoint position_;
}
@synthesize player = player_;
@synthesize playerItem = playerItem_;
@synthesize secondsPlaying = secondsPlaying_;

+ (instancetype)sharedHCPlayerSimple
{
    return sharedPlayerView;
}

+ (void)releaseSharedHCPlayerSimple
{
    t = 0;
    if(sharedPlayerView)
    {
        [sharedPlayerView readyToRelease];
        sharedPlayerView = nil;
    }
}

//- (void)setPlayerTransform:(CATransform3D)transform position:(CGPoint)position
//{
//    transform_  = transform;
//    position_ = position;
//}


static dispatch_once_t t;
static HCPlayerSimple *sharedPlayerView = nil;


- (id)initWithFrame:(CGRect) frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSLog(@"wtplayer alloc...");
        self.backgroundColor = [UIColor blackColor];
        self.mainBounds = frame;
        
//        self.cachingWhenPlaying = YES;
        
        playRate_ = 1;
        
        [self clearPlayerContents];
        
        //        transform_ = CATransform3DIdentity;
        //        position_ = self.center;
        //
        //        {
        //            UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(didTapped:)];
        //            [self addGestureRecognizer:tap];
        //            PP_RELEASE(tap);
        //
        //            self.userInteractionEnabled = YES;
        //        }
        sharedPlayerView = self;
    }
    return self;
}
- (AVPlayerLayer *)currentLayer
{
    return _playerLayer;
}
- (AVPlayer *) currentPlayer
{
    return player_;
}
- (void)resetPlayer
{
    //    if(self.loader)
    //    {
    //        [self.loader cancel];
    //        self.loader = nil;
    //    }
    [self hideActivityView];
    [self pause];
    [self clearPlayerContents];
}


#pragma mark - play pause
- (BOOL)canPlay
{
    if((self.playerItem && self.playerItem.status == AVPlayerItemStatusReadyToPlay)
       || ([player_ currentItem] && [player_ currentItem].status == AVPlayerItemStatusReadyToPlay))
    {
        return YES;
    }
    return NO;
}
- (void)play
{
    [self play:YES];
}
-(void)play:(BOOL)enterForeground
{
    
    if(!player_ || ![player_ currentItem])
    {
        NSLog(@"avplayer is nil!");
        return;
    }
    [self changeFlagsForPlay];
    
    if(player_ && player_.rate>0)
    {
        NSLog(@"is playing,do nothing,return;");
        return;
    }
    
    //回音消除相关代码
    //    if (currentPlayUrl_ && [CommonUtil isLocalFile:[currentPlayUrl_ absoluteString]] && self.isEcoCancellationMode && audioPlayerID_) {
    //        player_.muted = YES;
    //        [AudioCenter shareAudioCenter].isEcoCancellationEnable = YES;
    //        [[AudioCenter shareAudioCenter] playItemID:audioPlayerID_];
    //    }
    //    else{
    //        player_.muted = NO;
    //        [AudioCenter shareAudioCenter].isEcoCancellationEnable = NO;
    //    }
    
    [player_ play];
    player_.rate = playRate_;
    
    NSLog(@"player status:%d",(int)player_.status);
    if(player_.error)
    {
        [self changeFlagForPause];
        
        NSLog(@"play error:%@",[player_.error localizedDescription]);
        
        if(self.delegate && [self.delegate respondsToSelector:@selector(playerSimple:didFailWithError:)])
        {
            [self.delegate playerSimple:self didFailWithError:player_.error];
        }
    }
    else
    {
        if(self.delegate && [self.delegate respondsToSelector:@selector(playerSimple:beginPlay:)])
        {
            [self.delegate playerSimple:self beginPlay:self.playerItem];
        }
    }
}
- (void)setRate:(CGFloat)rate
{
    if(rate ==0)
    {
        NSLog(@"set play rate zero.");
    }
    playRate_ = rate;
    if(player_ && player_.rate!=0)
    {
        player_.rate = rate;
    }
}
- (BOOL)play:(CGFloat)begin end:(CGFloat)end
{
    secondsBegin_ = begin;
    secondsEnd_= end;
    
    if(!player_ || !playerItem_) return NO;
    
    [self setDurationWithPlayeritem:player_.currentItem];
    
    //如果到结尾，则自动从头开始
    if(begin >= secondsDuration_ - 0.01)
    {
        begin = 0;
    }
    needAutoPlay_ = YES;
    return [self seek:secondsBegin_ accurate:YES];
    
    return YES;
}
- (BOOL)seek:(CGFloat)seconds accurate:(BOOL)accurate
{
    return [self seek:seconds accurate:accurate count:0];
}
- (BOOL)seek:(CGFloat)seconds accurate:(BOOL)accurate count:(int)count
{
    //    while (count<20) {
    if(player_ && player_.currentItem && count<10)
    {
        if(seconds>= CMTimeGetSeconds(duration_))//到末尾了，就再重新开始
        {
            seconds = 0;
        }
        if(player_.currentItem.status == AVPlayerItemStatusReadyToPlay)
        {
            [self hideActivityView];
            if(count>0)
            {
                if(self.delegate && [self.delegate respondsToSelector:@selector(playerSimple:itemReady:)])
                {
                    [self.delegate playerSimple:self itemReady:player_.currentItem];
                }
            }
            count = 0;
            return [self seekInThread:seconds accurate:accurate];
        }
        else if(player_.currentItem.status == AVPlayerItemStatusUnknown)
        {
            [self showActivityView];
            __weak HCPlayerSimple * weakSelf = self;
            count ++;
            [NSThread sleepForTimeInterval:0.1];
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong HCPlayerSimple * strongSelf = weakSelf;
                [strongSelf seek:seconds accurate:accurate count:count];
            });
        }
        return NO;
    }
    
    NSError * error = [NSError errorWithDomain:@"maiba" code:-99 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"播放对像状态不正确 (重试超过 %i次)", count]}];
    if(self.delegate && [self.delegate respondsToSelector:@selector(playerSimple:didFailWithError:)])
    {
        [self.delegate playerSimple:self didFailWithError:error];
    }
    NSLog(@"%@",[error localizedDescription]);
    count = 0;
    return NO;
}
- (BOOL)seekInThread:(CGFloat)seconds accurate:(BOOL)accurate
{
    //    [self showActivityView];
    if(player_ && (player_.rate >0||self.playing))
    {
        [self pause];
        needAutoPlay_ = YES;
        [self showActivityView];
    }
    else
    {
        BOOL tempNeedAutoPlay = needAutoPlay_;
        [self changeFlagForPause];
        needAutoPlay_ = tempNeedAutoPlay;
    }
    
    [self setDurationWithPlayeritem:player_.currentItem];
    
    if(seconds <0) seconds = 0;
    else if(seconds >= secondsDuration_) seconds = 0;//secondsDuration_ -1;
    
    TimeScale ts = CMTIME_IS_VALID(duration_)?duration_.timescale:600;
    
    if(!accurate)
        [player_ seekToTime:CMTimeMakeWithSeconds(seconds, ts)];
    else
        [player_ seekToTime:CMTimeMakeWithSeconds(seconds, ts)
            toleranceBefore:kCMTimeZero
             toleranceAfter:kCMTimeZero];
    
    secondsPlaying_ = seconds;
    
    if(needAutoPlay_)
    {
        [self play:NO];
    }
    
    
    //回音消除相关代码
    //    if (currentPlayUrl_ && [CommonUtil isLocalFile:[currentPlayUrl_ absoluteString]] && self.isEcoCancellationMode && audioPlayerID_)
    //    {
    //        [[AudioCenter shareAudioCenter] seekToSeconds:seconds forItemID:audioPlayerID_];
    //    }
    return YES;
}
-(void)pause
{
    //    [self willEnterForeground];
    [self changeFlagForPause];
    
    if(player_)
    {
        if(player_.rate >0)
        {
            [player_ pause];
        }
        else
        {
            [self hideActivityView];
        }
    }
}

#pragma mark - helper contents views
- (void) buildPlayerContents
{
    if (!player_) {
        player_ =[[AVPlayer alloc] initWithPlayerItem:playerItem_];
    } else {
        [player_ replaceCurrentItemWithPlayerItem:playerItem_];
    }
    //    player_.allowsExternalPlayback = NO;
    player_.allowsExternalPlayback = YES;
    
    //    player_.muted = YES;
    [self addObserver];
    [self generateAvplayerLayer:nil];
}
-(void)generateAvplayerLayer:(NSTimer*)timer
{
    if (_playerLayer) {
        [_playerLayer removeFromSuperlayer];
    }
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:player_];
    _playerLayer.frame = self.bounds;
    NSLog(@"player layer bounds:%@",NSStringFromCGRect(_playerLayer.frame));
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    [self.layer addSublayer:_playerLayer];
    
    //    if(!CATransform3DIsIdentity(transform_))
    //    {
    //        _playerLayer.transform = transform_;
    //        _playerLayer.position = position_;
    //    }
    if(self.playerItem.status == AVPlayerItemStatusFailed)
    {
        NSLog(@"playeritem error:%@",[self.playerItem.error localizedDescription]);
    }
    NSLog(@"play item status:%d duration:%.2f",(int)self.playerItem.status,CMTimeGetSeconds(self.playerItem.duration));
}
- (void) clearPlayerContents
{
    //    if(bgTask_!=UIBackgroundTaskInvalid)
    //    {
    //        [[UIApplication sharedApplication]endBackgroundTask:bgTask_];
    //        bgTask_ = UIBackgroundTaskInvalid;
    //    }
    [self clearObserver];
    
    //回音消除相关代码
    //    if (audioPlayerID_) {
    //        [[AudioCenter shareAudioCenter] removePlayerForItemID:audioPlayerID_];
    //        audioPlayerID_ = nil;
    //    }
    //    if(progressView_)
    //    {
    //        [progressView_ removeFromSuperview];
    //        PP_RELEASE(progressView_);
    //    }
    if(_playerLayer)
    {
        _playerLayer.delegate = nil;
        [_playerLayer removeFromSuperlayer];
        _playerLayer = nil;
    }
    
    PP_RELEASE(playerItem_);
    PP_RELEASE(currentPlayUrl_);
    self.player = nil;
    
    //    [self removeLyric];
    //    [self resetComments];
    
    secondsPlaying_ =0;
    //    secondsDurationLastInArray_ = 0;
    duration_ = kCMTimeInvalid;
    secondsDuration_ = 0;
    secondsBegin_ = 0;
    secondsEnd_ = 0;
    
    //    bgTask_= UIBackgroundTaskInvalid;
}
- (void) changeFlagsForPlay
{
    self.playing = YES;
    
    if(player_.currentItem && CMTIME_IS_INVALID(duration_))
    {
        [self setDurationWithPlayeritem:[player_ currentItem]];
    }
}
- (void) changeFlagForPause
{
    self.playing = NO;
    needAutoPlay_ = NO;
}

#pragma mark - time seconds
-(CMTime) durationWhen{
    return CMTimeMakeWithSeconds(secondsPlaying_, duration_.timescale);
}
- (void) setDurationWhenWithSeconds:(CGFloat)seconds
{
    secondsPlaying_ = seconds;
}
-(CMTime) duration{
    
    if(CMTIME_IS_VALID(duration_))
        return duration_;
    else
        return kCMTimeZero;
}
-(CGFloat) getSecondsEnd
{
    return secondsEnd_;
}
-(CGFloat) getSecondsBegin
{
    return secondsBegin_;
}

- (void)setDurationWithPlayeritem:(AVPlayerItem *)item
{
    if(CMTIME_IS_VALID(item.duration) )
    {
        if((isnan(secondsDuration_)||secondsDuration_<=0))
        {
            duration_ = item.duration;
            secondsDuration_ = CMTimeGetSeconds(duration_);
            if(secondsEnd_<=0 || isnan(secondsEnd_))
            {
                secondsEnd_ = secondsDuration_;
            }
        }
        //        if(self.hasPlayPgrogress && progressView_)
        //        {
        //            [progressView_ setTotalSeconds:secondsDuration_];
        //        }
    }
    else
    {
        NSLog(@"cannot get player item.duration:%llu-%lu",(unsigned long long)item.duration.value,(unsigned long)item.duration.timescale);
    }
}
#pragma mark - player item
//- (void)resetPlayItemKey
//{
//    self.playerItemKey =nil;
//    PP_RELEASE(currentPlayUrl_);
//}
- (void) changeCurrentPlayerItem:(AVPlayerItem *)item
{
    if(playerItem_!=item)
    {
        if(player_.currentItem!=item)
        {
            [self resetPlayer];
        }
        else
        {
            NSLog(@"player item matched,but has error.");
        }
        playerItem_ = item;
        NSLog(@"play item status:%d duration:%.2f",(int)item.status,CMTimeGetSeconds(item.duration));
        
        if([NSThread isMainThread])
        {
            [self buildPlayerContents];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^(void)
                           {
                               [self buildPlayerContents];
                           });
        }
    }
}

- (void)changeCurrentItemUrl:(NSURL *)url
{
    AVURLAsset *movieAsset = nil;
    NSLog(@"play item url:%@",[url absoluteString]);
    
    movieAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    AVPlayerItem * playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
    [self changeCurrentPlayerItem:playerItem];
    
    currentPlayUrl_ = PP_RETAIN(url);
}

-(void) changeCurrentItemPath:(NSString *)path
{
    NSURL * url = [self getUrlFromString:path];
    [self changeCurrentItemUrl:url];
}
- (void)setItemOrgPath:(NSString *)orgPath
{
    PP_RELEASE(orgPath_);
    orgPath_ = PP_RETAIN(orgPath);
}

- (BOOL) isCurrentPath:(NSString *)path
{
    if(!path || path.length==0) return NO;
    //    if(self.playerItemKey && [self.playerItemKey isEqual:path])
    //        return YES;
    if(orgPath_ && [orgPath_ isEqualToString:path])
        return YES;
    //如果敀展名相同也可以的
    
    
    if(!currentPlayUrl_) return NO;
    
    NSString * fullPath = [[self getUrlFromString:path]absoluteString];
    if ([fullPath isEqual:currentPlayUrl_.absoluteString])
        return YES;
    else
        return NO;
}
- (NSURL *)getUrlFromString:(NSString *)urlString
{
    if(urlString)
    {
        if([urlString hasPrefix:@"/"])
            return [NSURL fileURLWithPath:urlString];
        else
            return [NSURL URLWithString:urlString];
    }
    return nil;
}
- (NSURL *)getCurrentUrl
{
    return currentPlayUrl_;
}
#pragma mark - volume set
-(void) setVideoVolume:(float)volume
{
    if(!playerItem_) return;
    if (volume < 0) {
        volume = 0;
    }
    if (volume > 1) {
        volume = 1;
    }
    player_.volume = volume;
    return;
    
    //    AVAsset *asset= [[self.playerItem asset] copy];
    //
    //    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    //
    //    NSMutableArray *allAudioParams = [NSMutableArray array];
    //    for (AVAssetTrack *track in audioTracks) {
    //        AVMutableAudioMixInputParameters *audioInputParams = [AVMutableAudioMixInputParameters audioMixInputParameters];
    //
    //        [audioInputParams setVolume:volume atTime:kCMTimeZero];
    //        [audioInputParams setTrackID:[track trackID]];
    //        [allAudioParams addObject:audioInputParams];
    //    }
    //
    //    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    //    [audioMix setInputParameters:allAudioParams];
    //
    //    [self.playerItem setAudioMix:audioMix];
}
- (CGFloat)getVideoVolumne
{
    if(player_)
    {
        NSLog(@"player volume:%f",player_.volume);
        return player_.volume;
    }
    else
    {
        return 1;
    }
}

#pragma mark - add observer remove observer

-(void) addObserver
{
    if(player_ && !hasObserver_){
        [[player_ currentItem] addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [[player_ currentItem] addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        [[player_ currentItem] addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        
        [player_ addObserver:self
                  forKeyPath:@"rate"
                     options:NSKeyValueObservingOptionNew
                     context:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(avPlayerItemDidPlayToEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:[player_ currentItem]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(avPlayerItemFailedToPlayToEnd:)
                                                     name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                   object:[player_ currentItem]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(avPlayerPlaybackStalled:)
                                                     name:AVPlayerItemPlaybackStalledNotification
                                                   object:[player_ currentItem]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(avPlayerItemTimeJumped:)
                                                     name:AVPlayerItemTimeJumpedNotification
                                                   object:[player_ currentItem]];
        
        __weak HCPlayerSimple *weakSelf = self;
        __block BOOL timerDoing_;
        timerDoing_ = NO;
        timeObserver_ = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 25)
                                                                  queue:NULL
                                                             usingBlock:^(CMTime time){
                                                                 if(weakSelf && !timerDoing_)
                                                                 {
                                                                     timerDoing_ = YES;
                                                                     __strong HCPlayerSimple *strongSelf = weakSelf;
                                                                     
                                                                     
                                                                     CGFloat seconds  = CMTimeGetSeconds(time);
                                                                     [strongSelf setDurationWhenWithSeconds:seconds];
                                                                     
                                                                     [strongSelf videoPlayer:strongSelf
                                                                               timeDidChange:seconds];
                                                                     
                                                                     //                                                                     结束，有可能有小数误差，因此给0.01的值
                                                                     if(secondsEnd_ > 0 && seconds >=secondsEnd_-0.01){
                                                                         //防止发送两次结束，因此，需要检查与最终结束的时长是否很近或相等
                                                                         if(secondsEnd_ + 0.1 < CMTimeGetSeconds([strongSelf.playerItem duration]))
                                                                         {
                                                                             //                                                                         NSLog(@"endtime:%.2f,seconds:%.2f",secondsEnd_,seconds);
                                                                             [strongSelf pause];
                                                                             [strongSelf videoPlayerDidReachEnd:weakSelf];
                                                                         }
                                                                     }
                                                                     timerDoing_ = NO;
                                                                 }
                                                             }];
        hasObserver_ = YES;
    }
}

-(void)clearObserver
{
    if(player_ && hasObserver_){
        
        [[player_ currentItem] removeObserver:self forKeyPath:@"status"];
        [[player_ currentItem] removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [[player_ currentItem] removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [player_ removeObserver:self forKeyPath:@"rate"];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:[player_ currentItem]];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemPlaybackStalledNotification
                                                      object:[player_ currentItem]];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                      object:[player_ currentItem]];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemTimeJumpedNotification
                                                      object:[player_ currentItem]];
        
        if(timeObserver_){
            [player_ removeTimeObserver:timeObserver_];
            timeObserver_ = nil;
        }
        hasObserver_ = NO;
        
    }
}

#pragma mark - observer value
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    
    if ([keyPath isEqualToString:@"status"]) {
        
        if ([playerItem status] == AVPlayerItemStatusReadyToPlay) {
            NSLog(@"player is ready to play!");
            [self videoPlayerIsReadyToPlayVideo:self];
        } else if ([playerItem status] == AVPlayerItemStatusFailed) {
            NSLog(@"%@", playerItem.error);
            [self videoPlayer:self didFailWithError:playerItem.error];
        }else{
            NSLog(@"any other play status,%d",(int)[playerItem status]);
        }
        [self hideActivityView];
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        [self videoPlayer:nil loadedTimeRangeDidChange:CMTimeGetSeconds(playerItem.currentTime)];
        if(needAutoPlay_ && player_.rate<=0){
            [self play:NO];
            needAutoPlay_ = NO;
        }
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){
        if (playerItem.playbackBufferEmpty)
        {
            [self pause];
            needAutoPlay_ = YES;
            [self showActivityView];
            NSLog(@"player item playback buffer is empty");
        }
    }
    else if([keyPath isEqualToString:@"rate"])
    {
        //    if (kRateDidChangeKVO == context) {
        NSLog(@"Player playback rate changed: %.5f seconds:%.1f/%.1f", self.player.rate,secondsPlaying_,secondsDuration_);
        if (self.player.rate == 0.0 && self.playing) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.08 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self checkPause];
            });
        }
    }
}
- (void)checkPause
{
    if(self.player.rate >0 || !self.playing) return;
    if(secondsPlaying_ >= secondsDuration_) //???
    {
        NSLog(@" . . . PAUSED (or)");
        [self showActivityView];
        pauseCount_ ++;
        
        if(pauseCount_>10)
        {
            self.playing = NO;
            if(self.delegate && [self.delegate respondsToSelector:@selector(playerSimple:pausedByUnexpected:item:)])
            {
                __weak HCPlayerSimple * weakSelf = self;
                __weak AVPlayerItem * weakItem = playerItem_;
                dispatch_async(dispatch_get_main_queue(), ^(void)
                               {
                                   [self.delegate playerSimple:weakSelf pausedByUnexpected:nil item:weakItem];
                               });
                
            }
            pauseCount_ = 0;
        }
        else
        {
            [player_ play];
        }
    }
    else
    {
        NSLog(@" . . . PAUSED (or)22");
        if(self.delegate && [self.delegate respondsToSelector:@selector(playerSimple:pausedByUnexpected:item:)])
        {
            __weak HCPlayerSimple * weakSelf = self;
            __weak AVPlayerItem * weakItem = playerItem_;
            dispatch_async(dispatch_get_main_queue(), ^(void)
                           {
                               [self.delegate playerSimple:weakSelf pausedByUnexpected:nil item:weakItem];
                           });
            
        }
    }
}
- (void)avPlayerItemDidPlayToEnd:(NSNotification *)notification
{
    NSLog(@"end...........");
    
    //    historyTime = kCMTimeZero;
    //单个文件播放结束
    //    if(totalItemCount_<2){
    needAutoPlay_ = NO;
    self.playing = NO;
    [self videoPlayerDidReachEnd:self];
    
    //    }
}

-(void)avPlayerPlaybackStalled:(NSNotification *)notification
{
    NSLog(@"media did not arrive in time to continue playback,stalled...........");
    //    [self rememberPlayTime];
    needAutoPlay_ = YES;
    [self showActivityView];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(playerSimple:didStalled:)]){
        [self.delegate  playerSimple:self didStalled:notification.object ];
    }
    
}
- (void)avPlayerItemFailedToPlayToEnd:(NSNotification *)notification
{
    NSLog(@"item has failed to play to its end time:%@",[notification userInfo]);
    if([self.delegate respondsToSelector:@selector(playerSimple:didFailedToPlayToEnd:)])
    {
        [self.delegate playerSimple:self didFailedToPlayToEnd:[notification.userInfo objectForKey:AVPlayerItemFailedToPlayToEndTimeErrorKey]];
    }
}
- (void)avPlayerItemTimeJumped:(NSNotification *)notification
{
    //    NSLog(@"the item's current time has changed discontinuously");
}

- (void)didTapped:(id)sender
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(playerSimple:didTapped:)])
    {
        [self.delegate playerSimple:self didTapped:nil];
    }
}
#pragma mark - videoPlayerDelegate
- (void)videoPlayerIsReadyToPlayVideo:(HCPlayerSimple *)videoPlayer
{
    [self setDurationWithPlayeritem:videoPlayer.playerItem];
    
    if ([videoPlayer.delegate respondsToSelector:@selector(playerSimple:itemReady:)])
    {
        [videoPlayer.delegate playerSimple:videoPlayer itemReady:videoPlayer.playerItem];
    }
}

- (void)videoPlayerDidReachEnd:(HCPlayerSimple *)videoPlayer
{
    if ([videoPlayer.delegate respondsToSelector:@selector(playerSimple:reachEnd:)])
    {
        [videoPlayer.delegate playerSimple:videoPlayer reachEnd:[videoPlayer getSecondsEnd]];
    }
}

- (void)videoPlayer:(HCPlayerSimple *)videoPlayer timeDidChange:(CGFloat)secondsPlaying
{
    [self hideActivityView];
    //显示歌词
    //    if(lyricView && self.lyricView.hidden == NO)
    //    {
    //        [self.lyricView didPlayingWithSecond:secondsPlaying];
    //    }
    
    if ([videoPlayer.delegate respondsToSelector:@selector(playerSimple:timeDidChange:)])
    {
        [videoPlayer.delegate playerSimple:videoPlayer timeDidChange:secondsPlaying];
    }
}

- (void)videoPlayer:(HCPlayerSimple *)videoPlayer loadedTimeRangeDidChange:(float)duration
{
    if ([videoPlayer.delegate respondsToSelector:@selector(playerSimple:loadedTimeRangeDidChange:)])
    {
        [videoPlayer.delegate playerSimple:videoPlayer loadedTimeRangeDidChange:duration];
    }
}

- (void)videoPlayer:(HCPlayerSimple *)videoPlayer didFailWithError:(NSError *)error
{
    if ([videoPlayer.delegate respondsToSelector:@selector(playerSimple:didFailWithError:)])
    {
        [videoPlayer.delegate playerSimple:videoPlayer didFailWithError:error];
    }
}
#pragma mark - change frame
-(void) resizeViewToRect:(CGRect) frame
         andUpdateBounds:(bool) isupdate
           withAnimation:(BOOL)animation
                  hidden:(BOOL)hidden
                 changed:(void (^)(CGRect frame,NSURL * url)) changed
{
    if(CGRectEqualToRect(self.frame, frame) && hidden==self.hidden)
    {
        if(changed)
        {
            changed(frame,currentPlayUrl_);
        }
        return;
    }
    
    if(isupdate){
        self.mainBounds = frame;
    }
    if(animation){
        [UIView animateWithDuration:0.35f animations:^{
            [self setFrame:frame];
            [_playerLayer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
            [self resizeActivityView];
        } completion:^(BOOL finished) {
            if(hidden)
            {
                [UIView animateWithDuration:0.2 animations:^(void)
                 {
                     self.alpha = 0.0;
                 }completion:^(BOOL finished)
                 {
                     self.hidden = YES;
                 }];
            }
            else
            {
                self.alpha = 1;
                self.hidden = NO;
            }
            if(changed)
            {
                changed(frame,currentPlayUrl_);
            }
        }];
    }else{
        [self setFrame:frame];
        [_playerLayer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        if(hidden)
        {
            self.hidden = YES;
        }
        else
        {
            self.hidden = NO;
        }
        self.alpha = 1;
        if(changed)
        {
            changed(frame,currentPlayUrl_);
        }
        [self resizeActivityView];
    }
    
}
#pragma mark - waiting View
- (void)resizeActivityView
{
    if(waitingView_)
    {
        waitingView_.frame = CGRectMake(0, -489.5/2.0f, 887, 489.5);
    }
}
- (void)showActivityView
{
    if(self.isNeverShowWaiting) return ;
    if([NSThread isMainThread])
    {
        if(self.delegate && [self.delegate respondsToSelector:@selector(playerSimple:showWaiting:)])
        {
            [self.delegate playerSimple:self showWaiting:YES];
        }
        else
        {
            
            if(!waitingView_)
            {
                waitingView_ = [[UIImageView alloc]initWithFrame:CGRectMake(0, -489.5/2.0f, 887, 489.5)];
                UIImage * image = [UIImage imageNamed:@"HCPlayer.bundle/playloading.png"];
                waitingView_.image = image;
                waitingView_.backgroundColor = [UIColor clearColor];
                [self addSubview:waitingView_];
                
                waitingTimer_ = PP_RETAIN([NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(moveWaitingView:) userInfo:nil repeats:YES]);
                waitingTimer_.fireDate = [NSDate distantFuture];
                waitingOffset_ = 0;
                
            }
            if(waitingView_.hidden)
            {
                waitingView_.hidden = NO;
                waitingTimer_.fireDate = [NSDate distantPast];
            }
            [self bringSubviewToFront:waitingView_];
            //        [self bringSubviewToFront:self.activityView_];
        }
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^(void)
                       {
                           [self showActivityView];
                       });
    }
}
- (void)hideActivityView
{
    if(self.isNeverShowWaiting) return ;
    if([NSThread isMainThread])
    {
        if(self.delegate && [self.delegate respondsToSelector:@selector(playerSimple:showWaiting:)])
        {
            [self.delegate playerSimple:self showWaiting:NO];
        }
        else
        {
            
            if(waitingView_ && waitingView_.hidden==NO)
            {
                //            [self.activityView_ stopAnimating];
                //            self.activityView_.hidden = YES;
                
                waitingTimer_.fireDate = [NSDate distantFuture];
                waitingView_.hidden = YES;
            }
        }
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^(void)
                       {
                           [self hideActivityView];
                       });
    }
}
- (void)moveWaitingView:(NSTimer *)timer
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       CGRect frame = waitingView_.frame;
                       frame.origin.x -= 5;
                       if(frame.origin.x < - 100)
                       {
                           frame.origin.x = 0;
                       }
                       waitingView_.frame = frame;
                   });
    
}
#pragma mark - helper capture image
- (UIImage *)captureImage
{
    if(!player_) return nil;
    CMTime time = [[player_ currentItem] currentTime];
    AVAsset *asset = [[player_ currentItem] asset];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    imageGenerator.videoComposition = [player_ currentItem].videoComposition;
    
    if ([imageGenerator respondsToSelector:@selector(setRequestedTimeToleranceBefore:)] && [imageGenerator respondsToSelector:@selector(setRequestedTimeToleranceAfter:)]) {
        [imageGenerator setRequestedTimeToleranceBefore:kCMTimeZero];
        [imageGenerator setRequestedTimeToleranceAfter:kCMTimeZero];
    }
    CGImageRef imgRef = [imageGenerator copyCGImageAtTime:time
                                               actualTime:NULL
                                                    error:NULL];
    if (imgRef == nil) {
        if ([imageGenerator respondsToSelector:@selector(setRequestedTimeToleranceBefore:)] && [imageGenerator respondsToSelector:@selector(setRequestedTimeToleranceAfter:)]) {
            [imageGenerator setRequestedTimeToleranceBefore:kCMTimePositiveInfinity];
            [imageGenerator setRequestedTimeToleranceAfter:kCMTimePositiveInfinity];
        }
        imgRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    }
    UIImage *image = [[UIImage alloc] initWithCGImage:imgRef scale:[[UIScreen mainScreen]scale] orientation:UIImageOrientationUp];
    CGImageRelease(imgRef);
    PP_RELEASE(imageGenerator);
    
    //    NSLog(@"capture image: size:%@  scale:%f",NSStringFromCGSize(image.size),image.scale);
    //    NSString * filePath = [[UDManager sharedUDManager]tempFileFullPath:[NSString stringWithFormat:@"%@.jpg",[CommonUtil stringFromDate:[NSDate date] andFormat:@"yyyyMMddhhmmss"]]];
    //
    //    NSLog(@" write to file:%@",filePath);
    //
    //    BOOL result = [UIImagePNGRepresentation(image) writeToFile: filePath atomically:YES]; // 保存成功会返回YES
    return PP_AUTORELEASE(image);
}


#pragma mark - init dealloc
- (void)readyToRelease
{
    [self clearObserver];
    //    [self resetPlayer];
    PP_RELEASE(_delegate);
    sharedPlayerView = nil;
}
- (void)dealloc
{
    NSLog(@"player simple dealloc...");
    [self readyToRelease];
    [self resetPlayer];
    
    PP_SUPERDEALLOC;
}
@end

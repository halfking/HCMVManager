//
//  ActionManagerPogress.m
//  HCMVManager
//
//  Created by HUANGXUTAO on 16/6/7.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "ActionManagerProgress.h"
#import "MediaWithAction.h"
//慢速的颜色：＃00FFFF
//快速的颜色：＃FF5500
#define DEFAULT_TIPS @"长按滤镜为视频增加特效"

@implementation AMProgressItem

- (void)dealloc
{
    _barView = nil;
    _media = nil;
    
    NSLog(@"progressitem release.");
    PP_SUPERDEALLOC;
}

@end

@implementation ActionManagerProgress
- (id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        _barHeight = 2;
        _colorForTrack = [UIColor darkGrayColor];
        _colorForNormal = [UIColor yellowColor];
        _colorForFast = UIColorFromRGB(0xFF5500);
        _colorForSlow = UIColorFromRGB(0x00FFFF);
        _colorForReverse1 = _colorForTrack;
        _colorForReverse2 = _colorForNormal;
        _colorForRepeat = _colorForNormal;
        _durationForFlag = 2;
        _flagImageName = @"flag.png";
        _autoHideFlag = YES;
        _reverseUseNewLine = YES;
        
        defaultMsg_ = DEFAULT_TIPS;
        [self buildViews];
    }
    return self;
}
- (void)showFullTracks
{
    NSArray * mediaList = [manager_ getMediaList];
    if(mediaList)
        mediaList_ = [NSMutableArray arrayWithArray:mediaList];
    else
        mediaList_ = [NSMutableArray array];
    
    if(barBgView_)
    {
        for (UIView * bars in barBgView_.subviews) {
            [bars removeFromSuperview];
        }
        [barViews_ removeAllObjects];
    }
    else
    {
        barBgView_ = [[UIView alloc]initWithFrame:CGRectMake(0, self.frame.size.height -self.barHeight-1, self.frame.size.width, self.barHeight+1)];
        barBgView_.backgroundColor = [UIColor darkGrayColor];
        [self addSubview:barBgView_];
    }
    
    [self buildBarViews:YES];
}
- (void)reset
{
    NSArray * mediaList = [manager_ getMediaList];
    if(mediaList)
        mediaList_ = [NSMutableArray arrayWithArray:mediaList];
    else
        mediaList_ = [NSMutableArray array];
    if(mediaList_.count>0)
        currentMedia_ = [mediaList_ firstObject];
    secondsInArray_ = 0;
    defaultMsg_ = DEFAULT_TIPS;
    msgLabel_.text = defaultMsg_;
    
    if(barBgView_)
    {
        for (UIView * bars in barBgView_.subviews) {
            [bars removeFromSuperview];
        }
        [barViews_ removeAllObjects];
    }
    else
    {
        barBgView_ = [[UIView alloc]initWithFrame:CGRectMake(0, self.frame.size.height -self.barHeight-1, self.frame.size.width, self.barHeight+1)];
        barBgView_.backgroundColor = [UIColor darkGrayColor];
        [self addSubview:barBgView_];
    }
    
    [self buildBarViews:NO];
}
- (void)setManager:(ActionManager *)manager
{
    manager_ = manager;
    NSArray * mediaList = [manager getMediaList];
    if(mediaList)
        mediaList_ = [NSMutableArray arrayWithArray:mediaList];
    else
        mediaList_ = [NSMutableArray array];
    
}
- (void) buildViews
{
    if(!barViews_) barViews_ = [NSMutableArray new];
    if(!msgLabel_)
    {
        UIFont * font = [UIFont boldSystemFontOfSize:17.0f];
        
        msgLabel_ = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 20)];
        msgLabel_.textAlignment = NSTextAlignmentCenter;
        msgLabel_.font = font;
        msgLabel_.shadowColor = UIColorFromRGB(0xa3a3a3);
        msgLabel_.shadowOffset = CGSizeMake(0,0.5);
        msgLabel_.textColor = [UIColor whiteColor];
        msgLabel_.backgroundColor = [UIColor clearColor];
        [self addSubview:msgLabel_];
    }
    
    msgLabel_.text = defaultMsg_;
    
    if(!barBgView_)
    {
        barBgView_ = [[UIView alloc]initWithFrame:CGRectMake(0, self.frame.size.height -self.barHeight-1, self.frame.size.width, self.barHeight+1)];
        barBgView_.backgroundColor = [UIColor darkGrayColor];
        [self addSubview:barBgView_];
    }
    
    [self buildBarViews:NO];
}
- (void)buildBarViews:(BOOL)full
{
    [self clearBarViews];
    
    MediaWithAction * lastMedia = mediaList_ && mediaList_.count>0?[mediaList_ lastObject]:nil;
    CGFloat totalSeconds = lastMedia?lastMedia.secondsEndBeforeReverse>0?lastMedia.secondsEndBeforeReverse:15:15;
    widthPerSeconds_ = self.frame.size.width / totalSeconds;
    
    AMProgressItem * prevItem = nil;
    AMProgressItem * currentItem = nil;
    //查找需要显示旗帜的Repeat
    MediaWithAction * lastRepeat = nil;
    MediaWithAction * prevMedia = nil;
    for (MediaWithAction * media in mediaList_) {
        if(media == currentMedia_ && !full)
        {
            if(media.Action.ActionType == SRepeat)
            {
                lastRepeat = media;
                break;
            }
        }
        else
        {
            if(media.Action.ActionType == SRepeat)
            {
                lastRepeat = media;
            }
        }
        prevMedia = media;
    }
    
    for (MediaWithAction * media in mediaList_) {
        BOOL hasFlag = NO;
        BOOL buildFlag = lastRepeat && lastRepeat == media;
        
        UIView * v = [self buildBarView:media hasFlag:&hasFlag full:full buildFlag:full || buildFlag];
        if(!v)
        {
            NSLog(@"view cannot be nil....");
            continue;
        }
        {
            AMProgressItem * item = [[AMProgressItem alloc]init];
            item.media = media;
            item.barView = v;
            item.hasFlag = hasFlag;
            [barViews_ addObject:item];
            [barBgView_ addSubview:v];
            
            //            [self showProgress:item prevItem:prevItem secondsInArray:media.secondsInArray checkAll:NO];
            
            prevItem =currentItem;
            currentItem = item;
        }
        if(!full && (media == currentMedia_ || !currentMedia_)) break;
    }
    if(currentMedia_)
    {
        [self showProgress:currentItem prevItem:prevItem secondsInArray:currentMedia_.secondsInArray checkAll:YES];
    }
    else
    {
        [self showProgress:currentItem prevItem:prevItem secondsInArray:0 checkAll:YES];
    }
}
//- (void)checkPreMediaWidth:(MediaWithAction *)media prevMedia:(MediaWithAction *)prevMedia checkCurrentWidth:(BOOL)checkCurrentWidth
//{
//    NSLog(@" progress check prev media width....");
//    if(!prevMedia) return;
//    //Repeat 需要将之前的进度缩回去
//    if(media.Action.ActionType==SRepeat)
//    {
//        CGFloat pos = roundf(media.secondsBeginBeforeReverse * widthPerSeconds_+0.5);
//        BOOL isMatch = NO;
//        for (int i = (int)mediaList_.count-1; i>=0; i --) {
//            MediaWithAction * mm = mediaList_[i];
//            if(mm==media)
//            {
//                isMatch = YES;
//                continue;
//            }
//            if(isMatch)
//            {
//                //                if(barViews_.count>i)
//                //                {
//                int viewCount = MIN((int)barViews_.count-1,i);
//                for (int j =viewCount; j>=0; j--) {
//                    AMProgressItem * dic = barViews_[j];
//
//
//                    MediaWithAction * item = dic.media;
//                    if(item !=media || checkCurrentWidth)
//                    {
//                        UIView * prevView = dic.barView;
//                        CGRect frame = prevView.frame;
//                        frame.size.width = roundf(item.secondsDurationInArray * widthPerSeconds_+0.5);
//
//                        if(frame.origin.x > pos)
//                        {
//                            frame.size.width = 0;
//                        }
//                        else if(frame.origin.x + frame.size.width >pos)
//                        {
//                            CGFloat diff = pos - frame.origin.x;
//                            frame.size.width = diff;
//                        }
//                        prevView.frame = frame;
//                    }
//                }
//                for (int j = viewCount +1; j<barViews_.count; j ++) {
//                    AMProgressItem * item  = barViews_[j];
//                    CGRect frame = item.barView.frame;
//                    frame.size.width = 0;
//                    item.barView.frame = frame;
//                }
//                //                }
//                break;
//            }
//        }
//    }
//    else
//    {
//        //处理最后一个的长度，但不是当前对像
//        AMProgressItem * dic = nil;//[barViews_ lastObject];
//
//        for (AMProgressItem * item  in barViews_) {
//            if(item.media == currentMedia_)
//            {
//                dic = item;
//                break;
//            }
//        }
//        if(checkCurrentWidth)
//        {
//            UIView * v = dic.barView;
//            MediaWithAction * lastMedia = dic.media;
//            CGRect frame = v.frame;
//            CGFloat width = roundf(lastMedia.secondsDurationInArray * widthPerSeconds_+0.5);
//            if(lastMedia.rateBeforeReverse <0)
//            {
//                CGFloat pos = roundf(widthPerSeconds_ * media.secondsBeginBeforeReverse + 0.5);
//                frame.origin.x = pos - width;
//                frame.size.width =  width;
//            }
//            else
//            {
//                CGFloat pos = roundf(widthPerSeconds_ * media.secondsBeginBeforeReverse + 0.5);
//                frame.origin.x = pos;
//                frame.size.width = width;
//            }
//            v.frame = frame;
//        }
//        //处理之前的宽度
//        BOOL isBefore = YES;
//        for (AMProgressItem * item in barViews_) {
//            if(item == dic)
//            {
//                isBefore = NO;
//                continue;
//            }
//            CGRect frame = item.barView.frame;
//            if(isBefore)
//            {
//                if(item.media.rateBeforeReverse <0)
//                {
//                    if(frame.size.width >0)
//                    {
//                        frame.size.width = 0;
//                        item.barView.frame = frame;
//                    }
//                }
//                else
//                {
//                    CGFloat width = roundf(item.media.secondsDurationInArray * widthPerSeconds_+0.5);
//                    CGFloat pos = roundf(widthPerSeconds_ * item.media.secondsBeginBeforeReverse + 0.5);
//                    if(frame.origin.x != pos || frame.size.width != width)
//                    {
//                        frame.origin.x = pos;
//                        frame.size.width = width;
//                        item.barView.frame = frame;
//                    }
//                }
//            }
//            else
//            {
//                if(frame.size.width >0)
//                {
//                    frame.size.width = 0;
//                    item.barView.frame = frame;
//                }
//            }
//        }
//    }
//}
- (void)clearBarViews
{
    NSLog(@"AP : clear bar views");
    for (UIView * subView in barBgView_.subviews) {
        [subView removeFromSuperview];
    }
    [barViews_ removeAllObjects];
    //    NSArray * mediaList = [manager_ getMediaList];
    //    if(mediaList)
    //        mediaList_ = [NSMutableArray arrayWithArray:mediaList];
    //    else
    //        mediaList_ = [NSMutableArray array];
}
- (void) addBarView:(MediaWithAction *)media
{
    if([NSThread isMainThread])
    {
        NSLog(@" progress add barview %@",[media toString]);
        BOOL isFind = NO;
        AMProgressItem * prevItem = nil;
        AMProgressItem * currentItem = nil;
        for (AMProgressItem * mm in barViews_) {
            if(mm.media == media)
            {
                currentItem = mm;
                isFind = YES;
                break;
            }
            prevItem = mm;
        }
        if(isFind)
        {
            [self showProgress:currentItem prevItem:prevItem secondsInArray:media.secondsInArray checkAll:NO];
        }
        else
        {
            //            [self checkPreMediaWidth:media prevMedia:prevMedia checkCurrentWidth:NO];
            
            BOOL hasFlag = NO;
            UIView * barView =[self buildBarView:media hasFlag:&hasFlag full:NO buildFlag:YES];
            if(barView)
            {
                AMProgressItem * item = [[AMProgressItem alloc]init];
                item.media = media;
                item.barView = barView;
                item.hasFlag = hasFlag;
                [barViews_ addObject:item];
                [barBgView_ addSubview:barView];
                
                [self showProgress:currentItem prevItem:prevItem secondsInArray:media.secondsInArray checkAll:NO];
                
                item = nil;
            }
        }
        [self checkFlagIsValid:media.secondsInArray];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addBarView:media];
        });
    }
}
// 显示具体的一个Bar，如果Bar属于当前正在处理的素材，则长度只显示1，由PlayerSeconds事件来决定显示多长
// full 表示是否需要不考虑上述的条件，即直接显示全长
- (UIView *)buildBarView:(MediaWithAction *)media hasFlag:(BOOL *)hasFlag full:(BOOL)full buildFlag:(BOOL)buildFlag
{
    CGFloat left = roundf(media.secondsBeginBeforeReverse * widthPerSeconds_+0.5);
    CGFloat top = (barBgView_.frame.size.height - self.barHeight)/2.0f;
    UIView * barView = nil;
    CGFloat width = roundf(widthPerSeconds_ * media.secondsDurationInArray + 0.5);
    CGRect frame = CGRectMake(left, top, width, self.barHeight) ;
    if(media!=currentMedia_ && currentMedia_)
    {
        if(media.Action.ActionType == SReverse)
        {
            frame.origin.x = left - frame.size.width;
            
        }
        else if(media.Action.ActionType == SRepeat)
        {
            //            frame.size.width = 1;
        }
        //        frame.origin.x += 0.5;
        
        barView = [[UIView alloc]initWithFrame:frame];
        barView.backgroundColor = [self getColorForMedia:media];
        
        if(hasFlag)
        {
            *hasFlag = NO;
        }
        
        if(buildFlag &&
           media.Action.ActionType == SRepeat
           && (secondsInArray_ - media.secondsInArray <self.durationForFlag + 0.01 && secondsInArray_ - media.secondsInArray + 0.01 >=0)
           && _flagImageName)
        {
            NSLog(@"AP : show type:%d flag:%f media:%f frame:%@",media.Action.ActionType,secondsInArray_,media.secondsInArray,NSStringFromCGRect(barView.frame));
            
            UIImageView * imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, top - 14, 7.5, 16)];
            imageView.image = [UIImage imageNamed:_flagImageName];
            [barView addSubview:imageView];
            if(hasFlag)
            {
                *hasFlag = YES;
            }
            //移除之前的对像的旗帜
            [self removeFlagBeforeIndex:-1];
        }
    }
    else
    {
        frame.origin.x = left;// + 0.5;
        if(!full)
            frame.size.width = 1;
        barView = [[UIView alloc]initWithFrame:frame];
        barView.backgroundColor = [self getColorForMedia:media];
        
        if(hasFlag)
        {
            *hasFlag = NO;
        }
        if(media.Action.ActionType == SRepeat)
        {
            //            当前对像或在时间范围内
            if( (media==currentMedia_ ||
                 (secondsInArray_ - media.secondsInArray <self.durationForFlag +0.01 && secondsInArray_ - media.secondsInArray + 0.01 >=0))
               && _flagImageName)
            {
                UIImageView * imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, top - 14, 7.5, 16)];
                imageView.image = [UIImage imageNamed:_flagImageName];
                
                [barView addSubview:imageView];
                if(hasFlag)
                {
                    *hasFlag = YES;
                }
            }
            
        }
    }
    NSLog(@"build barview :%@",NSStringFromCGRect(barView.frame));
    return barView;
}
- (void)refresh
{
    if([NSThread isMainThread])
    {
        NSLog(@" progress refresh.....");
        //        if(!barBgView_)
        //        {
        [self buildViews];
        //        }
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refresh];
        });
    }
}
- (void)removeFlagBeforeIndex:(int)index
{
    int i = 0;
    if(index <0) index = 99999;
    
    for (AMProgressItem * dic in barViews_) {
        MediaWithAction * media = dic.media;
        BOOL hasFlag = dic.hasFlag;
        if(hasFlag && media.Action.ActionType==SRepeat)
        {
            if(i < index)
            {
                UIView * view = dic.barView;
                for (UIView * subView in view.subviews) {
                    [subView removeFromSuperview];
                }
                dic.hasFlag = NO;
            }
            i ++;
        }
    }
}
- (void)checkFlagIsValid:(CGFloat)secondsInArray
{
    if(!_autoHideFlag) return ;
    
    for (AMProgressItem * dic in barViews_) {
        MediaWithAction * media = dic.media;
        BOOL hasFlag = dic.hasFlag;
        if(hasFlag && media.Action.ActionType==SRepeat)
        {
            //            超时的，非当前对像的，不显示
            if((secondsInArray- media.secondsInArray +0.01>self.durationForFlag)
               ||
               secondsInArray < media.secondsInArray
               ||(currentMedia_ && currentMedia_!=media))
            {
                UIView * view = dic.barView;
                for (UIView * subView in view.subviews) {
                    [subView removeFromSuperview];
                }
                dic.hasFlag = NO;
            }
        }
    }
}

- (void)setCurrentMedia:(MediaWithAction *)media
{
    if(!media)
    {
        if(mediaList_.count>0)
            currentMedia_ = [mediaList_ firstObject];
        secondsInArray_ = currentMedia_?currentMedia_.secondsInArray:0;
        [self refresh];
    }
    else
    {
        currentMedia_ = media;
        secondsInArray_ = currentMedia_.secondsInArray;
        
        //检查数据是否发生过变化
        if(mediaList_.count != [manager_ getMediaList].count)
        {
            [mediaList_ removeAllObjects];
            [mediaList_ addObjectsFromArray:[manager_ getMediaList]];
            [self refresh];
        }
        else
        {
            [self addBarView:media];
        }
    }
    
    if(secondsInArray_ < currentMedia_.secondsInArray)
        secondsInArray_ = currentMedia_.secondsInArray;
    
    defaultMsg_ = [self getTipsForMedia:currentMedia_];
    
    if([NSThread isMainThread])
    {
        msgLabel_.text = defaultMsg_;
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            msgLabel_.text = defaultMsg_;
        });
    }
}
- (void)setPlaySeconds:(CGFloat)playerSeconds secondsInArray:(CGFloat)secondsInArray
{
    if([NSThread isMainThread])
    {
        secondsInArray_ = secondsInArray;
        
        if(!currentMedia_ && mediaList_.count>0) currentMedia_ = [mediaList_ firstObject];
        if(!currentMedia_) return ;
        
        AMProgressItem * prevAmp = nil;
        AMProgressItem * currentAmp = nil;
        for (AMProgressItem * item in barViews_) {
            if(item.media == currentMedia_)
            {
                currentAmp = item;
                break;
            }
            prevAmp = item;
        }
        [self showProgress:currentAmp prevItem:prevAmp secondsInArray:(CGFloat)secondsInArray checkAll:NO];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setPlaySeconds:playerSeconds secondsInArray:secondsInArray];
        });
    }
    
}
- (void)showProgress:(AMProgressItem *)ampItem prevItem :(AMProgressItem *)prevAmp secondsInArray:(CGFloat)secondsInArray checkAll:(BOOL)checkAll
{
    if(!ampItem) return;
    
    CGRect frame = ampItem.barView.frame;
    if(secondsInArray <0) secondsInArray = ampItem.media.secondsInArray + fabs(ampItem.media.secondsDurationInArray);
    
    CGFloat duration = secondsInArray - ampItem.media.secondsInArray;
    if(duration <0)
    {
        NSLog(@"AP : duration<  0 !!!!");
        return;
    }
    
    //处理之前的宽度
    CGFloat currentPos = roundf(ampItem.media.secondsBeginBeforeReverse * widthPerSeconds_+0.5);
    
    //倒放时，x是变化的
    if(ampItem.media.rateBeforeReverse <0)
    {
        currentPos = roundf((ampItem.media.secondsBeginBeforeReverse - duration)  * widthPerSeconds_+0.5);
    }
    
    BOOL isBefore = YES;
    for (AMProgressItem * item in barViews_) {
        if(item == ampItem)
        {
            isBefore = NO;
            continue;
        }
        CGRect frame = item.barView.frame;
        if(isBefore)
        {
            //远处的就不需要处理了
            if(!checkAll &&
               (
                (item.media.rateBeforeReverse >0 &&
                 item.media.secondsEndBeforeReverse < ampItem.media.secondsEndBeforeReverse
                 && item.media.secondsEndBeforeReverse < ampItem.media.secondsBeginBeforeReverse)
                ||(item.media.rateBeforeReverse <0 &&
                   item.media.secondsBeginBeforeReverse < ampItem.media.secondsEndBeforeReverse
                   && item.media.secondsBeginBeforeReverse < ampItem.media.secondsBeginBeforeReverse)
                )
               && (!prevAmp || item !=prevAmp)
               )
            {
                continue;
            }
            if(item.media.rateBeforeReverse <0)
            {
                //                if(frame.size.width >0)
                //                {
                frame.origin.x = roundf(item.media.secondsEndBeforeReverse * widthPerSeconds_+0.5);
                frame.size.width = roundf(item.media.secondsDurationInArray * widthPerSeconds_ + 0.5);
                item.barView.frame = frame;
                //                }
            }
            else
            {
                CGFloat width = roundf(item.media.secondsDurationInArray * widthPerSeconds_+0.5);
                CGFloat pos = roundf(widthPerSeconds_ * item.media.secondsBeginBeforeReverse + 0.5);
                if(frame.origin.x != pos || frame.origin.x != currentPos || frame.size.width != width)
                {
                    frame.origin.x = pos;
                    frame.size.width = width;
                    if(frame.size.width + frame.origin.x > currentPos)
                    {
                        frame.size.width = MAX(currentPos - frame.origin.x, 0);
                    }
                    item.barView.frame = frame;
                }
            }
        }
        else
        {
            if(!checkAll) break;
            
            if(frame.size.width >0)
            {
                frame.size.width = 0;
                item.barView.frame = frame;
            }
        }
    }
    //如果当前是倒放
    if(ampItem.media.rateBeforeReverse <0)
    {
        CGFloat width = roundf(duration * widthPerSeconds_ +0.5);
        CGFloat x = currentPos;
        if(prevAmp)
        {
            CGFloat x1 = prevAmp.barView.frame.origin.x + prevAmp.barView.frame.size.width - width;
            if(x1 < x)
            {
                x = x1;
            }
        }
        
        if(width<0) width = 1;
        frame.origin.x = x;
        frame.size.width = width;
    }
    else
    {
        CGFloat x = currentPos;
        CGFloat width = roundf(duration * widthPerSeconds_ + 0.5);
        if(prevAmp)
        {
            //对齐，防止有间隙
            if(prevAmp.media.Action.ActionType==SReverse && prevAmp.media.rateBeforeReverse <0)
            {
                x = prevAmp.barView.frame.origin.x;
            }
            else if(x > prevAmp.barView.frame.origin.x + prevAmp.barView.frame.size.width)
            {
                x = prevAmp.barView.frame.origin.x + prevAmp.barView.frame.size.width;
            }
        }
        
        frame.origin.x = x;
        frame.size.width = width;
    }
    ampItem.barView.frame = frame;
    
    
    //    [self checkPreMediaWidth:lastmedia prevMedia:preViewMedia checkCurrentWidth:NO];
    
    //        if(lastmedia.Action.ActionType==SRepeat)
    //            NSLog(@" --- playerseconds %f -----\n view for %@ \n frame:%@",playerSeconds,[lastmedia toString],NSStringFromCGRect(frame));
    [self checkFlagIsValid:secondsInArray];
}
- (void)setMsgString:(NSString *)msg
{
    defaultMsg_ = msg;
    if(msgLabel_)
    {
        msgLabel_.text = msg;
    }
}
- (UIColor *) getColorForMedia:(MediaWithAction *)media
{
    if(media.Action.ActionType == SReverse)
    {
        if(media.rateBeforeReverse <0)
            return _colorForReverse1;
        else
            return _colorForReverse2;
    }
    else if(media.Action.ActionType ==SSlow)
        return _colorForSlow;
    else if(media.Action.ActionType == SFast)
        return _colorForFast;
    else if(media.Action.ActionType == SRepeat)
        return _colorForRepeat;//[UIColor redColor];
    else
        return _colorForNormal;
}
- (NSString *) getTipsForMedia:(MediaWithAction *)media
{
    NSString * tips = nil;
    if(media.Action.ActionType==SSlow)
    {
        tips = @"慢放中...";
    }
    else if(media.Action.ActionType == SFast)
    {
        tips = @"快进中...";
    }
    else if(media.Action.ActionType == SRepeat)
    {
        tips = @"可以多次点击哦~";
    }
    else if(media.Action.ActionType == SReverse && media.rateBeforeReverse < 0)
    {
        tips = @"倒带中...";
    }
    else
    {
        tips = @"长按滤镜为视频添加特效";
    }
    return tips;
}
- (void)dealloc
{
    manager_ = nil;
    mediaList_ = nil;
    barViews_ = nil;
    barBgView_ = nil;
    PP_SUPERDEALLOC;
}
@end

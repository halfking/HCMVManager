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
        _durationForFlag = 2;
        _flagImageName = @"flag.png";
        _autoHideFlag = YES;
        
        defaultMsg_ = DEFAULT_TIPS;
        [self buildViews];
    }
    return self;
}
- (void)reset
{
    NSArray * mediaList = [manager_ getMediaList];
    if(mediaList)
        mediaList_ = [NSMutableArray arrayWithArray:mediaList];
    else
        mediaList_ = [NSMutableArray array];
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
    
    [self buildBarViews:YES];
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
    
    MediaWithAction * prevMedia = nil;
    for (MediaWithAction * media in mediaList_) {
        BOOL hasFlag = NO;
        UIView * v = [self buildBarView:media hasFlag:&hasFlag];
        if(!v)
        {
            NSLog(@"view cannot be nil....");
            continue;
        }
        {
            NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:media,@"media",
                                         v,@"view",
                                         [NSNumber numberWithBool:hasFlag],@"flag", nil];
            [barViews_ addObject:dic];
            [barBgView_ addSubview:v];
            
            if(media == currentMedia_ && !full)
            {
                [self checkPreMediaWidth:media prevMedia:prevMedia];
            }
            if(!full && (media == currentMedia_ || !currentMedia_)) break;
        }
        prevMedia = media;
    }
}
- (void)checkPreMediaWidth:(MediaWithAction *)media prevMedia:(MediaWithAction *)prevMedia
{
    NSLog(@" progress check prev media width....");
    if(!prevMedia) return;
    //Repeat 需要将之前的进度缩回去
    if(media.Action.ActionType==SRepeat)
    {
        CGFloat pos = media.secondsBeginBeforeReverse * widthPerSeconds_;
        BOOL isMatch = NO;
        for (int i = (int)mediaList_.count-1; i>=0; i --) {
            MediaWithAction * mm = mediaList_[i];
            if(mm==media)
            {
                isMatch = YES;
                continue;
            }
            if(isMatch)
            {
                //                if(barViews_.count>i)
                //                {
                int viewCount = MIN((int)barViews_.count-1,i);
                for (int j =viewCount; j>=0; j--) {
                    NSDictionary * dic = barViews_[j];
                    
                    UIView * prevView = [dic objectForKey:@"view"];
                    MediaWithAction * item = [dic objectForKey:@"media"];
                    
                    CGRect frame = prevView.frame;
                    frame.size.width = item.secondsDurationInArray * widthPerSeconds_;
                    
                    if(frame.origin.x > pos)
                    {
                        frame.size.width = 0;
                    }
                    else if(frame.origin.x + frame.size.width >pos)
                    {
                        CGFloat diff = pos - frame.origin.x;
                        frame.size.width = diff;
                    }
                    prevView.frame = frame;
                }
                //                }
                break;
            }
        }
    }
    else
    {
        //处理最后一个的长度
        NSDictionary * dic = [barViews_ lastObject];
        UIView * v = [dic objectForKey:@"view"];
        MediaWithAction * lastMedia = [dic objectForKey:@"media"];
        CGRect frame = v.frame;
        CGFloat width = lastMedia.secondsDurationInArray * widthPerSeconds_;
        if(lastMedia.rateBeforeReverse <0)
        {
            frame.origin.x = lastMedia.secondsBeginBeforeReverse * widthPerSeconds_ - width;
            frame.size.width =  width;
        }
        else
        {
            frame.origin.x = lastMedia.secondsBeginBeforeReverse * widthPerSeconds_;
            frame.size.width = width;
        }
        v.frame = frame;
    }
}
- (void)clearBarViews
{
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
        int index = 0;
        MediaWithAction * prevMedia = nil;
        for (MediaWithAction * mm in mediaList_) {
            if(mm == media) break;
            prevMedia = mm;
            index ++;
        }
//        if(index ==0)
//        {
//            [self clearBarViews];
//        }
        
        if(barViews_.count <= index)
        {
            [self checkPreMediaWidth:media prevMedia:prevMedia];
            
            BOOL hasFlag = NO;
            UIView * barView =[self buildBarView:media hasFlag:&hasFlag];
            if(barView)
            {
                NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:media,@"media",
                                             barView,@"view",
                                             [NSNumber numberWithBool:hasFlag],@"flag", nil];
                [barViews_ addObject:dic];
                [barBgView_ addSubview:barView];
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
- (UIView *)buildBarView:(MediaWithAction *)media hasFlag:(BOOL *)hasFlag
{
    CGFloat left = media.secondsBeginBeforeReverse * widthPerSeconds_;
    CGFloat top = (barBgView_.frame.size.height - self.barHeight)/2.0f;
    UIView * barView = nil;
    CGRect frame = CGRectMake(left, top, widthPerSeconds_ * media.secondsDurationInArray, self.barHeight) ;
    if(media!=currentMedia_ && currentMedia_)
    {
        if(media.Action.ActionType == SReverse)
        {
            frame.origin.x = left - frame.size.width;
            
        }
        else if(media.Action.ActionType == SRepeat)
        {
            
            frame.size.width = 1;
        }
        barView = [[UIView alloc]initWithFrame:frame];
        barView.backgroundColor = [self getColorForMedia:media];
        
        if(hasFlag)
        {
            *hasFlag = NO;
        }
        
        if(media.Action.ActionType == SRepeat && media.secondsInArray - secondsInArray_ <=2 && _flagImageName)
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
    else
    {
        frame.origin.x = left;
        frame.size.width = 1;
        barView = [[UIView alloc]initWithFrame:frame];
        barView.backgroundColor = [self getColorForMedia:media];
        
        if(hasFlag)
        {
            *hasFlag = NO;
        }
        if(media.Action.ActionType == SRepeat)
        {
            if(media.secondsInArray - secondsInArray_ <=2 && _flagImageName)
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

- (void)checkFlagIsValid:(CGFloat)secondsInArray
{
    if(!_autoHideFlag) return ;
    
    for (NSMutableDictionary * dic in barViews_) {
        MediaWithAction * media = [dic objectForKey:@"media"];
        BOOL hasFlag = [[dic objectForKey:@"flag"]boolValue];
        if(hasFlag && media.Action.ActionType==SRepeat)
        {
            if(secondsInArray- media.secondsInArray>self.durationForFlag)
            {
                UIView * view = [dic objectForKey:@"view"];
                for (UIView * subView in view.subviews) {
                    [subView removeFromSuperview];
                }
                [dic setObject:[NSNumber numberWithBool:NO] forKey:@"flag"];
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
        [self refresh];
    }
    else
    {
        currentMedia_ = media;
        
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
        
        if(!barViews_||barViews_.count==0 ||!currentMedia_) return;
        int index = 0;
        if(currentMedia_)
        {
            for (MediaWithAction * item in mediaList_) {
                if(item == currentMedia_)
                {
                    break;
                }
                index ++;
            }
            if(index >= barViews_.count)
            {
                index = (int)barViews_.count-1;
            }
        }
        NSDictionary * dic = [barViews_ objectAtIndex:index];
        UIView * barView = [dic objectForKey:@"view"];
        MediaWithAction * lastmedia = [dic objectForKey:@"media"];
        
        CGRect frame = barView.frame;
        
        if(lastmedia.rateBeforeReverse <0)
        {
            CGFloat width = (lastmedia.secondsBeginBeforeReverse - playerSeconds) * widthPerSeconds_;
            if(width<0) width = 0;
            frame.origin.x = lastmedia.secondsBeginBeforeReverse * widthPerSeconds_ - width;
            frame.size.width = width;
        }
        else
        {
            frame.origin.x = lastmedia.secondsBeginBeforeReverse * widthPerSeconds_;
            frame.size.width = (playerSeconds - lastmedia.secondsBeginBeforeReverse) * widthPerSeconds_;
        }
        barView.frame = frame;
        if(lastmedia.Action.ActionType==SRepeat)
            NSLog(@" --- playerseconds %f -----\n view for %@ \n frame:%@",playerSeconds,[lastmedia toString],NSStringFromCGRect(frame));
        [self checkFlagIsValid:secondsInArray];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setPlaySeconds:playerSeconds secondsInArray:secondsInArray];
        });
    }
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
        return _colorForTrack;
    else if(media.Action.ActionType ==SSlow)
        return _colorForSlow;
    else if(media.Action.ActionType == SFast)
        return _colorForFast;
    else if(media.Action.ActionType == SRepeat)
        return [UIColor redColor];
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
    else if(media.Action.ActionType == SReverse)
    {
        tips = @"倒带中...";
    }
    else
    {
        tips = @"长按滤镜为视频添加特效";
    }
    return tips;
}
@end

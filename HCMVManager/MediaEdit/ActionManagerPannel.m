//
//  ActionManagerPannel.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/20.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "ActionManagerPannel.h"
#import "ActionManager.h"
#import "MediaWithAction.h"
#import "MediaActionDo.h"
#import "MediaItem.h"

@interface ActionManagerPannel()
{
    ActionManager * manager_;
    CGFloat leftMargin_;
    CGFloat rightMargin_;
    CGFloat contentWidth_;
    CGFloat baseWidth_;
    CGFloat rowHeight_;
    CGFloat top_;
    CGFloat scaleItemWidth_;
}
@end
@implementation ActionManagerPannel
- (id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        leftMargin_ = 10;
        rightMargin_ = 10;
        top_ = 10;
        contentWidth_ = frame.size.width - leftMargin_ -rightMargin_;
        baseWidth_ = (int)(contentWidth_ * 2/3);
        rowHeight_ = 20;
        scaleItemWidth_ = baseWidth_/10;
    }
    return self;
}
- (void) refresh
{
    for (UIView * v in self.subviews) {
        [v removeFromSuperview];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self buildViews];
    });
}
- (void) setActionManager:(ActionManager *)actionManager
{
    manager_ = actionManager;
    top_ = 10;
    for (UIView * v in self.subviews) {
        [v removeFromSuperview];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self buildViews];
    });
}

- (void) buildViews
{
    MediaItem * bgVideo = [manager_ getBaseVideo];
    scaleItemWidth_ = (int)(baseWidth_/ (int)(bgVideo.secondsDurationInArray / 2.0 +0.5)+0.5);
    [self buildBaseLine:bgVideo];
    
    //    NSArray * actionList = [manager_ getActionList];
    NSArray * mediaList = [manager_ getMediaList];
    //    for (MediaActionDo * action in actionList) {
    //        [self buildActionView:action mediaList:mediaList];
    //    }
    int index =1;
    CGFloat top = top_ + 40;
    for (MediaWithAction * item in mediaList) {
        [self buildMediaItemView:item index:index top:top];
        index ++;
        top += 40;
    }
    
}
- (void) buildMediaItemView:(MediaWithAction *)item index:(int)index top:(CGFloat)top
{
    UIColor * color = [UIColor blueColor];
    if(item.Action.ActionType == SNormal)
    {
        color = [UIColor greenColor];
    }
    CGFloat left = leftMargin_ + 30 + scaleItemWidth_ * item.secondsInArray/2.0f;
    CGFloat width = scaleItemWidth_ * item.secondsDurationInArray/2.0f;
    
    UIView * line = [self buildLineWithScale:CGRectMake(left , top, width, 20)
                                        diff:scaleItemWidth_
                                       color:color
                                       label:[NSString stringWithFormat:@"%d-%d",index,item.Action.ActionType]
                                       begin:[NSString stringWithFormat:@"%.2f",item.secondsInArray]
                                         end:[NSString stringWithFormat:@"%.2f",item.secondsDurationInArray + item.secondsInArray]
                                 sourceBegin:[NSString stringWithFormat:@"%.2f",item.secondsBegin]
                                   sourceEnd:[NSString stringWithFormat:@"%.2f",item.secondsEnd]
                     rightText:[NSString stringWithFormat:@"(%.2f/%.2f)",item.durationInPlaying,item.secondsDurationInArray]
                     ];
    [self addSubview:line];
}
- (void) buildActionView:(MediaActionDo*)action mediaList:(NSArray *)mediaList
{
    
}
- (UIView *) buildActionIconView:(MediaActionDo *)action
{
    
    //    UIView * view = [UIView alloc]initWithFrame:CGRectMake(<#CGFloat x#>, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>)
    return nil;
}

#pragma mark - base line
- (void) buildBaseLine:(MediaItem *)media
{
    UIView * line = [self buildLineWithScale:CGRectMake(leftMargin_ + 30 , top_, baseWidth_, 20)
                                        diff:scaleItemWidth_
                                       color:[UIColor blueColor]
                                       label:@"Base"
                                       begin:@"00"
                                         end:[NSString stringWithFormat:@"%.2f",media.secondsDurationInArray]
                                 sourceBegin:[NSString stringWithFormat:@"%.2f",media.secondsBegin]
                                   sourceEnd:[NSString stringWithFormat:@"%.2f",media.secondsEnd]
                                   rightText:[NSString stringWithFormat:@"(%.2f)",media.secondsDurationInArray/(media.playRate>0?media.playRate:1)]
                     ];
    [self addSubview:line];
}
- (UIView *) buildLineWithScale:(CGRect)frame diff:(CGFloat)diff color:(UIColor *)color
                          label:(NSString *)lable
                          begin:(NSString *)beginText
                            end:(NSString *)endtext
                    sourceBegin:(NSString *)sourceBeginText
                      sourceEnd:(NSString *)sourceEndText
                      rightText:(NSString *)rightText
{
    CGFloat leftMargin = 30;
    UIFont * font = [UIFont systemFontOfSize:10];
    int count = 0;
    if(diff>0)
    {
        count = (int)((frame.size.width)/diff+ 0.5);
        frame.size.width = (int)(diff * count);
    }
    UIView * containerView = [[UIView alloc]initWithFrame:frame];
    {
        if(lable && lable.length>0)
        {
            UILabel * titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0 - leftMargin, frame.size.height - 10, 50, 10)];
            titleLabel.font = font;
            titleLabel.text = lable;
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.backgroundColor = [UIColor clearColor];
            [containerView addSubview:titleLabel];
        }
        UIView * line = [[UIView alloc]initWithFrame:CGRectMake(0, frame.size.height - 5, frame.size.width, 2)];
        line.backgroundColor = color;
        [containerView addSubview:line];
        
        if(rightText && rightText.length>0)
        {
            UILabel * titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(frame.size.width + 20, frame.size.height - 10, 100, 10)];
            titleLabel.font = font;
            titleLabel.text = rightText;
            titleLabel.textColor = [UIColor redColor];
            titleLabel.backgroundColor = [UIColor clearColor];
            [containerView addSubview:titleLabel];
        }
    }
    
    //build scale
    CGFloat top = frame.size.height - 10;
    CGFloat scaleHeight = 5;
    CGFloat x = 0;
    for (int i = 0; i<=count; i ++) {
        if(i==0)
        {
            if(beginText && beginText.length>0)
            {
                UILabel * titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(x - 5, top - 10, 50, 10)];
                titleLabel.font = font;
                titleLabel.text = beginText;
                titleLabel.textColor = [UIColor whiteColor];
                titleLabel.backgroundColor = [UIColor clearColor];
                [containerView addSubview:titleLabel];
            }
            UIView * scaleItem = [[UIView alloc]initWithFrame:CGRectMake(x, top, 1, scaleHeight)];
            scaleItem.backgroundColor = [UIColor whiteColor];
            [containerView addSubview:scaleItem];
            
            if(sourceBeginText && sourceBeginText.length>0)
            {
                UILabel * titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(x - 5, top +4, 50, 10)];
                titleLabel.font = font;
                titleLabel.text = sourceBeginText;
                titleLabel.textColor = [UIColor yellowColor];
                titleLabel.backgroundColor = [UIColor clearColor];
                [containerView addSubview:titleLabel];
            }
        }
        else if(i==count)
        {
            if(endtext && endtext.length>0)
            {
                UILabel * titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(x - 5, top - 10, 50, 10)];
                titleLabel.font = font;
                titleLabel.text = endtext;
                titleLabel.textColor = [UIColor whiteColor];
                titleLabel.backgroundColor = [UIColor clearColor];
                [containerView addSubview:titleLabel];
            }
            UIView * scaleItem = [[UIView alloc]initWithFrame:CGRectMake(x, top, 1, scaleHeight)];
            scaleItem.backgroundColor = [UIColor whiteColor];
            [containerView addSubview:scaleItem];
            
            if(sourceEndText && sourceEndText.length>0)
            {
                UILabel * titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(x - 5, top +4, 50, 10)];
                titleLabel.font = font;
                titleLabel.text = sourceEndText;
                titleLabel.textColor = [UIColor yellowColor];
                titleLabel.backgroundColor = [UIColor clearColor];
                [containerView addSubview:titleLabel];
            }
        }
        else
        {
            UIView * scaleItem = [[UIView alloc]initWithFrame:CGRectMake(x, top, 0.5, scaleHeight)];
            scaleItem.backgroundColor = [UIColor whiteColor];
            [containerView addSubview:scaleItem];
        }
        x += diff;
    }
    return containerView;
}

@end

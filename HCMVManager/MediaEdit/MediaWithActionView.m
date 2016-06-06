//
//  MediaWithActionView.m
//  HCMVManagerTest
//
//  Created by HUANGXUTAO on 16/5/29.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import "MediaWithActionView.h"
@interface MediaWithActionView()
{
    CGFloat leftTextWidth_;
    CGFloat rightTextWidth_;
    UIView * lineView_;
    UIView * playerIndcator_;
    NSString * title_;
}
@end
@implementation MediaWithActionView
@synthesize mediaWithAction = mediaWithAction_;
@synthesize ContentWidth = ContentWidth_;
@synthesize Index = Index_;
- (void) setBaseWidth:(CGFloat)leftMarin widthPerSeconds:(CGFloat)widthPerSeconds
{
    leftMargin_ = leftMarin;
    widthPerseconds_ = widthPerSeconds;
}
- (void) setData:(MediaWithAction *)media title:(NSString *)title
{
    title_ = title;
    mediaWithAction_ = media;
    [self buildBaseLine:media];
}
- (void)setCurrent:(BOOL)isCurrent
{
    if(!lineView_) return;
    if(isCurrent)
    {
        CGRect frame = lineView_.frame;
        frame.size.height = 8;
        lineView_.frame = frame;
        lineView_.backgroundColor = [UIColor purpleColor];
        [lineView_ setNeedsDisplay];
        _isCurrent = YES;
    }
    else
    {
        CGRect frame = lineView_.frame;
        frame.size.height =2;
        lineView_.frame = frame;
        lineView_.backgroundColor = [UIColor blueColor];
        _isCurrent = NO;
    }
}
- (BOOL)setPlayerSeconds:(CGFloat)seconds
{
    if(lineView_.frame.size.height <4)
    {
        if(playerIndcator_)
        {
            playerIndcator_.hidden = YES;
        }
        return NO;
    }
    if((mediaWithAction_.playRate>0 && ( seconds < mediaWithAction_.secondsBegin || seconds> mediaWithAction_.secondsEnd))
       ||
       (mediaWithAction_.playRate<0 && ( seconds < mediaWithAction_.secondsEnd || seconds> mediaWithAction_.secondsBegin))
       )
    {
        if(playerIndcator_)
        {
            playerIndcator_.hidden = YES;
        }
        self.backgroundColor = [UIColor blueColor];
        return NO;
    }
    CGRect frame = lineView_.frame;
    frame.size.width = (seconds - mediaWithAction_.secondsBegin) * widthPerseconds_;
    if(!playerIndcator_)
    {
        playerIndcator_ = [[UIView alloc]initWithFrame:frame];
        
        [self addSubview:playerIndcator_];
    }
    else
    {
        playerIndcator_.hidden = NO;
        playerIndcator_.frame = frame;
    }
    self.backgroundColor = [UIColor purpleColor];
    return YES;
}
- (void) buildBaseLine:(MediaWithAction *)media
{
    NSString * rightText = [NSString stringWithFormat:@"原长(%.2f)合成(%.2f)rate:(%.2f)",media.secondsDurationInArray, media.secondsDurationInArray/(media.playRate!=0?fabs(media.playRate):1),media.playRate];
    font_ = [UIFont systemFontOfSize:10];

    CGSize rightSize = [rightText sizeWithAttributes:@{NSFontAttributeName:font_}];
    ContentWidth_ = widthPerseconds_ * media.secondsDurationInArray + rightSize.width + 10;
    NSString * leftTitle = title_?title_:[NSString stringWithFormat:@"%d-%d",Index_,media.Action.ActionType];
    
    CGSize leftSize = [leftTitle sizeWithAttributes:@{NSFontAttributeName:font_}];
    leftTextWidth_ = leftSize.width;
    rightTextWidth_ = rightSize.width;
    
    UIView * line = [self buildLineWithScale:CGRectMake(0 , 2, ContentWidth_, 20)
                                        diff:widthPerseconds_
                                       color:[UIColor blueColor]
                                       label:leftTitle
                                       begin:[NSString stringWithFormat:@"%.2f",media.secondsInArray]
                                         end:[NSString stringWithFormat:@"%.2f",media.secondsDurationInArray]
                                 sourceBegin:[NSString stringWithFormat:@"%.2f",media.secondsBegin]
                                   sourceEnd:[NSString stringWithFormat:@"%.2f",media.secondsEnd]
                                   rightText:rightText
                     ];
    [self addSubview:line];
    self.backgroundColor = [UIColor clearColor];
}
- (UIView *) buildLineWithScale:(CGRect)frame diff:(CGFloat)diff color:(UIColor *)color
                          label:(NSString *)lable
                          begin:(NSString *)beginText
                            end:(NSString *)endtext
                    sourceBegin:(NSString *)sourceBeginText
                      sourceEnd:(NSString *)sourceEndText
                      rightText:(NSString *)rightText
{
    CGFloat duration = mediaWithAction_.secondsDurationInArray;
    if(duration<=0) duration = 5;
    
    int count = (int)roundf(duration + 0.5);
   
    
    UIView * containerView = [[UIView alloc]initWithFrame:frame];
    {
        if(lable && lable.length>0)
        {
            UILabel * titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0 - leftTextWidth_ - 5, frame.size.height - 10, 50, 10)];
            titleLabel.font = font_;
            titleLabel.text = lable;
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.backgroundColor = [UIColor clearColor];
            [containerView addSubview:titleLabel];
        }
        UIView * line = [[UIView alloc]initWithFrame:CGRectMake(0, frame.size.height - 5, duration * widthPerseconds_, 2)];
        line.backgroundColor = color;
        [containerView addSubview:line];
        
        lineView_ = line;
        
        if(rightText && rightText.length>0)
        {
            UILabel * titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(frame.size.width - rightTextWidth_ +5, frame.size.height - 10, rightTextWidth_, 10)];
            titleLabel.font = font_;
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
                titleLabel.font = font_;
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
                UILabel * titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(x - 5, top +8, 50, 10)];
                titleLabel.font = font_;
                titleLabel.text = sourceBeginText;
                titleLabel.textColor = [UIColor darkGrayColor];
                titleLabel.backgroundColor = [UIColor clearColor];
                [containerView addSubview:titleLabel];
            }
        }
        else if(i==count)
        {
            x = duration * widthPerseconds_;
            if(endtext && endtext.length>0 && count>2)
            {
                UILabel * titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(x - 11, top - 10, 50, 10)];
                titleLabel.font = font_;
                titleLabel.text = endtext;
                titleLabel.textColor = [UIColor whiteColor];
                titleLabel.backgroundColor = [UIColor clearColor];
                [containerView addSubview:titleLabel];
            }
            UIView * scaleItem = [[UIView alloc]initWithFrame:CGRectMake(x, top, 1, scaleHeight)];
            scaleItem.backgroundColor = [UIColor whiteColor];
            [containerView addSubview:scaleItem];
            
            if(sourceEndText && sourceEndText.length>0 && count>2)
            {
                UILabel * titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(x - 11, top +8, 50, 10)];
                titleLabel.font = font_;
                titleLabel.text = sourceEndText;
                titleLabel.textColor = [UIColor darkGrayColor];
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

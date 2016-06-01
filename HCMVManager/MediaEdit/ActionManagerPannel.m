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
#import "MediaWithActionView.h"

@interface ActionManagerPannel()
{
    ActionManager * manager_;
    CGFloat leftMargin_;
    CGFloat rightMargin_;
    CGFloat contentWidth_;
    CGFloat withPerseconds_;
    CGFloat rowHeight_;
    CGFloat top_;
    CGFloat scaleItemWidth_;
    
    CGFloat fullWidth_;
    CGFloat fullHeight_;
    
    NSMutableArray * lineViews_;
}
@end
@implementation ActionManagerPannel
- (id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        leftMargin_ = 30;
        rightMargin_ = 10;
        top_ = 10;
        contentWidth_ = frame.size.width - leftMargin_ -rightMargin_;
        withPerseconds_ = contentWidth_ /20;
        rowHeight_ = 20;
        
        lineViews_ = [NSMutableArray new];
    }
    return self;
}
- (void) refresh
{
    if([NSThread isMainThread])
    {
        for (UIView * v in self.subviews) {
            [v removeFromSuperview];
        }
        [self buildViews];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refresh];
        });
    }
}
- (void) setActionManager:(ActionManager *)actionManager
{
    manager_ = actionManager;
    top_ = 10;

    [self refresh];
}
- (void) setPlayerSeconds:(CGFloat)playerSeconds isReverse:(BOOL)isReverse
{
    if([NSThread isMainThread])
    {
        for (MediaWithActionView * lineView  in lineViews_) {
            [lineView setPlayerSeconds:playerSeconds];
        }
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self buildViews];
        });
    }
}
- (void) setPlayMedia:(MediaWithAction *)playerMedia
{
    if([NSThread isMainThread])
    {
        for (MediaWithActionView * lineView  in lineViews_) {
            if(lineView.mediaWithAction == playerMedia)
            {
                [lineView setCurrent:YES];
            }
            else
            {
                [lineView setCurrent:NO];
            }
        }
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self buildViews];
        });
    }
}
- (void) buildViews
{
    MediaItem * bgVideo = [manager_ getBaseVideo];
    withPerseconds_ =  contentWidth_ /(bgVideo.secondsDurationInArray + 5);
    
    CGRect frame = CGRectMake(leftMargin_, top_,contentWidth_ , 30);
    MediaWithActionView * baseLine = [[MediaWithActionView alloc]initWithFrame:frame];
    [baseLine setBaseWidth:leftMargin_ widthPerSeconds:withPerseconds_];
    
    MediaWithAction * ma = [[MediaWithAction alloc]init];
    [ma fetchAsCore:bgVideo];
    [baseLine setData:ma title:@"base"];
    [self addSubview:baseLine];
    
    NSArray * mediaList = [manager_ getMediaList];
    int index =1;
    CGFloat top = top_ + 40;
    for (MediaWithAction * item in mediaList) {
        frame.origin.y = top;
        frame.origin.x = withPerseconds_ * item.secondsInArray + leftMargin_;
        MediaWithActionView * lineView = [[MediaWithActionView alloc]initWithFrame:frame];
        lineView.Index = index * 10000+[self getIndexForMedia:item];
        [lineView setBaseWidth:leftMargin_ widthPerSeconds:withPerseconds_];
        [lineView setData:item title:nil];
        [self addSubview:lineView];
        
        [lineViews_ addObject:lineView];
        
        if(fullWidth_ < frame.origin.x + lineView.ContentWidth)
        {
            fullWidth_ = frame.origin.x + lineView.ContentWidth;
        }
        index ++;
        top += 40;
    }
    fullHeight_ = top + 50;
    
    self.contentSize = CGSizeMake(fullWidth_, fullHeight_);
    if(self.contentSize.width > self.frame.size.width ||
       self.contentSize.height > self.frame.size.height)
    {
        self.scrollEnabled = YES;
    }
    else
    {
        self.scrollEnabled = NO;
    }
    
}
- (int)getIndexForMedia:(MediaWithAction *)media
{
    int index = 0;
    NSArray * actionList = [manager_ getActionList];
    int i = 0;
    for(MediaActionDo * item in actionList)
    {
        i ++;
        if(item.MediaActionID == media.Action.MediaActionID)
        {
            index = i;
            break;
        }
    }
    return index;
}
- (void) buildActionView:(MediaActionDo*)action mediaList:(NSArray *)mediaList
{
    
}
- (UIView *) buildActionIconView:(MediaActionDo *)action
{
    
    //    UIView * view = [UIView alloc]initWithFrame:CGRectMake(<#CGFloat x#>, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>)
    return nil;
}
@end

//
//  UIView+screenshot.m
//  top100
//
//  Created by Dai Cloud on 12-7-21.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "UIView+extension.h"
#import <QuartzCore/QuartzCore.h>


@implementation UIView (extension)

- (UIImage *)screenshot 
{	
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return screenshot;
}

- (UIImage *)screenshotWithOffset:(CGFloat)deltaY
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext(); 
    //  KEY: need to translate the context down to the current visible portion of the tablview
    CGContextTranslateCTM(ctx, 0, deltaY);
    [self.layer renderInContext:ctx];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return screenshot;
}

- (id) traverseResponderChainForUIViewController {
    id nextResponder = [self nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        return nextResponder;
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        return [nextResponder traverseResponderChainForUIViewController];
    } else {
        return nil;
    }
}
- (CGFloat) getViewPositionOnScreen
{
    CGFloat cH = self.frame.origin.y;
    UIView * parentView = self.superview;
    while(parentView)
    {
        cH += parentView.frame.origin.y;
        parentView = parentView.superview;
    }
    return cH;
}
- (void)roundCorners:(float)cornerRadius andShadowOffset:(float)shadowOffset
{
    /*放置列表拖动时重复生成阴影*/
    if (nil != self.superview && self.superview.tag == SHADOWVIEW_TAG ) {
        return;
    }
    
    self.layer.cornerRadius = cornerRadius;
    self.layer.masksToBounds = YES;
    if(shadowOffset>0)
    {
        UIView * superView = [self superview];

        UIView* shadowView = [[UIView alloc] init];
        shadowView.layer.cornerRadius = cornerRadius;
        shadowView.layer.shadowColor = [[UIColor blackColor] CGColor];
        shadowView.layer.shadowOffset = CGSizeMake(shadowOffset, shadowOffset);
        shadowView.layer.shadowOpacity = 0.3f;
        shadowView.layer.shadowRadius = 1.0f;
        [shadowView setTag:SHADOWVIEW_TAG];
        [shadowView addSubview:self];
        
        [superView addSubview:shadowView];
    }
    
}
@end

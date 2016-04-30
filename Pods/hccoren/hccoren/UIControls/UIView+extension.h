//
//  UIView+screenshot.h
//  top100
//
//  Created by Dai Cloud on 12-7-21.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SHADOWVIEW_TAG 76383821

@interface UIView (extension)

- (UIImage *)screenshotWithOffset:(CGFloat)deltaY;
- (UIImage *)screenshot;
- (id) traverseResponderChainForUIViewController;
- (CGFloat) getViewPositionOnScreen;

- (void)roundCorners:(float)cornerRadius andShadowOffset:(float)shadowOffset;
@end

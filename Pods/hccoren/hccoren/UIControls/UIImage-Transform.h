//
//  UIImage-Transform.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 13-1-14.
//  Copyright (c) 2013年 Suixing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGBase.h>
#import <UIKit/UIImage.h>
@interface UIImage(Transform)
- (UIImage*)transformWidth:(CGFloat)width
                    height:(CGFloat)height;
@end

//
//  UIImage-Extension.h
//  HotelCloud
//
//  Created by XUTAO HUANG on 13-5-17.
//  Copyright (c) 2013年 Suixing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface UIImage(Extension)
- (UIImage *)imageAtRect:(CGRect)rect;
- (UIImage *)imageByScalingProportionallyToMinimumSize:(CGSize)targetSize;
- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize;
- (UIImage *)imageByScalingToSize:(CGSize)targetSize;
- (UIImage *)imageRotatedByRadians:(CGFloat)radians;
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;
- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize backcolor:(UIColor *)backColor;
- (UIImage *) roundCorners: (CGFloat) rw;
//static void addRoundedRectToPath(CGContextRef context, CGRect rect,
//                                 float ovalWidth,float ovalHeight);
- (UIImage *)fixOrientation;
- (UIImage *)normalizedImage:(UIImageOrientation)orientation;

- (UIImage *)imagebyTurnHorizental; //水平翻转
- (UIImage *)imagebyTurnVertical; //垂直翻转

@end

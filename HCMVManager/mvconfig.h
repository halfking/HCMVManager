//
//  mvconfig.h
//  HCMVManager
//
//  Created by HUANGXUTAO on 16/4/21.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//
#import <UIKit/UIKit.h>

#ifndef mvconfig_h
#define mvconfig_h


#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define UIColorFromRGBA(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:0.6]


#define COLOR_MV_BF        UIColorFromRGB(0xaaaaaa)//浅灰。
#define CT_WATERMARKFILE   @"watermark_MtvPlus.png"
#define FONT_MV_LYRIC      [UIFont fontWithName:@"FZQingKeBenYueSongS-R-GB" size:24]

#endif /* mvconfig_h */

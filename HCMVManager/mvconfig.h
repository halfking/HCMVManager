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

#ifndef MEDIA_TYPE
#define MEDIA_TYPE
enum _MediaItemInQueueType{
    
    MediaItemTypeIMAGE,
    MediaItemTypeVIDEO,
    MediaItemTypeTRANS,
    MediaItemTypeAUDIO
    
} ;
typedef u_int8_t MediaItemInQueueType;

#endif
#ifndef   CUTINOUT_MODE
#define   CUTINOUT_MODE
//转场模式类型
enum _CutInOutMode {
    CutInOutModeFadeIn = 0,
    CutInOutModeFadeOut = 1
};
typedef u_int8_t  CutInOutMode;
#endif //

#ifndef   NSMUSIC_TYPE
#define   NSMUSIC_TYPE
enum _MUSIC_TYPE {
    MP3         = 0,
    WAV              = 1
};
typedef u_int8_t MUSIC_TYPE;
#endif // NSMUSIC_TYPE

#ifndef   NSMUSIC_SOURCE
#define   NSMUSIC_SOURCE
enum _MUSIC_SOURCE {
    SAMPLE         = 0,
    UPLOAD         = 1
};
typedef u_int8_t MUSIC_SOURCE;
#endif // MUSIC_SOURCE

#ifndef   NSVIDEO_COMPLETEDPHARSE
#define   NSVIDEO_COMPLETEDPHARSE
enum _VIDEO_COMPLETEDPHARSE {
    NONE         = 0,
    MERGE         = 1
};
typedef u_int8_t VIDEO_COMPLETEDPHARSE;
#endif // VIDEO_COMPLETEDPHARSE



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
#define DEFAULT_TIMESCALE   600
#endif /* mvconfig_h */

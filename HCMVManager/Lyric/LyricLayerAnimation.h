//
//  LyricLayerAnimation.h
//  EditorWhileSing
//
//  Created by Matthew on 15/12/3.
//  Copyright © 2015年 Matthew. All rights reserved.
//
#define LyricAppearTime 0.3
#define miniScreenFontSize 16
#define fullScreenFontSize 28
//字幕和屏幕高度比例为0.08:1
//合成时字幕字体的大小需要根据bgv的尺寸来确定 sad!!important
typedef enum {
    
    Scale,
    
} LyricAniType;

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@interface LyricLayerAnimation : NSObject

+(CAAnimationGroup *)animationWithLyrics:(NSArray *)lyrics witAniType:(LyricAniType)type size:(CGSize)size font:(UIFont *)font rate:(CGFloat)rate;
+(CAKeyframeAnimation *)scaleLyricsN:(NSArray *)lyrics size:(CGSize)size font:(UIFont *)font rate:(CGFloat)rate;
+(CAAnimationGroup *)buildTitleAnimates:(NSString *)title singer:(NSString*)singer size:(CGSize)size font:(UIFont *)font;
@end

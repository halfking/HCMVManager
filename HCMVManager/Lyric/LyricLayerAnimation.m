//
//  LyricLayerAnimation.m
//  EditorWhileSing
//
//  Created by Matthew on 15/12/3.
//  Copyright © 2015年 Matthew. All rights reserved.
//


#import <hccoren/base.h>
#import <hccoren/RegexKitLite.h>

#import "LyricLayerAnimation.h"
#include "LyricItem.h"
@implementation LyricLayerAnimation
+(CAAnimation *)animationWithLyrics:(NSArray *)lyrics witAniType:(LyricAniType)type size:(CGSize)size font:(UIFont *)font rate:(CGFloat)rate
{
    return [LyricLayerAnimation scaleLyrics:lyrics size:size font:font rate:rate];
    //    CAAnimation * opt = [CAAnimation animation];
    ////    switch (type) {
    ////        case Scale:
    ////        {
    //            opt = [LyricLayerAnimation scaleLyrics:lyrics];
    ////        }
    ////            break;
    ////        default:
    ////            break;
    ////    }
    //    return opt;
}
+(CAAnimationGroup *)scaleLyrics:(NSArray *)lyrics size:(CGSize)size font:(UIFont *)font rate:(CGFloat)rate
{
    //    CAAnimationGroup * opt = [CAAnimationGroup animation];
    /*
     CATextLayer *lary = [CATextLayer layer];
     lary.string = @"dasfasa";
     lary.bounds = CGRectMake(0, 0, 320, 20);
     //lary.font = @"HiraKakuProN-W3"; //字体的名字 不是 UIFont
     lary.fontSize = 12.f; //字体的大小
     lary.alignmentMode = kCAAlignmentCenter;//字体的对齐方式
     lary.position = CGPointMake(160, 410);
     lary.foregroundColor = [UIColor redColor].CGColor;//字体的颜色
     [self.view.layer addSublayer:lary];
     */
    //    CABasicAnimation * frontSize = [CABasicAnimation animationWithKeyPath:@"fontSize"];
    //    frontSize.duration = 5.0f;
    //    frontSize.beginTime = 0.0;//AVCoreAnimationBeginTimeAtZero;
    //    frontSize.fromValue = @12.f;
    //    frontSize.toValue = @20.0f;
    //    frontSize.removedOnCompletion = NO;
    //
    //    UIColor * color = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
    //    UIColor * shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    //
    CGFloat totalTime = 0.0f;
    //    CGFloat st;
    CGFloat et;
    //    CGFloat alreadyAppear;
    //    CGFloat willDisappear;
    //所以最好是前后两句中间是间隔，不要重合在一起
    for (int i= 0 ; i < lyrics.count;  i++) {
        LyricItem * temp = [lyrics objectAtIndex:i];
        et = temp.begin + temp.duration;
        if (et > totalTime) {
            totalTime = et;
        }
    }
    //
    //    NSMutableArray * keyTimes = [[NSMutableArray alloc]init];
    //    NSMutableArray * keyTimesForString = [[NSMutableArray alloc]init];
    //    NSMutableArray * opacityValues = [[NSMutableArray alloc]init];
    ////    NSMutableArray * strings = [[NSMutableArray alloc]init];
    //    NSMutableArray * fontsizes = [[NSMutableArray alloc]init];
    //
    //    NSMutableArray * stringImages = [NSMutableArray new];
    //
    //    UIImage * blankImage = [self imageFromText:@"" size:size font:font color:color shadowColor:nil];
    //    //透明度和字体大小都需要考虑结束和开始之间的变换过渡，但是string不需要考虑
    //    for (int j= 0 ; j< lyrics.count; j++) {
    //        LyricItem * temp = [lyrics objectAtIndex:j];
    //        st = temp.begin;
    //        alreadyAppear = st + LyricAppearTime;
    //
    //        et = st + temp.duration;
    //        willDisappear = et - LyricAppearTime;
    //
    //        st = st / totalTime;
    //        alreadyAppear = alreadyAppear / totalTime;
    //        willDisappear = willDisappear / totalTime;
    //        et = et / totalTime;
    //
    //        [keyTimes addObject:[NSNumber numberWithFloat:st]];
    //        [keyTimes addObject:[NSNumber numberWithFloat:alreadyAppear]];
    //        [keyTimes addObject:[NSNumber numberWithFloat:willDisappear]];
    //        [keyTimes addObject:[NSNumber numberWithFloat:et]];
    //
    //        [opacityValues addObject:[NSNumber numberWithFloat:0.0f]];
    //        [opacityValues addObject:[NSNumber numberWithFloat:1.0f]];
    //        [opacityValues addObject:[NSNumber numberWithFloat:1.0f]];
    //        [opacityValues addObject:[NSNumber numberWithFloat:0.0f]];
    //
    //        [fontsizes addObject:[NSNumber numberWithFloat:50.0f]];
    //        [fontsizes addObject:[NSNumber numberWithFloat:20.0f]];
    //        [fontsizes addObject:[NSNumber numberWithFloat:20.0f]];
    //        [fontsizes addObject:[NSNumber numberWithFloat:50.0f]];
    //
    //
    //        [keyTimesForString addObject:[NSNumber numberWithFloat:st]];
    //        [keyTimesForString addObject:[NSNumber numberWithFloat:et]];
    //
    //
    //
    ////        [strings addObject:temp.text];
    ////        [strings addObject:@"123123"];
    //
    //        UIImage * image = [self imageFromText:temp.text size:size font:font color:color shadowColor:shadowColor];
    //        [stringImages addObject:(__bridge id)image.CGImage];
    //        [stringImages addObject:(__bridge id)blankImage.CGImage];
    //    }
    //
    //    CAKeyframeAnimation *overlay = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    //    overlay.values = stringImages;
    //    overlay.keyTimes = keyTimesForString;
    //    overlay.duration = totalTime;
    //    overlay.removedOnCompletion = NO;
    //    overlay.beginTime = 0;
    //
    //    CAKeyframeAnimation * opacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    //    opacity.keyTimes = keyTimes;
    //    opacity.values = opacityValues;
    //    opacity.duration = totalTime;
    //    opacity.removedOnCompletion = NO;
    //    opacity.beginTime = 0;
    
    //    CAKeyframeAnimation * string = [CAKeyframeAnimation animationWithKeyPath:@"string"];
    //    string.keyTimes = keyTimesForString;
    //    string.values = stringImages;
    //    string.duration = totalTime;
    //    string.removedOnCompletion = NO;
    //    string.beginTime = 0;
    
    //    CAKeyframeAnimation * scale = [CAKeyframeAnimation animationWithKeyPath:@"fontSize"];
    //    scale.keyTimes = keyTimes;
    //    scale.values = fontsizes;
    //    scale.duration = totalTime;
    //    scale.removedOnCompletion = NO;
    //    scale.beginTime = 0;
    
    //    CAKeyframeAnimation * opacity = [self scaleLyricsOpti:lyrics size:size font:font];
    CAKeyframeAnimation * overlay = [self scaleLyricsN:lyrics size:size font:font rate:rate];
    
    //必需加两层的Group，否则可能不成功
    CAAnimationGroup * group = [CAAnimationGroup animation];
    group.removedOnCompletion = NO;
    group.duration = totalTime;
    group.fillMode =kCAFillModeBoth; //只有forwards显示 但是一直显示最后一句
    group.beginTime = AVCoreAnimationBeginTimeAtZero;
    
    //    [group setAnimations:[NSArray arrayWithObjects:string, opacity,scale, nil]];
    [group setAnimations:[NSArray arrayWithObjects:overlay,nil]];
    
    CAAnimationGroup * opt1 = [CAAnimationGroup animation];
    opt1.removedOnCompletion = NO;
    opt1.duration = totalTime;
    opt1.beginTime = AVCoreAnimationBeginTimeAtZero;
    [opt1 setAnimations:[NSArray arrayWithObject:group]];
    
    
    return opt1;
}
+(CAKeyframeAnimation *)scaleLyricsOpti:(NSArray *)lyrics size:(CGSize)size font:(UIFont *)font
{
    CGFloat totalTime = 0.0f;
    CGFloat st;
    CGFloat et;
    CGFloat alreadyAppear;
    CGFloat willDisappear;
    //所以最好是前后两句中间是间隔，不要重合在一起
    for (int i= 0 ; i < lyrics.count;  i++) {
        LyricItem * temp = [lyrics objectAtIndex:i];
        et = temp.begin + temp.duration;
        if (et > totalTime) {
            totalTime = et;
        }
    }
    
    NSMutableArray * keyTimes = [[NSMutableArray alloc]init];
    NSMutableArray * opacityValues = [[NSMutableArray alloc]init];
    
    //透明度和字体大小都需要考虑结束和开始之间的变换过渡，但是string不需要考虑
    for (int j= 0 ; j< lyrics.count; j++) {
        LyricItem * temp = [lyrics objectAtIndex:j];
        st = temp.begin;
        alreadyAppear = st + LyricAppearTime;
        
        et = st + temp.duration;
        willDisappear = et - LyricAppearTime;
        
        st = st / totalTime;
        alreadyAppear = alreadyAppear / totalTime;
        willDisappear = willDisappear / totalTime;
        et = et / totalTime;
        
        [keyTimes addObject:[NSNumber numberWithFloat:st]];
        [keyTimes addObject:[NSNumber numberWithFloat:alreadyAppear]];
        [keyTimes addObject:[NSNumber numberWithFloat:willDisappear]];
        [keyTimes addObject:[NSNumber numberWithFloat:et]];
        
        [opacityValues addObject:[NSNumber numberWithFloat:0.0f]];
        [opacityValues addObject:[NSNumber numberWithFloat:1.0f]];
        [opacityValues addObject:[NSNumber numberWithFloat:1.0f]];
        [opacityValues addObject:[NSNumber numberWithFloat:0.0f]];
    }
    CAKeyframeAnimation * opacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opacity.keyTimes = keyTimes;
    opacity.values = opacityValues;
    opacity.duration = totalTime;
    opacity.removedOnCompletion = NO;
    opacity.beginTime = 0;
    
    
    return opacity;
}
+(CAKeyframeAnimation *)scaleLyricsN:(NSArray *)lyrics size:(CGSize)size font:(UIFont *)font rate:(CGFloat)rate
{
    UIColor * color = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
    UIColor * shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    if(rate <=0) rate = 1;
    CGFloat totalTime = 0.0f;
    CGFloat st;
    CGFloat et;
    CGFloat alreadyAppear;
    CGFloat willDisappear;
    //所以最好是前后两句中间是间隔，不要重合在一起
    for (int i= 0 ; i < lyrics.count;  i++) {
        LyricItem * temp = [lyrics objectAtIndex:i];
        et = temp.begin + temp.duration;
        if (et > totalTime) {
            totalTime = et;
        }
    }
    
    NSMutableArray * keyTimesForString = [[NSMutableArray alloc]init];
    NSMutableArray * stringImages = [NSMutableArray new];
    
    UIImage * blankImage = [self imageFromText:@"" size:size font:font color:color shadowColor:nil];
    
    [keyTimesForString addObject:[NSNumber numberWithFloat:0]];
    [stringImages addObject:(__bridge id)blankImage.CGImage];
    
    //透明度和字体大小都需要考虑结束和开始之间的变换过渡，但是string不需要考虑
    for (int j= 0 ; j< lyrics.count; j++) {
        LyricItem * temp = [lyrics objectAtIndex:j];
        st = temp.begin;
        st -= LyricAppearTime;
        alreadyAppear = st + LyricAppearTime;
        
        et = st + temp.duration;
        willDisappear = et - LyricAppearTime;
        
        st = st / totalTime;
        alreadyAppear = alreadyAppear / totalTime;
        willDisappear = willDisappear / totalTime;
        et = et / totalTime;
        
        [keyTimesForString addObject:[NSNumber numberWithFloat:st/rate]];
        [keyTimesForString addObject:[NSNumber numberWithFloat:alreadyAppear/rate]];
        [keyTimesForString addObject:[NSNumber numberWithFloat:willDisappear/rate]];
        [keyTimesForString addObject:[NSNumber numberWithFloat:et/rate]];
        
        
        UIImage * image = [self imageFromText:temp.text size:size font:font color:color shadowColor:shadowColor];
        
        [stringImages addObject:(__bridge id)blankImage.CGImage];
        [stringImages addObject:(__bridge id)image.CGImage];
        [stringImages addObject:(__bridge id)image.CGImage];
        [stringImages addObject:(__bridge id)blankImage.CGImage];
    }
    
    CAKeyframeAnimation *overlay = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    overlay.values = stringImages;
    overlay.keyTimes = keyTimesForString;
    overlay.duration = totalTime;
    overlay.removedOnCompletion = NO;
    overlay.beginTime = 0;
    
    return overlay;
}
+(CAAnimationGroup *)buildTitleAnimates:(NSString *)title singer:(NSString*)singer size:(CGSize)size font:(UIFont *)font
{
    CMTime duration = CMTimeMakeWithSeconds(3, 1000);
    
    UIColor * color = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
    UIColor * shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    
    UIImage * blankImage = [self imageFromText:@"" size:size font:font color:color shadowColor:nil];
    
    //    CAKeyframeAnimation * overlay = [self scaleLyricsN:lyrics size:size font:font];
    //
    //    //必需加两层的Group，否则可能不成功
    //    CAAnimationGroup * group = [CAAnimationGroup animation];
    //    group.removedOnCompletion = NO;
    //    group.duration = duration;
    //    group.fillMode =kCAFillModeBoth; //只有forwards显示 但是一直显示最后一句
    //    group.beginTime = AVCoreAnimationBeginTimeAtZero;
    //
    //    //    [group setAnimations:[NSArray arrayWithObjects:string, opacity,scale, nil]];
    //    [group setAnimations:[NSArray arrayWithObjects:overlay,nil]];
    //
    //    CAAnimationGroup * opt1 = [CAAnimationGroup animation];
    //    opt1.removedOnCompletion = NO;
    //    opt1.duration = duration;
    //    opt1.beginTime = AVCoreAnimationBeginTimeAtZero;
    //    [opt1 setAnimations:[NSArray arrayWithObject:group]];
    //
    //
    //    return opt1;
    return nil;
}
//歌词可能超长，需要折行
+(UIImage *)imageFromText:(NSString *)text size:(CGSize)size font:(UIFont *)font color:(UIColor *)color shadowColor:(UIColor *)shadowColor
{
//    text = @"我是一条长长的歌词 看看大家能否知道是否长度够 家能否知\nthis is english words and the space controls what is the space.";
    if(!text) text = @"";
    if(!color) color = [UIColor blackColor];
    
    //UIGraphicsBeginImageContext(sizeImageFromText); // iOS is < 4.0
    
    
    CGRect rect = CGRectZero;
    
    NSMutableArray * lineArray = [NSMutableArray new];
    CGFloat totalHeight = 0;
    CGFloat lineSpace = 5;
    NSArray * lines = [text componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r\t|"]];
    for (NSString * s in lines)
    {
        if(s.length==0) continue;
        
        NSString * lineText = s;
        NSString * remainText = s;
        CGSize textSize = [lineText sizeWithAttributes:@{NSFontAttributeName:font}];
        while (remainText &&lineText.length<=remainText.length)
        {
            while(textSize.width >size.width && textSize.width > 40)
            {
                NSRange range = [remainText rangeOfString:@" "];
                if(range.location==NSNotFound)
                {
                    lineText = [lineText substringToIndex:lineText.length-1];
                }
                else
                {
                    lineText = [remainText substringToIndex:range.location+1];
                }
                if([lineText isEqualToString:@" "])
                    continue;
                
                textSize = [lineText sizeWithAttributes:@{NSFontAttributeName:font}];
                
            }
            if(remainText.length>lineText.length)
            {
                remainText = [remainText substringFromIndex:lineText.length];
            }
            else
            {
                remainText = nil;
            }
            [lineArray addObject:@{@"text":lineText,@"width":@(textSize.width),@"height":@(textSize.height)}];
            totalHeight += textSize.height;
            
            lineText = remainText;
            if(lineText)
                textSize = [lineText sizeWithAttributes:@{NSFontAttributeName:font}];
            else
                textSize.width = 0;
            
        }
    }
    
    
    size.height = MAX(size.height,(totalHeight + lineSpace* lineArray.count+5));
    //从底下往上排
    CGFloat top = (size.height - totalHeight - lineSpace* lineArray.count -5);
    
    UIGraphicsBeginImageContextWithOptions(size,NO,[UIScreen mainScreen].scale);//Better resolution (antialiasing)
    
    for (NSDictionary * line in lineArray)
    {
        CGFloat width = [[line objectForKey:@"width"]floatValue];
        CGFloat height = [[line objectForKey:@"height"]floatValue];
        NSString * lineText = [line objectForKey:@"text"];
        
        rect = CGRectMake((size.width - width)/2, top, width+5, height);
        
        if(shadowColor)
        {
            rect.origin.x ++;
            rect.origin.y ++;
            [lineText drawInRect:rect withAttributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:shadowColor}];
            rect.origin.x --;
            rect.origin.y --;
        }
        [lineText drawInRect:rect withAttributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:color}];
        top += height + lineSpace;
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
//将TextLines转成可以显示的Drawlines。
//+(BOOL) buildText:(NSString *)message andRectSize:(CGSize)size
//andRetString:(NSString * *)retString
//justgetSize:(BOOL)getSize stringnumber:(int)snumber
//    {
//        CGFloat top = 0;
//        CGFloat left = 0;
//        CGFloat width = 0;
//        CGFloat height = 0;
//        CGFloat lineCount = 0;
//        CGFloat rowHeight = 0;
//        int segNumber = 0;
//        BOOL isAllShow = NO;
//        BOOL needDecreaseSize = NO;
//        //    BOOL isOutHeight = FALSE;
//        CGFloat topOrg                 = 0;
//        //    DLog(@"parse time:%d",snumber);
//        //逐段处理文字
//        CGSize realSize = CGSizeZero;
//        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingGB_18030_2000);
//
//        for (NSDictionary * textDic in textArray_) {
//            segNumber ++;
//            //        DLog(@"textDic:%@",textDic);
//
//            CGFloat cFontSize =[[textDic objectForKey:@"fontsize"]floatValue];
//            UIFont * fontTemp = [UIFont fontWithName:[textDic objectForKey:@"fontname"]
//                                                size:cFontSize];
//            if(!fontTemp)
//            {
//                fontTemp = [UIFont fontWithName:self.fontName size:self.fontSize];
//                cFontSize = self.fontSize;
//            }
//            NSString * segText = [textDic objectForKey:@"text"];
//            //本行剩余RECT范围
//            //如果非HTML下，每段String各占一行。
//            if(useHtml ==NO || left > size.width - cFontSize)
//                left = 0;
//            CGSize lineRect = CGSizeMake(size.width - left, MIN((size.height - top),lineHeight));
//            //文字占用的大小
//            //CGSize segSize = [segText sizeWithFont:fontTemp];
//
//            NSDictionary *attribute = @{NSFontAttributeName: fontTemp};
//            CGSize segSize = [segText boundingRectWithSize:CGSizeMake(1000, MAXFLOAT)
//                                                   options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
//                                                attributes:attribute context:nil].size;
//
//
//            //如果能显示完成，则可以放置在其中
//            if(segSize.width <= lineRect.width /*&& segSize.height <= lineRect.height*/)
//            {
//                NSMutableDictionary *dic       = [NSMutableDictionary dictionaryWithObjectsAndKeys:segText,@"text",
//                                                  @(top+topOrg),@"y",//+(lineRect.height - lineDiffMin - segSize.height)),@"y",
//                                                  @(left),@"x",
//                                                  fontTemp,@"font",
//                                                  @(segSize.width),@"width",
//                                                  @(segSize.height),@"height",
//                                                  [textDic objectForKey:@"fontcolor"],@"color",
//                                                  @(lineCount),@"row",
//                                                  nil];
//                if([textDic objectForKey:@"strike"])
//                {
//                    [dic setObject:[textDic objectForKey:@"strike"] forKey:@"strike"];
//                }
//                [drawLines_ addObject:dic];
//                width = MAX(width,left +segSize.width);
//                rowHeight = [self adjustRowHeight:lineCount changeLeft:NO];
//                height = MAX(height,top + rowHeight + lineDiffMin);
//                left += segSize.width + segmentSpace;
//                if(useHtml  == NO || left >= size.width -cFontSize)
//                {
//                    //判断行数是否已经到达指定值
//                    rowHeight = [self adjustRowHeight:lineCount changeLeft:NO];
//                    lineCount ++;
//                    // if(numberOfLines>0 && lineCount >=numberOfLines)//****   /* &&segNumber >= textArray_.count)*/
//                    if(numberOfLines>0 && lineCount > numberOfLines)
//                    {
//                        if(segNumber>=textArray_.count)
//                        {
//                            //                        isAllShow = YES;
//                            needDecreaseSize = NO;
//                            break;
//                        }
//                        else
//                        {
//                            //                        isAllShow = YES;
//                            needDecreaseSize = YES;
//                            break;
//                        }
//                    }
//                    else
//                    {
//                        top += rowHeight ;//+ lineDiffMin);// lineHeight;
//                        rowHeight = 0;
//                        left = 0;
//                        continue;
//                    }
//                }
//            }
//            //需要拆份成多行
//            else
//            {
//                //        REPEATER:
//                //逐字判断，是否在显示范围内
//                while (segText && segText.length>0) {
//                    NSString * retString = nil;
//                    for (int charIndex = (int)segText.length;charIndex>=0;charIndex--) {
//                        NSString * temp = [segText substringToIndex:charIndex];
//                        //文字占用的大小
//                        segSize = [temp sizeWithAttributes: @{NSFontAttributeName:fontTemp}];
//                        //                    segSize = [temp sizeWithFont:fontTemp];
//                        if(segSize.width <= lineRect.width /*&& segSize.height <= lineRect.height*/)
//                        {
//                            //判断是否根据词来分行,最后一行不分
//                            if(lineBreakByWord && charIndex < segText.length &&
//                               ((numberOfLines>0 && lineCount <numberOfLines) ||numberOfLines<=0))
//                            {
//                                int index2 = charIndex;
//                                for (int indexTemp = charIndex ;indexTemp >=0;indexTemp--) {
//                                    NSData *gb2312_data = [[segText substringWithRange:NSMakeRange(indexTemp, 1) ] dataUsingEncoding:enc];
//                                    //如果是中文或其它的，则不需要再处理
//                                    char *gb2312_string = (char *)[gb2312_data bytes];
//                                    if(gb2312_data.length>=2)
//                                    {
//                                        unsigned char ucHigh = (unsigned char)gb2312_string[0];
//                                        unsigned char ucLow  = (unsigned char)gb2312_string[1];
//                                        if ( ucHigh < 0xa1 || ucLow < 0xa1)
//                                        {
//                                            if(ucLow<=0x30)
//                                            {
//                                                index2 = indexTemp;
//                                                break;
//                                            }
//                                            else
//                                                continue;
//                                        }
//                                        else
//                                        {
//                                            index2 = indexTemp;
//                                            break;
//                                        }
//                                    }
//                                    else
//                                    {
//                                        unsigned char ucHigh = (unsigned char)gb2312_string[0];
//                                        if(ucHigh<=0x30||ucHigh=='|')
//                                        {
//                                            index2 = indexTemp;
//                                            break;
//                                        }
//                                        else
//                                            continue;
//                                    }
//                                }
//                                if(index2<charIndex && index2>0)
//                                {
//                                    charIndex = index2;
//                                    temp = [segText substringToIndex:charIndex];
//                                    segSize = [temp sizeWithAttributes: @{NSFontAttributeName:fontTemp}];
//                                    //                                segSize = [temp sizeWithFont:fontTemp];
//                                }
//                            }
//                            NSMutableDictionary *dic       = [NSMutableDictionary dictionaryWithObjectsAndKeys:temp,@"text",
//                                                              @(top+topOrg),@"y",
//                                                              //+(lineRect.height - lineDiffMin - segSize.height)),@"y",
//                                                              @(left),@"x",
//                                                              fontTemp,@"font",
//                                                              @(segSize.width),@"width",
//                                                              @(segSize.height),@"height",
//                                                              [textDic objectForKey:@"fontcolor"],@"color",
//                                                              @(lineCount),@"row",
//                                                              nil];
//
//                            if([textDic objectForKey:@"strike"])
//                            {
//                                [dic setObject:[textDic objectForKey:@"strike"] forKey:@"strike"];
//                            }
//                            //                        DLog(@"dic:%@",dic);
//                            if(charIndex < segText.length)
//                            {
//                                retString = [segText substringFromIndex:charIndex];
//                                if(lineBreakByWord)
//                                {
//                                    while ([retString hasPrefix:@" "]||[retString hasPrefix:@"|"])
//                                    {
//                                        retString = [retString substringFromIndex:1];
//                                        if(retString.length<1)
//                                        {
//                                            break;
//                                        }
//                                    }
//                                }
//                            }
//                            else
//                                retString = nil;
//
//
//
//                            if(numberOfLines>0 && lineCount >numberOfLines )
//                            {
//                                lineCount ++;
//                                isAllShow = YES; //不用往下显示了，已经显示完成了，因此可能需要中断，但需要变更字体
//                                break;
//                            }
//                            else
//                            {
//                                [drawLines_ addObject:dic];
//
//                                width = MAX(width,left +segSize.width);
//                                //因为已经超长了，则肯定是行要增加了
//                                if(left+segSize.width > size.width -cFontSize||(retString && retString.length>0))
//                                {
//                                    rowHeight = [self adjustRowHeight:lineCount changeLeft:NO];
//                                    lineCount ++;
//                                }
//                                else
//                                {
//                                    rowHeight = [self adjustRowHeight:lineCount changeLeft:NO];
//                                }
//                                //                            rowHeight = MAX(rowHeight,segSize.height + lineDiffMin);
//                                height = MAX(height,top + rowHeight);
//                                break;
//                            }
//                        }
//                    }
//                    if(isAllShow)
//                    {
//                        if(autoChangeSize)
//                        {
//                            needDecreaseSize = YES;
//                        }
//                        break;
//                    }
//                    else if(retString==nil||retString.length==0) //本段已经显示完成
//                    {
//                        left += segSize.width + segmentSpace;
//                        //在上一行刚刚显示完成时。
//                        if(left + cFontSize > size.width)
//                            left = 0;
//                        width = MAX(width,left);
//                        //                    rowHeight = MAX(rowHeight,segSize.height + lineDiffMin);
//                        height = MAX(height,top + rowHeight);
//
//                        break;
//                    }
//                    else //未显示完，则需要将剩余的字串铺到下一行
//                    {
//                        top += rowHeight;
//                        if(retString && retString.length>0
//                           && lineCount +1 >numberOfLines
//                           && numberOfLines>0)
//                        {
//                            isAllShow = YES;
//                            needDecreaseSize = YES;
//                            break;
//                        }
//                        left = 0;
//                        rowHeight = 0;
//                        if(retString)
//                        {
//                            //                        lineCount ++;
//                            segText = retString;
//                            lineRect = CGSizeMake(size.width - left, MIN((size.height - top),lineHeight));
//                            continue;
//                        }
//
//                    }
//                }
//                if(isAllShow)
//                {
//                    break;
//                }
//            }
//        }
//        if(isRowHeightFlexible)
//            height -= lineDiffMin;
//
//        realSize = CGSizeMake(width, height);
//        if(!needDecreaseSize)
//        {
//            for (int i=0;i<=lineCount;i++) {
//                [self adjustRowHeight:i changeLeft:YES];
//            }
//            //        DLog(@"last parse:%@",drawLines_);
//        }
//        return needDecreaseSize;
//    }
//
//
//    // Only override drawRect: if you perform custom drawing.
//    // An empty implementation adversely affects performance during animation.
//    - (void)drawRect:(CGRect)rect
//    {
//        CGFloat top                    = 0;
//        CGFloat left                   =0;
//        //    DLog(@"draw lines:%@",drawLines_);
//        //    CGFloat height                 = self.frame.size.height;
//        for (int i                     = 0;i<drawLines_.count;i++) {
//            NSDictionary * dic             = [drawLines_ objectAtIndex:i];
//
//            NSString * stringTemp          = [dic objectForKey:@"text"];
//            top                            = [[dic objectForKey:@"y"]floatValue];
//            left                            = [[dic objectForKey:@"x"]floatValue];
//            //        CGSize size0                   =
//            [self drawText:stringTemp
//                         x:left
//                         y:top
//                      font:[dic objectForKey:@"font"]
//                     color:[dic objectForKey:@"color"]
//                    stripe:[dic objectForKey:@"strike"] && [[dic objectForKey:@"strike"]boolValue]?YES:NO
//                     width:[[dic objectForKey:@"width"]floatValue]
//                    height:[[dic objectForKey:@"height"]floatValue]
//             ];
//            //        if(size0.width >= self.frame.size.width && size0.height>=height)
//            //        {
//            //            break;
//            //        }
//            //        else
//            //        {
//            //            height      -= size0.height;
//            //        }
//        }
//    }
+(UIImage *)imageFromTitle:(NSString *)text size:(CGSize)size font:(UIFont *)font color:(UIColor *)color shadowColor:(UIColor *)shadowColor
{
    if(!text) text = @"";
    if(!color) color = [UIColor blackColor];
    UIGraphicsBeginImageContextWithOptions(size,NO,0.0);//Better resolution (antialiasing)
    //UIGraphicsBeginImageContext(sizeImageFromText); // iOS is < 4.0
    
    CGRect rect = [text boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil];
    rect.origin.x = (size.width - rect.size.width)/2.0f;
    rect.origin.y = (size.height - rect.size.height)/2.0f;
    
    if(shadowColor)
    {
        rect.origin.x ++;
        rect.origin.y ++;
        [text drawInRect:rect withAttributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:shadowColor}];
        rect.origin.x --;
        rect.origin.y --;
    }
    [text drawInRect:rect withAttributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:color}];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
@end

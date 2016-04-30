//
//  UIMLabelEx.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 13-12-26.
//  Copyright (c) 2013年 Suixing. All rights reserved.
//

#import "UIMLabelEx.h"
#import <hccoren/base.h>
#import <hccoren/JSON.h>
//#import "RegExCategories.h"

#define  FONT_DEFAULT @"ArialMT"
#define COLOR_DEFAULT UIColorFromRGB(0x277bdd)


@implementation UIMLabelEx
@synthesize fontName,fontSize,minFontSize;
@synthesize numberOfLines;
@synthesize textColor,textAlignment,text;
@synthesize realSize;
@synthesize horizonCenter;
@synthesize lineDiffMin,lineHeight;
@synthesize segmentSpace;
@synthesize autoChangeSize;
@synthesize isRowHeightFlexible;
@synthesize useHtml;
@synthesize shadowColor,shadowOffset;
@synthesize alignByCenter;
@synthesize autoUseHTML;
@synthesize autoIncNumberOfLines;
@synthesize lineBreakByWord;
@synthesize notUseHTMLFONT;
@synthesize stripeColor;
- (void)dealloc
{
    PP_RELEASE(text);
    PP_RELEASE(fontName);
    PP_RELEASE(textColor);
    PP_RELEASE(textArray_);
    PP_RELEASE(drawLines_);
    PP_RELEASE(shadowColor);
    PP_RELEASE(stripeColor);
    PP_SUPERDEALLOC;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        fontName = PP_RETAIN(FONT_DEFAULT);
        fontSize = 15;
        minFontSize = 6;
        numberOfLines = 1;
        lineDiffMin                    = 0;
        lineHeight                     = 20;
        isRowHeightFlexible = NO;  //行高是否弹性的，如果根据行数来更改控件大小，则行高需要固定。如果在一个固定的范围内显示多行，则行高可能是可变的。
        autoChangeSize = YES;
        alignByCenter = NO;
        useHtml = YES;
        segmentSpace = 1;
        textColor = PP_RETAIN([UIColor blackColor]);
        self.backgroundColor = [UIColor clearColor];
        realSize = frame.size;
        textAlignment = NSTextAlignmentLeft;
        horizonCenter = YES;
        autoUseHTML = YES;
        notUseHTMLFONT = NO;
        lineBreakByWord = NO;
        textArray_ =[[NSMutableArray alloc]init];
        drawLines_ = [[NSMutableArray alloc]init];
        self.userInteractionEnabled = NO;
        autoIncNumberOfLines = YES;
        stripeColor = PP_RETAIN([UIColor blackColor]);
    }
    return self;
}
-(CGSize)fillOrginalSize  //在现有空间中填充，行高原则上是可变的
{
    [self getStrings];
    NSString * retString = nil;
    
    BOOL needChange = YES;
//    isRowHeightFlexible = YES;
    int snumber = 0;
    CGFloat lastSize = self.fontSize;
    while (needChange) {
        [drawLines_ removeAllObjects];
        
        if(autoIncNumberOfLines && lastSize *(numberOfLines+1) <= self.frame.size.height && numberOfLines >0)
        {
            numberOfLines ++;
            isRowHeightFlexible = YES;
            lineDiffMin = 1;
            //            lineHeight = lastSize + lineDiffMin;
            if([text isEqualToString:@"Tomorrow"])
            {
                NSLog(@"begin track...");
            }
        }
        needChange = [self buildText:self.text
                         andRectSize:self.frame.size
                        andRetString:&retString
                         justgetSize:YES
                        stringnumber:snumber];
        if(needChange && autoChangeSize)
        {
            BOOL changed = NO;
            CGFloat cSize = 0;
            for (NSMutableDictionary * textDic in textArray_) {
                CGFloat size = [[textDic objectForKey:@"fontsize"]floatValue];
                if(size> minFontSize)
                {
                    size --;
                    [textDic setObject:@(size) forKey:@"fontsize"];
                    changed = YES;
                    cSize = MAX(cSize,size);
                }
            }
            if(changed==NO)
                needChange = NO;
            else
                lastSize = cSize;
            snumber ++;
        }
        if(!autoChangeSize) break;
    }
    
    if(horizonCenter)
    {
        CGFloat diffTop   = (self.frame.size.height - realSize.height+lineDiffMin /*减去最后的空间*/)/2;
        if(diffTop >=-0.5 && diffTop <=0.5) diffTop = 0;
        if(diffTop < 0 && numberOfLines>0) //当显示区域小于需要时，则压紧每行的空间
        {
            diffTop = diffTop *2 /numberOfLines;
            if(diffTop >=-0.5 && diffTop <=0.5) diffTop = 0;
            if(diffTop <0)
            {
                for (int i = 1;i< numberOfLines;i++) {
                    CGFloat diff = diffTop * i;
                    for (NSMutableDictionary * dic in drawLines_) {
                        int rowID = [[dic objectForKey:@"row"]intValue];
                        if(rowID==i)
                        {
                            CGFloat orgTop    = [[dic objectForKey:@"y"]floatValue];
                            orgTop            += diff;
                            [dic setObject:@(orgTop) forKey:@"y"];
                        }
                    }
                }
            }
        }
        else if(diffTop>0)
        {
            for (NSMutableDictionary * dic in drawLines_) {
                CGFloat orgTop    = [[dic objectForKey:@"y"]floatValue];
                orgTop            += diffTop;
                [dic setObject:@(orgTop) forKey:@"y"];
            }
        }
    }
    return realSize;
}
-(CGSize)fitRealSize  //自动变更大小，那么行高是固定的
{
    [self getStrings];
    NSString * retString = nil;
    BOOL needChange = YES;
//    isRowHeightFlexible = NO;
    int snumber = 0;
    CGFloat lastSize = self.fontSize;
    while (needChange) {
        [drawLines_ removeAllObjects];
        if(autoIncNumberOfLines &&lastSize *(numberOfLines+1) <= self.frame.size.height && numberOfLines >0)
        {
            numberOfLines ++;
            isRowHeightFlexible = YES;
            lineDiffMin = 1;
        }
        needChange = [self buildText:self.text
                         andRectSize:self.frame.size
                        andRetString:&retString
                         justgetSize:YES
                        stringnumber:snumber];
        if(needChange && autoChangeSize)
        {
            BOOL changed = NO;
            CGFloat cSize = 0;
            for (NSMutableDictionary * textDic in textArray_) {
                CGFloat size = [[textDic objectForKey:@"fontsize"]floatValue];
                if(size> minFontSize)
                {
                    size --;
                    [textDic setObject:@(size) forKey:@"fontsize"];
                    changed = YES;
                    cSize = MAX(cSize,size);
                }
            }
            if(changed==NO)
                needChange = NO;
            else
                lastSize = cSize;
            snumber ++;
        }
        if(!autoChangeSize) break;
    }

    CGRect frame                   = self.frame;
    frame.size.height              = realSize.height;
    self.frame                     = frame;
    return realSize;
}
-(NSMutableDictionary *)buildStringLine:(NSString *)newTextWithoutHtml orgText:(NSString *)orgText
{
    NSMutableDictionary * seg = [[NSMutableDictionary alloc]init];
    [seg setObject:orgText forKey:@"orgtext"];
    [seg setObject:fontName forKey:@"name"];
    [seg setObject:@"" forKey:@"attr"];
    [seg setObject:fontName forKey:@"fontname"];
    [seg setObject:@(fontSize) forKey:@"fontsize"];
    [seg setObject:textColor forKey:@"fontcolor"];
    [seg setObject:newTextWithoutHtml forKey:@"text"];
    return PP_AUTORELEASE(seg);
}
//将字串分成多个组
-(NSArray *)getStrings
{
    [textArray_ removeAllObjects];
    if(!text) return textArray_;
    if([text isKindOfClass:[NSString class]]==NO)
    {
        NSString * orgText = PP_RETAIN(text);
        PP_RELEASE(text);
        text = PP_RETAIN([(NSObject*)orgText JSONRepresentationEx]);
    }
    if(!text || text.length==0) return textArray_;
    if(!useHtml)
    {
        NSArray * array = [text componentsSeparatedByRegex:@"\r\n|\\||\r|\n"];
//         NSArray * array1 = [@"adfas|ccd\r\ndsafskf" componentsSeparatedByRegex:@"\r\n|\\||\r|\n"];
//        NSLog(@"%@,%@,%@",array1[0],array1[1],array1[2]);
//        NSRegularExpression * reg = [[NSRegularExpression alloc]initWithPattern:@"\r\n|\\||\r|\n"];
//        NSArray * array = [text split:reg];
//        PP_RELEASE(reg);
        
        if(array && array.count>1)
        {
            for(NSString * s in array)
            {
                [textArray_ addObject:[self buildStringLine:s orgText:s]];
            }
        }
        else
        {
            [textArray_ addObject:[self buildStringLine:text orgText:text]];
        }
        return textArray_;
    }
    
    NSError * error = nil;
    NSArray * temp = [text arrayOfCaptureComponentsMatchedByRegex:REGEX_HTML
                                                          options:RKLCaseless|RKLDotAll
                                                            range:NSMakeRange(0, text.length) error:&error];
    if(temp==nil)
    {
        NSLog(@"match error:%@",[error description]);
    }
    else
    {
        //        DLog(@"temp:%@",[temp JSONRepresentationEx]);
        if(temp.count==0 && text.length>0)
        {
            if(autoUseHTML)
            {
                [textArray_ addObject:[self buildStringLine:text orgText:text]];
                self.useHtml = NO;
                return textArray_;
            }
        }
        self.useHtml = YES;
        for (NSArray * components in temp) {
            //        for (RxMatch * components in temp) {
            NSMutableDictionary * seg = [[NSMutableDictionary alloc]init];
            [seg setObject:[components objectAtIndex:0] forKey:@"orgtext"];
            [seg setObject:[components objectAtIndex:1]  forKey:@"name"];
            [seg setObject:[components objectAtIndex:2]  forKey:@"attr"];
            [seg setObject:[components objectAtIndex:3]  forKey:@"text"];
            [textArray_ addObject:seg];
            
            //Parse parameters
            NSString * attrs = [seg objectForKey:@"attr" ];
            if(attrs && attrs.length>0 &&
               [[[seg objectForKey:@"name"] lowercaseString]isEqualToString:@"font"])
            {
                NSArray * attrsTemp = [attrs arrayOfCaptureComponentsMatchedByRegex:REGEX_PARA
                                                                            options:RKLCaseless|RKLDotAll
                                                                              range:NSMakeRange(0, attrs.length)
                                                                              error:&error];
                if(!attrsTemp)
                {
                    NSLog(@"match error:%@",[error description]);
                }
                else
                {
                    //                    DLog(@"temp:%@",[attrsTemp JSONRepresentationEx]);
                    BOOL hasName = NO;
                    BOOL hasSize = NO;
                    BOOL hasColor = NO;
                    for (NSArray * att in attrsTemp) {
                        //                    for(RxMatch * att in attrsTemp){
                        //                        NSString * name = [(RxMatchGroup *)[att.groups objectAtIndex:1] value];
                        NSString * name = [att objectAtIndex:1];
                        name = [name lowercaseString];
                        
                        if([name isEqualToString:@"size"]||
                           [name isEqualToString:@"name"]||
                           [name isEqualToString:@"color"]||
                           [name isEqualToString:@"strike"])
                        {
                            NSString * v1 = [att objectAtIndex:3];
                            NSString * v2 = [att objectAtIndex:4];
                            if(v1 && v1.length==0 &&v2 && v2.length>0)
                                v1 = v2;
                            
                            if(!notUseHTMLFONT && [name isEqualToString:@"name"])
                            {
                                [seg setObject:v1 forKey:@"fontname"];
                                hasName = YES;
                            }
                            else if(!notUseHTMLFONT && [name isEqualToString:@"size"])
                            {
                                CGFloat fs = [v1 floatValue];
                                if(fs==0) fs = self.fontSize;
                                [seg setObject:[NSNumber numberWithFloat:fs] forKey:@"fontsize"];
                                hasSize = YES;
                            }
                            else if([name isEqualToString:@"color"])
                            {
                                UIColor * color = [self parseColor:v1];
                                [seg setObject:color forKey:@"fontcolor"];
                                hasColor = YES;
                            }
                            else if([name isEqualToString:@"strike"])
                            {
                                if([[v1 lowercaseString]isEqualToString:@"yes"])
                                {
                                    [seg setObject:[NSNumber numberWithBool:YES] forKey:@"strike"];
                                }
                            }
                        }
                        if(!hasColor)
                        {
                            if(textColor)
                                [seg setObject:textColor forKey:@"fontcolor"];
                            else
                                [seg setObject:COLOR_DEFAULT forKey:@"fontcolor"];
                        }
                        if(!hasName)
                        {
                            [seg setObject:self.fontName?self.fontName:FONT_DEFAULT forKey:@"fontname"];
                        }
                        if(!hasSize)
                        {
                            [seg setObject:[NSNumber numberWithFloat:self.fontSize] forKey:@"fontsize"];
                        }
                    }
                }
            }
            //            DLog(@"parse seg:%@",seg);
            PP_RELEASE(seg);
        }
    }
    //    DLog(@"textarray:%@",textArray_);
    return textArray_;
}
-(UIColor *)parseColor:(NSString*)colorString
{
    //    Rx* rxColor = [REGEX_COLORA toRxWithOptions:NSRegularExpressionCaseInsensitive];
    //    NSArray * temp =[text matchesWithDetails:rxColor];
    
    NSError * error = nil;
    NSArray * temp = [colorString componentsMatchedByRegex:REGEX_COLORA
                                                   options:RKLNoOptions
                                                     range:NSMakeRange(0, colorString.length)
                                                   capture:0
                                                     error:&error];
    if(error)
    {
        NSLog(@"error:%@",error);
    }
    if(temp && temp.count>0)
    {
        //        NSString * colorValue =  [(RxMatchGroup*)[temp objectAtIndex:0] value];
        NSString * colorValue =  [temp objectAtIndex:0];
        NSLog(@"colorValue:%@",colorValue);
        //        if(colorValue.length==3)
        //        {
        //
        //        }
        //        else
        //        {
        //
        //        }
        return [CommonUtil colorFromHexRGB:colorValue];
    }
    else
    {
        //        Rx* rxColor = [REGEX_COLORB toRxWithOptions:NSRegularExpressionCaseInsensitive];
        //        NSArray * temp =[text matchesWithDetails:rxColor];
        temp =[colorString componentsMatchedByRegex:REGEX_COLORB];
        if(temp && temp.count>0)
        {
            
            //            NSString * colorString = [[(RxMatchGroup*)[temp objectAtIndex:0]value]lowercaseString];
            NSString * colorString = [[temp objectAtIndex:0]lowercaseString];
            return [CommonUtil colorFromHexRGB:colorString];
//            if([colorString isEqualToString:@"color_a"])
//                return COLOR_A;
//            else if([colorString isEqualToString:@"color_b"])
//                return COLOR_B;
//            else if([colorString isEqualToString:@"color_c"])
//                return COLOR_C;
//            else if([colorString isEqualToString:@"color_d"])
//                return COLOR_D;
//            else if([colorString isEqualToString:@"color_e"])
//                return COLOR_E;
//            else if([colorString isEqualToString:@"color_f"])
//                return COLOR_F;
//            else if([colorString isEqualToString:@"color_g"])
//                return COLOR_G;
//            else if([colorString isEqualToString:@"color_h"])
//                return COLOR_H;
//            else if([colorString isEqualToString:@"color_i"])
//                return COLOR_I;
//            else if([colorString isEqualToString:@"color_j"])
//                return COLOR_J;
//            else if([colorString isEqualToString:@"color_k"])
//                return COLOR_K;
//            else if([colorString isEqualToString:@"color_l"])
//                return COLOR_L;
//            else if([colorString isEqualToString:@"color_m"])
//                return COLOR_M;
//            else if([colorString isEqualToString:@"color_n"])
//                return COLOR_N;
//            else if([colorString isEqualToString:@"color_o"])
//                return COLOR_O;
//            else if([colorString isEqualToString:@"color_p"])
//                return COLOR_P;
//            else if([colorString isEqualToString:@"color_q"])
//                return COLOR_Q;
//            else if([colorString isEqualToString:@"color_r"])
//                return COLOR_R;
//            else if([colorString isEqualToString:@"color_s"])
//                return COLOR_S;
//            else if([colorString isEqualToString:@"color_t"])
//                return COLOR_T;
//            //            else if([colorString isEqualToString:@"color_u"])
//            //                return COLOR_U;
//            //            else if([colorString isEqualToString:@"color_v"])
//            //                return COLOR_V;
//            else if([colorString isEqualToString:@"color_w"])
//                return COLOR_W;
//            else if([colorString isEqualToString:@"color_x"])
//                return COLOR_X;
//            else if([colorString isEqualToString:@"color_y"])
//                return COLOR_Y;
//            else if([colorString isEqualToString:@"color_z"])
//                return COLOR_Z;
//            else if([colorString isEqualToString:@"color_af"])
//                return COLOR_AF;
//            else if([colorString isEqualToString:@"color_ad"])
//                return COLOR_AD;
//            else if([colorString isEqualToString:@"color_login"])
//                return COLOR_C;
//            else if([colorString isEqualToString:@"color_ii"])
//            {
//                return COLOR_I;
//            }
        }
    }
//    return COLOR_D;
    return nil;
}
-(CGFloat)adjustRowHeight:(int)row changeLeft:(BOOL)changeLeft
{
    CGFloat rowheight = 0;
    CGFloat rowWidth = 0;
    CGFloat xDiff = 0;
    NSMutableArray * lines = [NSMutableArray new];
    for (NSMutableDictionary * rowDic in drawLines_) {
        int rowID = [[rowDic objectForKey:@"row"]intValue];
        if(rowID == row)
        {
            rowheight = MAX(rowheight,[[rowDic objectForKey:@"height"]floatValue]);
            if(changeLeft)
                rowWidth += [[rowDic objectForKey:@"width"]floatValue]+segmentSpace;
            [lines addObject:rowDic];
        }
    }
    if(changeLeft)
    {
        if(rowWidth > segmentSpace)
            rowWidth -= segmentSpace;
        if(textAlignment == NSTextAlignmentCenter)
        {
            xDiff = (self.frame.size.width - rowWidth)/2.0f;
            if(xDiff<1) xDiff = 0;
        }
        else if(textAlignment == NSTextAlignmentRight)
        {
            xDiff = (self.frame.size.width - rowWidth);
            if(xDiff <1) xDiff = 0;
        }
        
        //adjust top
        for (NSMutableDictionary * rowDic in lines) {
            CGFloat cHeight = [[rowDic objectForKey:@"height"]floatValue];
            CGFloat cTop =[[rowDic objectForKey:@"y"]floatValue];
            CGFloat top = cTop + (alignByCenter?((isRowHeightFlexible?rowheight:lineHeight) - cHeight)/2.0f: rowheight - cHeight);
            [rowDic setObject:@(top) forKey:@"y"];
            if(changeLeft && xDiff>0)
            {
                CGFloat left = [[rowDic objectForKey:@"x"]floatValue];
                left += xDiff;
                [rowDic setObject:@(left) forKey:@"x"];
            }
        }
    }
    PP_RELEASE(lines);
    if(isRowHeightFlexible)
        return rowheight + lineDiffMin;
    else
        return lineHeight;
}
//将TextLines转成可以显示的Drawlines。
-(BOOL)buildText:(NSString *)message andRectSize:(CGSize)size
    andRetString:(NSString * *)retString
     justgetSize:(BOOL)getSize stringnumber:(int)snumber
{
    CGFloat top = 0;
    CGFloat left = 0;
    CGFloat width = 0;
    CGFloat height = 0;
    CGFloat lineCount = 0;
    CGFloat rowHeight = 0;
    int segNumber = 0;
    BOOL isAllShow = NO;
    BOOL needDecreaseSize = NO;
    //    BOOL isOutHeight = FALSE;
    CGFloat topOrg                 = 0;
    //    DLog(@"parse time:%d",snumber);
    //逐段处理文字
    realSize = CGSizeZero;
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingGB_18030_2000);
	
    for (NSDictionary * textDic in textArray_) {
        segNumber ++;
        //        DLog(@"textDic:%@",textDic);
        
        CGFloat cFontSize =[[textDic objectForKey:@"fontsize"]floatValue];
        UIFont * fontTemp = [UIFont fontWithName:[textDic objectForKey:@"fontname"]
                                            size:cFontSize];
        if(!fontTemp)
        {
            fontTemp = [UIFont fontWithName:self.fontName size:self.fontSize];
            cFontSize = self.fontSize;
        }
        NSString * segText = [textDic objectForKey:@"text"];
        //本行剩余RECT范围
        //如果非HTML下，每段String各占一行。
        if(useHtml ==NO || left > size.width - cFontSize)
            left = 0;
        CGSize lineRect = CGSizeMake(size.width - left, MIN((size.height - top),lineHeight));
        //文字占用的大小
        //CGSize segSize = [segText sizeWithFont:fontTemp];
        
        NSDictionary *attribute = @{NSFontAttributeName: fontTemp};
        CGSize segSize = [segText boundingRectWithSize:CGSizeMake(1000, MAXFLOAT)
                                               options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                            attributes:attribute context:nil].size;
        
        
        //如果能显示完成，则可以放置在其中
        if(segSize.width <= lineRect.width /*&& segSize.height <= lineRect.height*/)
        {
            NSMutableDictionary *dic       = [NSMutableDictionary dictionaryWithObjectsAndKeys:segText,@"text",
                                              @(top+topOrg),@"y",//+(lineRect.height - lineDiffMin - segSize.height)),@"y",
                                              @(left),@"x",
                                              fontTemp,@"font",
                                              @(segSize.width),@"width",
                                              @(segSize.height),@"height",
                                              [textDic objectForKey:@"fontcolor"],@"color",
                                              @(lineCount),@"row",
                                              nil];
            if([textDic objectForKey:@"strike"])
            {
                [dic setObject:[textDic objectForKey:@"strike"] forKey:@"strike"];
            }
            [drawLines_ addObject:dic];
            width = MAX(width,left +segSize.width);
            rowHeight = [self adjustRowHeight:lineCount changeLeft:NO];
            height = MAX(height,top + rowHeight + lineDiffMin);
            left += segSize.width + segmentSpace;
            if(useHtml  == NO || left >= size.width -cFontSize)
            {
                //判断行数是否已经到达指定值
                rowHeight = [self adjustRowHeight:lineCount changeLeft:NO];
                lineCount ++;
               // if(numberOfLines>0 && lineCount >=numberOfLines)//****   /* &&segNumber >= textArray_.count)*/
                 if(numberOfLines>0 && lineCount > numberOfLines)
                {
                    if(segNumber>=textArray_.count)
                    {
                        //                        isAllShow = YES;
                        needDecreaseSize = NO;
                        break;
                    }
                    else
                    {
                        //                        isAllShow = YES;
                        needDecreaseSize = YES;
                        break;
                    }
                }
                else
                {
                    top += rowHeight ;//+ lineDiffMin);// lineHeight;
                    rowHeight = 0;
                    left = 0;
                    continue;
                }
            }
        }
        //需要拆份成多行
        else
        {
            //        REPEATER:
            //逐字判断，是否在显示范围内
            while (segText && segText.length>0) {
                NSString * retString = nil;
                for (int charIndex = (int)segText.length;charIndex>=0;charIndex--) {
                    NSString * temp = [segText substringToIndex:charIndex];
                    //文字占用的大小
                    segSize = [temp sizeWithAttributes: @{NSFontAttributeName:fontTemp}];
//                    segSize = [temp sizeWithFont:fontTemp];
                    if(segSize.width <= lineRect.width /*&& segSize.height <= lineRect.height*/)
                    {
                        //判断是否根据词来分行,最后一行不分
                        if(lineBreakByWord && charIndex < segText.length &&
                           ((numberOfLines>0 && lineCount <numberOfLines) ||numberOfLines<=0))
                        {
                            int index2 = charIndex;
                            for (int indexTemp = charIndex ;indexTemp >=0;indexTemp--) {
                                NSData *gb2312_data = [[segText substringWithRange:NSMakeRange(indexTemp, 1) ] dataUsingEncoding:enc];
                                //如果是中文或其它的，则不需要再处理
                                char *gb2312_string = (char *)[gb2312_data bytes];
                                if(gb2312_data.length>=2)
                                {
                                    unsigned char ucHigh = (unsigned char)gb2312_string[0];
                                    unsigned char ucLow  = (unsigned char)gb2312_string[1];
                                    if ( ucHigh < 0xa1 || ucLow < 0xa1)
                                    {
                                        if(ucLow<=0x30)
                                        {
                                            index2 = indexTemp;
                                            break;
                                        }
                                        else
                                            continue;
                                    }
                                    else
                                    {
                                        index2 = indexTemp;
                                        break;
                                    }
                                }
                                else
                                {
                                    unsigned char ucHigh = (unsigned char)gb2312_string[0];
                                    if(ucHigh<=0x30||ucHigh=='|')
                                    {
                                        index2 = indexTemp;
                                        break;
                                    }
                                    else
                                        continue;
                                }
                            }
                            if(index2<charIndex && index2>0)
                            {
                                charIndex = index2;
                                temp = [segText substringToIndex:charIndex];
                                segSize = [temp sizeWithAttributes: @{NSFontAttributeName:fontTemp}];
//                                segSize = [temp sizeWithFont:fontTemp];
                            }
                        }
                        NSMutableDictionary *dic       = [NSMutableDictionary dictionaryWithObjectsAndKeys:temp,@"text",
                                                          @(top+topOrg),@"y",
                                                          //+(lineRect.height - lineDiffMin - segSize.height)),@"y",
                                                          @(left),@"x",
                                                          fontTemp,@"font",
                                                          @(segSize.width),@"width",
                                                          @(segSize.height),@"height",
                                                          [textDic objectForKey:@"fontcolor"],@"color",
                                                          @(lineCount),@"row",
                                                          nil];
                        
                        if([textDic objectForKey:@"strike"])
                        {
                            [dic setObject:[textDic objectForKey:@"strike"] forKey:@"strike"];
                        }
                        //                        DLog(@"dic:%@",dic);
                        if(charIndex < segText.length)
                        {
                            retString = [segText substringFromIndex:charIndex];
                            if(lineBreakByWord)
                            {
                                while ([retString hasPrefix:@" "]||[retString hasPrefix:@"|"])
                                {
                                    retString = [retString substringFromIndex:1];
                                    if(retString.length<1)
                                    {
                                        break;
                                    }
                                }
                            }
                        }
                        else
                            retString = nil;
                        
                        
                        
                        if(numberOfLines>0 && lineCount >numberOfLines )
                        {
                            lineCount ++;
                            isAllShow = YES; //不用往下显示了，已经显示完成了，因此可能需要中断，但需要变更字体
                            break;
                        }
                        else
                        {
                            [drawLines_ addObject:dic];
                            
                            width = MAX(width,left +segSize.width);
                            //因为已经超长了，则肯定是行要增加了
                            if(left+segSize.width > size.width -cFontSize||(retString && retString.length>0))
                            {
                                rowHeight = [self adjustRowHeight:lineCount changeLeft:NO];
                                lineCount ++;
                            }
                            else
                            {
                                rowHeight = [self adjustRowHeight:lineCount changeLeft:NO];
                            }
                            //                            rowHeight = MAX(rowHeight,segSize.height + lineDiffMin);
                            height = MAX(height,top + rowHeight);
                            break;
                        }
                    }
                }
                if(isAllShow)
                {
                    if(autoChangeSize)
                    {
                        needDecreaseSize = YES;
                    }
                    break;
                }
                else if(retString==nil||retString.length==0) //本段已经显示完成
                {
                    left += segSize.width + segmentSpace;
                    //在上一行刚刚显示完成时。
                    if(left + cFontSize > size.width)
                        left = 0;
                    width = MAX(width,left);
                    //                    rowHeight = MAX(rowHeight,segSize.height + lineDiffMin);
                    height = MAX(height,top + rowHeight);
                    
                    break;
                }
                else //未显示完，则需要将剩余的字串铺到下一行
                {
                    top += rowHeight;
                    if(retString && retString.length>0
                       && lineCount +1 >numberOfLines
                       && numberOfLines>0)
                    {
                        isAllShow = YES;
                        needDecreaseSize = YES;
                        break;
                    }
                    left = 0;
                    rowHeight = 0;
                    if(retString)
                    {
                        //                        lineCount ++;
                        segText = retString;
                        lineRect = CGSizeMake(size.width - left, MIN((size.height - top),lineHeight));
                        continue;
                    }
                    
                }
            }
            if(isAllShow)
            {
                break;
            }
        }
    }
    if(isRowHeightFlexible)
        height -= lineDiffMin;
    
    realSize = CGSizeMake(width, height);
    if(!needDecreaseSize)
    {
        for (int i=0;i<=lineCount;i++) {
            [self adjustRowHeight:i changeLeft:YES];
        }
        //        DLog(@"last parse:%@",drawLines_);
    }
    return needDecreaseSize;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGFloat top                    = 0;
    CGFloat left                   =0;
    //    DLog(@"draw lines:%@",drawLines_);
    //    CGFloat height                 = self.frame.size.height;
    for (int i                     = 0;i<drawLines_.count;i++) {
        NSDictionary * dic             = [drawLines_ objectAtIndex:i];
        
        NSString * stringTemp          = [dic objectForKey:@"text"];
        top                            = [[dic objectForKey:@"y"]floatValue];
        left                            = [[dic objectForKey:@"x"]floatValue];
        //        CGSize size0                   =
        [self drawText:stringTemp
                     x:left
                     y:top
                  font:[dic objectForKey:@"font"]
                 color:[dic objectForKey:@"color"]
                stripe:[dic objectForKey:@"strike"] && [[dic objectForKey:@"strike"]boolValue]?YES:NO
                 width:[[dic objectForKey:@"width"]floatValue]
                height:[[dic objectForKey:@"height"]floatValue]
         ];
        //        if(size0.width >= self.frame.size.width && size0.height>=height)
        //        {
        //            break;
        //        }
        //        else
        //        {
        //            height      -= size0.height;
        //        }
    }
}
- (CGSize)drawText:(NSString*)message x:(CGFloat)x y:(CGFloat)y font:(UIFont*)fontTemp color:(UIColor*)color stripe:(BOOL)stripe width:(CGFloat)width height:(CGFloat)height
{
    UIFont *textFont               = fontTemp;
    if (message) {
        if(shadowColor && (shadowOffset.width!=0||shadowOffset.height!=0))
        {
            [shadowColor set];
//            segSize = [temp sizeWithAttributes: @{NSFontAttributeName:fontTemp}];
            [message drawAtPoint:CGPointMake(x+shadowOffset.width, y+shadowOffset.height) withAttributes:@{NSFontAttributeName:textFont}];
//            [message drawAtPoint:CGPointMake(x+shadowOffset.width, y+shadowOffset.height) withFont:textFont];
        }
        [color set];
        [message drawAtPoint:CGPointMake(x, y) withAttributes:@{NSFontAttributeName:textFont}];
//        [message drawAtPoint:CGPointMake(x, y) withFont:textFont];
    }
    if(stripe)
    {
        [stripeColor set];
        CGRect lineRect = CGRectMake(x+1, y+height/2.0f -0.5f, width-1, 1);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextFillRect(context, lineRect);
    }
    return CGSizeZero;
}

@end


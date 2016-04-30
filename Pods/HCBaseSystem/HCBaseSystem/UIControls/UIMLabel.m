////
////  UIMLabel.m
////  RBNews
////
////  Created by XUTAO HUANG on 13-5-22.
////  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
////
//
//#import "UIMLabel.h"
//
//@implementation UIMLabel
//@synthesize font,textColor,text;
//@synthesize numberOfLines,lineHeight;
//@synthesize textAlignment;
//- (void)dealloc
//{
//    self.textColor = nil;
//    self.font = nil;
////    self.backgroundColor = nil;
//    self.text = nil;
//    [super dealloc];
//}
//
//- (id)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code
//    }
//    return self;
//}
//-(void)fitToSize
//{
//    CGSize size0 = [self size:nil autoFill:NO];
//    CGRect frame  = self.frame;
//    frame.size = size0;
//    self.frame = frame;
//}
//-(CGSize)size:(NSString **)retString autoFill:(BOOL)autoFill{
//    CGSize size0 =  [self buildText:self.text andRectSize:self.frame.size andRetString:retString justgetSize:YES];
//    if(autoFill)
//    {
//        CGRect frame  = self.frame;
//        frame.size.height = size0.height;
//        self.frame = frame;
//    }
//    return size0;
//}
//-(CGSize)buildText:(NSString *)message andRectSize:(CGSize)size andRetString:(NSString * *)retString justgetSize:(BOOL)getSize
//{
//    CGFloat upX = 0;
//    CGFloat upY = 0;
//    CGFloat X = 0;
//    CGFloat Y = 0;
////    BOOL isOutHeight = FALSE;
//    
//    UIFont *fon = self.font;
//    //CGFloat Width = 0;
//    NSMutableString * retTemp = [[NSMutableString alloc]init];
//    BOOL notEND = NO;
//    if (message) {
//        int lPos = 0;
//        CGFloat orgX = upX;
//        for (int j = 1; j <= [message length]; j++) {
//            NSString *temp = [message substringWithRange:NSMakeRange(lPos, j - lPos)];
//            CGSize cSize=[temp sizeWithFont:fon constrainedToSize:CGSizeMake(400, 200)];
//            if((j >= [message length] )|| (cSize.width >= size.width - orgX))
//            {
//                if(j-lPos>1 &&(cSize.width > size.width - orgX)) //超过了，则需要回退
//                {
//                    j--;
//                    temp = [message substringWithRange:NSMakeRange(lPos, j - lPos)];
//                    cSize=[temp sizeWithFont:fon constrainedToSize:CGSizeMake(1024, 1024)];
//                    cSize.width = size.width;
//                }
//                if(j>=[message length]) notEND = NO;
//                
//                lPos = j;
//                if(cSize.width >= size.width - orgX)
//                {
//                    upY = upY + self.lineHeight ;
//                    Y =upY;
//                    X = size.width;
//                    upX = 0;
//                    notEND = NO;
//                    if(upY >= size.height && size.height>0) //如果限制高度
//                    {
//                        if(j < [message length])
//                        {
//                            [retTemp appendString:[message substringFromIndex:j]];
//                        }
////                        isOutHeight = TRUE;
//                        break;
//                    }
//                }
//                else
//                    upX=orgX+cSize.width;
//                
//                if(j<[message length])
//                    notEND = YES;
//                
//            }
//            else
//                upX=orgX+cSize.width;
//        }
//        if (X<size.width) {
//            X = upX;
//        }
//    }
//    if(retTemp.length >0)
//    {
//        if(retString)
//            (* retString) = [NSString stringWithString:retTemp];
//    }
//    else if(notEND == NO)
//    {
//        Y += self.lineHeight;
//    }
//    [retTemp release];
//    return CGSizeMake(X, Y);
//}
//
//
//// Only override drawRect: if you perform custom drawing.
//// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect
//{
////    CGContextRef context = UIGraphicsGetCurrentContext();
////    CGContextSetRGBFillColor(context, 240.0f/255, 240.0f/255, 240.0f/255, 0.0f); // translucent white
////    CGContextFillRect(context, rect);
//
//    if(self.textColor)
//    {
//        [self.textColor set];
//    }
//    else
//    {
//        [[UIColor blackColor]set];
//    }
//    UIFont *textFont = nil;
//    if(self.font)
//    {
//        textFont = self.font;
//    }
//    else
//    {
//        textFont = [UIFont systemFontOfSize:12];
//    }
//    CGFloat upX = 0;
//    CGFloat upY = 0;
////    CGFloat X = 0;
////    CGFloat Y = 0;
////    BOOL isOutHeight = FALSE;
//    
//    UIFont *fon = self.font;
////    BOOL notEND = NO;
//    CGSize size = self.frame.size;
//    NSString * message = self.text;
//    if (message) {
//        int lPos = 0;
//        CGFloat orgX = upX;
//        for (int j = 1; j <= [message length]; j++) {
//            NSString *temp = [message substringWithRange:NSMakeRange(lPos, j - lPos)];
//            CGSize cSize=[temp sizeWithFont:fon constrainedToSize:CGSizeMake(1024, 1024)];
//            if((j >= [message length] )|| (cSize.width >= size.width - orgX))
//            {
//                CGFloat realWidth = cSize.width;
//                if(j-lPos>1 &&(cSize.width > size.width - orgX)) //超过了，则需要回退
//                {
//                    j--;
//                    temp = [message substringWithRange:NSMakeRange(lPos, j - lPos)];
//                    cSize=[temp sizeWithFont:fon constrainedToSize:CGSizeMake(1024, 1024)];
//                    realWidth = cSize.width;
//                    cSize.width = size.width;
//                }
//                if(textAlignment==NSTextAlignmentLeft)
//                {
//                    [temp drawAtPoint:CGPointMake(orgX, upY) withFont:textFont];
//                }
//                else if(textAlignment==NSTextAlignmentCenter)
//                {
//                    CGFloat newX  = (self.frame.size.width - realWidth)/2 + orgX;
//                    [temp drawAtPoint:CGPointMake(newX, upY) withFont:textFont];
//                }
//                else if(textAlignment==NSTextAlignmentRight)
//                {
//                    CGFloat newX  = (self.frame.size.width - realWidth);
//                    [temp drawAtPoint:CGPointMake(newX, upY) withFont:textFont];
//                }
//                else
//                {
//                    [temp drawAtPoint:CGPointMake(orgX, upY) withFont:textFont];
//                }
//                    
//                lPos = j;
//                if(cSize.width >= size.width - orgX)
//                {
//                    upY = upY + self.lineHeight ;
//                    if(upY >= size.height && size.height>0) //如果限制高度
//                    {
//                        break;
//                    }
//                }
//            }
//        }
//    }
//}
//
//
//@end

//
//  UIMLabel.m
//  RBNews
//
//  Created by XUTAO HUANG on 13-5-22.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "UIMLabel.h"
@implementation UIMLabel
@synthesize font,textColor,text,fontName,fontSize,minFontSize,secondFontName;
@synthesize numberOfLines,lineHeight,lineDiffMin;
@synthesize autoChangeFontSize;
@synthesize isAllChangeSize;
@synthesize textAlignment;
@synthesize splitChar;
@synthesize horizonCenter;
- (void)dealloc
{
    self.textColor                 = nil;
    self.font                      = nil;
    //    self.backgroundColor = nil;
    self.text                      = nil;
    PP_RELEASE(secondFontName);
    PP_RELEASE(fontName);
    PP_RELEASE(textArray_);
    PP_RELEASE(drawLines_);
    PP_RELEASE(splitChar);
    PP_SUPERDEALLOC;
}

- (id)initWithFrame:(CGRect)frame
{
    self                           = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        splitChar                      = nil; //PP_RETAIN(@"|");
        horizonCenter                  = YES;
        autoChangeFontSize             = YES;
        textArray_                     = [[NSMutableArray alloc]init];
        drawLines_                     = [[NSMutableArray alloc]init];
        lineDiffMin                    = 4;
        lineHeight                     = 20;
        minFontSize                    = 8;
        fontSize                       = 16;
        fontName                       = PP_RETAIN(@"ArialMT");
        secondFontName                 = PP_RETAIN(@"ArialMT");
        self.userInteractionEnabled    = NO;
        isAllChangeSize = NO;
        self.backgroundColor = [UIColor clearColor];
        self.textColor = [UIColor blackColor];
    }
    return self;
}
-(CGSize)fitToRealSize
{
    CGSize size0                   = [self size:nil autoFill:YES];
    CGRect frame                   = self.frame;
    frame.size                     = size0;
    self.frame                     = frame;
    return size0;
}
- (CGSize)autoFillSize
{
    CGSize size0 =[self size:nil autoFill:NO];
    //    CGSize size0 = [self size:nil autoFill:NO];
    //    CGRect frame  = self.frame;
    //    frame.size = size0;
    //    self.frame = frame;
    return size0;
}
-(NSArray *)getStrings
{
    [textArray_ removeAllObjects];
    if(!self.text) return textArray_;
    if(!splitChar||splitChar.length==0)
    {
        [textArray_ addObject:text==nil?@"":text];
        return textArray_;
    }
    NSRange range                  = [self.text rangeOfString:splitChar];
    if(range.length>0)
    {
        {
            [textArray_ addObject:[text substringToIndex:range.location]];
        }
        {
            [textArray_ addObject:[text substringFromIndex:range.location+1]];
        }
        return textArray_;
    }
    else
    {
        [textArray_ addObject:text==nil?@"":text];
        return textArray_;
    }
}
// autofill 是否自动变更大小，这个与原意有些区别。否，表示自动填充，不变更大小。是表示自动变更大小
-(CGSize)size:(NSString **)retString autoFill:(BOOL)autoFill{
    [drawLines_ removeAllObjects];
    if(splitChar && splitChar.length>0)
    {
        NSArray * array                = [self getStrings];
        CGFloat top                    = 0;
        CGFloat height                 = self.frame.size.height;
        CGFloat width                  = self.frame.size.width;
        for (int i                     = 0;i<array.count;i++) {
            NSString * stringTemp          = [array objectAtIndex:i];
            CGSize size0                   = [self buildText:stringTemp
                                                 andRectSize:self.frame.size
                                                andRetString:retString
                                                 justgetSize:YES stringnumber:i];
            if(size0.width >= self.frame.size.width && size0.height>=height)
            {
                if(retString && *retString)
                {
                    if(i<array.count-1)
                        *retString                     = [NSString stringWithFormat:@"%@%@%@",(*retString),
                                                          splitChar,[array objectAtIndex:array.count-1]];
                }
                top                            = self.frame.size.height;
                break;
            }
            else
            {
                if(autoFill)
                {
                    top                            += size0.height;
                    width                          = MAX(self.frame.size.width, size0.width);
                }
                else
                {
                    height                         -= size0.height;
                }
            }
        }
        if(horizonCenter && top != self.frame.size.height && !autoFill)
        {
            CGFloat diffTop                = (self.frame.size.height - drawLines_.count * lineHeight+lineDiffMin /*减去最后的空间*/ )/2 ;
            for (NSMutableDictionary * dic in drawLines_) {
                CGFloat orgTop                 = [[dic objectForKey:@"y"]floatValue];
                orgTop                         += diffTop;
                [dic setObject:@(orgTop) forKey:@"y"];
            }
        }
        CGSize sizeA                   = CGSizeMake(width, !autoFill?MAX(top,self.frame.size.height):top);
        if(autoFill)
        {
            CGRect frameA                  = self.frame;
            frameA.size.height             = sizeA.height;
            self.frame                     = frameA;
        }
        return sizeA;
    }
    else
    {
        CGSize size0                   = [self buildText:self.text andRectSize:self.frame.size
                                            andRetString:retString justgetSize:YES stringnumber:0];
        if(autoFill)
        {
            CGRect frame                   = self.frame;
            frame.size.height              = size0.height;
            self.frame                     = frame;
        }
        else if(horizonCenter && size0.height != self.frame.size.height && !autoFill)
        {
            
            CGFloat diffTop                = (self.frame.size.height - drawLines_.count * lineHeight+lineDiffMin /*减去最后的空间*/)/2;
            //            diffTop += lineDiffMin /*减去最后的空间*/;
            for (NSMutableDictionary * dic in drawLines_) {
                CGFloat orgTop                 = [[dic objectForKey:@"y"]floatValue];
                orgTop                         += diffTop;
                [dic setObject:@(orgTop) forKey:@"y"];
            }
            
        }
        return size0;
    }
}
-(CGSize)buildText:(NSString *)message andRectSize:(CGSize)size andRetString:(NSString * *)retString justgetSize:(BOOL)getSize stringnumber:(int)snumber
{
    CGFloat upX                    = 0;
    CGFloat upY                    = 0;
    CGFloat X                      = 0;
    CGFloat Y                      = 0;
    //    BOOL isOutHeight = FALSE;
    CGFloat topOrg                 = 0;
    for (NSDictionary * dic in drawLines_) {
        if([dic objectForKey:@"height"])
        {
            topOrg                         += [[dic objectForKey:@"height"]floatValue];
        }
        else
        {
            topOrg                         += lineHeight;
        }
    }
    
    UIFont *fontTemp               = nil;
    if(snumber>0)
    {
        fontTemp                       = [UIFont fontWithName:secondFontName size:fontSize];
    }
    else
    {
        fontTemp                       = self.font?self.font:[UIFont fontWithName:fontName size:fontSize];
    }
    //CGFloat Width = 0;
    NSMutableString * retTemp      = [[NSMutableString alloc]init];
    BOOL notEND                    = NO;
    if (message) {
        int lPos                       = 0;
        CGFloat orgX                   = upX;
        CGFloat sizeNumber             = -1;
        for (int j                     = 1; j <= [message length]; j++) {
            NSString *temp                 = [message substringWithRange:NSMakeRange(lPos, j - lPos)];
            CGSize cSize = [CommonUtil sizeOfString:temp withFont:fontTemp width:400 height:600];
//            CGSize cSize=[temp sizeWithFont:fontTemp constrainedToSize:CGSizeMake(400, 600)];
            //只有最后一行使用自动缩放字体，尽量将大小放到范围内
            if((cSize.width >= size.width - orgX) && autoChangeFontSize && (drawLines_.count>0||isAllChangeSize))
            {
                if(sizeNumber ==-1) sizeNumber = fontSize;
                if(snumber>0)
                    fontTemp                       = [UIFont fontWithName:secondFontName size:sizeNumber];
                else
                    fontTemp                       = [UIFont fontWithName:fontName size:sizeNumber];
                 cSize = [CommonUtil sizeOfString:temp withFont:fontTemp width:400 height:600];
//                cSize=[temp sizeWithFont:fontTemp constrainedToSize:CGSizeMake(400, 600)];
                while (cSize.width >=size.width - orgX && sizeNumber>minFontSize) {
                    sizeNumber --;
                    fontTemp                       = [UIFont fontWithName:fontName size:sizeNumber];
                    cSize = [CommonUtil sizeOfString:temp withFont:fontTemp width:400 height:600];
//                    cSize=[temp sizeWithFont:fontTemp constrainedToSize:CGSizeMake(400, 600)];
                }
                if(sizeNumber>8 && j < message.length) continue;
            }
            if((j >= [message length] )|| (cSize.width >= size.width - orgX))
            {
                if(j-lPos>1 &&(cSize.width > size.width - orgX)) //超过了，则需要回退
                {
                    j--;
                    temp                           = [message substringWithRange:NSMakeRange(lPos, j - lPos)];
                    CGSize cSize = [CommonUtil sizeOfString:temp withFont:fontTemp width:1024 height:1024];
//                    cSize=[temp sizeWithFont:fontTemp constrainedToSize:CGSizeMake(1024, 1024)];
                    cSize.width                    = size.width;
                    NSMutableDictionary *dic       = [NSMutableDictionary dictionaryWithObjectsAndKeys:temp,@"text",
                                                      @(upY+topOrg),@"y",
                                                      nil];
                    //                    if(sizeNumber>=8)
                    //                    {
                    [dic setObject:fontTemp forKey:@"font"];
                    //                    }
                    [drawLines_ addObject:dic];
                    //如果是自动缩放，则需跳出循环
                    if(sizeNumber>-1 && sizeNumber<=15)
                    {
                        notEND                         = YES;
                        [retTemp appendString:[message substringFromIndex:j]];
                        Y                              += cSize.height+lineDiffMin;
                        break;
                    }
                }
                if(j>=[message length])//已经显示完成
                {
                    NSMutableDictionary *dic       = [NSMutableDictionary dictionaryWithObjectsAndKeys:temp,@"text",
                                                      @(upY+topOrg),@"y",
                                                      nil];
                    //                    if(sizeNumber>=8)
                    //                    {
                    [dic setObject:fontTemp forKey:@"font"];
                    [dic setObject:@(cSize.height) forKey:@"height"];
                    //                    }
                    [drawLines_ addObject:dic];
                    notEND                         = NO;
                }
                
                lPos                           = j;
                if(cSize.width >= size.width - orgX)
                {
                    upY                            = upY + self.lineHeight ;
                    Y                              = upY;
                    X                              = size.width;
                    upX                            = 0;
                    notEND                         = NO;
                    if(upY >= size.height && size.height>0) //如果限制高度
                    {
                        if(j < [message length])
                        {
                            [retTemp appendString:[message substringFromIndex:j]];
                        }
                        //                        isOutHeight = TRUE;
                        break;
                    }
                }
                else
                    upX                            = orgX+cSize.width;
                
                if(j<[message length])
                    notEND                         = YES;
                
            }
            else
                upX                            = orgX+cSize.width;
        }
        if (X<size.width) {
            X                              = upX;
        }
    }
    if(retTemp.length >0)
    {
        if(retString)
            (* retString)                  = [NSString stringWithString:retTemp];
    }
    else if(notEND == NO)
    {
        Y                              += self.lineHeight;
    }
    PP_RELEASE(retTemp);
    
    return CGSizeMake(X, Y);
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    //    CGContextRef context = UIGraphicsGetCurrentContext();
    //    CGContextSetRGBFillColor(context, 240.0f/255, 240.0f/255, 240.0f/255, 0.0f); // translucent white
    //    CGContextFillRect(context, rect);
    
    if(self.textColor)
    {
        [self.textColor set];
    }
    else
    {
        [[UIColor blackColor]set];
    }
    CGFloat top                    = 0;
    CGFloat height                 = self.frame.size.height;
    for (int i                     = 0;i<drawLines_.count;i++) {
        NSDictionary * dic             = [drawLines_ objectAtIndex:i];
        
        NSString * stringTemp          = [dic objectForKey:@"text"];
        top                            = [[dic objectForKey:@"y"]floatValue];
        CGSize size0                   = [self drawText:stringTemp y:top font:[dic objectForKey:@"font"]];
        if(size0.width >= self.frame.size.width && size0.height>=height)
        {
            break;
        }
        else
        {
            //            top                            += size0.height;
            height                         -= size0.height;
        }
    }
}
- (CGSize)drawText:(NSString*)message y:(CGFloat)y font:(UIFont*)fontTemp
{
    CGFloat upX                    = 0;
    CGFloat upY                    = y;
    //    CGFloat X = 0;
    //    CGFloat Y = 0;
    //    BOOL isOutHeight = FALSE;
    
    UIFont *textFont               = nil;
    if(fontTemp)
    {
        textFont                       = fontTemp;
    }
    else
    {
        textFont                       = self.font?self.font:[UIFont fontWithName:fontName size:fontSize];
    }
    //    BOOL notEND = NO;
    CGSize size                    = self.frame.size;
    if (message) {
        int lPos                       = 0;
        CGFloat orgX                   = upX;
        //        for (int j = 1; j <= [message length]; j++) {
        //由于前面已经处理好了，因此这里只需要最后一步的处理，因无时间简化，暂时如此。
        for (NSUInteger j                = message.length; j <= [message length]; j++) {
            NSString *temp                 = [message substringWithRange:NSMakeRange(lPos, j - lPos)];
            CGSize cSize = [CommonUtil sizeOfString:temp withFont:textFont width:1024 height:1024];
//            CGSize cSize=[temp sizeWithFont:textFont constrainedToSize:CGSizeMake(1024, 1024)];
            if((j >= [message length] )|| (cSize.width >= size.width - orgX))
            {
                CGFloat realWidth              = cSize.width;
                //                if(j-lPos>1 &&(cSize.width > size.width - orgX)) //超过了，则需要回退
                //                {
                //                    j--;
                //                    temp = [message substringWithRange:NSMakeRange(lPos, j - lPos)];
                //                    cSize=[temp sizeWithFont:textFont constrainedToSize:CGSizeMake(1024, 1024)];
                //                    realWidth = cSize.width;
                //                    cSize.width = size.width;
                //                }
                if(textAlignment==NSTextAlignmentLeft)
                {
                    [temp drawAtPoint:CGPointMake(orgX, upY) withFont:textFont];
                }
                else if(textAlignment==NSTextAlignmentCenter)
                {
                    CGFloat newX                   = (self.frame.size.width - realWidth)/2 + orgX;
                    [temp drawAtPoint:CGPointMake(newX, upY) withFont:textFont];
                }
                else if(textAlignment==NSTextAlignmentRight)
                {
                    CGFloat newX                   = (self.frame.size.width - realWidth);
                    [temp drawAtPoint:CGPointMake(newX, upY) withFont:textFont];
                }
                else
                {
                    [temp drawAtPoint:CGPointMake(orgX, upY) withFont:textFont];
                }
                
                lPos                           = j;
                if(cSize.width >= size.width - orgX)
                {
                    upY                            = upY + self.lineHeight ;
                    if(upY >= size.height && size.height>0) //如果限制高度
                    {
                        break;
                    }
                }
            }
        }
    }
    return CGSizeMake(upX, upY);
}

@end


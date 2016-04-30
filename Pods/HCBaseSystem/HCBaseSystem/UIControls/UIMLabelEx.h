////
////  UIMLabelEx.h
////  HotelCloud
////  使用多种色系及字体、大小显示一段文字
////  <font size="12" color="ffeeff" font="Arial">atest</font><font....>...</font>
////  font="Arial" or font="FONT_TITLE"...
////  color="ffeeff" or color="COLOR_A"....
////  Created by XUTAO HUANG on 13-12-26.
////  Copyright (c) 2013年 Suixing. All rights reserved.
////
//
//#import <UIKit/UIKit.h>
//#import "RegexKitLite.h"
//#import <mach/mach.h>
//#import <Foundation/Foundation.h>
//
//#define REGEX_HTML  @"<(\\S+)([^>]*)>([^>]*)(</\\1>)" //$3 parameters  $4 values
//#define REGEX_PARA  @"\\s*([^=]+)=(\"([^\"]*)\"|([^\\s]*))\\s*" //$1 paraname $3or$4 value
//#define REGEX_COLORA    @"^([0-9a-fA-F]{6})$"
//#define REGEX_COLORB    @"COLOR_[A-Z]{1,2}"
//
//#if __has_feature(objc_arc) && __clang_major__ >= 3
//#ifndef PP_ARC_ENABLED
//#define PP_ARC_ENABLED 1
//#endif
//#endif // __has_feature(objc_arc)
//
//#if PP_ARC_ENABLED
//#ifndef PP_RETAIN
//#define PP_RETAIN(xx) (xx)
//#endif
//#ifndef PP_RELEASE
//#define PP_RELEASE(xx)  xx = nil
//#endif
//#ifndef PP_AUTORELEASE
//#define PP_AUTORELEASE(xx)  (xx)
//#endif
//#ifndef PP_SUPERDEALLOC
//#define PP_SUPERDEALLOC
//#endif
//#ifndef PP_BEGINPOOL
//#define PP_BEGINPOOL(xx)
//#endif
//#ifndef PP_ENDPOOL
//#define PP_ENDPOOL(xx)
//#endif
//#else
//#ifndef PP_RETAIN
//#define PP_RETAIN(xx)           [xx retain]
//#endif
//#ifndef PP_RELEASE
//#define PP_RELEASE(xx)          [xx release], xx = nil
//#endif
//#ifndef PP_AUTORELEASE
//#define PP_AUTORELEASE(xx)      [xx autorelease]
//#endif
//#ifndef PP_SUPERDEALLOC
//#define PP_SUPERDEALLOC [super dealloc]
//#endif
//#ifndef PP_BEGINPOOL
//#define PP_BEGINPOOL(xx) NSAutoreleasePool *xx = [[NSAutoreleasePool alloc] init];
//#endif
//#ifndef PP_ENDPOOL
//#define PP_ENDPOOL(xx) if(xx) { [xx drain];xx=nil;}
//#endif
//#endif
//
//#ifndef PP_STRONG
//#if __has_feature(objc_arc)
//#define PP_STRONG strong
//#else
//#define PP_STRONG retain
//#endif
//#endif
//
//#ifndef PP_WEAK
//#if __has_feature(objc_arc_weak)
//#define PP_WEAK weak
//#elif __has_feature(objc_arc)
//#define PP_WEAK unsafe_unretained
//#else
//#define PP_WEAK assign
//#endif
//#endif
//
//@interface UIMLabelEx : UIView
//{
//    NSMutableArray * textArray_;
//    NSMutableArray * drawLines_;
//    int lineCount_;
//}
//@property(nonatomic,assign) CGSize realSize;
//@property(nonatomic,assign) BOOL numberOfLines;
//@property(nonatomic,assign) BOOL autoChangeSize;
//@property(nonatomic,assign) CGFloat fontSize;
//@property(nonatomic,assign) CGFloat minFontSize;
//@property(nonatomic,PP_STRONG)NSString * fontName;
//@property(nonatomic,PP_STRONG)UIColor * textColor;
//@property(nonatomic,PP_STRONG) NSString * text;
//@property(nonatomic,assign) BOOL useHtml;    //文本是否使用HTML格式的？不在HTML中的不处理
//@property(nonatomic,assign) NSTextAlignment textAlignment;
//@property(nonatomic,assign) CGFloat lineHeight;    //包括了分隔在内的行高
//@property(nonatomic,assign) CGFloat lineDiffMin;    //单纯行距
//@property(nonatomic,assign) CGFloat segmentSpace;   //不同段之间的间隔
//@property(nonatomic,assign) BOOL isLineHeightFlexable; //行高是否根据文字的高度来进行处理？
//@property(nonatomic,assign) BOOL horizonCenter;
//@property(nonatomic,assign) BOOL alignByCenter; //是否以中心线对齐，当不同字体高度不一样时。否，则为以底线对齐
//@property (nonatomic,PP_STRONG) UIColor * shadowColor;
//@property (nonatomic,assign)CGSize shadowOffset;
//@property (nonatomic,assign) BOOL autoUseHTML;//是否自动判断使用HTML方式，通过正则，如果正则失败，则不使用HTML方式
//@property (nonatomic,assign) BOOL autoIncNumberOfLines;//当能容纳更多行时，自动将行数加1，将会导致行高发生变化
//@property (nonatomic,assign) BOOL notUseHTMLFONT;//不使用HTML中的字体及大小
//@property (nonatomic,assign) BOOL lineBreakByWord;//根据单词断行
//@property (nonatomic,PP_STRONG) UIColor * stripeColor;
//-(CGSize)fitRealSize;
//-(CGSize)fillOrginalSize;
//- (UIColor *) colorFromHexRGB:(NSString *) inColorString;
//@end

//
//  UIMLabelEx.h
//  HotelCloud
//  使用多种色系及字体、大小显示一段文字
//  <font size="12" color="ffeeff" font="Arial">atest</font><font....>...</font>
//  font="Arial" or font="FONT_TITLE"...
//  color="ffeeff" or color="COLOR_A"....
//  Created by XUTAO HUANG on 13-12-26.
//  Copyright (c) 2013年 Suixing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <hccoren/base.h>

#import <mach/mach.h>
#import <Foundation/Foundation.h>

#define REGEX_HTML  @"<(\\S+)([^>]*)>([^>]*)(</\\1>)" //$3 parameters  $4 values
#define REGEX_PARA  @"\\s*([^=]+)=(\"([^\"]*)\"|([^\\s]*))\\s*" //$1 paraname $3or$4 value
#define REGEX_COLORA    @"^([0-9a-fA-F]{6})$"
#define REGEX_COLORB    @"COLOR_[A-Z]{1,2}"

@interface UIMLabelEx : UIView
{
    NSMutableArray * textArray_;
    NSMutableArray * drawLines_;
}
@property(nonatomic,assign) CGSize realSize;
@property(nonatomic,assign) BOOL numberOfLines;
@property(nonatomic,assign) BOOL autoChangeSize;
@property(nonatomic,assign) CGFloat fontSize;
@property(nonatomic,assign) CGFloat minFontSize;
@property(nonatomic,PP_STRONG)NSString * fontName;
@property(nonatomic,PP_STRONG)UIColor * textColor;
@property(nonatomic,PP_STRONG) NSString * text;
@property(nonatomic,assign) BOOL useHtml;    //文本是否使用HTML格式的？不在HTML中的不处理
@property(nonatomic,assign) NSTextAlignment textAlignment;
@property(nonatomic,assign) CGFloat lineHeight;    //包括了分隔在内的行高
@property(nonatomic,assign) CGFloat lineDiffMin;    //单纯行距
@property(nonatomic,assign) CGFloat segmentSpace;   //不同段之间的间隔
@property(nonatomic,assign) BOOL isRowHeightFlexible; //行高是否根据文字的高度来进行处理？
@property(nonatomic,assign) BOOL horizonCenter;
@property(nonatomic,assign) BOOL alignByCenter; //是否以中心线对齐，当不同字体高度不一样时。否，则为以底线对齐
@property (nonatomic,PP_STRONG) UIColor * shadowColor;
@property (nonatomic,assign)CGSize shadowOffset;
@property (nonatomic,assign) BOOL autoUseHTML;//是否自动判断使用HTML方式，通过正则，如果正则失败，则不使用HTML方式
@property (nonatomic,assign) BOOL autoIncNumberOfLines;//当能容纳更多行时，自动将行数加1，将会导致行高发生变化
@property (nonatomic,assign) BOOL notUseHTMLFONT;//不使用HTML中的字体及大小
@property (nonatomic,assign) BOOL lineBreakByWord;//根据单词断行
@property (nonatomic,PP_STRONG) UIColor * stripeColor;

-(CGSize)fitRealSize;  //控件可变大小
-(CGSize)fillOrginalSize;//控件大小不变，在有限范围内显示文本

@end

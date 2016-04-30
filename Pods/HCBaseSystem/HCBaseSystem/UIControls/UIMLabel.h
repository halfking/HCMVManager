////
////  UIMLabel.h
////  RBNews
////
////  Created by XUTAO HUANG on 13-5-22.
////  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
////
//
////
////UIMLabel * label = [[UIMLabel alloc]initWithFrame:CGRectMake(155, 15, _ScreenWidth - 165, 24*3)];
////label.text = news.title;
////label.font = font;
//////            label.lineBreakMode = NSLineBreakByWordWrapping;
////label.numberOfLines = 0;
////label.lineHeight = 24;
////label.textColor = [CommonUtil colorFromHexRGB:@"333333"];
////label.backgroundColor =[UIColor clearColor];
////
////[view addSubview:label];
////[label release];
////
////titleSize = [label size:nil autoFill:YES];
//
//#import <UIKit/UIKit.h>
//
//@interface UIMLabel : UIView
//@property(nonatomic,retain) UIFont * font;
//@property(nonatomic,retain) UIColor * textColor;
////@property(nonatomic,retain) UIColor * backgroundColor;
//@property(nonatomic,retain) NSString * text;
//@property(nonatomic,assign) CGFloat  lineHeight;
//@property(nonatomic,assign) int numberOfLines;
//@property(nonatomic,assign) NSTextAlignment textAlignment;
//-(CGSize)size:(NSString **)retString autoFill:(BOOL)autoFill;
//-(void)fitToSize;
//@end
//
//  UIMLabel.h
//  RBNews
//
//  Created by XUTAO HUANG on 13-5-22.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

//
//UIMLabel * label = [[UIMLabel alloc]initWithFrame:CGRectMake(155, 15, _ScreenWidth - 165, 24*3)];
//label.text = news.title;
//label.font = font;
////            label.lineBreakMode = NSLineBreakByWordWrapping;
//label.numberOfLines = 0;
//label.lineHeight = 24;
//label.textColor = COLOR_F;
//label.backgroundColor =[UIColor clearColor];
//
//[view addSubview:label];
//[label release];
//
//titleSize = [label size:nil autoFill:YES];

#import <UIKit/UIKit.h>
#import <hccoren/base.h>


@interface UIMLabel : UIView
{
    NSMutableArray * textArray_;
    NSMutableArray * drawLines_;
}
@property(nonatomic,PP_STRONG) UIFont * font;
@property(nonatomic,PP_STRONG) NSString * fontName;
@property(nonatomic,PP_STRONG) NSString * secondFontName;
@property(nonatomic,assign) CGFloat fontSize;
@property(nonatomic,assign) CGFloat minFontSize;
@property(nonatomic,PP_STRONG) UIColor * textColor;
//@property(nonatomic,retain) UIColor * backgroundColor;
@property(nonatomic,PP_STRONG) NSString * text;
@property(nonatomic,assign) CGFloat  lineHeight;    //包括了分隔在内的行高
@property(nonatomic,assign) CGFloat lineDiffMin;    //单纯行距
@property(nonatomic,assign) int numberOfLines;
@property(nonatomic,assign) BOOL autoChangeFontSize;    //是否|分隔的最后一个必须在一行内显示完。
@property(nonatomic,assign) BOOL isAllChangeSize;   //是否所有行都尽量在一行内显示完
@property(nonatomic,PP_STRONG) NSString * splitChar;
@property(nonatomic,assign) BOOL horizonCenter;
@property(nonatomic,assign) NSTextAlignment textAlignment;
-(CGSize)size:(NSString **)retString autoFill:(BOOL)autoFill;
-(CGSize)fitToRealSize;
-(CGSize)autoFillSize;
@end

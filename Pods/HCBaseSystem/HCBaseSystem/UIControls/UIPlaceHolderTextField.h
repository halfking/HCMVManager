//
//  UIPlaceHolderTextField.h
//  RBNews
//
//  Created by XUTAO HUANG on 13-5-31.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <hccoren/base.h>

@interface UIPlaceHolderTextField : UITextField
{
//    NSString *placeholderString;
//    UIColor *placeholderColor;
    int holderLabelTag;
    
@private
    UILabel *placeHolderLabel;
    UILabel * showMustLabel;
}

@property (nonatomic, retain) UILabel *placeHolderLabel;
@property (nonatomic, retain) NSString *placeholderString;
@property (nonatomic, retain) UIFont * placeholderFont;
@property (nonatomic, retain) UIColor *placeholderColor;
@property (nonatomic, assign) NSTextAlignment placeholderTextAlignment;
@property (nonatomic,assign) BOOL showMust; //是否显示必填
@property (nonatomic,retain) NSString * mustText;
//@property (nonatomic,assign) BOOL  isHolderCenter;
-(void)textChanged:(NSNotification*)notification;
@end

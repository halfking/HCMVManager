//
//  UIPlaceHolderTextView.h
//  HotelCloud
//
//  Created by Suixing on 12-10-31.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
@interface UIPlaceHolderTextView : UITextView
{
    NSString *placeholder;
    UIColor *placeholderColor;
    
@private
    UILabel *placeHolderLabel;
}

@property (nonatomic, retain) UILabel *placeHolderLabel;
@property (nonatomic, retain) NSString *placeholder;
@property (nonatomic, retain) UIColor *placeholderColor;
@property (nonatomic,retain) UIFont * placeholderFont;
-(void)textChanged:(NSNotification*)notification;
@end

//
//  UIView+LoadFromNib.m
//  Wutong
//
//  Created by HUANGXUTAO on 15/6/20.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import "UIView+LoadFromNib.h"

@implementation UIView(LoadFromNib)

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

+ (id)loadFromNib
{
    id view = nil;
    NSString *xibName = NSStringFromClass([self class]);
    UIViewController *temporaryController = [[UIViewController alloc] initWithNibName:xibName bundle:nil];
    if(temporaryController)
    {
        view = temporaryController.view;
    }
    return view;
}
@end

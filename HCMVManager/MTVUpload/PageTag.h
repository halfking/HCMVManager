//
//  PageTag.h
//  maiba
//
//  Created by seentech_5 on 16/3/7.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <hccoren/base.h>
@interface PageTag : HCEntity

@property(assign,nonatomic) int PageTagID;
@property(assign,nonatomic) int PageCode;
@property(PP_STRONG,nonatomic) NSString * PageTagName;
@property(PP_STRONG,nonatomic) NSString * PageTagCover;
@property(assign,nonatomic) short IsTag;
@property(assign,nonatomic) short DataStatus;
@property(assign,nonatomic) int Sort;

@property(PP_STRONG,nonatomic) NSString * OpenUrl;

// 是否选中
@property (nonatomic,assign) BOOL isSelected;

@end

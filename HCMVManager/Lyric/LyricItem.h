//
//  LyricItem.h
//  maiba
//
//  Created by Matthew on 16/2/25.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <hccoren/base.h>

@interface LyricItem : HCEntity
@property (nonatomic,strong) NSString * text;
@property (nonatomic,assign) CGFloat begin;
@property (nonatomic,assign) CGFloat end;
@property (nonatomic,assign) CGFloat duration;
@end
//
//  MusicTag.h
//  maiba
//
//  Created by WangSiyu on 15/12/8.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import <hccoren/NSEntity.h>

@interface MusicTag : HCEntity

@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) NSUInteger tagID;
@property (nonatomic, assign) NSUInteger refrerenceCount;

@end

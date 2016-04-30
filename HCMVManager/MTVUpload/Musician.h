//
//  Musician.h
//  maiba
//
//  Created by seentech_5 on 16/3/30.
//  Copyright © 2016年 seenvoice.com. All rights reserved.
//

#import <hccoren/NSEntity.h>

@interface Musician : HCEntity
@property(nonatomic, assign) long MusicianID;
@property(nonatomic, strong) NSString * MusicianName;
@property(nonatomic, strong) NSString * SingerCharName;
@property(nonatomic, strong) NSString * SingerFirstChar;
@property(nonatomic, strong) NSString * HeadPortrait;
@property(nonatomic, strong) NSString * DateCreated;
@property(nonatomic, assign) short DataStatus;
@property(nonatomic, assign) short IsRecommend;
@property(nonatomic, assign) NSInteger Sort;
@end

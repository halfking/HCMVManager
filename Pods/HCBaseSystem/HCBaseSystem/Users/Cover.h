//
//  Cover.h
//  maiba
//
//  Created by WangSiyu on 15/12/28.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//


///用户的背景图片
#import <hccoren/NSEntity.h>

@interface CoverAttributes : HCEntity

@property (nonatomic, assign) float width;

@property (nonatomic, assign) float height;

@property (nonatomic, strong) NSString *videoCover;

@end

@interface Cover : HCEntity

@property (nonatomic, strong) NSString *coverUrl;

@property (nonatomic, strong) NSString *localCoverUrl; //建议不要带file字段

@property (nonatomic, strong) CoverAttributes *attributes;

@property (nonatomic, assign) int type;  //1：图片 2：视频

@property (nonatomic, assign) long coverID;

@end

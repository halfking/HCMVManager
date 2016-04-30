//
//  MTVFile.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/7/11.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#import <hccoren/NSEntity.h>

@interface MTVFile : HCEntity
@property (nonatomic,assign) long MTVID;
@property (nonatomic,PP_STRONG) NSString * FilePath;
@property (nonatomic,PP_STRONG) NSString * Key; 

@end

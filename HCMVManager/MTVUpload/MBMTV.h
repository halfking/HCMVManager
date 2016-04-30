//
//  MBMTV.h
//  maiba
//
//  Created by SeenVoice on 15/8/26.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import <hccoren/NSEntity.h>

@interface MBMTV : HCEntity

@property(assign, nonatomic) long MBMTVID;
@property(assign, nonatomic) long SampleID;
@property(assign, nonatomic) long UserID;
@property(PP_STRONG, nonatomic) NSString *Materials;
@property(PP_STRONG, nonatomic) NSString *UploadTime;
@property(PP_STRONG, nonatomic) NSString *HeadPortrait;
@property(PP_STRONG, nonatomic) NSString *Author;
@property(assign, nonatomic) long LikeCount;

@end

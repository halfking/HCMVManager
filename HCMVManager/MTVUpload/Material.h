//
//  Materials.h
//  maiba
//
//  Created by SeenVoice on 15/8/26.
//  Copyright (c) 2015年 seenvoice.com. All rights reserved.
//

#import <hccoren/base.h>

@interface Material : HCEntity

@property(assign, nonatomic) long MaterialID;
@property(PP_STRONG, nonatomic) NSString *MaterialURL;
@property(assign, nonatomic) int MaterialType;
@property(assign, nonatomic) long UserID;
@property(PP_STRONG, nonatomic) NSString *UploadTime;
@property(assign, nonatomic) long MBMTVID;
@property(PP_STRONG, nonatomic) NSString *FilePath;

@end

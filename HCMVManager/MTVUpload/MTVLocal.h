//
//  MTVLocal.h
//  maiba
//
//  Created by HUANGXUTAO on 15/10/28.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import "MTV.h"

@interface MTVLocal : MTV
- (instancetype) initWithMTV:(MTV*)item;
@property (nonatomic,assign) CGFloat coverSize;
@property (nonatomic,assign) CGFloat lyricSize;
@property (nonatomic,assign) CGFloat audioSize;
@property (nonatomic,assign) CGFloat videoSize;
@property (nonatomic,PP_STRONG) NSString * coverPath;
@property (nonatomic,PP_STRONG) NSString * lyricPath;
//@property (nonatomic,PP_STRONG) NSString * audioPath;
@property (nonatomic,PP_STRONG) NSString * videoPath;
@property (nonatomic, PP_STRONG) NSString * infoPath;
- (BOOL) notUpload;
@end

//
//  SJoin.h
//  AVAnimation
//
//  Created by Matthew on 16/5/13.
//  Copyright © 2016年 Matthew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
@interface SJoin : NSObject
@property(nonatomic, assign) CGSize RenderSize;
-(instancetype)initWithPath:(NSString *)path withReverse:(NSString *)rPath withSitems:(NSArray *)items;
-(void)resetPath:(NSString *)path withReverse:(NSString *)rPath withSitems:(NSArray *)items;
-(void)join;
@end

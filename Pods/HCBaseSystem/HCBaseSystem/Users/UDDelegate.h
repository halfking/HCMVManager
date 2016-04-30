//
//  UDDelegate.h
//  Wutong
//
//  Created by HUANGXUTAO on 15/5/15.
//  Copyright (c) 2015年 HUANGXUTAO. All rights reserved.
//

#ifndef Wutong_UDDelegate_h
#define Wutong_UDDelegate_h

@class UDManager;
@class UDInfo;

@protocol UDDelegate <NSObject>
@optional
- (void)UDManager:(UDManager *)manager key:(NSString *)key progress:(UDInfo*)item;
- (void)UDManager:(UDManager *)manager key:(NSString *)key didCompleted:(UDInfo *)item;
- (void)UDManager:(UDManager *)manager key:(NSString *)key didFailure:(UDInfo *)item;
- (void)UDManager:(UDManager *)manager key:(NSString *)key didStart:(UDInfo *)item;
- (void)UDManager:(UDManager *)manager key:(NSString *)key didStop:(UDInfo *)item;
@end

#endif

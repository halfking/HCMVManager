//
//  CMDDelegate.h
//  
//
//  Created by Suixing on 12-8-6.
//  Copyright (c) 2012年 . All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol CMDDelegate <NSObject>
@optional
-(void)CMDCallback:(id)cmdHelper data:(NSDictionary *)data cmd:(NSString*)cmd;
//-(void) willCall:(id)cmdHelper cmd:(NSString *)cmd request:(CMDSocketRequest *) request;
//-(void) didFailure:(id)cmdHelper cmd:(NSString *)cmd request:(CMDSocketRequest *) request msg:(NSString *)msg;
//-(void) CMDCallback:(NSTimer*)timer;
//@required
//-(void) CMDCallback:(id)cmdHelper response:(CMDSocketResponse*) response data:(NSDictionary*)data;
//-(void) CMDCallback:(id)cmdHelper cmd:(NSString *)cmd;
@end

//
//  CMDSender.h
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-6.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "UploadParameters.h"

@class DeviceConfig;
@class FileDataCacheHelper;
@class CMDOP;
@interface CMDSender : NSObject
{
@protected
    DeviceConfig * config_;
    FileDataCacheHelper * cacheHelper_;
    NSString *tockenCode_;
    NSMutableArray * cmdQueueSended_;
}
//+ (CMDSender *)sharedCMDSender;
- (BOOL) sendCMD:(CMDOP*)cmd;
- (void) setTockenCode:(NSString *)code;
//- (void) downloadFile:(NSString *)url onSuccess:(void (^)(NSString *url, NSData * data))success onfailure:(void(^)(NSString * url,NSError * error))failure;
//- (void) uploadImage:(NSString *)filePath parameters:(UploadParameters *)parameters onSuccess:(void (^)( NSDictionary * data))success onfailure:(void(^)(NSDictionary * faildata,NSError * error))failure withCMDSender:(CMDOP *)cmdSender;


//-(BOOL)     Call:(NSString *)cmd args:(NSString *)args
//        cachekey:(NSString *)cacheKey
//        useCache:(BOOL)useCache hasLocalData:(BOOL)hasLocalData;
//
//- (BOOL)    Call:(NSDictionary *)dic;
@end

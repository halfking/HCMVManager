//
//  CMDSender.m
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-6.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "CMDSender.h"
#import "HCBase.h"
#import "PublicMControls.h"
#import "DeviceConfig.h"
#import "FileDataCacheHelper.h"
#import "CMDOP.h"

@implementation CMDSender
//SYNTHESIZE_SINGLETON_FOR_CLASS_NEW(CMDSender)
- (id)init
{
    if(self = [super init])
    {
        config_ = PP_RETAIN([DeviceConfig Instance]);
        cacheHelper_ = PP_RETAIN([FileDataCacheHelper sharedFileDataCacheHelper]);
        cmdQueueSended_ = [NSMutableArray new];
    }
    return self;
}
- (void)setTockenCode:(NSString *)code
{
    if(tockenCode_)
    {
        PP_RELEASE(tockenCode_);
    }
    tockenCode_ = PP_RETAIN(code);
}
- (BOOL)sendCMD:(CMDOP *)cmd
{
    return NO;
}
//- (BOOL)Call:(NSDictionary *)dic
//{
//    return NO;
//}
//- (BOOL)Call:(NSString *)cmd args:(NSString *)args
//    cachekey:(NSString *)cacheKey
//    useCache:(BOOL)useCache
//hasLocalData:(BOOL)hasLocalData
//{
//    return NO;
//}
//- (void) downloadFile:(NSString *)url onSuccess:(void (^)(NSString *url, NSData * data))success onfailure:(void(^)(NSString * url,NSError * error))failure
//{
//    if(failure)
//    {
//        NSError * error = [[NSError alloc]initWithDomain:@"not impliment" code:-1 userInfo:nil];
//        failure(nil,error);
//        PP_RELEASE(error);
//    }
//}
//- (void) uploadImage:(NSString *)filePath parameters:(UploadParameters *)parameters onSuccess:(void (^)( NSDictionary * data))success onfailure:(void(^)(NSDictionary * faildata,NSError * error))failure withCMDSender:(CMDOP *)cmdSender;
//{
//    if(failure)
//    {
//        NSError * error = [[NSError alloc]initWithDomain:@"not impliment" code:-1 userInfo:nil];
//        failure(nil,error);
//        PP_RELEASE(error);
//    }
//}
#pragma mark - dealloc
- (void)dealloc
{
    PP_RELEASE(config_);
    PP_RELEASE(cacheHelper_);
    PP_RELEASE(tockenCode_);
    PP_RELEASE(cmdQueueSended_);
    PP_SUPERDEALLOC;
}

@end

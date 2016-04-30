//
//  HttpServerManager.m
//  maiba
//
//  Created by seentech_5 on 15/12/8.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import "HttpServerManager.h"
#import "HCBase.h"
#import "HTTPServer.h"
//#import "Common.h"
#import "DeviceConfig.h"

@interface HttpServerManager ()
{
    HTTPServer * httpServer_;

}
@end

@implementation HttpServerManager


static HttpServerManager * intance_ = nil;
+(id)Instance
{
    if(intance_==nil)
    {
        @synchronized(self)
        {
            if (intance_==nil)
            {
                intance_ = [[HttpServerManager alloc]init];
            }
        }
    }
    return intance_;
}
+(HttpServerManager *)shareObject
{
    return (HttpServerManager *)[self Instance];
}

#pragma mark - httpServer
- (void)startHttpServer:(NSString *)dir completion:(void(^)(NSError * error))completion
{
    DeviceConfig * config = [DeviceConfig config];
    NSLog(@"start http server....");
    long defaultPort = config.LOCALHOST_PORT;
//    if(count>0) defaultPort += count;
    if(!httpServer_)
    {
        httpServer_ = [[HTTPServer alloc] init];
        [httpServer_ setType:@"_http._tcp."];
        [httpServer_ setPort:defaultPort];
        [httpServer_ setName:@"maibavdc"];
        [httpServer_ setupBuiltInDocroot:dir];
//        NSLog(@"")
    }
    
    if(httpServer_.isRunning==NO)
    {
        int times = 0;
        NSError *error;
//        BOOL serverIsRunning = NO;
        
//        defaultPort +=3;
//        [httpServer_ setPort:defaultPort];
        
        BOOL serverIsRunning = [httpServer_ start:&error];
        
        while(times<100 && !serverIsRunning)
        {
            NSLog(@"Error starting HTTP Server: %@", error);
            
            defaultPort +=3;
            [NSThread sleepForTimeInterval:0.1];
            
            [httpServer_ setPort:defaultPort];
            times ++;
            
            serverIsRunning = [httpServer_ start:&error];
        }
        if(!serverIsRunning)
        {
            if(completion)
            {
                NSError * error = [NSError errorWithDomain:@"com.seenvoice.hccoren" code:-1005 userInfo:@{NSLocalizedDescriptionKey:@"无法开启本地Web服务，将无法缓存远程文件。请先缓存歌曲后再操作。"}];
                completion(error);
            }
//            UIAlertView * alterView = [[UIAlertView alloc]initWithTitle:@"错误信息" message:@"无法开启本地Web服务，将无法缓存远程文件。请先缓存歌曲后再操作。" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//            [alterView show];
//            PP_RELEASE(alterView);
        }
        else
        {
            config.LOCALHOST_PORT = defaultPort;
        }
        {
            NSString * hostName = [httpServer_ hostName];
            config.LOCALHOST_IP = hostName;
            if(hostName==nil||[hostName isEqualToString:@"null"])
            {
                if(completion)
                {
                    NSError * error = [NSError errorWithDomain:@"com.seenvoice.hccoren" code:-1005 userInfo:@{NSLocalizedDescriptionKey:@"请打开WiFI，再开启服务。"}];
                    completion(error);
                }
                NSLog(@"%@", @"请打开WiFI，再开启服务");
                
            }
            else
            {
                NSLog(@"vdcserver:    http://%@:%d", hostName, [httpServer_ port]);
                if(completion)
                {
                    completion(nil);
                }
            }
            
            
        }
    }
}

- (void)stopHttpServer
{
    NSLog(@"stop http server....");
    if(httpServer_ && httpServer_.isRunning)
    {
        [httpServer_ stop];
    }
}

- (NSString *)buildUrlForResource:(NSString *)fileAndPath
{
    return [NSString stringWithFormat:@"http://127.0.0.1:%d/%@",[httpServer_ port],fileAndPath];
}

@end

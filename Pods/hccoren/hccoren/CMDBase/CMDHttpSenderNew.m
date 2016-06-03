//
//  CMDHttpSender.m
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-6.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "CMDHttpSenderNew.h"
#import "CMDOP.h"
#import "CMDHttpHeader.h"
#import "HCBase.h"
#import "CMDs.h"
#import "DeviceConfig.h"
//#import "config.h"
//#import "ASIHTTPRequest.h"
//#import "ASIFormDataRequest.h"
//#import "PublicText.h"
#import "JSON.h"

//#define USE_AFNETWORKING

//#ifdef USE_AFNETWORKING
//#import "AFNetworking.h"
//#else
////    #import <NS>
//#endif

@implementation CMDHttpSenderNew
SYNTHESIZE_SINGLETON_FOR_CLASS_NEW(CMDHttpSenderNew)

- (BOOL)sendCMD:(CMDOP *)cmd
{
    if(!cmd) return NO;
    
    DeviceConfig * config = [DeviceConfig config];
    
    __block CMDHttpHeader * header = [[CMDHttpHeader alloc]init];
    __block __weak CMDOP * weakCmd = cmd;
    NSString * url = cmd.serverURL;
    if (!url || !url.length) {
        url = PP_RETAIN([header toString:weakCmd includeUDI:NO]);
    }
    NSLog(@"拼接命令后%@",url);
    NSMutableString * parameterString  = nil;
    
    if(config.IsDebugMode||[cmd isPost])
    {
        parameterString = [NSMutableString new];
    }
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    //配置请求头
    //    [config setHTTPAdditionalHeaders:@{@"Authorization":[Dropbox apiAuthorizationHeader]}];
    //初始化会话
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    
    NSDictionary * postContent = [header postContents];//做遍历
    NSMutableDictionary *params = [NSMutableDictionary dictionary];//用于保存参数
    for (NSString * key in postContent.keyEnumerator) {
        NSString * object = [postContent objectForKey:key];
        NSString * objectString = nil;
        if([object isKindOfClass:[NSString class]])
        objectString = (NSString *)object;
        else
        {
            NSString * json = [object JSONRepresentationEx];
            objectString = json ? json : object;
        }
        [params setObject:objectString forKey:key];
        if(config.IsDebugMode||[cmd isPost])
        {
            //#ifndef __OPTIMIZE__
            [parameterString appendFormat:@"%@=%@&",key,objectString ];
            //#endif
        }
    }
    
    NSString * messageID = cmd.messageID;
    int cmdID = cmd.CMDID;
    if([cmd isPost])
    {
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20];
        if(cmd.refer)
        [request setValue:cmd.refer forHTTPHeaderField:@"Refer"];
        if(cmd.UA)
        [request setValue:cmd.UA forHTTPHeaderField:@"User-Agent"];
        
        [request setHTTPMethod:@"POST"];
        [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        
        
        NSData *bodyData = [parameterString dataUsingEncoding:NSUTF8StringEncoding];
        [request setHTTPBody:bodyData];
        
        [[session dataTaskWithRequest:request
                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        
                        if(data && !error){
                            CMDOP * op = PP_RETAIN([[CMDs sharedCMDs] getCMDOP:cmdID messageID:messageID]);//???
                            if(op)
                            {
                                NSLog(@"request finished: cmdID:%d,name:%@",[op CMDID],NSStringFromClass([op class]));
                                [[CMDs sharedCMDs] removeCMDOP:op];
                                
#ifdef LOGCMDTIME
                                op.ticksForSendTime = [CommonUtil getDateTicks:[NSDate date]];
                                NSLog(@"request:%@",operation.request.URL.absoluteString);
                                if(operation.responseData)
                                {
                                    NSLog(@"responseObject = %@",[responseObject JSONRepresentationEx]);
                                    op.bytesReceived = (int)operation.responseData.length;
                                }
                                if(operation.request.HTTPBody)
                                {
                                    op.bytesSend = (int)operation.request.HTTPBody.length;
                                }
                                
#endif
                                
                                NSString * result = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                                //                       NSString *result =  [responseObject JSONRepresentationEx];
                                
                                CMDHttpHeader * header = (CMDHttpHeader*)[op getHeader:[op preParseData:result]];
                                header.MessageID = op.messageID;
                                header.CMD = op;
                                header.CMDName = [self getCMDName:op];
                                header.CMDID = op.CMDID;
                                
                                //        if(header.Data && (!header.Data.Args))
                                //        {
                                //            header.Data.Args = header.Args?header.Args:[op argsDic];
                                //        }
                                [header parseResult];
                                [op sendNotification:header];
                                [op cancelCMD];
                                [[CMDs sharedCMDs]removeCMDOP:op];
                                PP_RELEASE(result);
                            }
                            else
                            {
                                NSLog(@"http request not matched...%@",messageID);
                            }
                            PP_RELEASE(op);
                        } else
                        {
                            @autoreleasepool {
                                //                       DLog(@"request failure:%@",[error description]);
                                HCCallbackResult * result = [[HCCallbackResult alloc]init];
                                //                       result.Code = -1;
                                //                       if(weakRequest.responseStatusCode ==2||error.code==2)
                                if(error.code==2||error.code==-1001)
                                {
                                    result.Code = 2;
                                    result.Msg = @"网络超时，请稍后重试。";
                                }
                                else
                                {
                                    result.Code = -1;
                                    result.Msg = [error description];
                                }
                                CMDOP * op = PP_RETAIN([[CMDs sharedCMDs] getCMDOP:cmdID messageID:messageID]);
                                
                                //???
                                if (op) {
                                    NSLog(@"request finished with error: cmdID:%d,name:%@",[op CMDID],NSStringFromClass([op class]));
#ifdef LOGCMDTIME
                                    op.ticksForSendTime = [CommonUtil getDateTicks:[NSDate date]];
                                    //                       weakCmd.bytesReceived = (int)weakRequest.totalBytesRead;
                                    //                       weakCmd.bytesSend = (int)weakRequest.totalBytesSent;
                                    if(operation.responseData)
                                    {
                                        op.bytesReceived = (int)operation.responseData.length;
                                    }
                                    if(operation.request.HTTPBody)
                                    {
                                        NSLog(@"request:%@",operation.request.URL.absoluteString);
                                        NSLog(@"request failure:%@",[error description]);
                                        op.bytesSend = (int)operation.request.HTTPBody.length;
                                    }
#endif
                                    if(error.code==NSURLErrorDNSLookupFailed
                                       ||error.code==NSURLErrorTimedOut
                                       || error.code==NSURLErrorCannotFindHost
                                       ||error.code==NSURLErrorNotConnectedToInternet
                                       || error.code==NSURLErrorNetworkConnectionLost
                                       ||
                                       error.code==NSURLErrorCannotConnectToHost)
                                    {
                                        op.didTimeout = YES;
                                    }
                                    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:@(error.code),@"code",error.localizedDescription,@"msg", nil];
                                    NSString *resultString =  [dic JSONRepresentationEx];
                                    
                                    CMDHttpHeader * header = (CMDHttpHeader*)[op getHeader:resultString];
                                    header.MessageID = op.messageID;
                                    header.CMD = op;
                                    header.CMDName = [self getCMDName:op];
                                    header.CMDID = op.CMDID;
                                    [header parseResult];
                                    
                                    
                                    
                                    [op sendNotification:header];
                                    [op cancelCMD];//??
                                    
                                    //remove....
                                    [[CMDs sharedCMDs]removeCMDOP:op];
                                }
                                else
                                {
                                    NSLog(@"request failure:%@",[error description]);
                                }
                                
                            }
                            
                        }
                    }]resume];
    }
    else
    {
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
        request.HTTPMethod = @"GET";
        
        [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        
        //        for (NSString * key in params.allKeys) {
        //            [request addValue:[params objectForKey:key] forHTTPHeaderField:key];
        //        }
        if(cmd.refer)
        [request setValue:cmd.refer forHTTPHeaderField:@"Refer"];
        if(cmd.UA)
        [request setValue:cmd.UA forHTTPHeaderField:@"User-Agent"];
        
        [request setHTTPMethod:@"GET"];
        [[session dataTaskWithRequest:request
                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        if(data && !error)
                        {
                            CMDOP * op = PP_RETAIN([[CMDs sharedCMDs] getCMDOP:cmdID messageID:messageID]);
                            if(op)
                            {
                                NSLog(@"request finished: cmdID:%d,name:%@",[op CMDID],NSStringFromClass([op class]));
                                [[CMDs sharedCMDs] removeCMDOP:op];
                                
#ifdef LOGCMDTIME
                                op.ticksForSendTime = [CommonUtil getDateTicks:[NSDate date]];
                                //                       op.bytesReceived = (int)operation.totalBytesRead;
                                ////                       (int)request.totalBytesRead;
                                //                       op.bytesSend = (int)operation.totalBytesSent;
                                if(operation.responseData)
                                {
                                    op.bytesReceived = (int)operation.responseData.length;
                                }
                                if(operation.request)
                                {
                                    NSLog(@"request:%@",operation.request.URL.absoluteString);
                                    NSLog(@"responseObject = %@",[responseObject JSONRepresentationEx]);
                                    op.bytesSend = (int)operation.request.URL.absoluteString.length;
                                    //                          op.bytesSend = (int)operation.request.HTTPBody.length;
                                }
                                
#endif
                                NSString * result = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                                //                      NSString *result =  [responseObject JSONRepresentationEx];
                                
                                CMDHttpHeader * header = (CMDHttpHeader*)[op getHeader:[op preParseData:result]];
                                //    if(!header.MessageID || header.MessageID.length==0)
                                //    {
                                header.MessageID = op.messageID;
                                //    }
                                header.CMD = op;
                                header.CMDName = [self getCMDName:op];
                                header.CMDID = op.CMDID;
                                
                                //        if(header.Data && (!header.Data.Args))
                                //        {
                                //            header.Data.Args = header.Args?header.Args:[op argsDic];
                                //        }
                                [header parseResult];
                                [op sendNotification:header];
                                [op cancelCMD];
                                [[CMDs sharedCMDs]removeCMDOP:op];
                            }
                            else
                            {
                                NSLog(@"http request not matched...%@",weakCmd.messageID);
                            }
                            PP_RELEASE(op);
                        }
                        else
                        {
                            //                  NSLog(@"网络请求失败");
                            //                  @autoreleasepool {
                            HCCallbackResult * result = [[HCCallbackResult alloc]init];
                            if(error.code==2||error.code==-1001)
                            {
                                result.Code = 2;
                                result.Msg = @"网络超时，请稍后重试。";
                            }
                            else
                            {
                                result.Code = -1;
                                result.Msg = [error description];
                            }
                            
                            CMDOP * op = PP_RETAIN([[CMDs sharedCMDs] getCMDOP:cmdID messageID:messageID]);
                            
                            //???
                            if (op) {
                                NSLog(@"request finished with error: cmdID:%d,name:%@",[op CMDID],NSStringFromClass([op class]));
#ifdef LOGCMDTIME
                                
                                op.ticksForSendTime = [CommonUtil getDateTicks:[NSDate date]];
                                //                       weakCmd.bytesReceived = (int)weakRequest.totalBytesRead;
                                //                       weakCmd.bytesSend = (int)weakRequest.totalBytesSent;
                                if(operation.responseData)
                                {
                                    op.bytesReceived = (int)operation.responseData.length;
                                }
                                if(operation.request)
                                {
                                    op.bytesSend = (int)operation.request.URL.absoluteString.length;
                                    NSLog(@"request:%@",operation.request.URL.absoluteString);
                                    NSLog(@"request failure:%@",[error description]);
                                }
#endif
                                NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:@(error.code),@"code",error.localizedDescription,@"msg", nil];
                                NSString *result =  [dic JSONRepresentationEx];
                                
                                //                          CMDHttpHeader * header = (CMDHttpHeader*)[op getHeader:result];
                                CMDHttpHeader * header = (CMDHttpHeader*)[op getHeader:result];
                                header.MessageID = op.messageID;
                                header.CMD = op;
                                header.CMDName = [self getCMDName:op];
                                header.CMDID = op.CMDID;
                                [header parseResult];
                                
                                [op sendNotification:header];
                                [op cancelCMD];//??
                                
                                //remove....
                                [[CMDs sharedCMDs]removeCMDOP:op];
                            }
                            else
                            {
                                NSLog(@"request failure:%@",[error description]);
                            }
                            //                  }
                        }
                    }]resume];
        
    }
    
    [session finishTasksAndInvalidate];
    
    if(config.IsDebugMode)
    {
        NSURL * url1 =  nil;
        if([url rangeOfString:@"?"].location==NSNotFound)
        {
            [parameterString insertString:@"?" atIndex:0];
        }
        [parameterString insertString:url atIndex:0];
        url1 = [NSURL URLWithString:[parameterString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        PP_RELEASE(parameterString);
        
        [cmd setRequestUrl:[url1 absoluteString]];
        NSLog(@"request:%@",cmd.requestUrl);
        //#endif
    }
    //#endif
    //设置报头
    //    if(cmd.refer)
    //        [manager.requestSerializer setValue:cmd.refer forHTTPHeaderField:@"Refer"];
    //    if(cmd.UA)
    //        [manager.requestSerializer setValue:cmd.UA forHTTPHeaderField:@"User-Agent"];
    //    manager.requestSerializer.timeoutInterval = HTTP_TIMEOUT;
    //    manager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    PP_RELEASE(url);
    
    PP_RELEASE(header);
    return YES;
}

- (NSString *)getCMDName:(CMDOP *)op
{
    NSString * className = NSStringFromClass([op class]);
    if([className hasPrefix:@"CMD_"])
    {
        return [className substringFromIndex:4];
    }
    else
    {
        return className;
    }
}
//- (void) downloadFile:(NSString *)url onSuccess:(void (^)(NSString *url, NSData * data))success onfailure:(void(^)(NSString * url,NSError * error))failure
//{
//    //下载文件
//    NSLog(@"++++++++++++++++++downloadFile++++++++++++++++++");
//
//    //创建请求管理，用于上传和下载。
//    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
//
//
//    //FIXME 下载后的文件位置放在哪里
//    //设置存放文件的位置（此Demo把文件存保在iPhone沙盒中的Documents文件夹中）
//    //方法一
//    //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    //    NSString *cachesDirectory = [paths objectAtIndex:0];
//    //    NSString *filePath = [cachesDirectory stringByAppendingPathComponent:@"文件名"];
//    //方法二
//    //    NSString *filePath = [NSString stringWithFormat:@"%@/Documents/文件名（注意后缀名）", NSHomeDirectory()];
//
//    //添加下载请求（获取服务器的输出流）
//    // operation.outputStream = [NSOutputStream outputStreamToFileAtPath:<#(NSString *)#> append:<#(BOOL)#>]
//
//    //请求管理判断请求结果
//    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation,id responseObject){
//        //请求成功
//        NSLog(@"下载请求成功");
//
//        if(success)
//        {
//            //???
//            success(url,responseObject);//怎么提取出data
//        }
//
//    }failure:^(AFHTTPRequestOperation *operation,NSError *error){
//        //请求失败
//        NSLog(@"下载请求失败");
//        NSLog(@"request failure:%@",[error description]);
//        if(failure)
//        {
//            failure(url,error);
//        }
//
//
//    }];
//    [operation start];
//}
//- (void)requestStarted:(ASIHTTPRequest *)request
//{
//    DLog(@"start download file:%@",request.url.absoluteString);
//}

//
//- (void) uploadImage:(NSString *)filePath parameters:(UploadParameters*)parameters onSuccess:(void (^)(NSDictionary * data))success onfailure:(void(^)(NSDictionary * faildata,NSError * error))failure withCMDSender:(CMDOP *)cmdSender
//{
//    NSLog(@"++++++++++++++++++uploadImage++++++++++++++++++");
//    //    //创建请求（ios7专用）
//    //    AFURLSessionManager *sessionManager = [[AFURLSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
//    //    //添加请求接口
//    //    DeviceConfig *deviceConfig = [DeviceConfig Instance];
//    //    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:deviceConfig.uploadServerUrl]];//上传地址。
//    //    //添加上传的文件
//    //    //FIXME 上传文件的本地文件地址在哪里？
//    //    //    NSURL *filePath = [NSURL fileURLWithPath:@"本地文件地址"];
//    //    //发送上传请求
//    ////    NSURLSessionUploadTask *uploadTask = [sessionManager uploadTaskWithRequest:request fromFile:filePath progress:nil completionHandler:^(NSURLResponse *response,id responseObject,NSError *error){
//    ////        if (error) {
//    ////            //请求失败
//    ////            NSLog(@"上传网络请求失败 Error：%@",error);
//    ////        }else{
//    ////            //请求成功
//    ////            NSLog(@"上传网络请求成功%@ %@",response,responseObject);
//    ////        }
//    ////    }];
//    //    //开始上传
//    //    [uploadTask resume];
//
//    //    DeviceConfig *deviceConfig = [DeviceConfig Instance];
//    //    ASIFormDataRequest *request=[ASIFormDataRequest requestWithURL:[NSURL URLWithString:deviceConfig.uploadServerUrl]];
//    //    [request setUserAgentString:deviceConfig.UA];
//    //    [request setShouldAttemptPersistentConnection:NO];
//    //    [request setStringEncoding:NSUTF8StringEncoding];
//    //
//    //    if(parameters.GroupName!=nil)
//    //        [request setPostValue:parameters.GroupName forKey:@"G"];
//    //    else
//    //        [request setPostValue:@"userimages" forKey:@"G"];
//    //    if(parameters.ThumnateList!=nil)
//    //        [request setPostValue:parameters.ThumnateList forKey:@"T"];
//    //    else
//    //    {
//    //        NSString * thumnateList = THUMNATELIST;
//    //        [request setPostValue:thumnateList forKey:@"T"];
//    //    }
//    //    [request setPostValue:[NSString stringWithFormat:@"%i",parameters.IsAddWaterMarker ] forKey:@"WM"];
//    //    [request setPostValue:[NSString stringWithFormat:@"%i",parameters.IsAllAddedMarker ] forKey:@"AS"];
//    //    [request setFile:parameters.FileName forKey:@"attach"];
//    //    //NSData * data = [NSData dataWithContentsOfFile:parameter.FileName];
//    //    //[request addData:data withFileName:parameter.FileName andContentType:@"image/jpeg" forKey:@"photos"];
//    //
//    //    __weak ASIFormDataRequest * weakRequest = request;
//    //
//    //    [request setCompletionBlock:^(void)
//    //     {
//    //         @autoreleasepool {
//    //             NSString *resultString = weakRequest.responseString;
//    //             NSDictionary *resultDic = [resultString JSONValueEx];
//    //
//    //             if(success)
//    //             {
//    //                 success(resultDic);
//    //             }
//    //         }
//    //     }];
//    //
//    //
//    //    [request setFailedBlock:^(void){
//    //        @autoreleasepool {
//    //            NSError *error = [weakRequest error];
//    //            DLog(@"request failure:%@",[error description]);
//    //            NSString *resultString = weakRequest.responseString;
//    //            NSDictionary *resultDic = [resultString JSONValueEx];
//    //            if(failure)
//    //            {
//    //                failure(resultDic,error);
//    //            }
//    //        }
//    //
//    //    }];
//    //
//    //    [request setTimeOutSeconds:20];
//    //    [request startAsynchronous];
//    //
//}

@end

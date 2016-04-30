//
//  CMDHeader.m
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-4.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "CMDHeader.h"
#import "JSON.h"
#import "CMDOP.h"
#import "CMDs.h"
@implementation CMDHeader
@synthesize CMDID;
@synthesize CMDName;
@synthesize MessageID;
@synthesize Data;
@synthesize UserID;
@synthesize PageIndex;
@synthesize PageSize;
@synthesize sIndex;
@synthesize eIndex;
@synthesize FromLocalDB;
@synthesize IsDataFromCache;
@synthesize IsSilence;
@synthesize CMD;
//@synthesize Args,paramDic;

- (id)initWithString:(NSString *)responseString
{
    if(self = [super init])
    {
        body_ = nil;
    }
    return self;
}
- (id)initWithArgs:(NSString *)cmdString andEncryptMethod:(short)em andProtocolVersion:(short)pv andUDI:(NSString *)udi andTocken:(NSString *)tockenCode andUserID:(int)userID andBody:(NSString *)body andCacheKey:(NSString *)cacheKey andResultMD5:(NSString *)resultMD5
{
    if(self = [super init])
    {
        body_ = nil;
    }
    return self;
}
- (void)parseResult
{
    if(!CMD)
    {
        if(self.CMDName && self.CMDName.length>0)
        {
            CMD = PP_RETAIN([[CMDs sharedCMDs]createCMDOP:self.CMDName]);
        }
        else if(self.CMDID>0)
        {
            CMD = PP_RETAIN([[CMDs sharedCMDs]createCMDOPByID:self.CMDID]);
        }
    }
    if(CMD && body_ && body_.length>=2 && (self.CMDID>0 || (self.CMDName && self.CMDName.length>0)))
    {
        NSString * stringReadyParse = [CMD preParseData:body_];
        if(![stringReadyParse hasSuffix:@"}"] && ![stringReadyParse hasSuffix:@"]"])
        {
            NSString *testString = [[stringReadyParse substringFromIndex:[stringReadyParse length] -5 ]
                                    stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
            if(![testString hasSuffix:@"}"] && ![testString hasSuffix:@"]"])
            {
                NSDictionary *resultDic = [NSDictionary dictionaryWithObjectsAndKeys:stringReadyParse,@"data", nil];
                
                @try {
                    HCCallbackResult * data =  [CMD parseResult:resultDic];
                    Data = PP_RETAIN(data);
                    //                self.Data = data;
                    Data.ArgsHash = CMD.argsHash;
#ifndef __OPTIMIZE__
                    data.ABrequestString = CMD.requestUrl;
#endif
                }
                @catch (NSException *exception) {
                    NSLog(@"error:%@",[exception description]);
                    NSLog(@"text:%@",body_);
                    PP_RELEASE(Data);
                    //                self.Data = nil;
                }
                @finally {
                    
                }
                return ;
            }
        }
        {
            
            @try {
                NSDictionary *resultDic = [stringReadyParse JSONValueEx]; //? [body_ JSONValueEx] : body_;//****
                HCCallbackResult * data =  [CMD parseResult:resultDic];
                Data = PP_RETAIN(data);
//                self.Data = data;
                Data.ArgsHash = CMD.argsHash;
#ifndef __OPTIMIZE__
                data.ABrequestString = CMD.requestUrl;
#endif
                
            }
            @catch (NSException *exception) {
                NSLog(@"error:%@",[exception description]);
                NSLog(@"text:%@",body_);
                PP_RELEASE(Data);
//                self.Data = nil;
            }
            @finally {
                
            }
            if(!self.Data)
            {
                NSLog(@"response body text error :%@",body_);
            }
        }
    }
}
- (void)setTockenCode:(NSString *)code
{
    if(tockenCode_)
    {
        PP_RELEASE(tockenCode_);
    }
    tockenCode_ = PP_RETAIN(code);
}
- (NSString *)requestHeaderUrl
{
    return nil;
}
#pragma mark - dealloc
- (void)dealloc
{
    PP_RELEASE(MessageID);
    PP_RELEASE(Data);
    PP_RELEASE(body_);
    PP_RELEASE(tockenCode_);
    PP_RELEASE(CMD);
    PP_SUPERDEALLOC;
}
@end

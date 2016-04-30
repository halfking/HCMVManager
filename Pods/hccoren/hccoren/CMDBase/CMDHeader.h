//
//  CMDHeader.h
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-4.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCBase.h"
#import "HCCallbackResult.h"
@class CMDOP;

@interface CMDHeader : NSObject
{
@protected
    NSString * body_;
    NSString *tockenCode_;
//    NSDictionary * argsDic_;
}
//@property(nonatomic,assign) short EncryptMethod;
//@property(nonatomic,assign) short ProtocolVersion;
@property(nonatomic,assign) int CMDID;
@property(nonatomic,PP_STRONG) NSString * CMDName;
@property(nonatomic,PP_STRONG) NSString * MessageID;
@property(nonatomic,PP_STRONG) HCCallbackResult * Data;
@property(nonatomic,PP_STRONG) CMDOP * CMD;
//@property(nonatomic,retain) NSMutableDictionary * paramDic;
//@property(nonatomic,retain) NSString * Args;

@property(nonatomic,assign) int UserID;
//@property(nonatomic,assign) short Code;
//@property(nonatomic,retain) NSString * SecretCode;
//@property(nonatomic,assign) int BodySize;
//@property(nonatomic,retain) NSString * CMD;
//@property(nonatomic,retain) NSString * TockenCode;

//@property(nonatomic,retain) NSString * UDI;
//@property(nonatomic,retain) NSString * Body;
////@property(nonatomic,retain) ResponseEntity * Data;
////@property(nonatomic,retain) NSDictionary * Dictionary;
//
@property(nonatomic,assign) int PageIndex;
@property(nonatomic,assign) int PageSize;
@property(nonatomic,assign) int sIndex;
@property(nonatomic,assign) int eIndex;
//@property(nonatomic,retain) NSString * KeySyntax;
@property(nonatomic,assign) BOOL FromLocalDB;
@property(nonatomic,assign) BOOL IsDataFromCache;
//@property(nonatomic,retain) NSString * Args;
@property(nonatomic,assign) BOOL IsSilence; //是否不需要在前台回调，只是后台数据处理。
//+ (CMDHeader *) initWithString:(NSString *) responseString;
//#if REQUEST_POST
//- (NSMutableDictionary *)postContents;
//#endif
- (id)initWithString:(NSString *)responseString;
- (void)parseResult;

- (NSString*)requestHeaderUrl;

//+ (CMDHeader *)initwithParams:(NSString *)cmdString andParams:(NSDictionary*)params;
- (id) initWithArgs:(NSString *)cmdString
   andEncryptMethod:(short)em
 andProtocolVersion:(short)pv
             andUDI:(NSString *)udi
          andTocken:(NSString *)tockenCode
          andUserID:(int) userID
            andBody:(NSString *) body
        andCacheKey:(NSString *)cacheKey
       andResultMD5:(NSString*) resultMD5;
- (void) setTockenCode:(NSString *)code;
@end

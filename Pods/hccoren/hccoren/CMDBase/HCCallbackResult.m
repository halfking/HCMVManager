//
//  HCCallbackResult.m
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-5.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "HCCallbackResult.h"

@implementation HCCallbackResult
@synthesize Code,Msg,Data,aCode;
@synthesize List;
@synthesize Args;
@synthesize DicNotParsed;
@synthesize resultDic;
@synthesize IsFromDB;
@synthesize ArgsHash;
@synthesize ResultHash;
@synthesize TotalCount;
@synthesize TotalDetailCount;
@synthesize SecondsItem;
#ifndef __OPTIMIZE__
@synthesize ABrequestString;
#endif
- (id)init
{
    if(self = [super init])
    {
        Msg = nil;
        Data = nil;
        List = nil;
        DicNotParsed = nil;
        resultDic = nil;
        IsFromDB = NO;
        SecondsItem = nil;
    }
    return self;
}
- (id) initWithArgs:(NSDictionary*)args response:(NSDictionary*)dic
{
    if(dic)
    {
        if(self = [super init])
        {
            [self setProperties:dic];
            self.Args = args;
            self.DicNotParsed = dic;
            if(dic)
            {
                if([dic objectForKey:@"totaldetailcount"])
                    TotalDetailCount = [[dic objectForKey:@"totaldetailcount"]intValue];
                if([dic objectForKey:@"totalcount"])
                    TotalCount = [[dic objectForKey:@"totalcount"]intValue];
            }
        }
    }
    else
    {
        self = [super init];
    }
    return self;
}
-(void)dealloc
{
    PP_RELEASE(Msg);
    PP_RELEASE(Data);
    PP_RELEASE(SecondsItem);
    PP_RELEASE(List);
    PP_RELEASE(Args);
    PP_RELEASE(DicNotParsed);
    PP_RELEASE(resultDic);
    PP_RELEASE(ResultHash);
    PP_RELEASE(ArgsHash);
    PP_SUPERDEALLOC;
}
@end

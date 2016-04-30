//
//  WindowItem.m
//  SuixingSteward
//  记录窗口开启与关闭的列表
//  Created by HUANGXUTAO on 14-7-17.
//  Copyright (c) 2014年 jokefaker. All rights reserved.
//

#import "WindowItem.h"
#import "JSON.h"
//#import "HCDBHelper.h"

@implementation WindowItem
@synthesize WinOrderID,IsOpened,IsDeallocate;
@synthesize WinClassName,WinInstance,WinParameters;
@synthesize WinParaDataKeyName;
@synthesize UrlString;
@synthesize EnterTime,LeaveTime;
@synthesize UIOSupport;
-(id)init{
    self = [super init];
    if(self)
    {
        self.TableName = @"windowlist";
        self.KeyName = @"winorderid";
    }
    return self;
}
-(void)dealloc
{
    PP_RELEASE(WinClassName);
    PP_RELEASE(WinInstance);
    PP_RELEASE(WinParameters);
    PP_RELEASE(WinParaDataKeyName);
    PP_RELEASE(UrlString);
    PP_RELEASE(LeaveTime);
    PP_RELEASE(EnterTime);
    
    PP_SUPERDEALLOC;
}
#pragma encodeWithCode decodeWithCoder

-(NSString *)JSONRepresentationEx
{
    NSMutableDictionary * dic = [[NSMutableDictionary alloc]init];
    [dic setObject:[NSNumber numberWithLong:self.WinOrderID] forKey:@"WinOrderID"];
    [dic setObject:[NSNumber numberWithInt:self.IsOpened] forKey:@"IsOpened"];
    [dic setObject:[NSNumber numberWithInt:self.IsDeallocate] forKey:@"IsDeallocate"];
    [dic setObject:self.WinClassName forKey:@"WinClassName"];
    if(self.WinParameters)
        [dic setObject:self.WinParameters forKey:@"WinParameters"];
    if(self.WinParaDataKeyName)
        [dic setObject:self.WinParaDataKeyName forKey:@"WinParaDataKeyName"];
    [dic setObject:[NSNumber numberWithInt:UIOSupport] forKey:@"uiosupport"];
    
    NSString * s = [dic JSONRepresentationEx];
    PP_RELEASE(dic);
    
    return s;
}
+ (void)saveData:(NSString*)data key:(NSString *)keyName
{
    
}
+ (NSString *)readData:(NSString *)keyName
{
    return nil;
}
@end

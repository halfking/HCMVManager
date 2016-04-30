//
//  UploadParameters.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-10-11.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "UploadParameters.h"
#import <hccoren/JSON.h>
#import <hccoren/HCImageItem.h>

@implementation UploadParameters
@synthesize FileName;
//@synthesize CutMode;
@synthesize ThumnateList;
@synthesize IsAddWaterMarker;
@synthesize IsAllAddedMarker;
@synthesize TargetFileName;
@synthesize GroupName;
+ (UploadParameters *) initWithArgs:(NSString *)fileName andGroup:(NSString *)groupName andThumnates:(NSString *)thumnateList
{
    UploadParameters * result = [[UploadParameters alloc]init];
    result.FileName = fileName;
    result.ThumnateList  = thumnateList;
    result.GroupName = groupName;
    result.IsAddWaterMarker = FALSE;
    result.IsAllAddedMarker = FALSE;
    result.TargetFileName = nil;
    return PP_AUTORELEASE(result);
//    return [result autorelease];
}
-(void)dealloc
{
    PP_RELEASE(FileName);
    PP_RELEASE(ThumnateList);
    PP_RELEASE(GroupName);
    PP_RELEASE(TargetFileName);
    
    
    PP_SUPERDEALLOC;
//    [super dealloc];
}
@end

#pragma marker UploadResponse
//完成上传
@implementation UploadResponse
@synthesize S;
@synthesize Msg;
@synthesize Src;
@synthesize Group;
@synthesize Pics;
+(UploadResponse *)initWithJson:(NSString *)json
{
    UploadResponse * result = [[UploadResponse alloc]init];
    @try {
        NSDictionary * dic = [json JSONValueEx];
        result.S = [[dic objectForKey:@"s"] intValue];
        result.Src = [dic objectForKey:@"src"];
        result.Msg = [dic objectForKey:@"msg"];
        result.Group = [dic objectForKey:@"group"];
        result.Pics = PP_AUTORELEASE([[NSMutableArray alloc]init] );
        NSArray * imageList = [dic objectForKey:@"pics"];
        if(imageList!=nil)
        {
            for (NSDictionary * object in imageList) {
                if(object!=nil)
                {
                    HCImageItem * item = [HCImageItem initWithDictionary:object];
                    [result.Pics addObject:item];
                }
            }
        }
    }
    @catch (NSException *exception) {
        result.S = -2;
        result.Msg = json;
        result.Group = @"error";
        NSLog(@"upload response parse error:%@",[exception description]);
    }
    @finally {
        
    }
    
    return PP_AUTORELEASE(result);// [result autorelease];
}
- (void)dealloc
{
    self.Msg = nil;
    self.Src = nil;
    self.Pics = nil;
    PP_SUPERDEALLOC;
//    [super dealloc];
}
@end

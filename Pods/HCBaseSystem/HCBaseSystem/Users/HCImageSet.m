//
//  HCImageSet.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-10-16.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//  图片的集合，包括了布局模版
#import "HCImageSet.h"
#import <hccoren/json.h>

@implementation HCImageSet
@synthesize Size;
@synthesize Type;
@synthesize Layout;
@synthesize Data;
- (id)init
{
    self = [super init];
    self.Data  = PP_AUTORELEASE([[NSMutableArray alloc]init]);
    return self;
}
- (id)initWithJSON:(NSString *)json
{
    if(json==nil||[json length]==0)
    {
        self =  [super init];
        return self;
    }
    else
    {
        NSString * tempJson = [json stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //    NSString * tempJson = [json stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
        NSDictionary * dic =nil;
        if([tempJson hasSuffix:@"}"] && [tempJson hasPrefix:@"{"])
        {
            dic = [tempJson JSONValueEx];
            //        id data = [dic objectForKey:@"data"];
            //        if([data isKindOfClass:[NSArray class]])
            //        {
            //            dic = [(NSArray *)data objectAtIndex:0];
            //        }
        }
        else if([tempJson hasPrefix:@"["] && [tempJson hasSuffix:@"]"])
        {
            NSString * temp = [NSString stringWithFormat:@"{\"layout\":\"\",\"type\":0,\"size\":0,\"data\":%@ }",tempJson ];
            dic = [temp JSONValueEx];
        }
        else
        {
            NSString * temp = [NSString stringWithFormat:@"{\"layout\":\"\",\"type\":0,\"size\":0,\"data\":[{\"src\":\"%@\"}] }",tempJson ];
            dic = [temp JSONValueEx];
            
            //dic = [NSDictionary dictionaryWithObject:tempJson forKey:@"src"];
        }
        return [self initWithDictionary:dic];
    }
}
- (id)initWithDictionary:(NSDictionary *)dic
{
    if(self = [super init])
    {
        if([dic objectForKey:@"layout"]==nil &&
           ([dic objectForKey:@"src"]!=nil || [dic objectForKey:@"url"]!=nil))
        {
            self.Layout = @"";
            self.Data = PP_AUTORELEASE([[NSMutableArray alloc]init]);
            HCImageItem * image = [HCImageItem initWithDictionary:dic];
            [self.Data addObject:image];
        }
        else
        {
            self.Layout = [dic objectForKey:@"layout"];
            if([dic objectForKey:@"type"]!=nil)
                self.Type = [[dic objectForKey:@"type"]intValue];
            if([dic objectForKey:@"size"]!=nil)
                self.Size = [[dic objectForKey:@"size"] intValue];
            
            id imageList = [dic objectForKey:@"data"];
            if(imageList==nil)
            {
                self.Data = nil;
            }
            else
            {
                NSArray * list = (NSArray *)imageList;
                self.Data = PP_AUTORELEASE([[NSMutableArray alloc]init]);
                for (NSDictionary * item in list) {
                    @try {
                        NSString * s = [item objectForKey:@"src"];
                        if(s== nil) s=  [item objectForKey:@"url"];
                        if(s)
                        {
                            //处理如下情况：
                            //Hotel/2013/rr/1da66455a16e441f82cdfdcde2c57755.jpg,Hotel/2013/rs/9c8e4ad5076848ee8bc183ab1830deeb.jpg,Hotel/2013/rt/d151b4586532494f983d8cb2da13cca9.jpg,Hotel/2013/ru/a4a2ec979202416b94db510415b8549e.jpg,
                            NSRange orgRange = NSMakeRange(0, s.length);
                            NSRange range = [s rangeOfString:@"," options:NSCaseInsensitiveSearch range:orgRange];
                            while (range.length!=NSNotFound && range.length>0 && range.length < s.length)
                            {
                                NSMutableDictionary * dicTemp = [NSMutableDictionary dictionaryWithDictionary:item];
                                NSString * temp = [s substringWithRange:NSMakeRange(orgRange.location , MIN((range.location - orgRange.location),(s.length - orgRange.location)))];
#ifdef TRACKPAGES
                                DLog(@"tempimage:%@",temp);
#endif
                                [dicTemp setObject:temp forKey:@"src"];
                                HCImageItem * image = [HCImageItem initWithDictionary:dicTemp];
                                [self.Data addObject:image];
                                orgRange = NSMakeRange(range.location+1, s.length - range.location-1);
                                if(orgRange.location >= s.length) break;
                                //                            [result.Data addObject:image];
                                range = [s rangeOfString:@"," options:NSCaseInsensitiveSearch range:orgRange];
                            }
                            if(orgRange.location< s.length)
                            {
                                NSMutableDictionary * dicTemp = [NSMutableDictionary dictionaryWithDictionary:item];
                                NSString * temp = [s substringWithRange:NSMakeRange(orgRange.location , s.length - orgRange.location)];
                                [dicTemp setObject:temp forKey:@"src"];
                                HCImageItem * image2 = [HCImageItem initWithDictionary:dicTemp];
                                [self.Data addObject:image2];
                            }
                        }
                        else
                        {
                            
                        }
                    }
                    @catch (NSException *exception) {
                        NSLog(@"parse item \"%@\" error:%@",[item JSONRepresentationEx],[exception description]);
                    }
                    @finally {
                        
                    }
                }
                
            }
        }
    }
    return self;
    
}
+ (HCImageSet *)initWithJson:(NSString *)json
{
    if(json==nil) return nil;
    if([json length]==0) return nil;
    NSString * tempJson = [json stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    //    NSString * tempJson = [json stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
    NSDictionary * dic =nil;
    if([tempJson hasSuffix:@"}"] && [tempJson hasPrefix:@"{"])
    {
        dic = [tempJson JSONValueEx];
        //        id data = [dic objectForKey:@"data"];
        //        if([data isKindOfClass:[NSArray class]])
        //        {
        //            dic = [(NSArray *)data objectAtIndex:0];
        //        }
    }
    else if([tempJson hasPrefix:@"["] && [tempJson hasSuffix:@"]"])
    {
        NSString * temp = [NSString stringWithFormat:@"{\"layout\":\"\",\"type\":0,\"size\":0,\"data\":%@ }",tempJson ];
        dic = [temp JSONValueEx];
    }
    else
    {
        NSString * temp = [NSString stringWithFormat:@"{\"layout\":\"\",\"type\":0,\"size\":0,\"data\":[{\"src\":\"%@\"}] }",tempJson ];
        dic = [temp JSONValueEx];
        
        //dic = [NSDictionary dictionaryWithObject:tempJson forKey:@"src"];
    }
    //    DLog(@"images json:%@",json);
    return [HCImageSet initWithDictionary:dic];
    
}
+ (HCImageSet *)initWithDictionary:(NSDictionary *)dic
{
    if(dic==nil) return nil;
    HCImageSet * result = [[HCImageSet alloc]initWithDictionary:dic];
    return PP_AUTORELEASE(result);
    
//    //只有一张图片，没有格式
//    if([dic objectForKey:@"layout"]==nil &&
//       ([dic objectForKey:@"src"]!=nil || [dic objectForKey:@"url"]!=nil))
//    {
//        result.Layout = @"";
//        result.Data = [[[NSMutableArray alloc]init] autorelease];
//        HCImageItem * image = [HCImageItem initWithDictionary:dic];
//        [result.Data addObject:image];
//    }
//    else
//    {
//        result.Layout = [dic objectForKey:@"layout"];
//        if([dic objectForKey:@"type"]!=nil)
//            result.Type = [[dic objectForKey:@"type"]intValue];
//        if([dic objectForKey:@"size"]!=nil)
//            result.Size = [[dic objectForKey:@"size"] intValue];
//        
//        id imageList = [dic objectForKey:@"data"];
//        if(imageList==nil)
//            result.Data = nil;
//        else
//        {
//            NSArray * list = (NSArray *)imageList;
//            result.Data = [[[NSMutableArray alloc]init] autorelease];
//            for (NSDictionary * item in list) {
//                @try {
//                    NSString * s = [item objectForKey:@"src"];
//                    if(s== nil) s=  [item objectForKey:@"url"];
//                    if(s)
//                    {
//                        //处理如下情况：
//                        //Hotel/2013/rr/1da66455a16e441f82cdfdcde2c57755.jpg,Hotel/2013/rs/9c8e4ad5076848ee8bc183ab1830deeb.jpg,Hotel/2013/rt/d151b4586532494f983d8cb2da13cca9.jpg,Hotel/2013/ru/a4a2ec979202416b94db510415b8549e.jpg,
//                        NSRange orgRange = NSMakeRange(0, s.length);
//                        NSRange range = [s rangeOfString:@"," options:NSCaseInsensitiveSearch range:orgRange];
//                        while (range.length!=NSNotFound && range.length>0 && range.length < s.length)
//                        {
//                            NSMutableDictionary * dicTemp = [NSMutableDictionary dictionaryWithDictionary:item];
//                            NSString * temp = [s substringWithRange:NSMakeRange(orgRange.location , MIN((range.location - orgRange.location),(s.length - orgRange.location)))];
//#ifdef TRACKPAGES
//                            DLog(@"tempimage:%@",temp);
//#endif
//                            [dicTemp setObject:temp forKey:@"src"];
//                            HCImageItem * image = [HCImageItem initWithDictionary:dicTemp];
//                            [result.Data addObject:image];
//                            orgRange = NSMakeRange(range.location+1, s.length - range.location-1);
//                            if(orgRange.location >= s.length) break;
//                            //                            [result.Data addObject:image];
//                            range = [s rangeOfString:@"," options:NSCaseInsensitiveSearch range:orgRange];
//                        }
//                        if(orgRange.location< s.length)
//                        {
//                            NSMutableDictionary * dicTemp = [NSMutableDictionary dictionaryWithDictionary:item];
//                            NSString * temp = [s substringWithRange:NSMakeRange(orgRange.location , s.length - orgRange.location)];
//                            [dicTemp setObject:temp forKey:@"src"];
//                            HCImageItem * image2 = [HCImageItem initWithDictionary:dicTemp];
//                            [result.Data addObject:image2];
//                        }
//                    }
//                    else
//                    {
//                        
//                    }
//                }
//                @catch (NSException *exception) {
//                    NSLog(@"parse item \"%@\" error:%@",[item JSONRepresentationEx],[exception description]);
//                }
//                @finally {
//                    
//                }
//            }
//            
//        }
//    }
//    return [result autorelease];
}
-(int)count
{
    if(self.Data!=nil)
        return (int)[self.Data count];
    else
        return 0;
}
-(void)dealloc
{
    self.Layout = nil;
    self.Data = nil;
    PP_SUPERDEALLOC;
}
@end

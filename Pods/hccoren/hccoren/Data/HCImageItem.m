//
//  HCImageItem.m
//  HotelCloud
//
//  Created by XUTAO HUANG on 12-10-11.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//


#import "HCImageItem.h"
#import "JSON.h"
#import "DeviceConfig.h"
//#import "CommonUtil.h"
//#import "HCDestinationPhoto.h"
//#import "HCDBHelper(WT).h"
//#import "SystemConfiguration.h"
//#import "HCUserSettings.h"
//#import "UserManager.h"
//#import "CommonUtil.h"
#import "HCFileManager.h"
@implementation HCImageItem
@synthesize ImageID;
@synthesize Title;
@synthesize Src;
@synthesize Sort;
@synthesize Icon;
@synthesize Wh;
@synthesize model;
//@synthesize ShareRights;
@synthesize ObjectID;
@synthesize ObjectType;
@synthesize Lat;
@synthesize Lng;
@synthesize Width;
@synthesize Height;

-(id)init
{
    self = [super init];
    if(self)
    {
        self.TableName = @"images";
        self.KeyName = @"ImageID";
    }
    return self;
}
//当图片没有ＩＤ时将无法保存到本地数据库
//-(void)setKeyID
//{
//    if(ImageID ==0)
//    {
//        ImageID = [DBHelper_WT getMaxImageID];
//        if(ImageID<=0)
//        {
//            NSDate * bDate =[[NSDate alloc]initWithTimeIntervalSince1970:0];
//            self.ImageID =  [[NSDate date]timeIntervalSinceDate:bDate];
//            PP_RELEASE(bDate);
//        }
//    }
//}
+ (HCImageItem *) initWithDictionary:(NSDictionary *)dic
{
    if(dic==nil) return nil;
    HCImageItem * result = [[HCImageItem alloc]init];
    PP_BEGINPOOL(pool);
    
    result.Title = [dic objectForKey:@"title"];
    if ([dic objectForKey:@"src"])
    {
        result.Src = [dic objectForKey:@"src"];
        
    }else if([dic objectForKey:@"url"])
    {
        result.Src = [dic objectForKey:@"url"];
        
    }else if([dic objectForKey:@"ico"])
    {
        result.Src = [dic objectForKey:@"ico"];
        
    }else if([dic objectForKey:@"logo"])
    {
        result.Src = [dic objectForKey:@"logo"];
    }
    if([dic objectForKey:@"pid"])
    {
        result.ImageID = [[dic objectForKey:@"pid"]intValue];
    }
    if(result.Src == nil) //如果是另外一种结构 destinationphotos
    {
        //        DLog(@"images dic:%@",[dic JSONRepresentationEx]);
        //        HCDestinationPhoto * p = [[HCDestinationPhoto alloc]initWithDictionary:dic];
        //        result.Src = p.ImageUrl;
        //        result.Wh = p.ImageWH;
        //        result.ObjectType = p.ObjectType;
        //        result.ObjectID = p.ObjectID;
        //        result.Title = p.Title;
        //        if(result.Src==nil)
        //        {
        //            DLog(@"images dic:%@",[dic JSONRepresentationEx]);
        //        }
        //        [p release];
    }
    else
    {
        result.Icon = [dic objectForKey:@"icon"];
        result.Wh = [dic objectForKey:@"wh"];
        if([dic objectForKey:@"lat"]!=nil)
            result.Lat = [[dic objectForKey:@"lat"]doubleValue];
        if([dic objectForKey:@"lng"]!=nil)
            result.Lat = [[dic objectForKey:@"lng"]doubleValue];
        
        if([dic objectForKey:@"objectid"]!=nil)
            result.ObjectID = [[dic objectForKey:@"objectid"]intValue];
        if([dic objectForKey:@"objecttype"]!=nil)
            result.ObjectType = [[dic objectForKey:@"objecttype"]shortValue];
    }
    if(result.Icon == nil)
    {
        result.Icon = [result urlWithWH:150 andHeight:150];
    }
    if(result.Wh!=nil && [result.Wh length]>0)
    {
        NSError *error;
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\d+)[x\\-\\*](\\d+)" options:NSRegularExpressionCaseInsensitive error:&error];
        
        int width = 0;
        int height = 0;
        if(regex!=nil)
        {
            NSArray *array =    nil;
            
            array = [regex matchesInString:result.Wh options:0 range:NSMakeRange(0, [result.Wh length])];
            //NSString *str1 = nil;
            for (NSTextCheckingResult* match in array)
            {
                //NSRange matchRange = [match range];
                @try {
                    
                    NSRange r1 = [match rangeAtIndex:1];
                    if (!NSEqualRanges(r1, NSMakeRange(NSNotFound, 0))) {    // 由时分组1可能没有找到相应的匹配，用这种办法来判断
                        NSString *tagName = [result.Wh substringWithRange:r1];  // 分组1所对应的串
                        width = [tagName intValue];
                    }
                    NSRange r2 = [match rangeAtIndex:2];
                    if (!NSEqualRanges(r2, NSMakeRange(NSNotFound, 0))) {    // 由时分组1可能没有找到相应的匹配，用这种办法来判断
                        NSString *tagName = [result.Wh substringWithRange:r2];  // 分组1所对应的串
                        height = [tagName intValue];
                    }
                }
                @catch (NSException *exception) {
                    NSLog(@"Parse widthheight:%@ error:%@",result.Wh,[exception description]);
                }
                @finally {
                    
                }
                
            }
        }
        [result setWidthAndHeight:width andHeight:height];
    }
    else
    {
        int width = 0;
        int height = 0;
        if ([dic objectForKey:@"width"]!=nil &&
            ([[dic objectForKey:@"width"] isKindOfClass:[NSString class]]
             ||[[dic objectForKey:@"width"] isKindOfClass:[NSNumber class]]))
        {
            width = [[dic objectForKey:@"width"]intValue];
        }
        if ([dic objectForKey:@"height"]!=nil &&
            ([[dic objectForKey:@"height"] isKindOfClass:[NSString class]]
             ||[[dic objectForKey:@"height"] isKindOfClass:[NSNumber class]]))
        {
            height = [[dic objectForKey:@"height"]intValue];
        }
        [result setWidthAndHeight:width andHeight:height];
        
    }
//    [result setKeyID];
    PP_ENDPOOL(pool);
    return PP_AUTORELEASE(result);
}
+ (HCImageItem *) initWithJson:(NSString *)json
{
    
    if(json==nil) return nil;
    if([json length] <4) return nil;
    PP_BEGINPOOL(pool);
    NSString * tempJson = [json stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
    if([tempJson hasSuffix:@" "])
    {
        tempJson = [tempJson substringToIndex:tempJson.length-1];
    }
    if([tempJson hasSuffix:@","])
    {
        tempJson = [tempJson substringToIndex:tempJson.length-1];
    }
    NSDictionary * dic =nil;
    if([tempJson hasSuffix:@"}"] && [tempJson hasPrefix:@"{"])
    {
        dic = [tempJson JSONValueEx];
    }
    else
    {
        dic = [NSDictionary dictionaryWithObject:tempJson forKey:@"src"];
    }
    HCImageItem * item = PP_RETAIN([HCImageItem initWithDictionary:dic]);
    PP_ENDPOOL(pool);
    
    return PP_AUTORELEASE(item);
}

- (void) setWidthAndHeight:(int)width andHeight:(int)height
{
    Width  = width;
    Height = height;
}
#pragma mark urlWithWH
////根据网络情况计算需要的图片的真实大小
//static NSArray * staticSizeList = nil;
//static NSMutableDictionary * imageSizeList = nil;
//+ (CGSize) getRealSize:(int)width height:(int)height
//{
//   UserManager * config = [UserManager sharedUserManager];
//    if(!staticSizeList)
//    {
//        @synchronized(config)
//        {
//            if(!staticSizeList)
//            {
//                staticSizeList = [NSArray arrayWithObjects:
//                                  [NSDictionary dictionaryWithObjectsAndKeys:@(640),@"width",@(0),@"height", nil],
//                                  [NSDictionary dictionaryWithObjectsAndKeys:@(350),@"width",@(65),@"height", nil],
//                                  [NSDictionary dictionaryWithObjectsAndKeys:@(300),@"width",@(200),@"height", nil],
//                                  [NSDictionary dictionaryWithObjectsAndKeys:@(300),@"width",@(0),@"height", nil],
//                                  [NSDictionary dictionaryWithObjectsAndKeys:@(150),@"width",@(150),@"height", nil],
//                                  [NSDictionary dictionaryWithObjectsAndKeys:@(150),@"width",@(0),@"height", nil],
//                                  //[NSDictionary dictionaryWithObjectsAndKeys:@(80),@"width",@(80),@"height", nil],
//                                  [NSDictionary dictionaryWithObjectsAndKeys:@(60),@"width",@(60),@"height", nil],
//                                  //[NSDictionary dictionaryWithObjectsAndKeys:@(60),@"width",@(0),@"height", nil],
//                                  
//                                  nil];
//                PP_RETAIN(staticSizeList);
//                //                60X60,150X150,150X150-5,170X170,170X170-5,300X200-5,300X0,640X0,650X0
//            }
//            if(!imageSizeList)
//            {
//                imageSizeList = [[NSMutableDictionary alloc]initWithCapacity:10];
//            }
//        }
//    }
//    
//    //    DeviceConfig * dc = [DeviceConfig config];
//    
//    if(width>0||height>0)
//    {
////        HCImgViewModel model = config.currentSettings.imgModel;
//        NetworkStatus networkType = [DeviceConfig config].networkStatus;
//        //低精度，或者在3G情况下的智能模式，只对大图进行处理
//        NSString * key = [NSString stringWithFormat:@"%d-%d-%d-%d",width,height,model,networkType];
//        if([imageSizeList objectForKey:key])
//        {
//            return CGSizeFromString([imageSizeList objectForKey:key]);
//        }
//        if(model==HCImgViewModelCustom||(model == HCImgViewModelAgent && networkType==ReachableViaWWAN))
//        {
//            if(width>150) //小图就不要省精度了
//            {
//                width/=2.0f;
//                height /=2.0f;
//                if(width>0) width ++;
//                if(height>0) height ++;
//            }
//            CGFloat rateX = height<=0?1:width<=0?0:width * 1.0f/height;
//            if(width!=height && rateX>0 && rateX < 1)
//            {
//                int currentRow = 0;
//                int matchedRow = -1;
//                CGFloat deltaRate = 1.0f;
//                for (NSDictionary * sizeDic in staticSizeList) {
//                    int newWidth = [[sizeDic objectForKey:@"width"]intValue];
//                    int newHeight = [[sizeDic objectForKey:@"height"]intValue];
//                    if(newWidth >0 && newHeight >0 && newWidth<=width && newHeight<=height)
//                    {
//                        CGFloat rateNew =  newHeight<=0?1:newWidth<=0?0:newWidth * 1.0f/newHeight;
//                        if(deltaRate <=0) deltaRate = 0- deltaRate;
//                        
//                        if(deltaRate > rateNew - rateX && rateNew-rateX >0)
//                        {
//                            deltaRate = rateNew = rateX;
//                            matchedRow = currentRow;
//                        }
//                        else if(0 - deltaRate < rateNew - rateX && rateNew-rateX <0)
//                        {
//                            deltaRate = rateX - rateNew;
//                            matchedRow = currentRow;
//                        }
//                    }
//                    currentRow ++;
//                }
//                if(matchedRow>=0 && matchedRow< staticSizeList.count && deltaRate <= 0.1)
//                {
//                    NSDictionary * sizeDic = [staticSizeList objectAtIndex:matchedRow];
//                    return CGSizeMake([[sizeDic objectForKey:@"width"]intValue], [[sizeDic objectForKey:@"height"]intValue]);
//                }
//                else    //没有匹配到同比例的，或精度不够
//                {
//                    height = 0;
//                }
//            }
//            for (NSDictionary * sizeDic in staticSizeList) {
//                int newWidth = [[sizeDic objectForKey:@"width"]intValue];
//                int newHeight = [[sizeDic objectForKey:@"height"]intValue];
//                
//                if(height==width)
//                {
//                    if(newWidth <=width && newWidth==newHeight)
//                    {
//                        height = newHeight;
//                        width = newWidth;
//                        break;
//                    }
//                }
//                else if(height==0)
//                {
//                    if(newWidth <=width && newHeight==0)
//                    {
//                        height = newHeight;
//                        width = newWidth;
//                        break;
//                    }
//                }
//                else if(width==0)
//                {
//                    if(newHeight <=height && newWidth==0)
//                    {
//                        height = newHeight;
//                        width = newWidth;
//                        break;
//                    }
//                }
//                else
//                {
//                    if(newWidth <=width && newHeight <=height)
//                    {
//                        height = newHeight;
//                        width = newWidth;
//                        break;
//                    }
//                }
//            }
//            CGSize size =CGSizeMake(width, height);
//            [imageSizeList setObject:NSStringFromCGSize(size) forKey:key];
//            return size;
//        }
//        CGSize size =CGSizeMake(width, height);
//        [imageSizeList setObject:NSStringFromCGSize(size) forKey:key];
//        return size;
//    }
//    return CGSizeMake(width, height);
//}
//
//+ (NSString*)getRealNoImage:(CGSize)size
//{
//    if(size.width==640)
//    {
//        return NOIMAGE_640X320;
//    }
//    else if(size.width==600)
//    {
//        return NOIMAGE_600X346;
//    }
//    else if(size.width ==320 ||size.width==300)
//    {
//        return NOIMAGE_290X290;
//    }
//    else if(size.width==150)
//    {
//        return NOIMAGE_160X160;
//    }
//    else if(size.width==120)
//    {
//        return NOIMAGE_120X120;
//    }
//    else
//    {
//        return NOIMAGE_100X100;
//    }
//}
#pragma mark - urlwithwh
+ (NSString *)urlWithWH:(NSString *)src width:(int)width height:(int)height mode:(int)mode
{
    //简化处理，只处理7牛的图片，其它的原样返回
    //http://qiniuphotos.qiniudn.com/gogopher.jpg?imageView/2/w/200/h/200
    //http://7xj5fp.com1.z0.glb.clouddn.com/微博推广图1.png?imageView/2/w200/h/200
    //    imageView/<mode>
    //    /w/<width>
    //    /h/<height>
    //    /q/<quality>
    //    /format/<format>
    DeviceConfig * config = [DeviceConfig config];
    if([HCFileManager isQiniuServer:src])
    {
        NSMutableString * str = [[NSMutableString alloc]init];
        NSString * tempUrl = src.lowercaseString ;
        NSRange rr = [tempUrl rangeOfString:@"/imageview"];
        if(rr.location!=NSNotFound)
        {
            src = [src substringToIndex:rr.location];
        }
        else
        {
            NSRange rr = [tempUrl rangeOfString:@"?imageview"];
            if(rr.location!=NSNotFound)
            {
                src = [src substringToIndex:rr.location];
            }
        }
        // containts "vframe" 代表从在视频中取封面 目前不能正确裁剪 所以不要加参数
        if ([src containsString:@"vframe"]) {
            return src;
        }
        [str appendString:src];
        if([src rangeOfString:@"?"].length>0)
        {
            [str appendString:@"/imageView"];
        }
        else
        {
        [str appendString:@"?imageView"];
        }
        if(mode>0)
        {
            [str appendFormat:@"/%d",mode ];
        }
        if(width>0)
        {
            [str appendFormat:@"/w/%i",(int)roundf(width*config.Scale)];
        }
        if(height>0)
        {
            [str appendFormat:@"/h/%i",(int)roundf(height*config.Scale)];
        }
        NSString * ret = [NSString stringWithString:str];
        PP_RELEASE(str);
        return ret;
    }
    else
    {
        NSString * root = [[DeviceConfig Instance] ImagePathRoot];
        CGSize realSize = CGSizeMake(roundf(width*config.Scale),roundf(height*config.Scale));
        //[HCImageItem getRealSize:width height:height];
        
        if(src==nil||[src length]==0)
        {
            return nil;
//            return [HCImageItem getRealNoImage:realSize];
        }
        width = realSize.width;
        height = realSize.height;
        //如果没有相对目录，则认为是本地文件，非网络文件。
        
        if([src hasPrefix:@"file://"]||[src hasPrefix:@"/"]||[src hasPrefix:@"~"])
        {
            return src;
        }
        NSRange range1 = [src rangeOfString:@"/"];
        if(range1.length <=0)
        {
            return src;
        }
        PP_BEGINPOOL(pool);
        //    NSAutoreleasePool * pool = [NSAutoreleasePool new];
        
        NSString *nSrc = [src lowercaseString];
        //本机图片地址开头：/users/
        NSString * DocumentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"documents"];
        if([nSrc hasPrefix:DocumentsPath])
        {
            PP_ENDPOOL(pool);
            //        [pool drain];
            return src;
        }
        
        //    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc]init];
        NSError *error;
        int length = (int)[nSrc length];
        NSRange range = NSMakeRange(0, length);
        
        NSString * regRootExpress = [NSString stringWithFormat:@"%@|%@|%@",
                                     [root stringByReplacingOccurrencesOfString:@"." withString:@"\\."] ,
                                     config.ImagePathRoot,config.ImagePathRoot2];
        //NSLog(@"regRootExpress:%@",regRootExpress);
        NSRegularExpression *regRoot = [NSRegularExpression
                                        regularExpressionWithPattern:regRootExpress
                                        options:NSRegularExpressionCaseInsensitive error:&error];
        NSTextCheckingResult * rootMatch = [regRoot firstMatchInString:src options:0 range:range];
        
        NSRange rootRange;
        //外站图片
        if(([nSrc hasPrefix:@"http://"] && !rootMatch))
        {
            PP_ENDPOOL(pool);
            //        [pool drain];
            return src;
        }
        if(rootMatch)
        {
            rootRange = rootMatch.range;
            //        NSString * temp = [src substringFromIndex:rootMatch.range.length ];
            //        DLog(@"pre:%@",temp);
        }
        if([nSrc hasPrefix:config.ImagePathRoot2])
        {
            NSMutableString * str = [[NSMutableString alloc]init];
            [str appendString:nSrc];
            [regRoot replaceMatchesInString:str options:NSMatchingReportCompletion range:NSMakeRange(0, str.length) withTemplate:config.ImagePathRoot];
            rootRange.length = [config.ImagePathRoot length];
            nSrc = [NSString stringWithString:str];
            PP_RELEASE(str);
            
            length = (int)nSrc.length;
            range = NSMakeRange(0, length);
        }
        
        if([nSrc hasSuffix:@","])
        {
            nSrc = [nSrc substringToIndex:nSrc.length -1];
        }
        if([nSrc hasSuffix:@"\""])
        {
            nSrc = [nSrc substringToIndex:nSrc.length -1];
        }
        
        /*
         
         NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:@"(.*)(\\.\\d+x\\d+)?(\\.(jpg|gif|bmp|png|jpeg|icon|swf))$" options:NSRegularExpressionCaseInsensitive error:&error]; //RegexOptions.IgnoreCase | RegexOptions.Compiled | RegexOptions.RightToLeft
         
         //     NSRegularExpression *regImg = [NSRegularExpression regularExpressionWithPattern:@"(?<n>.*)(?<ext>\\.(jpg|gif|bmp|png|jpeg|icon|swf))$" options:NSRegularExpressionCaseInsensitive error:&error]; //RegexOptions.IgnoreCase | RegexOptions.Compiled | RegexOptions.RightToLeft
         NSRegularExpression *regImgStart = [NSRegularExpression regularExpressionWithPattern:@"^/upload/" options:NSRegularExpressionCaseInsensitive error:&error]; //RegexOptions.IgnoreCase | RegexOptions.Compiled
         
         //     NSRegularExpression *regImgStart2 = [NSRegularExpression regularExpressionWithPattern:@"^/" options:NSRegularExpressionCaseInsensitive error:&error]; //RegexOptions.IgnoreCase | RegexOptions.Compiled
         NSRegularExpression *regSwf = [NSRegularExpression regularExpressionWithPattern:@"*.swf$" options:NSRegularExpressionCaseInsensitive error:&error];
         NSRegularExpression *regWH = [NSRegularExpression regularExpressionWithPattern:@"\\d+x\\d+$" options:NSRegularExpressionCaseInsensitive error:&error];
         */
        
        //新格式 ?imageView/2/w200/h/200
        
        NSString * ext = nil;
        NSString * pre = nil;
        NSString * whString = nil;
        
        NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:@"(.*)(\\.(jpg|gif|bmp|png|jpeg|icon|swf))?(imageView/\\d+/w/\\d+/h/\\d+)?" options:NSRegularExpressionCaseInsensitive error:&error]; //RegexOptions.IgnoreCase | RegexOptions.Compiled | RegexOptions.RightToLeft
        
        //     NSRegularExpression *regImg = [NSRegularExpression regularExpressionWithPattern:@"(?<n>.*)(?<ext>\\.(jpg|gif|bmp|png|jpeg|icon|swf))$" options:NSRegularExpressionCaseInsensitive error:&error]; //RegexOptions.IgnoreCase | RegexOptions.Compiled | RegexOptions.RightToLeft
        //    NSRegularExpression *regImgStart = [NSRegularExpression regularExpressionWithPattern:@"^/upload/" options:NSRegularExpressionCaseInsensitive error:&error]; //RegexOptions.IgnoreCase | RegexOptions.Compiled
        
        //     NSRegularExpression *regImgStart2 = [NSRegularExpression regularExpressionWithPattern:@"^/" options:NSRegularExpressionCaseInsensitive error:&error]; //RegexOptions.IgnoreCase | RegexOptions.Compiled
        //    NSRegularExpression *regSwf = [NSRegularExpression regularExpressionWithPattern:@"*.swf$" options:NSRegularExpressionCaseInsensitive error:&error];
        //    NSRegularExpression *regWH = [NSRegularExpression regularExpressionWithPattern:@"\\d+x\\d+$" options:NSRegularExpressionCaseInsensitive error:&error];
        
        //匹配是否图片，取出前一段
        NSTextCheckingResult * regMatch = [reg firstMatchInString:nSrc options:0 range:range];
        if(regMatch)
        {
            NSRange r1 = [regMatch rangeAtIndex:1];
            if (!NSEqualRanges(r1, NSMakeRange(NSNotFound, 0))) {    // 由时分组1可能没有找到相应的匹配，用这种办法来判断
                pre = [nSrc substringWithRange:r1];  // 分组1所对应的串
            }
            r1 = [regMatch rangeAtIndex:2];
            if (!NSEqualRanges(r1, NSMakeRange(NSNotFound, 0))) {    // 由时分组1可能没有找到相应的匹配，用这种办法来判断
                ext = [nSrc substringWithRange:r1];  // 分组1所对应的串
            }
            
            r1 = [regMatch rangeAtIndex:3];
            if (!NSEqualRanges(r1, NSMakeRange(NSNotFound, 0))) {
                whString = [nSrc substringWithRange:r1];  // 分组1所对应的串
            }
            
            //        NSTextCheckingResult * preMatch2 = [regWH firstMatchInString:pre options:0 range:NSMakeRange(0, [pre length])];
            //        if(preMatch2)
            //        {
            //            if(preMatch2.range.location>0)
            //            {
            //                whString = [pre substringFromIndex:preMatch2.range.location];
            //                pre = [pre substringToIndex:preMatch2.range.location -1];
            //
            //            }
            //        }
            
            //NSLog(@"Pre:%@",pre);
            //NSLog(@"Ext:%@",ext);
            
        }
        else
        {
            NSLog(@"not match return src:%@",nSrc);
            nSrc = PP_RETAIN(nSrc);
            PP_ENDPOOL(pool);
            return PP_AUTORELEASE(nSrc);// [ nSrc autorelease];
            whString = nil;
        }
        //    if(rootMatch && pre!=nil)
        //    {
        //        pre  = [pre substringFromIndex:rootRange.location + rootRange.length ];
        //        //NSLog(@"Pre: %@",pre);
        //    }
        
        //    NSTextCheckingResult *firstMatch = [regSwf firstMatchInString:nSrc options:0 range:range];
        //    if(firstMatch) //is swf
        //    {
        //        width = -1;
        //        height = -1;
        //    }
        if (width == 0 && height == 0)
        {
            //        whString = @"_o";
            whString = @"";
        }
        else if (width > 0 || height > 0)
        {
            whString = [NSString stringWithFormat:@"imageView/2/w/%i/h/%i",width,height];
        }
        
        if(!whString) whString = @"";
        if(!ext) ext = @"";
        //    else if(whString.length>0 && (![whString hasPrefix:@"."]))
        //    {
        //        whString = [NSString stringWithFormat:@".%@",whString];
        //    }
        
        //    NSTextCheckingResult * regImgStartMatch = [regImgStart firstMatchInString:nSrc options:0 range:range];
        //    if(regImgStartMatch)
        //    {
        //        pre = [pre substringFromIndex:[@"/upload/" length]];
        //    }
        //    else
        //    {
        //        //pre = [NSString stringWithFormat:@"%@%@",@"upload/",pre];
        //    }
        //NSLog(@"Pre:%@",pre);
        
        //    NSString * ret = nil;
        if([pre hasPrefix:@"/"])
            pre = [pre substringFromIndex:1];
        NSString * ret  =  [NSString stringWithFormat:@"%@%@?%@",pre,ext,whString];
        ret = PP_RETAIN(ret);
        PP_ENDPOOL(pool);
        return PP_AUTORELEASE(ret);
    }
}
+ (NSString *)urlWithWH:(NSString *)src width:(int)width height:(int)height
{
    DeviceConfig * config = [DeviceConfig config];
    NSString * root = [config ImagePathRoot];
    //NSLog(@"SRC:%@   ROOT:%@",Src,root);
//    CGSize realSize = [HCImageItem getRealSize:width height:height];
    CGSize realSize = CGSizeMake(width, height);
    if(src==nil||[src length]==0)
    {
        return nil;
//        return [HCImageItem getRealNoImage:realSize];
        //返回本地图片
        //        return @"box.png";
        //return [root stringByAppendingString:@"Themes/Default/images/noimage.100x100.jpg"];
    }
    width = realSize.width;
    height = realSize.height;
    //如果没有相对目录，则认为是本地文件，非网络文件。
    NSRange range1 = [src rangeOfString:@"/"];
    if(range1.length <=0)
    {
        return src;
    }
    if([src hasPrefix:@"file://"])
    {
        return src;
    }
    PP_BEGINPOOL(pool);
    //    NSAutoreleasePool * pool = [NSAutoreleasePool new];
    
    NSString *nSrc = [src lowercaseString];
    //本机图片地址开头：/users/
    NSString * DocumentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"documents"];
    if([nSrc hasPrefix:DocumentsPath])
    {
        PP_ENDPOOL(pool);
        //        [pool drain];
        return src;
    }
    //    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc]init];
    NSError *error;
    NSUInteger length = [nSrc length];
    NSRange range = NSMakeRange(0, length);
    
    NSString * regRootExpress = [NSString stringWithFormat:@"%@|%@",
                                 [root stringByReplacingOccurrencesOfString:@"." withString:@"\\."] ,
                                 [NSString stringWithFormat:@"%@|%@",config.ImagePathRoot,config.ImagePathRoot2]];
    //NSLog(@"regRootExpress:%@",regRootExpress);
    NSRegularExpression *regRoot = [NSRegularExpression
                                    regularExpressionWithPattern:regRootExpress
                                    options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult * rootMatch = [regRoot firstMatchInString:src options:0 range:range];
    
    NSRange rootRange;
    //外站图片
    if(([nSrc hasPrefix:@"http://"] && !rootMatch))
    {
        PP_ENDPOOL(pool);
        //        [pool drain];
        return src;
    }
    if(rootMatch)
    {
        rootRange = rootMatch.range;
        //        NSString * temp = [src substringFromIndex:rootMatch.range.length ];
        //        DLog(@"pre:%@",temp);
    }
    if([nSrc hasPrefix:config.ImagePathRoot2])
    {
        NSMutableString * str = [[NSMutableString alloc]init];
        [str appendString:nSrc];
        [regRoot replaceMatchesInString:str options:NSMatchingReportCompletion range:NSMakeRange(0, str.length) withTemplate:config.ImagePathRoot];
        rootRange.length = [config.ImagePathRoot length];
        nSrc = [NSString stringWithString:str];
        PP_RELEASE(str);
        
        length = nSrc.length;
        range = NSMakeRange(0, length);
    }
    
    if([nSrc hasSuffix:@","])
    {
        nSrc = [nSrc substringToIndex:nSrc.length -1];
    }
    if([nSrc hasSuffix:@"\""])
    {
        nSrc = [nSrc substringToIndex:nSrc.length -1];
    }
    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:@"(.*)(\\.\\d+x\\d+)?(\\.(jpg|gif|bmp|png|jpeg|icon|swf))$" options:NSRegularExpressionCaseInsensitive error:&error]; //RegexOptions.IgnoreCase | RegexOptions.Compiled | RegexOptions.RightToLeft
    
    //     NSRegularExpression *regImg = [NSRegularExpression regularExpressionWithPattern:@"(?<n>.*)(?<ext>\\.(jpg|gif|bmp|png|jpeg|icon|swf))$" options:NSRegularExpressionCaseInsensitive error:&error]; //RegexOptions.IgnoreCase | RegexOptions.Compiled | RegexOptions.RightToLeft
    NSRegularExpression *regImgStart = [NSRegularExpression regularExpressionWithPattern:@"^/upload/" options:NSRegularExpressionCaseInsensitive error:&error]; //RegexOptions.IgnoreCase | RegexOptions.Compiled
    
    //     NSRegularExpression *regImgStart2 = [NSRegularExpression regularExpressionWithPattern:@"^/" options:NSRegularExpressionCaseInsensitive error:&error]; //RegexOptions.IgnoreCase | RegexOptions.Compiled
    NSRegularExpression *regSwf = [NSRegularExpression regularExpressionWithPattern:@"*.swf$" options:NSRegularExpressionCaseInsensitive error:&error];
    NSRegularExpression *regWH = [NSRegularExpression regularExpressionWithPattern:@"\\d+x\\d+$" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString * ext = nil;
    NSString * pre = nil;
    NSString * whString = nil;
    
    
    //匹配是否图片，取出前一段
    NSTextCheckingResult * regMatch = [reg firstMatchInString:nSrc options:0 range:range];
    if(regMatch)
    {
        NSRange r1 = [regMatch rangeAtIndex:1];
        if (!NSEqualRanges(r1, NSMakeRange(NSNotFound, 0))) {    // 由时分组1可能没有找到相应的匹配，用这种办法来判断
            pre = [nSrc substringWithRange:r1];  // 分组1所对应的串
        }
        r1 = [regMatch rangeAtIndex:3];
        if (!NSEqualRanges(r1, NSMakeRange(NSNotFound, 0))) {    // 由时分组1可能没有找到相应的匹配，用这种办法来判断
            ext = [nSrc substringWithRange:r1];  // 分组1所对应的串
        }
        
        //取出可能存在的http://t_hcimg.me/upload/prouduct/2012/gj/6f1570af60ef42e9814b81824bbf202d.150x150 后面的150x150
        NSTextCheckingResult * preMatch2 = [regWH firstMatchInString:pre options:0 range:NSMakeRange(0, [pre length])];
        if(preMatch2)
        {
            if(preMatch2.range.location>0)
            {
                whString = [pre substringFromIndex:preMatch2.range.location];
                pre = [pre substringToIndex:preMatch2.range.location -1];
                
            }
        }
        
        //NSLog(@"Pre:%@",pre);
        //NSLog(@"Ext:%@",ext);
        
    }
    else
    {
        NSLog(@"not match return src:%@",nSrc);
        nSrc = PP_RETAIN(nSrc);
        PP_ENDPOOL(pool);
        return PP_AUTORELEASE(nSrc);// [ nSrc autorelease];
    }
    if(rootMatch && pre!=nil)
    {
        pre  = [pre substringFromIndex:rootRange.location + rootRange.length ];
        //NSLog(@"Pre: %@",pre);
    }
    
    NSTextCheckingResult *firstMatch = [regSwf firstMatchInString:nSrc options:0 range:range];
    if(firstMatch) //is swf
    {
        width = -1;
        height = -1;
    }
    if (width == 0 && height == 0)
    {
        //        whString = @"_o";
        whString = @"";
    }
    else if (width > 0 || height > 0)
    {
        whString = [NSString stringWithFormat:@".%ix%i",width,height];
    }
    
    if(!whString) whString = @"";
    else if(whString.length>0 && (![whString hasPrefix:@"."]))
    {
        whString = [NSString stringWithFormat:@".%@",whString];
    }
    
    NSTextCheckingResult * regImgStartMatch = [regImgStart firstMatchInString:nSrc options:0 range:range];
    if(regImgStartMatch)
    {
        pre = [pre substringFromIndex:[@"/upload/" length]];
    }
    else
    {
        //pre = [NSString stringWithFormat:@"%@%@",@"upload/",pre];
    }
    //NSLog(@"Pre:%@",pre);
    
    //    NSString * ret = nil;
    if([pre hasPrefix:@"/"])
        pre = [pre substringFromIndex:1];
    NSString * ret  =  [NSString stringWithFormat:@"%@%@%@%@",config.ImagePathRoot,pre,whString,ext];
    ret = PP_RETAIN(ret);
    PP_ENDPOOL(pool);
    return PP_AUTORELEASE(ret);
}
//格式化用户上传图片的全地址
- (NSString *)urlWithWH:(int)width andHeight:(int)height
{
    return [HCImageItem urlWithWH:Src width:width height:height mode:2];
}
- (int)width
{
    return Width;
}
- (int)height
{
    return Height;
}
- (int)heightWithWidth:(int)width
{
    if(self.Width>0 && width>0)
    {
        return self.Height * width/self.Width;
    }
    return self.Height;
}

#pragma  marker dealloc
- (void) dealloc
{
    PP_RELEASE(Title);
    PP_RELEASE(Src);
    PP_RELEASE(Icon);
    PP_RELEASE(Wh);
    PP_SUPERDEALLOC;
}
@end

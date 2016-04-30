//
//  CommonUtil.m
//  HotelCloud
//  常用的基本函数集合
//
//  Created by Lawrence Chen on 12-10-31.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import "CommonUtil.h"
#import <CommonCrypto/CommonDigest.h>

#import "RegexKitLite.h"
#import "NSString+SBJSON.h"
#import "JSON.h"
#import "DeviceConfig.h"

//#import "HCHotel.h"
//#import "ZipFile.h"
//#import <HCMinizip/ZipFile.h>

#define FileHashDefaultChunkSizeForReadingData 1024*8 // 8K

@implementation CommonUtil
+ (unsigned int)intFromHexString:(NSString *) hexStr
{
    unsigned int hexInt = 0;
    
    // Create scanner
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    
    // Tell scanner to skip the # character
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"#"]];
    
    // Scan hex value
    [scanner scanHexInt:&hexInt];
    
    return hexInt;
}
+(NSString*)readContentFromFile:(NSString *)fileName type:(NSString*)type
{
    NSError *error;
    NSString *textFileContents = [NSString
                                  stringWithContentsOfFile:[[NSBundle mainBundle]
                                                            pathForResource:fileName
                                                            ofType:type]
                                  encoding:NSUTF8StringEncoding
                                  error: & error];
    
    // If there are no results, something went wrong
    
    if (textFileContents == nil) {
        
        // an error occurred
        
        NSLog(@"Error reading text file. %@", [error localizedFailureReason]);
        
    }
    return textFileContents;
    //    NSArray *lines = [textFileContents componentsSeparatedByString:@" "];
    //
    //    NSLog(@"Number of lines in the file:%d”, [lines count] );
}
//+(int)getHotelIDFromBarCode:(NSString *)barCode
//{
//    if(!barCode) return 0;
//    NSString * matchCode = [barCode stringByMatching:@"\\d+$"];
//    @try {
//        return [ matchCode intValue];
//    }
//    @catch (NSException *exception) {
//        NSLog(@"get hotel from barcode error:\n%@",[exception description]);
//        return 0;
//    }
//    @finally {
//
//    }
//
//    //    NSRange range = [barCode rangeOfString:@"#"];
//    //    if(range.length>0)
//    //    {
//    //        @try {
//    //            return [[barCode substringFromIndex:range.location+1]intValue];
//    //        }
//    //        @catch (NSException *exception) {
//    //            NSLog(@"get hotel from barcode error:\n%@",[exception description]);
//    //            return 0;
//    //        }
//    //        @finally {
//    //
//    //        }
//    //    }
//    //    else
//    //        return 0;
//}
//国内使用百度地图
+(NSString*)getMapUrl:(double)lat lng:(double)lng width:(CGFloat)width height:(CGFloat)height
{
    //http://api.map.baidu.com/staticimage?parameters
    //http://api.map.baidu.com/staticimage?center=百度大厦&markers=百度大厦
    return [NSString stringWithFormat:@"http://api.map.baidu.com/staticimage?center=%0.6f,%0.6f&markers=%0.6f,%0.6f&width=%0.0f&height=%0.0f&zoom=%d",
            lng,lat,lng,lat,width,height,16];
    
}

+ (UIColor *) colorFromHexRGB:(NSString *) inColorString
{
    UIColor *result = nil;
    unsigned int colorCode = 0;
    unsigned char redByte, greenByte, blueByte;
    
    if (nil != inColorString)
    {
        NSScanner *scanner = [NSScanner scannerWithString:inColorString];
        (void) [scanner scanHexInt:&colorCode]; // ignore error
    }
    redByte = (unsigned char) (colorCode >> 16);
    greenByte = (unsigned char) (colorCode >> 8);
    blueByte = (unsigned char) (colorCode); // masks off high bits
    result = [UIColor
              colorWithRed: (float)redByte / 0xff
              green: (float)greenByte/ 0xff
              blue: (float)blueByte / 0xff
              alpha:1.0];
    return result;
}
+(BOOL) isLatLngValid:(double)lat lng:(double)lng
{
    if(lat==0 && lng==0) return NO; //原点不会有我们喜欢的东东
    if(lat >90 || lat < -90 ||lng >180 || lng < -180) return NO;
    return YES;
}
+(CGSize)getTextHeight:(NSString *)text font:(UIFont*)font width:(CGFloat)width
{
    if(!text) return CGSizeZero;
    //设置段落模式
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineBreakMode = NSLineBreakByCharWrapping;
    NSDictionary *attribute = @{NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraph};
    
    CGSize size = [text boundingRectWithSize:CGSizeMake(width, 1000)
                                     options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                  attributes:attribute context:nil].size;
    
    //    CGSize size=[text sizeWithFont:font constrainedToSize:CGSizeMake(width, 1000)];
    //return size.height;
    PP_RELEASE(paragraph);
    return size;
}
//+ (NSString *)starLevelWithNum:(NSInteger)starNum
//{
//    switch (starNum) {
//        case 0:
//            return START_LEVEL_FOLLOWTWO;
//        case 1:
//            return START_LEVEL_BEFORE_THREE;
//        case 2:
//            return START_LEVEL_THREE;
//        case 3:
//            return START_LEVEL_BEFORE_FOUR;
//        case 4:
//            return START_LEVEL_FOUR;
//        case 5:
//            return START_LEVEL_BEFORE_FIVE;
//        case 6:
//            return START_LEVEL_FIVE;
//        case 7:
//            return START_LEVEL_AFTER_FIVE;
//        default:
//            return START_LEVEL_NONE;
//    }
//}
+ (NSString *)stringFromDistance:(double)distance
{
    if (distance < 0) {
        distance = 0;
    }
    if (distance > 1000) {
        return [NSString stringWithFormat:@"%.2f公里", distance / 1000];
    }
    return [NSString stringWithFormat:@"%d米", (int)distance];
}
+ (NSString *)lbsDistanceToString:(double)lon
                          fromLat:(double)lat
                            toLon:(double)lon1
                            toLat:(double)lat1
{
    int distance = [self lbsDistance:lon fromLat:lat toLon:lon1 toLat:lat1];
    if (distance < 0) {
        distance = 0;
    }
    if(distance>10000)
    {
        return [NSString stringWithFormat:@"%.0f公里", ((double)distance) / 1000];
    }
    else if (distance > 1000) {
        return [NSString stringWithFormat:@"%.1f公里", ((double)distance) / 1000];
    }
    return [NSString stringWithFormat:@"%d米", distance];
}

+ (int)lbsDistance:(double)lon
           fromLat:(double)lat
             toLon:(double)lon1
             toLat:(double)lat1
{
    double con = 12733129.728;// 1.609344(1mile=?km) * 1000(m) * 3956
    return (int) (con * asin(sqrt(pow(
                                      sin((lat - ABS(lat1)) * M_PI / 180 / 2), 2)
                                  + cos(lat * M_PI / 180)
                                  * cos(ABS(lat1) * M_PI / 180)
                                  * pow(sin((lon - lon1) * M_PI / 180 / 2), 2))));
}
+(double)getDeltaByDistance:(double)lat fromLng:(double)lng distance:(int)distance
{
    double con = 12733129.728;// 1.609344(1mile=?km) * 1000(m) * 3956
    double deltaLat = 0.0;
    deltaLat =  asinh(asinh(distance /con)) *180/M_PI;
    return deltaLat;
}
+(NSString *)distanceString:(int)distance
{
    NSMutableString * ret = [[NSMutableString alloc]init];
    if(distance>10000)
    {
        [ret appendFormat:@"%0.0fKM",distance/1000.0f];
    }
    else if(distance>1000)
    {
        [ret appendFormat:@"%0.1fKM",distance/1000.0f];
    }
    else
    {
        [ret appendFormat:@"%dM",distance];
    }
    return PP_AUTORELEASE(ret);
}
#pragma mark - sort
//+ (void)hotelSortByDistance:(NSMutableArray *)array lat:(double)lat lng:(double)lng
//{
//    if(array==nil || [array count]==0) return;
//    NSMutableArray * arrayTemp = [[NSMutableArray alloc]initWithArray:array];
//    [array removeAllObjects];
//    for(HCHotel * hotel in arrayTemp)
//    {
//        hotel.Distance = [CommonUtil lbsDistance:hotel.Lng fromLat:hotel.Lat toLon:lng toLat:lat];
//        int row = 0;
//        for (HCHotel * hotelTemp in array) {
//            if(hotel.Distance <hotelTemp.Distance)
//            {
//                break;
//            }
//            row ++;
//        }
//        if(row >= [array count])
//            [array addObject:hotel];
//        else
//            [array insertObject:hotel atIndex:row];
//    }
//    [arrayTemp release];
//    //    for (HCHotel * hotel in array) {
//    //        NSLog(@"%@ dist:%d",hotel.Name,hotel.Distance);
//    //    }
//}
//+(NSString *)getBillStatus:(int)theStatus
//{
//    if(theStatus < HCOrderStateChecked)
//        return @"未处理";
//    else if(theStatus < HCOrderStateReceived)
//        return @"处理中";
//    else if(theStatus >=HCOrderStateReceived && theStatus <= HCOrderStateCompleted)
//        return @"已完成 未评论";
//    else if(theStatus == HCOrderStateCancel)
//        return @"已取消";
//    else if(theStatus == HCOrderStateClosed)
//        return @"已关闭";
//    else if(theStatus == HCOrderStateCommented)
//        return @"已评论";
//    else
//        return @"";
//}

//得到中英文混合字符串长度 方法1
+ (int)convertToInt:(NSString*)strtemp
{
    int strlength = 0;
    char* p = (char*)[strtemp cStringUsingEncoding:NSUnicodeStringEncoding];
    for (int i=0 ; i<[strtemp lengthOfBytesUsingEncoding:NSUnicodeStringEncoding] ;i++) {
        if (*p) {
            p++;
            strlength++;
        }
        else {
            p++;
        }
        
    }
    return strlength;
}
//下面的函数实现了类似ASCII编码的字节长
- (int)convertToInt:(NSString*)strtemp
{
    int strlength = 0;
    char* p = (char*)[strtemp cStringUsingEncoding:NSUnicodeStringEncoding];
    for (int i=0 ; i<[strtemp lengthOfBytesUsingEncoding:NSUnicodeStringEncoding] ;i++) {
        if (*p) {
            p++;
            strlength++;
        }
        else {
            p++;
        }
        
    }
    return strlength;
    
}
//得到中英文混合字符串长度 方法2
+ (int)getToInt:(NSString*)strtemp
{
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSData* da = [strtemp dataUsingEncoding:enc];
    return (int)[da length];
}

#pragma mark - valid string
+ (BOOL)isTelphoneNumber:(NSString *)tel
{
    //    匹配格式：
    //    11位手机号码
    //    3-4位区号，7-8位直播号码，1－4位分机号
    //    如：12345678901、1234-12345678-1234
    NSString * telRegex = @"((\\d{11})|((\\d{7,8})|(\\d{4}|\\d{3})-(\\d{7,8})|(\\d{4}|\\d{3})-(\\d{7,8})-(\\d{4}|\\d{3}|\\d{2}|\\d{1})|(\\d{7,8})-(\\d{4}|\\d{3}|\\d{2}|\\d{1}))$)|(\\d{3}-\\d{3}-\\d{4})|(\\d{10})";
    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", telRegex];
    if([regextestmobile evaluateWithObject:tel])
        return YES;
    else
        return NO;
}
+ (BOOL)isMobileNumber:(NSString *)mobileNum
{
    @autoreleasepool {
        /**
         手机号码前三位列表：
         13(老)号段：130、131、132、133、134、135、136、137、138、139
         15(新)号段：150、151、152、153、154、155、156、157、158、159
         18(3G)号段：180、181、182、183、184、185、186、187、188、189
         13(老)号段
         130：中国联通，GSM
         131：中国联通，GSM
         132：中国联通，GSM
         133：中国联通，后转给中国电信，CDMA
         134：中国移动，GSM
         135：中国移动，GSM
         136：中国移动，GSM
         137：中国移动，GSM
         138：中国移动，GSM
         139：中国移动，GSM
         15(新)号段
         150：中国移动，GSM
         151：中国移动，GSM
         152：中国联通，网友反映实际是中国移动的
         153：中国联通，后转给中国电信，CDMA
         154：154号段暂时没有分配，估计是因为154的谐音是“要吾死”，这样的手机号码谁敢要啊？
         155：中国联通，GSM
         156：中国联通，GSM
         157：中国移动，GSM
         158：中国移动，GSM
         159：中国移动，GSM
         18(3G)号段
         180：中国电信，3G
         181：中国电信，3G
         182：中国移动，3G
         183：中国移动，3G
         184：中国移动，3G
         185：中国联通，3G
         186：中国联通，3G
         187：中国移动，3G
         188：中国移动，3G，TD-CDMA
         189：中国电信，3G，CDMA，天翼189，2008年底开始对外放号
         **/
        NSString * MOBILE = @"^1(3[0-9]|5[0-35-9]|8[0-9])\\d{8}$";
        /**
         10         * 中国移动：China Mobile
         11         * 134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188
         12         */
        NSString * CM = @"^1(34[0-8]|(3[5-9]|5[017-9]|7[07]|8[23478])\\d)\\d{7}$";
        /**
         15         * 中国联通：China Unicom
         16         * 130,131,132,152,155,156,185,186
         17         */
        NSString * CU = @"^1(3[0-2]|5[256]|8[56])\\d{8}$";
        /**
         20         * 中国电信：China Telecom
         21         * 133,1349,153,180,189
         22         */
        NSString * CT = @"^1((33|53|8[019])[0-9]|349)\\d{7}$";
        /**
         25         * 大陆地区固话及小灵通
         26         * 区号：010,020,021,022,023,024,025,027,028,029
         27         * 号码：七位或八位
         28         */
        // NSString * PHS = @"^0(10|2[0-5789]|\\d{3})\\d{7,8}$";
        
        NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
        NSPredicate *regextestcm = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CM];
        NSPredicate *regextestcu = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CU];
        NSPredicate *regextestct = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CT];
        
        if (([regextestmobile evaluateWithObject:mobileNum] == YES)
            || ([regextestcm evaluateWithObject:mobileNum] == YES)
            || ([regextestct evaluateWithObject:mobileNum] == YES)
            || ([regextestcu evaluateWithObject:mobileNum] == YES))
        {
            return YES;
        }
        else
        {
            return NO;
        }
    }
}
//判断邮箱是否合法的代码
+(BOOL)validateEmail:(NSString*)email
{
    if((0 != [email rangeOfString:@"@"].length) &&
       (0 != [email rangeOfString:@"."].length))
    {
        
        NSCharacterSet* tmpInvalidCharSet = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
        NSMutableCharacterSet* tmpInvalidMutableCharSet = PP_AUTORELEASE([tmpInvalidCharSet mutableCopy]);
        [tmpInvalidMutableCharSet removeCharactersInString:@"_-"];
        
        //使用compare option 来设定比较规则，如
        //NSCaseInsensitiveSearch是不区分大小写
        //NSLiteralSearch 进行完全比较,区分大小写
        //NSNumericSearch 只比较定符串的个数，而不比较字符串的字面值
        NSRange range1 = [email rangeOfString:@"@"
                                      options:NSCaseInsensitiveSearch];
        
        //取得用户名部分
        NSString* userNameString = [email substringToIndex:range1.location];
        NSArray* userNameArray   = [userNameString componentsSeparatedByString:@"."];
        
        for(NSString* string in userNameArray)
        {
            NSRange rangeOfInavlidChars = [string rangeOfCharacterFromSet: tmpInvalidMutableCharSet];
            if(rangeOfInavlidChars.length != 0 || [string isEqualToString:@""])
                return NO;
        }
        
        NSString *domainString = [email substringFromIndex:range1.location+1];
        NSArray *domainArray   = [domainString componentsSeparatedByString:@"."];
        
        for(NSString *string in domainArray)
        {
            NSRange rangeOfInavlidChars=[string rangeOfCharacterFromSet:tmpInvalidMutableCharSet];
            if(rangeOfInavlidChars.length !=0 || [string isEqualToString:@""])
                return NO;
        }
        
        return YES;
    }
    else // no ''@'' or ''.'' present
        return NO;
}

+ (NSString *)getTelephoneFromString:(NSString*)phoneString
{
    NSString *regEx = @"((\\d{3,4})|\\d{3,4}-)?\\d{7,8}|(\\d{3}-\\d{3}-\\d{4})|(\\d{10})";
    NSError * error = nil;
    if(!phoneString||phoneString.length==0) return nil;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regEx options:NSRegularExpressionCaseInsensitive error:&error];
    if(error)
    {
        NSLog(@"regex error:%@",[error description]);
    }
    NSString *match = nil;
    NSArray* matches = [regex matchesInString:phoneString options:0 range:NSMakeRange(0, phoneString.length)];
    if(matches.count>0)
    {
        NSRange matchRange = [[matches objectAtIndex:0] range];
        match = [phoneString substringWithRange:matchRange];
    }
    else
        match = nil;
    
    //    NSString *match = [phoneString stringByMatching:regEx];
    if(match && match.length>0)
    {
        return match;
    }
    return nil;
}
+ (NSArray *)getTelephoneArrayFromString:(NSString*)phoneString
{
    NSString *regEx = @"((\\d{3,4})|\\d{3,4}-)?\\d{7,8}|(\\d{3}-\\d{3}-\\d{4})|(\\d{10})";
    NSError * error = nil;
    if(!phoneString||phoneString.length==0) return nil;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regEx options:NSRegularExpressionCaseInsensitive error:&error];
    if(error)
    {
        NSLog(@"regex error:%@",[error description]);
    }
    NSString *match = nil;
    NSArray* matches = [regex matchesInString:phoneString options:0 range:NSMakeRange(0, phoneString.length)];
    NSMutableArray * result = [[NSMutableArray alloc]initWithCapacity:matches.count];
    if(matches.count>0)
    {
        for (int i = 0; i <matches.count; i ++) {
            
            NSRange matchRange = [[matches objectAtIndex:i] range];
            match = [phoneString substringWithRange:matchRange];
            [result addObject:match];
        }
    }
    else
    {
        match = nil;
        PP_RELEASE(result);
    }
    if(result)
        return PP_AUTORELEASE(result);
    else
        return nil;
}

#pragma mark - images
//////传入的参数：1、生成图片的大小 2、压缩比 3、存放图片的路径
////- (UIImage *)createThumbImage:(UIImage *)image size:(CGSize )thumbSize cutRect:(CGRect)cutRect
////{
////
////    CGSize imageSize = image.size;
////    CGFloat width = imageSize.width;
////    CGFloat height = imageSize.height;
////
////    CGFloat scaleFactor = 0.0;
////    CGPoint thumbPoint = CGPointMake(0.0,0.0);
////    CGFloat widthFactor = thumbSize.width / width;
////    CGFloat heightFactor = thumbSize.height / height;
////
////    if (widthFactor > heightFactor)  {
////        scaleFactor = widthFactor;
////    }
////    else {
////        scaleFactor = heightFactor;
////    }
////
////    CGFloat scaledWidth  = width * scaleFactor;
////    CGFloat scaledHeight = height * scaleFactor;
////    if (widthFactor > heightFactor)
////    {
////        thumbPoint.y = (thumbSize.height - scaledHeight) * 0.5;
////    }
////
////    else if (widthFactor < heightFactor)
////    {
////        thumbPoint.x = (thumbSize.width - scaledWidth) * 0.5;
////    }
////
////    UIGraphicsBeginImageContext(thumbSize);
////
////    CGRect thumbRect = CGRectZero;
////    thumbRect.origin = thumbPoint;
////    thumbRect.size.width  = scaledWidth;
////    thumbRect.size.height = scaledHeight;
////    [image drawInRect:thumbRect];
////
////    UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
////    UIGraphicsEndImageContext();
////    return thumbImage;
////}
//
//+ (UIImage *)scaleImage:(UIImage*)image posx:(int)x posy:(int)y width:(int)width height:(int)height
//{
//    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width , height),NO,image.scale);
//    
//    //    [image drawInRect:CGRectMake((0-x),
//    //                                 (0-y),
//    //                                 (MIN(image.size.width -x,width)),
//    //                                 (MIN(image.size.height - y,height)))];
//    [image drawAsPatternInRect:CGRectMake(0-x, 0-y, width+x, height+y)];
//    UIImage *resultImg = UIGraphicsGetImageFromCurrentImageContext();
//    
//    UIGraphicsEndImageContext();
//    
//    return resultImg;
//}
//
////从底部往上平铺
//+ (UIImage *)scaleImageA:(UIImage*)image width:(int)width height:(int)height
//{
//    CGSize size = image.size;
//    CGFloat x= 0;
//    CGFloat y = height;
//    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width , height),NO,image.scale);
//    while (y>0) {
//        y -= size.height;
//    }
//    for (CGFloat y1 = y; y1 + size.height<=height; y1 +=size.height) {
//        [image drawAsPatternInRect:CGRectMake(x, y1, width+x, size.height)];
//    }
//    
//    UIImage *resultImg = UIGraphicsGetImageFromCurrentImageContext();
//    
//    UIGraphicsEndImageContext();
//    
//    return resultImg;
//}
//
//+ (UIImage *)addTwoImageToOne:(UIImage *)oneImg twoImage:(UIImage *)twoImg xposition:(NSInteger)xpos yposition:(NSInteger)ypos
//{
//    //    UIGraphicsBeginImageContext(CGSizeMake(oneImg.scale * oneImg.size.width, oneImg.scale * oneImg.size.height));
//    UIGraphicsBeginImageContextWithOptions(CGSizeMake(oneImg.scale * oneImg.size.width, oneImg.scale * oneImg.size.height), NO, oneImg.scale);
//    [oneImg drawInRect:CGRectMake(0, 0, oneImg.size.width * oneImg.scale, oneImg.size.height* oneImg.scale)];
//    //*scale这个是临时处理，因为oneImg是从摄像头来的，是实际的大小，twoImg不是
//    [twoImg drawInRect:CGRectMake(xpos, ypos, twoImg.size.width*twoImg.scale, twoImg.size.height*twoImg.scale)];
//    //    [twoImg drawInRect:CGRectMake(xpos, ypos, twoImg.size.width, twoImg.size.height)];
//    
//    UIImage *resultImg = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    
//    return resultImg;
//}
//+ (UIImage *)crapImageInTriangle:(UIImage *)image len:(CGFloat)len startx:(CGFloat)x starty:(CGFloat)y
//{
//    
//    //    CGFloat scale = image.scale;
//    
//    NSMutableArray *points = [[NSMutableArray alloc]initWithCapacity:3];
//    CGPoint point1 = CGPointMake(x, y );
//    CGPoint point2 = CGPointMake(x +len, y );
//    CGPoint point3 = CGPointMake(x +len/2.0f, y +len/1.73f);
//    [points addObject:NSStringFromCGPoint(point1)];
//    [points addObject:NSStringFromCGPoint(point2)];
//    [points addObject:NSStringFromCGPoint(point3)];
//    
//    CGRect rect = CGRectMake(0, 0, x + len, y + len/1.73f);
//    //    rect.size = image.size;
//    //    if(rect.size.width<50) rect.size.width = 50;
//    //    if(rect.size.height<50) rect.size.height = 50;
//    UIGraphicsBeginImageContextWithOptions(rect.size, YES, image.scale);
//    
//    {
//        [[UIColor blackColor] setFill];
//        UIRectFill(rect);
//        [[UIColor whiteColor] setFill];
//        
//        UIBezierPath *aPath = [UIBezierPath bezierPath];
//        
//        // Set the starting point of the shape.
//        CGPoint p1 = CGPointFromString([points objectAtIndex:0]);
//        [aPath moveToPoint:CGPointMake(p1.x, p1.y)];
//        
//        for (uint i=1; i<points.count; i++)
//        {
//            CGPoint p =  CGPointFromString([points objectAtIndex:i]);
//            [aPath addLineToPoint:CGPointMake(p.x, p.y)];
//        }
//        [aPath closePath];
//        [aPath fill];
//    }
//    
//    UIImage *mask = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    
//    
//    
//    UIGraphicsBeginImageContextWithOptions(rect.size, NO, image.scale);
//    
//    {
//        CGContextClipToMask(UIGraphicsGetCurrentContext(), rect, mask.CGImage);
//        [image drawAsPatternInRect:rect];
//        //        [image drawAtPoint:CGPointZero];
//    }
//    
//    UIImage *maskedImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    //    CGSize size1 = maskedImage.size;
//    [points release];
//    return maskedImage;
//}
//+ (UIImage *)imageForHotelBarcodeWithLogo:(int)hotelID width:(CGFloat)width borderWidth:(CGFloat)bw
//{
//    //#ifdef IS_MANAGERCONSOLE
//    return nil;
//    //#else
//    //    //生成二维码
//    //    //        NSString * bar = [NSString stringWithFormat:BARCODE,APPID,hotel_.HotelID];
//    //    NSString * bar = [NSString stringWithFormat:BARCODE,hotelID];
//    //    UIImage * barImage = nil;
//    //    @autoreleasepool {
//    //        barImage = PP_RETAIN([QRCodeGenerator qrImageForString:bar imageSize:2 * width]);
//    //        SystemConfiguration * config = [SystemConfiguration sharedSystemConfiguration];
//    //        UIImage * logoImage = nil;
//    //        if([config hotelID]==hotelID)
//    //        {
//    //            logoImage = [config themeImageWithName:@"pagelogo"];
//    //            if(!logoImage || hotelID==0)
//    //            {
//    //                logoImage = [UIImage imageNamed:@"icon.png"];
//    //            }
//    //        }
//    //        else
//    //        {
//    //            logoImage = [UIImage imageNamed:@"icon.png"];
//    //        }
//    //        if(logoImage)
//    //        {
//    //            CGSize size = CGSizeMake(50, 50);
//    //            if(logoImage.size.width>logoImage.size.height)
//    //            {
//    //                size.height = logoImage.size.height/logoImage.size.width * size.width;
//    //            }
//    //            else if(logoImage.size.width<logoImage.size.height)
//    //            {
//    //                size.width = logoImage.size.width/logoImage.size.height * size.height;
//    //            }
//    //            UIImage * backImage = [config themeImageWithName:@"pagebackground"];
//    //            if(backImage)
//    //            {
//    //                DeviceConfig * config = [DeviceConfig Instance];
//    //                CGFloat scaleM = logoImage.scale / config.Scale;
//    //                backImage = [backImage imageByScalingToSize:CGSizeMake(logoImage.size.width *scaleM, logoImage.size.height *scaleM)];
//    //                logoImage = [CommonUtil addTwoImageToOne:backImage twoImage:logoImage xposition:0 yposition:0];
//    //            }
//    //
//    //            UIImage * complicateLogo = [logoImage imageByScalingProportionallyToSize:size backcolor:nil];
//    //            complicateLogo = [CommonUtil roundCorners:complicateLogo regionWidth:2];
//    //            complicateLogo = [complicateLogo roundCorners:5];
//    //
//    //            //            PP_RELEASE(barImage);
//    //            UIImage * barImageN = [CommonUtil addTwoImageToOne:barImage
//    //                                                      twoImage:complicateLogo
//    //                                                     xposition:(width-size.width) yposition:(width-size.height)];
//    //            PP_RELEASE(barImage);
//    //            barImage = PP_RETAIN(barImageN);
//    //        }
//    //    }
//    //    return PP_AUTORELEASE(barImage);
//    //#endif
//}
//+ (UIImage *) roundCorners:(UIImage *)image regionWidth:(CGFloat)regionWidth
//{
//    CGFloat targetWidth = image.size.width +regionWidth  *2;
//    CGFloat targetHeight = image.size.height +regionWidth *2;
//    
//    
//    CGRect thumbnailRect = CGRectMake(regionWidth, regionWidth,image.size.width ,image.size.height);
//    // this is actually the interesting part:
//    
//    UIGraphicsBeginImageContextWithOptions(CGSizeMake(targetWidth,targetHeight), NO, image.scale);
//    [[UIColor whiteColor]set];
//    UIRectFill(CGRectMake(0, 0, targetWidth, targetHeight));
//    UIImage *newImage = [image roundCorners:5];
//    [newImage drawInRect:thumbnailRect];
//    
//    UIImage * resultImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return resultImage;
//}
//
//+ (void)setImageToBlur: (UIImageView *) imageview
//                 image: (UIImage *)image
//            blurRadius: (CGFloat)blurRadius
//
//{
//    CIContext *context   = [CIContext contextWithOptions:nil];
//    CIImage *sourceImage = [CIImage imageWithCGImage:image.CGImage];
//    
//    // Apply clamp filter:
//    // this is needed because the CIGaussianBlur when applied makes
//    // a trasparent border around the image
//    
//    NSString *clampFilterName = @"CIAffineClamp";
//    CIFilter *clamp = [CIFilter filterWithName:clampFilterName];
//    
//    if (!clamp) {
//        return;
//    }
//    
//    [clamp setValue:sourceImage
//             forKey:kCIInputImageKey];
//    
//    CIImage *clampResult = [clamp valueForKey:kCIOutputImageKey];
//    
//    // Apply Gaussian Blur filter
//    
//    NSString *gaussianBlurFilterName = @"CIGaussianBlur";
//    CIFilter *gaussianBlur           = [CIFilter filterWithName:gaussianBlurFilterName];
//    
//    if (!gaussianBlur) {
//        return;
//    }
//    
//    [gaussianBlur setValue:clampResult
//                    forKey:kCIInputImageKey];
//    [gaussianBlur setValue:[NSNumber numberWithFloat:blurRadius]
//                    forKey:@"inputRadius"];
//    
//    CIImage *gaussianBlurResult = [gaussianBlur valueForKey:kCIOutputImageKey];
//    
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        
//        CGImageRef cgImage = [context createCGImage:gaussianBlurResult
//                                           fromRect:[sourceImage extent]];
//        
//        UIImage *blurredImage = [UIImage imageWithCGImage:cgImage scale:image.scale orientation:UIImageOrientationDown];
//        CGImageRelease(cgImage);
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            imageview.image = blurredImage;
//        });
//    });
//    
//}
//+(void) rotatoImage:(UIImageView *) view direction:(NSInteger) dir
//{
//    if(view == nil)
//        return;
//    
//    float angle = M_PI / 1.33;
//    
//    if(dir == 0){
//        angle = 0 - angle;
//    }
//    
//    CGAffineTransform  transform;
//    //设置旋转度数
//    transform = CGAffineTransformRotate(view.transform,angle);
//    //动画开始
//    [UIView beginAnimations:@"rotate" context:nil ];
//    //动画时常
//    [UIView setAnimationDuration:0.3];
//    //添加代理
//    [UIView setAnimationDelegate:self];
//    //获取transform的值
//    [view setTransform:transform];
//    //关闭动画
//    [UIView commitAnimations];
//}

#pragma mark - string format
//转十六进制字符串
+ (NSString *)toHEXstring:(long)num
{
    return [NSString stringWithFormat:@"%lX",num];
}
+ (NSString *)stripAllTags:(NSString *)html
{
    if(!html||html.length<5) return html;
    
    @autoreleasepool {
        NSString *regexString   = @"<[^>]*>|\\r|\\n" ;
        //
        //    [regex replaceMatchesInString:mutableContent options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [testContent length]) withTemplate:@"*"];
        
        NSString * result  =[html stringByReplacingOccurrencesOfRegex:regexString withString:@""];
        NSString * result2 =[result stringByReplacingOccurrencesOfRegex:@"&nbsp;" withString:@" "];
        NSString * result3 =[[result2 stringByReplacingOccurrencesOfRegex:@"&rdquo;|&ldquo;" withString:@"\""] copy];
        return PP_AUTORELEASE(result3);//[result3 autorelease];
    }
}
//+ (NSString *)priceString:(CGFloat)minPrice maxPrice:(CGFloat )maxPrice unit:(NSString *)unit
//{
//    if(minPrice>maxPrice) minPrice = maxPrice;
//    if(minPrice==maxPrice)
//    {
//        NSString * format = unit && unit.length>0?FORMAT_PRICE2:FORMAT_PRICE21;
//        if(minPrice>0)
//            return [NSString stringWithFormat:format,minPrice,unit&&unit.length>0?unit:FORMAT_UNIT];
//        else if(minPrice==0)
//            return MSG_FREE;
//        else if(minPrice ==-3)
//            return @"";
//        else if(minPrice==-4)
//            return ROOMSTATE_NOPRICE;
//        else
//            return MSG_ALTERFEE;
//    }
//    else if(minPrice>0)
//    {
//        NSString * format = unit && unit.length>0?FORMAT_PRICE9:FORMAT_PRICE91;
//        return [NSString stringWithFormat:format,minPrice,maxPrice,unit&&unit.length>0?unit:FORMAT_UNIT];
//    }
//    else if(maxPrice<0 && maxPrice >-3)
//    {
//        return MSG_ALTERFEE;
//    }
//    else if(minPrice==-4)
//        return ROOMSTATE_NOPRICE;
//    else
//        return @"";
//}


+(NSString *)stringWithFixedLength:(NSInteger)number withLength:(int)length
{
    NSString * str = [NSString stringWithFormat:@"00000000000%d",(int)number];
    if(str.length>length)
        return  [str substringFromIndex:str.length - length];
    else
        return str;
}
//字符串左补零
+(NSString *)leftFillZero:(NSString *)orgString withLength:(int)length
{
    NSString * string =nil;
    NSString * string1 = orgString;
    if(length<0) length = 8;
    while ([string1 length]<length)
    {
        string =[NSString stringWithFormat:@"0%@",string1];
        //[string1 release];
        string1 = string;
    }
    //NSLog(@"补零成功%@",string1);
    return string1;
}

#pragma mark - md5 and sha1
+ (NSString *)sha1:(NSString *)str {
    const char *cstr = [str cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:str.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}
+ (NSString *)md5Hash:(NSString *)str {
    if(!str) return nil;
    
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
    NSString *md5Result = [NSString stringWithFormat:
                           @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                           result[0], result[1], result[2], result[3],
                           result[4], result[5], result[6], result[7],
                           result[8], result[9], result[10], result[11],
                           result[12], result[13], result[14], result[15]
                           ];
    return md5Result;
}
+ (BOOL)hasChinese:(NSString *)str
{
    if(!str || str.length==0) return NO;
    BOOL hasChinese = NO;
    for(int i=0; i< [str length];i++){
        int a = [str characterAtIndex:i];
        if( a > 0x4e00 && a < 0x9fff)
        {
            hasChinese = YES;
            break;
        }
    }
    return hasChinese;
}
//得到中英文混合字符串长度 方法1
+ (int)strlen:(NSString*)strtemp
{
    int strlength = 0;
    char* p = (char*)[strtemp cStringUsingEncoding:NSUnicodeStringEncoding];
    for (int i=0 ; i<[strtemp lengthOfBytesUsingEncoding:NSUnicodeStringEncoding] ;i++) {
        if (*p) {
            p++;
            strlength++;
        }
        else {
            p++;
        }
        
    }
    return strlength;
}
//得到中英文混合字符串长度 方法2
+ (int)strLen2:(NSString*)strtemp
{
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSData* da = [strtemp dataUsingEncoding:enc];
    return (int)[da length];
}
//+ (BOOL)unZipFileFrom:(NSString *)source to:(NSString *)destination
//{
//    if (nil == source || nil == destination || [source isEqualToString:@""] || [destination isEqualToString:@""]) {
//        return NO;
//    }
//    
//    BOOL returnState = NO;
//    
//    ZipFile *zipFile = [[ZipFile alloc] initWithResourcePath:source];
//    returnState = [zipFile UnzipFileTo:destination];
//    PP_RELEASE(zipFile);
////    [zipFile release];
//    return returnState;
//}

+ (UILabel *)labelWithText:(NSString *)aText
                      font:(UIFont *)aFont
                 textColor:(UIColor *)aColor
                     width:(NSInteger)aWidth
                    height:(NSInteger)aHeight
{
    if (!aText || [aText isEqualToString:@""]) {
        return nil;
    }
    UILabel *label  = [[UILabel alloc] init];
    label.font      = aFont;
    label.textColor = aColor;
    label.text      = aText;
    label.numberOfLines     = 0;
    label.lineBreakMode     = NSLineBreakByWordWrapping;
    label.backgroundColor   = [UIColor clearColor];
    
    CGSize size = [self sizeOfString:aText withFont:aFont width:aWidth height:aHeight];
    label.frame = CGRectMake(0, 0, size.width, size.height);
    
    return PP_AUTORELEASE(label);
}

+ (CGSize)sizeOfString:(NSString *)aStr
              withFont:(UIFont *)aFont
                 width:(NSInteger)aWidth
                height:(NSInteger)aHeight
{
    CGSize  size    = CGSizeZero;
    if(!aStr ||aStr.length==0) return size;
    NSInteger width = aWidth > 0 ? aWidth : NSIntegerMax;
    NSInteger height= aHeight > 0 ? aHeight : NSIntegerMax;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_7_0
    
    NSAttributedString *attributText    = [[NSAttributedString alloc] initWithString:aStr
                                                                          attributes:@{NSFontAttributeName:aFont}];
    size    = [attributText boundingRectWithSize:CGSizeMake(width, height)
                                         options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                         context:nil];
    [attributeText release];
    
#else
    
    //设置段落模式
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineBreakMode = NSLineBreakByCharWrapping;
    NSDictionary *attribute = @{NSFontAttributeName: aFont, NSParagraphStyleAttributeName: paragraph};
    
    size = [aStr boundingRectWithSize:CGSizeMake(width, height)
                              options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                           attributes:attribute context:nil].size;
    
    PP_RELEASE(paragraph);
    //    size    = [aStr sizeWithFont:aFont
    //               constrainedToSize:CGSizeMake(width, height)
    //                   lineBreakMode:NSLineBreakByWordWrapping];
    
#endif
    
    return size;
}

+ (NSString *)get_uuid
{
    CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
    CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);
    CFRelease(uuid_ref);
    NSString *uuid = [NSString stringWithString:(__bridge NSString*)uuid_string_ref];
    CFRelease(uuid_string_ref);
    return uuid;
}
#pragma mark - files
//
//+ (void)createFileDirectory:(NSString *)dirFullPath
//{
//    
//    // 判断存放音频、视频的文件夹是否存在，不存在则创建对应文件夹
//    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    
//    BOOL isDir = FALSE;
//    
//    BOOL isDirExist = [fileManager fileExistsAtPath:dirFullPath
//                                        isDirectory:&isDir];
//    
//    if(!(isDirExist && isDir))
//    {
//        NSError * error = nil;
//        if(isDirExist)
//        {
//            [fileManager removeItemAtPath:dirFullPath error:&error];
//            if(error)
//            {
//                NSLog(@" remove path:%@ failure:%@",dirFullPath,[error description]);
//            }
//        }
//        BOOL bCreateDir = [fileManager createDirectoryAtPath:dirFullPath
//                                 withIntermediateDirectories:YES
//                                                  attributes:nil
//                                                       error:&error];
//        
//        if(!bCreateDir){
//            
//            NSLog(@"Create dir:%@ Failed.%@",dirFullPath,[error description]);
//            
//        }
//        
//    }
//}
//+ (BOOL)createFileDirectories:(NSString * )path
//{
//    if(!path || path.length==0) return NO;
//    NSFileManager * fm = [NSFileManager defaultManager];
//    NSString *  parentPath = [path stringByDeletingLastPathComponent];
//    if(![fm fileExistsAtPath:parentPath])
//    {
//        if(![self createFileDirectories:parentPath])
//            return NO;
//    }
//    [fm changeCurrentDirectoryPath:parentPath];
//    path = [path substringFromIndex:parentPath.length+1];
//    
//    
//    //    [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
//    //    if(error)
//    //    {
//    //        NSLog(@" create path:%@",path);
//    //        NSLog(@" create failure:%@",[error localizedDescription]);
//    //        return NO;
//    //    }
//    
//    BOOL isDir = FALSE;
//    
//    BOOL isDirExist = [fm fileExistsAtPath:path
//                               isDirectory:&isDir];
//    
//    if(!(isDirExist && isDir))
//    {
//        NSError * error = nil;
//        if(isDirExist)
//        {
//            [fm removeItemAtPath:path error:&error];
//            if(error)
//            {
//                NSLog(@" remove path:%@ failure:%@",path,[error description]);
//                return NO;
//            }
//        }
//        BOOL bCreateDir = [fm createDirectoryAtPath:path
//                        withIntermediateDirectories:YES
//                                         attributes:nil
//                                              error:&error];
//        
//        if(!bCreateDir){
//            
//            NSLog(@"Create dir:%@ Failed.%@",path,[error description]);
//            return NO;
//            
//        }
//        
//    }
//    
//    return YES;
//}
//
//+ (void)movePath:(NSString *)sourcePath target:(NSString *)targetPath overwrite:(BOOL)overwriter
//{
//    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSError * error = nil;
//    
//    if((!overwriter) && ( ![fileManager fileExistsAtPath:targetPath]))
//    {
//        [self createFileDirectories:targetPath];
//    }
//    else
//    {
//        [self createFileDirectories:targetPath];
//    }
//    
//    NSArray * fileList = [fileManager contentsOfDirectoryAtPath:sourcePath error:&error];
//    if(error)
//    {
//        NSLog(@"** get dir files failure:%@",[error description]);
//    }
//    
//    
//    
//    for (NSString * fileName in fileList) {
//        
//        NSString * targetFile = [targetPath stringByAppendingPathComponent:fileName];
//        NSString * sourceFile = [sourcePath stringByAppendingPathComponent:fileName];
//        NSError * errorMove = nil;
//        BOOL exists = [fileManager fileExistsAtPath:targetFile];
//        if( exists && overwriter)
//        {
//            [fileManager removeItemAtPath:targetFile error:&error];
//            if(error)
//            {
//                NSLog(@"** remove exists file:%@ failure:%@",targetFile,[error description]);
//            }
//        }
//        if(!exists || overwriter)
//        {
//            NSDictionary * attr = [fileManager attributesOfItemAtPath:sourceFile error:&errorMove];
//            if(errorMove)
//            {
//                NSLog(@"** get file attributes failure: %@",[errorMove description]);
//            }
//            if([[attr objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
//            {
//                [self movePath:sourceFile target:targetFile overwrite:overwriter];
//            }
//            else
//            {
//                [fileManager moveItemAtPath:sourceFile toPath:targetFile error:&errorMove];
//                if(errorMove)
//                {
//                    NSLog(@"** move file failure: %@",[errorMove description]);
//                }
//                else
//                {
//                    NSLog(@"** move file:%@ OK",sourceFile);
//                }
//            }
//            
//        }
//    }
//}
//+ (void)copyFile:(NSString *)sourceFile target:(NSString *)targetFile overwrite:(BOOL)overwriter
//{
//    if(!targetFile || targetFile.length==0)
//    {
//        NSLog(@" empty target file.error....");
//        return;
//    }
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSError * error = nil;
//    
//    NSString * targetPath = [targetFile stringByDeletingLastPathComponent];
//    if((!overwriter) && ([fileManager fileExistsAtPath:targetPath]))
//    {
//        //        [self createFileDirectories:targetPath];
//    }
//    else
//    {
//        [self createFileDirectories:targetPath];
//    }
//    
//    NSError * errorMove = nil;
//    BOOL exists = [fileManager fileExistsAtPath:targetFile];
//    if( exists && overwriter)
//    {
//        [fileManager removeItemAtPath:targetFile error:&error];
//        if(error)
//        {
//            NSLog(@"** remove exists file:%@ failure:%@",targetFile,[error description]);
//        }
//    }
//    else if(exists)
//    {
//        error = nil;
//        UInt64 sizeTemp =  [[fileManager attributesOfItemAtPath:targetFile error:&error] fileSize];
//        if(error)
//        {
//            NSLog(@" get file [%@] size failure:%@",targetFile,[error description]);
//        }
//        if(sizeTemp>0)
//        {
//            NSLog(@" file %@ exists,cannot copy.",targetFile);
//            return;
//        }
//        else
//        {
//            error = nil;
//            [fileManager removeItemAtPath:targetFile error:&error];
//            if(error)
//            {
//                NSLog(@"** remove exists file:%@ failure:%@",targetFile,[error description]);
//            }
//        }
//    }
//    
//    [fileManager copyItemAtPath:sourceFile toPath:targetFile error:&errorMove];
//    if(errorMove)
//    {
//        NSLog(@"** copy file failure: %@",[errorMove description]);
//    }
//    else
//    {
//        NSLog(@"** copy file:%@ OK",sourceFile);
//    }
//    
//    
//}
//+ (void)copyPath:(NSString *)sourcePath target:(NSString *)targetPath overwrite:(BOOL)overwriter
//{
//    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSError * error = nil;
//    NSArray * fileList = [fileManager contentsOfDirectoryAtPath:sourcePath error:&error];
//    if(error)
//    {
//        NSLog(@"** get dir files failure:%@",[error description]);
//    }
//    
//    if((!overwriter) && ( ![fileManager fileExistsAtPath:targetPath]))
//    {
//        [self createFileDirectories:targetPath];
//    }
//    else
//    {
//        [self createFileDirectories:targetPath];
//    }
//    
//    for (NSString * fileName in fileList) {
//        
//        NSString * targetFile = [targetPath stringByAppendingPathComponent:fileName];
//        NSString * sourceFile = [sourcePath stringByAppendingPathComponent:fileName];
//        NSError * errorMove = nil;
//        BOOL exists = [fileManager fileExistsAtPath:targetFile];
//        if( exists && overwriter)
//        {
//            [fileManager removeItemAtPath:targetFile error:&error];
//            if(error)
//            {
//                NSLog(@"** remove exists file:%@ failure:%@",targetFile,[error description]);
//            }
//        }
//        if(!exists || overwriter)
//        {
//            NSDictionary * attr = [fileManager attributesOfItemAtPath:sourceFile error:&error];
//            if(error)
//            {
//                NSLog(@"** get file attributes failure: %@",[error description]);
//            }
//            if([[attr objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
//            {
//                [self copyPath:sourceFile target:targetFile overwrite:overwriter];
//            }
//            else
//            {
//                [fileManager copyItemAtPath:sourceFile toPath:targetFile error:&errorMove];
//                if(errorMove)
//                {
//                    NSLog(@"** move file failure: %@",[errorMove description]);
//                }
//                else
//                {
//                    NSLog(@"** move file:%@ OK",sourceFile);
//                }
//            }
//        }
//    }
//}


#pragma mark - rect 大小匹配
//用SourceSize的东东，填充满RectangeSize时，应该的大小
+ (CGSize)  sizeFillWithScale:(CGSize)sourceSize rectangeSize:(CGSize)rectangeSize
{
    if(sourceSize.width ==0||sourceSize.height ==0 ||rectangeSize.width==0||rectangeSize.height ==0)
        return sourceSize;
    
    CGFloat rate1 = sourceSize.width / sourceSize.height;
    CGFloat rate2 = rectangeSize.width / rectangeSize.height ;
    CGFloat rate1000 = roundf(rate1 * 1000);
    CGFloat rate2000 = roundf(rate2 * 1000);
    CGSize result = rectangeSize;
    if(rate1000 == rate2000) //处理简单的精度
    {
        //        return rectangeSize;
    }
    else if(rate1000 > rate2000)
    {
        result =  CGSizeMake(rectangeSize.height * rate1, rectangeSize.height);
    }
    else
    {
        result =  CGSizeMake(rectangeSize.width, rectangeSize.width/rate1);
    }
    return [self fixSize:result];
}
+ (CGSize)fixSize:(CGSize)size
{
    return [self fixSize:size canBeHalf:NO];
}
+ (CGSize)fixSize:(CGSize)size canBeHalf:(BOOL)canBeHalf
{
    if(canBeHalf)
    {
        if(size.width *2 == (int)(size.width *2) && (size.height *2) == (int)(size.height*2)) return size;
        
        size.width = round(size.width *2 +0.49)/2.0f;
        size.height = round(size.height *2 +0.49)/2.0f;
        return size;
    }
    else
    {
        if(size.width == (int)(size.width) && (size.height) == (int)(size.height)) return size;
        
        size.width = round(size.width +0.49);
        size.height = round(size.height +0.49);
        return size;
    }
}
+ (CGRect)fixRect:(CGRect)rect
{
    return [self fixRect:rect canBeHalf:NO];
}
+ (CGRect)fixRect:(CGRect)rect canBeHalf:(BOOL)canBeHalf
{
    if(canBeHalf)
    {
        if((rect.origin.x * 2 == (int)(rect.origin.x *2))
           &&(rect.origin.y * 2 == (int)(rect.origin.y *2))
           &&(rect.size.width * 2 == (int)(rect.size.width *2))
           &&(rect.size.height * 2 == (int)(rect.size.height *2))
           )
            return rect;
        
        rect.origin.x = round(rect.origin.x *2 +0.49)/2.0f;
        rect.origin.y = round(rect.origin.y *2+0.49)/2.0f;
        rect.size.width = round(rect.size.width * 2 +0.49)/2.0f;
        rect.size.height = round(rect.size.height *2 +0.49)/2.0f;
        return rect;
    }
    else
    {
        if((rect.origin.x  == (int)(rect.origin.x))
           &&(rect.origin.y  == (int)(rect.origin.y))
           &&(rect.size.width  == (int)(rect.size.width))
           &&(rect.size.height  == (int)(rect.size.height))
           )
            return rect;
        
        rect.origin.x = round(rect.origin.x +0.49);
        rect.origin.y = round(rect.origin.y+0.49);
        rect.size.width = round(rect.size.width  +0.49);
        rect.size.height = round(rect.size.height +0.49);
        return rect;
    }
}
//用SourceSize的东东，最大适配到RectangeSize时，应该的大小
+ (CGSize)  sizeFitWithScale:(CGSize)sourceSize rectangeSize:(CGSize)rectangeSize
{
    if(sourceSize.width ==0||sourceSize.height ==0 ||rectangeSize.width==0||rectangeSize.height ==0)
        return sourceSize;
    
    CGFloat rate1 = sourceSize.width / sourceSize.height;
    CGFloat rate2 = rectangeSize.width / rectangeSize.height ;
    CGFloat rate1000 = roundf(rate1 * 1000);
    CGFloat rate2000 = roundf(rate2 * 1000);
    CGSize result = rectangeSize;
    if(rate1000 == rate2000) //处理简单的精度
    {
        //        return rectangeSize;
    }
    else if(rate1000 > rate2000)
    {
        result =  CGSizeMake(rectangeSize.width, rectangeSize.width / rate1);
    }
    else
    {
        result = CGSizeMake(rectangeSize.height * rate1, rectangeSize.height);
    }
    return [self fixSize:result];
}
// 从sourceSize的区块中，最大可能地取出一块maskSize的范围，应该取的范围
+ (CGRect)  rectFitWithScale:(CGSize)sourceSize rectMask:(CGSize)maskSize
{
    if(sourceSize.width ==0||sourceSize.height ==0 ||maskSize.width==0||maskSize.height ==0)
        return CGRectZero;
    
    CGFloat width = 0;
    CGFloat height= 0;
    
    if(sourceSize.width/sourceSize.height > maskSize.width /maskSize.height)
    {
        CGFloat rate = sourceSize.height/maskSize.height ;
        width = maskSize.width * rate;
        height = maskSize.height * rate;
    }
    else
    {
        CGFloat rate = sourceSize.width/maskSize.width ;
        width = maskSize.width * rate;
        height = maskSize.height * rate;
    }
    
    CGRect result = CGRectZero;
    if(roundf(width)==roundf(sourceSize.width) && roundf(height) == roundf(sourceSize.height))
    {
        result =  CGRectMake(0, 0, sourceSize.width, sourceSize.height);
    }
    else
    {
        result =  CGRectMake((sourceSize.width - width)/2.0f,
                             (sourceSize.height - height)/2.0f,
                             width,
                             height);
    }
    result =  [self fixRect:result];
    if(result.origin.x >0)
    {
        result.size.width = sourceSize.width - 2* result.origin.x;
    }
    else if(result.origin.y >0)
    {
        result.size.height = sourceSize.height - 2 * result.origin.y;
    }
    return result;
}
//
//+ (BOOL) isQiniuServer:(NSString *)urlString
//{
//    return [urlString rangeOfString:@"qiniucdn.com"].length>0 || [urlString rangeOfString:@"qiniu.seenvoice.com"].length>0
//    ||[urlString rangeOfString:@"img.seenvoice.com"].length>0 || [urlString rangeOfString:@"media.seenvoice.com"].length>0
//    || [urlString rangeOfString:@"chat.seenvoice.com"].length>0;
//}
//+ (BOOL) isUrlOK:(NSString *)urlString
//{
//    if(!urlString || urlString.length<2) return NO;
//    NSRange range = [urlString rangeOfRegex:@"http://|https://|file://|ftp://|rstp://|mstp://"];
//    if(range.location==NSNotFound||range.location>5)
//        return NO;
//    else
//        return YES;
//}
//+ (BOOL) isLocalFile:(NSString *)urlString
//{
//    if(!urlString||urlString.length==0) return YES;
//    if([urlString hasPrefix:@"http://"]||[urlString hasPrefix:@"https://"]||[urlString hasPrefix:@"https://"]||[urlString hasPrefix:@"rtsp://"]||[urlString hasPrefix:@"rtp://"]||[urlString hasPrefix:@"rtcp://"]||[urlString hasPrefix:@"rtmp://"]||[urlString hasPrefix:@"stream://"])
//    {
//        return NO;
//    }
//    return YES;
//}
//+ (BOOL)isExistsFile:(NSString *)filePath
//{
//    NSFileManager * fm = [NSFileManager defaultManager];
//    if([fm fileExistsAtPath:[CommonUtil checkPath:filePath]])
//    {
//        return YES;
//    }
//    return NO;
//}
//+ (BOOL)isFileExistAndNotEmpty:(NSString *)filePath size:(UInt64 *)size
//{
//    if(!filePath || filePath.length==0) return NO;
//    NSFileManager * fm = [NSFileManager defaultManager];
//    if(![fm fileExistsAtPath:[CommonUtil checkPath:filePath]])
//    {
//        return NO;
//    }
//    NSError * error = nil;
//    UInt64 sizeTemp =  [[fm attributesOfItemAtPath:filePath error:&error] fileSize];
//    if(error)
//    {
//        NSLog(@" get file [%@] size failure:%@",filePath,[error description]);
//    }
//    if(size)
//    {
//        *size = sizeTemp;
//    }
//    if(sizeTemp > 0)
//        return YES;
//    else
//        return NO;
//}
//+ (BOOL)isInAblum:(NSString *)path
//{
//    if([path hasPrefix:@"assets-library://"])
//    {
//        return YES;
//    }
//    return NO;
//}
//+ (NSString *)checkPath:(NSString *)path
//{
//    if(!path) return nil;
//    if([path hasPrefix:@"file://"])
//    {
//        path = [path substringFromIndex:7];
//    }
//    return path;
//}
//+ (BOOL) isVideoFile:(NSString *)filePath
//{
//    if(!filePath) return NO;
//    
//    NSString * ext = [filePath pathExtension];
//    ext = [ext lowercaseString];
//    
//    if([ext isEqualToString:@"mp4"]
//       || [ext isEqualToString:@"mpeg"]
//       || [ext isEqualToString:@"mpg"]
//       || [ext isEqualToString:@"avi"]
//       || [ext isEqualToString:@"asf"]
//       || [ext isEqualToString:@"m4v"]
//    || [ext isEqualToString:@"mov"])
//    {
//        return YES;
//    }
//    return NO;
//}
//+ (BOOL) isImageFile:(NSString *)filePath
//{
//    if(!filePath) return NO;
//    
//    NSString * ext = [filePath pathExtension];
//    ext = [ext lowercaseString];
//    
//    if([ext isEqualToString:@"jpg"]
//       || [ext isEqualToString:@"png"]
//       || [ext isEqualToString:@"gif"]
//       || [ext isEqualToString:@"bmp"]
//       || [ext isEqualToString:@"jpeg"]
//       || [ext isEqualToString:@"wmf"])
//    {
//        return YES;
//    }
//    return NO;
//}
//+ (NSString *)getFileExtensionName:(NSString *)orgPath  defaultExt:(NSString *)defaultExt
//{
//    if(!orgPath||orgPath.length==0) return defaultExt;
//    NSString * ext = defaultExt;
//    NSString * lastComponent = [orgPath lastPathComponent];
//    NSRange  r = [lastComponent rangeOfString:@"."];
//    NSInteger lastPos = -1;
//    while (r.length>0) {
//        lastPos = r.location;
//        r = [lastComponent rangeOfString:@"." options:NSCaseInsensitiveSearch range:NSMakeRange(r.location +1, lastComponent.length - r.length - r.location-1)];
//    }
//    if(lastPos>0)
//    {
//        ext = [lastComponent substringFromIndex:lastPos +1];
//        if(ext.length==0 && defaultExt)
//        {
//            ext = defaultExt;
//        }
//    }
//    if(ext.length>5 && [ext rangeOfString:@"?"].length>0)
//    {
//        ext = [ext substringFromIndex:ext.length-3];
//    }
//    return [ext lowercaseString];
//}
//+ (NSString *)getMD5FileNameKeepExt:(NSString *)orgPath defaultExt:(NSString *)defaultExt
//{
//    if(!orgPath||orgPath.length==0) return nil;
//    NSString * ext = [self getFileExtensionName:orgPath defaultExt:defaultExt];
//    return [NSString stringWithFormat:@"%@.%@",[CommonUtil md5Hash:orgPath],ext];
//}
//+ (BOOL) checkUrlIsExists:(NSString *)urlString contengLength:(UInt64*)contentLength level:(int *)level
//{
//    if(!urlString || urlString.length<3) return NO;
//    if(level)
//    {
//        (*level) ++;
//        //跳转超过2次，则不算
//        if(*level >3) return NO;
//    }
//    if([CommonUtil isLocalFile:urlString])
//    {
//        return [CommonUtil isFileExistAndNotEmpty:urlString size:contentLength];
//    }
//    //    urlString = @"http://218.58.206.34/7xjw4n.media2.z0.glb.qiniucdn.com/E2YAEEeGssJ8zk8e11I_P82w1AI=/lhjWlG_lFMcYzrdHl6F2Sm6jcgls?wsiphost=local";
//    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15];
//    request.HTTPMethod = @"HEAD";
//    //    [request addValue:@"bytes=0-1" forHTTPHeaderField:@"Range"];
//    NSError *error = nil;
//    
//    NSHTTPURLResponse * response = nil;
//#ifndef __OPTIMIZE__
//    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
//#else
//    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
//#endif
//    
//    if(error)
//    {
//        NSLog(@"error:%@",error);
//        return NO;
//    }
//    else
//    {
//        NSLog(@"response:%@",[response.allHeaderFields JSONRepresentationEx]);
//        if(response.statusCode==404)
//        {
//            if(contentLength)
//                *contentLength = -1;
//            return NO;
//        }
//        else if(response.statusCode==302)
//        {
//#ifndef __OPTIMIZE__
//            NSLog(@"302:%@",PP_AUTORELEASE([[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]));
//#endif
//        }
//        else
//        {
//            if(contentLength)
//            {
//                
//                NSString * cr = [response.allHeaderFields objectForKey:@"Content-Range"];
//                if(cr){
//                    NSString * cl = [cr stringByMatching:@"\\d+$"];
//                    if(cl)
//                    {
//                        *contentLength = (NSInteger)[cl longLongValue];
//                    }
//                }
//                else
//                {
//                    cr = [response.allHeaderFields objectForKey:@"Content-Length"];
//                    if(cr)
//                    {
//                        *contentLength = (NSInteger)[cr longLongValue];
//                    }
//                }
//                
//                if(*contentLength<=0)
//                {
//                    *contentLength = response.expectedContentLength;
//                }
//            }
//        }
//        return YES;
//    }
//    return NO;
//}
#pragma mark - md5
+ (NSString *)trimWhitespace:(NSString *)string
{
    NSMutableString *str = [string mutableCopy];
    CFStringTrimWhitespace((__bridge CFMutableStringRef)str);
    return PP_AUTORELEASE(str);
}

+ (NSString*)getmd5WithString:(NSString *)string
{
    const char* original_str=[string UTF8String];
    unsigned char digist[CC_MD5_DIGEST_LENGTH]; //CC_MD5_DIGEST_LENGTH = 16
    CC_MD5(original_str, (CC_LONG)strlen(original_str), digist);
    NSMutableString* outPutStr = [NSMutableString stringWithCapacity:10];
    for(int  i =0; i<CC_MD5_DIGEST_LENGTH;i++){
        [outPutStr appendFormat:@"%02x", digist[i]];//小写x表示输出的是小写MD5，大写X表示输出的是大写MD5
    }
    return [outPutStr lowercaseString];
}

+ (NSString*)getMD5WithData:(NSData *)data{
    const char* original_str = (const char *)[data bytes];
    unsigned char digist[CC_MD5_DIGEST_LENGTH]; //CC_MD5_DIGEST_LENGTH = 16
    CC_MD5(original_str, (CC_LONG)strlen(original_str), digist);
    NSMutableString* outPutStr = [NSMutableString stringWithCapacity:10];
    for(int  i =0; i<CC_MD5_DIGEST_LENGTH;i++){
        [outPutStr appendFormat:@"%02x",digist[i]];//小写x表示输出的是小写MD5，大写X表示输出的是大写MD5
    }
    
    //也可以定义一个字节数组来接收计算得到的MD5值
    //    Byte byte[16];
    //    CC_MD5(original_str, strlen(original_str), byte);
    //    NSMutableString* outPutStr = [NSMutableString stringWithCapacity:10];
    //    for(int  i = 0; i<CC_MD5_DIGEST_LENGTH;i++){
    //        [outPutStr appendFormat:@"%02x",byte[i]];
    //    }
    //    [temp release];
    
    return [outPutStr lowercaseString];
    
}


+(NSString*)getFileMD5WithPath:(NSString*)path
{
    return (__bridge_transfer NSString *)FileMD5HashCreateWithPath((__bridge CFStringRef)path,FileHashDefaultChunkSizeForReadingData);
}

CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath,
                                      size_t chunkSizeForReadingData) {
    
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    
    CC_MD5_CTX hashObject;
    bool hasMoreData = true;
    bool didSucceed;
    
    if (!fileURL) goto done;
    
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    
    // Initialize the hash object
    CC_MD5_Init(&hashObject);
    
    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }
    
    // Feed the data to the hash object
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                  (UInt8 *)buffer,
                                                  (CFIndex)sizeof(buffer));
        if (readBytesCount == -1)break;
        if (readBytesCount == 0) {
            hasMoreData =false;
            continue;
        }
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    
    // Abort if the read operation failed
    if (!didSucceed) goto done;
    
    // Compute the string result
    char hash[22 *sizeof(digest) + 1];
    for (size_t i =0; i < sizeof(digest); ++i) {
        snprintf(hash + (22 * i),3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,
                                       (const char *)hash,
                                       kCFStringEncodingUTF8);
    
done:
    
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}
//+ (void)SaveImageFile:(NSString *)filePath image:(UIImage *)image
//{
//    //先把图片转成NSData
//    NSData *data;
//    if (UIImagePNGRepresentation(image) == nil)
//    {
//        data = UIImageJPEGRepresentation(image, 1.0);
//    }
//    else
//    {
//        data = UIImagePNGRepresentation(image);
//    }
//    //图片保存的路径
//    //这里将图片放在沙盒的documents文件夹中
//    //    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
//    
//    NSLog(@"filePath>>>>%@",filePath);
//    
//    
//    NSFileManager * fm = [NSFileManager defaultManager];
//    
//    NSString * path = [filePath stringByDeletingLastPathComponent];
//    //    NSLog(@"path:%@",path);
//    
//    if(![CommonUtil createFileDirectories:path])
//    {
//        return ;
//    }
//    
//    NSError * error = nil;
//    if([fm fileExistsAtPath:filePath])
//    {
//        
//        [fm removeItemAtPath:filePath error:&error];
//        if(error)
//        {
//            NSLog(@" create file:%@",path);
//            NSLog(@" create failure:%@",[error localizedDescription]);
//        }
//        
//    }
//    
//    [fm createFileAtPath:filePath contents:data attributes:nil];
//    
//}

@end

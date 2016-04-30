//
//  CommonUtil.h
//  HotelCloud
//
//  Created by Lawrence Chen on 12-10-31.
//  Copyright (c) 2012年 Suixing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HCBase.h"
//#import "HCResources.h"
//#import "PublicEnum.h"
#import "PublicMControls.h"
//#import "PublicText.h"
//#import "PublicConfig.h"
//#import "PublicViewTags.h"
#import <CoreGraphics/CGBase.h>
#import <UIKit/UIKit.h>
@interface CommonUtil : NSObject
+ (unsigned int)intFromHexString:(NSString *) hexStr;

+ (NSString*)   readContentFromFile:(NSString *)fileName type:(NSString*)type;
//+ (int)         getHotelIDFromBarCode:(NSString*)barCode;
+ (UIColor *)   colorFromHexRGB:(NSString *) inColorString;
+ (NSString*)   getMapUrl:(double)lat lng:(double)lng width:(CGFloat)width height:(CGFloat)height;
+ (BOOL)        isLatLngValid:(double)lat lng:(double)lng;
+ (CGSize)      getTextHeight:(NSString *)text font:(UIFont*)font width:(CGFloat)width;
//+ (NSString *)  starLevelWithNum:(NSInteger)starNum; //宾馆星级从数字转换为文字
//距离计算
+ (NSString *)  stringFromDistance:(double)distance;
+ (NSString *)  lbsDistanceToString:(double)lon
                            fromLat:(double)lat
                              toLon:(double)lon1
                              toLat:(double)lat1;

//距离计算
+ (int)         lbsDistance:(double)lon
                    fromLat:(double)lat
                      toLon:(double)lon1
                      toLat:(double)lat1;
+ (double)      getDeltaByDistance:(double)lat fromLng:(double)lng distance:(int)distance;
//+ (void)        hotelSortByDistance:(NSMutableArray *)array lat:(double)lat lng:(double)lng;

//+ (NSString *)  getBillStatus:(int)theStatus;
+ (int)         convertToInt:(NSString*)strtemp;
+ (int)         getToInt:(NSString*)strtemp;

+ (NSString *)  distanceString:(int)distance;

#pragma mark - valid string
+ (BOOL)isMobileNumber:(NSString *)mobileNum;
+ (BOOL)isTelphoneNumber:(NSString *)tel;
+ (BOOL)validateEmail:(NSString*)email;
+ (NSString *)getTelephoneFromString:(NSString*)phoneString;
+ (NSArray *)getTelephoneArrayFromString:(NSString*)phoneString;

#pragma mark - images
//+ (UIImage *)addTwoImageToOne:(UIImage *)oneImg
//                     twoImage:(UIImage *)twoImg
//                    xposition:(NSInteger)xpos
//                    yposition:(NSInteger)ypos;
//+ (UIImage *)crapImageInTriangle:(UIImage *)image len:(CGFloat)len startx:(CGFloat)x starty:(CGFloat)y;
//+ (UIImage *)scaleImage:(UIImage*)image posx:(int)x posy:(int)y width:(int)width height:(int)height;
//+ (UIImage *)scaleImageA:(UIImage*)image width:(int)width height:(int)height;
//+ (void)setImageToBlur: (UIImageView *) imageview
//                 image: (UIImage *)image
//            blurRadius: (CGFloat)blurRadius;
//+(void) rotatoImage:(UIImageView *) view direction:(NSInteger) dir;
//+ (UIImage *) roundCorners:(UIImage *)image regionWidth:(CGFloat)regionWidth;
//+ (UIImage *)imageForHotelBarcodeWithLogo:(int)hotelID width:(CGFloat)width borderWidth:(CGFloat)bw;
#pragma mark - string format
//转十六进制字符串
+ (NSString *)toHEXstring:(long)num;
+ (NSString *)stripAllTags:(NSString *)html;
//+ (NSString *)priceString:(CGFloat)minPrice maxPrice:(CGFloat )maxPrice unit:(NSString *)unit;
+ (NSString *)sha1:(NSString *)str;
+ (NSString *)md5Hash:(NSString *)str;

+ (NSString *)trimWhitespace:(NSString *)string;
//计算NSData 的MD5值
+(NSString*)getMD5WithData:(NSData*)data;
//计算字符串的MD5值，
+(NSString*)getmd5WithString:(NSString*)string;
//计算大文件的MD5值
+(NSString*)getFileMD5WithPath:(NSString*)path;

+ (int)     strlen:(NSString*)strtemp;
+ (int)     strLen2:(NSString*)strtemp;
+ (BOOL)    hasChinese:(NSString *)str;
+ (NSString *) leftFillZero:(NSString *)orgString withLength:(int)length;
+ (NSString *) stringWithFixedLength:(NSInteger)number withLength:(int)length;
//+ (BOOL)    unZipFileFrom:(NSString *)source to:(NSString *)destination;

+ (CGSize)  sizeOfString:(NSString *)aStr
              withFont:(UIFont *)aFont
                 width:(NSInteger)aWidth
                height:(NSInteger)aHeight;

+ (UILabel *)labelWithText:(NSString *)aText
                      font:(UIFont *)aFont
                 textColor:(UIColor *)aColor
                     width:(NSInteger)aWidth
                    height:(NSInteger)aHeight;

+ (NSString *)get_uuid;
//#pragma mark - files
//+ (void)    createFileDirectory:(NSString *)dirFullPath;
//+ (BOOL)    createFileDirectories:(NSString * )path;
//+ (void)    movePath:(NSString *)sourcePath target:(NSString *)targetPath overwrite:(BOOL)overwriter;
//+ (void)    copyPath:(NSString *)sourcePath target:(NSString *)targetPath overwrite:(BOOL)overwriter;
//+ (void)    copyFile:(NSString *)sourceFile target:(NSString *)targetFile overwrite:(BOOL)overwriter;
//+ (BOOL)    isExistsFile:(NSString *)filePath;
//+ (BOOL)    isFileExistAndNotEmpty:(NSString *)filePath size:(UInt64 *)size;

#pragma mark - rect
//用SourceSize的东东，填充满RectangeSize时，应该的大小
+ (CGSize)  sizeFillWithScale:(CGSize)sourceSize rectangeSize:(CGSize)rectangeSize;
//用SourceSize的东东，最大适配到RectangeSize时，应该的大小
+ (CGSize)  sizeFitWithScale:(CGSize)sourceSize rectangeSize:(CGSize)rectangeSize;
// 从sourceSize的区块中，最大可能地取出一块maskSize的范围，应该取的范围
+ (CGRect)  rectFitWithScale:(CGSize)sourceSize rectMask:(CGSize)maskSize;
+ (CGSize)fixSize:(CGSize)size;
+ (CGSize)fixSize:(CGSize)size canBeHalf:(BOOL)canBeHalf;
+ (CGRect)fixRect:(CGRect)rect;
+ (CGRect)fixRect:(CGRect)rect canBeHalf:(BOOL)canBeHalf;

//+ (BOOL)    isQiniuServer:(NSString *)urlString;
//+ (NSString *)checkPath:(NSString *)path;
//+ (BOOL)    isLocalFile:(NSString *)urlString;
//+ (BOOL)    isImageFile:(NSString *)filePath;
//+ (BOOL)    isVideoFile:(NSString *)filePath;
//+ (BOOL)    isInAblum:(NSString *)path;
//+ (NSString *)getFileExtensionName:(NSString *)orgPath  defaultExt:(NSString *)defaultExt;
//+ (NSString *)getMD5FileNameKeepExt:(NSString *)orgPath defaultExt:(NSString *)defaultExt;
//+ (BOOL)    checkUrlIsExists:(NSString *)urlString contengLength:(UInt64*)contentLength level:(int *)level;
//+ (BOOL)    isUrlOK:(NSString *)urlString;
//
//+ (void)    SaveImageFile:(NSString *)filePath image:(UIImage *)image;


@end

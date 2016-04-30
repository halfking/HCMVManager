//
//  CommonUtil(Date).h
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-3.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonUtil.h"

#define LOCATION_IDENTIFIER @"zh_CN"
#define MSG_JUSTNOW                 @"刚才"
#define MSG_MINITUESBEFORE          @"分钟前"
#define MSG_TODAY                   @"今天"
#define MSG_LASTUPDATETIME         @"最后刷新时间  %@"

@interface CommonUtil(Date)
#pragma mark - date operate

+ (NSString *) getCurrentTime;
+ (BOOL)isSameDay:(NSDate*)date1 date2:(NSDate*)date2;
+ (NSString *)shortenDateString:(NSString *)dateString;
+ (NSString *) stringFromDate:(NSDate *)date;
+ (NSString *) stringFromDate:(NSDate *)date andFormat:(NSString*)format;
+ (NSDate *) dateFromString:(NSString *)dateString;
+ (BOOL) isDateExpired:(NSDate *)originalDate andSeconds:(int)seconds;
+ (BOOL) isDateEarlier:(NSDate *)date1 thanDate:(NSDate *)date2;

+(NSString *)getDateText:(NSDate *)oldDate format:(NSString*)format;
+(NSString *)getDateText:(NSString *)oldDateString;
+(NSString *)getDateText:(NSString *)oldDateString andFormat:(NSString*)format;
+(NSString *)getActivityDateText:(NSString *)oldDateString;
//获得M/D格式日期
+(NSString *)getActivityDateTextSprit:(NSString *)oldDateString;
+(NSString *)getSubscribeDateText:(NSString *)oldDateString;

+(NSString *)getTimeText:(int)seconds;
+(long)getDateTicks:(NSDate *) date;

//判断时间是否在范围内
+ (BOOL)isTimeScope:(NSString *)beginTime endTime:(NSString *)endTime currentDateTime:(NSDate *)cDateTime;

+ (int)getRoomDays:(NSString *)dateBegin dateEnd:(NSString*)dateEnd check:(BOOL)check;
+ (int)getRoomDaysN:(NSDate *)dateBegin dateEnd:(NSDate *)dateEnd check:(BOOL)check;

+ (NSDate *) date:(NSDate *)date ByAddingDays: (NSInteger) dDays;
+ (NSDate *) date:(NSDate *)date BySubtractingDays: (NSUInteger) dDays;
+ (NSDateComponents *)dateComponents:(NSDate *)date;

+ (NSString *)getFirstShowTime:(NSString *)orgDate andType:(int)type;
+ (NSString *)getTimeStringOfTimeInterval:(NSTimeInterval)timeInterval;
@end

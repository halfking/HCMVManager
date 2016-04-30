//
//  CommonUtil(Date).m
//  HCIOS_2
//
//  Created by XUTAO HUANG on 13-9-3.
//  Copyright (c) 2013年 XUTAO HUANG. All rights reserved.
//

#import "CommonUtil(Date).h"

@implementation CommonUtil(Date)
#pragma mark - date operate
+(NSString *) getCurrentTime
{
    NSDate *curDate = [NSDate date];
    NSDateFormatter *formater = [[ NSDateFormatter alloc] init];
    [formater setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString * curTime = [formater stringFromDate:curDate];
    NSLog(@"curtime:%@",curTime);
    PP_RELEASE(formater);
    return curTime;
}
//得到中英文混合字符串长度 方法2
+ (BOOL)isSameDay:(NSDate*)date1 date2:(NSDate*)date2
{
    if(date1==nil || date2==nil) return NO;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:date1];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:date2];
    
    return [comp1 day]   == [comp2 day] &&
    [comp1 month] == [comp2 month] &&
    [comp1 year]  == [comp2 year];
}
+ (NSString *) stringFromDate:(NSDate *)date andFormat:(NSString*)format
{
    if(date==nil) return @"";
    
    NSDateFormatter *formate = [[NSDateFormatter alloc] init];
    
    [formate setTimeZone:[NSTimeZone defaultTimeZone]];
    [formate setLocale:PP_AUTORELEASE([[NSLocale alloc] initWithLocaleIdentifier:LOCATION_IDENTIFIER]
                                      )];
    
    [formate setDateFormat:(format)];
    
    NSString * result = [formate stringFromDate:date];
    PP_RELEASE(formate);
    
    return result;
}
static NSDateFormatter * defaultDateFormat = nil;
static dispatch_once_t dateformatOnce;
+ (NSString *) stringFromDate:(NSDate *)date
{
    if(date==nil) return nil;
    
    
    if(!defaultDateFormat)
    {
        dispatch_once(&dateformatOnce, ^{
            NSDateFormatter *formate = [[NSDateFormatter alloc] init];
            
            [formate setTimeZone:[NSTimeZone defaultTimeZone]];
            
            [formate setDateFormat:(DEFAULT_DATE_TIME_FORMAT)];
            defaultDateFormat = PP_RETAIN(formate);
            PP_RELEASE(formate);
        });
    }
    NSString * result = [defaultDateFormat stringFromDate:date];
    return result;
}
+ (NSString *)shortenDateString:(NSString *)dateString
{
    if(!dateString||dateString.length<5) return dateString;
    
    NSString *regexString   = @"\\d{1,2}[-/\\.]\\d{1,2}\\s+\\d{1,2}:\\d{1,2}" ;
//    PP_RETAIN(dateString);
    NSString *matchedString = nil;
    @autoreleasepool {
        @try {
            NSError * error = nil;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:&error];
            if(error)
            {
                NSLog(@"regex error:%@",[error description]);
            }
            NSArray* matches = [regex matchesInString:dateString options:0 range:NSMakeRange(0, dateString.length)];
            if(matches.count>0)
            {
                NSRange matchRange = [[matches objectAtIndex:0] range];
                matchedString = PP_RETAIN([dateString substringWithRange:matchRange]);
            }
            else
                matchedString = nil;
            //        matchedString = [dateString stringByMatching:regexString capture:0L];
        }
        @catch (NSException *exception) {
            NSLog(@"regex error:%@",[exception description]);
        }
        @finally {
            
        }
//        PP_RELEASE(dateString);
        
        return PP_AUTORELEASE(matchedString);
    }
}

+ (NSDate *) dateFromString:(NSString *)dateString
{
    if([dateString isKindOfClass:[NSDate class]])
    {
        return (NSDate *) dateString;
    }
    
    if(dateString==nil|| [dateString length]==0) return nil;
    NSDate *willdate = nil;
    @autoreleasepool {
        
        NSDateFormatter *formate = [[NSDateFormatter alloc] init];
        if([dateString rangeOfString:@"月"].length >0)
        {
            dateString = [dateString stringByReplacingOccurrencesOfString:@"年" withString:@"-"];
            dateString = [dateString stringByReplacingOccurrencesOfString:@"月" withString:@"-"];
            dateString = [dateString stringByReplacingOccurrencesOfString:@"日" withString:@""];
        }
        if([dateString rangeOfString:@"/"].length>0)
        {
            dateString = [dateString stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
        }
        [formate setTimeZone:[NSTimeZone defaultTimeZone]];
        if(dateString.length <=10)
            [formate setDateFormat:@"yyyy-MM-dd"];
        else
            [formate setDateFormat:(DEFAULT_DATE_TIME_FORMAT)];
        NSLocale *locale=[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        [formate setLocale:locale];
        
        @try {
            willdate = PP_RETAIN([formate dateFromString:dateString]);
        }
        @catch (NSException *exception) {
            NSLog(@"convert string %@ to date error:%@",dateString,[exception description]);
        }
        @finally {
            
        }
        if(willdate==nil)
        {
            dateString = [dateString stringByReplacingOccurrencesOfString:@"T" withString:@" "];
            dateString = [dateString stringByReplacingOccurrencesOfString:@"Z" withString:@""];
            NSRange range1 = [dateString rangeOfString:@"."];
            if(range1.length>0)
            {
                dateString = [dateString substringToIndex:range1.location];
            }
            
            [formate setDateFormat:(@"yyyy-MM-dd HH:mm:ss")];
            //NSLocale *locale=[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
            //[formate setLocale:locale];
            @try {
                willdate = PP_RETAIN([formate dateFromString:dateString]);
            }
            @catch (NSException *exception) {
                NSLog(@"convert string %@ to date error:%@",dateString,[exception description]);
            }
            @finally {
                
            }
        }
        PP_RELEASE(locale);
        PP_RELEASE(formate);
        return PP_AUTORELEASE(willdate);
    }
}
+ (BOOL) isDateExpired:(NSDate *)originalDate andSeconds:(int)seconds
{
    if(originalDate == nil) return TRUE;
    NSDate * cDate = [NSDate dateWithTimeIntervalSinceNow: (0 - seconds)];
    return ([originalDate timeIntervalSinceDate:cDate] <0);
}
+ (BOOL) isDateEarlier:(NSDate *)date1 thanDate:(NSDate *)date2
{
    NSTimeInterval date1Time = [date1 timeIntervalSince1970];
    NSTimeInterval date2Time = [date2 timeIntervalSince1970];
    
    return (date1Time < date2Time);
}
+(long) getDateTicks:(NSDate *)date
{
    NSTimeInterval t = [date timeIntervalSince1970];
    NSInteger totalSeconds = (int)t;
    NSInteger minute = (totalSeconds%36000)/60;//以10 小时为单位
    NSInteger second = (totalSeconds%3600)%60;
    int minSeconds = (t - totalSeconds) * 1000;
    return minute * 60000 + second*1000 + minSeconds;
}
+(NSString *)getSubscribeDateText:(NSString *)oldDateString
{
    if(oldDateString==nil) return @"";
    NSDate * currDate = [NSDate date];
    NSDate * oldDate = [CommonUtil dateFromString:oldDateString];
    
    NSTimeInterval diff = [currDate timeIntervalSinceDate:oldDate];
    if(diff <60)
    {
        return [NSString stringWithFormat:@"%@ %@",MSG_JUSTNOW,[CommonUtil stringFromDate:oldDate andFormat:@"HH:mm"] ];
    }
    else if(diff <30 *60)
    {
        return [NSString stringWithFormat:@"%i%@ %@",(int)(diff/60),MSG_MINITUESBEFORE,[CommonUtil stringFromDate:oldDate andFormat:@"HH:mm"] ];
    }
    else if([CommonUtil isSameDay:currDate date2:oldDate])
    {
        return [NSString stringWithFormat:@"%@ %@",MSG_TODAY,[CommonUtil stringFromDate:oldDate andFormat:@"HH:mm"] ];
    }
    else
    {
        return [CommonUtil stringFromDate:oldDate andFormat:@"MM-dd HH:mm"];
    }
}

+(NSString *)getDateText:(NSString *)oldDateString
{
    return [CommonUtil getDateText:oldDateString andFormat:nil];
}
+(NSString *)getDateText:(NSString *)oldDateString andFormat:(NSString*)format
{
    if(oldDateString==nil) return @"";
    NSDate * oldDate = [CommonUtil dateFromString:oldDateString];
    return [CommonUtil getDateText:oldDate format:format];
}
+(NSString *)getDateText:(NSDate *)oldDate format:(NSString*)format
{
    if(oldDate==nil) return @"";
    NSDate * currDate = [NSDate date];
    //    NSDate * oldDate = [CommonUtil dateFromString:oldDateString];
    if(format)
    {
        return [CommonUtil stringFromDate:oldDate andFormat:format];
    }
    else
    {
        NSTimeInterval diff = [currDate timeIntervalSinceDate:oldDate];
        if(diff <60)
        {
            return [NSString stringWithFormat:@"%@ %@",MSG_JUSTNOW,[CommonUtil stringFromDate:oldDate andFormat:@"HH:mm"] ];
        }
        else if(diff <30 *60)
        {
            return [NSString stringWithFormat:@"%i%@ %@",(int)(diff/60),MSG_MINITUESBEFORE,[CommonUtil stringFromDate:oldDate andFormat:@"HH:mm"] ];
        }
        else if([CommonUtil isSameDay:currDate date2:oldDate])
        {
            return [NSString stringWithFormat:@"%@ %@",MSG_TODAY,[CommonUtil stringFromDate:oldDate andFormat:@"HH:mm"] ];
        }
        else
        {
            return [CommonUtil stringFromDate:oldDate andFormat:@"yyyy-MM-dd"];
        }
    }
}

+(NSString *)getTimeText:(int)seconds
{
    if(seconds <=0) return @"";
    int dayCount = seconds / (60 * 60 * 24);
    int hourCount  = (seconds - (60 * 60 * 24) *dayCount)/(60*60);
    int minutes = (seconds % (60 * 60))/60;
    int secondCount = seconds % 60;
    NSMutableString * ret = [[NSMutableString alloc]init];
    int count = 0;
    if(dayCount >0)
    {
        [ret appendFormat:@"%d天",dayCount];
        count ++;
    }
    if(hourCount>0)
    {
        [ret appendFormat:@"%d小时",hourCount];
        count ++;
    }
    else if(count>0) count ++;
    if(minutes>0 && count <2)
    {
        [ret appendFormat:@"%d分钟",minutes];
        count ++;
    }
    else if(count>0) count ++;
    
    if(secondCount>0 && count <2)
    {
        [ret appendFormat:@"%d秒",secondCount];
        count ++;
    }
    return PP_AUTORELEASE(ret);
}
+ (BOOL)isTimeScope:(NSString *)beginTime endTime:(NSString *)endTime currentDateTime:(NSDate *)cDateTime
{
    if(!beginTime || !endTime) return YES;
    NSString * dateString = [CommonUtil stringFromDate:cDateTime andFormat:@"yyyy-MM-dd"];
    NSDate *beginDate = [CommonUtil dateFromString:[NSString stringWithFormat:@"%@ %@:00",dateString,beginTime]];
    NSDate *endDate = [CommonUtil dateFromString:[NSString stringWithFormat:@"%@ %@:00",dateString,endTime]];
    //如果从前一天下午到今天上午这种类型的或者从今天某个时候到第二天的某个时候的比较
    //如果开始日期比结束日期晚，则是从前一天到今天
    if([endDate earlierDate:beginDate]==endDate)
    {
        //前移一天
        NSDate* newbeginDate = [NSDate dateWithTimeInterval:-24*60*60 sinceDate:beginDate];
        if([newbeginDate earlierDate:cDateTime]==newbeginDate &&
           [cDateTime earlierDate:endDate]==cDateTime)
        {
            return YES;
        }
        //后移一天
        //        beginDate = [beginDate initWithTimeInterval:24*60*60 sinceDate:beginDate];
        NSDate * newEndDate = [NSDate dateWithTimeInterval:24*60*60 sinceDate:endDate];
        if([beginDate compare:cDateTime]<=NSOrderedSame &&
           [cDateTime compare:newEndDate]<=NSOrderedSame)
        {
            return YES;
        }
    }
    //否则是从今天到后一天，或者一天内
    else
    {
        if([beginDate compare:cDateTime]<=NSOrderedSame &&
           [cDateTime compare:endDate]<=NSOrderedSame)
        {
            return YES;
        }
    }
    
    return NO;
}
+ (int)getRoomDays:(NSString *)dateBegin dateEnd:(NSString *)dateEnd check:(BOOL)check
{
    if(!dateBegin||!dateEnd) return 0;
    
    NSString * dateBeginTemp = dateBegin.length>10?[dateBegin substringToIndex:10]:dateBegin;
    NSString * dateEndTemp = dateEnd.length>10?[dateEnd substringToIndex:10]:dateEnd;
    NSDate * begin = [CommonUtil dateFromString:dateBeginTemp];
    NSDate * end = [CommonUtil dateFromString:dateEndTemp];
    NSTimeInterval ticks = [end timeIntervalSinceDate:begin];
    int days = ticks / (24*60*60);
    if(days==0 && check) days = 1;
    
    return days;
}
+ (int)getRoomDaysN:(NSDate *)dateBegin dateEnd:(NSDate *)dateEnd check:(BOOL)check
{
    if(!dateBegin||!dateEnd) return 0;
    
    NSTimeInterval ticks = [dateEnd timeIntervalSinceDate:dateBegin];
    int days = ticks / (24*60*60);
    if(days==0 && check) days = 1;
    
    return days;
}
+(NSString *)getActivityDateText:(NSString *)oldDateString
{
    if(oldDateString==nil) return @"";
    NSDate * oldDate = [CommonUtil dateFromString:oldDateString];
    
    return [NSString stringWithFormat:@"%@",[CommonUtil stringFromDate:oldDate andFormat:@"M月d日"] ];
}

+(NSString *)getActivityDateTextSprit:(NSString *)oldDateString
{
    if(oldDateString==nil) return @"";
    NSDate * oldDate = [CommonUtil dateFromString:oldDateString];
    
    return [NSString stringWithFormat:@"%@",[CommonUtil stringFromDate:oldDate andFormat:@"M/d"] ];
}

+ (NSDate *) date:(NSDate *)date ByAddingDays: (NSInteger) dDays
{
    NSTimeInterval aTimeInterval = [date timeIntervalSinceReferenceDate] + 86400 * dDays;
    NSDate *newDate = [NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval];
    return newDate;
}

+ (NSDate *) date:(NSDate *)date BySubtractingDays: (NSUInteger) dDays
{
    return [CommonUtil date:date ByAddingDays: (dDays * -1)];
}

+ (int) getTimeIntValue:(NSDate *) odate
{
    NSString * timeArrive = [CommonUtil stringFromDate:odate andFormat:@"HH:mm"];
    NSString * minStr =[CommonUtil stringFromDate:odate andFormat:@"mm"];
    timeArrive = [timeArrive stringByReplacingOccurrencesOfString:@":" withString:@""];
    int time = [timeArrive intValue];
    int min = [minStr intValue];
    
    if(min >= 30){
        int t = (floor(time / 100) + 1) * 100;
        return t >= 2400 ? 0 : t;
    }else{
        return floor(time / 100) * 100 + 30;
    }
}

+ (NSString *)getFirstShowTime:(NSString *)orgDate andType:(int)type
{
    NSString * str = @"";
    int days = [CommonUtil getRoomDays:[CommonUtil getCurrentTime] dateEnd:orgDate check:YES];
    if (days > 1) {//预定明天
        if(type==0) //room
            str = @"18:00";
        else if(type==1) //seat
            str= @"11:00";
        else
            str = @"8:00";
    }
    else{
        NSString * timeArrive = [[CommonUtil getSubscribeDateText:[CommonUtil getCurrentTime]] substringFromIndex:3];
        timeArrive = [timeArrive stringByReplacingOccurrencesOfString:@":" withString:@""];
        int timeInt = [timeArrive intValue];
        if(type==0 && timeInt <1200)
        {
            str = @"12:00";
        }
        else if(type==0 && timeInt < 1800)
        {
            str = @"18:00";
        }
        else if(type==1 && timeInt <1100)
        {
            str = @"11:00";
        }
        else if(timeInt <800)
        {
            str = @"08:00";
        }
        else{
            //18:00后
            //            参考公式
            //            时间转化数字：19：00=1900
            //            X=下单时间+30
            //            Y=Math.ABS(1930-X)-Math.ABS(2000-X)
            //            Y>=0 取 2000（即20:00）
            //            Y<0 取1930（即19:30）
            
            NSDate *ldate = [CommonUtil dateFromString:[CommonUtil getCurrentTime]];
            NSDate *rdate = [NSDate dateWithTimeInterval:30*60 sinceDate:ldate];
            
            //计算可能合适的时间
            int ltime = [CommonUtil getTimeIntValue:ldate];
            int rtime = [CommonUtil getTimeIntValue:rdate];
            
            int x = timeInt;
            
            int finalTime = (abs(ltime - x) - abs(rtime - x)) < 0 ? ltime : rtime;
            NSString * timeStr = [NSString stringWithFormat:@"0000%d",finalTime];
            
            str = [NSString stringWithFormat:@"%@:%@",[timeStr substringWithRange:NSMakeRange(timeStr.length-4, 2)],[timeStr substringFromIndex:timeStr.length-2]];
        }
    }
    NSString * dateString =  [CommonUtil stringFromDate:[CommonUtil dateFromString:orgDate] andFormat:@"yyyy-MM-dd"];
    dateString = [dateString stringByAppendingString:[NSString stringWithFormat:@" %@:00",str]];
    return dateString;
}

#define DATE_COMPONENTS (NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekOfYear |  NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal)
#define CURRENT_CALENDAR [NSCalendar currentCalendar]
+ (NSDateComponents *)dateComponents:(NSDate *)date
{
    NSDateComponents *components = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:date];
    [components setCalendar:CURRENT_CALENDAR];
    return components;
}

+ (NSString *)getTimeStringOfTimeInterval:(NSTimeInterval)timeInterval
{
    //    NSCalendar *calendar = [NSCalendar currentCalendar];
    //
    //    NSDate *dateRef = [[NSDate alloc] init];
    //    NSDate *dateNow = [[NSDate alloc] initWithTimeInterval:timeInterval sinceDate:dateRef];
    //
    //    unsigned int uFlags =
    //    NSSecondCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit |
    //    NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit;
    //
    //
    //    NSDateComponents *components = [calendar components:uFlags
    //                                               fromDate:dateRef
    //                                                 toDate:dateNow
    //                                                options:0];
    NSString *retTimeInterval;
    long hours =(long)( timeInterval / 3600);
    double minutesWithSeconds = timeInterval - hours * 3600;
    long minutes = (long)(minutesWithSeconds/60);
    long seconds = (long)roundf((minutesWithSeconds - minutes * 60));
    
    if (hours)
    {
        retTimeInterval = [NSString stringWithFormat:@"%ld:%02ld:%02ld", hours, minutes, seconds];
    }
    else
    {
        retTimeInterval = [NSString stringWithFormat:@"%02ld:%02ld", minutes, seconds];
    }
    return retTimeInterval;
}
@end
